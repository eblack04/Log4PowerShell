function New-LogMessage() {
    <#
    .SYNOPSIS
        Creates a new LogMessage object.
    .DESCRIPTION
        This function instantiates a new LogMessage object by invoking its constructor 
        with the specified message and logging level.
    .PARAMETER Message
        The log message to encapsulate inside the LogMessage object.
    .PARAMETER LogLevel
        The level of the log message
    .EXAMPLE
        $logger = New-LogMessage -Message "a log message" -LogLevel [LogLevel]::DEBUG
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Message,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][LogLevel]$LogLevel
    )

    return [LogMessage]::new($Message, $LogLevel)
}