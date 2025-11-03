using module "..\classes\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

$messageHash = @{
    "vCenter" = "vcsa-01a.vmware.com"
    "Datacenter" = "dc-01a"
    "Cluster" = "c-01a"
}
Write-Host "messageHash.Keys.Count:  $($messageHash.Keys.Count)"

$logMessage1 = [LogMessage]::new($messageHash, [LogLevel]::DEBUG)

Write-Host "Message Length:  $($logMessage1.GetMessageLength())"
Write-Host "Message:  $($logMessage1.GetMessage())"

$logMessage2 = [LogMessage]::new("hello world", [LogLevel]::DEBUG)

Write-Host "Message Length:  $($logMessage2.GetMessageLength())"
Write-Host "Message:  $($logMessage2.GetMessage())"