package execution

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
)

func ExecutePowerShell(authentication string, authorization string, kitchen string, station string, scriptname string, journey string, args ...string) (string, error) {
	// info, _ := debug.ReadBuildInfo()

	// // split info.Main.Path by / and get the last element
	// s1 := strings.Split(info.Main.Path, "/")
	// name := s1[len(s1)-1]
	cmd1 := exec.Command("koksmat", "kitchen", "script", "setup", scriptname, "--kitchen", kitchen, "--station", station)
	sessionPath, err := cmd1.CombinedOutput()
	if err != nil {

		return "", errors.New("could not run powershell script")
	}
	sessionPath2 := strings.Replace(string(sessionPath), "\n", "", -1)
	scriptPath := path.Join(string(sessionPath2), "run.ps1")

	ps1, err := os.ReadFile(scriptPath)
	if err != nil {

		return "", errors.New("could not run powershell script")
	}
	code := string(ps1)
	ps1args := strings.Join(args, " ")

	newcode := strings.ReplaceAll(code, "##ARGS##", ps1args)
	//log.Println(newcode)
	err = os.WriteFile(scriptPath, []byte(newcode), 0644)

	if err != nil {

		return "", errors.New("could not run powershell script")
	}

	cmd := exec.Command("pwsh", "-f", "run.ps1", "-nologo", "-noprofile")

	cmd.Dir = sessionPath2

	pipe, _ := cmd.StdoutPipe()
	combinedOutput := []byte{}

	err = cmd.Start()
	go func(p io.ReadCloser) {
		reader := bufio.NewReader(pipe)
		line, err := reader.ReadString('\n')
		for err == nil {
			//log.Print(line)
			combinedOutput = append(combinedOutput, []byte(line)...)
			line, err = reader.ReadString('\n')
		}
	}(pipe)
	err = cmd.Wait()

	if err != nil {
		log.Println(fmt.Sprint(err), sessionPath2) //+ ": " + string(combinedOutput))
		return "", errors.New("Could not run PowerShell script")
	}

	return string(combinedOutput), nil
}
