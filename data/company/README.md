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
| Source | `Qezta/company@92c91f7e5d461a36cdd527fdf4a646f49febab9b` |
| Synced | 2026-11-19 |
