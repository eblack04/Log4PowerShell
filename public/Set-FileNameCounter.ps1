function Set-FileNameCounter {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$FileName,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][int]$Counter
    )

    $matchResults = [regex]::Match($FileName, "(.*)([0-9])([.].*)")

    if ($matchResults.Success) {
        return $matchResults.Groups[1].Value + $Counter + $matchResults.Groups[3].Value
    } else {
        return $FileName
    }
}