using module "../modules/Log4PowerShell.psm1"

$rollingPolicy = [RollingPolicy]::SIZE

switch ($rollingPolicy) {
    ([RollingPolicy]::SIZE) {
        Write-Host "It's SIZE"
    }
}