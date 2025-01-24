<#---
title: Publish
description: Publish all kitchens 
connection: sharepoint
input: kitchens-build.json
output: kitchens-published.json
xapi: post
tag: publish
---#>


$kitchens = Get-Content "$env:WORKDIR/kitchens-build.json" | ConvertFrom-Json







$result = "$env:WORKDIR/kitchens-published.json"
$kitchens | ConvertTo-Json -Depth 10 | Out-File -FilePath $result -Encoding utf8NoBOM