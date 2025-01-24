<#---
title: Generate Zod Schemas for CRUD Operations
tag: generate-zod-schemas
api: post
---
#>

param (
  # Set the desired kitchen name
  # Example: "magic-messages", "magic-people", etc.
  $kitchenname = "nexi-toolsv2",
  $databasename = "tools",
  $appname = "tools",
   
  $verbose = $false
)

# Header for the generated files to prevent overwriting unless specified
$header = @"
/* 
File has been automatically created. To prevent the file from getting overwritten,
set the Front Matter property 'keep' to 'true'. Syntax for the code snippet:
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
  }
  foreach ($col in $entity.additionalattributes) {
    if ($col.name -eq $name) {
      return $col
    }
  }
}

function ConvertTo-JsonSafe {
  param (
    [string]$Content
  )
  if ($null -eq $Content -or $Content -eq "") { return "" }
  # Replace special characters with their JSON-safe equivalents
  $safeContent = $Content -replace "`"", '\"' `
    -replace "`r", '' `
    -replace "`n", '\n' `
    -replace "`t", '\t'

  return $safeContent
}

function EnsurePath($path) {
  if (-not (Test-Path $path)) {
    Write-Host "Creating directory $path" -ForegroundColor Green
    New-Item -Path $path -ItemType Directory | Out-Null
  }
}

function GenerateZodSchema {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Operation, # Create, Update, Patch, Delete

    [Parameter(Mandatory = $true)]
    [string]$TableName,

    [Parameter(Mandatory = $true)]
    [array]$Columns
  )

  # Capitalize the first letter of TableName for consistent naming
  if ($TableName.Length -ge 1) {
    $TableNameCapitalized = ($TableName.Substring(0, 1).ToUpper() + $TableName.Substring(1))
  }
  else {
    Write-Host "Error: TableName is empty." -ForegroundColor Red
    throw "TableName cannot be empty."
  }

  Write-Host "Generating schema for Operation: $Operation, TableName: $TableNameCapitalized" -ForegroundColor Magenta

  # Define schema title and description based on operation
  switch ($Operation.ToLower()) {
    "create" { 
      $title = "Create $TableNameCapitalized"
      $description = "Schema for creating a new $TableNameCapitalized"
    }
    "update" { 
      $title = "Update $TableNameCapitalized"
      $description = "Schema for updating an existing $TableNameCapitalized"
    }
    "patch" { 
      $title = "Patch $TableNameCapitalized"
      $description = "Schema for patching an existing $TableNameCapitalized"
    }
    "delete" { 
      $title = "Delete $TableNameCapitalized"
      $description = "Schema for deleting an existing $TableNameCapitalized"
    }
    default {
      Write-Host "Unsupported operation: $Operation" -ForegroundColor Red
      throw "Unsupported operation: $Operation"
    }
  }

  # Start building the Zod schema
  $zodSchema = @"
$header
import { z } from 'zod';


export const schema = z.object({

"@

  foreach ($column in $Columns) {
    Write-Host "Processing column '$($column.Name)' with type '$($column.Type)'" -ForegroundColor Cyan
    if ($column.Type -eq "ARRAY" -or $column.Type -eq "") {
      # Handle array types
      if ($Operation.ToLower() -eq "delete") {
        # Typically, 'hard' is a boolean, not an array
        continue
      }

      # For array types, determine the inner type
      if ($column.JSONtype -eq "array") {
        if ($column.entity) {
          # Reference to another entity, assuming integer IDs
          $innerType = "z.number().int()"
          $zodType = "z.array($innerType)"
        }
        else {
          # Generic array of any type
          $zodType = "z.array(z.any())"
        }

        # Handle optionality based on operation
        if ($Operation.ToLower() -eq "create") {
          if ($column.required -eq $true) {
            # Field is required; no change
          }
          else {
            $zodType += ".optional()"
          }
        }
        elseif ($Operation.ToLower() -eq "update") {
          $zodType += ".optional()"
        }
        elseif ($Operation.ToLower() -eq "patch") {
          $zodType += ".optional()"
        }
        elseif ($Operation.ToLower() -eq "delete") {
          # Typically, arrays are not part of delete operations
          continue
        }

        # Add description as a comment if available
        $description = ""
        if ($column.PSObject.Properties.Name -contains "description" -and $column.description) {
          $description = $column.description
        }

        if ($description) {
          $zodSchema += "    // $description`n"
        }

        $zodSchema += "    $($column.Name): $zodType,`n"
        continue
      }
      else {
        # Non-array empty type, skip
        continue
      }
    }

    # Determine Zod type based on Type
    $zodType = "z.any()"

    switch ($column.Type) {
      "string" { $zodType = "z.string()" }
      "reference" { $zodType = "z.number().int()" }
      "integer" { $zodType = "z.number().int()" }
      "int" { $zodType = "z.number().int()" }
      "boolean" { $zodType = "z.boolean()" }
      "date" { $zodType = "z.string().refine((val) => !isNaN(Date.parse(val)), { message: 'Invalid date' })" }
      "datetime" { $zodType = "z.string().refine((val) => !isNaN(Date.parse(val)), { message: 'Invalid datetime' })" }
      "number" { $zodType = "z.number()" }
      "money" { $zodType = "z.number()" }
      "json" { $zodType = "z.object({}).passthrough()" }
      Default {
        Write-Host "Unsupported type '$($column.Type)' for column '$($column.Name)'" -ForegroundColor Red
        throw "Unsupported type '$($column.Type)' for column '$($column.Name)'"
      }
    }

    # Handle optional fields based on operation
    if ($Operation.ToLower() -eq "create") {
      # In create, fields marked as required are mandatory
      if ($column.required -eq $true) {
        # Field is required; no change
      }
      else {
        $zodType += ".optional()"
      }
    }
    elseif ($Operation.ToLower() -eq "update") {
      # In update, all fields except 'id' are optional
      if ($column.Name -eq "id") {
        $zodType = "z.number().int()"
      }
      else {
        $zodType += ".optional()"
      }
    }
    elseif ($Operation.ToLower() -eq "patch") {
      # In patch, all fields are optional
      $zodType += ".optional()"
    }
    elseif ($Operation.ToLower() -eq "delete") {
      # In delete, typically only 'id' and possibly 'hard' are required
      if ($column.Name -eq "id") {
        $zodType = "z.number().int()"
      }
      elseif ($column.Name -eq "hard") {
        $zodType = "z.boolean().optional()"
      }
      else {
        continue  # Skip other fields for delete
      }
    }

    # Add description as a comment if available
    $description = ""
    if ($column.PSObject.Properties.Name -contains "description" -and $column.description) {
      $description = $column.description
    }

    if ($description) {
      $zodSchema += "    // $description`n"
    }

    $zodSchema += "    $($column.Name): $zodType,`n"
  }

  # Special handling for Delete operation to include 'hard' field if not present
  if ($Operation.ToLower() -eq "delete") {
    # Check if 'hard' is already part of the columns
    $hasHard = $Columns | Where-Object { $_.Name -eq "hard" }
    if (-not $hasHard) {
      $zodSchema += @"
    // Indicates a hard delete (true) or soft delete (false)
    hard: z.boolean().optional(),
"@
    }
  }

  # Remove the last comma and add closing braces
  $zodSchema = $zodSchema.TrimEnd(",`n")
  $zodSchema += @"
});


"@

  return $zodSchema
}

function WriteTextFile($filepath, $content) {
  if (Test-Path $filepath) {
    $existingcontent = Get-Content $filepath -Raw

    # Check if the file should be kept
    $keep = $existingcontent -match "keep: true"
    if ($keep) {
      # If the string is found, skip writing
      Write-Host "Keeping existing $filepath" -ForegroundColor Yellow
      return
    }
  }

  $content | Out-File -FilePath $filepath -Encoding utf8NoBOM
  if ($verbose) {
    Write-Host "Writing $filepath" -ForegroundColor Cyan
  }
}

function GenerateIndexFile {
  param (
    [Parameter(Mandatory = $true)]
    [string]$SchemasPath
  )

  $indexContent = @"
/\* 
File has been automatically created. Do not edit manually.
*/

