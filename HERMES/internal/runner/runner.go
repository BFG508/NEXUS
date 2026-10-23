package runner

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/BFG508/NEXUS/HERMES/internal/artifact"
	"github.com/BFG508/NEXUS/HERMES/internal/executor"
	"github.com/BFG508/NEXUS/HERMES/internal/graph"
	"github.com/BFG508/NEXUS/HERMES/internal/manifest"
	"github.com/BFG508/NEXUS/HERMES/internal/reproducibility"
	"github.com/BFG508/NEXUS/HERMES/internal/scenario"
	"github.com/BFG508/NEXUS/HERMES/internal/telemetry"
	"github.com/BFG508/NEXUS/HERMES/internal/workspace"
	"github.com/BFG508/NEXUS/HERMES/pkg/protocol"
)

const Version = "0.1.0"

// Options controls one HERMES execution.
type Options struct {
	RunsDir      string
	RunID        string
	SeedOverride *int64
}

// Outcome describes the finalized run regardless of success/failure.
type Outcome struct {
	Layout   workspace.Layout
	Manifest manifest.RunManifest
	Err      error
}

// Plan loads, validates, and returns a deterministic execution order.
func Plan(scenarioPath string) (scenario.Scenario, []byte, []string, error) {
	value, raw, err := scenario.Load(scenarioPath)
	if err != nil {
		return scenario.Scenario{}, nil, nil, err
	}
	if err := scenario.Validate(value); err != nil {
		return scenario.Scenario{}, raw, nil, err
	}
	deps := make(map[string][]string, len(value.Steps))
	for name, step := range value.Steps {
		deps[name] = append([]string(nil), step.DependsOn...)
	}
	order, err := graph.TopologicalOrder(deps)
	if err != nil {
		return scenario.Scenario{}, raw, nil, err
	}
	return value, raw, order, nil
}

// Run executes one validated scenario and always attempts to finalize a manifest.
func Run(ctx context.Context, scenarioPath string, options Options) Outcome {
	value, raw, order, err := Plan(scenarioPath)
	if err != nil {
		return Outcome{Err: err}
	}
	absoluteScenario, err := filepath.Abs(scenarioPath)
	if err != nil {
		return Outcome{Err: err}
	}
	scenarioDir := filepath.Dir(absoluteScenario)
	effectiveSeed := value.Seed
	if options.SeedOverride != nil {
		effectiveSeed = *options.SeedOverride
	}

	workingDirectory, err := resolveWorkingDirectory(value.WorkingDirectory, scenarioDir, effectiveSeed)
	if err != nil {
		return Outcome{Err: err}
	}
	scenarioSHA := reproducibility.SHA256(raw)
	fingerprint := reproducibility.Fingerprint(scenarioSHA, effectiveSeed)
	runID := options.RunID
	if runID == "" {
		runID = defaultRunID(fingerprint)
	}
	if err := validateRunID(runID); err != nil {
		return Outcome{Err: err}
	}
	runsDir := options.RunsDir
	if runsDir == "" {
		runsDir = filepath.Join(workingDirectory, ".hermes", "runs")
	}
	layout, err := workspace.Create(runsDir, runID)
	if err != nil {
		return Outcome{Err: err}
	}

	writer, err := telemetry.Open(layout.TelemetryPath)
	if err != nil {
		return Outcome{Layout: layout, Err: err}
	}
	defer writer.Close()

	start := time.Now().UTC()
	runManifest := manifest.RunManifest{
		Schema: manifest.Schema, HermesVersion: Version, RunID: runID,
		RunFingerprint: fingerprint, Status: protocol.StatusRunning,
		Scenario:         manifest.ScenarioRecord{Name: value.Name, Path: absoluteScenario, SHA256: scenarioSHA, Seed: effectiveSeed},
		WorkingDirectory: workingDirectory,
		Runtime:          reproducibility.Environment(workingDirectory),
		StartedAt:        start, TelemetryPath: layout.TelemetryPath,
	}
	for _, name := range order {
		step := value.Steps[name]
		runManifest.Steps = append(runManifest.Steps, manifest.StepRecord{
			Name: name, Status: protocol.StatusPending, DependsOn: append([]string(nil), step.DependsOn...),
		})
	}
	_ = writer.Emit(telemetry.Event{RunID: runID, State: string(protocol.StatusRunning), Message: "run started"})
	if err := manifest.WriteAtomic(layout.ManifestPath, runManifest); err != nil {
		return Outcome{Layout: layout, Manifest: runManifest, Err: err}
	}

	failed := false
	var runErr error
	for i, name := range order {
		if failed {
			runManifest.Steps[i].Status = protocol.StatusBlocked
			runManifest.Steps[i].Error = "blocked because an earlier step failed"
			_ = writer.Emit(telemetry.Event{RunID: runID, Step: name, State: string(protocol.StatusBlocked)})
			continue
		}
		stepRecord, stepErr := executeStep(ctx, value.Steps[name], name, layout, runID, scenarioDir, workingDirectory, effectiveSeed, writer)
		runManifest.Steps[i] = stepRecord
		if stepErr != nil {
			failed = true
			runErr = fmt.Errorf("step %s failed: %w", name, stepErr)
		}
		_ = manifest.WriteAtomic(layout.ManifestPath, runManifest)
	}

	finish := time.Now().UTC()
	runManifest.FinishedAt = &finish
	if failed {
		runManifest.Status = protocol.StatusFailed
		_ = writer.Emit(telemetry.Event{RunID: runID, State: string(protocol.StatusFailed), Message: runErr.Error()})
	} else {
		runManifest.Status = protocol.StatusSucceeded
		_ = writer.Emit(telemetry.Event{RunID: runID, State: string(protocol.StatusSucceeded), Message: "run completed"})
	}
	if err := manifest.WriteAtomic(layout.ManifestPath, runManifest); err != nil && runErr == nil {
		runErr = err
	}
	return Outcome{Layout: layout, Manifest: runManifest, Err: runErr}
}

