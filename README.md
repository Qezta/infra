<div id="top">
    <div align="center">
        <img alt='An abstract image of a donut-like object' title='Qezta' height=250 width=250 src='https://qezta.com/qezta.gif' />
        <h1 align='center'>infra</h1>
        <strong>Qezta's infrastructure as code: GitHub org, repositories, teams and DNS (OpenTofu, Terranix, Terragrunt)</strong>
    </div>

</div>

______________________________________________________________________

<div align='center'>
    <a href="https://github.com/Qezta/infra/stargazers">
        <img src="https://img.shields.io/github/stars/Qezta/infra?&style=for-the-badge&logoColor=white&color=purple&logo=starship" alt="stars"/>
    </a>
    <a href="https://github.com/Qezta/infra/">
        <img src="https://img.shields.io/github/repo-size/Qezta/infra?&style=for-the-badge&logoColor=white&color=purple&logo=github" alt="size"/>
    </a>
    <a href="https://github.com/nixos/nixpkgs">
        <img src="https://img.shields.io/badge/Nixpkgs-unstable-blue.svg?style=for-the-badge&logo=NixOS&logoColor=white&color=purple" alt="nixpkgs"/>
    </a>
    <a href="https://opentofu.org">
        <img src="https://img.shields.io/badge/OpenTofu-1.11+-purple.svg?style=for-the-badge&logo=opentofu&logoColor=white" alt="opentofu"/>
    </a>
    <img src="https://img.shields.io/github/languages/top/Qezta/infra?style=for-the-badge&color=purple" alt="repo-top-language"/>
</div>

______________________________________________________________________

<div align='center'>
    <a href="https://github.com/Qezta/infra/actions/workflows/flake-check.yml">
        <img src="https://github.com/Qezta/infra/actions/workflows/flake-check.yml/badge.svg" alt="flake-check"/>
    </a>
    <a href="https://github.com/Qezta/infra/actions/workflows/tofu-plan.yml">
        <img src="https://github.com/Qezta/infra/actions/workflows/tofu-plan.yml/badge.svg" alt="tofu-plan"/>
    </a>
</div>

______________________________________________________________________

## Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [GitHub Organization](#github-organization)
- [DNS](#dns)
- [State and CI](#state-and-ci)
- [Decisions](#decisions)

______________________________________________________________________

## Overview

Everything about the [Qezta](https://github.com/Qezta) GitHub organization and
`qezta.com` that can be declared, is declared here and applied with
[OpenTofu](https://opentofu.org) through [Terragrunt](https://terragrunt.com).
Configuration is written in Nix with [Terranix](https://terranix.org) and
compiled to OpenTofu JSON at plan time.

Who belongs to which team comes from the private
[Qezta/company](https://github.com/Qezta/company) spec, built with
[company-framework](https://github.com/Qezta/company-framework). Only its
public-safe projection (roles, team names, GitHub logins, repositories) is
committed here.

## Quick Start

```sh
nix develop                      # opentofu, terragrunt, gh, alejandra
cd orgs/Qezta
terragrunt plan                  # uses GITHUB_TOKEN_QEZTA, else `gh auth token`
```

Org settings, Actions policy and membership need a token with `admin:org`
and are off unless `QEZTA_MANAGE_ORG_SETTINGS=true` (with
`QEZTA_ORG_BILLING_EMAIL` set). Never commit state, `.tfvars` or tokens.

## Architecture

```mermaid
flowchart LR
  company["<b>Qezta/company</b> (private)<br/>qezta.nix"]
  proj["data/company/<br/>projection.json"]
  repos["terranix/<br/>qezta-repositories.nix"]
  terranix(["Terranix<br/>nix build .#qezta-github-json"])
  tg["Terragrunt + OpenTofu<br/>orgs/Qezta"]
  gh["GitHub<br/>repos · teams · rulesets"]

  company -- "company-framework<br/>public projection" --> proj
  proj --> terranix
  repos --> terranix
  terranix --> tg --> gh
```

## Project Structure

```mermaid
flowchart LR
  root(["infra/"])
  root --> rh["root.hcl<br/>state: local or encrypted R2"]
  root --> orgs["orgs/Qezta/<br/>GitHub org unit"]
  root --> dns["dns/qezta.com/<br/>email DNS unit"]
  root --> data["data/company/<br/>public projection"]
  root --> tn["terranix/"]
  root --> docs["docs/<br/>remote state · decisions"]
  root --> fl["flake/<br/>devshell · checks · workflows"]
  tn --> t1["qezta-github.nix<br/>repositories · workflow permissions"]
  tn --> t2["qezta-repositories.nix<br/>repository map"]
  tn --> t3["qezta-teams.nix<br/>teams · members · access"]
  tn --> t4["qezta-rulesets.nix<br/>default-branch rulesets"]
  tn --> t5["qezta-org.nix<br/>org settings (flagged)"]
  tn --> t6["qezta-ci.nix<br/>infra-apply environment"]
  tn --> t7["qezta-dns.nix<br/>DMARC"]
```

## GitHub Organization

| What | Where | Notes |
| --- | --- | --- |
| Repositories | `terranix/qezta-repositories.nix` | `existing = false` creates a repo instead of importing it; `prevent_destroy` on all |
| Teams and members | `data/company/projection.json` | Flat teams (`founders`, `engineering`, `security`); org owners are maintainers |
| Repository access | derived | Each system's owner team gets its role's permission; CODEOWNERS teams get at least `push` |
| Rulesets | `terranix/qezta-rulesets.nix` | Public repos: PRs required, no force push or deletion; admins bypass only within a PR |
| Org settings | `terranix/qezta-org.nix` | Behind a flag; requiring 2FA must be done by hand (not in the API) |

## DNS

`qezta.com` uses Spaceship DNS. `dns/qezta.com` manages individual email
records with `spaceship_dns_record` (never the plural resource, which would
delete every record it doesn't list). It currently adds a monitoring-only
DMARC record; MX and SPF belong to Spaceship email forwarding. Needs
`SPACESHIP_API_KEY` and `SPACESHIP_API_SECRET`.

## State and CI

State is local today. [docs/remote-state.md](docs/remote-state.md) describes
the move to an encrypted, locked Cloudflare R2 backend. Once it's done and the
`REMOTE_STATE_ENABLED` variable is set, pull requests get a `tofu plan`
comment and merges to `main` apply after approval in the `infra-apply`
environment.

```mermaid
flowchart LR
  pr["pull request"] --> plan["tofu-plan.yml<br/>plan, posted as a comment"]
  pr --> merge["merge to main"]
  merge --> gate{"infra-apply<br/>reviewer approves?"}
  gate -- yes --> apply["tofu-apply.yml<br/>terragrunt apply"]
  apply --> gh["GitHub org"]
  state[("R2 state<br/>encrypted, locked")] <--> plan
  state <--> apply
```

## Decisions

- [0001: GitHub teams and access come from the company projection](docs/decisions/0001-org-from-company-projection.md)
- [0002: Flat GitHub teams](docs/decisions/0002-flat-github-teams.md)
- [0003: CODEOWNERS through pull requests](docs/decisions/0003-codeowners-sync-via-ci.md)

<div align="right">

[![][back-to-top]](#top)

</div>

[back-to-top]: https://img.shields.io/badge/-BACK_TO_TOP-151515?style=flat-square&color=purple
