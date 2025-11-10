# ====================================================================================
# Module: Log4PowerShell
# Version: 1.0
# Generated: 11-10-2025 15:19:20
# Description: Module for managing vSphere Lifecycle
# ====================================================================================
# -------------------------------------------------------------------------
# Start: Class Definition - LogMessage
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    The object representing a single log message.
.DESCRIPTION
    This class encapsulates all information that comprises a single logging
    message handled by this framework.
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
        A constructor that sets a single message string as the contents of the 
        log message.
    .DESCRIPTION
        The string message passed into this constructor is added to the internal
        hash object with the key "Message", and used to establish the length of
        the message.
    #>
    LogMessage([object]$Message, [LogLevel]$LogLevel) {
        if(!$Message) {
            throw "no message specified"
        }

        if(!$LogLevel) {
            throw "no log level specified"
        }

        if($Message -is [string]) {
            $this.MessageHash = @{}
            $this.MessageHash.Message = $Message
            $this.MessageLength = $Message.Length
        } else {
            $this.MessageHash = $Message
            
            foreach ($property in $this.MessageHash.GetEnumerator()) {
                $this.MessageLength += $property.Name.Length + $property.Value.Length
            }
        }

        $this.Timestamp = Get-Date
        $this.LogLevel = $LogLevel
    }

    <#
    .SYNOPSIS
        Returns the log message contained within an instance of this class.
    .DESCRIPTION
        If this class contains only a message string for the log message, then 
        that message is returned; otherwise, all entries in the message hash
        are iterated over, formatted into "name = value" strings, concatenated
        together, and returned as a single string.
    #>
    [string] GetMessage() { 
        Write-Host "this.MessageHash.Keys.Count:  $($this.MessageHash.Keys.Count)"
        Write-Host "this.MessageHash.ContainsKey(`"Message`"):  $($this.MessageHash.Contains("Message"))"

        if ($this.MessageHash.Keys.Count -eq 1 -and $this.MessageHash.Contains("Message")) {
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
        Getter method that returns the message hash object.
    .DESCRIPTION
        Getter method that returns the message hash object.
    #>
    [PSCustomObject] GetMessageHash() {
        return $this.MessageHash
    }

    <#
    .SYNOPSIS
        Getter method that returns the message log level.
    .DESCRIPTION
        Getter method that returns the message log level.
    #>
    [LogLevel] GetLogLevel() {
        return $this.LogLevel
    }

    <#
    .SYNOPSIS
        Getter method that returns the message length.
    .DESCRIPTION
        Getter method that returns the message length.
    #>
    [int] GetMessageLength() {
        return $this.MessageLength
    }

    <#
    .SYNOPSIS
        Getter method that returns the message timestamp.
    .DESCRIPTION
        Getter method that returns the message timestamp.
    #>
    [datetime] GetTimestamp() {
        return $this.Timestamp
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - LogMessage
# -------------------------------------------------------------------------
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

    [object]$Config

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
            $this.Config = $Config
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
        Returns the date pattern of the appender.
    #>
    [string] GetDatePattern () {
        return $this.DatePattern
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
# Start: Class Definition - FileAppender
# -------------------------------------------------------------------------

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
                $this.addFileHeader()
            }

            Add-Content -Path $this.logFile -Value "Set LogFilePath to:  $($this.LogFilePath)"
        } else {
            if ($Config.rolloverFileSize) { $this.RolloverFileSize = $Config.rolloverFileSize -as [double]}
            if ($Config.rolloverFileNumber) { $this.RolloverFileNumber = $Config.rolloverFileNumber}

            $this.RolloverPolicy = [RolloverPolicy]$Config.rolloverPolicy
            Add-Content -Path $this.logFile -Value "Rollover policy:  $($this.RolloverPolicy)" # Remove
            $this.LogFilePath = Add-FileNameCounter -FileName $this.LogFilePath -Counter $this.RolloverFileCounter
            $this.addFileHeader()
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
        $formattedMessage = $this.formatMessage($LogMessage)
        
        Add-Content -Path $this.logFile -Value "FileAppender::WriteLog: $($this.LogFilePath):$formattedMessage" # Remove

        if ($this.RolloverPolicy -and $this.RolloverPolicy -ne [RolloverPolicy]::NONE) {

            $triggerRollover = $false

            #Add-Content -Path $this.logFile -Value "Rollover policy:  $($this.RolloverPolicy)" # Remove
            switch ($this.RolloverPolicy) {
                ([RolloverPolicy]::SIZE) {
                    #Add-Content -Path $this.logFile -Value "Rollover policy is SIZE" # Remove
                    
                    # If the size of the current log file is greater than the 
                    # configured limit, then roll the log file to the next one.
                    #Add-Content -Path $this.logFile -Value "File size: $((Get-ChildItem -Path $this.LogFilePath).Length)" # Remove
                    #Add-Content -Path $this.logFile -Value "Rollover file size: $($this.RolloverFileSize)" # Remove
                    if(((Get-ChildItem -Path $this.LogFilePath).Length + $formattedMessage.Length) -gt $this.RolloverFileSize) {
                        $triggerRollover = $true
                    } 
                }
                ($_ -in @([RolloverPolicy]::MINUTE, [RolloverPolicy]::HOURLY, [RolloverPolicy]::DAILY,[RolloverPolicy]::WEEKLY)) {
                    $timeDifference = (Get-Date) - $this.LastRolloverTime

                    # Use the value assigned to the rollover policy enumeration,
                    # which is the value of the policy in minutes if the 
                    # enumeration represents a time value.
                    if ($timeDifference.Minutes -gt $_.Value__) {
                        $triggerRollover = $true
                    }
                }
            }

            if ($triggerRollover) {
                # This 'if' statement determines the index of the next file in the rollover list.
                #Add-Content -Path $this.logFile -Value "Log file $($this.LogFilePath) is greater than size $($this.RolloverFileSize)" # Remove
                if($this.RolloverFileCounter + 1 -gt $this.RolloverFileNumber) {
                    #Add-Content -Path $this.logFile -Value "Setting the RolloverFileCounter to 1" # Remove
                    $this.RolloverFileCounter = 1
                } else {
                    #Add-Content -Path $this.logFile -Value "Setting the RolloverFileCounter to $($this.RolloverFileCounter + 1)" # Remove
                    $this.RolloverFileCounter++
                }
                #Add-Content -Path $this.logFile -Value "Rollover file counter: $($this.RolloverFileCounter)" # Remove
                #Add-Content -Path $this.logFile -Value "Log file path: $($this.LogFilePath)" # Remove

                # This regular expression and 'if' statement removes the
                # current rollover index from the name, and inserts the
                # next one.
                $matchResults = [regex]::Match($this.LogFilePath, "(.*)(\d+)([.].*)")
                if ($matchResults.Success) {
                    $this.LogFilePath = $matchResults.Groups[1].Value + $this.RolloverFileCounter + $matchResults.Groups[3].Value
                }

                #Add-Content -Path $this.logFile -Value "Changed log file name to $($this.LogFilePath)" # Remove

                # After setting the log file name to the next name in 
                # rollover list, delete the file if it currently 
                # exists to rollover on top of it.
                if (Test-Path -Path $this.LogFilePath -PathType Leaf) {
                    Remove-Item -Path $this.LogFilePath
                }

                # Add the header, if one needs to be added, to the new file.
                $this.addFileHeader()
            }
        }

        if($formattedMessage) { Add-Content -Path $this.LogFilePath -Value $formattedMessage }
        #Add-Content -Path $this.logFile -Value "FileAppender::WriteLog:after writing:  $formattedMessage" # Remove
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

    hidden [void] addFileHeader() {
    }

    hidden [string] formatMessage([LogMessage]$LogMessage) {
        return "$($LogMessage.GetTimestamp().ToString($this.DatePattern)): $($LogMessage.GetMessage())"
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - FileAppender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - CSVAppender
# -------------------------------------------------------------------------

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
        # 2.  There is at lest one column with a value, and the ValuesMandatory
        #     flag is 'false'.
        #=======================================================================
        $containsAllAndValuesMandatory = ($containsAllKeys -and $this.ValuesMandatory)
        Add-Content -Path $this.logFile -Value "containsAllAndValuesMandatory:  $containsAllAndValuesMandatory"
        $notValuesMandatory = -not $this.ValuesMandatory
        Add-Content -Path $this.logFile -Value "notValuesMandatory:  $notValuesMandatory"
        $noValues = (($messageValues -join "").length -gt 0) -and $containsNonTimestampValue
        Add-Content -Path $this.logFile -Value "noValues:  $noValues"

        if ( ($containsAllKeys -and $this.ValuesMandatory) -or ((-not $this.ValuesMandatory) -and (($messageValues -join "").length -gt 0) -and $containsNonTimestampValue)) {
            Add-Content -Path $this.logFile -Value "Joining the fields"
            $csvMessage = $messageValues -Join ","
        }

        Add-Content -Path $this.logFile -Value "csvMessage:  $csvMessage"

        return $csvMessage
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - CSVAppender
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - GoogleChatAppender
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    An appender implementation that writes log messages to a Google chat space.
.DESCRIPTION
    This class writes log messages to a defined Google chat channel via a 
    specified web hook URL using a REST call.  If there are any issues when 
    sending the log messages, the attempt to write the log message to the 
    specified Google chat channel is resent a specified number of times until
    either the message is successfully sent, or the number of retries has be 
    depleted.
#>
[NoRunspaceAffinity()]
class GoogleChatAppender : Appender {

    #
    [string]$WebhookUrl

    #
    [int]$MaxRetryAttempts = 10

    #
    [int]$RetryInterval = 10

    ######### Temp ########
    [string]$LogFile = "C:\Users\EdwardBlackwell\Documents\logs\google-chat.jog"
    ######### Temp ########

    <#
    .SYNOPSIS
        The default constructor that initializes the appender.
    .DESCRIPTION
        The configuration passed into the class sets the Google Chat attributes
        for the class.  These include the webhook URL, the message-sending time
        interval, and the number of retries to perform if there is an issue 
        when sending a message.
    #>
    GoogleChatAppender([object]$Config) : base($Config) {
        Add-Content -Path $this.logFile -Value "Web Hook URL:  $($config.webhookUrl)"

        if ($Config.webhookUrl) { $this.WebhookUrl = $Config.webhookUrl } else { throw "No webhook URL specified within the appender configuration"}
        if ($Config.maxRetryAttempts) { $this.MaxRetryAttempts = $Config.maxRetryAttempts }
        if ($Config.retryInterval) { $this.RetryInterval = $Config.retryInterval }
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    [void] LogMessage([LogMessage]$LogMessage) {
        Add-Content -Path $this.logFile -Value "LogMessage:  $($LogMessage.GetMessage())"

        # Create the Google Chat message payload
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())"
        $this.SendMessage($formattedMessage)
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
    [void] LogMessages([LogMessage[]]$LogMessages) {
        $batchFormattedMessage = ""

        foreach($LogMessage in $LogMessages) {
            $batchFormattedMessage += "$($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())`n"
        }

        $this.SendMessage($batchFormattedMessage)
    }

    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    #>
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
# Start: Class Definition - LoggingThread
# -------------------------------------------------------------------------

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
        Starts the inner ThreadJob object to listen for incoming log messages.
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
# Start: Class Definition - Logger
# -------------------------------------------------------------------------

