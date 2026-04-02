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
#   - pyproject.toml with ruff, basedpyright, pytest, and bump-my-version config
#   - .vscode/settings.json with Ruff formatter (strict type checking)
#   - .vscode/launch.json for debugging
#   - .envrc for direnv auto-activation (with conda deactivation guard)
#   - .gitignore from gitignore.io (Python + Linux + VSCode)
#   - Dev dependencies: ruff pytest pytest-cov basedpyright colorlog bump-my-version pre-commit
#   - Git repository (if not already initialized)
#   - Justfile for task running
#   - .pre-commit-config.yaml for local quality checks (hygiene + ruff, no basedpyright)
#   - .github/workflows/ci.yml and release.yml (Level 3: CI/CD)
#   - AGENTS.md from blueprint template (Level 4: AI Agent Guidelines)

set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
PACKAGE_NAME="${PROJECT_NAME//-/_}"
echo -e "\e[34m💎 Initializing $_type project in ${PROJECT_NAME}...\e[0m"

# ─── Step 2: UV init with managed Python ──────────────────────────────────────
# Force managed Python to avoid Mamba conflicts
export UV_PYTHON_PREFERENCE=only-managed
uv init "$_type" --python 3.12

# ─── Step 2b: Ensure proper directory structure ───────────────────────────────
mkdir -p "src/$PACKAGE_NAME" tests
touch "src/$PACKAGE_NAME/__init__.py"
touch "tests/__init__.py" "tests/conftest.py" "tests/test_placeholder.py"

if [[ "$_type" == "--app" ]]; then
    touch "src/$PACKAGE_NAME/main.py"
else
    touch "src/$PACKAGE_NAME/py.typed"
fi

rm -f hello.py

# Add sentinel comment to version line for safe bump-my-version matching
sed -i 's/^version = "0.1.0"/version = "0.1.0"  # project-version/' pyproject.toml

# ─── Step 3: Add dev dependencies ─────────────────────────────────────────────
uv add --dev ruff pytest pytest-cov basedpyright colorlog bump-my-version pre-commit

# ─── Step 4: VS Code configuration ────────────────────────────────────────────
mkdir -p .vscode
cat > .vscode/settings.json << 'VSCODE_EOF'
{
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.analysis.typeCheckingMode": "strict",
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
cat >> pyproject.toml << 'TOOLS_EOF'

[tool.ruff]
target-version = "py312"
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "D", "UP", "B", "SIM", "RUF"]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.basedpyright]
pythonVersion = "3.12"
typeCheckingMode = "strict"
venvPath = "."
venv = ".venv"

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
addopts = "-ra -q"

[tool.bumpversion]
current_version = "0.1.0"
commit = true
tag = true
message = "chore: bump version from {current_version} to {new_version}"

[[tool.bumpversion.files]]
filename = "pyproject.toml"
search = 'version = "{current_version}"  # project-version'
replace = 'version = "{new_version}"  # project-version'
TOOLS_EOF

# ─── Step 6: direnv setup ─────────────────────────────────────────────────────
cat > .envrc << 'ENVRC_EOF'
# Deactivate any active non-base Conda environment to prevent variable leakage
if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" != "base" ]]; then
    conda deactivate 2>/dev/null || true
fi
source .venv/bin/activate
ENVRC_EOF
direnv allow

# ─── Step 7: Git + .gitignore ─────────────────────────────────────────────────
if [[ ! -d ".git" ]]; then
    git init
fi

# Fetch gitignore from gitignore.io with local fallback for offline/bootstrap use
if ! curl -fsSL -o .gitignore "https://www.toptal.com/developers/gitignore/api/python,linux,vscode"; then
    cat > .gitignore << 'GITIGNORE_BASE_EOF'
