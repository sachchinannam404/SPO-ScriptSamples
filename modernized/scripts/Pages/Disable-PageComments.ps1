#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Disables (or re-enables) comments on modern SharePoint pages in a site.
.DESCRIPTION
    Iterates modern pages in Site Pages and sets the comment setting.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER Disable
    When specified, comments are turned off.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Disable-PageComments.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Disable -Interactive
.NOTES
    Risk Level      : Low
    Required Roles  : Site Collection Administrator or Site owner
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
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
    $pages = Get-PnPListItem -List "Site Pages" -PageSize 100 -Connection $conn -ErrorAction Stop
    $action = if ($Disable) { "Disable comments" } else { "Enable comments" }
    $processed = 0
    foreach ($page in $pages) {
        $name = $page.FieldValues.FileLeafRef
        if ($PSCmdlet.ShouldProcess($name, $action)) {
            try {
                $clientPage = Get-PnPClientSidePage -Identity $name -Connection $conn -ErrorAction Stop
                $clientPage.CommentsDisabled = [bool]$Disable
                $clientPage.Save()
                $processed++
                Write-Host "  $action : $name" -ForegroundColor Green
            }
            catch {
                Write-Verbose "Skipped: $name – $_"
            }
        }
    }
    Write-Host "Processed $processed page(s)." -ForegroundColor Cyan
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
