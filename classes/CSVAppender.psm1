using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class CSVAppender : Appender {
    
    [string]$LogFilePath

    [string[]]$Headers

    [bool]$ValuesMandatory = $false

    ########## Temp #########
    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\csv-appender.log"
    #########################

    CSVAppender([object]$Config) : base($Config) {
        if (-not $Config.path) { throw "No file path specified" }
        if (-not $Config.fileName) { throw "No file name specified" }        

        $this.LogFilePath = $Config.path + "/" + (Convert-ToTimestampFileName -FileName $Config.fileName)

        # Delete the log file if the logger is not appending to an existing log
        # file.
        if (!$Config.append -and (Test-Path -Path $this.logFilePath -PathType Leaf)) {
            Remove-Item -Path $this.logFilePath
        }

        if ($Config.Headers) { $this.Headers = $Config.headers.Split(",") }
        if ($Config.ValuesMandatory) { $this.ValuesMandatory = $Config.valuesMandatory }

        Add-Content -Path $this.LogFilePath -Value $Config.headers
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