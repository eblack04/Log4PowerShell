using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class FileAppender : Appender {
    
    [string]$logFilePath

    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\threadJob.jog"

    FileAppender([object]$config) : base($config) {
        $this.logFilePath = $config.path + "/" + $config.fileName

        # Delete the log file if the logger is not appending to an existing log
        # file.
        if (!$config.append -and (Test-Path -Path $this.logFilePath -PathType Leaf)) {
            Remove-Item -Path $this.logFilePath
        }

        Add-Content -Path $this.logFile -Value "Set logFilePath to:  $($this.logFilePath)"
    }

    [void] LogMessage([string]$message) {
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:  $message"
        Add-Content -Path $this.logFilePath -Value $message
    }
}