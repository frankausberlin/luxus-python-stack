# Starts Jupyter Lab on localhost (secure by default).
# Usage: jl [-x] [--colab] [folder]
#   -x      start WITHOUT token (unsafe, for local development only)
#   --colab allow Google Colab origin
#   folder  notebook directory (defaults to ~/labor, "." means current directory)
jl () {
    local _use_token=1
    local _notebookdir="$HOME/labor"
    local _env_msg
    local _allow_root=""
    local _colab_origin=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -x)
                _use_token=0
                ;;
            --colab)
                _colab_origin="--ServerApp.allow_origin='https://colab.research.google.com'"
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Usage: jl [-x] [--colab] [folder]" >&2
                return 1
                ;;
            .)
                _notebookdir="$PWD"
                ;;
            *)
                _notebookdir="$1"
                ;;
        esac
        shift
    done

    [[ $EUID -eq 0 ]] && _allow_root="--allow-root"

    _env_msg=${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:-"(none)"}}

    echo -e "\n\e[95m Jupyter Lab is launching \e[0m"
    echo -e "URL:          \e[1;3;34mhttp://127.0.0.1:8888/lab/\e[0m"
    echo -e "Notebook-dir: \e[1;3;34m$_notebookdir\e[0m"
    echo -e "Environment:  $_env_msg"
    echo -e "Token:        $([[ $_use_token -eq 1 ]] && echo enabled || echo disabled)"
    echo -e "Instance:     \e[1;3;34m$(command -v jupyter)\n"

    if [[ $_use_token -eq 1 ]]; then
        jupyter lab \
            --notebook-dir="$_notebookdir" --port=8888 --no-browser \
            --ip=127.0.0.1 $_allow_root $_colab_origin
    else
        jupyter lab \
            --notebook-dir="$_notebookdir" --port=8888 --no-browser \
            --ip=127.0.0.1 $_allow_root $_colab_origin \
            --ServerApp.token='' \
            --ServerApp.disable_check_xsrf=True \
            --ServerApp.allow_credentials=True
    fi
}

