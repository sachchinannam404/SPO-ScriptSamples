#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Lists all site collections and their subsites in the tenant (or a single site collection).
.DESCRIPTION
    Produces a structured report of every web.
.PARAMETER AdminUrl
    SharePoint Admin Center URL when scanning the whole tenant.
.PARAMETER SiteUrl
    Single site collection URL when you only want that hierarchy.
.PARAMETER OutputPath
    Optional CSV path.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-AllSitesAndSubsites.ps1 -AdminUrl "https://contoso-admin.sharepoint.com" -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : SharePoint Administrator (tenant) or Site Collection Admin
    Last Updated    : 2026-10-02
#>

[CmdletBinding(DefaultParameterSetName = 'Tenant')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Tenant')]
    [string]$AdminUrl,
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\SitesAndSubsites.csv",
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

function Get-WebHierarchy {
    param([string]$Url, [string]$SiteCollectionUrl)
    $conn = $null
    $rows = @()
    try {
        $conn = Connect-Target -Url $Url
        $web = Get-PnPWeb -Connection $conn -Includes WebTemplate, Created, LastItemModifiedDate
        $rows += [PSCustomObject]@{ SiteCollectionUrl = $SiteCollectionUrl; WebUrl = $web.Url; Title = $web.Title; WebTemplate = $web.WebTemplate; Created = $web.Created; LastModified = $web.LastItemModifiedDate }
        $subs = Get-PnPSubWeb -Connection $conn -Recurse -ErrorAction SilentlyContinue
        foreach ($sub in $subs) {
            $rows += [PSCustomObject]@{ SiteCollectionUrl = $SiteCollectionUrl; WebUrl = $sub.Url; Title = $sub.Title; WebTemplate = $sub.WebTemplate; Created = $sub.Created; LastModified = $sub.LastItemModifiedDate }
        }
    }
    catch { Write-Warning "Failed on $Url : $_" }
    finally { if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue } }
    return $rows
}

$ErrorActionPreference = 'Stop'
$all = @()
try {
    if ($PSCmdlet.ParameterSetName -eq 'Tenant') {
        $adminConn = $null
        try {
            $adminConn = Connect-Target -Url $AdminUrl
            $sites = Get-PnPTenantSite -Connection $adminConn
            Write-Host "Found $($sites.Count) site collections." -ForegroundColor Cyan
            foreach ($site in $sites) {
                Write-Host "Scanning: $($site.Url)" -ForegroundColor Cyan
                $all += Get-WebHierarchy -Url $site.Url -SiteCollectionUrl $site.Url
            }
        }
        catch { Write-Error "Failed to enumerate tenant sites: $_"; throw }
        finally { if ($adminConn) { Disconnect-PnPOnline -Connection $adminConn -ErrorAction SilentlyContinue } }
    }
    else {
        $all += Get-WebHierarchy -Url $SiteUrl -SiteCollectionUrl $SiteUrl
    }
    if ($all.Count -gt 0) {
        $all | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported $($all.Count) web(s) to $OutputPath" -ForegroundColor Green
    }
    else { Write-Host "No webs found." -ForegroundColor Yellow }
    return $all
}
catch {
    Write-Error "Script failed: $_"
    throw
}
