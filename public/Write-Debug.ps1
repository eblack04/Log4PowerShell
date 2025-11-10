function Write-Debug {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][object]$Message
    )

    $logMessage = [LogMessage]::new($Message, [LogLevel]::DEBUG)
    $global:Logger.LogMessage($logMessage)
}