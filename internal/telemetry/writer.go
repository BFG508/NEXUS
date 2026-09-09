package telemetry

import (
	"encoding/json"
	"os"
	"sync"
	"time"
)

// Event is one append-only HERMES lifecycle event.
type Event struct {
	Timestamp time.Time `json:"timestamp"`
	RunID     string    `json:"run_id"`
	Step      string    `json:"step,omitempty"`
	State     string    `json:"state"`
	Message   string    `json:"message,omitempty"`
}

// Writer appends line-delimited JSON events.
type Writer struct {
	mu   sync.Mutex
	file *os.File
}

func Open(path string) (*Writer, error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return nil, err
	}
	return &Writer{file: file}, nil
}

func (w *Writer) Emit(event Event) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now().UTC()
	}
	data, err := json.Marshal(event)
	if err != nil {
		return err
	}
	if _, err := w.file.Write(append(data, '\n')); err != nil {
		return err
	}
	return w.file.Sync()
}

func (w *Writer) Close() error {
	return w.file.Close()
}
