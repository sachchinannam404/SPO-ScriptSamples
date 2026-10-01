#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Deletes all attachments from all items in a list (or from a single item).
.DESCRIPTION
    WARNING: Permanently deletes attachment files. Always run with -WhatIf first.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER ListTitle
    List title.
.PARAMETER ItemId
    Optional. When supplied, only attachments of that item are removed.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Remove-ListItemAttachments.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListTitle "Tasks" -Interactive -WhatIf
.NOTES
    Risk Level      : Destructive
    Required Roles  : Site Collection Administrator or List owner
    Last Updated    : 2026-10-02
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ListTitle,
    [Parameter(Mandatory = $false)]
    [int]$ItemId,
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
    $items = if ($ItemId) {
        @(Get-PnPListItem -List $ListTitle -Id $ItemId -Connection $conn)
    }
    else {
        Get-PnPListItem -List $ListTitle -PageSize 500 -Fields "ID","Title","Attachments" -Connection $conn |
            Where-Object { $_.FieldValues.Attachments -eq $true }
    }
    $deleted = 0
    foreach ($item in $items) {
        $attachments = Get-PnPProperty -ClientObject $item -Property AttachmentFiles -Connection $conn
        foreach ($att in $attachments) {
            if ($PSCmdlet.ShouldProcess("$($att.FileName) (Item $($item.Id))", "Delete attachment")) {
                Remove-PnPListItemAttachment -List $ListTitle -Identity $item.Id -FileName $att.FileName -Connection $conn -Force -ErrorAction Stop
                $deleted++
                Write-Host "  Deleted: $($att.FileName)" -ForegroundColor Green
            }
        }
    }
    Write-Host "Deleted $deleted attachment(s)." -ForegroundColor Cyan
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
