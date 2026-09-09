package executor

import (
	"context"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"
)

func TestRunCapturesExitCode(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixture is Unix-specific")
	}
	dir := t.TempDir()
	stdout, err := os.Create(filepath.Join(dir, "stdout"))
	if err != nil {
		t.Fatal(err)
	}
	defer stdout.Close()
	stderr, err := os.Create(filepath.Join(dir, "stderr"))
	if err != nil {
		t.Fatal(err)
	}
	defer stderr.Close()

	result := Run(context.Background(), Request{
		Command: "sh", Args: []string{"-c", "printf ok"}, Directory: dir,
		Timeout: time.Second, Stdout: stdout, Stderr: stderr,
	})
	if result.Err != nil || result.ExitCode != 0 || result.TimedOut {
		t.Fatalf("unexpected result: %#v", result)
	}
}

func TestTimeout(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("shell fixture is Unix-specific")
	}
	dir := t.TempDir()
	stdout, _ := os.Create(filepath.Join(dir, "stdout"))
	defer stdout.Close()
	stderr, _ := os.Create(filepath.Join(dir, "stderr"))
	defer stderr.Close()

	result := Run(context.Background(), Request{
		Command: "sh", Args: []string{"-c", "sleep 2"}, Directory: dir,
		Timeout: 50 * time.Millisecond, Stdout: stdout, Stderr: stderr,
	})
	if !result.TimedOut {
		t.Fatalf("expected timeout, got %#v", result)
	}
}
