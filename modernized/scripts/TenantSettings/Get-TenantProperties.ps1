#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Exports current SharePoint Online tenant properties to the console and optionally to CSV.
.DESCRIPTION
    Clean PnP implementation for auditing or comparing tenants.
.PARAMETER AdminUrl
    SharePoint Admin Center URL.
.PARAMETER OutputPath
    Optional CSV path.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-TenantProperties.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : SharePoint Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUrl,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    [Parameter(Mandatory = $false)]
    [string]$ClientId,
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    [Parameter(Mandatory = $false)]
    [string]$CertificatePath,
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

$conn = $null
$ErrorActionPreference = 'Stop'
try {
    if ($Interactive) {
        $conn = Connect-PnPOnline -Url $AdminUrl -Interactive -ReturnConnection
    }
    elseif ($ClientId -and $TenantId -and $CertificatePath) {
        $conn = Connect-PnPOnline -Url $AdminUrl -ClientId $ClientId -Tenant $TenantId -CertificatePath $CertificatePath -ReturnConnection
    }
    else {
        throw "Specify -Interactive or app-only parameters."
    }
    $tenant = Get-PnPTenant -Connection $conn
    $report = [PSCustomObject]@{
        SharingCapability = $tenant.SharingCapability
        DefaultSharingLinkType = $tenant.DefaultSharingLinkType
        DefaultLinkPermission = $tenant.DefaultLinkPermission
        RequireAnonymousLinksExpireInDays = $tenant.RequireAnonymousLinksExpireInDays
        PreventExternalUsersFromResharing = $tenant.PreventExternalUsersFromResharing
        NotifyOwnersWhenItemsReshared = $tenant.NotifyOwnersWhenItemsReshared
        OneDriveStorageQuota = $tenant.OneDriveStorageQuota
        LegacyAuthProtocolsEnabled = $tenant.LegacyAuthProtocolsEnabled
        RequireAcceptingAccountMatchInvitedAccount = $tenant.RequireAcceptingAccountMatchInvitedAccount
    }
    $report | Format-List
    if ($OutputPath) {
        $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported to $OutputPath" -ForegroundColor Green
    }
    return $report
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