[NoRunspaceAffinity()]
class Logger {

    # The list of logging threads that manage the appenders.
    [System.Collections.ArrayList]$LoggingThreads = [System.Collections.ArrayList]::new()

    # The log level for the console if it's enabled.
    [LogLevel]$ConsoleLevel = [LogLevel]::INFO

    # The timestamp date pattern to use if logging is echoed to the console.
    [string]$ConsoleDatePattern = "yyyy-MM-dd HH:mm:ss.fff"

    # A boolean flag indicating whether or not logging is echoed to the console.
    [bool]$ConsoleEnabled = $false

    <#
    .SYNOPSIS
        The object constructor that configures the logging framework.
    .DESCRIPTION
        Object constructor that sets the appenders for the log object, as well 
        as setting the lovel level for the log object.
    #>
    Logger ([object]$ConfigFile) {

        $jsonContent = Get-Content -Path $ConfigFile -Raw -Encoding UTF8
        $loggingConfig = $jsonContent | ConvertFrom-Json
        
        if ($loggingConfig.console.enabled) {
            $this.ConsoleEnabled = $true
            if ($loggingConfig.console.logLevel) { $this.ConsoleLevel = [LogLevel]$loggingConfig.console.logLevel }
            if ($loggingConfig.console.datePattern) { $this.ConsoleDatePattern = [string]$loggingConfig.console.datePattern }
        }

        foreach ($appenderConfig in $loggingConfig.appenders) {
            $loggingThread = [LoggingThread]::new($appenderConfig)
            $this.LoggingThreads += $loggingThread
        }
    }

