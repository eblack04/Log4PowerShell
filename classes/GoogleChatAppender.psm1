using module ".\Appender.psm1"
using module ".\LogMessage.psm1"
using module "..\enums\LogLevel.psm1"

[NoRunspaceAffinity()]
class GoogleChatAppender : Appender {

    [string]$WebhookUrl

    [int]$MaxRetryAttempts = 10

    [int]$RetryInterval = 10

    [string]$LogFile = "C:\Users\EdwardBlackwell\Documents\logs\google-chat.jog"

    GoogleChatAppender([object]$Config) : base($Config) {
        Add-Content -Path $this.logFile -Value "Web Hook URL:  $($config.webhookUrl)"

        if ($Config.webhookUrl) { $this.WebhookUrl = $Config.webhookUrl } else { throw "No webhook URL specified within the appender configuration"}
        if ($Config.maxRetryAttempts) { $this.MaxRetryAttempts = $Config.maxRetryAttempts }
        if ($Config.retryInterval) { $this.RetryInterval = $Config.retryInterval }
    }

    [void] LogMessage([LogMessage]$LogMessage) {
        Add-Content -Path $this.logFile -Value "LogMessage:  $($LogMessage.GetMessage())"

        # Create the Google Chat message payload
        $formattedMessage = "$($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())"
        $this.SendMessage($formattedMessage)
    }

    [void] LogMessages([LogMessage[]]$LogMessages) {
        $batchFormattedMessage = ""

        foreach($LogMessage in $LogMessages) {
            $batchFormattedMessage += "$($LogMessage.GetTimestamp().ToString($this.DatePattern)) - $($LogMessage.GetMessage())`n"
        }

        $this.SendMessage($batchFormattedMessage)
    }

    hidden [void] SendMessage([string]$Message) {
        $retryCount = 0
        $success = $false
        $lastError = $null

        while ($retryCount -lt $this.MaxRetryAttempts -and -not $success) {
            try {
                # Create the Google Chat message payload
                $chatMessage = @{
                    text = $Message
                }
                Add-Content -Path $this.logFile -Value "Message: $Message"
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
                    
                # Log success if we had previous failures
                if ($retryCount -gt 0) {
                    Write-Verbose "googleChatLogger ($($this.logName)): Successfully sent message after $retryCount retries."
                }
            } catch {
                Add-Content -Path $this.logFile -Value "Error: $($_.Exception.Message)"
                $lastError = $_
                $retryCount++

                if ($retryCount -lt $this.MaxRetryAttempts) {
                    $waitTime = $this.RetryInterval * $retryCount
                    Write-Warning "googleChatLogger ($($this.name)): Failed to send message batch (attempt $retryCount/$($this.MaxRetryAttempts)). Retrying in $waitTime seconds. Error: $($_.Exception.Message)"
                    Start-Sleep -Seconds $waitTime
                } else {
                    Write-Error "googleChatLogger ($($this.name)): Failed to send message batch after $($this.MaxRetryAttempts) attempts. Final error: $($_.Exception.Message)"
                }
            }
        }
    }
}