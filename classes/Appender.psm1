using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

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