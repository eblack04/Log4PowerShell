function Write-Info {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$Message
    )

    $logMessage = [LogMessage]::new($Message, [LogLevel]::INFO)
    $global:Logger.LogMessage($logMessage)
}