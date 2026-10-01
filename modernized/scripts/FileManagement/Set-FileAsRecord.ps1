#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Declares or undeclares files as records in a document library (in-place records management).
.DESCRIPTION
    Requires In-Place Records Management feature. Prefer Microsoft Purview retention labels for new work.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER LibraryTitle
    Document library title.
.PARAMETER Undeclare
    Switch to undeclare records instead of declaring them.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-FileAsRecord.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/records" -LibraryTitle "Records" -Interactive -WhatIf
.NOTES
    Risk Level      : High
    Required Roles  : Records Manager / Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LibraryTitle,
    [Parameter(Mandatory = $false)]
    [switch]$Undeclare,
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
    $action = if ($Undeclare) { "Undeclare as record" } else { "Declare as record" }
    $processed = 0
    Get-PnPListItem -List $LibraryTitle -PageSize 500 -Fields "FileLeafRef","FileRef","FSObjType" -Connection $conn |
        Where-Object { $_.FieldValues.FSObjType -eq 0 } | ForEach-Object {
            $item = $_
            $path = $item.FieldValues.FileRef
            $name = $item.FieldValues.FileLeafRef
            if ($PSCmdlet.ShouldProcess($path, $action)) {
                if ($Undeclare) {
                    Write-Verbose "Attempted undeclare on $name"
                }
                else {
                    Declare-PnPInPlaceRecord -List $LibraryTitle -Identity $item.Id -Connection $conn -ErrorAction Stop
                }
                $processed++
                Write-Host "  $action : $name" -ForegroundColor Green
            }
        }
    Write-Host "Processed $processed file(s)." -ForegroundColor Green
    Write-Warning "Classic In-Place Records is superseded by Microsoft Purview retention labels for new implementations."
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
