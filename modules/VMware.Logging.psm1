# ====================================================================================
# Module: VMware.Logging
# Version: 1.0
# Generated: 10-29-2025 16:44:55
# Description: Module for managing vSphere Lifecycle
# ====================================================================================
# -------------------------------------------------------------------------
# Start: Class Definition - Appender
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    The base class for all logging appenders.  

.DESCRIPTION
    Appenders are the construct that stores or sends a logging statement to a 
    storage mechanism or service.  Implementations of this class provide a
    specific technique for storing or sending a logging message, suchs as to a
    file, or to the console.

.NOTES
    Author: Todd Blackwell
#>
[NoRunspaceAffinity()]
class Appender {

    [string]$name

    [LogLevel]$level

    [string]$datePattern

    Appender([object]$config) {
        if($config) {
            if($config.name) { $this.name = $config.name} else { throw "No name specified in the configuration"}
            if($config.level) { $this.level = [LogLevel]$config.level} else { throw "No log level specified in the configuration"}
            if($config.datePattern) { $this.datePattern = $config.pattern} else { throw "No date pattern specified in the configuration"}
        } else {
            throw "Appender configuration not specified"
        }
    }

    <#
    .SYNOPSIS
        Returns the name of the appender.
    #>
    [string] GetName () {
        return $this.Name
    }

    <#
    .SYNOPSIS
        Returns the logging level of the appender.
    #>
    [LogLevel] GetLevel() {
        return $this.level
    }

    <#
    .SYNOPSIS
        Returns the logging pattern of the appender.
    #>
    [string] GetDatePattern() {
        return $this.datePattern
    }

