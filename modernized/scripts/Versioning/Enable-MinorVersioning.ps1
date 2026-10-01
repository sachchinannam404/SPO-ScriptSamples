#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Enables major and minor versioning on all suitable lists and libraries in a site.
.DESCRIPTION
    Turns on versioning + minor versions and optionally sets the minor version limit.
.PARAMETER SiteUrl
    Target site URL.
.PARAMETER MinorVersionLimit
    Number of minor versions to keep (default 10).
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Enable-MinorVersioning.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Interactive
.NOTES
    Risk Level      : Low
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 500)]
    [int]$MinorVersionLimit = 10,
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
    $lists = Get-PnPList -Connection $conn | Where-Object { $_.BaseType -in @('GenericList', 'DocumentLibrary') -and -not $_.Hidden }
    foreach ($list in $lists) {
        if ($PSCmdlet.ShouldProcess($list.Title, "Enable minor versioning (limit $MinorVersionLimit)")) {
            Set-PnPList -Identity $list -EnableVersioning $true -EnableMinorVersions $true -MinorVersions $MinorVersionLimit -Connection $conn
            Write-Host "Enabled minor versioning on: $($list.Title)" -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