func executeStep(
	ctx context.Context,
	step scenario.Step,
	name string,
	layout workspace.Layout,
	runID, scenarioDir, workingDirectory string,
	seed int64,
	writer *telemetry.Writer,
) (manifest.StepRecord, error) {
	// Step timing covers the entire attempt, including preparation before the
	// external process starts. A preparation failure has no process exit code.
	start := time.Now().UTC()
	record := manifest.StepRecord{Name: name, Status: protocol.StatusRunning, DependsOn: append([]string(nil), step.DependsOn...), StartedAt: &start}
	_ = writer.Emit(telemetry.Event{RunID: runID, Step: name, State: string(protocol.StatusRunning), Message: step.Command})
	failBeforeStart := func(err error) (manifest.StepRecord, error) {
		failed, failure := failedBeforeStart(record, err)
		_ = writer.Emit(telemetry.Event{RunID: runID, Step: name, State: string(protocol.StatusFailed), Message: err.Error()})
		return failed, failure
	}
	stepArtifactDir := filepath.Join(layout.ArtifactsDir, name)
	if err := os.MkdirAll(stepArtifactDir, 0o755); err != nil {
		return failBeforeStart(err)
	}
	builtins := map[string]string{
		"SCENARIO_DIR":      scenarioDir,
		"WORKING_DIR":       workingDirectory,
		"RUN_DIR":           layout.RunDir,
		"RUN_ID":            runID,
		"SEED":              strconv.FormatInt(seed, 10),
		"STEP":              name,
		"STEP_ARTIFACT_DIR": stepArtifactDir,
	}

	command, err := scenario.Expand(step.Command, builtins)
	if err != nil {
		return failBeforeStart(err)
	}
	args := make([]string, len(step.Args))
	for i, value := range step.Args {
		args[i], err = scenario.Expand(value, builtins)
		if err != nil {
			return failBeforeStart(err)
		}
	}
	env := make(map[string]string, len(step.Env))
	keys := make([]string, 0, len(step.Env))
	for key := range step.Env {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		env[key], err = scenario.Expand(step.Env[key], builtins)
		if err != nil {
			return failBeforeStart(err)
		}
	}

	stdoutPath := filepath.Join(layout.LogsDir, name+".stdout.log")
	stderrPath := filepath.Join(layout.LogsDir, name+".stderr.log")
	stdout, err := os.Create(stdoutPath)
	if err != nil {
		return failBeforeStart(err)
	}
	defer stdout.Close()
	stderr, err := os.Create(stderrPath)
	if err != nil {
		return failBeforeStart(err)
	}
	defer stderr.Close()

	record.Command = command
	record.Args = args
	record.Environment = env
	record.StdoutLog = stdoutPath
	record.StderrLog = stderrPath

	result := executor.Run(ctx, executor.Request{
		Command: command, Args: args, Directory: workingDirectory, Env: env,
		Timeout: time.Duration(step.TimeoutSeconds) * time.Second,
		Stdout:  stdout, Stderr: stderr,
	})
	finish := time.Now().UTC()
	record.FinishedAt = &finish
	record.DurationMS = finish.Sub(start).Milliseconds()
	record.ExitCode = &result.ExitCode
	record.TimedOut = result.TimedOut

	if result.Err != nil {
		message := result.Err.Error()
		if result.TimedOut {
			message = fmt.Sprintf("process exceeded timeout of %d seconds", step.TimeoutSeconds)
		}
		record.Status = protocol.StatusFailed
		record.Error = message
		_ = writer.Emit(telemetry.Event{RunID: runID, Step: name, State: string(protocol.StatusFailed), Message: message})
		return record, fmt.Errorf("%s", message)
	}

	for _, declared := range step.Artifacts {
		expanded, err := scenario.Expand(declared, builtins)
		if err != nil {
			record.Status = protocol.StatusFailed
			record.Error = err.Error()
			return record, err
		}
		if !filepath.IsAbs(expanded) {
			expanded = filepath.Join(workingDirectory, expanded)
		}
		item, err := artifact.Inspect(expanded)
		if err != nil {
			wrapped := fmt.Errorf("declared artifact %q: %w", declared, err)
			record.Status = protocol.StatusFailed
			record.Error = wrapped.Error()
			_ = writer.Emit(telemetry.Event{RunID: runID, Step: name, State: string(protocol.StatusFailed), Message: wrapped.Error()})
			return record, wrapped
		}
		record.Artifacts = append(record.Artifacts, item)
	}

	record.Status = protocol.StatusSucceeded
	_ = writer.Emit(telemetry.Event{RunID: runID, Step: name, State: string(protocol.StatusSucceeded)})
	return record, nil
}

