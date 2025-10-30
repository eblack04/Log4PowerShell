$stringArray1 = @("string1", "string2", "string3")
$stringArray2 = @("string4", "string5", "string6")

$stringArray3 = $stringArray1 + $stringArray2
Write-Host "stringArray3.Count: $($stringArray3.Count)"

$arrayLength1 = ($stringArray1 | Measure-Object -Property Length -Sum).Sum
Write-Host "arrayLength1:  $arrayLength1"

$arrayLength2 = ($stringArray2 | Measure-Object -Property Length -Sum).Sum
Write-Host "arrayLength2:  $arrayLength2"

$arrayLengthBoth = ($stringArray1 + $stringArray2 | Measure-Object -Property Length -Sum).Sum
Write-Host "arrayLengthBoth:  $arrayLengthBoth"

[datetime]$lastSendTime = [datetime]::Now
[int]$batchInterval = 1
Start-Sleep -Seconds 2
$elapsedTime = ((Get-Date) - $lastSendTime).TotalSeconds

Write-Host "elapsedTime:  $elapsedTime"
Write-Host "batchInterval:  $batchInterval"

if ($elapsedTime -ge $batchInterval) {
    Write-Host "its greater"
} else {
    Write-Host "its lesser"
}