    #===========================================================================
    # Method to add an appender instance.
    #===========================================================================
    <#
    .SYNOPSIS
        A method to add an appender instance.
    .DESCRIPTION
        Adds an appender instance to the list of appenders controlled by this
        object.
    #>
    [void] AddAppender([Appender]$Appender) {
        if(!$Appender) {
            throw "No appender specified"
        }

        $loggingThread = [LoggingThread]::new($Appender)
        $this.LoggingThreads += $loggingThread
    }

    <#
    #>
    [void] Start() {
        foreach ($loggingThread in $this.LoggingThreads) {
            $loggingThread.Start()
        }
    }

    <#
    #>
    [void] LogMessage([LogMessage]$LogMessage) {
        if(!$LogMessage) {
            throw "No log message specified"
        }

        if ($this.ConsoleEnabled) {
            if ($LogMessage.GetLogLevel() -le $this.ConsoleLevel ) {
                Write-Host "$((Get-Date).ToString($this.ConsoleDatePattern)) :: $($LogMessage.GetMessage())"
            }
        }

        foreach ($loggingThread in $this.LoggingThreads) {
            $loggingThread.LogMessage($LogMessage)
        }
    }

    <#
    #>
    [void] Stop() {
        foreach ($loggingThread in $this.LoggingThreads) {
            $loggingThread.Stop()
        }
    }
}

