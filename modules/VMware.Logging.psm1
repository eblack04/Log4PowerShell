# ====================================================================================
# Module: VMware.Logging
# Version: 1.0
# Generated: 11-03-2025 11:54:33
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
    specific technique for storing or sending a logging message, such as to a
    file, to a database, or to a web service.
.NOTES
    Author: Todd Blackwell
#>
[NoRunspaceAffinity()]
class Appender {

    # The name of the appender.
    [string]$Name

    [string]$DatePattern

    <#
    .SYNOPSIS
        The default constructor for the appender.
    .DESCRIPTION
        Creates an appender instance with the specified name in the provided
        configuration object.
    .EXAMPLE
        $config = @{
            "name" = "appender1"
        }
        $appender = [Appender]::New($config)
    #>
    Appender([object]$Config) {
        if($Config) {
            if($Config.name) { $this.Name = $Config.name} else { throw "No name specified in the configuration"}
            if($Config.datePattern) { $this.DatePattern = $Config.datePattern} else { throw "No date pattern specified in the configuration"}
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
        The base version of the method that will log a given message.
    .DESCRIPTION
        This method is not intended for use.  Derived Appender classes need to
        override this method to provide a specific implementation. 
    #>
    [void] LogMessage([LogMessage]$LogMessage) {
        Write-Host "Appender::LogMessage:  $($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())"
    }

    [void] LogMessages([LogMessage[]]$LogMessages) {
        $batchMessage = ""

        foreach($logMessage in $LogMessages) {
            $batchMessage += $($logMessage.GetTimestamp().ToString($this.DatePattern)) - $($logMessage.GetMessage()) + "`n"
        }
        Write-Host "$batchMessage"
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - Appender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - CSVAppender
# -------------------------------------------------------------------------

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

# -------------------------------------------------------------------------
# End: Class Definition - CSVAppender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - FileAppender
# -------------------------------------------------------------------------

[NoRunspaceAffinity()]
class FileAppender : Appender {
    
    [string]$LogFilePath

    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\file-appender.log"

    FileAppender([object]$config) : base($config) {
        $this.LogFilePath = $config.path + "/" + $config.fileName

        # Delete the log file if the logger is not appending to an existing log
        # file.
        if (!$config.append -and (Test-Path -Path $this.LogFilePath -PathType Leaf)) {
            Remove-Item -Path $this.LogFilePath
        }

        Add-Content -Path $this.logFile -Value "Set LogFilePath to:  $($this.LogFilePath)"
    }

    [void] LogMessage([LogMessage]$LogMessage) {
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)): $($LogMessage.GetMessage())"
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:  $formattedMessage"
        Add-Content -Path $this.LogFilePath -Value $formattedMessage
    }

    [void] LogMessages([LogMessage[]]$LogMessages) {
        foreach ($LogMessage in $LogMessages) {
            $this.LogMessage($LogMessage)
        }
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

    [string]$WebhookUrl

    [int]$MaxRetryAttempts = 10

    [int]$RetryInterval = 10

    [string]$LogFile = "C:\Users\EdwardBlackwell\Documents\logs\google-chat.jog"

    GoogleChatAppender([object]$Config) : base($Config) {
        Add-Content -Path $this.logFile -Value "Web Hook URL:  $($config.webhookUrl)"

        if ($Config.webhookUrl) { $this.WebhookUrl = $Config.webhookUrl } else { throw "No webhook URL specified within the appender configuration"}
        if ($Config.maxRetryAttempts) { $this.MaxRetryAttempts = $Config.maxRetryAttempts }
        if ($Config.retryInterval) { $this.RetryInterval = $Config.retryInterval }
    }

    [void] LogMessage([LogMessage]$LogMessage) {
        Add-Content -Path $this.logFile -Value "LogMessage:  $($LogMessage.GetMessage())"

        # Create the Google Chat message payload
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())"
        $this.SendMessage($formattedMessage)
    }

    [void] LogMessages([LogMessage[]]$LogMessages) {
        $batchFormattedMessage = ""

        foreach($LogMessage in $LogMessages) {
            $batchFormattedMessage += "$($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())`n"
        }

        $this.SendMessage($batchFormattedMessage)
    }

    hidden [void] SendMessage([string]$Message) {
        $retryCount = 0
        $success = $false
        $lastError = $null

        while ($retryCount -lt $this.MaxRetryAttempts -and -not $success) {
            try {
                # Create the Google Chat message payload
                $chatMessage = @{
                    text = $Message
                }
                Add-Content -Path $this.logFile -Value "Message: $Message"
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
                    
                # Log success if we had previous failures
                if ($retryCount -gt 0) {
                    Write-Verbose "googleChatLogger ($($this.logName)): Successfully sent message after $retryCount retries."
                }
            } catch {
                Add-Content -Path $this.logFile -Value "Error: $($_.Exception.Message)"
                $lastError = $_
                $retryCount++

                if ($retryCount -lt $this.MaxRetryAttempts) {
                    $waitTime = $this.RetryInterval * $retryCount
                    Write-Warning "googleChatLogger ($($this.name)): Failed to send message batch (attempt $retryCount/$($this.MaxRetryAttempts)). Retrying in $waitTime seconds. Error: $($_.Exception.Message)"
                    Start-Sleep -Seconds $waitTime
                } else {
                    Write-Error "googleChatLogger ($($this.name)): Failed to send message batch after $($this.MaxRetryAttempts) attempts. Final error: $($_.Exception.Message)"
                }
            }
        }
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
            if ($loggingConfig.console.logLevel) { $this.consoleLevel = [LogLevel]$loggingConfig.console.logLevel }
            if ($loggingConfig.console.datePattern) { $this.consoleDatePattern = [string]$loggingConfig.console.datePattern }
        }

        foreach ($appenderConfig in $loggingConfig.appenders) {
            $loggingThread = [LoggingThread]::new($appenderConfig)
            $this.loggingThreads += $loggingThread
        }
    }

    #===========================================================================
    # Method to add an appender instance.
    #===========================================================================
    [void] AddAppender([Appender]$Appender) {
        if(!$Appender) {
            throw "No appender specified"
        }

        $loggingThread = [LoggingThread]::new($Appender)
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
    [void] LogMessage([LogMessage]$LogMessage) {
        if(!$LogMessage) {
            throw "No log message specified"
        }

        if ($this.consoleEnabled) {
            if ($LogMessage.GetLogLevel() -le $this.consoleLevel ) {
                Write-Host "$((Get-Date).ToString($this.consoleDatePattern)) :: $($LogMessage.GetMessage())"
            }
        }

        foreach ($loggingThread in $this.loggingThreads) {
            $loggingThread.LogMessage($LogMessage)
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

# -------------------------------------------------------------------------
# End: Class Definition - LoggingThread
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - LogMessage
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    Brief description.
.DESCRIPTION
    Detailed description.
#>
[NoRunspaceAffinity()]
class LogMessage {
    # The time the message was generated.
    [datetime]$Timestamp

    # The object used as the body for the message.
    [object]$MessageHash

    # The logging level for the message.
    [LogLevel]$LogLevel

    # The number of characters in the message.
    [int]$MessageLength

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    LogMessage([string]$Message, [LogLevel]$LogLevel) {
        if(!$Message) {
            throw "no message specified"
        }

        if(!$LogLevel) {
            throw "no log level specified"
        }

        $this.Timestamp = Get-Date
        $this.MessageHash = @{}
        $this.MessageHash.Message = $Message
        $this.LogLevel = $LogLevel
        $this.MessageLength = $Message.Length
    }

    <#
    .SYNOPSIS
        A LogMessage constructor that accepts a hash message directly.
    .DESCRIPTION
        This constructor accepts a message hash object and the logging level for
        the message.  The hash object becomes the body of the message, and it is
        up to the appenders to utilize the hash for logging purposes.
    #>
    LogMessage([object]$MessageHash, [LogLevel]$LogLevel) {
        if(!$MessageHash) {
            throw "no message hash specified"
        }

        if(!$LogLevel) {
            throw "no log level specified"
        }

        $this.MessageHash = $MessageHash
        $this.LogLevel = $LogLevel
        
        foreach ($property in $this.MessageHash.GetEnumerator()) {
            $this.MessageLength += $property.Name.Length + $property.Value.Length
        }
    }

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [string] GetMessage() { 
        Write-Host "this.MessageHash.Keys.Count:  $($this.MessageHash.Keys.Count)"
        Write-Host "this.MessageHash.ContainsKey(`"Message`"):  $($this.MessageHash.ContainsKey("Message"))"

        if ($this.MessageHash.Keys.Count -eq 1 -and $this.MessageHash.ContainsKey("Message")) {
            return $this.MessageHash.Message
        } else {
            $messageText = ""

            foreach ($property in $this.MessageHash.GetEnumerator()) {
                if($messageText.Length -ne 0) {
                    $messageText += ", "
                }

                $messageText += $property.Name + " = " + $property.Value
            }

            return $messageText
        }
    }

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [PSCustomObject] GetMessageHash() {
        return $this.MessageHash
    }

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [LogLevel] GetLogLevel() {
        return $this.LogLevel
    }

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [int] GetMessageLength() {
        return $this.MessageLength
    }

    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    #>
    [datetime] GetTimestamp() {
        return $this.Timestamp
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
# -------------------------------------------------------------------------
# Start: Public Function - New-LogMessage
# -------------------------------------------------------------------------
function New-LogMessage() {
    <#
    .SYNOPSIS
        Creates a new FileLogger object.
    
    .DESCRIPTION
        This function instantiates a new FileLogger object by invoking its constructor 
        with the specified file path and logger name. The FileLogger is used for logging 
        messages to a file located at the provided path.
    
    .PARAMETER Path
        The file system path where the log file will be created and maintained.
    
    .PARAMETER Name
        The name of the logger instance. This name is typically used to identify the log file.
    
    .EXAMPLE
        $logger = New-FileLogger -Path "./Logs" -Name "ApplicationLog"
    
        This example creates a new FileLogger object that writes logs to the "./Logs" directory 
        with the name "ApplicationLog".
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Message,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][LogLevel]$LogLevel
    )

    return [LogMessage]::new($Message, $LogLevel)
}

# -------------------------------------------------------------------------
# End: Public Function - New-LogMessage
# -------------------------------------------------------------------------
Export-ModuleMember -Function Import-Config, New-Appender, New-LogMessage
