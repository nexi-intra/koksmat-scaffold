<#---
title: V2 Generate Microservice Integration Code
tag: generateapp-v2
api: post

---


#>
param (
    # $kitchenname = "magic-messages",
    # $kitchenname = "magic-people",
    # $kitchenname = "magic-it",
    # $kitchenname = "magic-mix",

    # $kitchenname = "nexi-infocast",
    # $kitchenname = "magic-boxes",
    # $kitchenname = "magic-apps",
    # $kitchenname = "magic-meetings",
    # $kitchenname = "magic-zones",
    #    $kitchenname = "nexi-booking",
    #$kitchenname = "nexi-tools",
   
    $verbose = $false

  
)
$migrationId = 0
$ISREQUIRED = $true
$ISNOTREQUIRED = $false
$ErrorActionPreference = "Stop"
$TextInfo = (Get-Culture).TextInfo
$koksmatDir = join-path $ENV:KITCHENROOT $kitchenname ".koksmat" 
$mapicapp = yq (join-path $koksmatDir "magicapp.yaml") -o json | ConvertFrom-Json
yq (join-path $koksmatDir "magicapp.yaml") -o json > (join-path $koksmatDir "magicapp.json")

$entitiesInOrder = yq (join-path $koksmatDir "magicapp.yaml") -o json  | jq '.entities | keys_unsorted' | ConvertFrom-Json
$goDatabasePath = join-path $koksmatDir "app"  "database" 
EnsurePath $goDatabasePath
$goDatabaseMigrationPath = join-path $goDatabasePath "tern" 
EnsurePath $goDatabaseMigrationPath
$goDatabaseProceduresPath = join-path $goDatabasePath "tern"  "procedures"
EnsurePath $goDatabaseProceduresPath

#region Support functions

if (-not $mapicapp) {
    throw "No magicapp.yaml found in $koksmatDir"
}

if ($mapicapp.magicappversion -ne "v0.0.1") {
    throw "Unsupported version $mapicapp.version"
}

<#

## Supporting functions
#>
function EnsurePath($path) {
    if (-not (Test-Path $path)) {
        write-host "Creating directory  $path"
        New-Item -Path  $path -ItemType Directory | Out-Null
    }
}

function EnsurePathWithId($path) {
    if (-not (Test-Path $path)) {
        write-host "Creating directory  $path"
        New-Item -Path  $path -ItemType Directory | Out-Null
        New-Item -Path  (join-path $path "[id]") -ItemType Directory | Out-Null

    }

}

function WriteTextFile($filepath, $content) {
    if (Test-Path $filepath) {
        $existingcontent = Get-Content $filepath
        

        # find the string "keep: true" in the $content read from Get-Content
        $keep = $existingcontent | Select-String -Pattern "keep: true"
        if ($keep) {
            # if the string is found, remove it from the $content
            write-host "Keeping $filepath" -ForegroundColor Yellow
            return
        }
    }
    $content | Out-File -FilePath $filepath -Encoding utf8NoBOM
    if ($verbose) {
        write-host "Writing $filepath" -ForegroundColor Yellow
    
    }
}

#endregion 
$fileHeader = @"
/* 
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´keep´ to ´true´ syntax for the code snippet
---
keep: false
---
*/
"@

#region Outputters


function column($name, $type, $map) {
    return @"
    $($name) $($type) ``json:"$($map)"``

"@
}
function sqlcolumn($name, $type, $map) {
    return @"
    $($name) $($type) ``bun:"$($map)"``

"@
}



function tscolumn($name, $type, $map) {
    return @"
    $($name) : $($type) `;`

"@
}

function sqlJSON($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name JSONB  $(NullContraint $required)

"@
}
function sqlNumber($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default"  $(NullContraint $required)

"@
}

function sqlInteger($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default"  $(NullContraint $required)

"@
}

function sqlBoolean($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name boolean  $(NullContraint $required)

"@
}

function sqlDatetime($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default"  $(NullContraint $required)

"@
}

function sqlReference($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }
    return @"
    ,$($name)_id int  $(NullContraint $required)

"@
}

