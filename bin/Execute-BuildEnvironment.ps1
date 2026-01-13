$hostName = "auto-a.site-a.vcf.lab"
$orgName = "hol-all-apps"
$apiToken = ""

try {
    # Generate a bearer token for the API token.
    $bearerToken = Get-BearerToken -HostName $hostName -OrgName $orgName -ApiToken $apiToken

    # Retrieve the namespaces for the given organization.
    $namespaces = Get-Namespaces -HostName $hostName -OrgName $orgName -BearerToken $bearerToken

    $deletingNamespaceIds = @()

    # Start the deletion of each of the namespaces.
    foreach ($namespace in $namespaces) {
        Write-Host "Deleting namespace: $($namespace.name)"
        Delete-Namespace -HostName $hostName -NamespaceId $($namespace.id) -BearerToken $bearerToken
        $deletingNamespaceIds += $namespace.id
    }

    # Check to make sure each namespace has finished being deleted.
    while ($deletingNamespaceIds.Count -gt 0) {
        
        # Check to see if a namespace has finished being deleted.  If so, remove
        # it from the list of namespaces being deleted.
        foreach ($deletingNamespaceId in $deletingNamespaceIds) {
            $namespace = Get-Namespace -HostName $hostName -NamespaceId $deletingNamespaceId -BearerToken $bearerToken

            # If no namespace is retrieved, then the deletion is finished.
            if(-not $namespace) {
                $deletingNamespaceIds = $deletingNamespaceId -ne $deletingNamespaceId
            }
        }

        Start-Sleep -Seconds 15
    }
} catch {
    $_
}