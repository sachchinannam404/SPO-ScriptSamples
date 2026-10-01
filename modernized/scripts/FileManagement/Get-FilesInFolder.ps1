#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Lists files (and optionally subfolders) under a given folder in a SharePoint library.
.DESCRIPTION
    Returns structured objects for pipeline or Export-Csv. Supports recursive listing.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER FolderServerRelativeUrl
    Server-relative URL of the folder.
.PARAMETER Recurse
    Include files from all subfolders.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-FilesInFolder.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -FolderServerRelativeUrl "/sites/demo/Shared Documents" -Recurse -Interactive
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
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FolderServerRelativeUrl,
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
    $results = [System.Collections.Generic.List[PSObject]]::new()
    function Collect-Items {
        param([string]$FolderUrl)
        $items = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderUrl -Connection $conn
        foreach ($item in $items) {
            $isFolder = $item.GetType().Name -eq 'Folder'
            $results.Add([PSCustomObject]@{
                Name = $item.Name
                ServerRelativeUrl = $item.ServerRelativeUrl
                ItemType = if ($isFolder) { 'Folder' } else { 'File' }
                Length = if (-not $isFolder) { $item.Length } else { $null }
                TimeLastModified = $item.TimeLastModified
            })
            if ($isFolder -and $Recurse) {
                Collect-Items -FolderUrl $item.ServerRelativeUrl
            }
        }
    }
    Collect-Items -FolderUrl $FolderServerRelativeUrl
    Write-Host "Found $($results.Count) items." -ForegroundColor Green
    return $results
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
