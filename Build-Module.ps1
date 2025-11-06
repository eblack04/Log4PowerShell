<#
.SYNOPSIS
    Builds a PowerShell module from the project script and module files.
.DESCRIPTION
    This script concatenates both script and module files from specified project
    directories, and outputs the generated module (.psm1) and manifest (.psd1) 
    files into the modules directory.

    The source folders containing the project .psm1 and .ps1 files are as 
    follows:

      - enums: Contains enumeration definitions.
      - classes: Contains class definitions.
      - private: Contains private functions.
      - public: Contains public functions.

    After writing the .psm1 file, the script automatically generates a module 
    manifest (.psd1) using New-ModuleManifest.
.PARAMETER ModuleName
    The name of the module. The output folder will be named after the module, and the module
    files will be named as <ModuleName>.psm1 and <ModuleName>.psd1. Default is 'Log4PowerShell'.
.PARAMETER OutputFolder
    The parent folder where the module folder will be created. Default is '.\Modules'.
.PARAMETER ClassesFolder
    The folder containing .ps1 files with class definitions. Default is '.\source\Classes'.
.PARAMETER PrivateFolder
    The folder containing .ps1 files with private functions. Default is '.\source\Private'.
.PARAMETER PublicFolder
    The folder containing .ps1 files with public functions. Default is '.\source\Public'.
.PARAMETER ModuleVersion
    The version number to embed in the module header and manifest (e.g., '1.0.0'). This parameter is required.
.PARAMETER CompanyName
    The company name used for the manifest’s CompanyName.
.PARAMETER Author
    The module author.
.PARAMETER RequiredModules
    An array of module names that your module depends on. Default is an empty array.
.EXAMPLE
    .\Build-Module.ps1 -ModuleName 'TestModule' -ModuleVersion '1.0.0' -OutputFolder '.\Modules'
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$ModuleName = "Log4PowerShell",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$OutputFolder = ".\modules",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$ClassesFolder = ".\classes",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$EnumsFolder = ".\enums",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$PrivateFolder = ".\private",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$PublicFolder = ".\public",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$ModuleVersion = "1.0",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$Description = "vSphere Logging",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$PowershellVersion = "7.4",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$CompanyName = "Broadcom",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$Author = "Todd Blackwell",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string[]]$RequiredModules = @()
)

#------------------------------------------
# Define full paths for the module script and manifest.
#------------------------------------------
$ModulePsm1Path = Join-Path -Path $OutputFolder -ChildPath ("$ModuleName.psm1")
$ModuleManifestPath = Join-Path -Path $OutputFolder -ChildPath ("$ModuleName.psd1")

#------------------------------------------
# Build the module file content in memory.
#------------------------------------------
$script:ModuleContent = @()

# Module Header
$ModuleHeader = @"
# ====================================================================================
# Module: $ModuleName
# Version: $ModuleVersion
# Generated: $(Get-Date -Format 'MM-dd-yyyy HH:mm:ss')
# Description: Module for managing vSphere Lifecycle
# ====================================================================================
"@
$script:ModuleContent += $ModuleHeader

function Get-ClassModuleList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][ValidateScript({ Test-Path $_ })][String]$FilePath
    )

    $FilePath = Resolve-Path -Path $FilePath
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

#------------------------------------------
# Helper Function: Get-FileContent
#------------------------------------------
Function Get-FileContent {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    Write-Host "Getting file content for file:  $Path"

    Try {
        $content = Get-Content -LiteralPath $Path -ErrorAction Stop
        $filteredContent = $()

        $content | ForEach-Object {
            Write-Host "Line: $_ end-of-line"
            if ($_ -notmatch "using module *") {
                $filteredContent += $_ + "`n"
            }
        }

        return $filteredContent
    } Catch {
        Write-Error "ERROR | Failed to read file '$Path'. Error: $($_.Exception.Message)"
        throw
    }
}

#------------------------------------------
# Create a list to collect public function names for manifest export.
#------------------------------------------
$PublicFunctionNames = [System.Collections.Generic.List[string]]::new()

#------------------------------------------
# Helper Function: Merge-Files
#------------------------------------------
Function Merge-Files {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)][string]$SectionName,
        [parameter(Mandatory=$true)][System.IO.FileInfo[]]$Files,
        [parameter(Mandatory=$false)][Switch]$IsPublic=$false
    )

    foreach ($file in $Files) {
        $nameBase = $file.BaseName

        # Read the file's content.
        $content = Get-FileContent -Path $file.FullName

        # Build header and footer for clarity.
        $sectionHeader = @"
# -------------------------------------------------------------------------
# Start: $SectionName - $nameBase
# -------------------------------------------------------------------------
"@
        $sectionFooter = @"
# -------------------------------------------------------------------------
# End: $SectionName - $nameBase
# -------------------------------------------------------------------------
"@

        $script:ModuleContent += $sectionHeader
        $script:ModuleContent += $content
        $script:ModuleContent += $sectionFooter

        if ($IsPublic) {
            $PublicFunctionNames.Add($nameBase)
        }
    }
}

