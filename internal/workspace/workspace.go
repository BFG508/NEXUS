package workspace

import (
	"fmt"
	"os"
	"path/filepath"
)

// Layout contains all durable paths for one HERMES run.
type Layout struct {
	RunDir        string
	LogsDir       string
	ArtifactsDir  string
	ManifestPath  string
	TelemetryPath string
}

// Create constructs a new run directory and refuses to overwrite an existing run.
func Create(runsDir, runID string) (Layout, error) {
	if runID == "" {
		return Layout{}, fmt.Errorf("run ID cannot be empty")
	}
	absoluteRuns, err := filepath.Abs(runsDir)
	if err != nil {
		return Layout{}, err
	}
	runDir := filepath.Join(absoluteRuns, runID)
	if _, err := os.Stat(runDir); err == nil {
		return Layout{}, fmt.Errorf("run directory already exists: %s", runDir)
	} else if !os.IsNotExist(err) {
		return Layout{}, err
	}
	layout := Layout{
		RunDir:        runDir,
		LogsDir:       filepath.Join(runDir, "logs"),
		ArtifactsDir:  filepath.Join(runDir, "artifacts"),
		ManifestPath:  filepath.Join(runDir, "manifest.json"),
		TelemetryPath: filepath.Join(runDir, "telemetry.jsonl"),
	}
	for _, path := range []string{layout.LogsDir, layout.ArtifactsDir} {
		if err := os.MkdirAll(path, 0o755); err != nil {
			return Layout{}, err
		}
	}
	return layout, nil
}
