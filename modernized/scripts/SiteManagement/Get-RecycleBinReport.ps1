#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Reports items in the first- and/or second-stage recycle bin of a site.
.DESCRIPTION
    Read-only report useful before bulk restore or permanent deletion.
.PARAMETER SiteUrl
    Site collection URL.
.PARAMETER Stage
    FirstStage, SecondStage, or Both (default).
.PARAMETER OutputPath
    Optional CSV path.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-RecycleBinReport.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [ValidateSet('FirstStage', 'SecondStage', 'Both')]
    [string]$Stage = 'Both',
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\RecycleBinReport.csv",
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
    $items = @()
    if ($Stage -in @('FirstStage', 'Both')) {
        $items += Get-PnPRecycleBinItem -FirstStageOnly -Connection $conn -ErrorAction SilentlyContinue |
            Select-Object Id, Title, ItemType, DirName, DeletedByName, DeletedDate, Size, @{N='Stage';E={'First'}}
    }
    if ($Stage -in @('SecondStage', 'Both')) {
        $items += Get-PnPRecycleBinItem -SecondStageOnly -Connection $conn -ErrorAction SilentlyContinue |
            Select-Object Id, Title, ItemType, DirName, DeletedByName, DeletedDate, Size, @{N='Stage';E={'Second'}}
    }
    $items = @($items)
    Write-Host "Found $($items.Count) recycle-bin item(s)." -ForegroundColor Cyan
    if ($items.Count -gt 0 -and $OutputPath) {
        $items | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported to $OutputPath" -ForegroundColor Green
    }
    return $items
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
