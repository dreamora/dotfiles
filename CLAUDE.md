# Project Instructions for AI Agents

Before working in this repository, read [`AGENTS.md`](AGENTS.md).

## Mandatory Maintenance Reference

Before changing the installer, package manifests or profiles, shell/PATH startup,
Stow targets, or CI, read
[`docs/reference/dotfiles-maintenance.md`](docs/reference/dotfiles-maintenance.md).
Treat it as canonical for verified decisions and reproducibility/idempotency limits.
Update it in the same change whenever those contracts change. Bootstrap CI alone
does not prove a fresh-machine or full optional-path installation.

This project uses Beads for durable task tracking. Run `bd prime` before managing
issues or project memory.
