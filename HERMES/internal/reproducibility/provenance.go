package reproducibility

import (
	"crypto/sha256"
	"encoding/hex"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
)

// Runtime records the local execution environment without serializing secrets.
type Runtime struct {
	GoVersion string `json:"go_version"`
	OS        string `json:"os"`
	Arch      string `json:"arch"`
	GitCommit string `json:"git_commit,omitempty"`
	GitDirty  *bool  `json:"git_dirty,omitempty"`
}

func SHA256(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

// Fingerprint is deterministic for one scenario content hash and effective seed.
func Fingerprint(scenarioSHA string, seed int64) string {
	raw := []byte(scenarioSHA + ":" + formatSeed(seed))
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func Environment(workingDirectory string) Runtime {
	value := Runtime{GoVersion: runtime.Version(), OS: runtime.GOOS, Arch: runtime.GOARCH}
	if commit, err := gitOutput(workingDirectory, "rev-parse", "HEAD"); err == nil {
		value.GitCommit = commit
		if status, err := gitOutput(workingDirectory, "status", "--porcelain"); err == nil {
			dirty := strings.TrimSpace(status) != ""
			value.GitDirty = &dirty
		}
	}
	return value
}

func gitOutput(directory string, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = directory
	out, err := cmd.Output()
	return strings.TrimSpace(string(out)), err
}

func formatSeed(seed int64) string {
	return strconv.FormatInt(seed, 10)
}
