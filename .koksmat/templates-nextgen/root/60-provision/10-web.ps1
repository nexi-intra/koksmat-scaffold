<#---
title: Web deploy to production
tag: webdeployproduction
api: post
---
We start by finding which version tag to use

eventually 

nexi-booking provision webdeployproduction 
#>

$appname = "magicbutton-sharepoint"
$imagename = "magicbutton-sharepoint"
$dnsname = "magicbutton-sharepoint.home.nexi-intra.com"
$inputFile = join-path  $env:KITCHENROOT $appname ".koksmat","koksmat.json"
$port = $env:KOKSMAT_WEBPORT
if (!(Test-Path -Path $inputFile) ) {
   Throw "Cannot find file at expected path: $inputFile"
} 
$json = Get-Content -Path $inputFile | ConvertFrom-Json
$version = "v$($json.version.major).$($json.version.minor).$($json.version.patch).$($json.version.build)"

<#
The we build the deployment file
#>

$image = "ghcr.io/magicbutton/$($imagename)-web:$($version)"

$config = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $appname
spec:
  selector:
    matchLabels:
      app: $appname
  replicas: 1
  template:
    metadata:
      labels:
        app: $appname
    spec: 
      containers:
      - name: $appname
        image: $image
        ports:
          - containerPort: $port
        env:
        - name: SPAUTH_TENANTID
          value: $($env:SPAUTH_TENANTID)
        - name: SPAUTH_CLIENTID
          value: $($env:SPAUTH_CLIENTID)
        - name: SPAUTH_CLIENTSECRET
          value: $($env:SPAUTH_CLIENTSECRET)
        - name: AZURE_AD_CLIENT_ID
          value: $($env:AZURE_AD_CLIENT_ID)
        - name: AZURE_AD_CLIENT_SECRET
          value: $($env:AZURE_AD_CLIENT_SECRET)
        - name: AZURE_AD_TENANT_ID
          value: $($env:AZURE_AD_TENANT_ID)
        
---
apiVersion: v1
kind: Service
metadata:
  name: $appname
  labels:
    app: $appname
    service: $appname
spec:
  ports:
  - name: http
    port: 5301
    targetPort: $port
  selector:
    app: $appname
---    
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $appname
spec:
  rules:
  - host: $dnsname
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $appname
            port:
              number: 5301
    

"@

write-host "Applying config" -ForegroundColor Green

write-host $config -ForegroundColor Gray

$config |  kubectl apply -f -