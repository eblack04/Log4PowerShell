using module "../modules/VMware.Logging.psm1"

$ConfigFile = "./config/logging.json"
$logger = [Logger]::new($ConfigFile)
$logger.Start()
$global:Logger = $logger

$logMessage = [LogMessage]::new("1:  hello world!", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)
$logMessage = [LogMessage]::new("2:  hello world!", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)

$logMessage = [LogMessage]::new("3:  This is a very long message to send through the magnificent, fantastic, extendable, easy-to-use, clever logging framework", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)
$logMessage = [LogMessage]::new("4:  This also happens to be a very long message that has been created in order to test the batching capablities of the PowerShell loging framework", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)
$logMessage = [LogMessage]::new("5:  And finally, this is the last message to pass into the logging framework that is somewhat long, but does the job of testing the batching capabilities of the logging framework", [LogLevel]::DEBUG)
$global:Logger.LogMessage($logMessage)
#$global:Logger.Stop() 