package runner

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/BFG508/NEXUS/HERMES/internal/manifest"
	"github.com/BFG508/NEXUS/HERMES/internal/scenario"
	"github.com/BFG508/NEXUS/HERMES/internal/telemetry"
	"github.com/BFG508/NEXUS/HERMES/pkg/protocol"
)

func TestPreparationFailureRecordsLifecycle(t *testing.T) {
	const unknown = "${NEXUS_TEST_UNDEFINED_PREPARATION_VARIABLE}"
	// An empty environment value is defined to Expand; ensure it is absent.
	key := "NEXUS_TEST_UNDEFINED_PREPARATION_VARIABLE"
	if value, exists := os.LookupEnv(key); exists {
		t.Cleanup(func() { _ = os.Setenv(key, value) })
	}
	if err := os.Unsetenv(key); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name string
		step scenario.Step
	}{
		{"command", scenario.Step{Command: unknown}},
		{"argument", scenario.Step{Command: "unused", Args: []string{unknown}}},
		{"environment", scenario.Step{Command: "unused", Env: map[string]string{"VALUE": unknown}}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			dir := t.TempDir()
			path := filepath.Join(dir, "scenario.json")
			value := scenario.Scenario{Version: 1, Name: "preparation-failure", Steps: map[string]scenario.Step{
				"first":  tc.step,
				"second": {Command: "unused", DependsOn: []string{"first"}},
			}}
			data, err := json.Marshal(value)
			if err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(path, data, 0o644); err != nil {
				t.Fatal(err)
			}
			outcome := Run(context.Background(), path, Options{RunsDir: filepath.Join(dir, "runs"), RunID: "failure"})
			if outcome.Err == nil || !strings.Contains(outcome.Err.Error(), "unknown variable") {
				t.Fatalf("expected expansion failure, got %v", outcome.Err)
			}
			loaded, err := manifest.Load(outcome.Layout.RunDir)
			if err != nil {
				t.Fatal(err)
			}
			step := loaded.Steps[0]
			if loaded.Status != protocol.StatusFailed || step.Status != protocol.StatusFailed || loaded.Steps[1].Status != protocol.StatusBlocked {
				t.Fatalf("unexpected manifest: %#v", loaded)
			}
			if step.StartedAt == nil || step.FinishedAt == nil {
				t.Fatal("preparation failure must record step timing")
			}
			if step.StartedAt.Before(loaded.StartedAt) || step.FinishedAt.Before(*step.StartedAt) || step.FinishedAt.After(*loaded.FinishedAt) {
				t.Fatal("step timing must fit within run timing")
			}
			if step.DurationMS != step.FinishedAt.Sub(*step.StartedAt).Milliseconds() || step.ExitCode != nil {
				t.Fatal("preparation failure must have attempt duration and no process exit code")
			}
			data, err = os.ReadFile(outcome.Layout.TelemetryPath)
			if err != nil {
				t.Fatal(err)
			}
			var states []string
			for _, line := range strings.Split(strings.TrimSpace(string(data)), "\n") {
				var event telemetry.Event
				if err := json.Unmarshal([]byte(line), &event); err != nil {
					t.Fatal(err)
				}
				if event.Step == "first" {
					states = append(states, event.State)
				}
			}
			if strings.Join(states, ",") != "running,failed" {
				t.Fatalf("unexpected step telemetry: %v", states)
			}
		})
	}
}

func TestEndToEndRun(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixture is Unix-specific")
	}
	dir := t.TempDir()
	scenarioPath := filepath.Join(dir, "scenario.yaml")
	text := `version: 1
name: e2e
seed: 7
working_directory: .
steps:
  write:
    command: sh
    args:
      - -c
      - printf 'seed=%s\\n' "${SEED}" > "${STEP_ARTIFACT_DIR}/value.txt"
    timeout_seconds: 5
    artifacts:
      - ${STEP_ARTIFACT_DIR}/value.txt
  read:
    command: sh
    depends_on:
      - write
    args:
      - -c
      - grep 'seed=7' "${RUN_DIR}/artifacts/write/value.txt"
    timeout_seconds: 5
`
	if err := os.WriteFile(scenarioPath, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
	outcome := Run(context.Background(), scenarioPath, Options{
		RunsDir: filepath.Join(dir, "runs"), RunID: "test-run",
	})
	if outcome.Err != nil {
		t.Fatal(outcome.Err)
	}
	if outcome.Manifest.Status != protocol.StatusSucceeded {
		t.Fatalf("unexpected status %s", outcome.Manifest.Status)
	}
	if len(outcome.Manifest.Steps) != 2 || len(outcome.Manifest.Steps[0].Artifacts) != 1 {
		t.Fatalf("unexpected manifest: %#v", outcome.Manifest)
	}
	loaded, err := manifest.Load(outcome.Layout.RunDir)
	if err != nil {
		t.Fatal(err)
	}
	if loaded.RunFingerprint != outcome.Manifest.RunFingerprint {
		t.Fatal("manifest fingerprint changed after persistence")
	}
}

func TestFailureBlocksRemainingSteps(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixture is Unix-specific")
	}
	dir := t.TempDir()
	path := filepath.Join(dir, "scenario.yaml")
	text := `version: 1
name: fail
seed: 1
steps:
  first:
    command: sh
    args:
      - -c
      - exit 3
  second:
    command: sh
    depends_on:
      - first
    args:
      - -c
      - exit 0
`
	_ = os.WriteFile(path, []byte(text), 0o644)
	outcome := Run(context.Background(), path, Options{RunsDir: filepath.Join(dir, "runs"), RunID: "fail-run"})
	if outcome.Err == nil {
		t.Fatal("expected failed run")
	}
	if outcome.Manifest.Steps[0].Status != protocol.StatusFailed || outcome.Manifest.Steps[1].Status != protocol.StatusBlocked {
		t.Fatalf("unexpected statuses: %#v", outcome.Manifest.Steps)
	}
}
