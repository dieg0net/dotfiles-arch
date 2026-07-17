# Glow Up Arch

An opinionated Arch Linux bootstrap that turns a minimal install into a personalized desktop.

This is not a full ISO yet. Think of it as the first step toward a tiny distro: install Arch, boot into your new system, then run one script that lets you choose exactly which apps and bundles you want.

## What It Does

- Installs a clean base set of CLI tools and `chezmoi`.
- Uses [chezmoi](https://www.chezmoi.io/) to manage and apply dotfiles.
- Lets you pick optional apps from categories instead of forcing a profile.
- Supports interactive installs for fresh machines.
- Supports unattended installs with category and app keys.
- Keeps risky system changes, like DNS, explicit instead of hidden.

## Quick Start

After a successful minimal Arch install, log in as your normal user with sudo access, then run:

```bash
cd /tmp
curl -fsSLO https://raw.githubusercontent.com/dieg0net/dotfiles-arch/main/install.sh
chmod +x install.sh
./install.sh
```

The installer always installs the base tools. After that, it walks through categories and lets you choose optional apps by number, key, `all`, or Enter for none.

## Categories

| Category | Key | Examples |
| --- | --- | --- |
| Desktop & Wayland | `desktop` | Hyprland, Waybar, Wofi, Kitty, Dolphin, screenshots, fonts |
| Audio | `audio` | PipeWire, Pavucontrol |
| Terminal & Files | `terminal` | Yazi, preview helpers, Kew |
| Browsers & Notes | `browsers` | LibreWolf, Obsidian |
| Development | `development` | GitHub CLI, Go, Node.js, Python, Rust |
| Creator Apps | `creative` | GIMP, Inkscape, OBS, Kdenlive |
| Gaming | `gaming` | Steam, Bottles, Wine, Gamescope, MangoHud |
| Virtualization | `virtualization` | QEMU, libvirt, virt-manager |
| Privacy & Security | `security` | UFW package |

List the current categories and app keys:

```bash
./install.sh --list-categories
```

Preview an install plan without changing the system:

```bash
./install.sh --dry-run --category desktop --app steam --non-interactive
```

## Unattended Examples

Install only base tools and dotfiles:

```bash
./install.sh --minimal --non-interactive --no-dns
```

Install all optional apps:

```bash
./install.sh --all --non-interactive
```

Install a desktop plus development tools:

```bash
./install.sh --category desktop --category audio --category development --non-interactive
```

Install selected apps by key:

```bash
./install.sh --app hyprland --app waybar --app kitty --app librewolf --app obsidian
```

Install gaming apps but skip Flatpak apps:

```bash
./install.sh --category gaming --skip-flatpak --non-interactive
```

Use SSH for the dotfiles checkout:

```bash
./install.sh --category desktop --ssh
```

Use a different chezmoi source repo:

```bash
./install.sh --repo https://github.com/yourname/dotfiles.git
```

## Options

| Option | Description |
| --- | --- |
| `--all` | Select every optional app and bundle |
| `--minimal` | Install only base tools and dotfiles |
| `--category NAME` | Select every app in a category; repeatable |
| `--app KEY` | Select one app or bundle by key; repeatable |
| `--list-categories` | Show categories, app keys, and labels |
| `--dry-run` | Print the install plan without changing the system |
| `--non-interactive` | Skip prompts and use explicit selections |
| `--repo URL` | Override the chezmoi dotfiles repo |
| `--ssh` | Use `git@github.com:dieg0net/dotfiles-arch.git` for chezmoi |
| `--skip-dotfiles` | Install `chezmoi` but do not apply dotfiles |
| `--skip-aur` | Skip `paru` and AUR packages |
| `--skip-flatpak` | Skip Flatpak setup and Flatpak apps |
| `--skip-virt` | Skip libvirt service/group setup |
| `--set-dns` | Configure NetworkManager DNS without prompting |
| `--no-dns` | Skip DNS configuration |

## Environment Overrides

Every major installer choice can also be driven by environment variables:

```bash
INTERACTIVE=no DNS_MODE=no ./install.sh --category gaming
```

Supported variables:

```text
DOTFILES_REPO
APPLY_DOTFILES
RUN_AUR
RUN_FLATPAK
RUN_VIRT
DNS_MODE
DNS_SERVERS
NM_CONNECTION
INTERACTIVE
```

## Philosophy

Glow Up Arch should feel like a distro without taking away what makes Arch fun:

- Minimal first, personalized second.
- App choices over mystery profiles.
- Dotfiles managed as source, not copied by hand.
- Useful defaults that can still be skipped.
- One install path for fresh machines, rebuilds, and experiments.

## Roadmap

- More categories for laptops, audio production, and streaming.
- A proper TUI installer.
- Post-install health checks.
- Optional disk/bootstrap automation before the post-install script.
- Eventually, a real ISO or `archinstall` profile.
