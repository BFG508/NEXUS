package scenario

import (
	"os"
	"path/filepath"
	"testing"
)

func TestYAMLSubset(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "scenario.yaml")
	text := `version: 1
name: test
seed: 42
working_directory: .
steps:
  first:
    command: sh
    args:
      - -c
      - echo hello
    depends_on: []
    timeout_seconds: 3
    env:
      MODE: test
    artifacts:
      - ${STEP_ARTIFACT_DIR}/out.txt
`
	if err := os.WriteFile(path, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
	value, _, err := Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := Validate(value); err != nil {
		t.Fatal(err)
	}
	if value.Name != "test" || value.Seed != 42 {
		t.Fatalf("unexpected scenario: %#v", value)
	}
	step := value.Steps["first"]
	if len(step.Args) != 2 || step.Env["MODE"] != "test" || len(step.Artifacts) != 1 {
		t.Fatalf("unexpected step: %#v", step)
	}
}

func TestExpandRejectsUnknown(t *testing.T) {
	_, err := Expand("${DOES_NOT_EXIST_HERMES_TEST}", nil)
	if err == nil {
		t.Fatal("expected unknown-variable error")
	}
}
