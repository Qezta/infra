---
status: accepted
date: 2026-11-17
---

# Generate GitHub teams and access from the company projection

## Context and Problem Statement

Roles and who holds them are defined in the private Qezta/company repository.
This repository is public. How does it learn who should be on which team
without exposing personal data?

## Considered Options

- (a) Commit a public-safe projection (`data/company/projection.json`) exported by Qezta/company
- (b) Make this repository private and import Qezta/company directly

## Decision Outcome

Chosen option: "(a)", because it keeps this repository public and the
projection contains only what GitHub already exposes: team names, GitHub
logins and repository names. company-framework's closed schema for the
projection rejects personal fields, and a mutation test proves it.

### Consequences

- Good, because every team, membership and repository grant is reviewable here.
- Bad, because the projection must be synced; until that is automated it is copied by hand with its source commit recorded in `data/company/README.md`.
