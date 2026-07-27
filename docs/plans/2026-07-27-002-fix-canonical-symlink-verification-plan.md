---
title: Canonical Bootstrap Symlink Verification - Plan
type: fix
date: 2026-07-27
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
---

# Canonical Bootstrap Symlink Verification - Plan

## Goal Capsule

- **Objective:** Make Bootstrap CI prove that every checked Stow symlink resolves to its exact repository source instead of accepting a matching path fragment.
- **Authority:** `AGENTS.md` defines repository conventions; `.github/workflows/bootstrap.yml` owns the Bootstrap CI verification surface; GNU Stow's generated links define the valid relative-link behavior.
- **Stop conditions:** Within U1, do not change link creation, install-time cleanup, `.github/workflows/reliability-gates.yml`, path filters, or package ownership; the separately authorized `001` dependency remains in scope for completion before shipping.
- **Execution profile:** One bounded workflow unit on the existing `modernize-shell` branch, followed by local fixture checks and the macOS Bootstrap CI matrix.
- **Tail ownership:** Complete the already-authorized manifest-bootstrap plan before shipping because the current worktree invokes bootstrap installer modes that are not implemented yet.

## Product Contract

### Summary

Replace substring-based symlink acceptance with exact equality between canonical actual and expected paths.
Valid relative or absolute links to the intended source pass, while lookalike, dangling, missing, and non-symlink targets fail with actionable diagnostics.

### Problem Frame

The current `verify_symlink` helper compares raw `readlink` output with a caller-provided substring.
A link to a different path containing that fragment can pass, and the check does not normalize Stow's relative links against the link location.

### Requirements

#### Identity verification

- R1. Each Bootstrap symlink check receives the full expected repository source path, including the filename or linked directory.
- R2. Verification canonicalizes the generated symlink and expected source independently, then accepts only exact path equality.
- R3. Relative and absolute symlinks that resolve to the same source both pass.

#### Failure handling

- R4. Missing or non-symlink targets, unresolvable actual targets, unresolvable expected sources, and canonical mismatches each count as failures.
- R5. One bad link does not prevent the helper from checking and reporting the remaining links.
- R6. Failure output distinguishes the raw link destination from canonical actual and expected paths where those values are available.

#### Compatibility and scope

- R7. The implementation remains compatible with the Bash and `realpath` available on the macOS GitHub runners.
- R8. Existing Bootstrap path filters, Stow setup, checked link inventory, and aggregate step failure behavior remain unchanged.

### Acceptance Examples

- AE1. A Stow-created relative link and an absolute link to the same repository source both pass.
- AE2. A link to a lookalike path whose text contains `.dotfiles/homedir` fails because its canonical destination differs.
- AE3. A dangling link, a regular file, and a missing expected source each produce one failure without stopping later checks.
- AE4. Source and target paths containing spaces pass when they resolve to the same object.

### Scope Boundaries

- Do not change the similar legacy check in `.github/workflows/reliability-gates.yml`; it is outside finding #2's Bootstrap CI scope.
- Do not change the install-time Mise cleanup predicate in `install.sh`; it governs migration cleanup rather than CI verification.
- Do not extract a shared helper or add a test framework for one workflow-local function.
- Complete `docs/plans/2026-07-27-001-fix-manifest-owned-bootstrap-plan.md` before pushing because its partial work currently leaves Bootstrap CI broken.

## Planning Contract

### Key Technical Decisions

- KTD1. Canonicalize both operands with quoted `realpath` calls and compare them with exact shell equality. Canonicalizing both sides preserves valid relative Stow links and filesystem aliases such as `/var` to `/private/var`.
- KTD2. Keep `readlink` only for diagnostics. Raw link text is useful evidence but is not an identity check.
- KTD3. Guard each canonicalization under `set -euo pipefail`, increment the aggregate error counter, and return from the helper instead of allowing a failed command substitution to abort the workflow step.
- KTD4. Pass full sources rooted at `$GITHUB_WORKSPACE`: `homedir/$dotfile`, `homedir/.config/mise`, `config/starship.toml`, and `scripts/regen-completions.sh`.

### Assumptions

- GitHub's supported macOS runners continue to expose `/bin/realpath`, matching the current local macOS environment.
- Exact source identity is the intended contract; accepting any source beneath a broader package directory is not required.

