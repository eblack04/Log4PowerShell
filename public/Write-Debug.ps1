function Write-Debug {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$Message
    )

    $logMessage = [LogMessage]::new($Message, [LogLevel]::DEBUG)
    $global:Logger.LogMessage($logMessage)
}