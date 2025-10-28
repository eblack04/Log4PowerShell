function Import-Config {
    param (
        [Parameter(Mandatory=$true)][ValidateScript({ Test-Path $_ })][String]$ConfigFile = "../config/logging.json"
    )

    #------------------------------------------
    # Loading and validating JSON configuration
    #------------------------------------------
    try {
        $global:configJsonPath = Join-Path $scriptPath $ConfigFile
        $global:configJsonContent = Get-Content $configJsonPath -ErrorAction Stop

        # Convert JSON content into an object; any conversion error will be caught.
        $global:envConfig = $configJsonContent | ConvertFrom-Json -ErrorAction Stop

        # Validate that the JSON object is not null or empty.
        if (-not $envConfig) {
            $logMessage = "ERROR | The JSON configuration is empty or invalid."
            Write-Error $logMessage
            $globalLogger.Enqueue($logMessage)
            throw
        }
    }
    catch {
        $logMessage = "ERROR | Failed to load or parse JSON configuration file: $($_.Exception.Message)"
        Write-Error $logMessage
        $globalLogger.Enqueue($logMessage)
        throw
    }
}
