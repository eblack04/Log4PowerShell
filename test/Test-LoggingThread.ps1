using module "..\modules\VMware.Logging.psm1"

$appenderConfig = @{
    name = "console1"
    type = "Console"
    level = "DEBUG"
    pattern = "%d [%t] %p %c - %m%n"
}

Write-Host "Creating ConsoleAppender..."
$appender = [ConsoleAppender]::new($appenderConfig)
If($appender) {
    Write-Host "ConsoleAppender created"
}
Write-Host "done."

Write-Host "Creating LoggingThread..."
$loggingThread = [LoggingThread]::new($appender)
Write-Host "done."

Write-Host "Starting the thread..."
$loggingThread.Start($Host)
Write-Host "started."

$logMessage1 = [LogMessage]::new("test message 1")
$loggingThread.LogMessage($logMessage1)
$logMessage2 = [LogMessage]::new("test message 2")
$loggingThread.LogMessage($logMessage2)

Start-Sleep -Seconds 2

Write-host "Stopping the thread..."
$loggingThread.Stop()
Write-Host "stopped."