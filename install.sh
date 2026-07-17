#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/dieg0net/dotfiles-arch.git}"
APPLY_DOTFILES="${APPLY_DOTFILES:-yes}"
RUN_AUR="${RUN_AUR:-yes}"
RUN_FLATPAK="${RUN_FLATPAK:-yes}"
RUN_VIRT="${RUN_VIRT:-yes}"
DNS_MODE="${DNS_MODE:-ask}"
DNS_SERVERS="${DNS_SERVERS:-1.1.1.1 9.9.9.9}"
NM_CONNECTION="${NM_CONNECTION:-}"
PRESET="${PRESET:-}"
INTERACTIVE="${INTERACTIVE:-auto}"
TARGET_USER="${SUDO_USER:-${USER:-}}"

SELECT_DESKTOP="no"
SELECT_YAZI="no"
SELECT_DEV="no"
SELECT_CREATOR="no"
SELECT_GAMING="no"
SELECT_VIRT="no"
SELECT_PRIVACY="no"
SELECT_FLATPAKS="no"

BASE_PACKAGES=(
    7zip
    base-devel
    chezmoi
    fastfetch
    fd
    fzf
    git
    htop
    jq
    neovim
    net-tools
    ripgrep
    zoxide
)

DESKTOP_PACKAGES=(
    brightnessctl
    dolphin
    grim
    hyprland
    hyprlock
    kitty
    mako
    network-manager-applet
    pavucontrol
    pipewire
    pipewire-alsa
    pipewire-pulse
    playerctl
    slurp
    ttf-jetbrains-mono-nerd
    waybar
    wireplumber
    wl-clipboard
    wofi
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
)

YAZI_PACKAGES=(
    chafa
    ffmpeg
    ffmpegthumbnailer
    imagemagick
    poppler
    resvg
    yazi
)

DEV_PACKAGES=(
    github-cli
    go
    nodejs
    npm
    python
    python-pip
    rustup
)

CREATOR_PACKAGES=(
    gimp
    inkscape
)

GAMING_PACKAGES=(
    gamescope
    mangohud
    wine
    winetricks
)

VIRT_PACKAGES=(
    bridge-utils
    dnsmasq
    edk2-ovmf
    qemu-full
    virt-manager
)

PRIVACY_PACKAGES=(
    ufw
)

AUR_MEDIA_PACKAGES=(
    kew-git
)

AUR_PRIVACY_PACKAGES=(
    librewolf-bin
)

FLATPAK_BASE_APPS=(
    md.obsidian.Obsidian
)

FLATPAK_CREATOR_APPS=(
    com.obsproject.Studio
    org.kde.kdenlive
)

FLATPAK_GAMING_APPS=(
    com.usebottles.bottles
    com.valvesoftware.Steam
)

PACMAN_PACKAGES=()
AUR_PACKAGES=()
FLATPAK_APPS=()

log() {
    printf '\n==> %s\n' "$*"
}

warn() {
    printf '\nWARN: %s\n' "$*" >&2
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_yes() {
    [[ "$1" == "yes" || "$1" == "true" || "$1" == "1" ]]
}

contains() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done

    return 1
}

append_unique() {
    local target_name="$1"
    shift

    local -n target="$target_name"
    local item
    for item in "$@"; do
        contains "$item" "${target[@]}" || target+=("$item")
    done
}

usage() {
    printf '%s\n' \
        "Usage: $0 [options]" \
        "" \
        "Options:" \
        "  --preset NAME       Use a preset: minimal, desktop, creator, gaming, virt, full" \
        "  --list-presets      Show available presets and exit" \
        "  --repo URL          Dotfiles repo for chezmoi (default: $DOTFILES_REPO)" \
        "  --ssh               Use the SSH GitHub repo URL for chezmoi" \
        "  --non-interactive   Do not prompt; uses --preset or desktop by default" \
        "  --skip-dotfiles     Install chezmoi but do not run chezmoi init/update" \
        "  --skip-aur          Skip paru and AUR package installation" \
        "  --skip-flatpak      Skip Flatpak remote/app installation" \
        "  --skip-virt         Skip libvirt/virt-manager service setup" \
        "  --set-dns           Configure NetworkManager DNS without prompting" \
        "  --no-dns            Skip NetworkManager DNS configuration" \
        "  -h, --help          Show this help message" \
        "" \
        "Environment overrides:" \
        "  DOTFILES_REPO, APPLY_DOTFILES, RUN_AUR, RUN_FLATPAK, RUN_VIRT," \
        "  DNS_MODE, DNS_SERVERS, NM_CONNECTION, PRESET, INTERACTIVE"
}

