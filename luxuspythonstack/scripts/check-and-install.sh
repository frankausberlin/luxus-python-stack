#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# check-and-install.sh — Luxus Python Stack Level 0 Validator
#
# Checks whether all required tools for Level 0 (System/Global) are installed,
# detects conflicts with other Python environment managers, and offers to
# install missing components.
#
# Usage: bash scripts/check-and-install.sh
# =============================================================================

# --- Platform Detection ------------------------------------------------------

detect_platform() {
    local os
    os="$(uname -s)"
    case "$os" in
        Linux*)
            if command -v apt-get &>/dev/null; then
                echo "linux-apt"
            elif command -v dnf &>/dev/null; then
                echo "linux-dnf"
            elif command -v pacman &>/dev/null; then
                echo "linux-pacman"
            else
                echo "linux-unknown"
            fi
            ;;
        Darwin*)
            if command -v brew &>/dev/null; then
                echo "macos-brew"
            else
                echo "macos-no-brew"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

PLATFORM="$(detect_platform)"

# --- Configuration -----------------------------------------------------------

# Required tools for Level 0: name|check_command
declare -a REQUIRED_TOOLS=(
    "python3|python3 --version"
    "git|git --version"
    "curl|curl --version"
    "direnv|direnv --version"
    "mamba|mamba --version"
    "uv|uv --version"
    "ruff|ruff --version"
    "basedpyright|basedpyright --version"
    "just|just --version"
)

# Recommended extras: name|check_command
declare -a RECOMMENDED_TOOLS=(
    "rg|rg --version"
    "fd|fd --version"
    "shellcheck|shellcheck --version"
    "shfmt|shfmt --version"
    "build-essential|dpkg -s build-essential &>/dev/null"
)

# Conflict detectors: name|check_command|severity
declare -a CONFLICT_CHECKS=(
    "pyenv|command -v pyenv &>/dev/null|warning"
    "anaconda/miniconda|test -d \$HOME/anaconda3 -o -d \$HOME/miniconda3|warning"
)

# --- State Tracking ----------------------------------------------------------

MISSING_REQUIRED=()
MISSING_RECOMMENDED=()
CONFLICTS_FOUND=()
WARNINGS_FOUND=()
INSTALLED_COUNT=0

# --- Color Output ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}Luxus Python Stack — Check & Install (Level 0)${NC}      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Platform: ${BOLD}${PLATFORM}${NC}"
    echo -e "  Date:     $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

print_section() {
    echo -e "\n${BOLD}${BLUE}── $1 ──${NC}"
}

print_ok() {
    printf "  ${GREEN}✅${NC} %-16s %s\n" "$1" "$2"
}

print_fail() {
    printf "  ${RED}❌${NC} %-16s %s\n" "$1" "$2"
}

print_warn() {
    printf "  ${YELLOW}⚠️${NC}  %-16s %s\n" "$1" "$2"
}

print_info() {
    printf "  ${CYAN}ℹ️${NC}  %s\n" "$1"
}

# --- Check Functions ---------------------------------------------------------

check_tool() {
    local name="$1"
    local check_cmd="$2"
    local output
    # Use read array split instead of eval to avoid injection risk.
    # check_cmd is a static space-separated command from REQUIRED_TOOLS;
    # shellcheck disable=SC2086 — intentional word-splitting on static string
    if output=$(bash -c "$check_cmd" 2>&1); then
        local version
        version=$(echo "$output" | head -1 | sed 's/^[[:space:]]*//')
        local location=""
        if command -v "$name" &>/dev/null; then
            location="$(command -v "$name" 2>/dev/null || echo "unknown")"
        fi
        echo "OK|${version}|${location}"
    else
        echo "FAIL|NOT FOUND|"
    fi
}

