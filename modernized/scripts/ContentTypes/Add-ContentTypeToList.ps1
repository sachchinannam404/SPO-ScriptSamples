#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Adds an existing site content type to a list or library.

.DESCRIPTION
    Enables content types on the list if needed, then adds the specified content type.

.PARAMETER SiteUrl
    SharePoint site URL.

.PARAMETER ListTitle
    Target list or library title.

.PARAMETER ContentTypeName
    Name (or ID) of the site content type to add.

.PARAMETER Interactive
    Use interactive login.

.EXAMPLE
    PS> .\Add-ContentTypeToList.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" `
            -ListTitle "Documents" -ContentTypeName "Project Document" -Interactive

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

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ListTitle,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ContentTypeName,

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
        $conn = Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $TenantId `
            -CertificatePath $CertificatePath -ReturnConnection
    }
    else {
        throw "Specify -Interactive or app-only parameters."
    }

    if ($PSCmdlet.ShouldProcess($ListTitle, "Add content type '$ContentTypeName'")) {
        Set-PnPList -Identity $ListTitle -EnableContentTypes $true -Connection $conn
        Add-PnPContentTypeToList -List $ListTitle -ContentType $ContentTypeName -Connection $conn
        Write-Host "Content type '$ContentTypeName' added to '$ListTitle'." -ForegroundColor Green
    }
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
