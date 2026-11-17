______________________________________________________________________

## status: accepted date: 2026-11-17

# Deliver CODEOWNERS through pull requests, not github_repository_file

## Context and Problem Statement

CODEOWNERS files are generated in Qezta/company (`exports/codeowners/`).
How do they reach each repository?

## Considered Options

- `github_repository_file` resources in this repository
- A CI job in Qezta/company that opens a pull request in each repository when its file changes

## Decision Outcome

Chosen option: "CI sync through pull requests", because:

- the default-branch rulesets require pull requests; `github_repository_file`
  commits straight to the branch and would need a permanent bypass;
- a pull request is reviewable and visible in each repository's history,
  while a provider commit isn't;
- edits made in a repository show up as a diff in the next sync PR instead
  of being silently overwritten on the next apply.

### Consequences

- Bad, because it is another workflow to maintain (company-framework phase 5).
