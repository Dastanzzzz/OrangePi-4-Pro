#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Orange Pi Custom Kernel Modules Installer
#
# Repository:
#   https://github.com/Dastanzzzz/OrangePi-4-Pro
#
# Supported:
#   Kernel : 6.6.98-sun60iw2
#   Arch   : ARM64
#
# Features:
#   1. TUN + POSIX MQUEUE + UTF-8
#   2. OverlayFS
#   3. WireGuard
#   4. CIFS / SMB
#   5. OpenVPN DCO
# ============================================================

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

REPO="Dastanzzzz/OrangePi-4-Pro"
BRANCH="main"

REQUIRED_KERNEL="6.6.98-sun60iw2"
REQUIRED_ARCH="aarch64"

TMP_DIR="/tmp/orangepi-custom-modules"

PKG_TUN="orangepi-custom-modules_1.0_arm64.deb"
PKG_WIREGUARD="wireguard-6.6.98-sun60iw2.deb"
PKG_CIFS="cifs-6.6.98-sun60iw2.deb"
PKG_OVERLAY="overlayfs-config-6.6.98-sun60iw2.deb"
PKG_OVPN="ovpn-backports-kmod_7.1.0-1_arm64.deb"

DOWNLOAD_CMD=""

SELECTED=()

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ------------------------------------------------------------
# Output helpers
# ------------------------------------------------------------

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[ OK ]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

die() {
    error "$*"
    exit 1
}

pause() {
    echo
    read -r -p "Press Enter to continue..." _
}

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

# ------------------------------------------------------------
# Root privilege
# ------------------------------------------------------------

ensure_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        return 0
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        die "This installer requires root privileges and sudo was not found."
    fi

    info "Root privileges are required."
    info "Re-running installer with sudo..."

    exec sudo bash "$0" "$@"
}

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

