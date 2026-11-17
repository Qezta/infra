______________________________________________________________________

## status: accepted date: 2026-11-17

# Host qezta.com DNS and email routing on Cloudflare

## Context and Problem Statement

Email forwarding (`divit@`, `hello@`, ...) is configured in the Spaceship
dashboard. Neither the Spaceship OpenTofu provider (v1.0.6) nor, as far as we
could find, Spaceship's API manages forwarding rules, so they can't be code.

## Considered Options

- Keep Spaceship forwarding, configured by hand
- Cloudflare DNS + Email Routing, managed with the Cloudflare provider
- A third-party forwarding service with an API

## Decision Outcome

Chosen option: "Cloudflare DNS + Email Routing", because every record and
every forward becomes reviewable code with a supported provider, Email
Routing also publishes DKIM, and it's free. Spaceship remains the registrar;
the nameserver change is itself code (`spaceship_domain`).

### Consequences

- Good, because the whole zone is declared, not just the records we added.
- Bad, because the migration has to sequence DNSSEC (disable, wait, cut over,
  re-sign) to avoid an outage; a hook refuses the cutover while the old DS
  record is published.
