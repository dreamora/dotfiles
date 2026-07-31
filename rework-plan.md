# Dotfiles Rework Plan

## Status

This document was created during the initial planning phase and some items have
been resolved. It is kept as a reference for remaining architectural questions.
Completed decisions are marked **[done]**; rejected approaches are marked
**[rejected]**.

## Value

The dotfiles should represent the current productive setup while staying usable
across two recurring environments:

- Software engineering machines: private or work macOS laptops and desktops.
- AI nodes: Mac mini or Mac Studio machines on macOS, plus remote Linux
  containers across different distributions.

The goal is to simplify the repository and make it more generally reusable.

## Inventory

1. Review all Brew, gem, npm global, pip global, and MAS packages — **[done]**
   consolidated into `software/*.list` manifests.
2. Decide which packages are still actively needed — ongoing.
3. Identify packages that can be replaced by more autonomous open-source
   alternatives, such as Docker to Podman or local Kubernetes alternatives.
4. Identify services that should move out of the workstation setup and into the
   NAS container manager through Docker Compose.

## Config Layout

- Move tools that support `~/.config` into the repository `config/` folder —
  **[done]** (Starship, mise).
- Keep app folders such as `nvim` and `tmux` linkable as individual config targets.
- Evaluate GNU Stow, `tuckr`, or a similar tool — **[done]** Stow kept.

## Shell

Oh My Zsh was heavy and created friction with Git-related shell behavior.
**[done]** — OMZ removed, replaced by hand-rolled ~80-line `.zshrc` + Starship
prompt. See the shell modernization history entry in HISTORY.md.

## Packages

~~Prefer Brewfiles where possible~~ — **[rejected]**. The repo uses
`software/*.list` files with profile overlays (common / private / business)
instead. This approach is simpler, more reviewable, and avoids Brewfile's
limitations with non-brew dependencies (mas, npm -g, VS Code extensions).

For packages not available through Homebrew, the `.list` manifest system
handles mas, npm, gem, and VS Code extensions natively. No separate
`packages.json` needed — **[rejected]**.

### Remaining challenge

The provisioning layer still spans 7 dependency managers: Homebrew, mas, npm
globals, gems, curl installers, pip, and VS Code extensions. mise consolidated
runtimes (Node.js, Python, Bun) but doesn't cover system packages. Evaluating
[Nix](https://nixos.org) / nix-darwin / home-manager as a potential single
source of truth is still open — see the `bd` task `dotfiles-ftf.2`.

## Coding

Slim the primary coding surface area:

- Zed — primary macOS editor
- Neovim — terminal editor via LazyVim
- Environment-specific JetBrains IDEs when valuable, such as Rider for C# or
  DataSpell for SQL and data workflows.