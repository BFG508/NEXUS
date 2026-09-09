package manifest

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/BFG508/NEXUS/HERMES/internal/artifact"
	"github.com/BFG508/NEXUS/HERMES/internal/reproducibility"
	"github.com/BFG508/NEXUS/HERMES/pkg/protocol"
)

const Schema = "hermes.run_manifest.v1"

// ScenarioRecord captures immutable scenario provenance for a run.
type ScenarioRecord struct {
	Name   string `json:"name"`
	Path   string `json:"path"`
	SHA256 string `json:"sha256"`
	Seed   int64  `json:"seed"`
}

// StepRecord captures one planned/executed step.
type StepRecord struct {
	Name        string            `json:"name"`
	Status      protocol.Status   `json:"status"`
	DependsOn   []string          `json:"depends_on,omitempty"`
	Command     string            `json:"command,omitempty"`
	Args        []string          `json:"args,omitempty"`
	Environment map[string]string `json:"environment_overrides,omitempty"`
	StartedAt   *time.Time        `json:"started_at,omitempty"`
	FinishedAt  *time.Time        `json:"finished_at,omitempty"`
	DurationMS  int64             `json:"duration_ms,omitempty"`
	ExitCode    *int              `json:"exit_code,omitempty"`
	TimedOut    bool              `json:"timed_out,omitempty"`
	StdoutLog   string            `json:"stdout_log,omitempty"`
	StderrLog   string            `json:"stderr_log,omitempty"`
	Artifacts   []artifact.Record `json:"artifacts,omitempty"`
	Error       string            `json:"error,omitempty"`
}

// RunManifest is the durable HERMES v0.1.0 run record.
type RunManifest struct {
	Schema           string                  `json:"schema"`
	HermesVersion    string                  `json:"hermes_version"`
	RunID            string                  `json:"run_id"`
	RunFingerprint   string                  `json:"run_fingerprint"`
	Status           protocol.Status         `json:"status"`
	Scenario         ScenarioRecord          `json:"scenario"`
	WorkingDirectory string                  `json:"working_directory"`
	Runtime          reproducibility.Runtime `json:"runtime"`
	StartedAt        time.Time               `json:"started_at"`
	FinishedAt       *time.Time              `json:"finished_at,omitempty"`
	TelemetryPath    string                  `json:"telemetry_path"`
	Steps            []StepRecord            `json:"steps"`
}

func WriteAtomic(path string, value RunManifest) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	data = append(data, '\n')
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

func Load(path string) (RunManifest, error) {
	info, err := os.Stat(path)
	if err != nil {
		return RunManifest{}, err
	}
	if info.IsDir() {
		path = filepath.Join(path, "manifest.json")
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return RunManifest{}, err
	}
	var value RunManifest
	if err := json.Unmarshal(data, &value); err != nil {
		return RunManifest{}, err
	}
	if value.Schema != Schema {
		return RunManifest{}, fmt.Errorf("unsupported manifest schema %q", value.Schema)
	}
	return value, nil
}
