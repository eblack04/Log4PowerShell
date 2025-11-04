using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

<#
.SYNOPSIS
    An appender implementation that writes log messages to a file.
.DESCRIPTION
    This class is an implementation of the Appender class that writes log 
    messages to a file.
#>
[NoRunspaceAffinity()]
class FileAppender : Appender {
    
    [string]$LogFilePath

    ###### Temp ######
    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\file-appender.log"
    ##################

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    FileAppender([object]$Config) : base($Config) {

        if (-not $Config.path) { throw "No file path specified" }
        if (-not $Config.fileName) { throw "No file name specified" }

        $this.LogFilePath = $Config.path + "/" + (Convert-ToTimestampFileName -FileName $Config.fileName)

        # Delete the log file if the logger is not appending to an existing log
        # file.
        if (!$Config.append -and (Test-Path -Path $this.LogFilePath -PathType Leaf)) {
            Remove-Item -Path $this.LogFilePath
        }

        Add-Content -Path $this.logFile -Value "Set LogFilePath to:  $($this.LogFilePath)"
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    [void] LogMessage([LogMessage]$LogMessage) {
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)): $($LogMessage.GetMessage())"
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog: $($this.LogFilePath):$formattedMessage"
        Add-Content -Path $this.LogFilePath -Value $formattedMessage
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:after writing:  $formattedMessage"
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    [void] LogMessages([LogMessage[]]$LogMessages) {
        foreach ($LogMessage in $LogMessages) {
            $this.LogMessage($LogMessage)
        }
    }
}