list_presets() {
    printf '%s\n' \
        "Available presets:" \
        "  minimal   Base CLI tools, chezmoi, and dotfiles" \
        "  desktop   Minimal plus Hyprland desktop, audio, clipboard, launcher, and Yazi" \
        "  creator   Desktop plus creator packages and OBS/Kdenlive Flatpaks" \
        "  gaming    Desktop plus gaming helpers, Steam, and Bottles" \
        "  virt      Desktop plus QEMU, virt-manager, and libvirt setup" \
        "  full      Everything this installer knows how to set up"
}

parse_args() {
    while (($#)); do
        case "$1" in
            --preset)
                [[ $# -ge 2 ]] || die "--preset requires a preset name"
                PRESET="$2"
                shift 2
                ;;
            --minimal)
                PRESET="minimal"
                shift
                ;;
            --desktop)
                PRESET="desktop"
                shift
                ;;
            --full)
                PRESET="full"
                shift
                ;;
            --list-presets|--list-profiles)
                list_presets
                exit 0
                ;;
            --repo)
                [[ $# -ge 2 ]] || die "--repo requires a URL"
                DOTFILES_REPO="$2"
                shift 2
                ;;
            --ssh)
                DOTFILES_REPO="git@github.com:dieg0net/dotfiles-arch.git"
                shift
                ;;
            --non-interactive)
                INTERACTIVE="no"
                shift
                ;;
            --skip-dotfiles)
                APPLY_DOTFILES="no"
                shift
                ;;
            --skip-aur)
                RUN_AUR="no"
                shift
                ;;
            --skip-flatpak)
                RUN_FLATPAK="no"
                shift
                ;;
            --skip-virt)
                RUN_VIRT="no"
                shift
                ;;
            --set-dns)
                DNS_MODE="yes"
                shift
                ;;
            --no-dns)
                DNS_MODE="no"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

require_arch_linux() {
    [[ -r /etc/arch-release ]] || die "This installer is intended for Arch Linux."
    (( EUID != 0 )) || die "Run this as your normal user. The script uses sudo when needed."
}

resolve_target_user() {
    [[ -n "$TARGET_USER" ]] || TARGET_USER="$(id -un)"
}

use_interactive_mode() {
    [[ "$INTERACTIVE" == "yes" ]] && return 0
    [[ "$INTERACTIVE" == "no" ]] && return 1
    [[ -t 0 ]]
}

enable_desktop() {
    SELECT_DESKTOP="yes"
    SELECT_YAZI="yes"
    SELECT_FLATPAKS="yes"
}

set_preset() {
    local preset="$1"

    SELECT_DESKTOP="no"
    SELECT_YAZI="no"
    SELECT_DEV="no"
    SELECT_CREATOR="no"
    SELECT_GAMING="no"
    SELECT_VIRT="no"
    SELECT_PRIVACY="no"
    SELECT_FLATPAKS="no"

    case "$preset" in
        minimal)
            ;;
        desktop)
            enable_desktop
            SELECT_PRIVACY="yes"
            ;;
        creator)
            enable_desktop
            SELECT_CREATOR="yes"
            SELECT_PRIVACY="yes"
            ;;
        gaming)
            enable_desktop
            SELECT_GAMING="yes"
            SELECT_PRIVACY="yes"
            ;;
        virt|virtualization)
            enable_desktop
            SELECT_VIRT="yes"
            SELECT_PRIVACY="yes"
            PRESET="virt"
            ;;
        full)
            enable_desktop
            SELECT_DEV="yes"
            SELECT_CREATOR="yes"
            SELECT_GAMING="yes"
            SELECT_VIRT="yes"
            SELECT_PRIVACY="yes"
            ;;
        *)
            die "Unknown preset: $preset"
            ;;
    esac
}

ask_yes_no() {
    local prompt="$1"
    local default="$2"
    local reply suffix

    if is_yes "$default"; then
        suffix="[Y/n]"
    else
        suffix="[y/N]"
    fi

    read -r -p "$prompt $suffix " reply
    [[ -z "$reply" ]] && reply="$default"

    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

prompt_for_preset() {
    printf '%s\n' \
        "" \
        "Choose an install preset:" \
        "  1) minimal  - Base CLI tools, chezmoi, and dotfiles" \
        "  2) desktop  - Hyprland desktop, audio, Yazi, Flatpak basics" \
        "  3) creator  - Desktop plus creative apps" \
        "  4) gaming   - Desktop plus gaming apps" \
        "  5) virt     - Desktop plus QEMU/libvirt" \
        "  6) full     - Everything"

    local choice
    read -r -p "Preset [2]: " choice
    case "${choice:-2}" in
        1|minimal) PRESET="minimal" ;;
        2|desktop) PRESET="desktop" ;;
        3|creator) PRESET="creator" ;;
        4|gaming) PRESET="gaming" ;;
        5|virt|virtualization) PRESET="virt" ;;
        6|full) PRESET="full" ;;
        *) die "Unknown preset selection: $choice" ;;
    esac
}

