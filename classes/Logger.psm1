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