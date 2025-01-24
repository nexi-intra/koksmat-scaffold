<#---
title: Step 1
tag: step1
---#>

# Step 1


if ((Split-Path -Leaf (Split-Path  -Parent -Path $PSScriptRoot)) -eq "sessions"){
    $path = join-path $PSScriptRoot ".." ".."
}
else{
  $path = join-path $PSScriptRoot ".." ".koksmat/"

}

$koksmatDir = Resolve-Path $path
$env:NODE_ENV="development"
Set-Location (join-path $koksmatDir "web")

pnpm build