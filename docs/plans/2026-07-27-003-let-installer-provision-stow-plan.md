---
title: Installer-Owned Stow Provisioning - Plan
type: fix
date: 2026-07-27
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
---

# Installer-Owned Stow Provisioning - Plan

## Goal Capsule

- **Objective:** Make Bootstrap CI exercise `install.sh` as the sole provisioner of GNU Stow instead of satisfying that prerequisite in the workflow.
- **Authority:** `AGENTS.md` defines repository conventions; `software/bootstrap.list` owns pre-Stow formulae; `install.sh` owns bootstrap sequencing; `.github/workflows/bootstrap.yml` owns the remote proof.
- **Stop conditions:** Do not change the bootstrap manifest, installer implementation, runner image state, Git identity behavior, or other review findings.
- **Execution profile:** One workflow-only implementation unit on the existing `modernize-shell` branch, followed by static checks and the macOS Bootstrap CI matrix.
- **Tail ownership:** Ship through the existing PR and distinguish proof of Stow provisioning from unrelated downstream CI failures.

---

## Product Contract

### Summary

Remove the workflow's standalone `brew install stow` step.
The subsequent `Run install.sh` step must install Stow from `software/bootstrap.list` before the first `stow` invocation, so the CI job validates the installer contract it is meant to exercise.

### Problem Frame

Bootstrap CI currently installs Stow before calling `install.sh`.
That setup masks a regression where the repository installer no longer provisions a command it uses later in the same run.
The manifest-backed bootstrap path already includes Stow and executes before dotfile symlinking, so CI should consume that path directly.

### Requirements

- R1. `.github/workflows/bootstrap.yml` does not install Stow independently of `install.sh`.
- R2. `install.sh` remains responsible for installing `software/bootstrap.list` before its first `stow` command.
- R3. The workflow continues to run the same installer command, environment, matrix, path filters, and post-install verification steps.
- R4. No workflow reset or assertion assumes whether a future GitHub runner image preinstalls Stow.
- R5. Remote evidence identifies whether `Run install.sh` completes its Stow operations, even if a later unrelated check fails.

### Acceptance Examples

- AE1. On a runner without Stow, `Run install.sh` installs the `stow` entry from `software/bootstrap.list` and then creates the expected links.
- AE2. On a runner where Stow is already present, the idempotent bootstrap path accepts it and continues without workflow-owned installation.
- AE3. A future regression that removes Stow from the installer path fails within `Run install.sh` rather than being masked by workflow setup.

### Scope Boundaries

- Do not uninstall Stow or assert its initial absence; runner image contents are not repository-owned.
- Do not alter `software/bootstrap.list`, `install.sh`, or `install_packages.sh`; current code already implements the required ordering.
- Do not address the separate Git identity verification failure or other retained review findings in this unit.

---

## Planning Contract

### Key Technical Decisions

- KTD1. session-settled: Remove the standalone `Install stow` workflow step and let `install.sh` provision Stow. This is user-directed; keeping the preinstall was rejected because it masks the installer contract.
- KTD2. Do not replace installation with workflow-owned uninstall or absence assertions. The behavioral contract is that the installer works from either absent or already-satisfied state, while hosted runner inventory may drift.
- KTD3. Treat completion of the installer and symlink verification as the relevant evidence. Record unrelated later job failures as residual CI state rather than widening this change.

### Assumptions

- `software/bootstrap.list` continues to include `stow`.
- `install.sh` continues to invoke `install_packages.sh --bootstrap-install` before its first Stow command.
- Homebrew remains available on the supported macOS GitHub-hosted runners.

### Risks & Dependencies

- The hosted runner may already contain Stow, so a single run cannot always prove a cold install; removal of the masking step still restores installer ownership and allows cold runners to exercise it.
- The Bootstrap job may remain red at the known downstream Git identity check; logs must show whether the installer and symlink stages passed.
- This unit depends on the already-landed manifest-owned bootstrap work on the branch.

### Sources & Research

- `AGENTS.md`
- `.github/workflows/bootstrap.yml`
- `install.sh`
- `install_packages.sh`
- `software/bootstrap.list`
- `docs/plans/2026-07-27-001-fix-manifest-owned-bootstrap-plan.md`

The repository has no `.compound-engineering/solutions/` corpus, and external research is not load-bearing for this repository-local ownership correction.

### Execution Sequence

1. Remove the standalone workflow step.
2. Confirm the installer-to-manifest-to-Stow ordering remains intact.
3. Run local workflow/static validation, then inspect both remote Bootstrap matrix jobs for installer-stage evidence.

---

## Implementation Units

### U1. Delegate Stow provisioning to the installer

- **Goal:** Ensure Bootstrap CI no longer masks whether `install.sh` provides GNU Stow.
- **Requirements:** R1-R5; AE1-AE3
- **Files:** `.github/workflows/bootstrap.yml`
- **Approach:** Delete only the named `Install stow` step. Preserve the checkout, repository symlink, installer command and environment, symlink checks, matrix, and all later workflow steps.
- **Dependencies:** Manifest-owned bootstrap behavior already present in `software/bootstrap.list`, `install_packages.sh`, and `install.sh`.
- **Test scenarios:**
  - **Static ownership:** No workflow-local Stow installation remains, the manifest still contains `stow`, and bootstrap installation precedes the first Stow call.
  - **Idempotence:** Existing installer behavior handles both missing and already-installed formulae.
  - **Integration:** Both macOS jobs run `install.sh`; logs show whether installer and symlink verification complete before any unrelated failure.
- **Verification:** Parse the workflow, run shell syntax and manifest checks, inspect the scoped diff, then inspect remote Bootstrap job logs.

---

## Verification Contract

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/bootstrap.yml")'
bash -n install.sh install_packages.sh
./install_packages.sh --check combined
test "$(grep -cx 'stow' software/bootstrap.list)" -eq 1
test "$(rg -n 'bootstrap-install' install.sh | wc -l | tr -d ' ')" -ge 1
! rg -n 'brew install stow|name: Install stow' .github/workflows/bootstrap.yml
git diff --check
```

After push, inspect both Bootstrap CI matrix jobs.
The installer and symlink stages must pass or provide a Stow-specific failure; a later unrelated failure is recorded separately.

---

## Definition of Done

- Bootstrap CI contains no standalone Stow installation.
- The existing manifest-backed bootstrap call remains before the first Stow invocation.
- Workflow parsing, shell syntax, manifest validation, focused ownership assertions, and diff checks pass.
- Remote Bootstrap logs show the installer-owned path executing on both supported macOS runners.
- The diff contains no runner-state manipulation, Git identity change, unrelated cleanup, or private untracked runtime files.
