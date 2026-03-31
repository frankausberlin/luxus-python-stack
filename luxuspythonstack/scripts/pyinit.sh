#!/usr/bin/env bash
# pyinit.sh — Luxury Python Project Initializer
# Part of the Luxurious Python Stack
#
# Usage:
#   bash pyinit.sh                   # initialize current directory as app
#   bash pyinit.sh my-project        # create new directory and initialize as app
#   bash pyinit.sh my-lib --lib      # create new directory and initialize as library
#   bash pyinit.sh . --lib           # initialize current directory as library
#
# What it creates:
#   - uv project (app or library) with Python 3.12
#   - .venv/ virtual environment
#   - .python-version pin
#   - pyproject.toml with bump-my-version config
#   - .vscode/settings.json with Ruff formatter
#   - .vscode/launch.json for debugging
#   - .envrc for direnv auto-activation
#   - .gitignore from gitignore.io (Python + Linux + VSCode)
#   - Dev dependencies: ruff pytest basedpyright colorlog bump-my-version pre-commit
#   - Git repository (if not already initialized)
#   - Justfile for task running
#   - .pre-commit-config.yaml for local quality checks

set -euo pipefail

# ─── Parse arguments ──────────────────────────────────────────────────────────
_dir="."
_type="--app"

for arg in "$@"; do
    case "$arg" in
        --lib)  _type="--lib" ;;
        *)      _dir="$arg" ;;
    esac
done

# ─── Step 1: Create and enter directory ───────────────────────────────────────
if [[ "$_dir" != "." ]]; then
    mkdir -p "$_dir"
    cd "$_dir"
fi

PROJECT_NAME="$(basename "$PWD")"
echo -e "\e[34m💎 Initializing $_type project in ${PROJECT_NAME}...\e[0m"

# ─── Step 2: UV init with managed Python ──────────────────────────────────────
# Force managed Python to avoid Mamba conflicts
export UV_PYTHON_PREFERENCE=only-managed
uv init "$_type" --python 3.12

# ─── Step 3: Add dev dependencies ─────────────────────────────────────────────
uv add --dev ruff pytest basedpyright colorlog bump-my-version pre-commit

# ─── Step 4: VS Code configuration ────────────────────────────────────────────
mkdir -p .vscode
cat > .vscode/settings.json << 'VSCODE_EOF'
{
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.analysis.typeCheckingMode": "standard",
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.codeActionsOnSave": {
        "source.fixAll.ruff": "always",
        "source.organizeImports.ruff": "always"
    },
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": [
        "src",
        "tests"
    ],
    "python.terminal.activateEnvironment": true
}
VSCODE_EOF

cat > .vscode/launch.json << 'LAUNCH_EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": false
        },
        {
            "name": "Python: Pytest",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": ["-s", "${file}"],
            "console": "integratedTerminal"
        }
    ]
}
LAUNCH_EOF

# ─── Step 5: bump-my-version config ───────────────────────────────────────────
cat >> pyproject.toml << 'BUMP_EOF'

[tool.bumpversion]
current_version = "0.1.0"
commit = true
tag = true
message = "chore: bump version from {current_version} to {new_version}"

[[tool.bumpversion.files]]
filename = "pyproject.toml"
search = 'version = "{current_version}"'
replace = 'version = "{new_version}"'
BUMP_EOF

# ─── Step 6: direnv setup ─────────────────────────────────────────────────────
echo "source .venv/bin/activate" > .envrc
direnv allow

# ─── Step 7: Git + .gitignore ─────────────────────────────────────────────────
if [[ ! -d ".git" ]]; then
    git init
fi

# Fetch gitignore from gitignore.io
curl -s "https://www.toptal.com/developers/gitignore/api/python,linux,vscode" > .gitignore

# Append Luxurious Python Stack additions
cat >> .gitignore << 'GITIGNORE_EOF'

# Added by 'Luxurious Python Stack'
# volatile, agent-generated data
SESSION.md
# freestyle: here you can put whatever you want
ignore/
ign/
ignored/
ignored.txt
# end of 'Luxurious Python Stack'
GITIGNORE_EOF

# ─── Step 8: Justfile setup ───────────────────────────────────────────────────
cat > Justfile << 'JUST_EOF'
set shell := ["bash", "-uc"]

# Run the project
run:
    uv run python src/$(basename "$PWD" | tr '-' '_')/main.py

# Run tests
test:
    uv run pytest

# Run linters and type checker (find errors)
lint:
    uv run ruff check .
    uv run ruff format --check .
    uv run basedpyright

# Type check only
typecheck:
    uv run basedpyright

# Full local quality gate (lint + typecheck + tests)
check:
    uv run ruff check .
    uv run ruff format --check .
    uv run basedpyright
    uv run pytest

# Fix linting issues
fix:
    uv run ruff check --fix .
    uv run ruff format .

# Bump version (patch, minor, major)
bump part="patch":
    uv run bump-my-version {{part}}
JUST_EOF

# ─── Step 9: pre-commit setup ─────────────────────────────────────────────────
cat > .pre-commit-config.yaml << 'PRECOMMIT_EOF'
repos:
  - repo: local
    hooks:
      - id: ruff-check
        name: ruff check
        entry: uv run ruff check --force-exclude
        language: system
        types_or: [python, pyi]
        require_serial: true
      - id: ruff-format
        name: ruff format
        entry: uv run ruff format --force-exclude
        language: system
        types_or: [python, pyi]
        require_serial: true
      - id: basedpyright
        name: basedpyright
        entry: uv run basedpyright
        language: system
        types_or: [python, pyi]
        pass_filenames: false
PRECOMMIT_EOF

# ─── Step 10: Final sync & install hooks ──────────────────────────────────────
uv sync
uv run pre-commit install

echo ""
echo -e "\e[32m✨ Success! Project '${PROJECT_NAME}' is ready.\e[0m"
echo ""
echo "  Next steps:"
echo "  1. direnv allow   (if not yet activated)"
echo "  2. Start coding in src/${PROJECT_NAME//-/_}/"
echo "  3. Run tests with: just test"
echo "  4. Lint with:      just lint"
echo "  5. Auto-fix:       just fix"
echo "  6. Full gate:      just check"
echo ""
echo "  To release:"
echo "  just bump patch"
echo "  git push origin main --tags"
