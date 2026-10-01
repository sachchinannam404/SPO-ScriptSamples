#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Prevents (or allows) external users from re-sharing content they were given access to.
.DESCRIPTION
    When enabled, external users cannot share further.
.PARAMETER AdminUrl
    SharePoint Admin Center URL.
.PARAMETER PreventResharing
    $true = prevent external users from resharing; $false = allow it.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-PreventExternalReshare.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -PreventResharing $true -Interactive -WhatIf
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
    [bool]$PreventResharing,
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
    $current = (Get-PnPTenant -Connection $conn).PreventExternalUsersFromResharing
    Write-Host "Current PreventExternalUsersFromResharing: $current" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Tenant", "Set PreventExternalUsersFromResharing = $PreventResharing")) {
        Set-PnPTenant -PreventExternalUsersFromResharing:$PreventResharing -Connection $conn
        $new = (Get-PnPTenant -Connection $conn).PreventExternalUsersFromResharing
        Write-Host "New value: $new" -ForegroundColor Green
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
