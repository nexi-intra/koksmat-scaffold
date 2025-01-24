<#---
title: Upgrade v2
---

#>

$root = $env:KITCHENROOT

$dirs = Get-ChildItem -Path $root -Directory

foreach ($dir in $dirs) {
    $dirName = $dir.Name
    $dirPath = $dir.FullName

    write-host $dirName

    365admin-publish scaffold generateapi $dirName 
    
}