<#---
title: Install Go app
tag: go
---




All dependencies for the Go app will be installed and the app will be build.

#>



if ((Split-Path -Leaf (Split-Path  -Parent -Path $PSScriptRoot)) -eq "sessions"){
    $path = join-path $PSScriptRoot ".." ".."
}
else{
  $path = join-path $PSScriptRoot ".." ".koksmat/"

}

$koksmatDir = Resolve-Path $path

Set-Location (join-path $koksmatDir "app")

go install