<#
.SYNOPSIS
    This is a utility function that inserts a timestamp into a given string.
.DESCRIPTION
    This function takes a file name string as input, looks for a date format 
    string within the file name where the date format is bounded by the 
    characters "%d{<date format>}", and then uses that date format to create a
    timestamp string.  the timestamp is then inserted into the file name where
    the markup text resided.

    For example, given that this function is called like the following:

    Convert-ToTimestampFileName -FileName "csv-main-%d{MM-dd-yyyy}.log"

    And that the current date is November 4, 2025, then the returned string 
    will be:

    "csv-main-11-04-2025.log"

    If no date format string is present within the supplied string, then the
    string is simply echoed back.  Also, the date format string within the file
    name is checked to make sure there are no invalid file name characters 
    present.  If any are found, and exception is thrown.
#>
function Convert-ToTimestampFileName {
    param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$InputString
    )

    $datePattern = [regex]::Match($InputString, ".*%d{(.*)}.*")

    if ($datePattern.Success) {
        $pattern = $datePattern.Groups[1].Value
        $timestamp = Get-Date -Format $pattern
        $InputString = $InputString -replace "%d{.*}", $timestamp
    }

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()

    foreach ($char in $invalidChars) {
        if ($InputString.Contains($char)) {
            throw "Invalid file name: $InputString"
        }
    }

    return $InputString
}