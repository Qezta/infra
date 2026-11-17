# Company projection

`projection.json` is generated in the private
[Qezta/company](https://github.com/Qezta/company) repository
(`exports/public/projection.json`) by
[company-framework](https://github.com/Qezta/company-framework). It is the
public-safe part of the company spec: roles, GitHub teams and permissions,
members' GitHub logins, and systems with their CODEOWNERS rules. It never
contains names or email addresses; a closed JSON Schema enforces that
upstream.

Do not edit it here. Change `qezta.nix` in Qezta/company, regenerate, and
copy the file over (the sync will be automated).

| Field | Value |
| --- | --- |
| Source | `Qezta/company@1e6d1f66565c368a3cf76b1d8dbeb32146faed05` |
| Synced | 2026-11-17 |
