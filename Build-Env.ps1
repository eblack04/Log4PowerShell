<#
.SYNOPSIS
    This script configures the VMware PowerShell environment by performing the 
    following actions:

    1.  Validate that the current Powershell version is 7.4, or above.
    2.  Define the script and module path variables.
    3.  Import the VMware modules.
    4.  Import the non-VMware modules.
    5.  Import the VMware logging module contained within this project.
    6.  Read the logging JSON file.
    7.  Initialize the logging framework.
#>

#-------------------------------------------------------------------------------
# Verify Version of PowerCLI and PowerShell
# Requires -Version 7.4
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Dynamically define the script path
#-------------------------------------------------------------------------------
# Script path is used across many scripts and functions to set a baseline for paths.
try {
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path
    $modulePath = "$scriptPath/modules"
    Write-Output "modulePath:  $modulePath"
}
catch {
    Write-Error "ERROR | Failed to set path: $($_.Exception.Message)"
    throw "ERROR | Failed to set path: $($_.Exception.Message)"
}

#-------------------------------------------------------------------------------
# Importing VMware PowerCLI modules
#-------------------------------------------------------------------------------
try {
    Write-Host "INFO | Importing VMware PowerCLI modules..." -ForegroundColor Yellow
    Import-Module VMware.VimAutomation.Core -ErrorAction Stop
    Import-Module VMware.VimAutomation.Common -ErrorAction Stop
    Import-Module VMware.VimAutomation.SDK -ErrorAction Stop
    Write-Host "INFO | VMware PowerCLI module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "ERROR | Failed to import VMware PowerCLI module: $($_.Exception.Message)"
    throw "ERROR | Failed to import VMware PowerCLI module: $($_.Exception.Message)"
}

#-------------------------------------------------------------------------------
# Importing non-VMware PowerCLI modules
#-------------------------------------------------------------------------------
try {
    Write-Host "INFO | Importing non-VMware PowerCLI modules..." -ForegroundColor Yellow
    Import-Module Import-Module Pester -PassThru -ErrorAction Stop
    Write-Host "INFO | VMware PowerCLI module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "ERROR | Failed to import non-VMware PowerCLI module: $($_.Exception.Message)"
    throw "ERROR | Failed to import non-VMware PowerCLI module: $($_.Exception.Message)"
}

#-------------------------------------------------------------------------------
# Importing VMware Logging module
#-------------------------------------------------------------------------------
try {
    Write-Host "INFO | Importing VMware Logging module..." -ForegroundColor Yellow
    Import-Module "$modulePath/VMware.Logging.psm1" -ErrorAction Stop
    Write-Host "INFO | VMware Lifecycle module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "ERROR | Failed to import VMware Logging module: $($_.Exception.Message)"
    throw "ERROR | Failed to import VMware Logging module: $($_.Exception.Message)"
}

#-------------------------------------------------------------------------------
# Loading and validating JSON configuration
#-------------------------------------------------------------------------------
try {
    $configJsonPath = Join-Path $scriptPath "config/logging.json"
    $configJsonContent = Get-Content $configJsonPath -ErrorAction Stop

    # Convert JSON content into an object; any conversion error will be caught.
    $envConfig = $configJsonContent | ConvertFrom-Json -ErrorAction Stop

    # Validate that the JSON object is not null or empty.
    if (-not $envConfig) {
        Write-Error "ERROR | The JSON configuration is empty or invalid."
        throw "Empty or invalid JSON configuration."
    }
}
catch {
    Write-Error "ERROR | Failed to load or parse JSON configuration file: $($_.Exception.Message)"
    throw "ERROR | Failed to load or parse JSON configuration file: $($_.Exception.Message)"
}

#-------------------------------------------------------------------------------
# Initializing loggers
#-------------------------------------------------------------------------------
<#
try {
    Write-Host "INFO | Initializing loggers..." -ForegroundColor Yellow

    # Define local log paths
    $localLogPath1 = Join-Path $scriptPath "log.log"
    $localLogPath2 = Join-Path $scriptPath "log2.log"

    # Create logger instances
    $logger1 = New-FileLogger -Path $localLogPath1 -Name "File Logger"
    $globalLogger = New-GlobalLogger
    $globalLogger.AddLogger($logger1)

    Write-Host "INFO | Loggers initialized and added to the global logger." -ForegroundColor Green
}
catch {
    Write-Error "ERROR | Error initializing loggers: $($_.Exception.Message)"
    throw "ERROR | Error initializing loggers: $($_.Exception.Message)"
}
#>

#------------------------------------------
# Cleaning up existing jobs
#------------------------------------------
<#
try {
    $logMessage = "INFO | Stopping and removing all existing jobs..."
    Write-Host $logMessage -ForegroundColor Yellow
    $globalLogger.Enqueue($logMessage)

    Get-Job | Stop-Job
    Get-Job | Remove-Job

    $logMessage = "INFO | All existing jobs stopped and removed successfully."
    Write-Host $logMessage -ForegroundColor Green
    $globalLogger.Enqueue($logMessage)
}
catch {
    $errorMsg = "ERROR | Error while stopping or removing jobs: $($_.Exception.Message)"
    Write-Error $errorMsg
}
#>

#------------------------------------------
# Starting logging servers
#------------------------------------------
<#
try {
    Write-Host "INFO | Starting logging servers for all registered loggers..." -ForegroundColor Yellow
    $globalLogger.Loggers | ForEach-Object {
        Start-LogServer -Logger $_
        $logMessage = "INFO | Log server started for: $($_.LogName)"
        Write-Host $logMessage -ForegroundColor Cyan
        $globalLogger.Enqueue($logMessage)
    }
    $logMessage = "INFO | All log servers started successfully."
    Write-Host $logMessage -ForegroundColor Green
    $globalLogger.Enqueue($logMessage)
}
catch {
    $errorMsg = "ERROR | Error starting log servers: $($_.Exception.Message)"
    Write-Error $errorMsg
    throw $errorMsg
}
#>




#------------------------------------------
# Marking environment setup as successful
#------------------------------------------
<#
$envSetupSuccess = $true
$logMessage = "INFO | Environment setup completed successfully. envSetupSuccess set to $envSetupSuccess."
Write-Host $logMessage -ForegroundColor Green
$globalLogger.Enqueue($logMessage)
#>
