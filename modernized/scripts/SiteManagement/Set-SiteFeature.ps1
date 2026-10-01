#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Activates or deactivates a SharePoint feature on a site (web or site-collection scoped).
.DESCRIPTION
    Uses the feature GUID (e.g. Publishing: 94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb).
.PARAMETER SiteUrl
    Target site URL.
.PARAMETER FeatureId
    GUID of the feature.
.PARAMETER Scope
    Web (default) or Site.
.PARAMETER Disable
    Deactivate instead of activate.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-SiteFeature.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -FeatureId "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" -Scope Site -Interactive
.NOTES
    Risk Level      : Medium
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [Guid]$FeatureId,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Web', 'Site')]
    [string]$Scope = 'Web',
    [Parameter(Mandatory = $false)]
    [switch]$Disable,
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
    $action = if ($Disable) { "Disable feature $FeatureId ($Scope)" } else { "Enable feature $FeatureId ($Scope)" }
    if ($PSCmdlet.ShouldProcess($SiteUrl, $action)) {
        if ($Disable) {
            Disable-PnPFeature -Identity $FeatureId -Scope $Scope -Force -Connection $conn
            Write-Host "Feature disabled." -ForegroundColor Green
        }
        else {
            Enable-PnPFeature -Identity $FeatureId -Scope $Scope -Force -Connection $conn
            Write-Host "Feature enabled." -ForegroundColor Green
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
