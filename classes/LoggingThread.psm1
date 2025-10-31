using module ".\LogMessage.psm1"
using module ".\Appender.psm1"
using module "..\enums\LogLevel.psm1"

<#
    This is the workhorse class for the logging system.  Each logging thread is
    in charge of distributing log messages to the appender stored within it as 
    an attribute.  In addition, if the appender is configured with message-
    batching configuration, then it is this class that is in charge of executing 
    the batching functionality.

    In general, each logging thread contains a reference to an internal thread
    job that receives log messages off of a message queue, and sends those 
    messages to the appender.
#>
[NoRunspaceAffinity()]
class LoggingThread {

    # The log message communications object from the main Logger instance, to 
    # each individual LoggingThread instance.
    [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]$LogQueue

    # The object that does something with the incoming log messages on the 
    # LogQueue object.
    [Appender]$Appender

    # The date pattern to use when creating the final log entry from the given
    # log message.
    [string]$DatePattern

    # The logging level to use when determining of log statements are processed
    # the Appender object.
    [LogLevel]$LogLevel

    # A boolean flag indicating whether or not log messages are currently being
    # taken off of the LogQueue object, and sent to the Appender object.
    [bool]$IsProcessing = $false

    # A boolean flag indicating whether or not log messages received by this 
    # logging thread are batched up first before being sent to the Appender 
    # object.
    [bool]$IsBatched = $false

    # The amount of time in seconds between batch message sendings.  If batching
    # is enabled for this logging thread, then log messages are saved up in a 
    # temporary list, joined together into a single message, and sent to the 
    # Appender object after this amount of time has passed.
    [int]$BatchInterval = 5

    [int]$MaxBatchSize = 50

    [int]$MaxMessageLength = 4000

    [Object]$Job

    [datetime]$LastSendTime

