<#---
title: Generate Web
api: post
tag: generateweb
---#>


param (
    $kitchenname = "nexi-infocast"
)


function EnsurePath($path) {
    if (-not (Test-Path $path)) {
        write-host "Creating directory  $path"
        $x = New-Item -Path  $path -ItemType Directory 
    }
    return $path
}

function SanitizeCode($cmd) {
    $cmd = [string]$cmd.Replace('.', '')
    $elements = $cmd -split '-'
    $TextInfo = (Get-Culture).TextInfo
    $elements = $elements | ForEach-Object { $TextInfo.ToTitleCase($_) }
    $cmd = $elements -join ''
    $cmd = [regex]::Replace($cmd, "([\W]+)", "")
    return $cmd
}
function SanitizeCmd($cmd) {
    $cmd = [string]$cmd.Replace('.json', '')
    $cmd = [string]$cmd.Replace('.', '-')
    $elements = $cmd -split '-'
    $TextInfo = (Get-Culture).TextInfo
    $elements = $elements | ForEach-Object { $TextInfo.ToTitleCase($_) }
    $cmd = $elements -join ''
    $cmd = [regex]::Replace($cmd, "([\W]+)", "")
    return $cmd
}

$webPath = join-path $ENV:KITCHENROOT $kitchenname ".koksmat" "web" 
if (-not (Test-Path $webPath)) {
    write-host "File webPath  does not exist" -ForegroundColor Red
    write-host "You need to run the `365admin-publish scaffold initweb` command first" -ForegroundColor Yellow
	
    return
}


$workdirPath = join-path $ENV:KITCHENROOT $kitchenname ".koksmat" "workdir" 
$schemaPath = join-path $ENV:KITCHENROOT $kitchenname ".koksmat" "web" "schemas"
EnsurePath $schemaPath
<#
## Function for generating the schema

https://github.com/glideapps/quicktype

#>
function MakeSchema($name) {
    $structName = SanitizeCmd($name)

    $filename = join-path $workdirPath  $name

    if (-not (Test-Path $filename)) {
        write-host "File $filename does not exist"
        return $structName 
    }
    $outputfilename = join-path $schemaPath "$name.ts"
    quicktype --src  $filename --src-lang json --lang typescript --out $outputfilename
    


   
}

Get-ChildItem -Path $workdirPath -Filter *.json | ForEach-Object { 
    write-host "Processing $_.Name"
    MakeSchema $_.Name
}

