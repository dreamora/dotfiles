---
title: Finish Shell Review Findings - Plan
type: fix
date: 2026-07-27
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
---

# Finish Shell Review Findings - Plan

## Goal Capsule

- **Objective:** Close retained findings #5-#7 by verifying controlled JavaScript package-manager selection, renaming the completion refresh
  command to the repository convention, and routing its output through shared helpers.
- **Authority:** `AGENTS.md` defines shell naming and output conventions; `homedir/.shellfn` owns `deps()` behavior; `scripts/` and
  Bootstrap CI define the globally Stow-linked command contract.
- **Stop conditions:** Do not change package-manager precedence or install commands, add package managers, retain a legacy command shim,
  broadly clean user-owned links, rewrite shared output helpers, or address unrelated shell and CI findings.
- **Execution profile:** One verification-only unit and one behavior-bearing implementation unit on the existing `modernize-shell`
  branch, with disjoint subagent ownership and canonical integration in the main task.
- **Tail ownership:** Ship through the existing PR, run both Bootstrap matrix jobs, and preserve the private untracked runtime directories.

---

## Product Contract

### Summary

The `deps()` helper must fail clearly when the manager selected by the highest-priority lockfile is unavailable.
The completion refresh command must use the repository's `snake_case.sh` naming convention and shared output vocabulary while remaining
runnable through its Stow-created global symlink.

### Problem Frame

The retained review described three related shell-quality gaps.
Finding #5 has since been implemented on the branch in commit `8d28132`, so this run must verify that behavior without duplicating it.
Findings #6 and #7 remain: the globally exposed completion command uses a hyphenated filename and prints its own raw status strings rather
than the shared helpers.

### Requirements

#### Controlled package-manager selection

- R1. `deps()` preserves lockfile precedence: pnpm, then npm, then Yarn.
- R2. The selected manager is checked with `command -v` before invocation.
- R3. A missing selected manager emits a lockfile-specific error and returns `1` without falling through to a lower-priority lockfile.
- R4. Existing install arguments, command failure propagation, and no-lockfile failure behavior remain unchanged.

#### Completion command naming

- R5. The tracked executable and globally Stow-linked command are named `regen_completions.sh`.
- R6. Bootstrap symlink verification and command discovery use the new name and exact repository source.
- R7. All maintained tracked references use the new name; no compatibility wrapper preserves the convention violation.
- R8. Before restowing scripts, `install.sh` removes the old global name only when it is a symlink whose resolved parent is this checkout's
  physical `scripts/` directory and whose basename is `regen-completions.sh`.

#### Shared output behavior

- R9. The completion command sources `lib_sh/echos.sh` from the physical repository location even when invoked through a relative Stow
  symlink from another working directory.
- R10. Successful regeneration, skipped tools, failures, and final completion use the repository's shared success, warning, error, and
  announcement helpers.
- R11. Failure output remains on stderr, generator exit status is preserved, temporary output is removed on failure, and the previous
  completion file remains intact.

### Acceptance Examples

- AE1. With multiple lockfiles, an unavailable highest-priority manager produces its matching error and no lower-priority manager runs.
- AE2. Invoking `regen_completions.sh` through a Stow-style relative symlink from outside the checkout loads shared helpers successfully.
- AE3. Successful fake `jj` and `kubectl` generators atomically replace their completion files and emit shared success output.
- AE4. An absent generator produces a shared warning without failing the whole refresh.
- AE5. A failing generator emits a shared error on stderr, preserves its previous completion file, removes temporary output, and returns
  the generator's status.
- AE6. Bootstrap CI finds only `regen_completions.sh` on `PATH` and verifies its canonical source.
- AE7. Re-running `install.sh` after upgrading removes the old repository-owned dangling symlink before Stow creates the new command,
  while a regular file or symlink to any other location remains untouched.

### Scope Boundaries

