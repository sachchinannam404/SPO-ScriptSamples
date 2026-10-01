#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Lists web parts / client-side controls on a given page.
.DESCRIPTION
    For modern pages lists client-side controls.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER PageName
    File name of the page (e.g. Home.aspx).
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-WebPartsOnPage.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -PageName "Home.aspx" -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : Site Member or higher
    Last Updated    : 2026-10-02
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PageName,
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
    try {
        $page = Get-PnPPage -Identity $PageName -Connection $conn -ErrorAction Stop
        $controls = $page.Controls
        $report = foreach ($c in $controls) {
            [PSCustomObject]@{
                Page = $PageName
                Type = 'Modern'
                Title = $c.Title
                InstanceId = $c.InstanceId
                WebPartType = $c.Type
            }
        }
        $report | Format-Table -AutoSize
        return $report
    }
    catch {
        Write-Verbose "Not a modern page or Get-PnPPage failed: $_"
        Write-Host "Classic web-part enumeration is limited in modern PnP." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