# ─── pyinit ───────────────────────────────────────────────────────────────────
# Luxury Python Project Initializer — initialize a uv-based Python project.
#
# Usage:
#   pyinit                             # initialize current directory as app
#   pyinit my-project                  # create new directory and initialize as app
#   pyinit my-lib --lib                # create new directory and initialize as library
#   pyinit . --lib                     # initialize current directory as library
#   pyinit my-project --python 3.11    # specify Python version
#   pyinit my-project --force          # overwrite existing config (idempotent re-run)
pyinit() {
    local _SCRIPT_DIR
    _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # ─── Parse arguments ──────────────────────────────────────────────────────
    local _dir="."
    local _type="--app"
    local _py_version="3.12"
    local _force=0
    local _positional_count=0
    local _prev_arg=""

    for arg in "$@"; do
        case "$arg" in
            --lib)        _type="--lib" ;;
            --force)      _force=1 ;;
            --python=*)   _py_version="${arg#--python=}" ;;
            --python)     ;;  # handled by next-arg logic below
            *)
                # Ignore if this is the value after --python
                if [[ "${_prev_arg:-}" == "--python" ]]; then
                    _py_version="$arg"
                else
                    (( _positional_count++ )) || true
                    if [[ $_positional_count -eq 1 ]]; then
                        _dir="$arg"
                    fi
                fi
                ;;
        esac
        _prev_arg="$arg"
    done

    # ─── Step 1: Create and enter directory ───────────────────────────────────
    if [[ "$_dir" != "." ]]; then
        mkdir -p "$_dir"
        cd "$_dir" || return 1
    fi

    local PROJECT_NAME
    local PACKAGE_NAME
    PROJECT_NAME="$(basename "$PWD")"
    PACKAGE_NAME="${PROJECT_NAME//-/_}"
    echo -e "\e[34m💎 Initializing $_type project '${PROJECT_NAME}' (Python ${_py_version})...\e[0m"
    [[ $_force -eq 1 ]] && echo -e "\e[33m   --force: existing generated files will be overwritten.\e[0m"

    # Helper: write file only if missing (or --force)
    _write_if_missing() {
        local _path="$1"
        if [[ ! -f "$_path" || $_force -eq 1 ]]; then
            return 0  # caller should write
        else
            echo -e "\e[90m   Skipping (exists): $_path\e[0m"
            return 1  # skip
        fi
    }

    # ─── Step 2: UV init with managed Python ──────────────────────────────────
    # Force managed Python to avoid Mamba conflicts
    export UV_PYTHON_PREFERENCE=only-managed
    if [[ ! -f "pyproject.toml" || $_force -eq 1 ]]; then
        uv init "$_type" --python "$_py_version"
    else
        echo -e "\e[90m   Skipping uv init (pyproject.toml exists).\e[0m"
    fi

    # ─── Step 2b: Ensure proper directory structure ───────────────────────────
    mkdir -p "src/$PACKAGE_NAME" tests
    touch "src/$PACKAGE_NAME/__init__.py"
    touch "tests/__init__.py" "tests/conftest.py" "tests/test_placeholder.py"

    if [[ "$_type" == "--app" ]]; then
        [[ ! -f "src/$PACKAGE_NAME/main.py" ]] && touch "src/$PACKAGE_NAME/main.py"
    else
        touch "src/$PACKAGE_NAME/py.typed"  # PEP 561 marker
    fi

    rm -f hello.py

    # Add sentinel comment to version line for safe bump-my-version matching
    if grep -q '^version = "0\.1\.0"$' pyproject.toml 2>/dev/null; then
        sed -i 's/^version = "0\.1\.0"$/version = "0.1.0"  # project-version/' pyproject.toml
    fi

    # ─── Step 3: Add dev dependencies ─────────────────────────────────────────
    uv add --dev ruff pytest pytest-cov basedpyright colorlog bump-my-version pre-commit

    # ─── Step 4: VS Code configuration ────────────────────────────────────────
    mkdir -p .vscode

    if _write_if_missing ".vscode/settings.json"; then
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
    fi

    if _write_if_missing ".vscode/launch.json"; then
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
    fi

    # #26: Generate extensions.json for team/agent onboarding
    if _write_if_missing ".vscode/extensions.json"; then
cat > .vscode/extensions.json << 'EXTENSIONS_EOF'
{
    "recommendations": [
        "charliermarsh.ruff",
        "detachhead.basedpyright",
        "tamasfe.even-better-toml"
    ]
}
EXTENSIONS_EOF
    fi

    # ─── Step 5: pyproject.toml tool config ───────────────────────────────────
    # Idempotent: only append if sentinel section is missing
    if ! grep -q "tool.bumpversion" pyproject.toml 2>/dev/null; then
        cat >> pyproject.toml << TOOLS_EOF

[tool.ruff]
target-version = "py${_py_version//./}"
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "D", "UP", "B", "SIM", "RUF"]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.basedpyright]
pythonVersion = "${_py_version}"
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

[[tool.bumpversion.files]]
filename = "src/${PACKAGE_NAME}/__init__.py"
search = '__version__ = "{current_version}"'
replace = '__version__ = "{new_version}"'
TOOLS_EOF

        # Write __version__ into __init__.py so bumpversion can find it
        if ! grep -q '__version__' "src/$PACKAGE_NAME/__init__.py" 2>/dev/null; then
            printf '__version__ = "0.1.0"\n' >> "src/$PACKAGE_NAME/__init__.py"
        fi
    elif [[ $_force -eq 1 ]]; then
        echo -e "\e[33m   Note: pyproject.toml tool config already present; skipping (use manual edit to update tool config).\e[0m"
    fi

    # ─── Step 6: direnv setup ─────────────────────────────────────────────────
    if _write_if_missing ".envrc"; then
