# SPO-ScriptSamples (Modernized)

Cleaned, modernized, and security-hardened versions of scripts from the original SPO-ScriptSamples repository.

## Quick Start

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser

.\scripts\Versioning\Enable-MinorVersioning.ps1 `
    -SiteUrl "https://contoso.sharepoint.com/sites/demo" `
    -Interactive
```

## Layout

See scripts/ for categories: Permissions, Versioning, ListsAndLibraries, FileManagement, OneDrive, TenantSettings, SiteManagement, ContentTypes, ItemsManagement, Workflows, Pages, SiteMailboxes.

Every script uses modern auth, try/catch/finally, and risk labels.
