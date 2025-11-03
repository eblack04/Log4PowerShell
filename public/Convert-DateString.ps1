function Convert-DateString {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$DateString
    )

    $datePattern = [regex]::Match($DateString, ".*%d{(.*)}.*")

    if ($datePattern.Success) {
        $pattern = $datePattern.Groups[1].Value
        $timestamp = Get-Date -Format $pattern
        return $DateString -replace "%d{.*}", $timestamp
    } else {
        return $DateString
    }
}

$testString1 = "file-%d{MM-dd-yyyy-HH:mm:ss}-log.log"
Write-Host "testString1: $testString1"
$formattedString1 = Convert-DateString -DateString $testString1
Write-Host "formattedString1: $formattedString1"

$testString2 = "file-%d{MM-dd-yyyy}-log.log"
Write-Host "testString2: $testString2"
$formattedString2 = Convert-DateString -DateString $testString2
Write-Host "formattedString2: $formattedString2"