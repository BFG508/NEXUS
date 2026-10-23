package scenario

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// Load reads a Scenario v1 file. JSON is decoded directly; .yaml/.yml files
// use HERMES's deliberately constrained Scenario YAML subset.
func Load(path string) (Scenario, []byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Scenario{}, nil, err
	}
	var value Scenario
	trimmed := bytes.TrimSpace(data)
	if len(trimmed) == 0 {
		return Scenario{}, data, fmt.Errorf("scenario is empty")
	}
	if trimmed[0] == '{' || strings.EqualFold(filepath.Ext(path), ".json") {
		if err := json.Unmarshal(data, &value); err != nil {
			return Scenario{}, data, fmt.Errorf("decode JSON scenario: %w", err)
		}
	} else {
		value, err = parseYAMLSubset(data)
		if err != nil {
			return Scenario{}, data, err
		}
	}
	return value, data, nil
}

func parseYAMLSubset(data []byte) (Scenario, error) {
	value := Scenario{Steps: map[string]Step{}}
	scanner := bufio.NewScanner(bytes.NewReader(data))
	lineNo := 0
	section := ""
	currentStep := ""
	stepSubsection := ""

	for scanner.Scan() {
		lineNo++
		raw := strings.TrimRight(scanner.Text(), " \t\r")
		if strings.Contains(raw, "\t") {
			return Scenario{}, yamlError(lineNo, "tabs are not supported; use spaces")
		}
		content := stripComment(raw)
		if strings.TrimSpace(content) == "" {
			continue
		}
		indent := leadingSpaces(content)
		text := strings.TrimSpace(content)

		switch indent {
		case 0:
			currentStep = ""
			stepSubsection = ""
			key, scalar, ok := splitKeyValue(text)
			if !ok {
				return Scenario{}, yamlError(lineNo, "expected top-level key: value")
			}
			switch key {
			case "version":
				n, err := strconv.Atoi(unquoteScalar(scalar))
				if err != nil {
					return Scenario{}, yamlError(lineNo, "version must be an integer")
				}
				value.Version = n
				section = ""
			case "name":
				value.Name = unquoteScalar(scalar)
				section = ""
			case "seed":
				n, err := strconv.ParseInt(unquoteScalar(scalar), 10, 64)
				if err != nil {
					return Scenario{}, yamlError(lineNo, "seed must be an integer")
				}
				value.Seed = n
				section = ""
			case "working_directory":
				value.WorkingDirectory = unquoteScalar(scalar)
				section = ""
			case "steps":
				if strings.TrimSpace(scalar) != "" {
					return Scenario{}, yamlError(lineNo, "steps must be a block mapping")
				}
				section = "steps"
			default:
				return Scenario{}, yamlError(lineNo, fmt.Sprintf("unsupported top-level key %q", key))
			}

		case 2:
			if section != "steps" {
				return Scenario{}, yamlError(lineNo, "2-space indentation is only valid under steps")
			}
			if !strings.HasSuffix(text, ":") || strings.Contains(strings.TrimSuffix(text, ":"), ":") {
				return Scenario{}, yamlError(lineNo, "expected step_name:")
			}
			currentStep = strings.TrimSpace(strings.TrimSuffix(text, ":"))
			if currentStep == "" {
				return Scenario{}, yamlError(lineNo, "step name cannot be empty")
			}
			if _, exists := value.Steps[currentStep]; exists {
				return Scenario{}, yamlError(lineNo, fmt.Sprintf("duplicate step %q", currentStep))
			}
			value.Steps[currentStep] = Step{Env: map[string]string{}}
			stepSubsection = ""

		case 4:
			if section != "steps" || currentStep == "" {
				return Scenario{}, yamlError(lineNo, "4-space indentation requires an active step")
			}
			key, scalar, ok := splitKeyValue(text)
			if !ok {
				return Scenario{}, yamlError(lineNo, "expected step property key: value")
			}
			step := value.Steps[currentStep]
			switch key {
			case "command":
				step.Command = unquoteScalar(scalar)
				stepSubsection = ""
			case "timeout_seconds":
				n, err := strconv.Atoi(unquoteScalar(scalar))
				if err != nil {
					return Scenario{}, yamlError(lineNo, "timeout_seconds must be an integer")
				}
				step.TimeoutSeconds = n
				stepSubsection = ""
			case "args", "depends_on", "artifacts":
				if strings.TrimSpace(scalar) == "" {
					stepSubsection = key
				} else {
					items, err := parseInlineList(scalar)
					if err != nil {
						return Scenario{}, yamlError(lineNo, err.Error())
					}
					setList(&step, key, items)
					stepSubsection = ""
				}
			case "env":
				if strings.TrimSpace(scalar) != "" {
					return Scenario{}, yamlError(lineNo, "env must be a block mapping")
				}
				stepSubsection = "env"
			default:
				return Scenario{}, yamlError(lineNo, fmt.Sprintf("unsupported step property %q", key))
			}
			value.Steps[currentStep] = step

		case 6:
			if section != "steps" || currentStep == "" || stepSubsection == "" {
				return Scenario{}, yamlError(lineNo, "unexpected 6-space indentation")
			}
			step := value.Steps[currentStep]
			if stepSubsection == "env" {
				key, scalar, ok := splitKeyValue(text)
				if !ok || key == "" {
					return Scenario{}, yamlError(lineNo, "expected environment KEY: value")
				}
				if step.Env == nil {
					step.Env = map[string]string{}
				}
				step.Env[key] = unquoteScalar(scalar)
			} else {
				if !strings.HasPrefix(text, "- ") && text != "-" {
					return Scenario{}, yamlError(lineNo, fmt.Sprintf("expected '- value' under %s", stepSubsection))
				}
				item := ""
				if text != "-" {
					item = unquoteScalar(strings.TrimSpace(strings.TrimPrefix(text, "-")))
				}
				if item == "" {
					return Scenario{}, yamlError(lineNo, "list item cannot be empty")
				}
				appendList(&step, stepSubsection, item)
			}
			value.Steps[currentStep] = step

		default:
			return Scenario{}, yamlError(lineNo, fmt.Sprintf("unsupported indentation level %d", indent))
		}
	}
	if err := scanner.Err(); err != nil {
		return Scenario{}, err
	}
	return value, nil
}

