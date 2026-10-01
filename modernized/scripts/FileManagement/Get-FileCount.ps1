#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Counts files (and optionally folders) in a document library or specific folder, including subfolders.
.DESCRIPTION
    Recursively counts files using folder enumeration.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER LibraryTitle
    Title of the document library (default: Documents).
.PARAMETER FolderServerRelativeUrl
    Optional server-relative URL of a starting folder.
.PARAMETER IncludeFolders
    Also return folder count.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-FileCount.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Interactive
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
    [string]$LibraryTitle = "Documents",
    [Parameter(Mandatory = $false)]
    [string]$FolderServerRelativeUrl,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeFolders,
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
    $list = Get-PnPList -Identity $LibraryTitle -Connection $conn -Includes ItemCount, RootFolder
    $startFolder = if ($FolderServerRelativeUrl) {
        Get-PnPFolder -Url $FolderServerRelativeUrl -Connection $conn
    } else {
        $list.RootFolder
    }
    $fileCount = 0
    $folderCount = 0
    function Walk-Folder {
        param($Folder)
        $items = Get-PnPFolderItem -FolderSiteRelativeUrl $Folder.ServerRelativeUrl -Connection $conn
        foreach ($item in $items) {
            if ($item.GetType().Name -eq 'Folder') {
                $script:folderCount++
                Walk-Folder -Folder $item
            }
            else {
                $script:fileCount++
            }
        }
    }
    Write-Host "Counting in '$LibraryTitle'..." -ForegroundColor Cyan
    Walk-Folder -Folder $startFolder
    $result = [PSCustomObject]@{
        SiteUrl = $SiteUrl
        Library = $LibraryTitle
        StartFolder = $startFolder.ServerRelativeUrl
        FileCount = $fileCount
        FolderCount = if ($IncludeFolders) { $folderCount } else { $null }
        ListItemCount = $list.ItemCount
    }
    $result | Format-List
    return $result
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
