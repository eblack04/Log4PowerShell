function New-LogMessage() {
    <#
    .SYNOPSIS
        Creates a new FileLogger object.
    
    .DESCRIPTION
        This function instantiates a new FileLogger object by invoking its constructor 
        with the specified file path and logger name. The FileLogger is used for logging 
        messages to a file located at the provided path.
    
    .PARAMETER Path
        The file system path where the log file will be created and maintained.
    
    .PARAMETER Name
        The name of the logger instance. This name is typically used to identify the log file.
    
    .EXAMPLE
        $logger = New-FileLogger -Path "./Logs" -Name "ApplicationLog"
    
        This example creates a new FileLogger object that writes logs to the "./Logs" directory 
        with the name "ApplicationLog".
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Message,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][LogLevel]$LogLevel
    )

    return [LogMessage]::new($Message, $LogLevel)
}