func failedBeforeStart(record manifest.StepRecord, err error) (manifest.StepRecord, error) {
	finish := time.Now().UTC()
	record.FinishedAt = &finish
	record.DurationMS = finish.Sub(*record.StartedAt).Milliseconds()
	record.Status = protocol.StatusFailed
	record.Error = err.Error()
	return record, err
}

func resolveWorkingDirectory(raw, scenarioDir string, seed int64) (string, error) {
	if raw == "" {
		return filepath.Abs(scenarioDir)
	}
	expanded, err := scenario.Expand(raw, map[string]string{
		"SCENARIO_DIR": scenarioDir,
		"SEED":         strconv.FormatInt(seed, 10),
	})
	if err != nil {
		return "", err
	}
	if !filepath.IsAbs(expanded) {
		expanded = filepath.Join(scenarioDir, expanded)
	}
	absolute, err := filepath.Abs(expanded)
	if err != nil {
		return "", err
	}
	info, err := os.Stat(absolute)
	if err != nil {
		return "", fmt.Errorf("working_directory: %w", err)
	}
	if !info.IsDir() {
		return "", fmt.Errorf("working_directory is not a directory: %s", absolute)
	}
	return absolute, nil
}

func defaultRunID(fingerprint string) string {
	return time.Now().UTC().Format("20060102T150405.000000000Z") + "-" + fingerprint[:8]
}

func validateRunID(value string) error {
	if value == "" || value == "." || value == ".." || strings.ContainsAny(value, `/\\`) {
		return fmt.Errorf("invalid run ID %q", value)
	}
	return nil
}
