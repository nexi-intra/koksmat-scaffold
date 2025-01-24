package magicapp

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"os/exec"
)

func ExecutePowerShell(cwd string) (err error) {
	cmd := exec.Command("pwsh", "-nologo", "-noprofile")

	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Fatal(err)
	}

	cmd.Dir = cwd

	pipe, _ := cmd.StdoutPipe()
	combinedOutput := []byte{}

	script := fmt.Sprintf(`
	$ErrorActionPreference = "Stop"
	. ./run.ps1 `)
	go func() {
		defer stdin.Close()

		fmt.Fprintln(stdin, script)

	}()

	err = cmd.Start()
	go func(p io.ReadCloser) {
		reader := bufio.NewReader(pipe)
		line, err := reader.ReadString('\n')
		for err == nil {
			log.Print(line)
			combinedOutput = append(combinedOutput, []byte(line)...)
			line, err = reader.ReadString('\n')
		}
	}(pipe)
	err = cmd.Wait()

	if err != nil {
		log.Println(fmt.Sprint(err) + ": " + string(combinedOutput))
		return errors.New("Could not run PowerShell script")
	}

	return nil
}
