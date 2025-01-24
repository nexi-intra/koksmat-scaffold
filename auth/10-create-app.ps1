<#---
title: Create app
tag: create-app
api: post
---#>
param (
    $kitchenname = "kubernetes-management"
    )

$appname = "magicapp-$kitchenname"

#$app = az ad app list --display-name $appname --query "[].{name:appId}" -o tsv
#if ($app -eq "") {

   $roles = @"
   [{
    "allowedMemberTypes": [
      "User"
    ],
    "description": "Approvers can mark documents as approved",
    "displayName": "Approver",
    "isEnabled": "true",
    "value": "approver"
}]

"@ 
   az ad app create  --display-name $appname #--app-roles $roles
   
#}

write-host $app


