<#---
title: Build Index of Kitchens
connection: sharepoint
output: kitchens-found.json
api: post
tag: scan
---#>
$result = "$env:WORKDIR/kitchens-found.json"

$kitchens = koksmat kitchen list

$kitchens  | Out-File -FilePath $result -Encoding utf8NoBOM