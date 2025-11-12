function Get-ClassModuleList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][ValidateScript({ Test-Path $_ })][String]$FilePath
    )

    $fileList = @()
    $classModuleFiles = Get-ChildItem -Path $FilePath -File

    # Iterate over each class module file in the given directory.
    foreach ($classModuleFile in $classModuleFiles) {

        # Grab the content of the current file.
        $content = Get-Content -LiteralPath $classModuleFile.FullName -ErrorAction Stop

        # Iterate over each line of the content.
        $content | ForEach-Object {

            # Search for the lines that use other modules.
            $matchResults = [regex]::Match($_, 'using module ".*\\([\w]+.psm1)"$')
            
            # If a 'using module' line is found, then extract the module name 
            # and add it to the list.
            if ($matchResults.Success) {

                # Grab the module name piece of the line.
                $fileName = $FilePath + [System.IO.Path]::DirectorySeparatorChar + $matchResults.Groups[1].Value

                # Check to make sure the module file is in the given directory,
                # and that it isn't already in the list of module files.
                if ((Test-Path $fileName) -and ($fileList -notcontains $fileName)) {
                    $fileList += $fileName
                }
            }
        }

        # Finally, add the file that's currently being processed.
        if ($fileList -notcontains $classModuleFile.FullName) {
            $fileList += $classModuleFile.FullName
        }
    }

    return $fileList
}

$filePath = "G:\My Drive\GitHub\Log4PowerShell\classes"
$fileList = Get-ClassModuleList -FilePath $filePath

foreach ($fileName in $fileList) {
    Write-Host "File Name:  $filename"
}
