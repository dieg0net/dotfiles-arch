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
INTERACTIVE="${INTERACTIVE:-auto}"
TARGET_USER="${SUDO_USER:-${USER:-}}"

SELECT_ALL="no"
MINIMAL_ONLY="no"
DRY_RUN="no"
NEEDS_VIRT_SETUP="no"
NEEDS_SDDM_SETUP="no"

BASE_PACKAGES=(
    7zip
    base-devel
    chezmoi
    fastfetch
    fd
    fzf
    git
    btop
    jq
    neovim
    net-tools
    pacman-contrib
    ripgrep
    zoxide
)

CATEGORY_SLUGS=()
CATEGORY_TITLES=()
ITEM_KEYS=()
ITEM_CATEGORIES=()
ITEM_LABELS=()
ITEM_PACMAN=()
ITEM_AUR=()
ITEM_FLATPAK=()
ITEM_POST=()

REQUESTED_CATEGORIES=()
REQUESTED_APPS=()
SELECTED_ITEMS=()
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
        [[ -z "$item" ]] && continue
        contains "$item" "${target[@]}" || target+=("$item")
    done
}

append_words() {
    local target_name="$1"
    shift

    local words word
    for words in "$@"; do
        for word in $words; do
            append_unique "$target_name" "$word"
        done
    done
}

add_category() {
    CATEGORY_SLUGS+=("$1")
    CATEGORY_TITLES+=("$2")
}

add_item() {
    ITEM_CATEGORIES+=("$1")
    ITEM_KEYS+=("$2")
    ITEM_LABELS+=("$3")
    ITEM_PACMAN+=("$4")
    ITEM_AUR+=("$5")
    ITEM_FLATPAK+=("$6")
    ITEM_POST+=("${7:-}")
}

define_catalog() {
    add_category "desktop" "Desktop & Wayland"
    add_item "desktop" "hyprland" "Hyprland session, themed login, lock screen, idle policy, wallpaper, portals, and authentication" "hyprland hyprpaper hypridle hyprlock hyprpolkitagent sddm xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland" "" "" "sddm"
    add_item "desktop" "waybar" "Waybar status bar (current Hyprland Lua protocol support)" "" "waybar-git" "" ""
    add_item "desktop" "vicinae" "Vicinae launcher and command palette" "" "vicinae-bin" "" ""
    add_item "desktop" "kitty" "Kitty terminal" "kitty" "" "" ""
    add_item "desktop" "dolphin" "Dolphin, imv, Gwenview, and Okular" "dolphin imv gwenview okular ark" "" "" ""
    add_item "desktop" "mako" "Mako notifications" "mako" "" "" ""
    add_item "desktop" "clipboard" "Screenshots and clipboard history" "grim slurp wl-clipboard" "clipse" "" ""
    add_item "desktop" "desktop-controls" "OSD, power profiles, brightness, media, Bluetooth, network, and audio controls" "swayosd brightnessctl power-profiles-daemon blueman network-manager-applet pavucontrol playerctl" "" "" ""
    add_item "desktop" "fonts" "JetBrainsMono Nerd Font" "ttf-jetbrains-mono-nerd" "" "" ""

    add_category "audio" "Audio"
    add_item "audio" "pipewire" "PipeWire audio stack" "pipewire pipewire-alsa pipewire-pulse wireplumber" "" "" ""
    add_item "audio" "pavucontrol" "PulseAudio volume control" "pavucontrol" "" "" ""

    add_category "terminal" "Terminal & Files"
    add_item "terminal" "yazi" "Yazi terminal file manager" "yazi" "" "" ""
    add_item "terminal" "yazi-preview" "Yazi preview helpers" "chafa ffmpeg ffmpegthumbnailer imagemagick poppler resvg" "" "" ""
    add_item "terminal" "kew" "Kew terminal music player" "" "kew-git" "" ""

    add_category "browsers" "Browsers & Notes"
    add_item "browsers" "librewolf" "LibreWolf browser" "" "librewolf-bin" "" ""
    add_item "browsers" "obsidian" "Obsidian notes" "" "" "md.obsidian.Obsidian" ""

    add_category "development" "Development"
    add_item "development" "github-cli" "GitHub CLI" "github-cli" "" "" ""
    add_item "development" "go" "Go toolchain" "go" "" "" ""
    add_item "development" "node" "Node.js and npm" "nodejs npm" "" "" ""
    add_item "development" "python" "Python and pip" "python python-pip" "" "" ""
    add_item "development" "rust" "Rustup" "rustup" "" "" ""

    add_category "creative" "Creator Apps"
    add_item "creative" "gimp" "GIMP image editor" "gimp" "" "" ""
    add_item "creative" "inkscape" "Inkscape vector editor" "inkscape" "" "" ""
    add_item "creative" "obs" "OBS Studio" "" "" "com.obsproject.Studio" ""
    add_item "creative" "kdenlive" "Kdenlive video editor" "" "" "org.kde.kdenlive" ""

    add_category "gaming" "Gaming"
    add_item "gaming" "steam" "Steam" "" "" "com.valvesoftware.Steam" ""
    add_item "gaming" "bottles" "Bottles" "" "" "com.usebottles.bottles" ""
    add_item "gaming" "wine" "Wine and Winetricks" "wine winetricks" "" "" ""
    add_item "gaming" "gamescope" "Gamescope and MangoHud" "gamescope mangohud" "" "" ""

    add_category "virtualization" "Virtualization"
    add_item "virtualization" "virt-manager" "QEMU, libvirt, and virt-manager" "bridge-utils dnsmasq edk2-ovmf qemu-full virt-manager" "" "" "virt"

    add_category "security" "Privacy & Security"
    add_item "security" "ufw" "UFW firewall package" "ufw" "" "" ""
}