show_banner() {
    clear

    echo -e "${CYAN}"
    cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║        Orange Pi Custom Kernel Module Installer         ║
╠══════════════════════════════════════════════════════════╣
║ Kernel : 6.6.98-sun60iw2                               ║
║ Arch   : ARM64                                         ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ------------------------------------------------------------
# System checks
# ------------------------------------------------------------

check_system() {
    info "Checking system..."
    echo

    local arch
    local kernel

    arch="$(uname -m)"
    kernel="$(uname -r)"

    echo "Architecture : $arch"
    echo "Kernel       : $kernel"
    echo

    if [[ "$arch" != "$REQUIRED_ARCH" ]]; then
        die "Unsupported architecture: $arch. Required: $REQUIRED_ARCH"
    fi

    success "Architecture: ARM64"

    if [[ "$kernel" != "$REQUIRED_KERNEL" ]]; then
        echo
        error "Unsupported kernel detected!"
        echo
        echo "Current : $kernel"
        echo "Required: $REQUIRED_KERNEL"
        echo
        error "Installation aborted."
        exit 1
    fi

    success "Kernel: $REQUIRED_KERNEL"

    if ! command -v dpkg >/dev/null 2>&1; then
        die "dpkg was not found."
    fi

    success "dpkg found"

    if ! command -v dpkg-deb >/dev/null 2>&1; then
        die "dpkg-deb was not found."
    fi

    success "dpkg-deb found"

    if ! command -v modprobe >/dev/null 2>&1; then
        die "modprobe was not found."
    fi

    success "modprobe found"

    if ! command -v depmod >/dev/null 2>&1; then
        die "depmod was not found."
    fi

    success "depmod found"

    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget"
    else
        die "curl or wget is required."
    fi

    success "Download utility: $DOWNLOAD_CMD"

    echo
    success "All system checks passed."
}

# ------------------------------------------------------------
# Download package
# ------------------------------------------------------------

download_package() {
    local package="$1"

    mkdir -p "$TMP_DIR"

    local url
    local output

    url="https://github.com/${REPO}/raw/refs/heads/${BRANCH}/${package}"
    output="${TMP_DIR}/${package}"

    if [[ -f "$output" ]]; then
        if dpkg-deb --info "$output" >/dev/null 2>&1; then
            success "Already downloaded: $package" >&2
            echo "$output"
            return 0
        fi

        warn "Existing file is invalid. Re-downloading: $package" >&2
        rm -f "$output"
    fi

    echo >&2
    info "Downloading:" >&2
    echo "  $package" >&2

    if [[ "$DOWNLOAD_CMD" == "curl" ]]; then

        if ! curl \
            --fail \
            --location \
            --show-error \
            --progress-bar \
            "$url" \
            --output "$output" >&2; then

            rm -f "$output"

            error "Failed to download package."
            error "URL: $url"

            return 1
        fi

    elif [[ "$DOWNLOAD_CMD" == "wget" ]]; then

        if ! wget \
            --show-progress \
            "$url" \
            --output-document="$output" >&2; then

            rm -f "$output"

            error "Failed to download package."
            error "URL: $url"

            return 1
        fi

    else

        error "No supported download utility found."
        return 1
    fi

    if [[ ! -s "$output" ]]; then
        rm -f "$output"

        error "Downloaded file is empty:"
        error "$package"

        return 1
    fi

    if ! dpkg-deb --info "$output" >/dev/null 2>&1; then
        rm -f "$output"

        error "Downloaded file is not a valid Debian package:"
        error "$package"

        return 1
    fi

    success "Downloaded: $package" >&2

    # stdout ONLY returns the package path.
    echo "$output"
}

# ------------------------------------------------------------
# Install package
# ------------------------------------------------------------

install_package() {
    local package="$1"

    echo
    info "Installing package: $package"

    local deb

    if ! deb="$(download_package "$package")"; then
        error "Could not download: $package"
        return 1
    fi

    echo

    if dpkg -i "$deb"; then
        success "Installed: $package"
        return 0
    fi

    warn "dpkg reported an installation problem."

    if command -v apt-get >/dev/null 2>&1; then

        info "Attempting to fix package dependencies..."

        if apt-get install -f -y; then

            if dpkg-query \
                -W \
                -f='${Status}' \
                "$package" 2>/dev/null |
                grep -q "install ok installed"; then

                success "Package dependencies fixed."
                success "Installed: $package"

                return 0
            fi
        fi
    fi

    error "Failed to install: $package"

    return 1
}

# ------------------------------------------------------------
# Load kernel module
# ------------------------------------------------------------

load_module() {
    local module="$1"

    info "Loading module: $module"

    if modprobe "$module" 2>/dev/null; then
        success "Module loaded: $module"
        return 0
    fi

    warn "Could not load module: $module"

    return 1
}

# ------------------------------------------------------------
# Verification helpers
# ------------------------------------------------------------

verify_tun() {
    if [[ -c /dev/net/tun ]]; then
        success "TUN: OK"
    else
        warn "TUN: NOT AVAILABLE"
    fi
}

verify_posix() {
    if mountpoint -q /dev/mqueue 2>/dev/null; then
        success "POSIX MQUEUE: OK"
    else
        warn "POSIX MQUEUE: NOT ACTIVE"
    fi
}

verify_overlay() {
    if grep -qw overlay /proc/filesystems; then
        success "OverlayFS: OK"
    else
        warn "OverlayFS: NOT AVAILABLE"
    fi
}

verify_utf8() {
    if [[ "$(locale charmap 2>/dev/null)" == "UTF-8" ]]; then
        success "UTF-8 locale: OK"
    else
        warn "UTF-8 locale: NOT UTF-8"
    fi

    if lsmod | grep -qw nls_utf8; then
        success "nls_utf8: OK"
    else
        warn "nls_utf8: NOT LOADED"
    fi
}

verify_wireguard() {
    if lsmod | grep -qw wireguard; then
        success "WireGuard: OK"
    else
        warn "WireGuard: NOT LOADED"
    fi
}

verify_cifs() {
    if lsmod | grep -qw cifs; then
        success "CIFS: OK"
    else
        warn "CIFS: NOT LOADED"
    fi

    for module in \
        netfs \
        dns_resolver \
        cifs_md4 \
        cifs_arc4
    do
        if lsmod | grep -qw "$module"; then
            success "$module: loaded"
        fi
    done
}

verify_ovpn() {
    if lsmod | grep -qw ovpn; then
        success "OpenVPN DCO (ovpn): OK"
    else
        warn "OpenVPN DCO (ovpn): NOT LOADED"
    fi

    if lsmod | grep -qw strparser; then
        success "strparser: OK"
    else
        warn "strparser: NOT LOADED"
    fi
}

# ------------------------------------------------------------
# TUN + POSIX MQUEUE + UTF-8
# ------------------------------------------------------------

install_tun_posix_utf8() {

    echo
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} TUN + POSIX MQUEUE + UTF-8${NC}"
    echo -e "${CYAN}================================================${NC}"

    if ! install_package "$PKG_TUN"; then
        return 1
    fi

    echo
    info "Updating module dependency database..."

    depmod -a

    success "depmod completed."

    echo
    load_module tun || true

    echo
    load_module nls_utf8 || true

    echo
    info "Checking POSIX MQUEUE..."

    if mountpoint -q /dev/mqueue 2>/dev/null; then

        success "POSIX MQUEUE is already mounted."

    else

        mkdir -p /dev/mqueue

        if mount -t mqueue none /dev/mqueue 2>/dev/null; then
            success "POSIX MQUEUE mounted."
        else
            warn "Could not mount /dev/mqueue."
        fi

    fi

    echo
    verify_tun
    verify_posix
    verify_utf8
}

