$newDisks = @()

try {
    $newDisk2 = @{
        "Label" = "[disk2Label]"
        "Letter" = "[disk2Letter]"
        "Size" = ([int]"[disk2Size]")*1024*1024*1024
    }
    $newDisks += $newDisk2
} catch {
    # Do nothing
}

try {
    $newDisk3 = @{
        "Label" = "[disk3Label]"
        "Letter" = "[disk3Letter]"
        "Size" = ([int]"[disk3Size]")*1024*1024*1024
    }
    $newDisks += $newDisk3
} catch {
    # Do nothing
}

try {
    $newDisk4 = @{
        "Label" = "[disk4Label]"
        "Letter" = "[disk4Letter]"
        "Size" = ([int]"[disk4Size]")*1024*1024*1024
    }
    $newDisks += $newDisk4
} catch {
    # Do nothing
}

[System.Collections.ArrayList]$rawDisks = New-Object System.Collections.ArrayList
$rawDisks += Get-Disk | Where-Object { $_.PartitionStyle.ToUpper() -eq "RAW" }
if($newDisks.Count -ne $rawDisks.Count) {
    throw "The number of raw disks ($($rawDisks.Size)) does not equal the number of new disks ($($newDisks.Size))"
}

foreach($newDisk in $newDisks) {
    Write-Host "New Disk: $($newDisk.Label), Letter: $($newDisk.Letter), Size: $($newDisk.Size)"

    # This command will iterate through the list of raw disks, and find the first
    # entry with a size that matches the current new disk being processed.
    $rawDisk = $rawDisks | Where-Object { $_.Size -eq $newDisk.Size } | Select-Object -First 1

    # The above command should have found a matching raw disk, but just in case
    # it doesn't for some strange reason, then throw an exception.
    if($rawDisk) {
        Write-Host "Found matching disk: $($rawDisk.Number), Size: $($rawDisk.Size)"
        $rawDisks.Remove($rawDisk)
        Initialize-Disk -Number $rawDisk.Number -PartitionStyle MBR
        New-Partition -DiskNumber $rawDisk.Number -UseMaximumSize
        Get-Partition -DiskNumber $rawDisk.Number | Format-Volume -FileSystem NTFS -NewFileSystemLabel $newDisk.Label
        Get-Partition -DiskNumber $rawDisk.Number | Set-Partition -NewDriveLetter $newDisk.Letter
    } else {
        throw "No raw disk found with size $($newDisk.Size)"
    }
}
