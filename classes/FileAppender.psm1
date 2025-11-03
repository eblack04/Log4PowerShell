using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class FileAppender : Appender {
    
    [string]$LogFilePath

    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\file-appender.log"

    FileAppender([object]$config) : base($config) {
        $this.LogFilePath = $config.path + "/" + $config.fileName

        # Delete the log file if the logger is not appending to an existing log
        # file.
        if (!$config.append -and (Test-Path -Path $this.LogFilePath -PathType Leaf)) {
            Remove-Item -Path $this.LogFilePath
        }

        Add-Content -Path $this.logFile -Value "Set LogFilePath to:  $($this.LogFilePath)"
    }

    [void] LogMessage([LogMessage]$LogMessage) {
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)): $($LogMessage.GetMessage())"
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:  $formattedMessage"
        Add-Content -Path $this.LogFilePath -Value $formattedMessage
    }

    [void] LogMessages([LogMessage[]]$LogMessages) {
        foreach ($LogMessage in $LogMessages) {
            $this.LogMessage($LogMessage)
        }
    }
}