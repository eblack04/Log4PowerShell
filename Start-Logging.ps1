using module ".\modules\VMware.Logging.psm1"

param (
    [parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][string]$ConfigFile = "./config/logging.json"
)
<#
$jsonContent = Get-Content -Path $ConfigFile -Raw -Encoding UTF8
$configObject = $jsonContent | ConvertFrom-Json
$appenders = $configObject.appenders

foreach ($appender in $appenders) {
    Write-Host "Appender: $($appender.Name)"
}
#>
$logger = [Logger]::new($ConfigFile)
$logger.Start()
$global:Logger = $logger 