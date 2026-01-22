$hostName = "auto-a.site-a.vcf.lab"
$orgName = "hol-all-apps"
if ($env:ApiToken) {
    $apiToken = $env:ApiToken
} else {
    $apiToken = ""
}

Import-Module -Name "/home/holuser/main/Log4PowerShell-main/bin/VMware.VCF.Automation.psm1"

try {
    # Generate a bearer token for the API token.
    $bearerToken = Get-BearerToken -HostName $hostName -OrgName $orgName -ApiToken $apiToken

    $contentLibraries = Get-ContentLibraries -HostName $hostName -BearerToken $bearerToken

    foreach ($contentLibrary in $contentLibraries) {
        Remove-ContentLibrary -HostName $hostName -BearerToken $bearerToken -Id $contentLibrary.id
    }

    # Retrieve the namespaces for the given organization.
    $namespaces = Get-Namespaces -HostName $hostName -BearerToken $bearerToken -OrgName $orgName

    $deletingNamespaceIds = @()

    # Start the deletion for each namespace.
    foreach ($namespace in $namespaces) {
        Write-Host "Starting the deletion of namespace:  $($namespace.name)"
        Remove-Namespace -HostName $hostName -BearerToken $bearerToken -Id $($namespace.id)
        $deletingNamespaceIds += $namespace.id
    }

    # Iterate over the namespaces until they are all deleted.
    while ($deletingNamespaceIds.Count -gt 0) {

        # Check to see if the current namespace has finished being deleted.  If
        # so, remove it from the list of namespaces being deleted.
        foreach ($deletingNamespaceId in $deletingNamespaceIds) {
            $namespace = Get-Namespace -HostName $hostName -BearerToken $bearerToken -Id deletingNamespaceId
        
            if(-not $namespace) {
                $deletingNamespaceIds = $deletingNamespaceIds -ne $deletingNamespaceId
            }
        }

        Start-Sleep -Seconds 15
    }

    # Next, delete the regional network settings for the organization.
    $regionalNetworkSettingIds = Get-RegionalNetworkSettings -HostName $hostName -BearerToken $bearerToken -OrgName $orgName

    foreach ($regionalNetworkSettingId in $regionalNetworkSettingIds) {
        Remove-RegionalNetworkSetting -HostName $hostName -BearerToken $bearerToken -Id $regionalNetworkSettingId.id
    }
} catch {
    $_
}
