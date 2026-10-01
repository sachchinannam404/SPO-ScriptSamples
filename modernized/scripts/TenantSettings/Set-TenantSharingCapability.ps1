#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Sets the external sharing capability for the SharePoint Online tenant.
.DESCRIPTION
    Controls whether users can share with external users / anonymous guests.
.PARAMETER AdminUrl
    SharePoint Admin Center URL.
.PARAMETER SharingCapability
    Disabled, ExistingExternalUserSharingOnly, ExternalUserSharingOnly, or ExternalUserAndGuestSharing.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-TenantSharingCapability.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -SharingCapability ExternalUserSharingOnly -Interactive -WhatIf
.NOTES
    Risk Level      : High
    Required Roles  : SharePoint Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUrl,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Disabled', 'ExistingExternalUserSharingOnly', 'ExternalUserSharingOnly', 'ExternalUserAndGuestSharing')]
    [string]$SharingCapability,
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
    $current = (Get-PnPTenant -Connection $conn).SharingCapability
    Write-Host "Current SharingCapability: $current" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Tenant", "Set SharingCapability to $SharingCapability")) {
        Set-PnPTenant -SharingCapability $SharingCapability -Connection $conn
        $new = (Get-PnPTenant -Connection $conn).SharingCapability
        Write-Host "New SharingCapability: $new" -ForegroundColor Green
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