customize_install() {
    ask_yes_no "Customize package groups?" "no" || return 0

    ask_yes_no "Install Hyprland desktop stack?" "$SELECT_DESKTOP" && SELECT_DESKTOP="yes" || SELECT_DESKTOP="no"
    ask_yes_no "Install Yazi and preview tools?" "$SELECT_YAZI" && SELECT_YAZI="yes" || SELECT_YAZI="no"
    ask_yes_no "Install development tools?" "$SELECT_DEV" && SELECT_DEV="yes" || SELECT_DEV="no"
    ask_yes_no "Install creator tools and media Flatpaks?" "$SELECT_CREATOR" && SELECT_CREATOR="yes" || SELECT_CREATOR="no"
    ask_yes_no "Install gaming tools and gaming Flatpaks?" "$SELECT_GAMING" && SELECT_GAMING="yes" || SELECT_GAMING="no"
    ask_yes_no "Install virtualization tools?" "$SELECT_VIRT" && SELECT_VIRT="yes" || SELECT_VIRT="no"
    ask_yes_no "Install privacy/security extras?" "$SELECT_PRIVACY" && SELECT_PRIVACY="yes" || SELECT_PRIVACY="no"
    ask_yes_no "Install Flatpak app bundle?" "$SELECT_FLATPAKS" && SELECT_FLATPAKS="yes" || SELECT_FLATPAKS="no"
}

choose_install_shape() {
    if [[ -z "$PRESET" ]]; then
        if use_interactive_mode; then
            prompt_for_preset
        else
            PRESET="desktop"
            warn "No preset provided and stdin is not interactive. Using desktop preset."
        fi
    fi

    set_preset "$PRESET"

    if use_interactive_mode; then
        customize_install
    fi
}

build_package_lists() {
    PACMAN_PACKAGES=()
    AUR_PACKAGES=()
    FLATPAK_APPS=()

    append_unique PACMAN_PACKAGES "${BASE_PACKAGES[@]}"

    is_yes "$SELECT_DESKTOP" && append_unique PACMAN_PACKAGES "${DESKTOP_PACKAGES[@]}"
    is_yes "$SELECT_YAZI" && append_unique PACMAN_PACKAGES "${YAZI_PACKAGES[@]}"
    is_yes "$SELECT_DEV" && append_unique PACMAN_PACKAGES "${DEV_PACKAGES[@]}"
    is_yes "$SELECT_CREATOR" && append_unique PACMAN_PACKAGES "${CREATOR_PACKAGES[@]}"
    is_yes "$SELECT_GAMING" && append_unique PACMAN_PACKAGES "${GAMING_PACKAGES[@]}"
    is_yes "$SELECT_VIRT" && append_unique PACMAN_PACKAGES "${VIRT_PACKAGES[@]}"
    is_yes "$SELECT_PRIVACY" && append_unique PACMAN_PACKAGES "${PRIVACY_PACKAGES[@]}"

    if is_yes "$RUN_FLATPAK" && { is_yes "$SELECT_FLATPAKS" || is_yes "$SELECT_CREATOR" || is_yes "$SELECT_GAMING"; }; then
        append_unique PACMAN_PACKAGES flatpak flatseal
        append_unique FLATPAK_APPS "${FLATPAK_BASE_APPS[@]}"
    fi

    is_yes "$SELECT_YAZI" && append_unique AUR_PACKAGES "${AUR_MEDIA_PACKAGES[@]}"
    is_yes "$SELECT_PRIVACY" && append_unique AUR_PACKAGES "${AUR_PRIVACY_PACKAGES[@]}"

    is_yes "$SELECT_CREATOR" && append_unique FLATPAK_APPS "${FLATPAK_CREATOR_APPS[@]}"
    is_yes "$SELECT_GAMING" && append_unique FLATPAK_APPS "${FLATPAK_GAMING_APPS[@]}"

    if ! is_yes "$RUN_AUR"; then
        AUR_PACKAGES=()
    fi

    if ! is_yes "$RUN_FLATPAK"; then
        FLATPAK_APPS=()
    fi
}

print_config() {
    log "Install configuration"
    printf 'Preset: %s\n' "$PRESET"
    printf 'Dotfiles repo: %s\n' "$DOTFILES_REPO"
    printf 'Apply dotfiles: %s\n' "$APPLY_DOTFILES"
    printf 'Desktop stack: %s\n' "$SELECT_DESKTOP"
    printf 'Yazi tools: %s\n' "$SELECT_YAZI"
    printf 'Development tools: %s\n' "$SELECT_DEV"
    printf 'Creator tools: %s\n' "$SELECT_CREATOR"
    printf 'Gaming tools: %s\n' "$SELECT_GAMING"
    printf 'Virtualization tools: %s\n' "$SELECT_VIRT"
    printf 'Privacy extras: %s\n' "$SELECT_PRIVACY"
    printf 'Flatpak apps: %s\n' "$RUN_FLATPAK"
    printf 'DNS mode: %s\n' "$DNS_MODE"
    printf 'Pacman packages: %s\n' "${#PACMAN_PACKAGES[@]}"
    printf 'AUR packages: %s\n' "${#AUR_PACKAGES[@]}"
    printf 'Flatpak apps selected: %s\n' "${#FLATPAK_APPS[@]}"
}

