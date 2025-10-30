using module ".\LogMessage.psm1"
using module ".\Appender.psm1"
using module "..\enums\LogLevel.psm1"

<#
Each appender will exist within a thread where the thread reads messages off of
a queue, and feeds those messages to the appender.
#>

[NoRunspaceAffinity()]
class LoggingThread {

    # The log message communications object from the main Logger instance, to 
    # each individual LoggingThread instance.
    [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]$LogQueue

    # Provides the ability to cache log messages before sending them out to 
    # appender object stored within this object.  This helps to conserve CPU
    # usage by not constantly checking for messages off of the queue and 
    # instantly writing them.
    [System.Collections.Concurrent.ConcurrentQueue[string]]$MessageBatch

    [Appender]$Appender

    [string]$DatePattern

    [LogLevel]$LogLevel

    [bool]$IsProcessing = $false

    [bool]$IsBatched = $false

    [int]$BatchInterval = 5

    [int]$MaxBatchSize = 50

    [int]$MaxMessageLength = 4000

    [int]$RetryInterval = 10

    [Object]$Job

    [datetime]$LastSendTime

    LoggingThread([object]$AppenderConfig) {
        if(!$AppenderConfig) {
            throw "No appender configuration specified"
        }

        if($AppenderConfig.type) { 
            $this.Appender = New-Object -TypeName "$($AppenderConfig.type)Appender" -ArgumentList $AppenderConfig 
        } else {
            throw "No appender class name specified in the configuration"
        }
        if($AppenderConfig.level) { $this.LogLevel = [LogLevel]$AppenderConfig.level} else { throw "No log level specified in the configuration"}
        if($AppenderConfig.datePattern) { $this.DatePattern = $AppenderConfig.pattern} else { throw "No date pattern specified in the configuration"}

        # If batching configuration is specified in the configuration, then set 
        # the batching parameters if they're present.
        if ($appenderConfig.batchConfig) {
            $this.IsBatched = $true
            if ($AppenderConfig.batchConfig.maxRetryAttempts) { $this.BatchInterval = $AppenderConfig.batchConfig.maxRetryAttempts }
            if ($AppenderConfig.batchConfig.batchInterval) { $this.BatchInterval = $AppenderConfig.batchConfig.batchInterval }
            if ($AppenderConfig.batchConfig.maxBatchSize) { $this.MaxBatchSize = $AppenderConfig.batchConfig.maxBatchSize }
            if ($AppenderConfig.batchConfig.maxMessageLength) { $this.MaxMessageLength = $AppenderConfig.batchConfig.maxMessageLength }
            if ($AppenderConfig.batchConfig.retryInterval) { $this.RetryInterval = $AppenderConfig.batchConfig.retryInterval }
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

                        # The batched messages are sent to the appenders under
                        # three conditions:
                        #
                        # 1.  The amount of time between batch sendings has 
                        #     occurred.
                        # 2.  The size of the batched message is equal to or
                        #     greater than the maximum batch message size.
                        # 3.  The number of messages in the batch is equal to 
                        #     the maximum allowed batch size.

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
                        # batch queue, and distribute them to the appenders.
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
            #Receive-Job -Job $this.job
        }
    }

    [void]Stop() {
        Write-Host "LoggingThread::Stop:  $($this.job.Name)"
        Stop-Job -Job $this.job 
        Remove-Job -Job $this.job
    }

    [void] SendMessageBatch([Appender]$appender) {
        if ($this.batchQueue.Count -eq 0) {
            return
        }

        try {
            $this.isProcessing = $true

            # Collect all messages from the batch queue
            $messagesToSend = @()
            $message = $null
            
            # Dequeue all messages from the batch
            while ($this.batchQueue.TryDequeue([ref]$message)) {
                $messagesToSend += $message
            }
            
            # If no messages were dequeued, return
            if ($messagesToSend.Count -eq 0) {
                return
            }

            $retryCount = 0
            $success = $false
            $lastError = $null
        
            while ($retryCount -lt $this.maxRetryAttempts -and -not $success) {
                try {
                    # Combine messages into a single formatted text
                    $batchedMessage = $messagesToSend -join "`n"
                
                    # Truncate if too long
                    if ($batchedMessage.Length -gt $this.maxMessageLength) {
                        $batchedMessage = $batchedMessage.Substring(0, $this.maxMessageLength - 100) + "`n... (truncated)"
                    }
                
                    $Appender.LogMessage($batchedMessage)
                
                    # If we get here, the request was successful
                    $success = $true
                    $this.lastSendTime = Get-Date
                
                    # Log success if we had previous failures
                    if ($retryCount -gt 0) {
                        Write-Verbose "googleChatLogger ($($this.logName)): Successfully sent message batch of $($messagesToSend.Count) messages after $retryCount retries."
                    }
                }
                catch {
                    $lastError = $_
                    $retryCount++
                
                    if ($retryCount -lt $this.config.MaxRetryAttempts) {
                        $waitTime = $this.config.RetryIntervalSeconds * $retryCount
                        Write-Warning "googleChatLogger ($($this.logName)): Failed to send message batch (attempt $retryCount/$($this.config.MaxRetryAttempts)). Retrying in $waitTime seconds. Error: $($_.Exception.Message)"
                        Start-Sleep -Seconds $waitTime
                    }
                    else {
                        Write-Error "googleChatLogger ($($this.logName)): Failed to send message batch after $($this.config.MaxRetryAttempts) attempts. Final error: $($_.Exception.Message)"
                    
                        # Re-enqueue failed messages back to the batch for next attempt
                        foreach ($msg in $messagesToSend) {
                            $this.messageBatch.Enqueue($msg)
                        }
                        
                        # Also log them to console as fallback
                        Write-Host "FAILED TO SEND MESSAGES (re-queued for next attempt):" -ForegroundColor Red
                        foreach ($msg in $messagesToSend) {
                            Write-Host $msg -ForegroundColor Yellow
                        }
                    
                        $this.lastSendTime = Get-Date
                    }
                }
            }
        }
        finally {
            $this.isProcessing = $false
        }
    }
}