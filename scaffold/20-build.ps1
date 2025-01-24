<#---
connection: sharepoint
title: Build
tag: build
api: post
---#>
param (
	$kitchenname = "365admin-publish"
)

$ErrorActionPreference = "Stop"
Push-Location 
Set-Location  "$($ENV:KITCHENROOT)/$kitchenname"
go mod tidy
go install
Pop-Location

# . $kitchenname