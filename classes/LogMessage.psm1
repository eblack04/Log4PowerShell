using module "../enums/LogLevel.psm1"

[NoRunspaceAffinity()]
class LogMessage {
    [string]$message

    [LogLevel]$level

    LogMessage([string]$message, [LogLevel]$level) {
        $this.message = $message
        $this.level = $level
    }

    [string] GetMessage() {
        return $this.message
    }

    [LogLevel] GetLevel() {
        return $this.level
    }
}