usage() {
    printf '%s\n' \
        "Usage: $0 [options]" \
        "" \
        "Options:" \
        "  --all                 Select every optional app and bundle" \
        "  --minimal             Install only base tools and dotfiles" \
        "  --category NAME       Select every app in a category; repeatable" \
        "  --app KEY             Select one app or bundle by key; repeatable" \
        "  --list-categories     Show categories, app keys, and app labels" \
        "  --dry-run             Print the install plan without changing the system" \
        "  --repo URL            Dotfiles repo for chezmoi (default: $DOTFILES_REPO)" \
        "  --ssh                 Use the SSH GitHub repo URL for chezmoi" \
        "  --non-interactive     Do not prompt; use --all, --minimal, --category, or --app" \
        "  --skip-dotfiles       Install chezmoi but do not run chezmoi init/update" \
        "  --skip-aur            Skip paru and AUR package installation" \
        "  --skip-flatpak        Skip Flatpak setup and Flatpak apps" \
        "  --skip-virt           Skip libvirt/virt-manager service setup" \
        "  --set-dns             Configure NetworkManager DNS without prompting" \
        "  --no-dns              Skip NetworkManager DNS configuration" \
        "  -h, --help            Show this help message" \
        "" \
        "Examples:" \
        "  $0" \
        "  $0 --dry-run --category desktop --app steam --non-interactive" \
        "  $0 --all --non-interactive" \
        "  $0 --category desktop --category development --app steam" \
        "  $0 --minimal --non-interactive --no-dns" \
        "" \
        "Environment overrides:" \
        "  DOTFILES_REPO, APPLY_DOTFILES, RUN_AUR, RUN_FLATPAK, RUN_VIRT," \
        "  DNS_MODE, DNS_SERVERS, NM_CONNECTION, INTERACTIVE"
}

category_title() {
    local slug="$1"
    local index
    for index in "${!CATEGORY_SLUGS[@]}"; do
        if [[ "${CATEGORY_SLUGS[$index]}" == "$slug" ]]; then
            printf '%s\n' "${CATEGORY_TITLES[$index]}"
            return 0
        fi
    done

    printf '%s\n' "$slug"
}