function GenerateDatabaseMigration( $organisation, $serviceName, $name, $entity, $migrationId ) {
 

    $columns = ""
    $references = ""
    $dropCmd = ""
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)
    if ($null -ne $entity.parent ) {
        $columns += sqlReference $entity.parent.name $ISNOTREQUIRED
       
        $references += @"
        ALTER TABLE IF EXISTS public.$($name)
        ADD FOREIGN KEY ($($entity.parent.name)_id)
        REFERENCES public.$($entity.parent.name) (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID;
"@
    }

    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
       
            continue
        }
        $columnname = $attribute.name
    
        $map = $attribute.name
        switch ($attribute.type) {
            "string" { 
                $columns += sqlString $columnname $attribute.required
            }
            "json" { 
                $columns += sqlJSON $columnname $attribute.required
            }
            "number" { 
                $columns += sqlNumber $columnname $attribute.required
            }
            "int" { 
                $columns += sqlInteger $columnname $attribute.required
            }
            "boolean" { 
                $columns += sqlBoolean $columnname $attribute.required
            }
            "datetime" { 
                $columns += sqlDatetime $columnname $attribute.required
            }
            "reference" { 
                $columns += sqlReference $columnname $attribute.required
                if ($null -eq $attribute.entity.name) {
                    throw "No entity name found for $($name).$($columnname)"
                }
                $references += @"
                ALTER TABLE IF EXISTS public.$($name)
                ADD FOREIGN KEY ($($columnname)_id)
                REFERENCES public.$($attribute.entity.name) (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                NOT VALID;
"@
            }
            "array" { 

                $manytomanytablename = "$($name)_m2m_$($attribute.entity.name)"
                $dropCmd += @"
DROP TABLE IF EXISTS public.$($manytomanytablename);
"@
                $references += @"
                -- lollipop
                CREATE TABLE public.$($manytomanytablename) (
                id SERIAL PRIMARY KEY,
                created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_by character varying COLLATE pg_catalog."default"  ,
                updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_by character varying COLLATE pg_catalog."default",
                deleted_at timestamp with time zone
                
                $(sqlReference $($name)_id) $REQUIRED
                $(sqlReference $($attribute.entity.name)_id) $REQUIRED

                );
            

                ALTER TABLE public.$($manytomanytablename)
                ADD FOREIGN KEY ($($name)_id)
                REFERENCES public.$($name) (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                NOT VALID;

                ALTER TABLE public.$($manytomanytablename)
                ADD FOREIGN KEY ($($attribute.entity.name)_id)
                REFERENCES public.$($attribute.entity.name) (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                NOT VALID;
"@
                
                # $columns += sqlString $columnname 
            }
            Default {
              
                write-host "Unknown type  $($attribute.type)"
                throw $errormessage
            }
        }
    
    }

    $sqlMigrationFileContent = @"
$fileHeader   


-- sure sild

CREATE TABLE public.$($name)
(
    id SERIAL PRIMARY KEY,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by character varying COLLATE pg_catalog."default"  ,

    updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by character varying COLLATE pg_catalog."default" ,

    deleted_at timestamp with time zone
$columns

);

$references


---- create above / drop below ----
$dropCmd
DROP TABLE public.$($name);

"@

    $migrationTag = '{0:d4}' -f $migrationId
    WriteTextFile (join-path $goDatabaseMigrationPath "$($migrationTag)_create_table_$name.sql") $sqlMigrationFileContent

}



#endregion
#region Main
<#

## Main program

#>

write-host "Generating code for $($mapicapp.name)" -ForegroundColor Yellow
write-host $mapicapp.services.Count "services found" -ForegroundColor Yellow

$map = @{
    name     = $mapicapp.name
    services = @()
}

$appRegisterEndpoints = @"
$fileHeader
package magicapp

import (
	"github.com/$($mapicapp.organisation)/$($kitchenname)/services"
	"github.com/nats-io/nats.go/micro"
)

func RegisterServiceEndpoints(root micro.Group) {

"@


foreach ($entityKey in $entitiesInOrder ) {
    $entity = $mapicapp.entities.$entityKey
    $migrationId += 1
    GenerateDatabaseMigration $mapicapp.organisation  $kitchenname $entity.name $entity $migrationId
}
$register = ""
foreach ($service in $mapicapp.services) {

    [array]$procedures = $service.procedures.PSObject.Properties.Name # | convertto-json -Depth 3 | Set-Clipboard
    Write-Host "Generating code for $($service.name) procedures" -ForegroundColor Green

    foreach ($procedure in $procedures) {
        $procedureName = "$($service.name)_$($procedure)"
        write-host "Generating code for $($procedureName)" -ForegroundColor Yellow
        $code = @"
        -- todo proc.$($procedureName)
"@
        WriteTextFile (join-path $goDatabaseProceduresPath "$($procedureName).sql") $code
        $register += @"
{{ template "$($procedureName).sql".}} 

"@
    }
    
    foreach ($method in $service.methods) {
        $procedureName = "$($service.name)_$($method.name)_record"
        write-host "Generating standard code for $($procedureName)" -ForegroundColor Gray  

        $code = @"
        --  todo proc.$($procedureName)
"@
        WriteTextFile (join-path $goDatabaseProceduresPath "$($procedureName).sql") $code
        $register += @"
{{ template "$($procedureName).sql".}} 

"@
     
    }
}

$installSql = @"
drop schema if exists "proc" cascade;

CREATE SCHEMA "proc"

$register
"@
WriteTextFile (join-path $goDatabaseProceduresPath "install.sql") $installSql


#endregion