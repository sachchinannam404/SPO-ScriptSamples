#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Short description of what the script does.

.DESCRIPTION
    Longer description. Mention any data-loss risk, required permissions, and scope (single site / site collection / tenant).

.PARAMETER SiteUrl
    The full URL of the SharePoint site (or admin center URL when working at tenant level).

.PARAMETER ClientId
    Azure AD App Registration (Client) ID for app-only authentication.

.PARAMETER TenantId
    Azure AD Tenant ID (GUID or *.onmicrosoft.com).

.PARAMETER CertificatePath
    Full path to the .pfx certificate used for app-only auth.

.PARAMETER CertificatePassword
    Password for the certificate (SecureString). Prefer using -Thumbprint when possible.

.PARAMETER Interactive
    Use interactive / device-code login instead of app-only.

.PARAMETER WhatIf
    Shows what would happen without making changes (when SupportsShouldProcess is used).

.EXAMPLE
    PS> .\ScriptTemplate.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -Interactive

.EXAMPLE
    PS> .\ScriptTemplate.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" `
            -ClientId "00000000-0000-0000-0000-000000000000" `
            -TenantId "contoso.onmicrosoft.com" `
            -CertificatePath "C:\certs\spo.pfx"

.NOTES
    Author          : <Your Name>
    Risk Level      : Low / Medium / High / Destructive
    Required Roles  : Site Collection Administrator / SharePoint Administrator
    Last Updated    : 2026-10-02
    Compatible with : PnP.PowerShell 2.x+, PowerShell 5.1 / 7.x
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,

    [Parameter(Mandatory = $false)]
    [string]$ClientId,

    [Parameter(Mandatory = $false)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CertificatePath,

    [Parameter(Mandatory = $false)]
    [SecureString]$CertificatePassword,

    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

begin {
    $ErrorActionPreference = 'Stop'

    function Connect-SPO {
        if ($Interactive) {
            Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection
        }
        elseif ($ClientId -and $TenantId -and $CertificatePath) {
            $params = @{
                Url            = $SiteUrl
                ClientId       = $ClientId
                Tenant         = $TenantId
                CertificatePath = $CertificatePath
                ReturnConnection = $true
            }
            if ($CertificatePassword) {
                $params['CertificatePassword'] = $CertificatePassword
            }
            Connect-PnPOnline @params
        }
        else {
            throw "Specify either -Interactive or the combination of -ClientId, -TenantId and -CertificatePath."
        }
    }
}

process {
    $connection = $null
    try {
        $connection = Connect-SPO
        Write-Verbose "Connected to $SiteUrl"

        # ---------------------------------------------------------------
        # MAIN LOGIC GOES HERE
        # Use $PSCmdlet.ShouldProcess() for any change that modifies data
        # ---------------------------------------------------------------

    }
    catch {
        Write-Error "Script failed: $_"
        throw
    }
    finally {
        if ($null -ne $connection) {
            Disconnect-PnPOnline -Connection $connection -ErrorAction SilentlyContinue
        }
        else {
            Disconnect-PnPOnline -ErrorAction SilentlyContinue
        }
    }
}

end {
    Write-Verbose "Script completed."
}
