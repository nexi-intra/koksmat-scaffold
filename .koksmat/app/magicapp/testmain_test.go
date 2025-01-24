package magicapp

import (
	"os"
	"testing"
)

func TestMain(m *testing.M) {
	cwd, _ := os.Getwd()

	MakeEnvFile(cwd)
	Setup("./.env-test")
	code := m.Run()

	os.Exit(code)
}
