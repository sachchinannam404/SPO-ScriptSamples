# Security Policy

## Supported Versions

Only scripts that follow the current coding standard (modern authentication, no hardcoded secrets) are considered supported.

| Version / Status      | Supported |
|-----------------------|-----------|
| Modernized (PnP + app-only / interactive) | Yes |
| Legacy CSOM + password auth               | No  |
| On-premises-only scripts                  | No  |

## Reporting a Vulnerability

If you discover a security issue (e.g. a script that still contains credentials, uses insecure auth, or can be abused for privilege escalation):

1. **Do not** open a public GitHub issue.
2. Contact the repository maintainers privately (open a security advisory on GitHub if available, or reach out via the contact method listed in the root README).
3. Include:
   - Script path
   - Description of the issue
   - Potential impact
   - Suggested fix (if any)

We will acknowledge the report within 5 business days and aim to publish a fix or mitigation quickly.

## Security Guidance for Users

- **Never** run these scripts with an account that has more privileges than necessary.
- Prefer **app-only authentication** with a certificate and least-privilege Azure AD permissions.
- Always test in a non-production tenant first.
- Treat any script marked **High** or **Destructive** with extreme caution (version limits, permission resets, bulk updates, recycle-bin operations, etc.).
- Rotate any credentials that may have been exposed by older versions of the scripts.

## Known Historical Issues

Older scripts in this repository (originating from Technet Gallery 2013-2019) commonly contained:

- Hardcoded example usernames / tenants
- `SharePointOnlineCredentials` (password auth)
- Basic authentication for Exchange Online
- Hardcoded local paths to SharePoint Client components

These patterns are being systematically removed. If you find any remaining instance, please report it.
