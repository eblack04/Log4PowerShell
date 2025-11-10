$messageHash = [ordered]@{
    "param1" = "value1"
    "param2" = "value2"
    "param3" = "value3"
}

if ($messageHash.Contains("param5")) {
    Write-Host "yes"
} else {
    Write-Host "no"
}