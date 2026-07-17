# Glow Up Arch

An opinionated Arch Linux bootstrap that turns a minimal install into a personalized desktop.

This is not a full ISO yet. Think of it as the first step toward a tiny distro: install Arch, boot into your new system, then run one script that lets you choose the kind of machine you want.

## What It Does

- Installs a clean base set of CLI tools, fonts, and quality-of-life packages.
- Uses [chezmoi](https://www.chezmoi.io/) to manage and apply dotfiles.
- Offers install presets for desktop, creator, gaming, virtualization, and full setups.
- Supports interactive prompts for people installing by hand.
- Supports unattended installs with flags and environment variables.
- Keeps risky system changes, like DNS, explicit instead of hidden.

## Quick Start

After a successful minimal Arch install, log in as your normal user with sudo access, then run:

```bash
cd /tmp
curl -fsSLO https://raw.githubusercontent.com/dieg0net/dotfiles-arch/main/install.sh
chmod +x install.sh
./install.sh
```

The installer will ask which preset you want and whether you want to customize the selected package groups.

## Presets

| Preset | Best For | Includes |
| --- | --- | --- |
| `minimal` | Servers, shells, and very small installs | Base CLI tools, `chezmoi`, dotfiles |
| `desktop` | Daily Hyprland workstation | Minimal plus Hyprland, audio, launcher, clipboard, Yazi, Flatpak basics |
| `creator` | Video, notes, streaming, and design | Desktop plus creative tools, OBS, Kdenlive |
| `gaming` | Games and Windows app compatibility | Desktop plus Steam, Bottles, Wine helpers |
| `virt` | VM host machines | Desktop plus QEMU, virt-manager, libvirt setup |
| `full` | The whole Glow Up stack | Every package group in the installer |

List presets any time:

```bash
./install.sh --list-presets
```

## Unattended Examples

Run the desktop preset without prompts:

```bash
./install.sh --preset desktop --non-interactive
```

Install everything and configure DNS automatically:

```bash
./install.sh --preset full --non-interactive --set-dns
```

Install only the base tools and dotfiles:

```bash
./install.sh --preset minimal --non-interactive --skip-flatpak --skip-aur --no-dns
```

Use SSH for the dotfiles checkout:

```bash
./install.sh --preset desktop --ssh
```

Use a different chezmoi source repo:

```bash
./install.sh --repo https://github.com/yourname/dotfiles.git
```

## Options

| Option | Description |
| --- | --- |
| `--preset NAME` | Use `minimal`, `desktop`, `creator`, `gaming`, `virt`, or `full` |
| `--list-presets` | Print available presets and exit |
| `--non-interactive` | Skip prompts and use the selected preset |
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
PRESET=gaming INTERACTIVE=no DNS_MODE=no ./install.sh
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
PRESET
INTERACTIVE
```

## Philosophy

Glow Up Arch should feel like a distro without taking away what makes Arch fun:

- Minimal first, personalized second.
- Clear choices over mystery defaults.
- Dotfiles managed as source, not copied by hand.
- Useful defaults that can still be skipped.
- One install path for fresh machines, rebuilds, and experiments.

## Roadmap

- More package groups for laptops, audio production, and streaming.
- A proper TUI installer.
- Post-install health checks.
- Optional disk/bootstrap automation before the post-install script.
- Eventually, a real ISO or `archinstall` profile.
