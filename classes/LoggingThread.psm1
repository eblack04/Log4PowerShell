using module ".\LogMessage.psm1"
using module ".\Appender.psm1"
using module "..\enums\LogLevel.psm1"

<#
.SYNOPSIS
    The main class that maintains the message queue for log messages going to an
    appender.
.DESCRIPTION
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

    # The maximum number of log messages received by this logging thread before 
    # the batched log messages need to be sent to the appender.
    [int]$MaxBatchSize = 50

    # The maximum number of characters the total length of all batched log
    # messages needs to execede before the batched log messages are sent to the
    # appender.
    [int]$MaxMessageLength = 4000

    # The PowerShell thread object that constantly listens for messages coming
    # in on the message queue.
    [Object]$Job

    # The last time that a single message, or batch of messages, were sent to
    # the appender.
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
                throw "Invalid appender type $($AppenderConfig.type): $_.Exception.Message"
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

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [void]Start() {

        $this.job = Start-ThreadJob -Name $this.appender.Name -ScriptBlock {
            param ($LoggingThread)

            # Track the last time messages were sent (for Google Chat batch processing)
            $lastSendTime = [datetime]::Now

            $batchedLogMessages = @()

            [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\threadJob-$($LoggingThread.Appender.Name).log"

            while ($true) {
                try {
                    $logMessageRef = $null
                    Add-Content -Path $logFile -Value "1"

                    # Pull the log messages off the main log queue, and store
                    # them in a temporary array.
                    $logMessages = @()
                    while ($LoggingThread.LogQueue.TryDequeue([ref]$logMessageRef)) {
                        Add-Content -Path $logFile -Value "log message: $($logMessageRef.GetMessage())"
                        $logMessages += $logMessageRef
                    }
                    Add-Content -Path $logFile -Value "Messages dequeued: $($logMessages.Count)"

                    if ($LoggingThread.IsBatched) {
                        # Add the current messages to the current batch of 
                        # messages.  
                        $batchedLogMessages += $logMessages

                        $batchedLogMessagesLength = ($batchedLogMessages | Measure-Object -Property MessageLength -Sum).Sum

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

                            $LoggingThread.Appender.LogMessages($batchedLogMessages)

                            # Reset the batched log messages array, and set the
                            # timestamp for the last time a message was sent.
                            $batchedLogMessages = @()
                            $lastSendTime = Get-Date
                        }
                    } else {
                        # If the logging thread is not configured to be a 
                        # batching thread, then pull the messages out of the
                        # batch queue, and distribute them directly to the 
                        # appenders.
                        Add-Content -Path $logFile -Value "The messages are not batched"
                        foreach ($logMessage in $logMessages) {
                            Add-Content -Path $logFile -Value "Non-batched message:  $($logMessage.GetMessage()), sending to appender $($LoggingThread.Appender.Name)"
                            $LoggingThread.Appender.LogMessage($logMessage)
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

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [void]LogMessage([LogMessage]$LogMessage) {
        if ($LogMessage.GetLogLevel() -le $this.LogLevel) {
            $this.logQueue.Enqueue($LogMessage)
        }
    }

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [void]Stop() {
        Write-Host "LoggingThread::Stop:  $($this.job.Name)"
        Stop-Job -Job $this.job 
        Remove-Job -Job $this.job
    }
}