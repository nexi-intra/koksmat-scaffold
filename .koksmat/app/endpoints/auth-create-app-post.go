// -------------------------------------------------------------------
// Generated by 365admin-publish/api/20 makeschema.ps1
// -------------------------------------------------------------------
/*
---
title: Create app
---
*/
package endpoints

import (
	"context"

	"github.com/swaggest/usecase"

	"github.com/magicbutton/365admin-publish/execution"
)

func AuthCreateAppPost() usecase.Interactor {
	type Request struct {
		Kitchenname string `query:"kitchenname" binding:"required"`
	}
	u := usecase.NewInteractor(func(ctx context.Context, input Request, output *string) error {

		_, err := execution.ExecutePowerShell("john", "*", "365admin-publish", "auth", "10-create-app.ps1", "", "-kitchenname", input.Kitchenname)
		if err != nil {
			return err
		}

		return err

	})
	u.SetTitle("Create app")
	// u.SetExpectedErrors(status.InvalidArgument)
	u.SetTags("auth")
	return u
}
