package magicapp

import (
	"os"

	"github.com/spf13/cobra"

	"github.com/magicbutton/365admin-publish/cmds"
	"github.com/magicbutton/365admin-publish/utils"
)

func RegisterCmds() {
	utils.RootCmd.PersistentFlags().StringVarP(&utils.Output, "output", "o", "", "Output format (json, yaml, xml, etc.)")

	healthCmd := &cobra.Command{
		Use:   "health",
		Short: "Health",
		Long:  `Describe the main purpose of this kitchen`,
	}
	HealthPingPostCmd := &cobra.Command{
		Use:   "ping  pong",
		Short: "Ping",
		Long:  `Simple ping endpoint`,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.HealthPingPost(ctx, args)
		},
	}
	healthCmd.AddCommand(HealthPingPostCmd)
	HealthCoreversionPostCmd := &cobra.Command{
		Use:   "coreversion ",
		Short: "Core Version",
		Long:  ``,
		Args:  cobra.MinimumNArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.HealthCoreversionPost(ctx, args)
		},
	}
	healthCmd.AddCommand(HealthCoreversionPostCmd)

	utils.RootCmd.AddCommand(healthCmd)
	authCmd := &cobra.Command{
		Use:   "auth",
		Short: "auth",
		Long:  `Describe the main purpose of this kitchen`,
	}
	AuthCreateAppPostCmd := &cobra.Command{
		Use:   "create-app  kitchenname",
		Short: "Create app",
		Long:  ``,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.AuthCreateAppPost(ctx, args)
		},
	}
	authCmd.AddCommand(AuthCreateAppPostCmd)

	utils.RootCmd.AddCommand(authCmd)
	kitchensCmd := &cobra.Command{
		Use:   "kitchens",
		Short: "docusaurus",
		Long:  `Describe the main purpose of this kitchen`,
	}
	KitchensScanPostCmd := &cobra.Command{
		Use:   "scan ",
		Short: "Build Index of Kitchens",
		Long:  ``,
		Args:  cobra.MinimumNArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.KitchensScanPost(ctx, args)
		},
	}
	kitchensCmd.AddCommand(KitchensScanPostCmd)
	KitchensBuildcachePostCmd := &cobra.Command{
		Use:   "buildcache ",
		Short: "Build Cache files for each Kitchens",
		Long:  `Build Cache files for each Kitchens`,
		Args:  cobra.MinimumNArgs(0),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()
			body, err := os.ReadFile(args[0])
			if err != nil {
				panic(err)
			}

			cmds.KitchensBuildcachePost(ctx, body, args)
		},
	}
	kitchensCmd.AddCommand(KitchensBuildcachePostCmd)
	KitchensPublishdocusaurusPostCmd := &cobra.Command{
		Use:   "publishdocusaurus  destinationKitchen",
		Short: "Build Cache files for each Kitchens",
		Long:  `Build Cache files for each Kitchens`,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.KitchensPublishdocusaurusPost(ctx, args)
		},
	}
	kitchensCmd.AddCommand(KitchensPublishdocusaurusPostCmd)

	utils.RootCmd.AddCommand(kitchensCmd)
	scaffoldCmd := &cobra.Command{
		Use:   "scaffold",
		Short: "scaffold",
		Long:  `Describe the main purpose of this kitchen`,
	}
	ScaffoldInitPostCmd := &cobra.Command{
		Use:   "init  kitchenname",
		Short: "Init",
		Long:  ``,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.ScaffoldInitPost(ctx, args)
		},
	}
	scaffoldCmd.AddCommand(ScaffoldInitPostCmd)
	ScaffoldInitwebPostCmd := &cobra.Command{
		Use:   "initweb  kitchenname",
		Short: "Init",
		Long:  ``,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.ScaffoldInitwebPost(ctx, args)
		},
	}
	scaffoldCmd.AddCommand(ScaffoldInitwebPostCmd)
	ScaffoldGenerateapiPostCmd := &cobra.Command{
		Use:   "generateapi  kitchenname",
		Short: "Generate API",
		Long:  ``,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.ScaffoldGenerateapiPost(ctx, args)
		},
	}
	scaffoldCmd.AddCommand(ScaffoldGenerateapiPostCmd)
	ScaffoldGeneratewebPostCmd := &cobra.Command{
		Use:   "generateweb  kitchenname",
		Short: "Generate Web",
		Long:  ``,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.ScaffoldGeneratewebPost(ctx, args)
		},
	}
	scaffoldCmd.AddCommand(ScaffoldGeneratewebPostCmd)
	ScaffoldBuildPostCmd := &cobra.Command{
		Use:   "build  kitchenname",
		Short: "Build",
		Long:  ``,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.ScaffoldBuildPost(ctx, args)
		},
	}
	scaffoldCmd.AddCommand(ScaffoldBuildPostCmd)
	ScaffoldGenerateappPostCmd := &cobra.Command{
		Use:   "generateapp  kitchenname verbose",
		Short: "Generate Microservice Integration Code",
		Long:  ``,
		Args:  cobra.MinimumNArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			ctx := cmd.Context()

			cmds.ScaffoldGenerateappPost(ctx, args)
		},
	}
	scaffoldCmd.AddCommand(ScaffoldGenerateappPostCmd)

	utils.RootCmd.AddCommand(scaffoldCmd)
}
