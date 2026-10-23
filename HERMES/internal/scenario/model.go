package scenario

// Scenario is the HERMES Scenario v1 execution definition.
type Scenario struct {
	Version          int             `json:"version"`
	Name             string          `json:"name"`
	Seed             int64           `json:"seed"`
	WorkingDirectory string          `json:"working_directory,omitempty"`
	Steps            map[string]Step `json:"steps"`
}

// Step is one external command in a scenario dependency graph.
type Step struct {
	Command        string            `json:"command"`
	Args           []string          `json:"args,omitempty"`
	DependsOn      []string          `json:"depends_on,omitempty"`
	TimeoutSeconds int               `json:"timeout_seconds,omitempty"`
	Env            map[string]string `json:"env,omitempty"`
	Artifacts      []string          `json:"artifacts,omitempty"`
}