    <#
    .SYNOPSIS
        The default constructor for the logging thread class.
    .DESCRIPTION
        Uses the given appender configuration ojbect to create an appender 
        instance and initialize attributes needed by this class.
    #>
    LoggingThread([object]$AppenderConfig) {
        if(!$AppenderConfig) {
            throw "No appender configuration specified"
        }

        if($AppenderConfig.type) { 
            try {
                $this.Appender = New-Object -TypeName "$($AppenderConfig.type)Appender" -ArgumentList $AppenderConfig
            } catch{
                throw "Invalid appender type $($AppenderConfig.type)"
            }
        } else {
            throw "No appender class name specified in the configuration"
        }
        if($AppenderConfig.logLevel) { $this.LogLevel = [LogLevel]$AppenderConfig.logLevel} else { throw "No log level specified in the configuration"}
        if($AppenderConfig.datePattern) { $this.DatePattern = $AppenderConfig.pattern} else { throw "No date pattern specified in the configuration"}

        # If batching configuration is specified in the configuration, then set 
        # the batching parameters if they're present.
        if ($appenderConfig.batchConfig) {
            $this.IsBatched = $true
            if ($AppenderConfig.batchConfig.batchInterval) { $this.BatchInterval = $AppenderConfig.batchConfig.batchInterval }
            if ($AppenderConfig.batchConfig.maxBatchSize) { $this.MaxBatchSize = $AppenderConfig.batchConfig.maxBatchSize }
            if ($AppenderConfig.batchConfig.maxMessageLength) { $this.MaxMessageLength = $AppenderConfig.batchConfig.maxMessageLength }
        }

        # Initialize the queues.
        $this.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]::new()
    }

    [void]Start() {

        $this.job = Start-ThreadJob -Name $this.appender.Name -ScriptBlock {
            param ($LoggingThread)

            # Track the last time messages were sent (for Google Chat batch processing)
            $lastSendTime = [datetime]::Now

            $batchedLogMessages = @()

            [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\threadJob.jog"

            while ($true) {
                try {
                    $logMessageRef = $null
                    Add-Content -Path $logFile -Value "1"

                    # Pull the log messages off the main log queue, and store
                    # them in a temporary array.
                    $logMessages = @()
                    while ($LoggingThread.LogQueue.TryDequeue([ref]$logMessageRef)) {
                        Add-Content -Path $logFile -Value "log message: $($logMessageRef.GetMessage())"
                        $logMessages += $logMessageRef.GetMessage()
                    }
                    Add-Content -Path $logFile -Value "2"

                    if ($LoggingThread.IsBatched) {
                        # Add the current messages to the current batch of 
                        # messages.  
                        $batchedLogMessages += $logMessages

                        $batchedLogMessagesLength = ($batchedLogMessages | Measure-Object -Property Length -Sum).Sum

                        Add-Content -Path $logFile -Value "batchedLogMessagesLength: $($batchedLogMessagesLength)"
                        Add-Content -Path $logFile -Value "LoggingThread.MaxMessageLength: $($LoggingThread.MaxMessageLength)"
                        Add-Content -Path $logFile -Value "`n"
                        Add-Content -Path $logFile -Value "Now.TotalSeconds: $(((Get-Date) - $lastSendTime).TotalSeconds)"
                        Add-Content -Path $logFile -Value "LoggingThread.BatchInterval: $($LoggingThread.BatchInterval)"
                        Add-Content -Path $logFile -Value "`n"
                        Add-Content -Path $logFile -Value "batchedLogMessages.Count: $($batchedLogMessages.Count)"
                        Add-Content -Path $logFile -Value "LoggingThread.MaxBatchSize: $($LoggingThread.MaxBatchSize)"
                        Add-Content -Path $logFile -Value "$(((Get-Date) - $lastSendTime).TotalSeconds -ge $LoggingThread.BatchInterval)"

                        #=======================================================
                        # The batched messages are sent to the appender under
                        # three conditions:
                        #
                        # 1.  The amount of time between batch sendings has 
                        #     occurred (BatchInterval).
                        # 2.  The size of the batched message is equal to or
                        #     greater than the maximum batch message size
                        #     (MaxMessageLength).
                        # 3.  The number of messages in the batch is equal to 
                        #     the maximum allowed batch size (MaxBatchSize).
                        #=======================================================
                        if ($batchedLogMessagesLength -ge $LoggingThread.MaxMessageLength -or
                            ((Get-Date) - $lastSendTime).TotalSeconds -ge $LoggingThread.BatchInterval -or
                            $batchedLogMessages.Count -ge $LoggingThread.MaxBatchSize) {

                            $formattedBatchedMessage = ""
                            foreach ($batchedLogMessage in $batchedLogMessages) {
                                Add-Content -Path $logFile -Value "Sending message:  $batchedLogMessage"
                                $formattedBatchedMessage += "$(Get-Date -Format $this.datePattern): $batchedLogMessage`n"
                            }

                            $LoggingThread.Appender.LogMessage($formattedBatchedMessage)
                            $batchedLogMessages = @()
                            $lastSendTime = Get-Date
                        }
                    } else {
                        # If the logging thread is not configured to be a 
                        # batching thread, then pull the messages out of the
                        # batch queue, and distribute them directly to the 
                        # appenders.
                        Add-Content -Path $logFile -Value "3"
                        foreach ($logMessage in $logMessages) {
                            Add-Content -Path $logFile -Value "4"
                            $Appender.LogMessage($logMessage)
                        }
                    }
                } catch {
                    $errorMessage = "ERROR | Log processing error: $($_.Exception.Message)"
                    Add-Content -Path $logFile -Value "Error: $errorMessage"
                    Write-Error $errorMessage -ForegroundColor Red
                }

                Start-Sleep -Milliseconds $10
            }
        } -ArgumentList $this

        Write-Host "Job type:  $($this.job.GetType())"
    }

    [bool]IsIdle() {
        return $true
    }

    [void]LogMessage([LogMessage]$logMessage) {
        if ($logMessage.GetLevel() -le $this.LogLevel) {
            $this.logQueue.Enqueue($logMessage)
        }
    }

    [void]Stop() {
        Write-Host "LoggingThread::Stop:  $($this.job.Name)"
        Stop-Job -Job $this.job 
        Remove-Job -Job $this.job
    }
}