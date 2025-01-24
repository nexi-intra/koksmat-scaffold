<#---
title: Build Cache files for each Kitchens
description: Build Cache files for each Kitchens
connection: sharepoint
output: kitchens-build.json
api: post
tag: publishdocusaurus
---#>

param (    
    
    $destinationKitchen = "profiling-pizza"
)

function PathMustExist($path) {
    if (-not (Test-Path $path)) {
        Throw "Directory $path does not exist"
    }
    return $path
}


function PathMustBeEmpty($path) {
    if (Test-Path $path) {       
        Remove-Item -Path $path -Recurse -Force
    
    }
    $x = New-Item -Path $path -ItemType Directory -Force

    return $path
}



$docupath = PathMustExist (Join-Path $env:KITCHENROOT $destinationKitchen ".koksmat" "web" "docs")
$kitchenFile = PathMustExist (Join-Path $env:KITCHENROOT $destinationKitchen ".koksmat" "kitchens.json")

$kitchens = Get-Content $kitchenFile | ConvertFrom-Json
if ($true) {
  
    $kitchenFileDownloadPath = PathMustBeEmpty ( Join-Path $env:KITCHENROOT $destinationKitchen ".koksmat" "workdir" "kitchencache")

    try {
        $oldKITCHENROOT = $env:KITCHENROOT
        $env:KITCHENROOT = $kitchenFileDownloadPath

        Push-Location

        Set-Location $env:KITCHENROOT 
        foreach ($kitchen in $kitchens) {
            # write-host "Cloning $($kitchen.name)" -ForegroundColor Green
            git clone "https://github.com/$($kitchen.repo)/$($kitchen.name).git" --depth 1
            # git -C $kitchen.name checkout $kitchen.branch
        }

    }
    catch {
        write-host $_.Exception.Message -ForegroundColor Red
        return
    }
    finally {

        Pop-Location
        $env:KITCHENROOT = $oldKITCHENROOT
    }
    write-host "Cleaning up $docupath" -ForegroundColor Green
    $packagesPath = (join-path $docupath  "packages")
    if (Test-Path $packagesPath) {
        Remove-Item -Path $packagesPath -Recurse -Force
    }
}

write-host "Copying files to $docupath" -ForegroundColor Green

foreach ($kitchen in $kitchens) {
  
    # check it the directory for the kitchen exists
    $kitchenpath = join-path $docupath  "packages" $kitchen.name
    if (-not (Test-Path $kitchenpath)) {
        $x = New-Item -Path $kitchenpath -ItemType Directory -Force
    }

    $sourcePath = join-path $kitchenFileDownloadPath $kitchen.name 

    Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.png" } | Copy-Item -Destination $kitchenpath -Recurse
    Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.jpg" } | Copy-Item -Destination $kitchenpath -Recurse
    Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.gif" } | Copy-Item -Destination $kitchenpath -Recurse
    Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.mp4" } | Copy-Item -Destination $kitchenpath -Recurse

    write-host $kitchen.name -ForegroundColor Green
    
    $kitchenStatus = koksmat kitchen status $kitchen.name | ConvertFrom-Json
    $markdown = $kitchenStatus.markdown

    if ($null -eq $markdown) {
        $markdown = @"
---
title: $($kitchen.title)
---
# $($kitchen.title)
"@
    }
    
    $markdown | Out-File -FilePath "$kitchenpath/index.md" -Encoding utf8NoBOM     
    $kitchenStations = koksmat kitchen stations $kitchen.name | ConvertFrom-Json

    foreach ($station in $kitchenStations.stations) {
        
        $stationPath = "$kitchenpath/$($station.name)"
        $sourcePath = join-path $kitchenFileDownloadPath $kitchen.name $station.name
        
        Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.png" }  | Copy-Item -Destination $stationPath
        Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.jpg" }  | Copy-Item -Destination $stationPath
        Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.gif" }  | Copy-Item -Destination $stationPath
        Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -like "*.mp4" }  | Copy-Item -Destination $stationPath
        if (-not (Test-Path $stationPath)) {
            $x = New-Item -Path  $stationPath -ItemType Directory 
        }
        $markdown = @"
---
title: $($station.title)
---
# $($station.title)

$($station.html)
        
        
"@
        
        
        $markdown | Out-File -FilePath "$stationPath/index.md" -Encoding utf8NoBOM     
        
     


        $station.scripts | ForEach-Object {
            $script = $_
            $scriptStatus = koksmat kitchen script meta $script.name --kitchen $kitchen.name --station $station.name  | ConvertFrom-Json
            $markdown = koksmat kitchen script markdown $script.name --kitchen $kitchen.name --station $station.name  
         
            $OldErrorActionPreference = $ErrorActionPreference   
            $ErrorActionPreference = "Continue"
            $markdown | Out-File -FilePath (Join-Path $stationPath "$($script.name).md") -Encoding utf8NoBOM     -ErrorAction Continue
            $ErrorActionPreference = $OldErrorActionPreference
     
        }
    }
  

    
}


write-host "Done" -ForegroundColor Green