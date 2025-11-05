function DisplayFileSize {
    param (
        $bytecount
    )
    
    switch -Regex ([math]::truncate([math]::log($bytecount,1024))) {
        '^0' {"$bytecount Bytes"}
        '^1' {"{0:n2} KB" -f ($bytecount / 1KB)}    
        '^2' {"{0:n2} MB" -f ($bytecount / 1MB)}
        '^3' {"{0:n2} GB" -f ($bytecount / 1GB)}
        '^4' {"{0:n2} TB" -f ($bytecount / 1TB)}
        Default {"{0:n2} Bytes" -f ($bytecount / 1KB)}
    }
}

$fileSize1 = 20Gb
$fileSize2 = 15Mb

Write-Host "fileSize1:  $fileSize1"
Write-Host "fileSize2:  $fileSize2"

Write-Host "fileSize1 (user friendly):  $(DisplayFileSize -bytecount $fileSize1)"

$fileSize1 += 299394934

Write-Host "fileSize1 (user friendly):  $(DisplayFileSize -bytecount $fileSize1)"