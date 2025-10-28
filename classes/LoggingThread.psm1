using module ".\LogMessage.psm1"
using module ".\Appender.psm1"
using module ".\ConsoleAppender.psm1"

<#
Each appender will exist within a thread where the thread reads messages off of
a queue, and feeds those messages to the appender.
#>

[NoRunspaceAffinity()]
class LoggingThread {

    # The log message communications object from the main Logger instance, to 
    # each individual LoggingThread instance.
    [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]$logQueue

    # Provides the ability to cache log messages before sending them out to 
    # appender object stored within this object.  This helps to conserve CPU
    # usage by not constantly checking for messages off of the queue and 
    # instantly writing them.
    [System.Collections.Concurrent.ConcurrentQueue[string]]$messageBatch

    [Appender]$appender

    [bool]$isBatched = $false

    [int]$batchInterval = 5

    [int]$maxBatchSize = 50

    [int]$maxMessageLength = 4000

    [int]$retryInterval = 10

    [Object]$job

    LoggingThread([Appender]$appender) {
        if(!$appender) {
            throw "No appender specified"
        }

        $this.appender = $appender

        # Initialize the queues.
        $this.logQueue = [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]::new()

        if ($this.isBatched) {
            $this.messageBatch = [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]::new()
        }
    }

    [void]Start() {

        $this.job = Start-ThreadJob -Name $this.appender.Name -ScriptBlock {
            param ($Appender, $LogQueue, $IsBatched)

            # Track the last time messages were sent (for Google Chat batch processing)
            $lastSendTime = [datetime]::Now

            [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\threadJob.jog"

            while ($true) {
                try {
                    $logMessages = @()
                    $logMessageRef = $null
                    Add-Content -Path $logFile -Value "1"
                    while ($LogQueue.TryDequeue([ref]$logMessageRef)) {
                        Add-Content -Path $logFile -Value "log message: $($logMessageRef.GetMessage())"
                        $logMessages += $logMessageRef.GetMessage()
                    }
                    Add-Content -Path $logFile -Value "2"
                    if ($IsBatched) {
                        # Check if we need to force-send any batched messages that haven't been sent due to batch size
                        $now = [datetime]::Now
                        $timeElapsed = ($now - $lastSendTime).TotalSeconds

                        if ($timeElapsed -ge $this.batchInterval -and $this.messageBatch.Count -gt 0) {
                            # Time to send the current batch
                            
                        }
                    } else {
                        Add-Content -Path $logFile -Value "3"
                        foreach ($logMessage in $logMessages) {
                            Add-Content -Path $logFile -Value "4"
                            $Appender.LogMessage($logMessage)
                        }
                    }
                } catch {
                    $errorMessage = "ERROR | Log processing error: $($_.Exception.Message)"
                    Write-Error $errorMessage -ForegroundColor Red
                }

                Start-Sleep -Milliseconds $10

                <#try {
                    Add-Content -Path $logFile -Value "1"
                    $logMessages = @()
                    Add-Content -Path $logFile -Value "2"
                    $logMessageRef = $null
                    Add-Content -Path $logFile -Value "3"
                    while ($LogQueue.TryDequeue([ref]$logMessageRef)) {
                        Add-Content -Path $logFile -Value "logMessageRef:  $($logMessageRef.GetMessage())"
                        $logMessages += $logMessageRef.GetMessage()
                    }
                    Add-Content -Path $logFile -Value "5"    
                    # Process all collected events
                    Add-Content -Path $logFile -Value "Number of log messages: $($logMessages.Count)"
                    foreach ($logMessage in $logMessages) {
                        Add-Content -Path $logFile -Value "Sending $logMessage to appender $($Appender.GetName())"
                        #Write-Host "$($Appender | Get-Member -MemberType Method)"
                        $Appender.LogMessage($logMessage)
                        Add-Content -Path $logFile -Value "done"
                    }
                    Add-Content -Path $logFile -Value "8"
                    # Only sleep if we didn't process any messages to prevent high CPU usage
                    if (($logMessages.Count -eq 0 -and $logEvents.Count -eq 0) -or (-not $IsCSVLogger -and -not $IsGoogleChatLogger -and $logMessages.Count -eq 0)) {
                        Add-Content -Path $logFile -Value "9"
                        Start-Sleep -Milliseconds 10
                    }
                }
                catch {
                    $logMessage = "ERROR | Log processing error: $($_.Exception.Message)"
                    Add-Content -Path $logFile -Value $logMessage
                    Write-Host $logMessage -ForegroundColor Red
                    
                    # Try to log the error through the logger if possible
                    try {
                        $Appender.LogMessage($logMessage)
                    } 
                    catch {
                        # Last resort, write to console if logger fails
                        Add-Content -Path $logFile -Value "CRITICAL ERROR: Failed to log error through logger: $($_.Exception.Message)"
                        Write-Host "CRITICAL ERROR: Failed to log error through logger: $($_.Exception.Message)" -ForegroundColor Red
                    }
                    
                    Start-Sleep -Milliseconds 10  # Prevent high CPU usage.
                }
                Add-Content -Path $logFile -Value "10"
                # Sleep between checks to avoid high CPU usage
                Start-Sleep -Milliseconds 10
                Add-Content -Path $logFile -Value "11"
                #>
            }
        } -ArgumentList ($this.appender, $this.logQueue, $this.isBatched) #-StreamingHost (Get-Host)

        Write-Host "Job type:  $($this.job.GetType())"
    }

    [bool]IsIdle() {
        return $true
    }

    [void]LogMessage([LogMessage]$logMessage) {
        if ($logMessage.GetLevel() -le $this.appender.GetLevel()) {
            $this.logQueue.Enqueue($logMessage)
            #Receive-Job -Job $this.job
        }
    }

    [void]Stop() {
        Write-Host "LoggingThread::Stop:  $($this.job.Name)"
        Stop-Job -Job $this.job 
        Remove-Job -Job $this.job
    }
}