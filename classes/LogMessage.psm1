using module "../enums/LogLevel.psm1"

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
        Returns the log message contained within an instance of this class.
    .DESCRIPTION
        If this class contains only a message string for the log message, then 
        that message is returned; otherwise, all entries in the message hash
        are iterated over, formatted into "name = value" strings, concatenated
        together, and returned as a single string.
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