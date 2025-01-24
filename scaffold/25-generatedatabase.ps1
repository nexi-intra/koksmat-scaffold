<#---
title: V3 Generate Microservice Integration Code
tag: generateapp-v2
api: post

---


#>
param (
    # $kitchenname = "magic-messages",
    # $kitchenname = "magic-people",
    #$kitchenname = "magic-share",    
    # $kitchenname = "magic-it",
    #    $kitchenname = "magic-mix",
    # $kitchenname = "magic-facility",

    # $kitchenname = "magic-it",
    # $kitchenname = "nexi-infocast",
    # $kitchenname = "magic-boxes",
    # $kitchenname = "magic-apps",
    # $kitchenname = "magic-meeting",
    # $kitchenname = "magic-zones",
    # $kitchenname = "nexi-booking-v2",
    # $kitchenname = "nexi-toolsv2",
    $kitchenname = "magic-mix",
    #$kitchenname = "magic-work",
   
    $verbose = $false

  
)
$header = @"
/* 
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´keep´ to ´true´ syntax for the code snippet
---
keep: false
---
*/   

"@

function FindColumn($name, $entity) {
    foreach ($col in $entity.baselineattributes) {
        if ($col.name -eq $name) {
            return $col
        }
        <# $currentItemName is the current item #>
    }
    foreach ($col in $entity.additionalattributes) {
        if ($col.name -eq $name) {
            return $col
        }
        <# $currentItemName is the current item #>
    }
}

function ConvertTo-JsonSafe {
    param (

        [string]$Content
    )
    if ( $null -eq $Content ) { return "" }
    if ( "" -eq $Content ) { return "" }
    # Replace special characters with their JSON-safe equivalents
    $safeContent = $Content -replace "`"", '\"' `
        -replace "`r", '' `
        -replace "`n", '\n' `
        -replace "`t", '\t'

    return $safeContent
}
function EnsurePath($path) {
    if (-not (Test-Path $path)) {
        write-host "Creating directory  $path"
        New-Item -Path  $path -ItemType Directory | Out-Null
    }
}

function GenerateSqlScripts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TableName,
        
        [Parameter(Mandatory = $true)]
        [array]$Columns,

        $Service
    )
    # Shared Columns Definition
    $sharedColumns = @"
id SERIAL PRIMARY KEY,
created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by VARCHAR COLLATE pg_catalog.`"default` NOT NULL ",
updated_by VARCHAR COLLATE pg_catalog.`"default` NOT NULL ",
tenant VARCHAR COLLATE pg_catalog.`"default`" NOT NULL,
searchindex VARCHAR COLLATE pg_catalog.`"default`" NOT NULL,
name VARCHAR COLLATE pg_catalog.`"default`" NOT NULL,
description VARCHAR COLLATE pg_catalog.`"default`",
koksmat_masterdataref VARCHAR COLLATE pg_catalog.`"default`",
koksmat_masterdata_id VARCHAR COLLATE pg_catalog.`"default`",
koksmat_masterdata_etag VARCHAR COLLATE pg_catalog.`"default`",
koksmat_compliancetag VARCHAR COLLATE pg_catalog.`"default`",
koksmat_state VARCHAR COLLATE pg_catalog.`"default`",

koksmat_bucket JSONB 

"@

    # Building Additional Columns and Constraints
    $additionalColumnsStr = ""
    $constraints = ""
    
    foreach ($column in $Columns) {
        if ($column.Type -eq "ARRAY") {
            continue
        }
        else {
            $additionalColumnsStr += "$($column.Name) $($column.Type),"
        }
    }

    # Remove the last comma
    $additionalColumnsStr = $additionalColumnsStr.TrimEnd(",")
    $constraints = $constraints.TrimEnd(",")

    # Table Creation Script
    $tableScript = @"
