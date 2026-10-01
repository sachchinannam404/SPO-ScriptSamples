#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Checks in (or discards check-out of) all checked-out files in a library.
.DESCRIPTION
    Useful after bulk uploads or when users leave files checked out. Supports -WhatIf.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER LibraryTitle
    Document library title.
.PARAMETER CheckInType
    MajorCheckIn (default), MinorCheckIn, or OverwriteCheckIn.
.PARAMETER Comment
    Optional check-in comment.
.PARAMETER DiscardCheckout
    Discard check-out instead of checking in.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-FileCheckIn.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -LibraryTitle "Documents" -Interactive -WhatIf
.NOTES
    Risk Level      : Medium
    Required Roles  : Site Collection Administrator or Library owner
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LibraryTitle,
    [Parameter(Mandatory = $false)]
    [ValidateSet('MajorCheckIn', 'MinorCheckIn', 'OverwriteCheckIn')]
    [string]$CheckInType = 'MajorCheckIn',
    [Parameter(Mandatory = $false)]
    [string]$Comment = "Checked in by administrator script",
    [Parameter(Mandatory = $false)]
    [switch]$DiscardCheckout,
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
    $items = Get-PnPListItem -List $LibraryTitle -PageSize 500 -Fields "FileLeafRef","FileRef","CheckoutUser" -Connection $conn |
        Where-Object { $null -ne $_.FieldValues.CheckoutUser }
    Write-Host "Found $($items.Count) checked-out file(s)." -ForegroundColor Cyan
    $action = if ($DiscardCheckout) { "Discard check-out" } else { "Check in ($CheckInType)" }
    $processed = 0
    foreach ($item in $items) {
        $name = $item.FieldValues.FileLeafRef
        $path = $item.FieldValues.FileRef
        if ($PSCmdlet.ShouldProcess($path, $action)) {
            if ($DiscardCheckout) {
                Undo-PnPFileCheckout -Url $path -Connection $conn
            }
            else {
                Set-PnPFileCheckedIn -Url $path -CheckInType $CheckInType -Comment $Comment -Connection $conn
            }
            $processed++
            Write-Host "  $action : $name" -ForegroundColor Green
        }
    }
    Write-Host "Processed $processed file(s)." -ForegroundColor Green
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
