package magicapp

import (
	"os"

	"github.com/spf13/cobra"
)

var RootCmd = &cobra.Command{}

func Execute(use string, short string, long string) {
	RootCmd.Use = use
	RootCmd.Short = short
	RootCmd.Long = long
	err := RootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {

	//RootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
