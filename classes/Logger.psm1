using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module ".\LoggingThread.psm1"
using module "..\enums\LogLevel.psm1"

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