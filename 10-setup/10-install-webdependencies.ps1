<#---
title: Install Web app
tag: web
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
$env:NODE_ENV="development"
Set-Location (join-path $koksmatDir "web")

pnpm install
pnpm build