<#---
connection: sharepoint
title: Init
api: post
tag: initweb
---#>
param (
	$kitchenname = "nexi-infocast"
)

<#
Copy the basic scructure of the kitchen

## MapicApp folder
#>

function CopyFiles($source, $destination) {
	if (-not (Test-Path $destination)) {
		# write-host "Creating directory $destinationFolder"
		$x = New-Item -Path $destination -ItemType Directory 
	}
	# write-host "Copying files to $destination"
	$files = Get-ChildItem -Path $source -Force
	for ($i = 0; $i -lt $files.Count; $i++) {
		$file = $files[$i]
		if ($file.PSIsContainer) {

			$destinationFolder = Join-Path $destination  $file.Name
		
			CopyFiles $file.FullName $destinationFolder $exclude
			continue
		}
		$destinationFile = Join-Path $destination  $file.Name
		if (-not (Test-Path $destinationFile)) {
			write-host "Copying $destinationFile" -ForegroundColor Green
			$x = Copy-Item -Path $file.FullName -Destination $destinationFile -ErrorAction Continue -Force:$false
		}
		else {
			# write-host "File $destinationFile already exists" -ForegroundColor Gray
		
		}
		if ($file.PSIsContainer) {

			$destinationFolder = Join-Path $destination  $file.Name
		
			CopyFiles $file.FullName $destinationFolder $exclude
			
		}
		else {
			
		
			$destinationFile = Join-Path  $destination  $file.Name
	
			if (-not (Test-Path $destinationFile)) {
				write-host "Copying $destinationFile" -ForegroundColor Green
				$x = Copy-Item -Path $file.FullName -Destination $destinationFile 
			}
			else {
				#	write-host "Skipping $destinationFile" -ForegroundColor Gray
		
			}
		}
	}
}

$kitchenPath = Join-Path $ENV:KITCHENROOT $kitchenname

if (-not (Test-Path $kitchenPath)) {
	Throw "The kitchen $kitchenname does not exist"
	
}


$webPath = Join-Path  $ENV:KITCHENROOT $kitchenname ".koksmat" "web" 
$templatePath = Join-Path  $ENV:KITCHENROOT "365admin-publish" ".koksmat" "templates" "web" 

$templateWebPath = Join-Path  $templatePath "nextjs"

CopyFiles $templateWebPath $webPath 

Push-Location
Set-Location $webPath
pnpm install
Pop-Location