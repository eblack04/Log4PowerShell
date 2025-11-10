using module ".\FileAppender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class CSVAppender : FileAppender {

    [string[]]$Headers

    [bool]$ValuesMandatory = $false

    ###### Temp ######
    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\csv-appender.log" # Remove
    ##################

    CSVAppender([object]$Config) : base($Config) {
        if ($Config.Headers) { $this.Headers = $Config.headers.Split(",") }
        if ($Config.ValuesMandatory) { $this.ValuesMandatory = $Config.valuesMandatory }
        Add-Content -Path $this.logFile -Value "CSVAppender::constructor::Headers  $($this.Headers)"
        Add-Content -Path $this.logFile -Value "CSVAppender::constructor::ValuesMandatory  $($this.ValuesMandatory)"
    }

    hidden [void] addFileHeader() {
        Add-Content -Path $this.logFile -Value "Adding headers: $($this.Config.headers) to file $($this.LogFilePath)"
        Add-Content -Path $this.LogFilePath -Value $this.Config.headers
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
    #>
    hidden [string] formatMessage([LogMessage]$LogMessage) {
        $containsAllKeys = $true
        $containsNonTimestampValue = $false
        $messageValues = @()
        $csvMessage = $null#$LogMessage.GetMessage()

        # This 'for' loop retrieves all the values for each column in the CSV
        # file.  If any of the column values are missing, then the log entry is
        # skipped.
        foreach ($header in $this.Headers) {
            if ($header -eq "Timestamp") {
                Add-Content -Path $this.logFile -Value "Date pattern:  $($this.DatePattern)"
                Add-Content -Path $this.logFile -Value "Timestamp from message:  $($this.Timestamp)"
                $messageValue = $LogMessage.GetTimestamp().ToString($this.DatePattern)
            } else {
                $messageValue = $LogMessage.GetMessageHash()[$header]
                Add-Content -Path $this.logFile -Value "messageValue:  $messageValue"
                if($messageValue) { $containsNonTimestampValue = $true }
                Add-Content -Path $this.logFile -Value "containsNonTimestampValue:  $containsNonTimestampValue"
            }

            if ($messageValue) {
                Add-Content -Path $this.logFile -Value "messageValue is not null:  $messageValue"
                $messageValues += $messageValue
            } else {
                Add-Content -Path $this.logFile -Value "messageValue not found"
                $messageValues += ""
                $containsAllKeys = $false
            }
        }

        #=======================================================================
        # Okay, this if statement adds an entry to the CSV file under the
        # following two conditions:
        #
        # 1.  All columns have values and the ValuesMandatory flag is 'true'.
        # 2.  There is at least one non-timestamp column with a value, and the 
        #     ValuesMandatory flag is 'false'.
        #=======================================================================
        if (($containsAllKeys -and $this.ValuesMandatory) -or `
            ((-not $this.ValuesMandatory) -and (($messageValues -join "").length -gt 0) -and $containsNonTimestampValue)) {
            Add-Content -Path $this.logFile -Value "Joining the fields"
            $csvMessage = $messageValues -Join ","
        }

        Add-Content -Path $this.logFile -Value "csvMessage:  $csvMessage"

        return $csvMessage
    }
}