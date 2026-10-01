#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Reports SharePoint 2010/2013 workflow associations on lists and sites.
.DESCRIPTION
    Classic workflows are deprecated. This report helps inventory remaining associations before migration to Power Automate.
.PARAMETER SiteUrl
    Site URL to scan.
.PARAMETER Recurse
    Also scan all subsites.
.PARAMETER OutputPath
    Optional CSV path.
.PARAMETER Interactive
    Use interactive login.
.EXAMPLE
    PS> .\Get-WorkflowReport.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Recurse -Interactive
.NOTES
    Risk Level      : Low (read-only)
    Required Roles  : Site Collection Administrator
    Last Updated    : 2026-10-02
    Note            : Classic workflows are deprecated; prefer Power Automate.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\WorkflowReport.csv",
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
    throw "Specify -Interactive or app-only parameters."
}

function Get-WorkflowsOnWeb {
    param([string]$Url)
    $conn = $null
    $rows = @()
    try {
        $conn = Connect-Target -Url $Url
        $siteWfs = Get-PnPProperty -ClientObject (Get-PnPWeb -Connection $conn) -Property WorkflowAssociations -Connection $conn -ErrorAction SilentlyContinue
        foreach ($wf in $siteWfs) {
            $rows += [PSCustomObject]@{ WebUrl = $Url; Scope = 'Site'; ListTitle = ''; WorkflowName = $wf.Name; Enabled = $wf.Enabled }
        }
        $lists = Get-PnPList -Connection $conn | Where-Object { -not $_.Hidden }
        foreach ($list in $lists) {
            $listWfs = Get-PnPProperty -ClientObject $list -Property WorkflowAssociations -Connection $conn -ErrorAction SilentlyContinue
            foreach ($wf in $listWfs) {
                $rows += [PSCustomObject]@{ WebUrl = $Url; Scope = 'List'; ListTitle = $list.Title; WorkflowName = $wf.Name; Enabled = $wf.Enabled }
            }
        }
        if ($Recurse) {
            $subs = Get-PnPSubWeb -Connection $conn -Recurse -ErrorAction SilentlyContinue
            foreach ($sub in $subs) { $rows += Get-WorkflowsOnWeb -Url $sub.Url }
        }
    }
    catch { Write-Warning "Failed on $Url : $_" }
    finally { if ($conn) { Disconnect-PnPOnline -Connection $conn -ErrorAction SilentlyContinue } }
    return $rows
}

$ErrorActionPreference = 'Stop'
try {
    $report = Get-WorkflowsOnWeb -Url $SiteUrl
    Write-Host "Found $($report.Count) workflow association(s)." -ForegroundColor Cyan
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