### Risks & Dependencies

| Risk or dependency | Mitigation |
| --- | --- |
| A failed `realpath` exits the step before aggregate reporting | Run each call in a guarded conditional and count one failure per checked link. |
| Raw relative and absolute links differ textually | Compare only canonical paths; retain raw text solely for diagnostics. |
| The branch's unfinished manifest-bootstrap work makes CI fail independently | Execute the existing `001` plan before shipping this change. |
| Local fixtures cannot prove runner behavior | Require both macOS Bootstrap CI matrix jobs after push. |

### Sources & Research

- `AGENTS.md`
- `.github/workflows/bootstrap.yml`
- `docs/plans/2026-05-18-001-fix-ci-merge-conflicts-plan.md`
- `docs/plans/2026-07-27-001-fix-manifest-owned-bootstrap-plan.md`

The repository has no `.compound-engineering/solutions/` corpus to apply, and external research was not load-bearing for this repository-local CI contract.

### Execution Sequence

1. Execute U1 and U2 from `docs/plans/2026-07-27-001-fix-manifest-owned-bootstrap-plan.md` to finish the already-authorized package-ownership prerequisite.
2. Execute this plan's U1 without making package-ownership changes beyond that prerequisite.
3. Run the combined local and remote verification contracts before shipping.

## Implementation Units

### U1. Enforce exact canonical symlink identity

- **Goal:** Make Bootstrap CI accept only links resolving to the exact expected repository object while retaining aggregate diagnostics.
- **Requirements:** R1-R8; AE1-AE4
- **Dependencies:** Complete the implementation described by `docs/plans/2026-07-27-001-fix-manifest-owned-bootstrap-plan.md` before shipping.
- **Files:** `.github/workflows/bootstrap.yml`
- **Approach:**
  1. Give the helper descriptive raw, actual, and expected path variables.
  2. Reject non-symlinks, then guard raw-link capture and both canonicalization calls so failures are counted rather than terminating the step.
  3. Compare canonical actual and expected paths exactly and emit evidence-rich mismatch diagnostics.
  4. Replace every expected fragment at the call sites with the corresponding full `$GITHUB_WORKSPACE` source.
- **Execution note:** This is workflow configuration; use temporary filesystem and Stow smoke fixtures before relying on the remote matrix.
- **Patterns to follow:** Preserve the existing helper boundary, aggregate `errors` counter, GitHub annotation summary, and macOS matrix in `.github/workflows/bootstrap.yml`.
- **Test scenarios:**
  - **Happy path:** Relative Stow links for homedir, config, and script targets resolve to their full expected sources and pass.
  - **Compatibility:** Absolute links and paths containing spaces resolve to their full expected sources and pass.
  - **False-positive regression:** A link resolving beneath a lookalike path containing the old expected fragment fails exact comparison.
  - **Error paths:** A dangling link, regular file, and missing expected source each increment errors without preventing later checks.
  - **Integration:** The complete workflow parses and both macOS Bootstrap CI jobs validate the actual Stow output.
- **Verification:** The fixture matrix rejects every invalid case, accepts both valid link forms, workflow parsing succeeds, and remote Bootstrap CI passes on both runner versions.

## Verification Contract

### Focused behavioral proof

- Build a temporary source tree with paths containing spaces and exercise relative and absolute valid links, a lookalike target, a dangling link, a regular file, and a missing expected source.
- Run GNU Stow against a temporary home and confirm homedir, nested config, and script links canonicalize to their exact repository sources.
- Confirm all invalid fixtures are reported in one run and the aggregate result is nonzero.

### Repository gates

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/bootstrap.yml")'
git diff --check
```

### Environment-dependent gates

After push, require both Bootstrap CI matrix jobs and Syntax Gate to pass.

## Definition of Done

- Every Bootstrap symlink call names its exact repository source.
- Valid relative and absolute links pass only when their canonical destinations equal the canonical expected sources.
- Lookalike, dangling, missing, non-symlink, and unresolvable expected cases fail without suppressing later diagnostics.
- The existing Bootstrap workflow behavior outside symlink verification remains unchanged.
- The `001` manifest-bootstrap plan is complete, all local verification gates pass, and the macOS CI matrix is green.
- No abandoned helper, debug output, unrelated cleanup, or private untracked runtime files enter the shipped diff.
