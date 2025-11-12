using module ".\modules\VMware.Logging.psm1"

<#
$jsonContent = Get-Content -Path $ConfigFile -Raw -Encoding UTF8
$configObject = $jsonContent | ConvertFrom-Json
$appenders = $configObject.appenders

foreach ($appender in $appenders) {
    Write-Host "Appender: $($appender.Name)"
}
#>
$logger = $global:Logger

if ($logger) {
    $logger.Stop()
}

$global:Logger = $null