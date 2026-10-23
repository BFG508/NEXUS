package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/BFG508/NEXUS/HERMES/internal/manifest"
	"github.com/BFG508/NEXUS/HERMES/internal/runner"
	"github.com/BFG508/NEXUS/HERMES/pkg/protocol"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	var err error
	switch os.Args[1] {
	case "version":
		fmt.Println(runner.Version)
		return
	case "validate":
		err = validateCommand(os.Args[2:])
	case "plan":
		err = planCommand(os.Args[2:])
	case "run":
		err = runCommand(os.Args[2:])
	case "inspect":
		err = inspectCommand(os.Args[2:])
	case "help", "-h", "--help":
		usage()
		return
	default:
		fmt.Fprintf(os.Stderr, "unknown command %q\n", os.Args[1])
		usage()
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "HERMES:", err)
		os.Exit(1)
	}
}

func validateCommand(args []string) error {
	fs := flag.NewFlagSet("validate", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() != 1 {
		return fmt.Errorf("usage: hermes validate <scenario>")
	}
	value, _, order, err := runner.Plan(fs.Arg(0))
	if err != nil {
		return err
	}
	fmt.Printf("[OK] %s: %d steps, valid DAG\n", value.Name, len(order))
	return nil
}

func planCommand(args []string) error {
	fs := flag.NewFlagSet("plan", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() != 1 {
		return fmt.Errorf("usage: hermes plan <scenario>")
	}
	value, _, order, err := runner.Plan(fs.Arg(0))
	if err != nil {
		return err
	}
	fmt.Printf("Scenario: %s\n", value.Name)
	for i, name := range order {
		fmt.Printf("%d. %s\n", i+1, name)
	}
	return nil
}

func runCommand(args []string) error {
	fs := flag.NewFlagSet("run", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	runsDir := fs.String("runs-dir", "", "directory that will contain HERMES run directories")
	runID := fs.String("run-id", "", "explicit unique run identifier")
	seedText := fs.String("seed", "", "override scenario seed")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() != 1 {
		return fmt.Errorf("usage: hermes run [--runs-dir PATH] [--run-id ID] [--seed N] <scenario>")
	}
	var seed *int64
	if *seedText != "" {
		value, err := strconv.ParseInt(*seedText, 10, 64)
		if err != nil {
			return fmt.Errorf("invalid --seed: %w", err)
		}
		seed = &value
	}
	outcome := runner.Run(context.Background(), fs.Arg(0), runner.Options{
		RunsDir: *runsDir, RunID: *runID, SeedOverride: seed,
	})
	if outcome.Layout.RunDir != "" {
		fmt.Println("run_dir:", outcome.Layout.RunDir)
		fmt.Println("manifest:", outcome.Layout.ManifestPath)
		if outcome.Manifest.RunFingerprint != "" {
			fmt.Println("fingerprint:", outcome.Manifest.RunFingerprint)
		}
	}
	return outcome.Err
}

func inspectCommand(args []string) error {
	fs := flag.NewFlagSet("inspect", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() != 1 {
		return fmt.Errorf("usage: hermes inspect <run-directory|manifest.json>")
	}
	value, err := manifest.Load(fs.Arg(0))
	if err != nil {
		return err
	}
	fmt.Printf("HERMES %s run %s\n", value.HermesVersion, value.RunID)
	fmt.Printf("scenario: %s\n", value.Scenario.Name)
	fmt.Printf("seed: %d\n", value.Scenario.Seed)
	fmt.Printf("fingerprint: %s\n", value.RunFingerprint)
	fmt.Printf("status: %s\n", value.Status)
	fmt.Printf("started: %s\n", value.StartedAt.Format(time.RFC3339Nano))
	if value.FinishedAt != nil {
		fmt.Printf("finished: %s\n", value.FinishedAt.Format(time.RFC3339Nano))
	}
	for _, step := range value.Steps {
		marker := " "
		if step.Status == protocol.StatusSucceeded {
			marker = "✓"
		} else if step.Status == protocol.StatusFailed {
			marker = "✗"
		} else if step.Status == protocol.StatusBlocked {
			marker = "-"
		}
		fmt.Printf("%s %-24s %-10s %d ms\n", marker, step.Name, step.Status, step.DurationMS)
	}
	return nil
}

func usage() {
	fmt.Fprintln(os.Stderr, `HERMES - heterogeneous local workflow orchestrator

Usage:
  hermes version
  hermes validate <scenario>
  hermes plan <scenario>
  hermes run [--runs-dir PATH] [--run-id ID] [--seed N] <scenario>
  hermes inspect <run-directory|manifest.json>`)
}