normalize_category() {
    case "$1" in
        audio|sound) printf '%s\n' "audio" ;;
        browser|browsers|notes|web) printf '%s\n' "browsers" ;;
        creative|creator|media) printf '%s\n' "creative" ;;
        desktop|wayland|hyprland) printf '%s\n' "desktop" ;;
        dev|development|code) printf '%s\n' "development" ;;
        files|shell|terminal|term) printf '%s\n' "terminal" ;;
        gaming|games) printf '%s\n' "gaming" ;;
        privacy|security) printf '%s\n' "security" ;;
        virt|virtualization|vm|vms) printf '%s\n' "virtualization" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

list_categories() {
    local category index
    for category in "${CATEGORY_SLUGS[@]}"; do
        printf '\n%s (%s)\n' "$(category_title "$category")" "$category"
        for index in "${!ITEM_KEYS[@]}"; do
            [[ "${ITEM_CATEGORIES[$index]}" == "$category" ]] || continue
            printf '  %-16s %s\n' "${ITEM_KEYS[$index]}" "${ITEM_LABELS[$index]}"
        done
    done
}

split_requested_values() {
    local target_name="$1"
    local raw="${2//,/ }"
    local -n target="$target_name"
    local value

    for value in $raw; do
        target+=("$value")
    done
}

