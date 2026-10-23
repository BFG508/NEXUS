package executor

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"time"
)

// Request describes one local process execution.
type Request struct {
	Command   string
	Args      []string
	Directory string
	Env       map[string]string
	Timeout   time.Duration
	Stdout    *os.File
	Stderr    *os.File
}

// Result captures observable process completion information.
type Result struct {
	ExitCode int
	TimedOut bool
	Err      error
}

// Run executes one local process with an optional timeout.
func Run(parent context.Context, request Request) Result {
	ctx := parent
	cancel := func() {}
	if request.Timeout > 0 {
		ctx, cancel = context.WithTimeout(parent, request.Timeout)
	}
	defer cancel()

	cmd := exec.CommandContext(ctx, request.Command, request.Args...)
	cmd.Dir = request.Directory
	cmd.Stdout = request.Stdout
	cmd.Stderr = request.Stderr
	cmd.Env = mergedEnvironment(request.Env)

	err := cmd.Run()
	result := Result{Err: err, ExitCode: 0}
	if cmd.ProcessState != nil {
		result.ExitCode = cmd.ProcessState.ExitCode()
	} else if err != nil {
		result.ExitCode = -1
	}
	if errors.Is(ctx.Err(), context.DeadlineExceeded) {
		result.TimedOut = true
	}
	return result
}

func mergedEnvironment(overrides map[string]string) []string {
	env := os.Environ()
	index := make(map[string]int, len(env))
	for i, item := range env {
		for j := 0; j < len(item); j++ {
			if item[j] == '=' {
				index[item[:j]] = i
				break
			}
		}
	}
	for key, value := range overrides {
		entry := key + "=" + value
		if i, ok := index[key]; ok {
			env[i] = entry
		} else {
			env = append(env, entry)
		}
	}
	return env
}
