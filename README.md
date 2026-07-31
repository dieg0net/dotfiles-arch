# 󱔐 Understory

<p align="center">
  <em>A quiet Arch Linux rice inspired by dark timber, forest floors, and the green that grows underneath.</em>
</p>

<p align="center">
  <img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-181B16?style=for-the-badge&logo=archlinux&logoColor=8EAD73">
  <img alt="Hyprland" src="https://img.shields.io/badge/Hyprland-20251D?style=for-the-badge&logo=wayland&logoColor=89B49B">
  <img alt="Chezmoi" src="https://img.shields.io/badge/Chezmoi-4A3829?style=for-the-badge&logo=gnu-bash&logoColor=D8D2C4">
</p>

![Understory desktop](assets/screenshots/desktop.png)

## The rice

Understory is cohesive before it is flashy. One earthy palette flows through
the compositor, terminal, launcher, editor, notifications, lock screen, OSD,
GTK applications, and KDE applications.

| Layer | Choice |
| --- | --- |
| Compositor | Hyprland 0.56+ using the modern Lua API |
| Bar | Waybar with workspaces, privacy capture, media, power, and Mako state |
| Launcher | Vicinae |
| Terminal | Kitty + JetBrainsMono Nerd Font |
| Shell | Bash + Starship |
| Editor | LazyVim / Neovim |
| Notifications | Mako |
| OSD | SwayOSD |
| Files | Dolphin + Gwenview + Okular |
| Clipboard | Clipse |
| Dotfiles | Chezmoi |

<table>
  <tr>
    <td width="50%"><img alt="Understory Vicinae launcher" src="assets/screenshots/launcher.png"></td>
    <td width="50%"><img alt="Understory LazyVim editor" src="assets/screenshots/editor.png"></td>
  </tr>
  <tr>
    <td align="center"><sub>Vicinae command palette</sub></td>
    <td align="center"><sub>LazyVim with the shared palette</sub></td>
  </tr>
</table>

## Small details

- `Super + D` opens the launcher.
- `Super + V` opens searchable text and image clipboard history.
- `Super + Shift + S` selects an area and copies it without creating a file.
- Volume left-click opens the mixer; middle-click mutes; right-click chooses an output.
- Waybar shows microphone and screen-sharing capture only while active.
- Idle behavior dims, locks, powers off the panel, then suspends only on battery.
- The wallpaper and every color-bearing configuration are included.

## Install

> [!IMPORTANT]
> This is an opinionated post-install for Arch Linux, not an unattended OS
> installer. Read the script before running it and start from a working user
> account with `sudo` access.

```bash
git clone https://github.com/dieg0net/dotfiles-arch.git
cd dotfiles-arch
./install.sh --category desktop --category audio
```

For only the managed files on an already configured system:

```bash
chezmoi init --apply dieg0net
```

Preview the installer without changing anything:

```bash
./install.sh --dry-run --category desktop --category audio --non-interactive
```

The installer remains category-driven, so development, creator, gaming,
virtualization, and security tools stay optional. Run `./install.sh
--list-categories` for the complete catalog. The original pre-Understory
installer is preserved at `scripts/glow-up-arch.sh`.

## Layout

```text
dot_config/              application configuration managed by Chezmoi
dot_local/bin/           small desktop helpers
Pictures/Wallpapers/     the Understory wallpaper
assets/screenshots/      repository showcase images
install.sh               interactive Arch post-install
packages.txt             concise package reference
```

The Framework Laptop display declaration is near the top of
`dot_config/hypr/hyprland.lua`; change the output, resolution, refresh rate, or
scale for another machine.

## Palette

| Role | Hex |
| --- | --- |
| Forest black | `#181B16` |
| Bark surface | `#20251D` |
| Moss | `#66845A` |
| New growth | `#8EAD73` |
| Dark wood | `#4A3829` |
| Warm wood | `#A47B50` |
| Linen | `#D8D2C4` |

## Privacy

Browser profiles, GitHub authentication, clipboard contents, shell history,
cookies, application databases, and caches are deliberately excluded. The
repository contains configuration—not personal state.
