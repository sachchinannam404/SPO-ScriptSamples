#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Breaks role inheritance on a single list (optionally copying existing role assignments).
.DESCRIPTION
    Makes the list stop inheriting permissions from its parent web.
.PARAMETER SiteUrl
    Site URL.
.PARAMETER ListTitle
    List or library title.
.PARAMETER CopyRoleAssignments
    When true (default), existing parent permissions are copied before breaking inheritance.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-UniquePermissionsOnList.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListTitle "Sensitive Docs" -Interactive
.NOTES
    Risk Level      : Medium
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ListTitle,
    [Parameter(Mandatory = $false)]
    [bool]$CopyRoleAssignments = $true,
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
        $conn = Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection
    }
    elseif ($ClientId -and $TenantId -and $CertificatePath) {
        $conn = Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $TenantId -CertificatePath $CertificatePath -ReturnConnection
    }
    else {
        throw "Specify -Interactive or app-only parameters."
    }
    $list = Get-PnPList -Identity $ListTitle -Connection $conn -Includes HasUniqueRoleAssignments
    if ($list.HasUniqueRoleAssignments) {
        Write-Host "List '$ListTitle' already has unique permissions." -ForegroundColor Yellow
        return
    }
    $msg = if ($CopyRoleAssignments) { "Break inheritance (copy existing roles)" } else { "Break inheritance (clear all roles)" }
    if ($PSCmdlet.ShouldProcess($ListTitle, $msg)) {
        Set-PnPList -Identity $ListTitle -BreakRoleInheritance -CopyRoleAssignments:$CopyRoleAssignments -Connection $conn
        Write-Host "Unique permissions set on '$ListTitle'." -ForegroundColor Green
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
