# Qezta GitHub repositories

The repository definitions are maintained in `../../terranix/qezta-repositories.nix`.

This directory is the planned Qezta management boundary. The shared GitHub
modules and provider wiring will be migrated from `forge-terraform` here
before the first apply.

Before applying, import existing repositories and review the plan. Do not
apply until the remote state backend is configured.
