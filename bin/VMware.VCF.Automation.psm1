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

    Write-Host "Get-BearerToken"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   Org Name:  $OrgName"
    Write-Host "   API Token:  $ApiToken"

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

    Write-Host "Get-Namespaces"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   Org Name:  $OrgName"
    Write-Host "   API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/namespaceSummaries"
        $method = "GET"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

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
        [Parameter(Mandatory=$true)][String]$Id,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Get-Namespace"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   ID:  $Id"
    Write-Host "   API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/namespaceSummaries"
        $method = "GET"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

        if($Id) {
            $filter = [uri]::EscapeDataString("id==$Id")
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

Function Remove-Namespace {
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
    .PARAMETER Id
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$Id,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Remove-Namespace"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   ID:  $Id"
    Write-Host "   API Token:  $BearerToken"

    try {
        # First, check to see if the namespace is present as trying to delete a
        # namespace that is either not present, or already has a status of
        # "DELETING", will throw an exception that is not too informative.
        $namespace = Get-Namespace -HostName $hostName -BearerToken $bearerToken -Id $Id

        if ($namespace) {
            if ($namespace.status -eq "DELETING") {
                return
            }
        } else {
            throw "No namespace with ID $Id present within host $HostName"
        }

        $uri = "https://$HostName/cloudapi/vcf/namespaces/$([uri]::EscapeDataString($Id))?force=true"
        $method = "DELETE"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

        Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error removing namespace with ID $Id ($statusCode):  $statusDescription"
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
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Get-ContentLibraries"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   Name:  $Name"
    Write-Host "   API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/contentLibraries"
        $method = "GET"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

        if($Name) {
            $filter = [uri]::EscapeDataString("name==$Name")
            $uri += "?filter=$filter"
        }

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

Function Remove-ContentLibrary {
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
        [Parameter(Mandatory=$true)][String]$Id,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Remove-ContentLibrary"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   ID:  $Id"
    Write-Host "   API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/contentLibraries/$([uri]::EscapeDataString($Id))?force=true"
        $method = "DELETE"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

        Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error deleting content library $ContentLibraryId ($statusCode):  $statusDescription"
    }
}

Function Get-RegionalNetworkSettings {
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
    .PARAMETER Id
        (Optional) 
    .PARAMETER Name
        (Optional)
    .PARAMETER OrgId
        (Optional) 
    .PARAMETER OrgName
        (Optional) 
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$false)][String]$Id,
        [Parameter(Mandatory=$false)][String]$Name,
        [Parameter(Mandatory=$false)][String]$OrgId,
        [Parameter(Mandatory=$false)][String]$OrgName,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Get-RegionalNetworkSettings"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   Bearer Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/regionalNetworkingSettings"
        $method = "GET"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

        if($Id) {
            $filter = [uri]::EscapeDataString("id==$Id")
            $uri += "?filter=$filter"
        }

        if($Name) {
            $filter = [uri]::EscapeDataString("name==$Name")
            $uri += "?filter=$filter"
        }

        if($OrgId) {
            $filter = [uri]::EscapeDataString("orgRef.id==$OrgId")
            $uri += "?filter=$filter"
        }

        if($OrgName) {
            $filter = [uri]::EscapeDataString("orgRef.name==$OrgName")
            $uri += "?filter=$filter"
        }

        $regionalNetworkSettingsResponse = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers

        if($regionalNetworkSettingsResponse) {
            $regionalNetworkSettingsJson = $regionalNetworkSettingsResponse | ConvertTo-Json -Depth 5
            Write-Host "Regional Network Settings:  $regionalNetworkSettingsJson"

            return $regionalNetworkSettingsResponse.values
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error retrieving regional network setting $Id ($statusCode):  $statusDescription"
    }
}

Function Remove-RegionalNetworkSetting {
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
    .PARAMETER Id
        (Mandatory) The vCenter connection object that contains the cluster.
    .PARAMETER BearerToken
        (Mandatory) The API token.
    .EXAMPLE
        Initialize-Cluster -ClusterConfiguration $clusterConfiguration -Vcenter $vcenter
    #>
    param(
        [Parameter(Mandatory=$false)][String]$HostName="auto-a.site-a.vcf.lab",
        [Parameter(Mandatory=$true)][String]$Id,
        [Parameter(Mandatory=$true)][String]$BearerToken
    )

    Write-Host "Remove-RegionalNetworkSetting"
    Write-Host "   Host Name:  $HostName"
    Write-Host "   ID:  $Id"
    Write-Host "   API Token:  $BearerToken"

    try {
        $uri = "https://$HostName/cloudapi/vcf/regionalNetworkingSettings/$([uri]::EscapeDataString($Id))"
        $method = "DELETE"

        $headers = @{
            "Accept" = "application/json;version=40.0"
            "Authorization" = "Bearer $BearerToken"
        }

        Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $statusDescription = $_.Exception.Response.StatusCode
        throw "Error deleting regional network setting $Id ($statusCode):  $statusDescription"
    }
}
