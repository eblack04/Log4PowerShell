$hash1 = @{
    "Property1" = "Value1"
    "Property2" = "Value2"
    "Property3" = "Value3"
}

$headers = @("Property1", "Property2", "Propertdy3")

Write-Host "Number of keys:  $($hash1.Keys.Count)"

$containsKey = $hash1.ContainsKey("Property2")

Write-Host "containsKey:  $containsKey"

$numberOfObjectProperties = ($hash1 | Get-Member -MemberType Property | Measure-Object).Count

Write-Host "numberOfObjectProperties:  $numberOfObjectProperties"

$containsAllKeys = $true

foreach ($header in $headers) {
    $containsAllKeys = $containsAllKeys -and $hash1.Keys -contains $header
}

Write-Host "containsAllKeys: $containsAllKeys"