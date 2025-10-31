using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class HashLogMessage : LogMessage {

    [PSCustomObject]$MessagePartMap

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