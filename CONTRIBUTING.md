# Contributing to SPO-ScriptSamples

Thank you for helping modernize and improve these SharePoint Online scripts.

## Code of Conduct

- Be respectful and constructive.
- Never commit credentials, certificates, or real tenant data.
- Prefer fixing root causes over work-arounds.

## Development Standards (Mandatory)

Every new or updated script **must** follow these rules:

### 1. Authentication
- **No password-based auth.**  
  Forbidden: `SharePointOnlineCredentials`, `Read-Host` for passwords, Basic auth.
- Supported methods only:
  - `-Interactive` / device code
  - App-only with certificate (`-ClientId` + `-TenantId` + `-CertificatePath` / Thumbprint)
  - Managed Identity (when running in Azure)
- Always disconnect in a `finally` block.

### 2. Structure
- Use the official template: [`templates/ScriptTemplate.ps1`](templates/ScriptTemplate.ps1)
- Include full comment-based help (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`).
- Declare `#Requires -Modules PnP.PowerShell` (and version if needed).
- Use `[CmdletBinding(SupportsShouldProcess = $true)]` for any script that changes data.
- Prefer PnP.PowerShell cmdlets over raw CSOM.

### 3. Parameters & Output
- No hardcoded tenant names, URLs, usernames, or file paths.
- Validate parameters (`ValidateNotNullOrEmpty`, `ValidateScript`, `ValidateSet`, etc.).
- Prefer structured objects + `Export-Csv` / pipeline output. Use `Write-Host` only for progress.

### 4. Safety
- Destructive scripts must support `-WhatIf` / `-Confirm`.
- Clearly document risk level in the `.NOTES` section: `Low | Medium | High | Destructive`.
- Add warnings for data-loss operations (version limits, permission resets, bulk updates).

### 5. Style
- Consistent indentation (4 spaces).
- Meaningful variable names.
- Avoid global variables.
- Keep functions small and focused.

## Pull Request Checklist

Before submitting a PR, verify:

- [ ] Uses modern authentication only
- [ ] No hardcoded credentials, tenants, or personal paths
- [ ] Based on (or updated from) `templates/ScriptTemplate.ps1`
- [ ] Has complete comment-based help
- [ ] Uses `try / catch / finally` with `Disconnect-PnPOnline`
- [ ] Supports `-WhatIf` if the script modifies data
- [ ] Risk level documented
- [ ] Tested against a modern SharePoint Online tenant
- [ ] PSScriptAnalyzer shows no high-severity issues (when CI is enabled)

## Adding a New Script

1. Copy `templates/ScriptTemplate.ps1`.
2. Place it in the correct category folder under `scripts/` (or the existing category structure).
3. Update the category README and the root index if one exists.
4. Open a Pull Request with a clear description of purpose, risk, and test evidence.

## Updating an Existing Script

- Prefer in-place modernization over creating a parallel "v2" file.
- If the old script must be kept for historical reasons, move it to `archived/` and add a note pointing to the modern version.
- Update the script's `.NOTES` → `Last Updated` date.

## Questions?

Open an issue with the label `question` or `modernization`.
