koksmat kitchen script meta "pageinfo.ps1" -k "sharepoint-governance" -s "30-sharepoint"
return 
$filepath = "/Users/nielsgregersjohansen/kitchens/sharepoint-governance/30-sharepoint/pageinfo.ps1"
$x = (Get-Command $filepath).Parameters
$parameters = @()
foreach ($key in $x.Keys) {
    write-host $key
    if ($x[$key].Attributes[0].Position -gt -1){
      
        $p = @{
            Name = $key
            Position = $x[$key].Attributes[0].Position
            HelpMessage = $x[$key].Attributes[0].HelpMessage
            ParameterType = $x[$key].ParameterType.FullName
            Mandatory = $x[$key].Attributes[0].Mandatory
        }
        $parameters += $p
      
    }
   
}
$parameters


