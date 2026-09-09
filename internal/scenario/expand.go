package scenario

import (
	"fmt"
	"os"
	"regexp"
)

var variablePattern = regexp.MustCompile(`\$\{([A-Za-z_][A-Za-z0-9_]*)\}`)

// Expand replaces explicit ${NAME} placeholders. Built-in values take
// precedence over process environment variables. Unknown names are errors.
func Expand(value string, builtins map[string]string) (string, error) {
	var expansionErr error
	result := variablePattern.ReplaceAllStringFunc(value, func(match string) string {
		name := variablePattern.FindStringSubmatch(match)[1]
		if replacement, ok := builtins[name]; ok {
			return replacement
		}
		if replacement, ok := os.LookupEnv(name); ok {
			return replacement
		}
		if expansionErr == nil {
			expansionErr = fmt.Errorf("unknown variable %s", match)
		}
		return match
	})
	return result, expansionErr
}
