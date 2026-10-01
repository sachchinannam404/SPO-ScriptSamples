#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Enables or disables attachments on a list (or on all lists in a site).
.DESCRIPTION
    When disabled, users can no longer add new attachments; existing ones remain until removed.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER ListTitle
    Specific list title. Omit to process all non-hidden generic lists.
.PARAMETER Enabled
    $true to enable attachments, $false to disable.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Set-ListAttachmentsEnabled.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListTitle "Tasks" -Enabled $false -Interactive
.NOTES
    Risk Level      : Low
    Required Roles  : Site Collection Administrator or List owner
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [string]$ListTitle,
    [Parameter(Mandatory = $true)]
    [bool]$Enabled,
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
    $lists = if ($ListTitle) {
        @(Get-PnPList -Identity $ListTitle -Connection $conn)
    }
    else {
        Get-PnPList -Connection $conn | Where-Object { -not $_.Hidden -and $_.BaseType -eq 'GenericList' }
    }
    foreach ($list in $lists) {
        if ($PSCmdlet.ShouldProcess($list.Title, "Set EnableAttachments = $Enabled")) {
            Set-PnPList -Identity $list -EnableAttachments:$Enabled -Connection $conn
            Write-Host "Updated: $($list.Title)" -ForegroundColor Green
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