# -------------------------------------------------------------------------
# End: Class Definition - Logger
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Class Definition - README
# -------------------------------------------------------------------------
# Description

# -------------------------------------------------------------------------
# End: Class Definition - README
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
# Start: Enum Definition - RolloverPolicy
# -------------------------------------------------------------------------
enum RolloverPolicy {
    NONE = 0
    MINUTE = 1
    HOURLY = 60
    DAILY = 1440
    WEEKLY = 10080
    SIZE
}

# -------------------------------------------------------------------------
# End: Enum Definition - RolloverPolicy
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
# Start: Public Function - Add-FileNameCounter
# -------------------------------------------------------------------------
function Add-FileNameCounter {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$FileName,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][int]$Counter
    )

    $matchResults = [regex]::Match($FileName, "(.*)(\..*)")

    if ($matchResults.Success) {
        return $matchResults.Groups[1].Value + "-" + $Counter + $matchResults.Groups[2].Value
    } else {
        return $FileName
    }
}

# -------------------------------------------------------------------------
# End: Public Function - Add-FileNameCounter
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Public Function - Convert-ToTimestampFileName
# -------------------------------------------------------------------------
<#
.SYNOPSIS
    This is a utility function that inserts a timestamp into a given string.
.DESCRIPTION
    This function takes a file name string as input, looks for a date format 
    string within the file name where the date format is bounded by the 
    characters "%d{<date format>}", and then uses that date format to create a
    timestamp string.  the timestamp is then inserted into the file name where
    the markup text resided.

    For example, given that this function is called like the following:

    Convert-ToTimestampFileName -FileName "csv-main-%d{MM-dd-yyyy}.log"

    And that the current date is November 4, 2025, then the returned string 
    will be:

    "csv-main-11-04-2025.log"

    If no date format string is present within the supplied string, then the
    string is simply echoed back.  Also, the date format string within the file
    name is checked to make sure there are no invalid file name characters 
    present.  If any are found, and exception is thrown.
#>
function Convert-ToTimestampFileName {
    param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$FileName
    )

    $datePattern = [regex]::Match($FileName, ".*%d{(.*)}.*")

    if ($datePattern.Success) {
        $pattern = $datePattern.Groups[1].Value
        $timestamp = Get-Date -Format $pattern
        $FileName = $FileName -replace "%d{.*}", $timestamp
    }

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()

    foreach ($char in $invalidChars) {
        if ($FileName.Contains($char)) {
            throw "Invalid file name: $FileName"
        }
    }

    return $FileName
}

# -------------------------------------------------------------------------
# End: Public Function - Convert-ToTimestampFileName
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

<#
.SYNOPSIS
    A factory function that creates an appender from an appender configuration.
.DESCRIPTION
    When an appender configuration is retrieved from the logging system JSON
    file, the configuration can be passed into this function, and an appropriate
    appender implementation created from the configuration.  the appender object
    is them returned.
#>
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
        Creates a new LogMessage object.
    .DESCRIPTION
        This function instantiates a new LogMessage object by invoking its constructor 
        with the specified message and logging level.
    .PARAMETER Message
        The log message to encapsulate inside the LogMessage object.
    .PARAMETER LogLevel
        The level of the log message
    .EXAMPLE
        $logger = New-LogMessage -Message "a log message" -LogLevel [LogLevel]::DEBUG
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][object]$Message,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][LogLevel]$LogLevel
    )

    return [LogMessage]::new($Message, $LogLevel)
}

# -------------------------------------------------------------------------
# End: Public Function - New-LogMessage
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Public Function - Write-Debug
# -------------------------------------------------------------------------
function Write-Debug {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][object]$Message
    )

    $logMessage = [LogMessage]::new($Message, [LogLevel]::DEBUG)
    $global:Logger.LogMessage($logMessage)
}

# -------------------------------------------------------------------------
# End: Public Function - Write-Debug
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Start: Public Function - Write-Info
# -------------------------------------------------------------------------
function Write-Info {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][object]$Message
    )

    $logMessage = [LogMessage]::new($Message, [LogLevel]::INFO)
    $global:Logger.LogMessage($logMessage)
}

# -------------------------------------------------------------------------
# End: Public Function - Write-Info
# -------------------------------------------------------------------------
Export-ModuleMember -Function Add-FileNameCounter, Convert-ToTimestampFileName, Import-Config, New-Appender, New-LogMessage, Write-Debug, Write-Info
