// -------------------------------------------------------------------
// Generated by 365admin-publish/api/20 makeschema.ps1
// -------------------------------------------------------------------
/*
---
title: Init
---
*/
package endpoints

import (
	"context"

	"github.com/swaggest/usecase"

	"github.com/magicbutton/365admin-publish/execution"
)

func ScaffoldInitwebPost() usecase.Interactor {
	type Request struct {
		Kitchenname string `query:"kitchenname" binding:"required"`
	}
	u := usecase.NewInteractor(func(ctx context.Context, input Request, output *string) error {

		_, err := execution.ExecutePowerShell("john", "*", "365admin-publish", "scaffold", "01-initweb.ps1", "", "-kitchenname", input.Kitchenname)
		if err != nil {
			return err
		}

		return err

	})
	u.SetTitle("Init")
	// u.SetExpectedErrors(status.InvalidArgument)
	u.SetTags("scaffold")
	return u
}
