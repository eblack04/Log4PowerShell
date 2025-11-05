using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"
using module "..\enums\RolloverPolicy.psm1"

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

    [RolloverPolicy]$RolloverPolicy = [RolloverPolicy]::NONE

    [int]$RolloverFileSize = 10Mb

    [int]$RolloverFileNumber = 5

    [int]$RolloverFileCounter = 1

    [datetime]$LastRolloverTime = (Get-Date)

    ###### Temp ######
    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\file-appender.log" # Remove
    ##################

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    FileAppender([object]$Config) : base($Config) {

        if (-not $Config.path) { throw "No file path specified" }
        if (-not $Config.fileName) { throw "No file name specified" }
        if ($Config.rolloverPolicy -and -not [Enum]::IsDefined([RolloverPolicy], $Config.rolloverPolicy.ToUpper())) { throw "Invalid rollover policy $($Config.rolloverPolicy)"}

        $this.LogFilePath = $Config.path + "/" + (Convert-ToTimestampFileName -FileName $Config.fileName)

        # If there is no rollover policy defined, then set up the single-file
        # configuration.
        if (-not $Config.rolloverPolicy -or $Config.rolloverPolicy -eq [RolloverPolicy]::NONE.ToString()) {
            # Delete the log file if the logger is not appending to an existing log
            # file.
            if (!$Config.append -and (Test-Path -Path $this.LogFilePath -PathType Leaf)) {
                Remove-Item -Path $this.LogFilePath
            }

            Add-Content -Path $this.logFile -Value "Set LogFilePath to:  $($this.LogFilePath)"
        } else {
            if ($Config.rolloverFileSize) { $this.RolloverFileSize = $Config.rolloverFileSize -as [double]}
            if ($Config.rolloverFileNumber) { $this.RolloverFileNumber = $Config.rolloverFileNumber}

            $this.RolloverPolicy = [RolloverPolicy]$Config.rolloverPolicy
            Add-Content -Path $this.logFile -Value "Rollover policy:  $($this.RolloverPolicy)" # Remove
            $this.LogFilePath = Add-FileNameCounter -FileName $this.LogFilePath -Counter $this.RolloverFileCounter
            Add-Content -Path $this.logFile -Value "Set LogFilePath to:  $($this.LogFilePath)" # Remove

            Add-Content -Path $this.logFile -Value "Rollover file number:  $($this.RolloverFileNumber)" # Remove
            Add-Content -Path $this.logFile -Value "Rollover file size:  $($this.RolloverFileSize)" # Remove
        }
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    [void] LogMessage([LogMessage]$LogMessage) {
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)): $($LogMessage.GetMessage())"
        
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog: $($this.LogFilePath):$formattedMessage"

        if ($this.RolloverPolicy) {

            $triggerRollover = $false

            Add-Content -Path $this.logFile -Value "Rollover policy:  $($this.RolloverPolicy)" # Remove
            switch ($this.RolloverPolicy) {
                ([RolloverPolicy]::SIZE) {
                    Add-Content -Path $this.logFile -Value "Rollover policy is SIZE" # Remove
                    
                    # If the size of the current log file is greater than the 
                    # configured limit, then roll the log file to the next one.
                    Add-Content -Path $this.logFile -Value "File size: $((Get-ChildItem -Path $this.LogFilePath).Length)" # Remove
                    Add-Content -Path $this.logFile -Value "Rollover file size: $($this.RolloverFileSize)" # Remove
                    if(((Get-ChildItem -Path $this.LogFilePath).Length + $formattedMessage.Length) -gt $this.RolloverFileSize) {
                        $triggerRollover = $true
                    } 
                }
                ($_ -in @([RolloverPolicy]::MINUTE, [RolloverPolicy]::HOURLY, [RolloverPolicy]::DAILY,[RolloverPolicy]::WEEKLY)) {
                    $timeDifference = (Get-Date) - $this.LastRolloverTime

                    if ($timeDifference.Minutes -gt $_.Value__) {
                        $triggerRollover = $true
                    }
                }
            }

            if ($triggerRollover) {
                # This 'if' statement determines the index of the next file in the rollover list.
                Add-Content -Path $this.logFile -Value "Log file $($this.LogFilePath) is greater than size $($this.RolloverFileSize)" # Remove
                if($this.RolloverFileCounter + 1 -gt $this.RolloverFileNumber) {
                    Add-Content -Path $this.logFile -Value "Setting the RolloverFileCounter to 1" # Remove
                    $this.RolloverFileCounter = 1
                } else {
                    Add-Content -Path $this.logFile -Value "Setting the RolloverFileCounter to $($this.RolloverFileCounter + 1)" # Remove
                    $this.RolloverFileCounter++
                }
                Add-Content -Path $this.logFile -Value "Rollover file counter: $($this.RolloverFileCounter)" # Remove
                Add-Content -Path $this.logFile -Value "Log file path: $($this.LogFilePath)" # Remove
                            
                # This regular expression and 'if' statement removes the
                # current rollover index from the name, and inserts the
                # next one.
                $matchResults = [regex]::Match($this.LogFilePath, "(.*)(\d+)([.].*)")
                if ($matchResults.Success) {
                    $this.LogFilePath = $matchResults.Groups[1].Value + $this.RolloverFileCounter + $matchResults.Groups[3].Value
                }

                Add-Content -Path $this.logFile -Value "Changed log file name to $($this.LogFilePath)" # Remove

                # After setting the log file name to the next name in 
                # rollover list, delete the file if it currently 
                # exists to rollover on top of it.
                if (Test-Path -Path $this.LogFilePath -PathType Leaf) {
                    Remove-Item -Path $this.LogFilePath
                }
            }
        }

        Add-Content -Path $this.LogFilePath -Value $formattedMessage
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:after writing:  $formattedMessage" # Remove
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

    hidden [string] formatMessage([LogMessage]$LogMessage) {
        return "$($LogMessage.GetTimestamp().ToString($this.DatePattern)): $($LogMessage.GetMessage())"
    }
}