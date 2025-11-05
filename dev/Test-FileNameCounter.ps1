using module "../modules/Log4PowerShell.psm1"

$fileName = $null
$newFileName1 = $null
$newFileName2 = $null
$newFileName3 = $null

$fileName = "file-%d{MM-dd-yyyy-HH-mm-ss}-log.other.stuff"
$fileName = "C:\Users\EdwardBlackwell\Documents\logs\file-appender.log"
Write-Host "fileName:  $fileName"

$newFileName1 = Add-FileNameCounter -FileName $fileName -Counter 1

Write-Host "newFileName1:  $newFileName1"

$newFileName2 = Set-FileNameCounter -FileName $newFileName1 -Counter 2

Write-host "newFileName2:  $newFileName2"

$string1 = "lslkekd-1.log"
Write-Host "string1:  $string1"

$newFileName3 = Set-FileNameCounter -FileName $string1 -Counter 5

Write-Host "newFileName3:  $newFileName3"