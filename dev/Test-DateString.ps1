$fileName = "file-%d{MM-dd-yyyy-HH:mm:ss}-log.log"
Write-Host "fileName: $fileName"
$datePattern = [regex]::Match($fileName, ".*%d{(.*)}.*")
Write-Host "datePattern: $datePattern"

if ($datePattern.Success) {
    $pattern = $datePattern.Groups[1].Value
    Write-Host "pattern: $pattern"
    $timestamp = Get-Date -Format $pattern
    Write-Host "timestamp: $timestamp"
    $fileName = $fileName -replace "%d{.*}", $timestamp
    Write-Host "fileName: $fileName"
} else {
    Write-Host "Doesn't match"
}