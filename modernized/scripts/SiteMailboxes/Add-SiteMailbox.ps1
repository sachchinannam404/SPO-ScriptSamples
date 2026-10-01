#Requires -Version 5.1
#Requires -Modules PnP.PowerShell, ExchangeOnlineManagement

<#
.SYNOPSIS
    Enables the Site Mailbox feature on a SharePoint site and creates the associated mailbox.
.DESCRIPTION
    Classic Site Mailboxes are deprecated in favor of Microsoft 365 Groups. Prefer Groups when possible.
.PARAMETER SiteUrl
    Full URL of the SharePoint site.
.PARAMETER DisplayName
    Display name for the mailbox. Defaults to the site title.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Add-SiteMailbox.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/project" -Interactive
.NOTES
    Risk Level      : Medium
    Required Roles  : SharePoint Admin + Exchange Admin
    Last Updated    : 2026-10-02
    Deprecation     : Classic Site Mailboxes are deprecated. Prefer M365 Groups.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [string]$DisplayName,
    [Parameter(Mandatory = $false)]
    [string]$ClientId,
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    [Parameter(Mandatory = $false)]
    [string]$CertificatePath,
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

$spoConn = $null
$ErrorActionPreference = 'Stop'
try {
    if ($Interactive) {
        $spoConn = Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection
    }
    elseif ($ClientId -and $TenantId -and $CertificatePath) {
        $spoConn = Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $TenantId -CertificatePath $CertificatePath -ReturnConnection
    }
    else {
        throw "Specify -Interactive or app-only parameters."
    }
    $web = Get-PnPWeb -Connection $spoConn
    if (-not $DisplayName) { $DisplayName = $web.Title }
    $featureId = [Guid]"502a2d54-6102-4757-aaa0-a90586106368"
    if ($PSCmdlet.ShouldProcess($SiteUrl, "Enable Site Mailbox feature and create mailbox '$DisplayName'")) {
        Enable-PnPFeature -Identity $featureId -Scope Web -Connection $spoConn -ErrorAction SilentlyContinue
        Write-Host "Site Mailbox feature enabled on $($web.Url)" -ForegroundColor Green
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false
        try {
            New-SiteMailbox -DisplayName $DisplayName -SharePointUrl $web.Url -ErrorAction Stop
            Write-Host "Site mailbox created: $DisplayName" -ForegroundColor Green
        }
        catch {
            if ($_.Exception.Message -match "already exists") { Write-Warning "Mailbox already exists for this site." }
            else { throw }
        }
        finally {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($spoConn) { Disconnect-PnPOnline -Connection $spoConn -ErrorAction SilentlyContinue }
}
