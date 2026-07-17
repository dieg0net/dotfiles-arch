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
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

PACMAN_PACKAGES=(
    base-devel
    chezmoi
    dolphin
    dnsmasq
    fd
    fastfetch
    flatpak
    flatseal
    ffmpegthumbnailer
    fzf
    git
    htop
    hyprlock
    imagemagick
    jq
    neovim
    net-tools
    7zip
    poppler
    qemu-full
    ripgrep
    ttf-jetbrains-mono-nerd
    virt-manager
    wine
    winetricks
    xdg-desktop-portal-hyprland
    yazi
    zoxide
)

AUR_PACKAGES=(
    kew-git
    librewolf-bin
)

FLATPAK_APPS=(
    com.obsproject.Studio
    com.usebottles.bottles
    com.valvesoftware.Steam
    md.obsidian.Obsidian
    org.kde.kdenlive
)

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

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --repo URL          Dotfiles repo for chezmoi (default: $DOTFILES_REPO)
  --ssh              Use the SSH GitHub repo URL for chezmoi
  --skip-dotfiles    Install chezmoi but do not run chezmoi init/update
  --skip-aur         Skip paru and AUR package installation
  --skip-flatpak     Skip Flatpak remote/app installation
  --skip-virt        Skip libvirt/virt-manager service setup
  --set-dns          Configure NetworkManager DNS without prompting
  --no-dns           Skip NetworkManager DNS configuration
  -h, --help         Show this help message

Environment overrides:
  DOTFILES_REPO, APPLY_DOTFILES, RUN_AUR, RUN_FLATPAK, RUN_VIRT,
  DNS_MODE, DNS_SERVERS, NM_CONNECTION
EOF
}

parse_args() {
    while (($#)); do
        case "$1" in
            --repo)
                [[ $# -ge 2 ]] || die "--repo requires a URL"
                DOTFILES_REPO="$2"
                shift 2
                ;;
            --ssh)
                DOTFILES_REPO="git@github.com:dieg0net/dotfiles-arch.git"
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

print_config() {
    log "Install configuration"
    printf 'Dotfiles repo: %s\n' "$DOTFILES_REPO"
    printf 'Apply dotfiles: %s\n' "$APPLY_DOTFILES"
    printf 'Install AUR packages: %s\n' "$RUN_AUR"
    printf 'Install Flatpaks: %s\n' "$RUN_FLATPAK"
    printf 'Setup virtualization: %s\n' "$RUN_VIRT"
    printf 'DNS mode: %s\n' "$DNS_MODE"
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

    log "Installing Pacman packages"
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
    if ! is_yes "$RUN_AUR"; then
        log "Skipping AUR packages"
        return
    fi

    install_paru

    log "Installing AUR packages"
    paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

install_flatpak_apps() {
    if ! is_yes "$RUN_FLATPAK"; then
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
    if ! is_yes "$RUN_VIRT"; then
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
        if [[ ! -t 0 ]]; then
            warn "Skipping DNS configuration because stdin is not interactive. Use --set-dns to force it."
            return
        fi

        local reply
        read -r -p "Set NetworkManager DNS to ${DNS_SERVERS}? [y/N] " reply
        if [[ ! "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            log "Skipping DNS configuration"
            return
        fi
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
    sudo -v

    print_config
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