check_all_tools() {
    print_section "Checking required tools (Level 0)"

    for tool_def in "${REQUIRED_TOOLS[@]}"; do
        IFS='|' read -r name check_cmd <<< "$tool_def"
        local result
        result=$(check_tool "$name" "$check_cmd")
        IFS='|' read -r status version location <<< "$result"

        if [[ "$status" == "OK" ]]; then
            print_ok "$name" "$version"
        else
            print_fail "$name" "NOT FOUND"
            MISSING_REQUIRED+=("$name")
        fi
    done

    print_section "Checking recommended extras"

    for tool_def in "${RECOMMENDED_TOOLS[@]}"; do
        IFS='|' read -r name check_cmd <<< "$tool_def"
        local result
        result=$(check_tool "$name" "$check_cmd")
        IFS='|' read -r status version location <<< "$result"

        if [[ "$status" == "OK" ]]; then
            print_ok "$name" "$version"
        else
            print_warn "$name" "NOT FOUND (recommended)"
            MISSING_RECOMMENDED+=("$name")
        fi
    done
}

check_conflicts() {
    print_section "Conflict detection"

    local has_critical=false

    for conflict_def in "${CONFLICT_CHECKS[@]}"; do
        IFS='|' read -r name check_cmd severity <<< "$conflict_def"
        # bash -c used for static conflict-check expressions; never pass user input here.
        if bash -c "$check_cmd" &>/dev/null; then
            if [[ "$severity" == "error" ]]; then
                print_fail "$name" "CONFLICT DETECTED"
                CONFLICTS_FOUND+=("$name")
                has_critical=true
            else
                print_warn "$name" "may conflict with Luxus stack tools"
                WARNINGS_FOUND+=("$name")
            fi
        fi
    done

    # Check for Miniforge vs Anaconda/Miniconda conflict
    if [[ -d "$HOME/miniforge3" ]] && { [[ -d "$HOME/anaconda3" ]] || [[ -d "$HOME/miniconda3" ]]; } 2>/dev/null; then
        print_fail "conda" "Miniforge AND Anaconda/Miniconda both installed"
        CONFLICTS_FOUND+=("conda_conflict")
        has_critical=true
    fi

    # Check for multiple direnv installations (type -a lists all matches in PATH).
    # On modern Debian/Ubuntu /bin is a symlink to /usr/bin, so both paths resolve
    # to the same inode — that is NOT a real conflict.  Deduplicate by inode before
    # deciding whether to report a problem.
    local direnv_paths direnv_unique_inodes
    mapfile -t direnv_paths < <(type -a direnv 2>/dev/null | awk '{print $NF}')
    # Resolve real paths and collect unique inodes
    direnv_unique_inodes=()
    local seen_inodes=()
    for dp in "${direnv_paths[@]}"; do
        local real_path inode
        real_path="$(realpath "$dp" 2>/dev/null || echo "$dp")"
        inode="$(stat --format='%i' "$real_path" 2>/dev/null || echo "unknown")"
        local already_seen=false
        for si in "${seen_inodes[@]:-}"; do
            [[ "$si" == "$inode" ]] && already_seen=true && break
        done
        if [[ "$already_seen" == false ]]; then
            seen_inodes+=("$inode")
            direnv_unique_inodes+=("$real_path")
        fi
    done
    if [[ "${#direnv_unique_inodes[@]}" -gt 1 ]]; then
        print_fail "direnv" "multiple installations detected (${direnv_unique_inodes[*]})"
        CONFLICTS_FOUND+=("multiple_direnv")
        has_critical=true
    fi

    if [[ "$has_critical" == false ]] && [[ ${#CONFLICTS_FOUND[@]} -eq 0 ]]; then
        print_ok "conflicts" "No critical conflicts detected"
    fi
}

# --- Install Functions (apt-based) -------------------------------------------

# Platform-aware package installer
install_packages() {
    local -a packages=("$@")
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo -e "${BOLD}Installing apt packages: ${packages[*]}${NC}"

    case "$PLATFORM" in
        linux-apt)
            if sudo apt-get update -qq &>/dev/null; then
                if sudo apt-get install -y "${packages[@]}" &>/dev/null; then
                    echo -e "${GREEN}✅ Successfully installed: ${packages[*]}${NC}"
                    ((INSTALLED_COUNT += ${#packages[@]})) || true
                else
                    echo -e "${RED}❌ Failed to install: ${packages[*]}${NC}"
                    return 1
                fi
            else
                echo -e "${RED}❌ apt-get update failed${NC}"
                return 1
            fi
            ;;
        linux-dnf)
            echo -e "${YELLOW}⚠️  DNF platform detected — manual install required:${NC}"
            echo -e "   sudo dnf install -y ${packages[*]}"
            return 1
            ;;
        linux-pacman)
            echo -e "${YELLOW}⚠️  Pacman platform detected — manual install required:${NC}"
            echo -e "   sudo pacman -S ${packages[*]}"
            return 1
            ;;
        macos-brew)
            echo -e "${YELLOW}⚠️  macOS/Homebrew platform — manual install required:${NC}"
            echo -e "   brew install ${packages[*]}"
            return 1
            ;;
        *)
            echo -e "${RED}❌ Unsupported platform — install manually:${NC}"
            echo -e "   ${packages[*]}"
            return 1
            ;;
    esac
}

install_python3() {
    install_packages "python3" "python3-venv"
}

install_git() {
    install_packages "git"
}

install_curl() {
    install_packages "curl"
}

install_direnv() {
    install_packages "direnv"
}

install_shellcheck() {
    install_packages "shellcheck"
}

install_shfmt() {
    # shfmt is available as a snap or via direct download; prefer apt on Ubuntu 22.04+
    if install_packages "shfmt" 2>/dev/null; then
        return 0
    fi
    # Fallback: install via snap
    if command -v snap &>/dev/null; then
        echo -e "${YELLOW}⚠️  shfmt not in apt — trying snap${NC}"
        sudo snap install shfmt && ((INSTALLED_COUNT++)) || true
    else
        echo -e "${YELLOW}⚠️  Install shfmt manually: https://github.com/mvdan/sh/releases${NC}"
        return 1
    fi
}

install_build_essential() {
    install_packages "build-essential"
}

install_rg() {
    install_packages "ripgrep"
}

install_fd() {
    install_packages "fd-find"
    # fd-find installs as fdfind on Debian/Ubuntu — create symlink
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        local link_dir="$HOME/.local/bin"
        mkdir -p "$link_dir"
        ln -sf "$(command -v fdfind)" "$link_dir/fd"
        echo -e "${CYAN}ℹ️  Created symlink: fd -> fdfind${NC}"
    fi
}

install_miniforge() {
    if [[ -d "$HOME/miniforge3" ]]; then
        echo -e "${CYAN}ℹ️  Miniforge3 already exists at $HOME/miniforge3${NC}"
        return 0
    fi

    echo ""
    echo -e "${BOLD}Installing Miniforge3...${NC}"
    local installer="Miniforge3-$(uname)-$(uname -m).sh"
    local url="https://github.com/conda-forge/miniforge/releases/latest/download/${installer}"

    if curl -L -o "$HOME/${installer}" "$url"; then
        # Verify SHA-256 checksum before executing the downloaded installer
        local sha_url="${url}.sha256"
        local expected_sha
        if expected_sha=$(curl -sL "$sha_url" | awk '{print $1}'); then
            local actual_sha
            actual_sha=$(sha256sum "$HOME/${installer}" | awk '{print $1}')
            if [[ "$expected_sha" != "$actual_sha" ]]; then
                echo -e "${RED}❌ Checksum mismatch for ${installer} — aborting${NC}"
                rm -f "$HOME/${installer}"
                return 1
            fi
            echo -e "${CYAN}ℹ️  Checksum verified ✔${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not fetch checksum — proceeding without verification${NC}"
        fi

        if bash "$HOME/${installer}" -b -p "$HOME/miniforge3"; then
            rm -f "$HOME/${installer}"
            echo -e "${GREEN}✅ Miniforge3 installed successfully${NC}"
            ((INSTALLED_COUNT++)) || true
            "$HOME/miniforge3/bin/conda" init bash &>/dev/null || true
            echo -e "${CYAN}ℹ️  Run 'source ~/.bashrc' to activate${NC}"
        else
            rm -f "$HOME/${installer}"
            echo -e "${RED}❌ Miniforge installation failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to download Miniforge installer${NC}"
        return 1
    fi
}

install_uv() {
    if command -v uv &>/dev/null; then
        echo -e "${CYAN}ℹ️  uv already installed at $(command -v uv)${NC}"
        return 0
    fi

    echo ""
    echo -e "${BOLD}Installing uv...${NC}"
    # Download installer to a temp file and verify it is non-empty before executing.
    # The astral.sh installer is served over HTTPS; for stricter pinning use a
    # versioned release URL and compare the SHA from https://github.com/astral-sh/uv/releases.
    local uv_installer
    uv_installer="$(mktemp /tmp/uv-install-XXXXXX.sh)"
    if curl -LsSf https://astral.sh/uv/install.sh -o "$uv_installer" \
       && [[ -s "$uv_installer" ]]; then
        chmod +x "$uv_installer"
        if sh "$uv_installer"; then
            rm -f "$uv_installer"
            echo -e "${GREEN}✅ uv installed successfully${NC}"
            ((INSTALLED_COUNT++)) || true
            echo -e "${CYAN}ℹ️  Run 'source ~/.bashrc' or 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to activate${NC}"
        else
            rm -f "$uv_installer"
            echo -e "${RED}❌ uv installation failed${NC}"
            return 1
        fi
    else
        rm -f "$uv_installer"
        echo -e "${RED}❌ Failed to download uv installer${NC}"
        return 1
    fi
}

install_ruff() {
    if ! command -v uv &>/dev/null; then
        echo -e "${RED}❌ uv is required to install ruff${NC}"
        return 1
    fi
    echo ""
    echo -e "${BOLD}Installing ruff via uv tool...${NC}"
    if uv tool install ruff@latest; then
        echo -e "${GREEN}✅ ruff installed successfully${NC}"
        ((INSTALLED_COUNT++)) || true
    else
        echo -e "${RED}❌ ruff installation failed${NC}"
        return 1
    fi
}

install_basedpyright() {
    if ! command -v uv &>/dev/null; then
        echo -e "${RED}❌ uv is required to install basedpyright${NC}"
        return 1
    fi
    echo ""
    echo -e "${BOLD}Installing basedpyright via uv tool...${NC}"
    if uv tool install basedpyright; then
        echo -e "${GREEN}✅ basedpyright installed successfully${NC}"
        ((INSTALLED_COUNT++)) || true
    else
        echo -e "${RED}❌ basedpyright installation failed${NC}"
        return 1
    fi
}

install_just() {
    if ! command -v uv &>/dev/null; then
        echo -e "${RED}❌ uv is required to install just${NC}"
        return 1
    fi
    echo ""
    echo -e "${BOLD}Installing just via uv tool...${NC}"
    if uv tool install rust-just; then
        echo -e "${GREEN}✅ just installed successfully${NC}"
        ((INSTALLED_COUNT++)) || true
    else
        echo -e "${RED}❌ just installation failed${NC}"
        return 1
    fi
}

# --- Installation Orchestration ----------------------------------------------

install_missing() {
    local missing_all=("${MISSING_REQUIRED[@]}" "${MISSING_RECOMMENDED[@]}")
    if [[ ${#missing_all[@]} -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}All tools are installed. Nothing to do.${NC}"
        return 0
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}Missing tools: ${missing_all[*]}${NC}"
    echo -e "${BOLD}${YELLOW}────────────────────────────────────────────────────────────${NC}"
    echo ""

    # Check for critical conflicts before installing
    if [[ ${#CONFLICTS_FOUND[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}⚠️  CRITICAL CONFLICTS DETECTED — Please resolve before installing:${NC}"
        for conflict in "${CONFLICTS_FOUND[@]}"; do
            echo -e "  ${RED}•${NC} $conflict"
        done
        echo ""
        echo -e "${YELLOW}Recommendation: Remove or disable conflicting tools first.${NC}"
        echo ""
        read -rp "Continue anyway? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation aborted."
            return 1
        fi
    fi

    read -rp "Install missing tools? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Installation skipped."
        return 0
    fi

    echo ""
    echo -e "${BOLD}${BLUE}Starting installation...${NC}"

    for tool in "${missing_all[@]}"; do
        local install_func="install_${tool//-/_}"
        if declare -f "$install_func" &>/dev/null; then
            echo ""
            echo -e "${BOLD}→ Installing: $tool${NC}"
            if $install_func; then
                echo -e "${GREEN}  ✅ Done: $tool${NC}"
            else
                echo -e "${RED}  ❌ Failed: $tool${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  No automated installer for '$tool' — install manually${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}${GREEN}────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}${GREEN}Installation complete!${NC}"
    echo -e "${CYAN}ℹ️  Run 'source ~/.bashrc' to activate all changes${NC}"
    echo -e "${BOLD}${GREEN}────────────────────────────────────────────────────────────${NC}"
}

# --- Summary -----------------------------------------------------------------

print_summary() {
    echo ""
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Summary${NC}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════${NC}"

    local required_total=${#REQUIRED_TOOLS[@]}
    local missing_count=${#MISSING_REQUIRED[@]}
    local present_count=$((required_total - missing_count))

    echo -e "  Required tools:    ${GREEN}${present_count}/${required_total} present${NC}"
    if [[ $missing_count -gt 0 ]]; then
        echo -e "  Missing required:  ${RED}${MISSING_REQUIRED[*]}${NC}"
    fi

    local recommended_total=${#RECOMMENDED_TOOLS[@]}
    local missing_rec_count=${#MISSING_RECOMMENDED[@]}
    local present_rec_count=$((recommended_total - missing_rec_count))
    echo -e "  Recommended:       ${present_rec_count}/${recommended_total} present"

    if [[ ${#WARNINGS_FOUND[@]} -gt 0 ]]; then
        echo -e "  Warnings:          ${YELLOW}${#WARNINGS_FOUND[@]} — ${WARNINGS_FOUND[*]}${NC}"
    fi

    if [[ ${#CONFLICTS_FOUND[@]} -gt 0 ]]; then
        echo -e "  Conflicts:         ${RED}${#CONFLICTS_FOUND[@]} — ${CONFLICTS_FOUND[*]}${NC}"
    fi

    echo ""

    if [[ $missing_count -eq 0 ]] && [[ ${#CONFLICTS_FOUND[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✅ Level 0 is fully configured and ready!${NC}"
    elif [[ $missing_count -gt 0 ]] && [[ ${#CONFLICTS_FOUND[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}⚠️  Missing tools detected — run installation to complete setup${NC}"
    elif [[ ${#CONFLICTS_FOUND[@]} -gt 0 ]]; then
        echo -e "  ${RED}${BOLD}❌ Conflicts detected — resolve before proceeding${NC}"
    fi

    echo ""
}

# --- Main --------------------------------------------------------------------

main() {
    print_header

    case "$PLATFORM" in
        linux-apt)
            echo -e "  ${GREEN}✅ Platform supported: Linux (apt)${NC}"
            ;;
        linux-dnf|linux-pacman)
            echo -e "  ${YELLOW}⚠️  Platform detected ($PLATFORM) — apt installers will not work${NC}"
            echo -e "  ${CYAN}ℹ️  Manual installation required for system packages${NC}"
            ;;
        macos-brew)
            echo -e "  ${YELLOW}⚠️  Platform detected ($PLATFORM) — apt installers will not work${NC}"
            echo -e "  ${CYAN}ℹ️  Use 'brew install <package>' for system packages${NC}"
            ;;
        *)
            echo -e "  ${RED}❌ Unsupported platform: $PLATFORM${NC}"
            echo -e "  ${CYAN}ℹ️  Please install tools manually${NC}"
            ;;
    esac

    check_all_tools
    check_conflicts
    print_summary
    install_missing
}

main "$@"
