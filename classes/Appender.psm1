using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

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