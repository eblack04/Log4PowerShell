using module "..\modules\VMware.Logging.psm1"

$appenderConfig = @{
    name = "console1"
    type = "Console"
    level = "DEBUG"
    pattern = "%d [%t] %p %c - %m%n"
}

$appender = New-Appender -Config $appenderConfig

Write-Host "Appender: $($appender.name), type = $($appender.GetType())"