# Fallback .gitignore generated by Luxurious Python Stack
__pycache__/
*.py[cod]
*.so
.Python
.venv/
.env
.direnv/
.pytest_cache/
.ruff_cache/
.mypy_cache/
.coverage
htmlcov/
dist/
build/
*.egg-info/
.vscode/
GITIGNORE_BASE_EOF
fi

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
if [[ "$_type" == "--app" ]]; then
cat > Justfile << 'JUST_EOF'
set shell := ["bash", "-uc"]

# Run the project
run:
    uv run python src/$(basename "$PWD" | tr '-' '_')/main.py

# Run tests with coverage report
test:
    uv run pytest --cov=src --cov-report=term-missing

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
    uv run pytest --cov=src --cov-report=term-missing

# Fix linting issues
fix:
    uv run ruff check --fix .
    uv run ruff format .

# Bump version (patch, minor, major)
bump part="patch":
    uv run bump-my-version {{part}}
JUST_EOF
else
cat > Justfile << 'JUST_EOF'
set shell := ["bash", "-uc"]

# Run tests with coverage report
test:
    uv run pytest --cov=src --cov-report=term-missing

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
    uv run pytest --cov=src --cov-report=term-missing

# Fix linting issues
fix:
    uv run ruff check --fix .
    uv run ruff format .

# Bump version (patch, minor, major)
bump part="patch":
    uv run bump-my-version {{part}}
JUST_EOF
fi

# ─── Step 8b: GitHub Actions CI/CD workflows ──────────────────────────────────
mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'CI_EOF'
name: CI
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --dev
      - run: just check
CI_EOF

cat > .github/workflows/release.yml << 'RELEASE_EOF'
name: Release
on:
  push:
    tags: ["v*"]
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv build
      - run: uv publish
RELEASE_EOF

# ─── Step 8c: Generate AGENTS.md from blueprint ───────────────────────────────
_BLUEPRINT="${_SCRIPT_DIR}/../references/blueprint-AGENTS.md"
if [[ -f "$_BLUEPRINT" ]]; then
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
        "$_BLUEPRINT" > AGENTS.md
    echo -e "\e[34m   Generated AGENTS.md from blueprint.\e[0m"
else
    echo -e "\e[33m   Warning: blueprint-AGENTS.md not found, skipping AGENTS.md generation.\e[0m"
fi

# ─── Step 9: pre-commit setup ─────────────────────────────────────────────────
cat > .pre-commit-config.yaml << 'PRECOMMIT_EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
  - repo: local
    hooks:
      - id: ruff-check
        name: ruff check
        entry: uv run ruff check --force-exclude
        language: system
        types_or: [python, pyi]
      - id: ruff-format
        name: ruff format
        entry: uv run ruff format --force-exclude
        language: system
        types_or: [python, pyi]
# Note: basedpyright runs in `just check` and CI, not as a pre-commit hook.
# Full-codebase type checking on every commit is too slow for interactive work.
PRECOMMIT_EOF

# ─── Step 10: Final sync & install hooks ──────────────────────────────────────
uv sync
uv run pre-commit install

echo ""
echo -e "\e[32m✨ Success! Project '${PROJECT_NAME}' is ready.\e[0m"
echo ""
echo "  Next steps:"
echo "  1. direnv allow   (if not yet activated)"
if [[ "$_type" == "--app" ]]; then
    echo "  2. Start coding in src/${PACKAGE_NAME}/"
    echo "  3. Run the app with: just run"
    echo "  4. Run tests with:   just test"
    echo "  5. Lint with:        just lint"
    echo "  6. Auto-fix:         just fix"
    echo "  7. Full gate:        just check"
else
    echo "  2. Start coding in src/${PACKAGE_NAME}/"
    echo "  3. Run tests with: just test"
    echo "  4. Lint with:      just lint"
    echo "  5. Auto-fix:       just fix"
    echo "  6. Full gate:      just check"
fi
echo ""
echo "  To release:"
echo "  just bump patch"
echo "  git push origin main --tags"
