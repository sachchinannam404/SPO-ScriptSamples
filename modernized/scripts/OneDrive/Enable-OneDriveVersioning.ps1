#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Enables versioning on document libraries inside OneDrive for Business sites.
.DESCRIPTION
    Can target all OneDrive sites or a list of specific URLs. Enabling versioning increases storage use.
.PARAMETER AdminUrl
    SharePoint Admin Center URL (required when targeting all OneDrives).
.PARAMETER OneDriveUrls
    Optional array of specific OneDrive URLs.
.PARAMETER EnableMinorVersions
    Also enable minor versions.
.PARAMETER MajorVersionLimit
    Optional major version limit.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Enable-OneDriveVersioning.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -Interactive -WhatIf
.NOTES
    Risk Level      : Medium (storage impact)
    Required Roles  : SharePoint Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false)]
    [string]$AdminUrl,
    [Parameter(Mandatory = $false)]
    [string[]]$OneDriveUrls,
    [Parameter(Mandatory = $false)]
    [switch]$EnableMinorVersions,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 50000)]
    [int]$MajorVersionLimit,
    [Parameter(Mandatory = $false)]
    [string]$ClientId,
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    [Parameter(Mandatory = $false)]
    [string]$CertificatePath,
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

function Connect-Target {
    param([string]$Url)
    if ($Interactive) { return Connect-PnPOnline -Url $Url -Interactive -ReturnConnection }
    if ($ClientId -and $TenantId -and $CertificatePath) {
        return Connect-PnPOnline -Url $Url -ClientId $ClientId -Tenant $TenantId -CertificatePath $CertificatePath -ReturnConnection
    }
    throw "Specify -Interactive or app-only parameters."
}

$ErrorActionPreference = 'Stop'
$success = 0
$failed = 0
try {
    if (-not $OneDriveUrls) {
        if (-not $AdminUrl) { throw "Provide either -OneDriveUrls or -AdminUrl." }
        $adminConn = $null
        try {
            $adminConn = Connect-Target -Url $AdminUrl
            $OneDriveUrls = (Get-PnPTenantSite -IncludeOneDriveSites -Connection $adminConn |
                Where-Object { $_.Template -like "SPSPERS*" -and $_.Status -eq "Active" }).Url
            Write-Host "Found $($OneDriveUrls.Count) OneDrive site(s)." -ForegroundColor Cyan
        }
        catch { Write-Error "Failed to enumerate OneDrive sites: $_"; throw }
        finally { if ($adminConn) { Disconnect-PnPOnline -Connection $adminConn -ErrorAction SilentlyContinue } }
    }
    foreach ($url in $OneDriveUrls) {
        $conn = $null
        try {
            if (-not $PSCmdlet.ShouldProcess($url, "Enable versioning on document libraries")) { continue }
            $conn = Connect-Target -Url $url
            $lists = Get-PnPList -Connection $conn | Where-Object { $_.BaseType -eq "DocumentLibrary" -and -not $_.Hidden }
            foreach ($list in $lists) {
                try {
                    $params = @{ Identity = $list; EnableVersioning = $true; Connection = $conn }
                    if ($EnableMinorVersions) { $params['EnableMinorVersions'] = $true }
                    if ($MajorVersionLimit) { $params['MajorVersions'] = $MajorVersionLimit }
                    Set-PnPList @params
                }
                catch { Write-Warning "Failed on list '$($list.Title)' at $url : $_" }
            }
            Write-Host "Updated: $url" -ForegroundColor Green
            $success++
        }
        catch { Write-Warning "Failed on $url : $_"; $failed++ }
        finally { if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue } }
    }
    Write-Host "Completed. Success: $success  Failed: $failed" -ForegroundColor Cyan
}
catch {
    Write-Error "Script failed: $_"
    throw
}