- Do not add Corepack activation, Bun support, `package.json#packageManager` parsing, or automatic manager installation.
- Do not change pnpm/npm/Yarn precedence or fall through when the selected manager is unavailable.
- Do not retain `regen-completions.sh` as a wrapper or alias.
- Do not remove a regular file, a symlink owned by another checkout, or a similarly named user-owned link during migration.
- Do not change `lib_sh/echos.sh`; consume its existing API.
- Do not address the pre-existing `homedir/.shellfn` tmux interpolation concern.

---

## Planning Contract

### Key Technical Decisions

- KTD1. Verify the current `command -v` guards rather than reimplementing them. (session-settled: user-directed — chosen over invoking a
  lockfile-selected manager without a controlled availability check: missing tools should fail clearly and predictably.)
- KTD2. Rename the executable and command to `regen_completions.sh`. (session-settled: user-directed — chosen over retaining
  `regen-completions.sh`: repository shell filenames use `snake_case.sh`.)
- KTD3. Source and use the shared output helpers for every status class. (session-settled: user-directed — chosen over raw script-local
  `echo` strings: user-facing shell output should follow the repository vocabulary.)
- KTD4. Resolve the script's physical location through relative or absolute symlink targets before sourcing `lib_sh/echos.sh`. The
  supported command is invoked from `$HOME/.local/bin`, so the apparent invocation directory is not a reliable repository root.
- KTD5. Apply the rename without a legacy wrapper. A wrapper would keep the nonconforming command and weaken Bootstrap's proof that the
  new public name is installed.
- KTD6. Add a narrowly guarded pre-Stow migration in `install.sh`. Resolve only the legacy link's parent directory physically, compare it
  with `$DOTFILES_DIR/scripts`, require the old basename, and remove the link before restowing; this handles a dangling final target without
  broad suffix matching.

### Assumptions

- GNU Stow continues to create a relative link from `$HOME/.local/bin` to the repository script.
- The shared helper API remains `ok`, `warn`, `error`, and `bot`.
- Maintained plan references are updated when the executable path they specify changes.

### Risks & Dependencies

| Risk or dependency | Mitigation |
| --- | --- |
| Sourcing relative to the symlink path fails outside the checkout | Exercise a Stow-style relative symlink from an unrelated working directory. |
| A helper conversion changes exit or stderr behavior | Use focused fake generators covering success, absence, and nonzero failure. |
| Rename leaves stale CI or documentation references | Search the entire tracked tree for the old name and update every maintained reference. |
| Stow leaves a dangling old command after a rename | Remove the repository-owned link and prove unrelated links survive. |
| Parallel agents collide on the script | Give U1 read-only ownership and U2 exclusive rename/helper ownership. |

### Sources & Research

- `AGENTS.md`
- `homedir/.shellfn`
- `scripts/regen-completions.sh`
- `lib_sh/echos.sh`
- `.github/workflows/bootstrap.yml`
- `scripts/verify_folder_contracts.sh`
- `docs/plans/modernisation.md`
- `docs/plans/2026-07-27-002-fix-canonical-symlink-verification-plan.md`
- Git history for commits `8d28132`, `d585ee4`, and `3cacebb`

The repository has no `.compound-engineering/solutions/` corpus, and external research is not load-bearing for these repository-local shell contracts.

### Execution Sequence

1. Run U1 as verification-only work; do not modify `homedir/.shellfn` when the existing behavior satisfies R1-R4.
2. Execute U2 with exclusive ownership of the command rename, guarded upgrade cleanup, helper integration, and all tracked references.
3. Run focused shell fixtures, repository gates, and the remote CI matrix.

---

## Implementation Units

### U1. Verify controlled manager checks

- **Goal:** Confirm finding #5 remains completely addressed without redundant edits.
- **Requirements:** R1-R4; AE1
- **Files:** `homedir/.shellfn` for read-only verification
- **Approach:** Inspect the current guards and exercise lockfile precedence, missing-manager paths, exact argument vectors, no-lockfile
  behavior, and manager failure propagation with isolated command stubs.
