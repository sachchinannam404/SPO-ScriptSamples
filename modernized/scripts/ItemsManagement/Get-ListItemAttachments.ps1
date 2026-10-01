#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Lists all attachments for items in a SharePoint list and optionally exports to CSV.
.DESCRIPTION
    Useful for inventory, migration, or cleanup planning.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER ListTitle
    List title (must support attachments).
.PARAMETER OutputPath
    Optional CSV path.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-ListItemAttachments.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListTitle "Tasks" -Interactive
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
    [string]$ListTitle,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\ListAttachments.csv",
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
    $items = Get-PnPListItem -List $ListTitle -PageSize 500 -Fields "ID","Title","Attachments" -Connection $conn |
        Where-Object { $_.FieldValues.Attachments -eq $true }
    $report = [System.Collections.Generic.List[PSObject]]::new()
    foreach ($item in $items) {
        $attachments = Get-PnPProperty -ClientObject $item -Property AttachmentFiles -Connection $conn
        foreach ($att in $attachments) {
            $report.Add([PSCustomObject]@{
                ItemId = $item.Id
                ItemTitle = $item.FieldValues.Title
                FileName = $att.FileName
                ServerRelativeUrl = $att.ServerRelativeUrl
            })
        }
    }
    Write-Host "Found $($report.Count) attachment(s) across $($items.Count) item(s)." -ForegroundColor Cyan
    if ($report.Count -gt 0) {
        $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported to $OutputPath" -ForegroundColor Green
    }
    return $report
}
catch {
    Write-Error "Script failed: $_"
    throw
}
finally {
    if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue }
}
