---
status: accepted
date: 2026-11-17
---

# Keep GitHub teams flat

## Context and Problem Statement

Company roles form a tree (`founder` above `engineering`, `security`, ...).
Should GitHub teams mirror it with parent teams?

## Decision Outcome

Chosen option: "flat teams", because in GitHub a child team inherits its
parent team's repository access. Nesting `engineering` under `founders`
would give engineering the founders' `admin` rights, the opposite of the
role tree's intent. Each team gets only the permission of its own role,
raised to `push` where it owns paths in CODEOWNERS (GitHub ignores code
owners without write access).
