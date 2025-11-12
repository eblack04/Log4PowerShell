using module "..\modules\VMware.Logging.psm1"

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