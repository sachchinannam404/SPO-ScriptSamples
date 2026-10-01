#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Bulk-updates a single field on all items in a list (including large lists).
.DESCRIPTION
    WARNING: Modifies every item. Always run with -WhatIf first. Uses paged processing.
.PARAMETER SiteUrl
    Site URL.
.PARAMETER ListTitle
    Target list title.
.PARAMETER FieldInternalName
    Internal name of the field to update.
.PARAMETER Value
    New value to set.
.PARAMETER BatchSize
    Items per page (default 200).
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Update-ListItemsBulk.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListTitle "Tasks" -FieldInternalName "Status" -Value "Completed" -Interactive -WhatIf
.NOTES
    Risk Level      : High
    Required Roles  : Site Collection Administrator or List Editor
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
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FieldInternalName,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Value,
    [Parameter(Mandatory = $false)]
    [ValidateRange(50, 1000)]
    [int]$BatchSize = 200,
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
    Write-Host "List '$ListTitle' has $($list.ItemCount) items." -ForegroundColor Cyan
    if (-not $PSCmdlet.ShouldProcess("$ListTitle ($($list.ItemCount) items)", "Set field '$FieldInternalName' to '$Value' on ALL items")) {
        return
    }
    $updated = 0
    Get-PnPListItem -List $ListTitle -PageSize $BatchSize -Fields "ID",$FieldInternalName -Connection $conn | ForEach-Object {
        $item = $_
        if ($PSCmdlet.ShouldProcess("Item ID $($item.Id)", "Update $FieldInternalName")) {
            Set-PnPListItem -List $ListTitle -Identity $item.Id -Values @{ $FieldInternalName = $Value } -Connection $conn | Out-Null
            $updated++
        }
    }
    Write-Host "Updated $updated items." -ForegroundColor Green
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