cat > .envrc << 'ENVRC_EOF'
# Deactivate any active non-base Conda environment to prevent variable leakage
if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" != "base" ]]; then
    conda deactivate 2>/dev/null || true
fi
source .venv/bin/activate
ENVRC_EOF
    fi
    direnv allow 2>/dev/null || true

    # ─── Step 7: Git + .gitignore ─────────────────────────────────────────────
    if [[ ! -d ".git" ]]; then
        git init
    fi

    if _write_if_missing ".gitignore"; then
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
JOURNAL.md
# freestyle: here you can put whatever you want
ignore/
ign/
ignored/
ignored.txt
# end of 'Luxurious Python Stack'

# Allow shared VS Code settings (override any .vscode/ ignore above)
!.vscode/settings.json
!.vscode/launch.json
!.vscode/extensions.json
GITIGNORE_EOF
    fi

    # ─── Step 8: Justfile ─────────────────────────────────────────────────────
    if _write_if_missing "Justfile"; then
cat > Justfile << 'JUST_COMMON_EOF'
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

# Audit dependencies for known security vulnerabilities
audit:
    uvx pip-audit

# Bump version — requires a clean working tree (patch | minor | major)
bump part="patch":
    #!/usr/bin/env bash
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Error: Working tree is dirty. Commit or stash changes first." >&2
        exit 1
    fi
    uv run bump-my-version bump {{part}}
JUST_COMMON_EOF

        # Append run recipe only for app projects
        if [[ "$_type" == "--app" ]]; then
cat >> Justfile << 'JUST_APP_EOF'

# Run the project
run:
    uv run python src/$(basename "$PWD" | tr '-' '_')/main.py
JUST_APP_EOF
        fi
    fi

    # ─── Step 8b: GitHub Actions CI/CD workflows ──────────────────────────────
    mkdir -p .github/workflows

    if _write_if_missing ".github/workflows/ci.yml"; then
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
      - run: uvx pip-audit   # security: check for known vulnerabilities
CI_EOF
    fi

    if _write_if_missing ".github/workflows/release.yml"; then
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
    fi

    # ─── Step 8c: Generate AGENTS.md from blueprint ───────────────────────────
    local _BLUEPRINT="${_SCRIPT_DIR}/../references/blueprint-AGENTS.md"
    if _write_if_missing "AGENTS.md"; then
        if [[ -f "$_BLUEPRINT" ]]; then
            sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
                -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
                "$_BLUEPRINT" > AGENTS.md
            echo -e "\e[34m   Generated AGENTS.md from blueprint.\e[0m"
        else
            echo -e "\e[33m   Warning: blueprint-AGENTS.md not found, skipping AGENTS.md generation.\e[0m"
        fi
    fi

    # ─── Step 8d: Generate README.md ──────────────────────────────────────────
    if _write_if_missing "README.md"; then
cat > README.md << README_EOF
# ${PROJECT_NAME}

## Getting Started