# ------------------------------------------------------------
# OverlayFS
# ------------------------------------------------------------

install_overlay() {

    echo
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} OverlayFS${NC}"
    echo -e "${CYAN}================================================${NC}"

    if ! install_package "$PKG_OVERLAY"; then
        return 1
    fi

    echo
    info "Updating module dependency database..."

    depmod -a

    success "depmod completed."

    modprobe overlay 2>/dev/null || true

    echo
    verify_overlay
}

# ------------------------------------------------------------
# WireGuard
# ------------------------------------------------------------

install_wireguard() {

    echo
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} WireGuard${NC}"
    echo -e "${CYAN}================================================${NC}"

    if ! install_package "$PKG_WIREGUARD"; then
        return 1
    fi

    echo
    info "Updating module dependency database..."

    depmod -a

    success "depmod completed."

    echo
    load_module wireguard || true

    echo
    verify_wireguard
}

# ------------------------------------------------------------
# CIFS / SMB
# ------------------------------------------------------------

install_cifs() {

    echo
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} CIFS / SMB${NC}"
    echo -e "${CYAN}================================================${NC}"

    if ! install_package "$PKG_CIFS"; then
        return 1
    fi

    echo
    info "Updating module dependency database..."

    depmod -a

    success "depmod completed."

    echo
    load_module cifs || true

    echo
    verify_cifs
}

# ------------------------------------------------------------
# OpenVPN DCO
# ------------------------------------------------------------

install_ovpn() {

    echo
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} OpenVPN DCO${NC}"
    echo -e "${CYAN}================================================${NC}"

    if ! install_package "$PKG_OVPN"; then
        return 1
    fi

    echo
    info "Updating module dependency database..."

    depmod -a

    success "depmod completed."

    echo
    load_module ovpn || true

    echo
    load_module strparser || true

    echo
    verify_ovpn
}

# ------------------------------------------------------------
# Verify all
# ------------------------------------------------------------

verify_all() {

    clear

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║              Installation Verification              ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo
    echo "=== KERNEL ==="
    uname -r

    echo
    echo "=== ARCHITECTURE ==="
    uname -m

    echo
    echo "=== TUN ==="
    verify_tun

    echo
    echo "=== POSIX MQUEUE ==="
    verify_posix

    echo
    echo "=== OVERLAYFS ==="
    verify_overlay

    echo
    echo "=== UTF-8 ==="
    verify_utf8

    echo
    echo "=== WIREGUARD ==="
    verify_wireguard

    echo
    echo "=== CIFS ==="
    verify_cifs

    echo
    echo "=== OPENVPN DCO ==="
    verify_ovpn

    echo
    echo "=== MODULE INFORMATION ==="

    if modinfo ovpn >/dev/null 2>&1; then
        echo
        echo "--- ovpn ---"

        modinfo ovpn |
            grep -E 'filename|version|depends|vermagic' ||
            true
    fi

    if modinfo strparser >/dev/null 2>&1; then
        echo
        echo "--- strparser ---"

        modinfo strparser |
            grep -E 'filename|version|depends|vermagic' ||
            true
    fi

    echo
    echo -e "${GREEN}Verification complete.${NC}"
}

# ------------------------------------------------------------
# Display selected modules
# ------------------------------------------------------------