CREATE TABLE public.$TableName (
$sharedColumns,
$additionalColumnsStr
    $constraints
);
"@

    # Prepare Variables for Procedures
    $declareVariables = "   v_rows_updated INTEGER;`n"
    $extractVariables = ""
    $selectParams = ""
    $insertValues = ""
    $updateSet = ""
    $schemaVariables = ""

    # Combine Shared and Additional Columns for Procedures
    $allColumns = @(
        @{ Name = "tenant"; Type = "VARCHAR COLLATE pg_catalog.`"default`" "; JSONtype = "string" },
        @{ Name = "searchindex"; Type = "VARCHAR COLLATE pg_catalog.`"default`" " ; JSONtype = "string" },
        @{ Name = "name"; Type = "VARCHAR COLLATE pg_catalog.`"default`" " ; JSONtype = "string" },
        @{ Name = "description"; Type = "VARCHAR COLLATE pg_catalog.`"default`"" ; JSONtype = "string" }
    ) 
    
    foreach ($column in $Columns) {
        if ($column.Type -eq "ARRAY") {
            continue
        }
        $allColumns += $column
    }
  
    $auditLogDeclaration = @"
    v_audit_id integer;  -- Variable to hold the OUT parameter value
    p_auditlog_params jsonb;

"@
    $manifestColumns = @()
    
    $schemaColumns = ""
    foreach ($column in $allColumns) {
        $entityCol = FindColumn $column.name $Service.entity.entity
        if ($column.Type -eq "ARRAY") {
            continue
        }
        $declareVariables += "v_$($column.Name) $($column.Type);`n    "
        $extractVariables += "v_$($column.Name) := p_params->>'$($column.Name)';`n    "



        $selectParams += "p_params->>'$($column.Name)',`n        "
        $insertValues += "v_$($column.Name),`n        "
        $updateSet += "$($column.Name) = v_$($column.Name),`n        "
        $manifestColumns += $column

        $schemaType = "string"
        switch ($column.JSONtype) {
            "string" { $schemaType = "string" }
            "reference" { $schemaType = "number" }
            "integer" { $schemaType = "number" }
            "int" { $schemaType = "number" }
            "boolean" { $schemaType = "boolean" }
            "date" { $schemaType = "string" }
            "datetime" { $schemaType = "string" }
            "number" { $schemaType = "number" }
            "money" { $schemaType = "number" }
            "bytea" { $schemaType = "string" }
            "json" { $schemaType = "object" }
            "array" { continue }
            Default {
                throw "Unsupported type $($column.JSONtype)"
            }
        }


        $schemaColumns += @"

    "$($column.Name)": { 
    "type": "$schemaType",
    "description":"$(ConvertTo-JsonSafe $entityCol.description)" },
"@
    }
    $declareVariables = $declareVariables.TrimEnd("`n    ")
    $selectParams = $selectParams.TrimEnd(",`n        ")
    $insertValues = $insertValues.TrimEnd(",`n        ")
    $updateSet = $updateSet.TrimEnd(",`n        ")
    
    $schemaColumns = $schemaColumns.TrimEnd(",")

    $schemaHeader = @"
 "$('$')schema": "https://json-schema.org/draft/2020-12/schema",
  "$('$')id": "https://booking.services.koksmat.com/$($Service.entity.name).schema.json",
   
  "type": "object",

"@

    $createmanifest = @"
{
  $schemaHeader
  "title": "Create $($Service.entity.objectname)",
  "description": "Create operation",

  "properties": {
  $schemaColumns

    }
}

"@

    $updateManifest = @"
{
  $schemaHeader
  "properties": {
    "title": "Update $($Service.entity.objectname)",
  "description": "Update operation",
  $schemaColumns

    }
}
"@

    $deleteManifest = @"
{
    $schemaHeader
  "title": "Delete $($Service.entity.objectname)",
  "description": "Delete operation",
  "properties": {
   "id": { "type": "number" },
    "hard": { "type": "boolean" }

    }
}
"@

    $undodeletemanifest = @"
{
    $schemaHeader
    "title": "Restore $($Service.entity.objectname)",
  "description": "Restore operation",
    "properties": {
    "id": { "type": "number" }

    }
}
"@

    $Xcreatemanifest = @"
{
  "$('$')schema": "https://json-schema.org/draft/2020-12/schema",
  "$('$')id": "https://koksmat.com/product.schema.json",
  "title": "Product",
  "description": "A product from Acme's catalog",
  "type": "object",
  "properties": {
    "productId": {
      "description": "The unique identifier for a product",
      "type": "integer"
    },
    "productName": {
      "description": "Name of the product",
      "type": "string"
    },
    "price": {
      "description": "The price of the product",
      "type": "number",
      "exclusiveMinimum": 0
    }
  },
  "required": [ "productId", "productName", "price" ]
}
"@
    # Create Procedure
    $createProcedure = @"
$header

-- tomat sild
-- TODO: Figure out why i had this in the public schmea and not in the proc schema 
CREATE OR REPLACE FUNCTION proc.create_$TableName(
    p_actor_name VARCHAR,
    p_params JSONB,
    p_koksmat_sync JSONB DEFAULT NULL
   
)
RETURNS JSONB LANGUAGE plpgsql 
AS $('$$')
DECLARE
    $declareVariables
    v_id INTEGER;
    $auditLogDeclaration
BEGIN
    RAISE NOTICE 'Actor % Input % ', p_actor_name,p_params;
    $extractVariables     
    
    INSERT INTO public.$TableName (
    id,
    created_at,
    updated_at,
        created_by, 
        updated_by, 
        $(($allColumns | ForEach-Object { $_.Name }) -join ",`n        ")
    )
    VALUES (
        DEFAULT,
        DEFAULT,
        DEFAULT,
        p_actor_name, 
        p_actor_name,  -- Use the same value for updated_by
        $insertValues
    )
    RETURNING id INTO v_id;

    

       p_auditlog_params := jsonb_build_object(
        'tenant', '',
        'searchindex', '',
        'name', 'create_$($TableName)',
        'status', 'success',
        'description', '',
        'action', 'create_$($TableName)',
        'entity', '$TableName',
        'entityid', -1,
        'actor', p_actor_name,
        'metadata', p_params
    );
/*###MAGICAPP-START##
$createmanifest
##MAGICAPP-END##*/

    -- Call the create_auditlog procedure
    CALL proc.create_auditlog(p_actor_name, p_auditlog_params, v_audit_id);

    return jsonb_build_object(
    'comment','created',
    'id',v_id);

END;
$('$$') 
;




"@

    # Update Procedure
    $updateProcedure = @"
$header

-- sherry sild

CREATE OR REPLACE FUNCTION proc.update_$TableName(
    p_actor_name VARCHAR,
    p_params JSONB,
    p_koksmat_sync JSONB DEFAULT NULL
   
)
RETURNS JSONB LANGUAGE plpgsql 
AS $('$$')
DECLARE
    v_id INTEGER;
    $declareVariables
    $auditLogDeclaration
    
BEGIN
    RAISE NOTICE 'Actor % Input % ', p_actor_name,p_params;
    v_id := p_params->>'id';
    $extractVariables     
    

        
    UPDATE public.$TableName
    SET updated_by = p_actor_name,
        updated_at = CURRENT_TIMESTAMP,
        $updateSet
    WHERE id = v_id;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    
    IF v_rows_updated < 1 THEN
        RAISE EXCEPTION 'No records updated. $TableName ID % not found', v_id ;
    END IF;


           p_auditlog_params := jsonb_build_object(
        'tenant', '',
        'searchindex', '',
        'name', 'update_$($TableName)',
        'status', 'success',
        'description', '',
        'action', 'update_$($TableName)',
        'entity', '$TableName',
        'entityid', -1,
        'actor', p_actor_name,
        'metadata', p_params
    );
/*###MAGICAPP-START##
$updateManifest
##MAGICAPP-END##*/
    -- Call the create_auditlog procedure
    CALL proc.create_auditlog(p_actor_name, p_auditlog_params, v_audit_id);

    return jsonb_build_object(
    'comment','updated',
    'id',v_id
    );
END;
$('$$') 
;


"@

    # Patch Procedure
    $patchProcedure = @"
 $header
 
 -- tuna fish
 
 CREATE OR REPLACE FUNCTION proc.patch_$TableName(
     p_actor_name VARCHAR,
      p_id integer,
    p_fields jsonb,

     p_koksmat_sync JSONB DEFAULT NULL
    
 )
 RETURNS JSONB LANGUAGE plpgsql 
 AS $('$$')
 DECLARE
    v_rows_updated INTEGER;
    v_query TEXT;
    v_param_name TEXT;
    v_param_value TEXT;
    v_set_clause TEXT := '';
      $auditLogDeclaration
BEGIN
    -- Raise a notice with actor and input
    RAISE NOTICE 'Actor: % Input: %', p_actor_name, p_fields;
    
    -- Loop through the fields to build the dynamic SET clause
    FOR v_param_name, v_param_value IN
        SELECT key, value::text
        FROM jsonb_each(p_fields)
    LOOP
        -- Dynamically build the SET clause
        v_set_clause := v_set_clause || format('%I = %L,', v_param_name, v_param_value);
    END LOOP;
    
    -- Remove the trailing comma from the SET clause
    v_set_clause := rtrim(v_set_clause, ',');

    -- Build the final query
    v_query := format('UPDATE public.$($TableName) SET %s, updated_by = %L, updated_at = CURRENT_TIMESTAMP WHERE id = %L',
                      v_set_clause, p_actor_name, p_id);
    
    -- Execute the dynamic query
    EXECUTE v_query;
    
    -- Get the number of rows updated
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    -- If no rows were updated, raise an exception
    IF v_rows_updated < 1 THEN
        RAISE EXCEPTION 'No records updated.  ID % not found in table $($TableName)', p_id;
    END IF;
       p_auditlog_params := jsonb_build_object(
        'tenant', '',
        'searchindex', '',
        'name', 'patch_$($TableName)',
        'status', 'success',
        'description', '',
        'action', 'patch_$($TableName)',
        'entity', '$TableName',
        'entityid', -1,
        'actor', p_actor_name,
        'metadata', p_fields
    );

        -- Call the create_auditlog procedure
    CALL proc.create_auditlog(p_actor_name, p_auditlog_params, v_audit_id);

    -- Return success
    RETURN jsonb_build_object(
        'comment', 'patched',
        'id', p_id
    );
END;
 $('$$') 
 ;
 
 
"@
    # Delete Procedure (with soft delete option)
    $deleteProcedure = @"
$header

-- krydder sild

CREATE OR REPLACE FUNCTION proc.delete_$TableName(
    p_actor_name VARCHAR,
    p_params JSONB,
    p_koksmat_sync JSONB DEFAULT NULL
   
)
RETURNS JSONB LANGUAGE plpgsql 
AS $('$$')
DECLARE
    v_id INTEGER;
    v_hard BOOLEAN;
     v_rows_updated INTEGER;
    $auditLogDeclaration

BEGIN
    RAISE NOTICE 'Actor % Input % ', p_actor_name,p_params;
    v_id := p_params->>'id';
    v_hard := p_params->>'hard';
  
    IF v_hard THEN
     DELETE FROM public.$TableName
        WHERE id = v_id;
       
    ELSE
        UPDATE public.$TableName
        SET deleted_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = p_actor_name
        WHERE id = v_id;
        
        GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    
        IF v_rows_updated < 1 THEN
            RAISE EXCEPTION 'No records updated. $TableName ID % not found', v_id ;
        END IF;
    END IF;

     

           p_auditlog_params := jsonb_build_object(
        'tenant', '',
        'searchindex', '',
        'name', 'delete_$($TableName)',
        'status', 'success',
        'description', '',
        'action', 'delete_$($TableName)',
        'entity', '$TableName',
        'entityid', -1,
        'actor', p_actor_name,
        'metadata', p_params
    );
/*###MAGICAPP-START##
$deleteManifest
##MAGICAPP-END##*/
    -- Call the create_auditlog procedure
    CALL proc.create_auditlog(p_actor_name, p_auditlog_params, v_audit_id);


  return jsonb_build_object(
    'comment','deleted',
    'id',v_id
    
    );
END;
$('$$') 
;

"@

    # Undo Delete Procedure
    $undoDeleteProcedure = @"
$header
-- karry sild

CREATE OR REPLACE FUNCTION proc.undo_delete_$TableName(
    p_actor_name VARCHAR,
    p_params JSONB
   
)
RETURNS JSONB LANGUAGE plpgsql 
AS $('$$')
DECLARE
    v_id INTEGER;
    $auditLogDeclaration

BEGIN
    RAISE NOTICE 'Actor % Input % ', p_actor_name,p_params;
    v_id := p_params->>'id';
    
        
    UPDATE public.$TableName
    SET deleted_at = NULL,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_actor_name
    WHERE id = v_id;
  

           p_auditlog_params := jsonb_build_object(
        'tenant', '',
        'searchindex', '',
        'name', 'undo_delete_$($TableName)',
        'status', 'success',
        'description', '',
        'action', 'undo_delete_$($TableName)',
        'entity', '$TableName',
        'entityid', -1,
        'actor', p_actor_name,
        'metadata', p_params
    );
/*###MAGICAPP-START##
$undodeletemanifest
##MAGICAPP-END##*/
    -- Call the create_auditlog procedure
    CALL proc.create_auditlog(p_actor_name, p_auditlog_params, v_audit_id);

return jsonb_build_object(
    'comment','undo_delete',
    'id',v_id);
END; 
$('$$') 
;

"@

    return @{
        TableScript = $tableScript
        Create      = $createProcedure
        Update      = $updateProcedure
        Patch       = $patchProcedure
        Delete      = $deleteProcedure
        UndoDelete  = $undoDeleteProcedure
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

if (-not $mapicapp) {
    throw "No magicapp.yaml found in $koksmatDir"
}

if ($mapicapp.magicappversion -ne "v0.0.1") {
    throw "Unsupported version $mapicapp.version"
}

$register = @"
/*
---
keep: false
---
Generated by $($PSScriptRoot)/25-generatedatabase.ps1
Do not edit this file manually
*/

--drop schema if exists "proc" cascade;

--CREATE SCHEMA if not exists "proc";

"@
foreach ($service in $mapicapp.services) {

    [array]$procedures = $service.procedures.PSObject.Properties.Name # | convertto-json -Depth 3 | Set-Clipboard
    Write-Host "Generating code for $($service.name) procedures" -ForegroundColor Green

    foreach ($procedure in $procedures) {
        if ($procedure -eq "create") {
            throw "Create is a reserved procedure name"
        }
        if ($procedure -eq "update") {
            throw "Update is a reserved procedure name"
        }
        if ($procedure -eq "delete") {
            throw "Delete is a reserved procedure name"
        }
        if ($procedure -eq "undo_delete") {
            throw "Undo_delete is a reserved procedure name"
        }
        $procedureName = "$($procedure)_$($service.name)"
        write-host "Generating code for $($procedureName)" -ForegroundColor Yellow
        $code = @"
$header

-- tomat sild

CREATE OR REPLACE FUNCTION proc.$procedureName(
    p_actor_name VARCHAR,
    p_params JSONB
    
)
RETURNS JSONB LANGUAGE plpgsql 
AS $('$$')
BEGIN
RAISE NOTICE 'Actor % Input % ', p_actor_name,p_params;
    
END;
$('$$') 
;    
"@
        WriteTextFile (join-path $goDatabaseProceduresPath "$($procedureName).sql") $code
        $register += @"
{{ template "$($procedureName).sql".}} 

"@
    }


    $columns = @(
      
    )
    $schemacolumns = @(
      
    )
    $service.entity.entity.additionalattributes | ForEach-Object {
        $columnDef = $_
        if ($null -eq $columnDef) {
            continue
        }
        $name = $columnDef.name
        $reference = ""
        $type = ""
        $columnname = $name
        switch ( $columnDef.type) {
            "string" {
                $type = "VARCHAR"
            }
            "integer" {
                $type = "INTEGER"
            }
            "int" {
                $type = "INTEGER"
            }
            "boolean" {
                $type = "BOOLEAN"
            }
            "date" {
                $type = "TIMESTAMP WITH TIME ZONE"
            }
            "datetime" {
                $type = "TIMESTAMP WITH TIME ZONE"
            }
            "reference" {
                $type = "INTEGER"
                $columnname = "$name`_id"
                $reference = $columnDef.entity.name
            }
            "number" {
                $type = "MONEY"
            }
            "money" {
                $type = "MONEY"
            }
            "bytea" {
                $type = "BYTEA"
            }
            "json" {
                $type = "JSONB"
            }
            "array" {                
                $type = "ARRAY"
                continue
            }
            
            default {
                throw "Unsupported type $( $columnDef.type)"
            }
        }

        $columns += @{
            Name           = $columnname
            Type           = $type
            ReferenceTable = $reference
            JSONtype       = $columnDef.type
        }
       
    }
    
    if ( $service.name -eq "request") {
        write-host "x"
    }
    $tableName = $service.name
    $sqlScripts = GenerateSqlScripts -TableName $tableName -Columns $columns -Service $service

    #Output the scripts
    # $sqlScripts.TableScript | Out-File -FilePath "$tableName`_table.sql"
    
    $procedureName = "$tableName`_create_proc"
    WriteTextFile (join-path $goDatabaseProceduresPath "$procedureName.sql") $sqlScripts.Create 
    $register += @"
{{ template "$($procedureName).sql".}} 

"@
    $procedureName = "$tableName`_update_proc"
    WriteTextFile (join-path $goDatabaseProceduresPath "$procedureName.sql") $sqlScripts.Update 
    $register += @"
{{ template "$($procedureName).sql".}} 
"@
    $procedureName = "$tableName`_patch_proc"
    WriteTextFile (join-path $goDatabaseProceduresPath "$procedureName.sql") $sqlScripts.Patch 
    $register += @"
{{ template "$($procedureName).sql".}} 

"@
    $procedureName = "$tableName`_delete_proc"
    WriteTextFile (join-path $goDatabaseProceduresPath "$procedureName.sql") $sqlScripts.Delete 
    $register += @"
{{ template "$($procedureName).sql".}} 

"@
    $procedureName = "$tableName`_undo_delete_proc"
    WriteTextFile (join-path $goDatabaseProceduresPath "$procedureName.sql") $sqlScripts.UndoDelete  
    $register += @"
{{ template "$($procedureName).sql".}} 

"@

}
WriteTextFile (join-path $goDatabaseProceduresPath "install.sql") $register

$register