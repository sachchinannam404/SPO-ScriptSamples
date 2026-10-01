#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Retrieves OneDrive for Business URLs for users in the tenant.
.DESCRIPTION
    Uses the SharePoint Admin Center to enumerate personal sites and returns a report.
.PARAMETER AdminUrl
    SharePoint Admin Center URL (https://contoso-admin.sharepoint.com).
.PARAMETER OutputPath
    CSV path for the report.
.PARAMETER OnlyProvisioned
    Return only users who already have a OneDrive site.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-OneDriveUrls.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : SharePoint Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUrl,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\OneDriveUrls.csv",
    [Parameter(Mandatory = $false)]
    [switch]$OnlyProvisioned,
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
    Write-Host "Retrieving OneDrive sites..." -ForegroundColor Cyan
    $sites = Get-PnPTenantSite -IncludeOneDriveSites -Connection $conn | Where-Object { $_.Template -like "SPSPERS*" }
    if ($OnlyProvisioned) {
        $sites = $sites | Where-Object { $_.Status -eq "Active" }
    }
    $report = foreach ($site in $sites) {
        [PSCustomObject]@{
            Url = $site.Url
            Owner = $site.Owner
            Title = $site.Title
            StorageUsageMB = $site.StorageUsageCurrent
            Status = $site.Status
            LastContentModifiedDate = $site.LastContentModifiedDate
        }
    }
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported $($report.Count) OneDrive site(s) to $OutputPath" -ForegroundColor Green
    return $report
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
