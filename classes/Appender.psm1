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

    Appender([object]$config) {
        if($config) {
            if($config.name) { $this.name = $config.name} else { throw "No name specified in the configuration"}
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

    [void] LogMessage([string]$message) {
        Write-Host "Appender::LogMessage:  $message"
    }
}