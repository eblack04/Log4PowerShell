Function Get-BearerToken {
    <#
    .NOTES
        ========================================================================
        Created by: Todd Blackwell
        Organization: Walmart
        ========================================================================
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER HostName
        (Mandatory) The configuration object containing the cluster 
        configuration values.
    .PARAMETER OrgName
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER ApiToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$false)][String]$OrgName="hol-all-apps",
        [Parameter(Mandatory=$true)][String]$ApiToken
    )

    Write-Host "Host Name:  $HostName"
    Write-Host "Org Name:  $OrgName"
    Write-Host "API Token:  $ApiToken"

    try {
        $uri = "https://$HostName/oauth/provider/token"
        $method = "POST"

        $headers = @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }

        $body = @{
            "grant_type" = "refresh_token"
            "refresh_token" = "$ApiToken"
        }

        $tokenResponse = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -Body $body

        if($tokenResponse.access_token) {
            Write-Host "Bearer Token:  $($tokenResponse.access_token)"
            return $tokenResponse.access_token
        } else {
            throw "No access token returned from successful authentication call"
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving access token ($statusCode):  $statusDescription"
    }
}

Function Get-Namespaces {
    <#
    .NOTES
        ========================================================================
        Created by: Todd Blackwell
        Organization: Walmart
        ========================================================================
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER HostName
        (Mandatory) The configuration object containing the cluster 
        configuration values.
    .PARAMETER OrgName
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$OrgName,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Host Name:  $HostName"
    Write-Host "Org Name:  $OrgName"
    Write-Host "API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/namespaceSummaries"
        $method = "GET"

        if($OrgName) {
            $filter = [uri]::EscapeDataString("organization.name==$OrgName")
            $uri += "?filter=$filter"
        }

        $namespacesResponse = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers

        if($namespacesResponse) {
            $namespacesJson = $namespacesResponse | ConvertTo-Json -Depth 5
            Write-Host "Namespaces:  $namespacesJson"

            return $namespacesResponse.values
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving namespaces ($statusCode):  $statusDescription"
    }
}

Function Get-Namespace {
    <#
    .NOTES
        ========================================================================
        Created by: Todd Blackwell
        Organization: Walmart
        ========================================================================
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER HostName
        (Mandatory) The configuration object containing the cluster 
        configuration values.
    .PARAMETER OrgName
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$NamespaceId,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Host Name:  $HostName"
    Write-Host "Namespace ID:  $NamespaceId"
    Write-Host "API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/namespaceSummaries"
        $method = "GET"

        if($NamespaceId) {
            $filter = [uri]::EscapeDataString("id==$NamespaceId")
            $uri += "?filter=$filter"
        }

        $namespacesResponse = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers

        if($namespacesResponse) {
            $namespacesJson = $namespacesResponse | ConvertTo-Json -Depth 5
            Write-Host "Namespaces:  $namespacesJson"

            return $namespacesResponse.values
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving namespaces ($statusCode):  $statusDescription"
    }
}

Function Delete-Namespaces {
    <#
    .NOTES
        ========================================================================
        Created by: Todd Blackwell
        Organization: Walmart
        ========================================================================
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER HostName
        (Mandatory) The configuration object containing the cluster 
        configuration values.
    .PARAMETER NamespaceId
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$NamespaceId,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Host Name:  $HostName"
    Write-Host "Namespace ID:  $NamespaceId"
    Write-Host "API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/namespace/$NamespaceId"
        $method = "DELETE"

        Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving namespaces ($statusCode):  $statusDescription"
    }
}

Function Get-ContentLibraries {
    <#
    .NOTES
        ========================================================================
        Created by: Todd Blackwell
        Organization: Walmart
        ========================================================================
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER HostName
        (Mandatory) The configuration object containing the cluster 
        configuration values.
    .PARAMETER OrgName
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Host Name:  $HostName"
    Write-Host "API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/contentLibraries"
        $method = "GET"

        $contentLibrariesResponse = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers

        if($contentLibrariesResponse) {
            $contentLibrariesJson = $contentLibrariesResponse | ConvertTo-Json -Depth 5
            Write-Host "Content Libraries:  $contentLibrariesJson"

            return $contentLibrariesResponse.values
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving content libraries ($statusCode):  $statusDescription"
    }
}

Function Get-ContentLibraryByName {
    <#
    .NOTES
        ========================================================================
        Created by: Todd Blackwell
        Organization: Walmart
        ========================================================================
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER HostName
        (Mandatory) The configuration object containing the cluster 
        configuration values.
    .PARAMETER OrgName
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$ContentLibraryName,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Host Name:  $HostName"
    Write-Host "Content Library Name:  $ContentLibraryName"
    Write-Host "API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/contentLibraries"
        $method = "GET"

        if($ContentLibraryName) {
            $filter = [uri]::EscapeDataString("name==$ContentLibraryName")
            $uri += "?filter=$filter"
        }

        $contentLibrariesResponse = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers

        if($contentLibrariesResponse) {
            $contentLibrariesJson = $contentLibrariesResponse | ConvertTo-Json -Depth 5
            Write-Host "Content Libraries:  $contentLibrariesJson"

            if($contentLibrariesResponse.values.Count -eq 0) {
                throw "No content library found with name $ContentLibraryName"
            }

            if($contentLibrariesResponse.values.Count -gt 1) {
                throw "More than one content library found with name $ContentLibraryName"
            }

            return $contentLibrariesResponse.values
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving content libraries ($statusCode):  $statusDescription"
    }
}