func yamlError(line int, message string) error {
	return fmt.Errorf("scenario YAML line %d: %s", line, message)
}

func leadingSpaces(s string) int {
	return len(s) - len(strings.TrimLeft(s, " "))
}

func splitKeyValue(s string) (string, string, bool) {
	idx := strings.IndexByte(s, ':')
	if idx < 0 {
		return "", "", false
	}
	return strings.TrimSpace(s[:idx]), strings.TrimSpace(s[idx+1:]), true
}

func stripComment(s string) string {
	var quote rune
	escaped := false
	for i, r := range s {
		if escaped {
			escaped = false
			continue
		}
		if r == '\\' && quote == '"' {
			escaped = true
			continue
		}
		if quote != 0 {
			if r == quote {
				quote = 0
			}
			continue
		}
		if r == '\'' || r == '"' {
			quote = r
			continue
		}
		if r == '#' {
			return strings.TrimRight(s[:i], " ")
		}
	}
	return s
}

func unquoteScalar(s string) string {
	s = strings.TrimSpace(s)
	if len(s) >= 2 && s[0] == '"' && s[len(s)-1] == '"' {
		if value, err := strconv.Unquote(s); err == nil {
			return value
		}
	}
	if len(s) >= 2 && s[0] == '\'' && s[len(s)-1] == '\'' {
		return strings.ReplaceAll(s[1:len(s)-1], "''", "'")
	}
	return s
}

func parseInlineList(s string) ([]string, error) {
	s = strings.TrimSpace(s)
	if s == "[]" {
		return nil, nil
	}
	if len(s) < 2 || s[0] != '[' || s[len(s)-1] != ']' {
		return nil, fmt.Errorf("inline list must use [item, item]")
	}
	body := strings.TrimSpace(s[1 : len(s)-1])
	if body == "" {
		return nil, nil
	}
	parts := strings.Split(body, ",")
	items := make([]string, 0, len(parts))
	for _, part := range parts {
		item := unquoteScalar(part)
		if item == "" {
			return nil, fmt.Errorf("inline list contains an empty item")
		}
		items = append(items, item)
	}
	return items, nil
}

func setList(step *Step, key string, items []string) {
	switch key {
	case "args":
		step.Args = items
	case "depends_on":
		step.DependsOn = items
	case "artifacts":
		step.Artifacts = items
	}
}

func appendList(step *Step, key, item string) {
	switch key {
	case "args":
		step.Args = append(step.Args, item)
	case "depends_on":
		step.DependsOn = append(step.DependsOn, item)
	case "artifacts":
		step.Artifacts = append(step.Artifacts, item)
	}
}
