#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Resets unique permissions (restores inheritance) on all items in a list, including large lists.
.DESCRIPTION
    WARNING: Permanently removes item-level unique permissions. Processes items in pages.
.PARAMETER SiteUrl
    Site that contains the list.
.PARAMETER ListTitle
    Title of the target list/library.
.PARAMETER BatchSize
    Number of items per page (default 500).
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Reset-ListItemInheritance.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListTitle "Documents" -Interactive -WhatIf
.NOTES
    Risk Level      : High
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ListTitle,
    [Parameter(Mandatory = $false)]
    [ValidateRange(50, 2000)]
    [int]$BatchSize = 500,
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
    $list = Get-PnPList -Identity $ListTitle -Connection $conn -Includes ItemCount
    Write-Host "List '$ListTitle' contains $($list.ItemCount) items." -ForegroundColor Cyan
    if (-not $PSCmdlet.ShouldProcess("$ListTitle ($($list.ItemCount) items)", "Reset unique permissions on all items")) {
        return
    }
    $processed = 0
    $hasUnique = 0
    Get-PnPListItem -List $ListTitle -PageSize $BatchSize -Fields "ID","HasUniqueRoleAssignments" -Connection $conn | ForEach-Object {
        $item = $_
        if ($item.HasUniqueRoleAssignments) {
            $hasUnique++
            if ($PSCmdlet.ShouldProcess("Item ID $($item.Id)", "Reset role inheritance")) {
                Set-PnPListItemPermission -List $ListTitle -Identity $item.Id -InheritPermissions -Connection $conn
            }
        }
        $processed++
    }
    Write-Host "Processed $processed items. Reset unique permissions on $hasUnique items." -ForegroundColor Green
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
