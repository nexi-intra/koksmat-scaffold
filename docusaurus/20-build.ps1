<#---
title: Build Cache files for each Kitchens
description: Build Cache files for each Kitchens
connection: sharepoint
input: kitchens-found.json
output: kitchens-build.json
api: post
tag: buildcache
---#>


$kitchens = Get-Content "$env:WORKDIR/kitchens-found.json" | ConvertFrom-Json



foreach ($kitchen in $kitchens) {
    write-host  $kitchen.name  -ForegroundColor Green
    $kitchenStatus = koksmat kitchen stations $kitchen.name | ConvertFrom-Json
    $kitchensWithDetails = @{
        status     = $kitchenStatus
       scripts = @()

    }
    if ($kitchenStatus.stations -eq $null) {
        write-host "No stations found" -ForegroundColor Red
        continue
    }
    $kitchenStatus.stations | ForEach-Object {
        $station = $_
        if ($station.tag -eq "") {
            write-host "---", $ $station.tag -NoNewline -ForegroundColor Gray
            break
        }
        write-host "---", $ $station.tag -NoNewline -ForegroundColor DarkGreen
        $station.scripts | ForEach-Object {
            $script = $_
            write-host "|", $ $script.tag -NoNewline -ForegroundColor Green
            $scriptStatus = koksmat kitchen script meta $script.name --kitchen $kitchen.name --station $station.name  | ConvertFrom-Json
            $scriptHTML = koksmat kitchen script html $script.name --kitchen $kitchen.name --station $station.name  
         

            $kitchensWithDetails.scripts += @{
                route = "$($station.name)/$($script.name)"
                status = $scriptStatus
                html = $scriptHTML
            }
        }
        write-host ""
    }
  

    $kfilePath = "$env:WORKDIR/$($kitchen.name).kitchen.json"

    $kitchensWithDetails | ConvertTo-Json -Depth 10 |   Out-File -FilePath $kfilePath -Encoding utf8NoBOM
  
    write-host "read"
}




$result = "$env:WORKDIR/kitchens-build.json"
$kitchens | ConvertTo-Json -Depth 10 | Out-File -FilePath $result -Encoding utf8NoBOM