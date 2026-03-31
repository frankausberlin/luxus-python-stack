#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
BASH_LIB="$SCRIPT_DIR/.bash_lib_luxuspythonstack"
MINIFORGE_INSTALLER="Miniforge3-$(uname)-$(uname -m).sh"
LUXUS_BLOCK_START="# >>> Luxus Python Stack >>>"
LUXUS_BLOCK_END="# <<< Luxus Python Stack <<<"
DIRENV_HOOK='eval "$(direnv hook bash)"'

sudo apt update && sudo apt install -y python3 direnv curl git

if [[ ! -d "$HOME/miniforge3" ]]; then
    curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE_INSTALLER}"
    bash "$MINIFORGE_INSTALLER" -b -p "$HOME/miniforge3"
    rm -f "$MINIFORGE_INSTALLER"
fi

"$HOME/miniforge3/bin/conda" init bash

curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

uv tool install ruff@latest
uv tool install basedpyright
uv tool install rust-just

if ! grep -Fq "$LUXUS_BLOCK_START" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<EOF

$LUXUS_BLOCK_START
source "$BASH_LIB"
mamba activate \$([[ -f \$HOME/.startenv ]] && cat \$HOME/.startenv || echo base)
$LUXUS_BLOCK_END
EOF
fi

if ! grep -Fqx "$DIRENV_HOOK" "$BASHRC" 2>/dev/null; then
    printf '\n# direnv hook (MUST BE AT THE END)\n%s\n' "$DIRENV_HOOK" >> "$BASHRC"
fi

# use main trunk
git config --global init.defaultBranch main

echo "Luxus Python Stack installed. Reload your shell with: source ~/.bashrc"
