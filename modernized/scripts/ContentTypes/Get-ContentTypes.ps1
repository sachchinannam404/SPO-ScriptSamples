#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Lists content types available on a site or on a specific list.
.DESCRIPTION
    Returns name, ID, group, hidden flag, and related properties.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER ListTitle
    Optional. When supplied, returns content types added to that list only.
.PARAMETER IncludeHidden
    Include hidden content types (default: false).
.PARAMETER OutputPath
    Optional CSV path.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-ContentTypes.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Interactive
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
    [Parameter(Mandatory = $false)]
    [string]$ListTitle,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeHidden,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
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
    if ($ListTitle) {
        $cts = Get-PnPContentType -List $ListTitle -Connection $conn
    }
    else {
        $cts = Get-PnPContentType -Connection $conn
    }
    if (-not $IncludeHidden) {
        $cts = $cts | Where-Object { -not $_.Hidden }
    }
    $report = foreach ($ct in $cts) {
        [PSCustomObject]@{
            Name = $ct.Name
            Id = $ct.StringId
            Group = $ct.Group
            Hidden = $ct.Hidden
            ReadOnly = $ct.ReadOnly
            Sealed = $ct.Sealed
        }
    }
    $report | Format-Table -AutoSize
    if ($OutputPath) {
        $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported $($report.Count) content type(s) to $OutputPath" -ForegroundColor Green
    }
    return $report
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
