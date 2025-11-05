using module "../modules/Log4PowerShell.psm1"

try {
    $ConfigFile = "./config/logging.json"
    $logger = [Logger]::new($ConfigFile)
    $logger.Start()
    $global:Logger = $logger

    $logHash1 = @{
        "vCenter" = "storelabvcsa"
        "Datacenter" = "05590US"
        "Cluster" = "vsh01.s05590.us"
        "ResourcePool" = "K8"
    }

    $logHash2 = @{
        "vCenter" = "storelabvcsa"
        "Datacenter" = "05591US"
        "Cluster" = "vsh01.s05591.us"
        "ResourcePool" = "K8"
    }

    $logHash3 = @{
        "vCenter" = "storelabvcsa"
        "Datacenter" = "32014US"
        "Cluster" = "vsh01.s32014.us"
        "ResourcePool" = "K8"
    }

    $logHash4 = @{
        "vCenter" = "storelabvcsa"
        "Datacenter" = "32015US"
        "Cluster" = "vsh01.s32015.us"
    }
    $logMessages = @()
    $logMessage = [LogMessage]::new($logHash1, [LogLevel]::DEBUG)
    $logMessages += $logMessage
    $global:Logger.LogMessage($logMessage)
    $logMessage = [LogMessage]::new($logHash2, [LogLevel]::DEBUG)
    $logMessages += $logMessage
    $global:Logger.LogMessage($logMessage)
    $logMessage = [LogMessage]::new($logHash3, [LogLevel]::DEBUG)
    $logMessages += $logMessage
    $global:Logger.LogMessage($logMessage)
    $logMessage = [LogMessage]::new($logHash4, [LogLevel]::DEBUG)
    $logMessages += $logMessage
    $global:Logger.LogMessage($logMessage)
    $logMessage = [LogMessage]::new("4:  This also happens to be a very long message that has been created in order to test the batching capablities of the PowerShell loging framework", [LogLevel]::DEBUG)
    $logMessages += $logMessage
    $global:Logger.LogMessage($logMessage)
    $logMessage = [LogMessage]::new("5:  And finally, this is the last message to pass into the logging framework that is somewhat long, but does the job of testing the batching capabilities of the logging framework", [LogLevel]::DEBUG)
    $logMessages += $logMessage
    $global:Logger.LogMessage($logMessage)

    foreach ($i in 0..1000) {
        foreach ($logMessage in $logMessages) {
            Start-Sleep -Milliseconds 50
            $global:Logger.LogMessage($logMessage)
        }
    }


    $logMessages = @()
    

    #$global:Logger.Stop()
} catch {
    Write-Host "Error in Test-Logger:  $($_.Exception.Message)"
}