parse_args() {
    while (($#)); do
        case "$1" in
            --all)
                SELECT_ALL="yes"
                shift
                ;;
            --minimal)
                MINIMAL_ONLY="yes"
                shift
                ;;
            --category|--categories)
                [[ $# -ge 2 ]] || die "$1 requires a category name"
                split_requested_values REQUESTED_CATEGORIES "$2"
                shift 2
                ;;
            --app|--apps)
                [[ $# -ge 2 ]] || die "$1 requires an app key"
                split_requested_values REQUESTED_APPS "$2"
                shift 2
                ;;
            --list-categories|--list-apps)
                list_categories
                exit 0
                ;;
            --dry-run|--print-plan)
                DRY_RUN="yes"
                shift
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

find_item_index() {
    local key="$1"
    local index

    for index in "${!ITEM_KEYS[@]}"; do
        if [[ "${ITEM_KEYS[$index]}" == "$key" ]]; then
            printf '%s\n' "$index"
            return 0
        fi
    done

    return 1
}

select_item_by_key() {
    local key="$1"
    find_item_index "$key" >/dev/null || die "Unknown app key: $key"
    append_unique SELECTED_ITEMS "$key"
}

select_category_by_slug() {
    local slug
    slug="$(normalize_category "$1")"

    contains "$slug" "${CATEGORY_SLUGS[@]}" || die "Unknown category: $1"

    local index
    for index in "${!ITEM_KEYS[@]}"; do
        [[ "${ITEM_CATEGORIES[$index]}" == "$slug" ]] || continue
        select_item_by_key "${ITEM_KEYS[$index]}"
    done
}

select_all_items() {
    local key
    for key in "${ITEM_KEYS[@]}"; do
        select_item_by_key "$key"
    done
}

selection_requested() {
    is_yes "$SELECT_ALL" && return 0
    is_yes "$MINIMAL_ONLY" && return 0
    ((${#REQUESTED_CATEGORIES[@]} > 0)) && return 0
    ((${#REQUESTED_APPS[@]} > 0)) && return 0
    return 1
}

apply_requested_selections() {
    if is_yes "$MINIMAL_ONLY"; then
        if is_yes "$SELECT_ALL" || ((${#REQUESTED_CATEGORIES[@]} > 0)) || ((${#REQUESTED_APPS[@]} > 0)); then
            die "--minimal cannot be combined with --all, --category, or --app"
        fi

        return 0
    fi

    if is_yes "$SELECT_ALL"; then
        select_all_items
    fi

    local category app
    for category in "${REQUESTED_CATEGORIES[@]}"; do
        select_category_by_slug "$category"
    done

    for app in "${REQUESTED_APPS[@]}"; do
        select_item_by_key "$app"
    done
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

prompt_for_category() {
    local category="$1"
    local title
    title="$(category_title "$category")"

    local indices=()
    local index
    for index in "${!ITEM_KEYS[@]}"; do
        [[ "${ITEM_CATEGORIES[$index]}" == "$category" ]] || continue
        indices+=("$index")
    done

    ((${#indices[@]} > 0)) || return 0

    printf '\n%s\n' "$title"

    local number item_index
    number=1
    for item_index in "${indices[@]}"; do
        printf '  %2d) %-16s %s\n' "$number" "${ITEM_KEYS[$item_index]}" "${ITEM_LABELS[$item_index]}"
        number=$((number + 1))
    done

    printf 'Select numbers, keys, "all", or press Enter for none.\n'

    local reply token selected_index
    read -r -p "Selection: " reply
    reply="${reply//,/ }"

    [[ -z "$reply" || "$reply" == "none" || "$reply" == "n" || "$reply" == "skip" ]] && return 0

    if [[ "$reply" == "all" || "$reply" == "a" || "$reply" == "*" ]]; then
        for item_index in "${indices[@]}"; do
            select_item_by_key "${ITEM_KEYS[$item_index]}"
        done
        return 0
    fi

    for token in $reply; do
        if [[ "$token" =~ ^[0-9]+$ ]]; then
            if ((token < 1 || token > ${#indices[@]})); then
                die "Invalid selection '$token' in $title"
            fi

            selected_index="${indices[$((token - 1))]}"
            select_item_by_key "${ITEM_KEYS[$selected_index]}"
        else
            select_item_by_key "$token"
        fi
    done
}

prompt_for_apps() {
    printf '%s\n' \
        "" \
        "Base CLI tools and chezmoi are always installed." \
        "Now choose optional apps and bundles by category."

    if ask_yes_no "Install all optional apps?" "no"; then
        select_all_items
        return 0
    fi

    local category
    for category in "${CATEGORY_SLUGS[@]}"; do
        prompt_for_category "$category"
    done
}

choose_apps() {
    apply_requested_selections

    if is_yes "$MINIMAL_ONLY"; then
        return 0
    fi

    if ! selection_requested; then
        if use_interactive_mode; then
            prompt_for_apps
        else
            warn "No app selections provided and stdin is not interactive. Installing base tools only."
        fi
    fi
}

selected_item_label() {
    local key="$1"
    local index
    index="$(find_item_index "$key")"
    printf '%s\n' "${ITEM_LABELS[$index]}"
}

build_package_lists() {
    PACMAN_PACKAGES=()
    AUR_PACKAGES=()
    FLATPAK_APPS=()
    NEEDS_VIRT_SETUP="no"
    NEEDS_SDDM_SETUP="no"

    append_unique PACMAN_PACKAGES "${BASE_PACKAGES[@]}"

    local key index
    for key in "${SELECTED_ITEMS[@]}"; do
        index="$(find_item_index "$key")"
        append_words PACMAN_PACKAGES "${ITEM_PACMAN[$index]}"

        if is_yes "$RUN_AUR"; then
            append_words AUR_PACKAGES "${ITEM_AUR[$index]}"
        fi

        if is_yes "$RUN_FLATPAK"; then
            append_words FLATPAK_APPS "${ITEM_FLATPAK[$index]}"
        fi

        if [[ "${ITEM_POST[$index]}" == *"virt"* ]]; then
            NEEDS_VIRT_SETUP="yes"
        fi
        if [[ "${ITEM_POST[$index]}" == *"sddm"* ]]; then
            NEEDS_SDDM_SETUP="yes"
        fi
    done

    if ((${#FLATPAK_APPS[@]} > 0)); then
        append_unique PACMAN_PACKAGES flatpak flatseal
    fi
}

print_selected_items() {
    if ((${#SELECTED_ITEMS[@]} == 0)); then
        printf 'Selected optional apps: none\n'
        return
    fi

    printf 'Selected optional apps:\n'
    local key
    for key in "${SELECTED_ITEMS[@]}"; do
        printf '  - %-16s %s\n' "$key" "$(selected_item_label "$key")"
    done
}

selection_has_payload() {
    local payload_name="$1"
    local key index

    for key in "${SELECTED_ITEMS[@]}"; do
        index="$(find_item_index "$key")"
        case "$payload_name" in
            aur)
                [[ -n "${ITEM_AUR[$index]}" ]] && return 0
                ;;
            flatpak)
                [[ -n "${ITEM_FLATPAK[$index]}" ]] && return 0
                ;;
        esac
    done

    return 1
}

print_config() {
    log "Install configuration"
    printf 'Dotfiles repo: %s\n' "$DOTFILES_REPO"
    printf 'Apply dotfiles: %s\n' "$APPLY_DOTFILES"
    printf 'Install AUR selections: %s\n' "$RUN_AUR"
    printf 'Install Flatpak selections: %s\n' "$RUN_FLATPAK"
    printf 'Setup virtualization services: %s\n' "$RUN_VIRT"
    printf 'DNS mode: %s\n' "$DNS_MODE"
    print_selected_items
    printf 'Pacman packages: %s\n' "${#PACMAN_PACKAGES[@]}"
    printf 'AUR packages: %s\n' "${#AUR_PACKAGES[@]}"
    printf 'Flatpak apps: %s\n' "${#FLATPAK_APPS[@]}"

    if ! is_yes "$RUN_AUR" && selection_has_payload aur; then
        printf 'Note: AUR-backed selections are skipped because RUN_AUR is disabled.\n'
    fi

    if ! is_yes "$RUN_FLATPAK" && selection_has_payload flatpak; then
        printf 'Note: Flatpak-backed selections are skipped because RUN_FLATPAK is disabled.\n'
    fi
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

configure_package_maintenance() {
    log "Enabling conservative weekly package-cache maintenance"
    sudo systemctl enable --now paccache.timer
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
    if ! is_yes "$NEEDS_VIRT_SETUP" || ! is_yes "$RUN_VIRT"; then
        log "Skipping virtualization setup"
        return
    fi

    log "Configuring libvirt"
    sudo usermod -aG libvirt "$TARGET_USER"
    sudo systemctl enable --now libvirtd.service
    warn "Log out and back in before using virt-manager so the libvirt group change takes effect."
}

configure_sddm() {
    if ! is_yes "$NEEDS_SDDM_SETUP"; then
        log "Skipping SDDM setup"
        return
    fi

    local repo_root
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    log "Theming SDDM and installing a Hyprland-only session menu"
    sudo install -d /usr/local/share/wayland-sessions /etc/sddm.conf.d
    sudo install -m 0644 "$repo_root/system/sddm/breeze-theme.conf.user" /usr/share/sddm/themes/breeze/theme.conf.user
    sudo install -m 0644 "$repo_root/Pictures/Wallpapers/understory-pattern-dark.png" /usr/share/sddm/themes/breeze/understory-background.png
    sudo install -m 0644 "$repo_root/system/sddm/hyprland-uwsm.desktop" /usr/local/share/wayland-sessions/hyprland-uwsm.desktop
    sudo install -m 0644 "$repo_root/system/sddm/10-understory.conf" /etc/sddm.conf.d/10-understory.conf
    sudo systemctl enable sddm.service
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
    define_catalog
    parse_args "$@"

    if is_yes "$DRY_RUN"; then
        choose_apps
        build_package_lists
        print_config
        log "Dry run complete. No changes were made."
        exit 0
    fi

    require_arch_linux
    resolve_target_user
    choose_apps
    build_package_lists
    print_config
    confirm_install
    sudo -v

    create_home_directories
    install_pacman_packages
    configure_package_maintenance
    install_aur_packages
    install_flatpak_apps
    apply_dotfiles
    configure_sddm
    setup_virtualization
    configure_dns

    log "Arch setup complete"
}

main "$@"
