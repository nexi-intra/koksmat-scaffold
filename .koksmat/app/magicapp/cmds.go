package magicapp

import (
	"fmt"
	"log"
	"net/http"
	"runtime/debug"
	"strings"

	"github.com/spf13/cobra"
	"github.com/swaggest/rest/web"
	swgui "github.com/swaggest/swgui/v4emb"

	"github.com/magicbutton/365admin-publish/endpoints"
	"github.com/magicbutton/365admin-publish/utils"
)

func StartAPIServer(title string, version string, description string, port int) {
	info, _ := debug.ReadBuildInfo()

	// split info.Main.Path by / and get the last element
	s1 := strings.Split(info.Main.Path, "/")
	name := s1[len(s1)-1]
	root := fmt.Sprintf("/v1/%s", name)
	docs := fmt.Sprintf("%s/docs", root)
	s := web.DefaultService()

	// Init API documentation schema.
	s.OpenAPI.Info.Title = title
	s.OpenAPI.Info.WithDescription(description)
	s.OpenAPI.Info.Version = version

	// sharedSettings(s)
	endpoints.AddEndpoints(s, Authenticator)
	// addAdminEndpoints(s, Authenticator)
	// addExchangeEndpoints(s, Authenticator)
	// addCoreEndpoints(s, Authenticator)
	s.Docs(docs, swgui.New)
	log.Printf("Server started, read documentation at http://localhost:%d%s", port, docs)
	if err := http.ListenAndServe(fmt.Sprintf(":%d", port), s); err != nil {
		log.Fatal(err)
	}
}

func RegisterServeCmd(title string, description string, version string, port int) {
	listCmd := &cobra.Command{
		Use:   "serve",
		Short: "Serve the API",
		Long:  `Serve the API`,
		Run: func(cmd *cobra.Command, args []string) {
			StartAPIServer(title, version, description, port)
		},
	}
	utils.RootCmd.AddCommand(listCmd)
}
