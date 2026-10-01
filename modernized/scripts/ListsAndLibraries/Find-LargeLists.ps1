#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Finds lists and libraries that exceed a given item-count threshold across a site or tenant.
.DESCRIPTION
    Produces a CSV report of large lists. Correct context handling (no disposed-context bugs).
.PARAMETER AdminUrl
    SharePoint Admin Center URL when scanning the tenant.
.PARAMETER SiteUrl
    Single site URL when scanning one site collection.
.PARAMETER ItemThreshold
    Minimum item count to report (default 5000).
.PARAMETER OutputPath
    Path for the CSV report.
.PARAMETER IncludeOneDrive
    Also include OneDrive sites (tenant scan only).
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Find-LargeLists.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/hr" -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : SharePoint Administrator (tenant) or Site Collection Admin
    Last Updated    : 2026-10-02
#>

[CmdletBinding(DefaultParameterSetName = 'SingleSite')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Tenant')]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUrl,
    [Parameter(Mandatory = $true, ParameterSetName = 'SingleSite')]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000000)]
    [int]$ItemThreshold = 5000,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\LargeListsReport.csv",
    [Parameter(Mandatory = $false, ParameterSetName = 'Tenant')]
    [switch]$IncludeOneDrive,
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

function Get-LargeListsFromSite {
    param([string]$Url, [int]$Threshold)
    $conn = $null
    $results = @()
    try {
        $conn = Connect-Target -Url $Url
        $lists = Get-PnPList -Connection $conn -Includes ItemCount, ParentWebUrl |
            Where-Object { -not $_.Hidden -and $_.ItemCount -gt $Threshold }
        foreach ($list in $lists) {
            $results += [PSCustomObject]@{ SiteUrl = $Url; ListTitle = $list.Title; ItemCount = $list.ItemCount; ParentWebUrl = $list.ParentWebUrl; BaseType = $list.BaseType }
            Write-Host "  Large: $($list.Title) ($($list.ItemCount) items)" -ForegroundColor Yellow
        }
        $subs = Get-PnPSubWeb -Connection $conn -Recurse -ErrorAction SilentlyContinue
        foreach ($sub in $subs) { $results += Get-LargeListsFromSite -Url $sub.Url -Threshold $Threshold }
    }
    catch { Write-Warning "Failed on $Url : $_" }
    finally { if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue } }
    return $results
}

$ErrorActionPreference = 'Stop'
$allResults = @()
try {
    if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
    if ($PSCmdlet.ParameterSetName -eq 'Tenant') {
        $adminConn = $null
        try {
            $adminConn = Connect-Target -Url $AdminUrl
            $sites = Get-PnPTenantSite -Connection $adminConn -IncludeOneDriveSites:$IncludeOneDrive
            Write-Host "Found $($sites.Count) site collections to scan." -ForegroundColor Cyan
            foreach ($site in $sites) {
                Write-Host "Scanning: $($site.Url)" -ForegroundColor Cyan
                $allResults += Get-LargeListsFromSite -Url $site.Url -Threshold $ItemThreshold
            }
        }
        catch { Write-Error "Failed to enumerate tenant sites: $_"; throw }
        finally { if ($adminConn) { Disconnect-PnPOnline -Connection $adminConn -ErrorAction SilentlyContinue } }
    }
    else {
        Write-Host "Scanning single site: $SiteUrl" -ForegroundColor Cyan
        $allResults += Get-LargeListsFromSite -Url $SiteUrl -Threshold $ItemThreshold
    }
    if ($allResults.Count -gt 0) {
        $allResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Report written to $OutputPath ($($allResults.Count) large lists found)." -ForegroundColor Green
    }
    else { Write-Host "No lists exceeded the threshold of $ItemThreshold items." -ForegroundColor Green }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
