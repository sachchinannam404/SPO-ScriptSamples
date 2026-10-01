#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Sets the expiration period (in days) for anonymous sharing links at tenant level.
.DESCRIPTION
    When set to a positive number, anonymous links expire after that many days. 0 = never expire.
.PARAMETER AdminUrl
    SharePoint Admin Center URL.
.PARAMETER Days
    Number of days after which anonymous links expire (0 = never).
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-AnonymousLinkExpiration.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -Days 30 -Interactive -WhatIf
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
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 730)]
    [int]$Days,
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
    $current = (Get-PnPTenant -Connection $conn).RequireAnonymousLinksExpireInDays
    Write-Host "Current anonymous link expiration: $current day(s)" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Tenant", "Set anonymous link expiration to $Days day(s)")) {
        Set-PnPTenant -RequireAnonymousLinksExpireInDays $Days -Connection $conn
        $new = (Get-PnPTenant -Connection $conn).RequireAnonymousLinksExpireInDays
        Write-Host "New anonymous link expiration: $new day(s)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