show_selected() {

    echo
    echo -e "${WHITE}Selected modules:${NC}"

    for choice in "${SELECTED[@]}"; do

        case "$choice" in
            1)
                echo "  ✓ TUN + POSIX MQUEUE + UTF-8"
                ;;
            2)
                echo "  ✓ OverlayFS"
                ;;
            3)
                echo "  ✓ WireGuard"
                ;;
            4)
                echo "  ✓ CIFS / SMB"
                ;;
            5)
                echo "  ✓ OpenVPN DCO"
                ;;
        esac

    done
}

# ------------------------------------------------------------
# Select modules
# ------------------------------------------------------------

select_modules() {

    clear

    echo -e "${CYAN}"
    cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║              Select Modules To Install                 ║
╠══════════════════════════════════════════════════════════╣
║ [1] TUN + POSIX MQUEUE + UTF-8                         ║
║ [2] OverlayFS                                          ║
║ [3] WireGuard                                          ║
║ [4] CIFS / SMB                                         ║
║ [5] OpenVPN DCO                                        ║
║ [6] ALL                                                 ║
║ [0] Cancel                                              ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo
    echo "You can select multiple modules."
    echo "Example: 1 3 4"
    echo

    read -r -p "Select modules: " selections

    if [[ -z "$selections" ]]; then
        warn "No selection made."
        return 1
    fi

    for choice in $selections; do
        if [[ "$choice" == "0" ]]; then
            info "Installation cancelled."
            return 1
        fi
    done

    for choice in $selections; do
        if [[ "$choice" == "6" ]]; then
            SELECTED=(1 2 3 4 5)
            show_selected
            echo
            return 0
        fi
    done

    SELECTED=()

    for choice in $selections; do

        case "$choice" in
            1|2|3|4|5)
                SELECTED+=("$choice")
                ;;

            *)
                error "Invalid option: $choice"
                return 1
                ;;
        esac

    done

    if [[ "${#SELECTED[@]}" -eq 0 ]]; then
        warn "No valid modules selected."
        return 1
    fi

    mapfile -t SELECTED < <(
        printf '%s\n' "${SELECTED[@]}" |
        sort -n -u
    )

    show_selected

    echo

    return 0
}

# ------------------------------------------------------------
# Install selected modules
# ------------------------------------------------------------

install_selected() {

    local failed=0

    echo
    read -r -p "Continue installation? [Y/n]: " confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        info "Installation cancelled."
        return 0
    fi

    echo
    echo -e "${CYAN}Starting installation...${NC}"

    for choice in "${SELECTED[@]}"; do

        case "$choice" in

            1)
                if ! install_tun_posix_utf8; then
                    failed=1
                fi
                ;;

            2)
                if ! install_overlay; then
                    failed=1
                fi
                ;;

            3)
                if ! install_wireguard; then
                    failed=1
                fi
                ;;

            4)
                if ! install_cifs; then
                    failed=1
                fi
                ;;

            5)
                if ! install_ovpn; then
                    failed=1
                fi
                ;;

        esac

        echo
    done

    info "Running final depmod..."

    depmod -a

    success "Module dependency database updated."

    echo
    echo "================================================"
    echo "                Installation Result"
    echo "================================================"

    if [[ "$failed" -eq 0 ]]; then
        success "All selected modules installed successfully."
    else
        warn "One or more modules failed to install."
    fi

    echo

    read -r -p "Run verification now? [Y/n]: " verify

    if [[ ! "$verify" =~ ^[Nn]$ ]]; then
        verify_all
    fi

    return "$failed"
}

# ------------------------------------------------------------
# Main menu
# ------------------------------------------------------------

main_menu() {

    while true; do

        clear

        echo -e "${CYAN}"
        cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║        Orange Pi Custom Kernel Module Installer         ║
╠══════════════════════════════════════════════════════════╣
║ Kernel : 6.6.98-sun60iw2                               ║
║ Arch   : ARM64                                         ║
╠══════════════════════════════════════════════════════════╣
║ [1] Install Modules                                     ║
║ [2] Verify Installation                                 ║
║ [0] Exit                                                 ║
╚══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"

        echo
        read -r -p "Select an option [0-2]: " menu_choice

        case "$menu_choice" in

            1)
                if select_modules; then
                    install_selected || true
                    pause
                else
                    pause
                fi
                ;;

            2)
                verify_all
                pause
                ;;

            0)
                echo
                info "Exiting installer."
                exit 0
                ;;

            *)
                warn "Invalid option."
                sleep 1
                ;;
        esac

    done
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    ensure_root "$@"

    show_banner

    check_system

    echo
    pause

    main_menu
}

main "$@"
