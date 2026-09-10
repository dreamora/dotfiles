# Dotfiles Maintenance Reference

- **Status:** Canonical operational reference
- **Last verified:** 2026-08-01
- **Scope:** Installer, package manifests and profiles, shell startup and `PATH`, GNU Stow layout, and CI
- **Platform:** macOS workstation provisioning; Linux support is not established

This is a prerequisite for changes to the areas above. Read it before making those changes and update it in the same change
whenever a documented contract changes. It records durable outcomes, not the chronology of the rework.

| Label | Meaning |
|---|---|
| **Verified behavior** | Observed in the current implementation or reproduced locally. |
| **Policy decision** | The intended repository contract, even when an implementation gap remains. |
| **Known limitation** | Behavior that is incomplete, unproven, or unsafe to generalize. |

The implementation remains the evidence for behavior. If it and this reference diverge, re-verify the behavior and update both.
Broad claims in the [README](../../README.md) do not override the limitations recorded here.

## 1. Workstation model

**Policy decision:** This repository is an executable macOS workstation definition. The provisioning model is:

```text
software manifests + managed configuration
                  |
                  v
              install.sh
                  |
        +---------+----------+
        |         |          |
     Homebrew    mise      GNU Stow
                              |
                    +---------+----------+
                    |         |          |
                  $HOME   ~/.config  ~/.local/bin
```

| Component | Verified responsibility |
|---|---|
| [`install.sh`](../../install.sh) | Orchestrates bootstrap, Stow, runtimes, packages, and optional macOS customization. |
| Homebrew | Installs bootstrap formulae, normal formulae, casks, and trusted taps. |
| mise | Owns development runtimes and exposes their shims. |
| GNU Stow | Retained configuration linker; replacing it was rejected. |
| `homedir/` | Stowed into `$HOME`. |
| `config/` | Stowed into `$HOME/.config`. |
| `scripts/` | Stowed into `$HOME/.local/bin`. |

## 2. Package profile semantics

**Verified behavior:** Root manifests are always the common package set. Overlay manifests append to common; they do not replace it.

| Profile argument | Effective declaration set | Intended role |
|---|---|---|
| `common` | root manifests | Every workstation |
| `private` | common + `software/private/` | Personal workstation |
| `business` | common + `software/business/` | Work workstation |
| `combined` or `all` | common + private + business | Deliberate union/testing only |

`software/bootstrap.list` is common-only and profile-independent. The current workstation role is **private**, so its drift
command must use `private`.

**Known limitation:** [`install_packages.sh`](../../install_packages.sh) defaults to `combined`, and `install.sh` explicitly
hardcodes `combined`. That is current behavior, not correct role selection. Do not use it as evidence that a private machine should
install business packages. Track explicit installer profile selection in Bead `dotfiles-ftf.16`.

## 3. Shell startup and `PATH`

**Policy decision:** The shell is hand-rolled zsh with Starship. Oh My Zsh and Powerlevel10k are not part of the model.

| File | Ownership |
|---|---|
| [`.zshenv`](../../homedir/.zshenv) | Highest-priority mise shims, Cargo binaries, and `~/.local/bin`; applies to all zsh invocations. |
| [`.zprofile`](../../homedir/.zprofile) | Login-shell bridge that sources `.profile`. |
| [`.profile`](../../homedir/.profile) | Homebrew `shellenv`; shared paths/variables; private vars; LM Studio, Cargo, and Atuin environment. |
| [`.shellpaths`](../../homedir/.shellpaths) | Remaining tool paths, including Android, Ruby, Google Cloud, Bun, LLVM/ICU, and optional CLIs. |
| [`.zshrc`](../../homedir/.zshrc) | Interactive aliases, functions, completions, plugins, and tool activation. |

**Known limitation:** `.zshrc` sources `.profile` only when `HOMEBREW_PREFIX` is unset. Therefore `source ~/.zshrc` does not
reliably refresh state owned by `.profile`, `.shellvars`, or `.shellpaths` in an existing shell.

Use a new login shell for a complete reload:

```bash
exec "$SHELL" -l
reload # alias for the command above
```

## 4. Package policy and decisions

**Policy decisions:**

- The `.list` files under [`software/`](../../software/README.md) are canonical. Brewfiles and `packages.json` were evaluated and rejected.
- One declaration per line keeps Homebrew, npm, gem, MAS, and VS Code policy in one reviewable format.
- Every entry in [`software/tap.list`](../../software/tap.list) is an explicit trust declaration. The installer runs
  `brew trust --tap` and only then `brew tap`; review a tap before declaring it.
- `anomalyco/tap` plus `anomalyco/tap/opencode` is the canonical OpenCode source.
- `claude-code@latest` is the canonical private Claude cask.

