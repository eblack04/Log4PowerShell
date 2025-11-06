using module "../enums/LogLevel.psm1"

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

        $this.Timestamp = Get-Date
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