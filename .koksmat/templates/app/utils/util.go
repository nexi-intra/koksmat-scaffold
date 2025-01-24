package utils

import (
	"fmt"
	"os"
	"path"
	"strings"
)

var Output string = ""

func PrintSkip2FirstAnd2LastLines(output string) {
	lines := strings.Split(output, "\n")
	if len(lines) > 4 {
		fmt.Println(strings.Join(lines[3:len(lines)-2], "\n"))
		return
	}
	fmt.Println(output)
}

func WorkDir(kitchenname string) string {
	if os.Getenv("WORKDIR") != "" {
		return os.Getenv("WORKDIR")
	}
	return path.Join(os.Getenv("KITCHENROOT"), kitchenname, ".koksmat", "workdir")
}