"@

  foreach ($file in Get-ChildItem -Path $SchemasPath -Filter "*.ts") {
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    if ($basename -eq "index") {
      continue  # Skip index.ts to prevent self-inclusion
    }
    $exportName = $basename
    $indexContent += "export { ${exportName}Schema, ${exportName} } from './$basename';`n"
  }

  $indexPath = Join-Path $SchemasPath "index.ts"
  WriteTextFile -filepath $indexPath -content $indexContent
}

# Initialization
$ErrorActionPreference = "Stop"
$koksmatDir = Join-Path $ENV:KITCHENROOT $kitchenname ".koksmat" 
$magicappPath = Join-Path $koksmatDir "magicapp.yaml"

if (-not (Test-Path $magicappPath)) {
  throw "No magicapp.yaml found in $koksmatDir"
}

# Convert YAML to JSON and parse
$mapicapp = yq eval -o=json $magicappPath | ConvertFrom-Json

# Define the directory for Zod schemas
$zodSchemasPath = Join-Path $koksmatDir "web" "app" $appname "api" "database" "databases" $databasename "schemas"
EnsurePath $zodSchemasPath

# Process each service to generate Zod schemas
foreach ($service in $mapicapp.services) {
  Write-Host "Processing service: $($service.name)" -ForegroundColor Green

  $columns = @()

  # Combine baselineattributes and additionalattributes
  $entity = $service.entity.entity
  $baselineAttributes = $entity.baselineattributes
  $additionalAttributes = $entity.additionalattributes

  # Process baseline attributes
  foreach ($columnDef in $baselineAttributes) {
    if ($null -eq $columnDef) {
      continue
    }
    $name = $columnDef.name
    $type = ""
    $required = $false
    if ($columnDef.PSObject.Properties.Name -contains "required") {
      $required = $columnDef.required
    }
    switch ($columnDef.type) {
      "string" { $type = "string" }
      "integer" { $type = "integer" }
      "int" { $type = "integer" }
      "boolean" { $type = "boolean" }
      "date" { $type = "datetime" }
      "datetime" { $type = "datetime" }
      "reference" { 
        $type = "integer"
        $name = "${name}_id"
      }
      "number" { $type = "number" }
      "money" { $type = "number" }
      "json" { $type = "json" }
      "array" { 
        # Array handling is managed separately
        continue 
      }
      Default {
        Write-Host "Unsupported type '$($column.type)' in baseline attributes for '$($entity.name)'" -ForegroundColor Red
        throw "Unsupported type '$($column.type)' in baseline attributes for '$($entity.name)'"
      }
    }

    $columns += @{
      Name        = $name
      Type        = $type
      JSONtype    = $column.type
      description = $column.description
      required    = $required
    }
  }

  # Process additional attributes
  foreach ($columnDef in $additionalAttributes) {
    if ($null -eq $columnDef) {
      continue
    }
    $name = $columnDef.name
    $type = ""
    $required = $false
    if ($columnDef.PSObject.Properties.Name -contains "required") {
      $required = $columnDef.required
    }
    switch ($columnDef.type) {
      "string" { $type = "string" }
      "integer" { $type = "integer" }
      "int" { $type = "integer" }
      "boolean" { $type = "boolean" }
      "date" { $type = "datetime" }
      "datetime" { $type = "datetime" }
      "reference" { 
        $type = "integer"
        $name = "${name}_id"
      }
      "number" { $type = "number" }
      "money" { $type = "number" }
      "json" { $type = "json" }
      "array" { 
        # Array handling is managed separately
        continue 
      }
      Default {
        Write-Host "Unsupported type '$($column.type)' in additional attributes for '$($entity.name)'" -ForegroundColor Red
        throw "Unsupported type '$($column.type)' in additional attributes for '$($entity.name)'"
      }
    }

    $columns += @{
      Name        = $name
      Type        = $type
      JSONtype    = $column.type
      description = $column.description
      required    = $required
      entity      = $columnDef.entity.name  # Capture entity if reference
    }
  }

  $tableName = $service.name
  Write-Host "Generating Zod schemas for table: $tableName" -ForegroundColor Yellow

  # Define operations to generate schemas for
  #  $operations = @("Create", "Update", "Patch", "Delete")
  #$operations = @("Create", "Update", "Patch", "Delete")

  # foreach ($operation in $operations) {
  $operation = "Create"
  # Generate Zod schema content
  try {
    $zodSchemaContent = GenerateZodSchema -Operation $operation -TableName $tableName -Columns $columns
  }
  catch {
    Write-Host "Error generating schema for operation '$operation' on table '$tableName': $_" -ForegroundColor Red
    continue
  }

  # Define the .ts file path
  $zodFileName = "${tableName}.ts"  # e.g., CreateUser.ts
  $zodFilePath = Join-Path $zodSchemasPath $zodFileName

  # Write the Zod schema to the .ts file
  WriteTextFile -filepath $zodFilePath -content $zodSchemaContent
  Write-Host $zodFilePath -ForegroundColor Cyan
  #}
}

# Generate index.ts for easy imports
GenerateIndexFile -SchemasPath $zodSchemasPath

Write-Host "Zod schema generation completed." -ForegroundColor Green