Commit `03e9e99` removed stale direct declarations from common and private manifests. The cleanup covered obsolete or superseded
CLI tools, transitive libraries/toolchains, no-longer-desired desktop/sync/VM/terminal apps, and private development apps. It also
removed obsolete taps, changed the OpenCode source, and replaced the old Claude cask declaration. Avoid restoring removed entries
merely because they remain installed.

The following are intentionally **transitive**, not direct formula declarations:

- `gdk-pixbuf`
- `lua`
- `openssl@3`
- `readline`

The following are verified desired direct packages:

| Provider | Direct declarations |
|---|---|
| Homebrew formulae | `cloudflare-wrangler`, `gtop`, `tree-sitter-cli` |
| Homebrew cask | `handbrake-app` |
| Global npm | `npm-check-updates`, `openupm-cli`, `safe-rm` |

Installed-but-undeclared extras are warning-only and intentionally ignored. They may be local experiments or provider dependencies;
do not reopen their classification unless package-inventory scope is explicitly reopened.

**Verified private-profile drift on 2026-08-01:**

| Provider | Missing declared state |
|---|---|
| Homebrew cask | `ledger-live` |
| Mac App Store | 21 declared apps |
| VS Code | 6 declared extensions |

Track app/editor reconciliation in Bead `dotfiles-ftf.17`.

## 5. Drift checker contract

For this workstation, run:

```bash
./install_packages.sh --drift-check ./software private
```

**Verified behavior:** Manifest validation completes before any provider is queried. A malformed or incomplete manifest therefore
fails without producing misleading provider drift.

| Condition | Result |
|---|---|
| Declared package is missing | Error; check fails. |
| Installed package is undeclared | Warning; check continues. |
| Provider command is unavailable | Warning; that provider is skipped. |
| Available provider query fails | Error; check fails without inventing missing-package results. |

Provider-specific rules:

- Homebrew missing-package checks compare declarations with **all** installed formulae.
- Homebrew extra warnings compare declarations only with `--installed-on-request`; transitive formulae are excluded.
- Homebrew uses full names and normalizes `homebrew/core/` while retaining tap-qualified names.
- Scoped npm packages such as `@scope/tool` retain their scope when parsed from npm's global tree.
- A declared tap must be both tapped and trusted. Missing or untrusted declarations fail; extra taps or trust entries warn.

## 6. Installer safety and idempotency truth

**Known limitation:** Do **not** claim full cross-machine consistency, full reproducibility, or complete idempotency yet.

The bootstrap workflow runs `install.sh` twice and verifies repository cleanliness, absence of new untracked files, no additional
backup directory on the second run, and selected symlink targets. This proves only the exercised CI path.

CI skips or declines:

- custom wallpaper replacement;
- font installation;
- `/etc/hosts` replacement;
- the full manifest package-install prompts, including casks and MAS apps;
- Vim plugin installation and GUI launches;
- optional macOS defaults/system configuration.

GitHub-hosted macOS runners normally already contain Homebrew. The deprecated Ruby-based Homebrew bootstrap branch is therefore
not proven as a fresh-machine path.

Current hardening concerns:

- deprecated `ruby -e` Homebrew bootstrap;
- hardcoded `combined` profile;
- no top-level strict mode in `install.sh`;
- old macOS defaults, launchd jobs, and filesystem paths;
- no implemented general dotfile backup before Stow conflict handling.

In particular, `install.sh` does not create dated `~/.dotfiles_backup` snapshots or move displaced dotfiles there. Stow alone does
not implement that claim, and the presence of [`restore.sh`](../../restore.sh) does not prove backups were generated. Do not document
generated dotfile backups as verified behavior.

Completed safety improvements:

- all system-wallpaper backup copies must succeed before replacement starts;
- the redundant Homebrew cache removal was removed;
- deprecated Time Machine behavior and sleep-image mutation have version/existence guards;
- the [mise helper](../../lib_sh/mise_setup.sh) resolves its sourced helper relative to `BASH_SOURCE`.

Bead `dotfiles-ftf.16` owns the known installer/profile work. File additional installer-hardening work in Beads and complete it
before claiming reproducibility or general idempotency.

## 7. CI and evidence boundaries

| Workflow | Verified coverage |
|---|---|
| [Syntax Gate](../../.github/workflows/syntax-gate.yml) | Bash/zsh syntax, combined manifest validation, folder contracts; lint runner is Ubuntu. |
| [Reliability Gates](../../.github/workflows/reliability-gates.yml) | ShellCheck plus Bash/zsh utility contracts; Stow/manifests/folders on macOS 15/26. |
| [Bootstrap CI](../../.github/workflows/bootstrap.yml) | CI install/rerun, links, shell, bootstrap, and drift on macOS 15/26. |