    [void] LogMessage([string]$message) {
        Write-Host "Appender::LogMessage:  $message"
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - Appender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - FileAppender
# -------------------------------------------------------------------------

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
        $timestamp = Get-Date -Format $this.pattern
        $logEntry = "$timestamp - $message"
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:  $logEntry"
        Add-Content -Path $this.logFilePath -Value $logEntry
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - FileAppender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - GoogleChatAppender
# -------------------------------------------------------------------------

[NoRunspaceAffinity()]
class GoogleChatAppender : Appender {

    [string]$webhookUrl

    [int]$maxRetryAttempts = 10

    [int]$retryInterval = 10

    GoogleChatAppender([object]$config) : base($config) {
        $this.webhookUrl = $config.webhookUrl
    }

    [void] WriteLog([string]$message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $message"
        
        $this.isProcessing = $true

        $retryCount = 0
        $success = $false
        $lastError = $null

        try {
            while ($retryCount -lt $this.maxRetryAttempts -and -not $success) {
                try {
                    # Create the Google Chat message payload
                    $chatMessage = @{
                        text = "$logEntry"
                    }

                    # Send to Google Chat webhook
                    $headers = @{
                        "Content-Type" = "application/json"
                    }

                    $body = $chatMessage | ConvertTo-Json -Compress
                    
                    # Add a small random delay to prevent rate limiting
                    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
                    
                    $response = Invoke-RestMethod -Uri $this.webhookUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop
                    
                    # If we get here, the request was successful
                    $success = $true
                    $this.lastSendTime = Get-Date
                    
                    # Log success if we had previous failures
                    if ($retryCount -gt 0) {
                        Write-Verbose "googleChatLogger ($($this.logName)): Successfully sent message after $retryCount retries."
                    }
                } catch {
                    $lastError = $_
                    $retryCount++

                    if ($retryCount -lt $this.maxRetryAttempts) {
                        $waitTime = $this.retryInterval * $retryCount
                        Write-Warning "googleChatLogger ($($this.name)): Failed to send message batch (attempt $retryCount/$($this.maxRetryAttempts)). Retrying in $waitTime seconds. Error: $($_.Exception.Message)"
                        Start-Sleep -Seconds $waitTime
                    } else {
                        Write-Error "googleChatLogger ($($this.name)): Failed to send message batch after $($this.maxRetryAttempts) attempts. Final error: $($_.Exception.Message)"
                        $this.lastSendTime = Get-Date
                    }
                }
            }
        } finally {
            $this.isProcessing = $false
        }
    }

    [void] WriteError([string]$message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - ERROR: $message"
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - GoogleChatAppender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - Logger
# -------------------------------------------------------------------------

[NoRunspaceAffinity()]
class Logger {

    # The list of logging threads that manage the appenders.
    [System.Collections.ArrayList]$loggingThreads = [System.Collections.ArrayList]::new()

    # The log level for the console if it's enabled.
    [LogLevel]$consoleLevel = [LogLevel]::INFO

    [string]$consoleDatePattern = "yyyy-MM-dd HH:mm:ss.fff"

    [bool]$consoleEnabled = $false

    #===========================================================================
    # Object constructor that sets the appenders for the log object, as well as
    # setting the lovel level for the log object.
    #===========================================================================
    Logger ([object]$configFile) {

        $jsonContent = Get-Content -Path $configFile -Raw -Encoding UTF8
        $loggingConfig = $jsonContent | ConvertFrom-Json
        
        if ($loggingConfig.console.enabled) {
            $this.consoleEnabled = $true
            if ($loggingConfig.console.level) { $this.consoleLevel = [LogLevel]$loggingConfig.console.level }
            if ($loggingConfig.console.datePattern) { $this.consoleDatePattern = [string]$loggingConfig.console.datePattern }
        }

        foreach ($appenderConfig in $loggingConfig.appenders) {
            Write-Host "Appender: $($appenderConfig.Name)"

            $className = "$($appenderConfig.type)Appender"
            $appender = New-Object -TypeName $className -ArgumentList $appenderConfig
            $loggingThread = [LoggingThread]::new($appender)
            if ($appenderConfig.batchConfig) {
                $loggingThread.isBatched = $true
                if ($appenderConfig.batchConfig.maxRetryAttempts) { $loggingThread.BatchInterval = $appenderConfig.batchConfig.maxRetryAttempts }
                if ($appenderConfig.batchConfig.batchInterval) { $loggingThread.BatchInterval = $appenderConfig.batchConfig.batchInterval }
                if ($appenderConfig.batchConfig.maxBatchSize) { $loggingThread.MaxBatchSize = $appenderConfig.batchConfig.maxBatchSize }
                if ($appenderConfig.batchConfig.maxMessageLength) { $loggingThread.MaxMessageLength = $appenderConfig.batchConfig.maxMessageLength }
                if ($appenderConfig.batchConfig.retryInterval) { $loggingThread.RetryInterval = $appenderConfig.batchConfig.retryInterval }
            }
            $this.loggingThreads += $loggingThread
        }
    }

    #===========================================================================
    # Method to add an appender instance.
    #===========================================================================
    [void] AddAppender([Appender]$appender) {
        if(!$appender) {
            throw "No appender specified"
        }

        $loggingThread = [LoggingThread]::new($appender)
        $this.loggingThreads += $loggingThread
    }

    #===========================================================================
    #
    #===========================================================================
    [void] Start() {
        foreach ($loggingThread in $this.loggingThreads) {
            $loggingThread.Start()
        }
    }

    #===========================================================================
    #
    #===========================================================================
    [void] LogMessage([LogMessage]$logMessage) {
        if(!$logMessage) {
            throw "No log message specified"
        }

        if ($this.consoleEnabled) {
            if ($logMessage.GetLevel() -le $this.consoleLevel ) {
                Write-Host "$((Get-Date).ToString($this.consoleDatePattern)) :: $($logMessage.GetMessage())"
            }
        }

        foreach ($loggingThread in $this.loggingThreads) {
            $loggingThread.LogMessage($logMessage)
        }
    }

    #===========================================================================
    #
    #===========================================================================
    [void] Stop() {
        foreach ($loggingThread in $this.loggingThreads) {
            $loggingThread.Stop()
        }
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - Logger
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - LoggingThread
# -------------------------------------------------------------------------

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

    [bool]$IsProcessing = $false

    [bool]$IsBatched = $false

    [int]$BatchInterval = 5

    [int]$MaxBatchSize = 50

    [int]$MaxMessageLength = 4000

    [int]$RetryInterval = 10

    [Object]$Job

    [datetime]$LastSendTime

    LoggingThread([Appender]$Appender) {
        if(!$Appender) {
            throw "No appender specified"
        }

        $this.Appender = $Appender

        # Initialize the queues.
        $this.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]::new()

        # The log messages currently pulled off of the log queue will 
        # temporarily be stored in this new concurrent queue.  For non-batched
        # appenders, this queue will then be drained of its messages, and the 
        # messages sent to all appenders.  For a batched appender, the messages 
        # will remain in this queue until the batched message sending parameters
        # are met.
        if ($this.IsBatched) {
            $this.BatchQueue = [System.Collections.Concurrent.ConcurrentQueue[LogMessage]]::new()
        }
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
                    # them in the temporary, batching queue.
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
                            foreach ($batchedLogMessage in $batchedLogMessages) {
                                Add-Content -Path $logFile -Value "Sending message:  $batchedLogMessage"
                                $LoggingThread.Appender.LogMessage($batchedLogMessage)
                            }
                            $batchedLogMessage = ""
                            $lastSendTime = Get-Date
                        }
                    } else {
                        # If the logging thread is not configured to be a 
                        # batching thread, then pull the messages out of the
                        # batch queue, and distribute them to the appenders.
                        Add-Content -Path $logFile -Value "3"
                        foreach ($logMessage in $LoggingThread.BatchQueue) {
                            Add-Content -Path $logFile -Value "4"
                            $Appender.LogMessage($logMessage)
                        }
                    }
                } catch {
                    $errorMessage = "ERROR | Log processing error: $($_.Exception.Message)"
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

# -------------------------------------------------------------------------
# End: Class Definition - LoggingThread
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - LogMessage
# -------------------------------------------------------------------------

[NoRunspaceAffinity()]
class LogMessage {
    [string]$message

    [LogLevel]$level

    LogMessage([string]$message, [LogLevel]$level) {
        $this.message = $message
        $this.level = $level
    }

    [string] GetMessage() {
        return $this.message
    }

    [LogLevel] GetLevel() {
        return $this.level
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - LogMessage
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Enum Definition - LogLevel
# -------------------------------------------------------------------------
# The enumeration representing the various logging levels available for use.
enum LogLevel {
    FATAL
    ERROR
    WARN
    CRITICAL
    VITAL
    INFO
    DEBUG
    TRACE
}

# -------------------------------------------------------------------------
# End: Enum Definition - LogLevel
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Enum Definition - Status
# -------------------------------------------------------------------------
# The enumeration representing the status values that a particular task can be 
# in.
enum Status {
    NotStarted
    Started
    InProgress
    Completed
    Failed
}

# -------------------------------------------------------------------------
# End: Enum Definition - Status
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Enum Definition - TaskType
# -------------------------------------------------------------------------
# The enumeration representing the type of task being tracked by the logging
# framework.
enum TaskType {
    Addition
    Analysis
    Authentication
    Cleanup
    Collection
    Configuration
    Connection
    Creation
    Deployment
    Execution
    Generation
    Input
    Migration
    Monitoring
    Processing
    Retrieval
    Setup
    SiteMigration
    SiteUpgrade
    Staging
    Testing
    Upgrade
    Validation
    Remediation
    VMManagement
    Wait
}

# -------------------------------------------------------------------------
# End: Enum Definition - TaskType
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Public Function - Import-Config
# -------------------------------------------------------------------------
function Import-Config {
    param (
        [Parameter(Mandatory=$true)][ValidateScript({ Test-Path $_ })][String]$ConfigFile = "../config/logging.json"
    )

    #------------------------------------------
    # Loading and validating JSON configuration
    #------------------------------------------
    try {
        $global:configJsonPath = Join-Path $scriptPath $ConfigFile
        $global:configJsonContent = Get-Content $configJsonPath -ErrorAction Stop

        # Convert JSON content into an object; any conversion error will be caught.
        $global:envConfig = $configJsonContent | ConvertFrom-Json -ErrorAction Stop

        # Validate that the JSON object is not null or empty.
        if (-not $envConfig) {
            $logMessage = "ERROR | The JSON configuration is empty or invalid."
            Write-Error $logMessage
            $globalLogger.Enqueue($logMessage)
            throw
        }
    }
    catch {
        $logMessage = "ERROR | Failed to load or parse JSON configuration file: $($_.Exception.Message)"
        Write-Error $logMessage
        $globalLogger.Enqueue($logMessage)
        throw
    }
}

# -------------------------------------------------------------------------
# End: Public Function - Import-Config
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Public Function - New-Appender
# -------------------------------------------------------------------------

function New-Appender() {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][Object]$Config
    )

    return New-Object -TypeName "$($Config.type)Appender" -ArgumentList $Config
}

# -------------------------------------------------------------------------
# End: Public Function - New-Appender
# -------------------------------------------------------------------------
Export-ModuleMember -Function Import-Config, New-Appender
