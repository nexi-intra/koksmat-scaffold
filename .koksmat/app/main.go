package main

import (
	"runtime/debug"
	"strings"

	"github.com/magicbutton/365admin-publish/magicapp"
)

func main() {
	info, _ := debug.ReadBuildInfo()

	// split info.Main.Path by / and get the last element
	s1 := strings.Split(info.Main.Path, "/")
	name := s1[len(s1)-1]
	description := `Generates the REST API and CLI for any kitchen`

	magicapp.Setup(".env")
	magicapp.RegisterServeCmd("365admin-publish", description, "0.0.1", 8080)
	magicapp.RegisterCmds()
	magicapp.Execute(name, "365admin-publish", "")
}