\`\`\`bash
uv sync
just check
\`\`\`

## Development

\`\`\`bash
just test       # run tests
just lint       # lint + type check
just fix        # auto-fix lint issues
just check      # full quality gate
\`\`\`

## Release

\`\`\`bash
just bump patch   # 0.1.0 → 0.1.1
git push origin main --tags
\`\`\`

See [AGENTS.md](AGENTS.md) for AI agent guidelines.
README_EOF
    fi

    # ─── Step 8e: .editorconfig ───────────────────────────────────────────────
    if _write_if_missing ".editorconfig"; then
cat > .editorconfig << 'EDITORCONFIG_EOF'
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[*.{yml,yaml,toml,json}]
indent_size = 2

[Makefile]
indent_style = tab
EDITORCONFIG_EOF
    fi

    # ─── Step 8f: CONTRIBUTING.md ─────────────────────────────────────────────
    if _write_if_missing "CONTRIBUTING.md"; then
cat > CONTRIBUTING.md << CONTRIBUTING_EOF
# Contributing to ${PROJECT_NAME}

## Development Setup

\`\`\`bash
git clone <repo-url>
cd ${PROJECT_NAME}
direnv allow      # auto-activates .venv (or run: source .venv/bin/activate)
uv sync           # install all dependencies
\`\`\`

## Workflow

1. Create a feature branch: \`git checkout -b feature/my-feature\`
2. Make your changes
3. Run the quality gate: \`just check\`
4. Commit (pre-commit hooks run automatically): \`git add -A && git commit -m "feat: ..."\`
5. Push and open a pull request

## Quality Gate

\`\`\`bash
just lint         # ruff + basedpyright
just typecheck    # type checking only
just test         # pytest with coverage
just check        # full gate (lint + typecheck + tests)
just fix          # auto-fix formatting and lint issues
\`\`\`

## Conventions

- **Python version:** ${_py_version}
- **Typing:** Strict — all public functions must have type annotations
- **Docstrings:** Google style
- **Imports:** Sorted by ruff (isort-compatible)
- **Line length:** 120 characters

## Versioning

Never edit version numbers manually. Use:

\`\`\`bash
just bump patch   # bugfix: 0.1.0 → 0.1.1
just bump minor   # feature: 0.1.1 → 0.2.0
just bump major   # breaking: 0.2.0 → 1.0.0
\`\`\`

See [AGENTS.md](AGENTS.md) for AI agent guidelines.
CONTRIBUTING_EOF
    fi

    # ─── Step 8g: LICENSE file ────────────────────────────────────────────────
    if _write_if_missing "LICENSE"; then
        local _current_year
        _current_year="$(date +%Y)"
cat > LICENSE << LICENSE_EOF
MIT License

Copyright (c) ${_current_year} $(git config user.name 2>/dev/null || echo "Project Author")

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE_EOF
    fi

    # ─── Step 9: pre-commit setup ─────────────────────────────────────────────
    if _write_if_missing ".pre-commit-config.yaml"; then
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
    fi

    # ─── Step 9b: MkDocs documentation (library projects only) ───────────────
    if [[ "$_type" == "--lib" ]]; then
        uv add --dev "mkdocs-material" "mkdocstrings[python]" 2>/dev/null || true

        if _write_if_missing "mkdocs.yml"; then
cat > mkdocs.yml << MKDOCS_EOF
site_name: ${PROJECT_NAME}
site_description: Documentation for ${PROJECT_NAME}
repo_url: https://github.com/YOUR_ORG/${PROJECT_NAME}

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate
    - search.suggest

plugins:
  - search
  - mkdocstrings:
      handlers:
        python:
          options:
            docstring_style: google
            show_source: true
            show_root_heading: true

nav:
  - Home: index.md
  - API Reference: api.md
MKDOCS_EOF
        fi

        mkdir -p docs
        if _write_if_missing "docs/index.md"; then
cat > docs/index.md << DOCS_INDEX_EOF
# ${PROJECT_NAME}

## Getting Started

\`\`\`bash
uv sync
just check
\`\`\`

## Installation

\`\`\`bash
pip install ${PROJECT_NAME}
\`\`\`

## Quick Start

\`\`\`python
import ${PACKAGE_NAME}
\`\`\`
DOCS_INDEX_EOF
        fi

        if _write_if_missing "docs/api.md"; then
cat > docs/api.md << DOCS_API_EOF
# API Reference

::: ${PACKAGE_NAME}
DOCS_API_EOF
        fi

        # Add docs recipe to Justfile (idempotent: only append if not present)
        if ! grep -q "^docs:" Justfile 2>/dev/null; then
cat >> Justfile << 'JUST_DOCS_EOF'

# Build documentation
docs:
    uv run mkdocs build

# Serve documentation locally (with live reload)
docs-serve:
    uv run mkdocs serve
JUST_DOCS_EOF
        fi

        echo -e "\e[34m   MkDocs documentation scaffolded (docs/, mkdocs.yml).\e[0m"
    fi

    # ─── Step 10: Final sync & install hooks ──────────────────────────────────
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

    unset -f _write_if_missing
}