- **Dependencies:** None.
- **Execution note:** Characterize the current behavior and leave the file unchanged when it satisfies the contract.
- **Test scenarios:**
  - Each manager receives its existing frozen-lockfile command when available.
  - Each missing manager produces its lockfile-specific error and status `1`.
  - Multiple lockfiles preserve precedence and do not fall through.
  - No lockfile returns `1`; an invoked manager's nonzero result propagates.
- **Verification:** Focused Zsh fixture matrix, `zsh -n homedir/.shellfn`, and ShellCheck at error severity.

### U2. Rename and standardize completion output

- **Goal:** Expose the completion refresh command under the repository naming convention and make its output use shared helpers without
  breaking global symlink execution.
- **Requirements:** R5-R11; AE2-AE7
- **Files:** `scripts/regen-completions.sh` renamed to `scripts/regen_completions.sh`, `install.sh`,
  `.github/workflows/bootstrap.yml`, `docs/plans/modernisation.md`, and
  `docs/plans/2026-07-27-002-fix-canonical-symlink-verification-plan.md`
- **Approach:** Rename the executable, remove only the repository-owned legacy symlink before restowing, resolve the new command's physical
  repository location before sourcing the shared output library, replace raw status messages with appropriate helpers, and update every
  tracked operational or maintained-plan reference.
- **Dependencies:** None; may execute alongside U1 because file ownership is disjoint.
- **Execution note:** Use a temporary HOME and fake commands to prove behavior through a relative Stow-style symlink before relying on remote CI.
- **Test scenarios:**
  - Both generators succeed and their files are atomically replaced.
  - One generator is absent and warns without failing.
  - One generator fails with a nonzero status; stderr, prior-file preservation, and temp cleanup remain correct.
  - The command loads helpers when invoked from outside the checkout through relative and absolute symlinks, including the global Stow-link
    shape.
  - Upgrade cleanup removes the former repository-owned dangling link and preserves unrelated symlinks and regular files.
  - No tracked old-name reference remains; Bootstrap verifies and discovers the new command.
- **Verification:** Targeted symlink smoke harness, Bash syntax, ShellCheck, folder-contract verification, workflow YAML parsing,
  tracked-reference search, and Bootstrap CI.

---

## Verification Contract

```bash
zsh -n homedir/.shellfn
bash -n install.sh scripts/regen_completions.sh
shellcheck --severity=error --shell=bash --exclude=SC1090,SC1091 \
  homedir/.shellfn install.sh scripts/regen_completions.sh
./scripts/verify_folder_contracts.sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/bootstrap.yml")'
test "$(git grep -n 'regen-completions\.sh' -- install.sh | wc -l | tr -d ' ')" -eq 1
! git grep -n 'regen-completions\.sh' -- .github scripts docs/plans/modernisation.md \
  docs/plans/2026-07-27-002-fix-canonical-symlink-verification-plan.md
git diff --check
```

Run isolated fixtures for U1 and U2 as specified above.
After push, require Syntax Gate, ShellCheck, both reliability matrix jobs, and both Bootstrap matrix jobs to pass.

---

## Definition of Done

- Finding #5's controlled package-manager behavior is verified with no redundant source edit.
- The completion refresh executable, global command, CI checks, and maintained references use `regen_completions.sh`.
- Existing installations remove only the repository-owned old symlink before restowing the renamed command.
- The renamed script uses shared helpers and resolves them correctly through a Stow-style relative symlink.
- Success, skip, error, atomic-write, stderr, and exit-status behavior pass focused fixtures.
- Shell syntax, ShellCheck, folder contracts, YAML parsing, reference search, and diff checks pass.
- The full GitHub CI set is green, no legacy wrapper remains, and no private untracked runtime file is staged.
