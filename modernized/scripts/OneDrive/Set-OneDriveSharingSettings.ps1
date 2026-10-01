#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Configures common OneDrive for Business sharing settings at tenant level.
.DESCRIPTION
    Surfaces tenant sharing capability; detailed ODB toggles may still require Admin Center.
.PARAMETER AdminUrl
    SharePoint Admin Center URL.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-OneDriveSharingSettings.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -Interactive
.NOTES
    Risk Level      : Medium
    Required Roles  : SharePoint Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUrl,
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
    Write-Host "Current tenant sharing capability: $($tenant.SharingCapability)" -ForegroundColor Cyan
    Write-Host "Review OneDrive-specific toggles in SharePoint Admin Center > Policies > Sharing." -ForegroundColor Cyan
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