#------------------------------------------
# Validate input directories; skip any that do not exist.
#------------------------------------------
foreach ($folder in @($ClassesFolder, $PrivateFolder, $PublicFolder)) {
    if (-not (Test-Path -LiteralPath $folder)) {
        Write-Warning "WARNING | Directory '$folder' does not exist and will be skipped."
    }
}

#------------------------------------------
# Merge Private function files.
#------------------------------------------
if (Test-Path -LiteralPath $PrivateFolder) {
    Write-Host "Merging files in the $PrivateFolder folder"
    $privateFiles = Get-ChildItem -Path $PrivateFolder -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    if ($privateFiles -and $privateFiles.Count -gt 0) {
        Merge-Files -SectionName "Private Function" -Files $privateFiles 
    }
}

#------------------------------------------
# Merge class files.
#------------------------------------------
if (Test-Path -LiteralPath $ClassesFolder) {
    Write-Host "Merging files in the $ClassesFolder folder"
    $classFiles = Get-ClassModuleList -FilePath $ClassesFolder
    if ($classFiles -and $classFiles.Count -gt 0) {
        Merge-Files -SectionName "Class Definition" -Files $classFiles
    }
}

#------------------------------------------
# Merge enumeration files.
#------------------------------------------
if (Test-Path -LiteralPath $EnumsFolder) {
    Write-Host "Merging files in the $EnumsFolder folder"
    $enumsFiles = Get-ChildItem -Path $EnumsFolder -Filter '*.psm1' -File -ErrorAction SilentlyContinue
    if ($enumsFiles -and $enumsFiles.Count -gt 0) {
        Merge-Files -SectionName "Enum Definition" -Files $enumsFiles
    }
}

#------------------------------------------
# Merge Public function files.
#------------------------------------------
if (Test-Path -LiteralPath $PublicFolder) {
    Write-Host "Merging files in the $PublicFolder folder"
    $publicFiles = Get-ChildItem -Path $PublicFolder -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    if ($publicFiles -and $publicFiles.Count -gt 0) {
        Merge-Files -SectionName "Public Function" -Files $publicFiles -IsPublic
    }
}

#------------------------------------------
# Append Export-ModuleMember statement for public functions.
#------------------------------------------
if ($PublicFunctionNames.Count -gt 0) {
    $exportLine = "Export-ModuleMember -Function " + ($PublicFunctionNames -join ', ')
    $script:ModuleContent += $exportLine
}

#------------------------------------------
# Write the complete module content to the .psm1 file.
#------------------------------------------
try {
    Set-Content -Path $ModulePsm1Path -Value $script:ModuleContent -ErrorAction Stop -Encoding UTF8
    Write-Host "INFO | Successfully wrote module file to '$ModulePsm1Path'." -ForegroundColor Green
}
catch {
    Write-Error "ERROR | Failed to write module file '$ModulePsm1Path'. Error: $($_.Exception.Message)"
    throw
}

#------------------------------------------
# Generate the module manifest (.psd1) for publishing.
#------------------------------------------
try {
    $ExportedFunctions = if ($PublicFunctionNames.Count -gt 0) { $PublicFunctionNames.ToArray() } else { @() }
    $manifestParams = @{
        Path              = $ModuleManifestPath
        RootModule        = (Split-Path -Leaf $ModulePsm1Path)
        ModuleVersion     = $ModuleVersion
        Author            = $Author
        CompanyName       = $CompanyName
        Description       = $Description
        FunctionsToExport = $ExportedFunctions
        PowerShellVersion = $PowershellVersion
        RequiredModules   = $RequiredModules
    }
    New-ModuleManifest @manifestParams | Out-Null
    Write-Host "INFO | Module manifest created at '$ModuleManifestPath'." -ForegroundColor Green
}
catch {
    Write-Error "ERROR | Failed to create module manifest '$ModuleManifestPath'. Error: $($_.Exception.Message)"
    throw
}

#------------------------------------------
# Final summary.
#------------------------------------------
Write-Output "Module build complete. The module '$ModuleName' (version $ModuleVersion) has been built in folder '$ModuleFolder'. You can now use Publish-Module on this folder."
