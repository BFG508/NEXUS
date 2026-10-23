package scenario

import (
	"fmt"
	"regexp"
	"sort"
)

var stepNamePattern = regexp.MustCompile(`^[A-Za-z0-9._-]+$`)

// Validate performs Scenario v1 structural and semantic validation.
func Validate(value Scenario) error {
	if value.Version != 1 {
		return fmt.Errorf("unsupported scenario version %d; HERMES v0.1.0 supports version 1", value.Version)
	}
	if value.Name == "" {
		return fmt.Errorf("scenario name is required")
	}
	if len(value.Steps) == 0 {
		return fmt.Errorf("scenario must contain at least one step")
	}

	names := make([]string, 0, len(value.Steps))
	for name := range value.Steps {
		names = append(names, name)
	}
	sort.Strings(names)

	for _, name := range names {
		step := value.Steps[name]
		if !stepNamePattern.MatchString(name) {
			return fmt.Errorf("step %q has invalid name; use letters, numbers, '.', '_' or '-'", name)
		}
		if step.Command == "" {
			return fmt.Errorf("step %q: command is required", name)
		}
		if step.TimeoutSeconds < 0 {
			return fmt.Errorf("step %q: timeout_seconds cannot be negative", name)
		}
		seen := map[string]bool{}
		for _, dep := range step.DependsOn {
			if dep == name {
				return fmt.Errorf("step %q cannot depend on itself", name)
			}
			if _, ok := value.Steps[dep]; !ok {
				return fmt.Errorf("step %q depends on unknown step %q", name, dep)
			}
			if seen[dep] {
				return fmt.Errorf("step %q repeats dependency %q", name, dep)
			}
			seen[dep] = true
		}
	}
	return nil
}
