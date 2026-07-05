# dotfiles

macOS and Linux dotfiles with a profile-driven installer, package manifest, stow-managed files, and modular macOS defaults.

## Quick Start

Review `install.sh` before running it on a new machine.

```bash
git clone https://github.com/<user>/<repo> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The first run is interactive and asks which machine profile to use. Later runs reuse the selected profile unless you pass `--profile=NAME`.

## Architecture

```text
dotfiles/
├── lib/              # Modular installer scripts (bootstrap, packages, stow, ...)
├── machines/         # Machine profiles (personal-mac.yaml, work-mac.yaml, ...)
├── packages.yaml     # Single package manifest (brew, cask, mas, npm, gem, apt)
├── macos/            # Modular macOS defaults (dock, finder, keyboard, ...)
├── homedir-common/   # Dotfiles -> $HOME (all platforms)
├── homedir-darwin/   # Dotfiles -> $HOME (macOS only)
├── homedir-linux/    # Dotfiles -> $HOME (Linux only)
├── configs/          # Configs -> ~/.config (all platforms)
├── configs-darwin/   # Configs -> ~/.config (macOS only)
├── scripts/          # Utilities -> ~/.local/bin
├── install.sh        # Slim orchestrator
└── migrate.sh        # Migration from old structure
```

Installer modules live in `lib/`: `antidote.sh`, `bootstrap.sh`, `macos-defaults.sh`, `packages.sh`, `profile.sh`, `stow.sh`, and `utils.sh`.

macOS defaults are split by concern in `macos/`, including Dock, Finder, keyboard, Safari, screenshots, security, and trackpad settings.

## Adding a Package

Edit `packages.yaml` once. Put the package under the role and category that should install it.

```yaml
roles:
  common:
    cli:
      - name: ripgrep
```

Package roles are additive. Categories include `cli`, `gui`, `fonts`, `language`, `dev`, `mas`, `npm`, and `gem`; package methods include `brew`, `cask`, `apt`, `snap`, `flatpak`, `mas`, `npm`, and `gem`.

Then run:

```bash
./install.sh
```

## Adding a Dotfile

Choose the target by where the file should land:

```text
homedir-common/  -> $HOME on every platform
homedir-darwin/  -> $HOME on macOS
homedir-linux/   -> $HOME on Linux
configs/         -> ~/.config on every platform
configs-darwin/  -> ~/.config on macOS
```

Add the file, commit it, then re-run `./install.sh`. Existing dotfiles are backed up under `~/.dotfiles_backup/` before stow replaces them.

## Machine Profiles

Profiles live in `machines/`:

```text
personal-mac.yaml
work-mac.yaml
linux-dev.yaml
```

Each profile sets the hostname, git identity, and package roles such as `common`, `development`, `private`, or `business`. Roles combine, so a work laptop can install the common base plus work-only tools.

Run a specific profile with:

```bash
./install.sh --profile=work-mac
```

## CLI Flags

| Flag | Use |
| --- | --- |
| `-h`, `--help` | Show installer help. |
| `--dry-run` | Print planned actions without installing or changing state. |
| `--skip-packages` | Skip package installation. |
| `--skip-defaults` | Skip macOS defaults. |
| `--profile=NAME` | Use `machines/NAME.yaml`, `NAME`, or a profile path. |
| `--profile NAME` | Same as `--profile=NAME`. |

## Migration

Switching from the old layout? Run the migration first:

```bash
./migrate.sh
```

After migration, inspect the moved files, run `./install.sh --dry-run`, then run `./install.sh` when the plan looks right.
