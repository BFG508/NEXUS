package artifact

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// Record is persisted in the HERMES run manifest for one declared artifact.
type Record struct {
	Path   string `json:"path"`
	Size   int64  `json:"size_bytes"`
	SHA256 string `json:"sha256"`
}

// Inspect verifies a regular file and calculates its SHA-256 digest.
func Inspect(path string) (Record, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return Record{}, err
	}
	info, err := os.Stat(absolute)
	if err != nil {
		return Record{}, err
	}
	if !info.Mode().IsRegular() {
		return Record{}, fmt.Errorf("declared artifact is not a regular file: %s", absolute)
	}
	file, err := os.Open(absolute)
	if err != nil {
		return Record{}, err
	}
	defer file.Close()
	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return Record{}, err
	}
	return Record{
		Path: absolute, Size: info.Size(), SHA256: hex.EncodeToString(hash.Sum(nil)),
	}, nil
}
