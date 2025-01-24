function GraphAPI($token, $method, $url, $body) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $token" )
    
    
    $errorCount = $error.Count
    $result = Invoke-RestMethod ($url) -Method $method -Headers $headers -Body $body
    if ($errorCount -ne $error.Count) {
        Write-Error $url
    }

    return $result

}
<#
.description
Read from Graph and follow @odata.nextLink
.changes
v1.03 Removed -Body from Invoke-RestMethod
#>
function GraphAPIAll($token, $method, $url) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $token" )
    
    $errorCount = $error.Count
    $result = Invoke-RestMethod ($url) -Method $method -Headers $headers 
    if ($errorCount -ne $error.Count) {
        Write-Error $url
    }


    $data = $result.value
    $counter = 0
    while ($result.'@odata.nextLink') {
        Write-Progress -Activity "Reading from GraphAPIAll $path" -Status "$counter Items Read" 

        if ($hexatown.verbose) {
            write-output "GraphAPIAll $($result.'@odata.nextLink')"
        }
        $result = Invoke-RestMethod ($result.'@odata.nextLink') -Method 'GET' -Headers $headers 
        $data += $result.value
        $counter += $result.value.Count
        
    }

    return $data

}


$scope = "https%3A//graph.microsoft.com/.default"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$body = "grant_type=client_credentials&client_id=$($env:GRAPH_APPID)&client_secret=$($env:GRAPH_APPSECRET)&scope=$scope"

$response = Invoke-RestMethod "https://login.microsoftonline.com/$($env:GRAPH_APPDOMAIN)/oauth2/v2.0/token" -Method 'POST' -Headers $headers -body $body
$env:GRAPH_ACCESSTOKEN = $response.access_token


