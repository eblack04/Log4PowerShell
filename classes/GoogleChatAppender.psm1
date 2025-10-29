using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class GoogleChatAppender : Appender {

    [string]$webhookUrl

    [int]$maxRetryAttempts = 10

    [int]$retryInterval = 10

    GoogleChatAppender([object]$config) : base($config) {
        $this.webhookUrl = $config.webhookUrl
    }

    [void] WriteLog([string]$message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $message"
        
        $this.isProcessing = $true

        $retryCount = 0
        $success = $false
        $lastError = $null

        try {
            while ($retryCount -lt $this.maxRetryAttempts -and -not $success) {
                try {
                    # Create the Google Chat message payload
                    $chatMessage = @{
                        text = "$logEntry"
                    }

                    # Send to Google Chat webhook
                    $headers = @{
                        "Content-Type" = "application/json"
                    }

                    $body = $chatMessage | ConvertTo-Json -Compress
                    
                    # Add a small random delay to prevent rate limiting
                    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
                    
                    $response = Invoke-RestMethod -Uri $this.webhookUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop
                    
                    # If we get here, the request was successful
                    $success = $true
                    $this.lastSendTime = Get-Date
                    
                    # Log success if we had previous failures
                    if ($retryCount -gt 0) {
                        Write-Verbose "googleChatLogger ($($this.logName)): Successfully sent message after $retryCount retries."
                    }
                } catch {
                    $lastError = $_
                    $retryCount++

                    if ($retryCount -lt $this.maxRetryAttempts) {
                        $waitTime = $this.retryInterval * $retryCount
                        Write-Warning "googleChatLogger ($($this.name)): Failed to send message batch (attempt $retryCount/$($this.maxRetryAttempts)). Retrying in $waitTime seconds. Error: $($_.Exception.Message)"
                        Start-Sleep -Seconds $waitTime
                    } else {
                        Write-Error "googleChatLogger ($($this.name)): Failed to send message batch after $($this.maxRetryAttempts) attempts. Final error: $($_.Exception.Message)"
                        $this.lastSendTime = Get-Date
                    }
                }
            }
        } finally {
            $this.isProcessing = $false
        }
    }

    [void] WriteError([string]$message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - ERROR: $message"
    }
}