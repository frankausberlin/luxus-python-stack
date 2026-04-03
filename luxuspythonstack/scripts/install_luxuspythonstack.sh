#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
INSTALL_DIR="$HOME/.local/share/luxuspythonstack"
LUXUS_BLOCK_START="# >>> Luxus Python Stack >>>"
LUXUS_BLOCK_END="# <<< Luxus Python Stack <<<"
DIRENV_HOOK='eval "$(direnv hook bash)"'

# ── Supply chain: pinnable versions ───────────────────────────────────────────
# Override these env vars to pin specific versions:
#   MINIFORGE_VERSION=25.3.0-1 bash install_luxuspythonstack.sh
MINIFORGE_VERSION="${MINIFORGE_VERSION:-latest}"   # or e.g. "25.3.0-1"
MINIFORGE_INSTALLER="Miniforge3-$(uname)-$(uname -m).sh"

# ─── Step 1: System packages ──────────────────────────────────────────────────
sudo apt update && sudo apt install -y python3 direnv curl git sha256sum

# ─── Step 2: Miniforge / Mamba ────────────────────────────────────────────────
if [[ ! -d "$HOME/miniforge3" ]]; then
    if [[ "$MINIFORGE_VERSION" == "latest" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE_INSTALLER}"
    else
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/${MINIFORGE_INSTALLER}"
    fi
    echo "Downloading Miniforge from: $MINIFORGE_URL"
    curl -L -O "$MINIFORGE_URL"

    # Verify checksum if a sha256 file is available alongside the release
    CHECKSUM_URL="${MINIFORGE_URL}.sha256"
    if curl -fsSL -o "${MINIFORGE_INSTALLER}.sha256" "$CHECKSUM_URL" 2>/dev/null; then
        sha256sum -c "${MINIFORGE_INSTALLER}.sha256" || {
            echo "ERROR: Miniforge checksum verification failed." >&2
            rm -f "$MINIFORGE_INSTALLER" "${MINIFORGE_INSTALLER}.sha256"
            exit 1
        }
        rm -f "${MINIFORGE_INSTALLER}.sha256"
        echo "Miniforge checksum verified."
    else
        echo "Warning: No checksum file found for Miniforge — skipping verification." >&2
    fi

    bash "$MINIFORGE_INSTALLER" -b -p "$HOME/miniforge3"
    rm -f "$MINIFORGE_INSTALLER"
fi
"$HOME/miniforge3/bin/conda" init bash

# ─── Step 3: UV ───────────────────────────────────────────────────────────────
command -v uv &>/dev/null || { curl -LsSf https://astral.sh/uv/install.sh | sh; }
export PATH="$HOME/.local/bin:$PATH"

# ─── Step 4: Global tools (idempotent) ────────────────────────────────────────
uv tool list | grep -q "^ruff "         || uv tool install ruff@latest
uv tool list | grep -q "^basedpyright " || uv tool install basedpyright
uv tool list | grep -q "^just "         || uv tool install rust-just

# ─── Step 5: Copy scripts to stable canonical location ────────────────────────
# This makes the installation relocatable: moving the repo won't break shells.
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/.bash_lib_luxuspythonstack" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/pyinit.sh"                  "$INSTALL_DIR/"
cp "$SCRIPT_DIR/launch_jupyter.sh"          "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/pyinit.sh" "$INSTALL_DIR/launch_jupyter.sh"

# ─── Step 6: Write managed bashrc block (replace on re-runs) ──────────────────
# Remove any existing managed block so re-runs replace instead of appending.
if grep -Fq "$LUXUS_BLOCK_START" "$BASHRC" 2>/dev/null; then
    # Use awk to delete the managed block including surrounding blank lines
    awk "
        /$LUXUS_BLOCK_START/{found=1; next}
        /$LUXUS_BLOCK_END/{found=0; next}
        !found{print}
    " "$BASHRC" > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "$BASHRC"
fi

# Append fresh block with failure-tolerant activation
cat >> "$BASHRC" <<EOF

$LUXUS_BLOCK_START
# Source the Luxus shell library (guards against missing file)
[[ -f "$INSTALL_DIR/.bash_lib_luxuspythonstack" ]] && \\
    source "$INSTALL_DIR/.bash_lib_luxuspythonstack"
# Restore saved Mamba environment (failure-tolerant)
if command -v mamba &>/dev/null; then
    _luxus_env=\$([[ -f "\$HOME/.startenv" ]] && cat "\$HOME/.startenv" || echo "base")
    mamba activate "\$_luxus_env" 2>/dev/null || mamba activate base 2>/dev/null || true
fi
$LUXUS_BLOCK_END
EOF

# ─── Step 7: direnv hook (must be last) ───────────────────────────────────────
if ! grep -Fqx "$DIRENV_HOOK" "$BASHRC" 2>/dev/null; then
    printf '\n# direnv hook (MUST BE AT THE END)\n%s\n' "$DIRENV_HOOK" >> "$BASHRC"
fi

# ─── Step 8: git defaults ─────────────────────────────────────────────────────
git config --global init.defaultBranch main

# ─── Done: post-install summary ───────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       Luxus Python Stack — Installation Complete         ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║ Scripts installed to: $INSTALL_DIR"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║ Installed versions:"
printf "║  uv:            %s\n" "$(uv --version 2>/dev/null || echo 'not found')"
printf "║  mamba:         %s\n" "$("$HOME/miniforge3/bin/mamba" --version 2>/dev/null | head -1 || echo 'not found')"
printf "║  direnv:        %s\n" "$(direnv --version 2>/dev/null || echo 'not found')"
printf "║  ruff:          %s\n" "$(uv tool run ruff --version 2>/dev/null || echo 'not found')"
printf "║  basedpyright:  %s\n" "$(uv tool run basedpyright --version 2>/dev/null || echo 'not found')"
printf "║  just:          %s\n" "$(just --version 2>/dev/null || echo 'not found')"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║ Next step: source ~/.bashrc"
echo "╚══════════════════════════════════════════════════════════╝"
