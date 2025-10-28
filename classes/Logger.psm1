using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module ".\LoggingThread.psm1"
using module "..\enums\LogLevel.psm1"

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