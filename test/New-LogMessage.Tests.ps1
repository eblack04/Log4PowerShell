
using module "../modules/Log4PowerShell.psm1"

Describe "New-LogMessage" {
    Context "When called with valid input" {
        It "Should return the correct result" {

            $message = "A log message"
            Write-Host "message:  $message"

            $logMessage = New-LogMessage -Message $message -LogLevel DEBUG
            $logMessage.GetMessage() | Should -Be $message
        }
    }
}

Describe "New-LogMessage" {
    Context "When called with valid input" {
        It "Should return the correct result" {
            $logMessageHash = [ordered]@{
                "param1" = "value1"
                "param2" = "value2"
                "param3" = "value3"
            }

            $logMessage = New-LogMessage -Message $logMessageHash -LogLevel DEBUG
            $logMessage.GetMessage() | Should -Be "param1 = value1, param2 = value2, param3 = value3"
        }
    }
}