package cmds

import (
	"os"
	"path/filepath"
)

func GetDirectory(kitchenname string) string {

	if (kitchenname == ".") || (kitchenname == "") {
		cwd, _ := os.Getwd()
		return filepath.Base(cwd)
	}

	return kitchenname
}
