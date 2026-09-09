package graph

import (
	"errors"
	"fmt"
	"sort"
)

var ErrCycle = errors.New("dependency graph contains a cycle")

// TopologicalOrder returns a deterministic lexical topological order.
func TopologicalOrder(dependencies map[string][]string) ([]string, error) {
	indegree := make(map[string]int, len(dependencies))
	dependents := make(map[string][]string, len(dependencies))

	for node := range dependencies {
		indegree[node] = 0
	}
	for node, deps := range dependencies {
		seen := map[string]bool{}
		for _, dep := range deps {
			if _, ok := dependencies[dep]; !ok {
				return nil, fmt.Errorf("%s depends on unknown node %s", node, dep)
			}
			if seen[dep] {
				continue
			}
			seen[dep] = true
			indegree[node]++
			dependents[dep] = append(dependents[dep], node)
		}
	}

	ready := make([]string, 0)
	for node, degree := range indegree {
		if degree == 0 {
			ready = append(ready, node)
		}
	}
	sort.Strings(ready)

	order := make([]string, 0, len(dependencies))
	for len(ready) > 0 {
		node := ready[0]
		ready = ready[1:]
		order = append(order, node)
		sort.Strings(dependents[node])
		for _, child := range dependents[node] {
			indegree[child]--
			if indegree[child] == 0 {
				ready = append(ready, child)
				sort.Strings(ready)
			}
		}
	}

	if len(order) != len(dependencies) {
		return nil, ErrCycle
	}
	return order, nil
}
