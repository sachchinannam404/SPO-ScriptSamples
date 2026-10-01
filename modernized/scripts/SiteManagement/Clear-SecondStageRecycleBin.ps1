#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Permanently empties the second-stage (site collection) recycle bin.
.DESCRIPTION
    WARNING: Items deleted from the second-stage recycle bin cannot be recovered.
    Always run with -WhatIf first.
.PARAMETER SiteUrl
    Site collection URL whose second-stage recycle bin should be emptied.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Clear-SecondStageRecycleBin.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Interactive -WhatIf
.NOTES
    Risk Level      : Destructive
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
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
    $items = Get-PnPRecycleBinItem -SecondStageOnly -Connection $conn -ErrorAction SilentlyContinue
    $count = if ($items) { @($items).Count } else { 0 }
    Write-Host "Second-stage recycle bin contains $count item(s)." -ForegroundColor Cyan
    if ($count -eq 0) {
        Write-Host "Nothing to delete." -ForegroundColor Green
        return
    }
    if ($PSCmdlet.ShouldProcess("$SiteUrl ($count items)", "Permanently delete all second-stage recycle bin items")) {
        Clear-PnPRecycleBinItem -SecondStageOnly -Force -Connection $conn
        Write-Host "Second-stage recycle bin emptied." -ForegroundColor Green
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
