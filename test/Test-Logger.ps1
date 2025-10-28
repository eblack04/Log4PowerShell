using module "../modules/VMware.Logging.psm1"

$ConfigFile = "./config/logging.json"
$logger = [Logger]::new($ConfigFile)
$logger.Start()
$global:Logger = $logger

$logMessage = [LogMessage]::new("1:  hello world!", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)
$logMessage = [LogMessage]::new("2:  hello world!", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)

#$global:Logger.Stop() 