The Reliability Gates and Bootstrap CI macOS matrices use `macos-15` and `macos-26`.

Ubuntu lint jobs do not establish Linux workstation support. `act` executes through Linux/Docker and is useful for workflow
debugging, but it is not authoritative evidence for these macOS jobs.

Exact workflow `run:` blocks can be extracted and executed locally when parity matters. For example, this runs the embedded drift
fixture rather than a rewritten approximation:

```bash
ruby -ryaml -e '
workflow = YAML.load_file(ARGV.fetch(0), aliases: true)
step = workflow.fetch("jobs").fetch("bootstrap").fetch("steps")
  .find { |item| item["name"] == ARGV.fetch(1) }
abort "step not found" unless step
print step.fetch("run")
' .github/workflows/bootstrap.yml "Verify package drift checker" \
  > /tmp/dotfiles-drift-fixture.sh
RUNNER_TEMP="$(mktemp -d)" bash /tmp/dotfiles-drift-fixture.sh
```

Hosted CI evidence verified on 2026-08-01 for branch `modernize-shell`:

- Local HEAD and origin matched commit `03e9e9928b6d963f46495f7985cbeb6d957a0f5c`.
- [Syntax Gate](https://github.com/dreamora/dotfiles/actions/runs/30688921324) succeeded.
- [Reliability Gates](https://github.com/dreamora/dotfiles/actions/runs/30688921308) succeeded, including macos-15 and macos-26.
- [Bootstrap CI](https://github.com/dreamora/dotfiles/actions/runs/30688921312) succeeded, including macos-15 and macos-26.

This proves the committed hosted CI path at that SHA. It does not establish skipped optional installer paths or general fresh-machine reproducibility; later changes require their own validation.

Representative local gates, run from the repository root:

```bash
bash -n install.sh install_packages.sh restore.sh lib_sh/*.sh scripts/*.sh \
  homedir/.profile homedir/.shellvars homedir/.shellpaths
shellcheck --severity=error --shell=bash --exclude=SC1090,SC1091,SC1087 \
  install.sh install_packages.sh restore.sh lib_sh/*.sh scripts/*.sh
./install_packages.sh --check ./software private
./install_packages.sh --check ./software combined
ruby -ryaml -e 'ARGV.each { |file| YAML.load_file(file, aliases: true) }' \
  .github/workflows/*.yml
./scripts/verify_folder_contracts.sh
git diff --check
```

Also run the exact extracted drift fixture above when package/drift code or its CI contract changes. Run full bootstrap only with
explicit awareness of its machine-changing behavior.

## 8. Operational workflow

1. Use Beads for durable work: `bd prime`, `bd show <id>`, then `bd update <id> --claim`.
2. Preserve unrelated working-tree changes. Stage and commit only explicit paths.
3. Run the narrowest relevant validation first, then broader gates justified by the change.
4. Commit completed work before closing its Bead. Never close a Bead while its implementation is uncommitted.
5. Do not commit, push, or synchronize Beads unless the current user/session explicitly authorizes it.
6. Report exactly what ran, what passed, what failed, and what remains unverified.

## 9. Open work under epic `dotfiles-ftf`

| Bead | Open work |
|---|---|
| `dotfiles-ftf.16` | Add explicit installer profile selection and continue installer hardening. |
| `dotfiles-ftf.2` | Evaluate Nix/nix-darwin/home-manager; no adoption decision has been made. |
| `dotfiles-ftf.17` | Reconcile private app and editor drift. |

## 10. Key file map

- **Overview:** [README](../../README.md) and [rework-plan.md](../../rework-plan.md).
- **Agent policy:** [AGENTS.md](../../AGENTS.md) and [CLAUDE.md](../../CLAUDE.md).
- **Installer:** [install.sh](../../install.sh) and [restore.sh](../../restore.sh).
- **Package engine:** [install_packages.sh](../../install_packages.sh) and [requirers.sh](../../lib_sh/requirers.sh).
- **Package policy:** [software/README.md](../../software/README.md), [bootstrap.list](../../software/bootstrap.list), and
  [tap.list](../../software/tap.list).
- **Shell:** [.zshenv](../../homedir/.zshenv), [.zprofile](../../homedir/.zprofile), [.profile](../../homedir/.profile),
  [.shellpaths](../../homedir/.shellpaths), and [.zshrc](../../homedir/.zshrc).
- **Stow/commands:** [verify_folder_contracts.sh](../../scripts/verify_folder_contracts.sh) and
  [regen_completions.sh](../../scripts/regen_completions.sh).
- **CI:** [syntax-gate.yml](../../.github/workflows/syntax-gate.yml),
  [reliability-gates.yml](../../.github/workflows/reliability-gates.yml), and
  [bootstrap.yml](../../.github/workflows/bootstrap.yml).
