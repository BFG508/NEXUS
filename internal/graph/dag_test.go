package graph

import (
	"errors"
	"reflect"
	"testing"
)

func TestTopologicalOrder(t *testing.T) {
	deps := map[string][]string{
		"astra": nil,
		"gaia":  {"astra"},
		"beam":  {"astra"},
		"levi":  {"beam", "gaia"},
	}
	got, err := TopologicalOrder(deps)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"astra", "beam", "gaia", "levi"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestCycle(t *testing.T) {
	_, err := TopologicalOrder(map[string][]string{"a": {"b"}, "b": {"a"}})
	if !errors.Is(err, ErrCycle) {
		t.Fatalf("expected ErrCycle, got %v", err)
	}
}