confirm_install() {
    if ! use_interactive_mode; then
        return 0
    fi

    ask_yes_no "Continue with this install?" "yes" || die "Install cancelled."
}

create_home_directories() {
    log "Creating common home directories"
    mkdir -p \
        "$HOME/Documents" \
        "$HOME/Downloads" \
        "$HOME/Music" \
        "$HOME/Pictures" \
        "$HOME/Videos"
}

install_pacman_packages() {
    log "Updating Arch packages"
    sudo pacman -Syu --noconfirm

    log "Installing Pacman package groups"
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

install_paru() {
    if command_exists paru; then
        log "paru is already installed"
        return
    fi

    local build_dir
    build_dir="$(mktemp -d -t paru-build.XXXXXXXX)"

    log "Installing paru from the AUR"
    git clone https://aur.archlinux.org/paru.git "$build_dir"
    (
        cd "$build_dir"
        makepkg -si --noconfirm
    )
    rm -rf "$build_dir"
}

install_aur_packages() {
    if ((${#AUR_PACKAGES[@]} == 0)); then
        log "Skipping AUR packages"
        return
    fi

    install_paru

    log "Installing AUR packages"
    paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

install_flatpak_apps() {
    if ((${#FLATPAK_APPS[@]} == 0)); then
        log "Skipping Flatpak apps"
        return
    fi

    log "Configuring Flathub"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    log "Installing Flatpak apps"
    flatpak install -y --or-update flathub "${FLATPAK_APPS[@]}"
}

apply_dotfiles() {
    if ! is_yes "$APPLY_DOTFILES"; then
        log "Skipping chezmoi dotfile apply"
        return
    fi

    local source_dir
    source_dir="$(chezmoi source-path 2>/dev/null || true)"

    if [[ -n "$source_dir" && -d "$source_dir/.git" ]]; then
        log "Updating existing chezmoi source"
        chezmoi update --apply
    else
        log "Initializing chezmoi from $DOTFILES_REPO"
        chezmoi init --apply "$DOTFILES_REPO"
    fi
}

setup_virtualization() {
    if ! is_yes "$SELECT_VIRT" || ! is_yes "$RUN_VIRT"; then
        log "Skipping virtualization setup"
        return
    fi

    log "Configuring libvirt"
    sudo usermod -aG libvirt "$TARGET_USER"
    sudo systemctl enable --now libvirtd.service
    warn "Log out and back in before using virt-manager so the libvirt group change takes effect."
}

configure_dns() {
    case "$DNS_MODE" in
        yes|ask|no) ;;
        *) die "DNS_MODE must be yes, ask, or no" ;;
    esac

    if [[ "$DNS_MODE" == "no" ]]; then
        log "Skipping DNS configuration"
        return
    fi

    if [[ "$DNS_MODE" == "ask" ]]; then
        if ! use_interactive_mode; then
            warn "Skipping DNS configuration because stdin is not interactive. Use --set-dns to force it."
            return
        fi

        ask_yes_no "Set NetworkManager DNS to ${DNS_SERVERS}?" "no" || {
            log "Skipping DNS configuration"
            return
        }
    fi

    if ! command_exists nmcli; then
        warn "nmcli was not found. Skipping DNS configuration."
        return
    fi

    local connection="$NM_CONNECTION"
    if [[ -z "$connection" ]]; then
        connection="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2 == "ethernet" { print $1; exit }' || true)"
    fi

    if [[ -z "$connection" ]]; then
        connection="$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n 1 || true)"
    fi

    if [[ -z "$connection" ]]; then
        warn "No active NetworkManager connection found. Skipping DNS configuration."
        return
    fi

    log "Setting DNS on NetworkManager connection: $connection"
    sudo nmcli connection modify "$connection" ipv4.ignore-auto-dns yes ipv4.dns "$DNS_SERVERS"
    sudo nmcli connection down "$connection" >/dev/null 2>&1 || true
    sudo nmcli connection up "$connection"
}

main() {
    parse_args "$@"
    require_arch_linux
    resolve_target_user
    choose_install_shape
    build_package_lists
    print_config
    confirm_install
    sudo -v

    create_home_directories
    install_pacman_packages
    install_aur_packages
    install_flatpak_apps
    apply_dotfiles
    setup_virtualization
    configure_dns

    log "Arch setup complete"
}

main "$@"
