# ====================================================================================
# Module: VMware.Logging
# Version: 1.0
# Generated: 10-28-2025 10:27:01
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

    [string]$pattern

    Appender([object]$config) {
        if($config) {
            if($config.name) { $this.name = $config.name} else { throw "No name specified in the configuration"}
            if($config.level) { $this.level = [LogLevel]$config.level} else { throw "No log level specified in the configuration"}
            if($config.pattern) { $this.pattern = $config.pattern} else { throw "No pattern specified in the configuration"}
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
    [string] GetPattern() {
        return $this.pattern
    }

    [void] LogMessage([string]$message) {
        if ($message.level -ge $this.level) {
            Write-Host "Appender::LogMessage:  $message"
        }
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - Appender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - ConsoleAppender
# -------------------------------------------------------------------------

[NoRunspaceAffinity()]
class ConsoleAppender : Appender {

    ConsoleAppender([object]$config) : base($config) { }

    [void] LogMessage([string]$message) {
        Write-Host "ConsoleAppender::LogMessage:  $message"
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - ConsoleAppender
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

    [string]$spaceId

    [string]$key

    [int]$maxRetryAttempts = 10

    [int]$retryInterval = 10

    GoogleChatAppender([object]$config) : base($config) {
        $this.spaceId = $config.spaceId
        $this.key = $config.key
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

    [string]$consolePattern = "yyyy-MM-dd HH:mm:ss.fff"

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
            if ($loggingConfig.console.pattern) { $this.consolePattern = [string]$loggingConfig.console.pattern }
        }

        foreach ($appenderConfig in $loggingConfig.appenders) {
            Write-Host "Appender: $($appenderConfig.Name)"

            $className = "$($appenderConfig.type)Appender"
            $appender = New-Object -TypeName $className -ArgumentList $appenderConfig
            $loggingThread = [LoggingThread]::new($appender)
            if ($loggingConfig.batchConfig) {
                $loggingThread.isBatched = $true
                if ($loggingConfig.batchInterval) { $loggingThread.batchInterval = $loggingConfig.batchConfig.batchInterval }
                if ($loggingConfig.maxBatchSize) { $loggingThread.maxBatchSize = $loggingConfig.batchConfig.maxBatchSize }
                if ($loggingConfig.maxMessageLength) { $loggingThread.maxMessageLength = $loggingConfig.batchConfig.maxMessageLength }
                if ($loggingConfig.retryInterval) { $loggingThread.retryInterval = $loggingConfig.batchConfig.retryInterval }
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
                Write-Host "$((Get-Date).ToString($this.consolePattern)) :: $($logMessage.GetMessage())"
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
