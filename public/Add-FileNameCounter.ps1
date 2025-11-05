function Add-FileNameCounter {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$FileName,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][int]$Counter
    )

    $matchResults = [regex]::Match($FileName, "(.*)(\..*)")

    if ($matchResults.Success) {
        return $matchResults.Groups[1].Value + "-" + $Counter + $matchResults.Groups[2].Value
    } else {
        return $FileName
    }
}