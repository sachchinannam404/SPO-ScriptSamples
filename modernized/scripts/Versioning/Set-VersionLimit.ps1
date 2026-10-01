#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Sets the major version limit on all lists and libraries in a site (and optionally subsites).
.DESCRIPTION
    WARNING: Lowering the major version limit can permanently delete older versions. Use -WhatIf first.
.PARAMETER SiteUrl
    Full URL of the SharePoint site to process.
.PARAMETER VersionLimit
    Maximum number of major versions to keep (1-50000).
.PARAMETER Recurse
    Also process all subsites.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-VersionLimit.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -VersionLimit 100 -Interactive -WhatIf
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
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 50000)]
    [int]$VersionLimit,
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
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
    throw "Specify -Interactive or -ClientId/-TenantId/-CertificatePath."
}

function Set-VersionLimitOnWeb {
    param([string]$WebUrl, [int]$Limit)
    $conn = $null
    try {
        $conn = Connect-Target -Url $WebUrl
        $lists = Get-PnPList -Connection $conn -Includes EnableVersioning, MajorVersionLimit |
            Where-Object { $_.BaseType -in @('GenericList', 'DocumentLibrary') -and -not $_.Hidden }
        foreach ($list in $lists) {
            $target = "$($list.Title) ($WebUrl)"
            try {
                if ($PSCmdlet.ShouldProcess($target, "Set MajorVersionLimit to $Limit")) {
                    Set-PnPList -Identity $list -MajorVersions $Limit -Connection $conn
                    Write-Host "Updated: $target" -ForegroundColor Green
                }
            }
            catch { Write-Warning "Failed on list '$($list.Title)' at $WebUrl : $_" }
        }
        if ($Recurse) {
            $subs = Get-PnPSubWeb -Connection $conn -Recurse -ErrorAction SilentlyContinue
            foreach ($sub in $subs) { Set-VersionLimitOnWeb -WebUrl $sub.Url -Limit $Limit }
        }
    }
    catch { Write-Warning "Failed on web $WebUrl : $_" }
    finally { if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue } }
}

$ErrorActionPreference = 'Stop'
try {
    Write-Warning "Lowering version limits can permanently delete older versions. Use -WhatIf to preview."
    Set-VersionLimitOnWeb -WebUrl $SiteUrl -Limit $VersionLimit
}
catch {
    Write-Error "Script failed: $_"
    throw
}
