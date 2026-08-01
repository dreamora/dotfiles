---
name: commit-doc-audit
description: >-
  Audit documentation against the exact staged commit candidate and repair stale path references. Use before committing documentation,
  when documentation describes code or configuration changes, or whenever files are added, deleted, renamed, or moved and documentation
  plus shell scripts must be scanned for affected references.
---

# Commit Documentation Audit

Audit one future repository state: `HEAD` plus staged index.

## Contract

- Limit documentation to behavior, files, commands, and structure already in `HEAD` or staged in same commit.
- Never describe unstaged or untracked work as included. Label intentional future work explicitly, or leave it out.
- Do not stage files, broaden the commit, or rewrite unrelated documentation without user authority.
- Update docs only when a reader-facing contract, command, path, inventory, example, or architecture statement changed.
- Treat historical references as valid only when their historical context is clear.

## Workflow

1. Establish commit candidate.

   ```bash
   git status --short
   git diff --cached --name-status -M -C
   git diff --cached --stat
   ```

   Empty index: stop. Ask for explicit boundary or report no staged candidate. Never group all dirty files by assumption.

2. Read staged implementation and documentation diffs.

   ```bash
   git diff --cached --
   ```

   Compare each doc claim with `HEAD` plus index. Use `git show HEAD:<path>` when baseline matters.

3. Treat `A`, `D`, `R*`, and `C*` as mandatory reference-scan triggers. Run from repository root:

   ```bash
   bash .agents/skills/commit-doc-audit/scripts/audit_references.sh
   ```

   Script searches staged snapshot, not working tree. It scans repository docs and shell scripts for affected full paths and standalone
   basenames. Matches are review candidates, not automatic defects.

4. Review both surfaces:

   - Documentation: update current paths, commands, file inventories, diagrams, setup steps, and architecture descriptions.
   - Shell scripts: update sources, invocations, copy/install targets, package lists, path checks, and generated-file references.

   For additions, decide whether inventory, installer, or usage guide needs new path; absence can be correct. For moves or deletions,
   preserve old references only for explicit history or compatibility.

5. Re-run staged diff and audit after fixes. Confirm docs do not depend on unstaged or untracked changes.

## Output

Report:

- commit boundary audited;
- documentation files reviewed or changed;
- shell scripts reviewed or changed;
- stale references fixed;
- unresolved matches with reason;
- validation commands and results.

Never claim synchronization if index changed after final audit.
