try {
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path
    $modulePath = "$scriptPath/../modules/"
}
catch {
    Write-Error "ERROR | Failed to set path: $($_.Exception.Message)"
    throw
}

Import-Module "$modulePath/Test-Module" -ErrorAction Stop

Get-First -First "AFirstString"

Get-Second -Second "ASecondString"

Get-Third -Third "AThirdString"