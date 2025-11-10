$array1 = @("","","","")

if (($array1 -join "").length -gt 0) {
    Write-Host "It has at least one value"
} else {
    Write-Host "It's empty"
}

$array1 = @("","sdf","","")

if (($array1 -join "").length -gt 0) {
    Write-Host "It has at least one value"
} else {
    Write-Host "It's empty"
}