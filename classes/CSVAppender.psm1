using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class CSVAppender : Appender {
    
    [string]$LogFilePath

    [string[]]$Headers

    [bool]$ValuesMandatory = $false

    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\csv-appender.log"

    CSVAppender([object]$config) : base($config) {
        $this.LogFilePath = $config.path + "/" + $config.fileName

        # Delete the log file if the logger is not appending to an existing log
        # file.
        if (!$config.append -and (Test-Path -Path $this.logFilePath -PathType Leaf)) {
            Remove-Item -Path $this.logFilePath
        }

        $this.Headers = $config.headers.Split(",")
        $this.ValuesMandatory = $config.valuesMandatory
        Add-Content -Path $this.LogFilePath -Value $config.headers

        Add-Content -Path $this.logFile -Value "Set logFilePath to:  $($this.logFilePath)"
    }

    [void] LogMessage([LogMessage]$LogMessage) {
        Add-Content -Path $this.logFile -Value "CSVAppender::LogMessage.GetMessage():  $($LogMessage.GetMessage()))"

        $containsAllKeys = $true
        $messageValues = @()

        # This 'for' loop retrieves all the values for each column in the CSV
        # file.  If any of the column values are missing, then the log entry is
        # skipped.
        foreach ($header in $this.Headers) {
            $messageValue = $LogMessage.GetMessageHash()[$header]

            if ($messageValue) {
                $messageValues += $messageValue
            } else {
                $messageValues += ""
                $containsAllKeys = $false
            }
        }

        if (($containsAllKeys -and $this.ValuesMandatory) -or (-not $this.ValuesMandatory)) {
            $csvMessage = $messageValues -Join ","
            Add-Content -Path $this.logFile -Value "CSVAppender::LogMessage:  $csvMessage)"

            # After processing all the properties, just returned the array as a 
            # joined string.
            Add-Content -Path $this.logFilePath -Value $csvMessage
        }
    }

    [void] LogMessages([LogMessage[]]$LogMessages) {
        foreach ($logMessage in $LogMessages) {
            $this.LogMessage($logMessage)
        }
    }
}