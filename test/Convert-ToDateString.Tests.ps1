Describe "Convert-ToDateFileName" {
    Context "When called with valid input" {
        It "Should return the correct result" {
            # Arrange: Set up the environment and input
            $unformattedFileName = "file-%d{MM-dd-yyyy-HH-mm}-log.log"
            Write-Host "unformattedFileName:  $unformattedFileName"
            $timestampString = Get-Date -Format "MM-dd-yyyy-HH-mm"
            Write-Host "timestampString:  $timestampString"
            $formattedFileName = "file-$timestampString-log.log"
            Write-Host "formattedFileName:  $formattedFileName"

            # Act: Call the function being tested
            $outputFormattedFileName = Convert-ToDateFileName -FileName $unformattedFileName
            Write-Host "outputFormattedFileName:  $outputFormattedFileName"

            # Assert: Verify the output
            $outputFormattedFileName | Should -Be $formattedFileName
        }
    }
}