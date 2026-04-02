# Prioritized Improvements for the Luxurious Python Stack

Your stack is exceptionally well-designed — the five-level architecture cleanly separates volatile data-science work from deterministic project environments, and the `uv`/`direnv` integration with AI agent guidelines is genuinely forward-thinking. That said, there are real gaps between what your documentation promises and what the scripts actually enforce. Here's a comprehensive, prioritized improvement plan.

---

## 🔴 Critical — Security & Correctness

### 1. Jupyter Lab runs with authentication and XSRF protection disabled by default

In `launch_jupyter.sh`, the default mode (no `-x` flag) sets `--ServerApp.token='' --ServerApp.disable_check_xsrf=True --ServerApp.allow_credentials=True`. Combined with `--allow-root`, this means any process on the machine — or any website open in another browser tab — can execute arbitrary code via the Jupyter API on localhost:8888.

**Fix:** Invert the default. Token-on should be the standard mode; add a `--unsafe` or `--no-token` flag for the rare convenience case. Additionally:
- Bind explicitly to `127.0.0.1` (not `localhost`, which can resolve to `0.0.0.0` on some systems).
- Only pass `--allow-root` when actually running as root.
- Make the `--ServerApp.allow_origin='https://colab.research.google.com'` conditional — only include it when Colab integration is actually needed (e.g., via a `--colab` flag), rather than always allowing that origin.

### 2. `pyinit.sh` does not create the directory structure the entire stack assumes

`uv init --app` creates a flat `hello.py`; `uv init --lib` creates `src/<package>/__init__.py` but no tests. Meanwhile, every other document (`AGENTS.md`, `daily-commands.md`, the Justfile's `run` recipe, coverage config) assumes `src/<package>/main.py` and `tests/` exist.

**Fix:** After `uv init`, add explicit scaffolding:
```bash
mkdir -p "src/$PACKAGE_NAME" tests
touch "src/$PACKAGE_NAME/__init__.py"
touch "tests/__init__.py" "tests/conftest.py" "tests/test_placeholder.py"
[[ "$_type" == "--app" ]] && touch "src/$PACKAGE_NAME/main.py"
[[ "$_type" == "--lib" ]] && touch "src/$PACKAGE_NAME/py.typed"  # PEP 561
```
The `py.typed` marker is required for library projects so downstream type checkers recognize inline type annotations.

### 3. The `bump-my-version` search pattern is fragile

The search string `version = "{current_version}"` will match the *first* occurrence in `pyproject.toml` — which could be a dependency pin, `requires-python`, or any other `version =` line. This can silently corrupt your project file.

**Fix:** Use a regex with section context, or add a unique comment sentinel:
```toml
[[tool.bumpversion.files]]
filename = "pyproject.toml"
search = "version = \"{current_version}\"  # project-version"
replace = "version = \"{new_version}\"  # project-version"
```
Then ensure `pyinit.sh` writes the version line with that sentinel.

### 4. The `SESSION.md` workflow is self-contradictory

In `daily-commands.md`, the session-end script runs `git add SESSION.md` and then comments *"SESSION.md is in .gitignore, this won't commit it."* In reality, `git add` on an ignored file either silently does nothing or errors depending on git configuration.

**Fix:** Remove the misleading `git add SESSION.md` line entirely. If the intent is to never track it, the `.gitignore` entry is sufficient. If it should occasionally be force-tracked, use `git add -f SESSION.md` and document why.

### 5. Fix the terminal line-wrapping bug in the `PS1` prompt

In `.bash_lib_luxuspythonstack`, the `python_info()` function echoes raw ANSI escape codes (e.g., `\033[1;31m`). Because these are injected into `PS1` via `$(python_info)` command substitution *without* being wrapped in `\[` and `\]`, Bash counts them as printable characters. This causes the cursor to overwrite the current line instead of wrapping when commands reach the terminal edge — making editing impossible.

**Fix:** Have `python_info()` output only plain text, and apply all coloring directly within the `PS1` string where `\[` / `\]` are properly evaluated:
```bash
python_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "(venv: $(basename "$PWD"))"
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        echo "(mamba: $CONDA_DEFAULT_ENV)"
    fi
}
```
Note: also fix the logic — the current code checks for `[[ -d "./.venv" ]]` which detects the *directory's existence*, not whether the venv is actually active. Check `$VIRTUAL_ENV` instead.

---

## 🟠 High — Robustness & Completeness

### 6. `pyinit.sh` generates no tool configuration, violating documented standards

The docs promise strict typing, Google-style docstrings, and a rigorous quality gate. But `pyinit.sh` writes zero configuration for `ruff`, `basedpyright`, or `pytest` into `pyproject.toml`. VS Code settings even say `"typeCheckingMode": "standard"` instead of `"strict"`. Every new project silently starts weaker than the stack promises.

**Fix:** Have `pyinit.sh` append configuration blocks to `pyproject.toml`:
```toml
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
```
The `pythonpath = ["src"]` setting is *critical* for the `src/` layout to work without editable installs — its absence is a common cause of `ModuleNotFoundError` when running `pytest`.

### 7. Level 3 (CI/CD) is documented but never scaffolded

`pyinit.sh` generates zero GitHub Actions workflow files despite Level 3 being a core tier of the stack architecture.

**Fix:** Generate at least two workflow files:

`.github/workflows/ci.yml` — runs `just check` on push/PR:
```yaml
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
```

`.github/workflows/release.yml` — builds and publishes on version tags:
```yaml
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
```

### 8. `pyinit.sh` should generate `AGENTS.md` from the blueprint

`blueprint-AGENTS.md` exists as a template with `{{PROJECT_NAME}}` and `{{PACKAGE_NAME}}` placeholders, but `pyinit.sh` never uses it. Level 4 remains entirely manual.

**Fix:** Add a step to `pyinit.sh`:
```bash
if [[ -f "$_LUXUS_SCRIPTS_DIR/../blueprint-AGENTS.md" ]]; then
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" \
        "$_LUXUS_SCRIPTS_DIR/../blueprint-AGENTS.md" > AGENTS.md
fi
```

### 9. Conda environment variables leak into Level 2 `direnv` projects

When you `cd` from an active Mamba environment (Level 1) into a `uv` project directory (Level 2), `direnv` loads `.venv/bin/activate`, but Conda variables like `$CONDA_PREFIX`, `$CONDA_DEFAULT_ENV`, and especially `LD_LIBRARY_PATH` persist. This can cause segfaults, wrong shared library loading, or confusing import behavior.

**Fix:** Write a smarter `.envrc` in `pyinit.sh`:
```bash
cat > .envrc << 'ENVRC_EOF'
if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" != "base" ]]; then
    conda deactivate 2>/dev/null || true
fi
source .venv/bin/activate
ENVRC_EOF
```

### 10. Move `basedpyright` out of `pre-commit` hooks

The current `.pre-commit-config.yaml` runs `basedpyright` with `pass_filenames: false` as a pre-commit hook. This forces a *full codebase* type-check on every single commit — even if you only changed a README. As the project grows, this will take 10+ seconds per commit, destroying flow.

**Fix:** Remove `basedpyright` from the pre-commit config. It already runs in `just check` and will run in CI. Instead, add lightweight hygiene hooks:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
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
```
If you want type checking before code leaves your machine, add it as a `pre-push` hook — not `pre-commit`.

### 11. Make the installer relocatable and update-safe

`install_luxuspythonstack.sh` writes an absolute `source "/home/user/some/path/.bash_lib_luxuspythonstack"` into `~/.bashrc`. If the repository is moved, renamed, or deleted, every new shell will error on startup.

**Fix:** Copy the shell library and scripts to a stable, canonical location:
```bash
INSTALL_DIR="$HOME/.local/share/luxuspythonstack"
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/.bash_lib_luxuspythonstack" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/pyinit.sh" "$SCRIPT_DIR/launch_jupyter.sh" "$INSTALL_DIR/"
# Then source from the stable path:
# source "$HOME/.local/share/luxuspythonstack/.bash_lib_luxuspythonstack"
```
Also, on re-runs, *replace* the managed block instead of append-only behavior, and verify the sourced file exists before sourcing it.

### 12. Make shell startup failure-tolerant

If the saved Mamba environment in `~/.startenv` no longer exists, or `mamba` isn't available, the bashrc block will error on every terminal open.

**Fix:**
```bash
$LUXUS_BLOCK_START
[[ -f "$HOME/.local/share/luxuspythonstack/.bash_lib_luxuspythonstack" ]] && \
    source "$HOME/.local/share/luxuspythonstack/.bash_lib_luxuspythonstack"
if command -v mamba &>/dev/null; then
    _env=$([[ -f "$HOME/.startenv" ]] && cat "$HOME/.startenv" || echo "base")
    mamba activate "$_env" 2>/dev/null || mamba activate base 2>/dev/null || true
fi
$LUXUS_BLOCK_END
```

### 13. `pyinit.sh` is not idempotent

Re-running `pyinit.sh` appends a *duplicate* `[tool.bumpversion]` section to `pyproject.toml`, appends another "Luxurious Python Stack" block to `.gitignore`, and overwrites VS Code, Justfile, and pre-commit config.

**Fix:**
- Use markers/sentinels (e.g., `# >>> Luxus Python Stack >>>`) around generated blocks and skip or replace them on re-runs.
- Check for existing config before appending: `grep -q "tool.bumpversion" pyproject.toml || cat >> pyproject.toml << ...`
- Add `--force` / `--fresh` flags for intentional overwrites.
- Validate arguments properly — currently, the last non-flag argument silently becomes the directory name.

---

## 🟡 Medium — Quality & Maintainability

### 14. Reduce documentation duplication and drift

Commands for dependencies, testing, code quality, and releasing are repeated nearly verbatim across `blueprint-AGENTS.md`, `daily-commands.md`, and `luxus-python-stack.md`. They are already drifting:
- Docs say strict typing; scaffold uses `"standard"`.
- `daily-commands.md` suggests `uv pip install` is okay for Level 3; CI should be lockfile-driven only.
- Agent workflow ordering differs between documents.

**Fix:** Make `daily-commands.md` a pure cheat-sheet (commands only, no prose). Keep `luxus-python-stack.md` as the rationale document. Treat `pyinit.sh` + generated `pyproject.toml` as the canonical source of truth. Cross-link instead of duplicating.

### 15. `AGENTS.md` quality gate section is inconsistent with the Justfile

`AGENTS.md` lists `ruff check .` under "Linting & Formatting," but the actual Justfile's `check` recipe also runs `ruff format --check .` as a separate step. An agent following AGENTS.md literally will miss format violations.

**Fix:** Update `blueprint-AGENTS.md` to match the actual Justfile recipes exactly, or better yet, just say "run `just check`" and don't enumerate the individual commands.

### 16. `__init__.py` is mentioned but not tracked by `bump-my-version`

`AGENTS.md` warns agents never to change versions in `__init__.py`, implying it should contain `__version__`. But the bumpversion config only targets `pyproject.toml`.

**Fix:** Either add a `[[tool.bumpversion.files]]` entry for `src/<package>/__init__.py`, or remove the mention from AGENTS.md and rely solely on `importlib.metadata.version()` at runtime.

### 17. Eliminate Justfile duplication between app and lib modes

The two Justfile heredocs in `pyinit.sh` differ only by the `run` recipe. This is a maintenance trap — any fix to one must be manually replicated in the other.

**Fix:** Write the common recipes once and conditionally append `run` for app projects:
```bash
cat > Justfile << 'JUST_COMMON_EOF'
# ... all shared recipes ...
JUST_COMMON_EOF

if [[ "$_type" == "--app" ]]; then
cat >> Justfile << 'JUST_APP_EOF'
# Run the project
run:
    uv run python src/$(basename "$PWD" | tr '-' '_')/main.py
JUST_APP_EOF
fi
```

### 18. The Justfile `bump` recipe doesn't enforce a clean working tree

The documentation says "ensure the working tree is clean," but the recipe runs `bump-my-version` unconditionally.

**Fix:**
```just
bump part="patch":
    #!/usr/bin/env bash
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Error: Working tree is dirty. Commit or stash changes first." >&2
        exit 1
    fi
    uv run bump-my-version {{part}}
```

### 19. Global tool installs can shadow project-specific versions

`ruff` and `basedpyright` are installed globally via `uv tool install` *and* as per-project dev-deps. Without `uv run`, `PATH` order determines which version runs. A developer using `ruff check .` directly might get version 0.4 globally while the project pins 0.6.

**Fix:** Either remove the global installs entirely (since `uv run ruff` always uses the project-pinned version and `direnv` + `.venv` handles interactive use), or clearly document the precedence in `luxus-python-stack.md`.

### 20. Generate a `README.md` for every new project

**Fix:** Have `pyinit.sh` create a minimal README:
```markdown
# ${PROJECT_NAME}

## Getting Started
\`\`\`bash
uv sync
just check
\`\`\`

See [AGENTS.md](AGENTS.md) for AI agent guidelines.
```

### 21. The `cw` alias uses global state that breaks with multiple terminals

`cw .` writes to `~/.config/current_working_folder`. If you're working on Project A in Terminal 1 and set `cw .` for Project B in Terminal 2, Terminal 1's `cw` now jumps to Project B.

**Fix:** Document this limitation clearly (rename to something like `cgw` — "Change Global Workspace"), or consider integration with terminal multiplexer session variables (e.g., tmux environment variables).

### 22. `SESSION.md` overwrite destroys historical context

Instructing the AI agent to *overwrite* `SESSION.md` at the end of every session means the sequence of decisions made over days is lost. If an agent goes down a wrong path, there's no history to diagnose it.

**Fix:** Split into two files:
- `SESSION.md` — overwritten each session with current state and next steps (as now).
- `JOURNAL.md` — append-only, with dated entries of what was accomplished. Both should remain in `.gitignore`.

### 23. Python version is hardcoded to 3.12 in `pyinit.sh`

Some projects need Python 3.10 (e.g., AWS Lambda), 3.11, or 3.13+. Hardcoding limits flexibility.

**Fix:** Add a `--python` argument:
```bash
_py_version="3.12"
for arg in "$@"; do
    case "$arg" in
        --lib)    _type="--lib" ;;
        --python) shift; _py_version="$1" ;;  # or use --python=3.13 pattern
        *)        _dir="$arg" ;;
    esac
done
uv init "$_type" --python "$_py_version"
echo "$_py_version" > .python-version
```

### 24. `install_luxuspythonstack.sh` is not idempotent

Running the script twice re-downloads the UV installer and re-installs all global tools without checking if they already exist.

**Fix:** Add guards:
```bash
command -v uv &>/dev/null || { curl -LsSf https://astral.sh/uv/install.sh | sh; }
uv tool list | grep -q ruff || uv tool install ruff@latest
# etc.
```

### 25. Fix the `.vscode` / `.gitignore` interaction

`pyinit.sh` creates `.vscode/settings.json` and `.vscode/launch.json`, but the fallback `.gitignore` (used when offline) ignores `.vscode/` entirely. This means those generated files may never be tracked in offline bootstrap scenarios.

**Fix:** Append explicit whitelisting at the end of `.gitignore`:
```gitignore
# Allow shared VS Code settings
!.vscode/settings.json
!.vscode/launch.json
!.vscode/extensions.json
```

### 26. Generate `.vscode/extensions.json` for team onboarding

**Fix:** Add to `pyinit.sh`:
```json
{
    "recommendations": [
        "charliermarsh.ruff",
        "detachhead.basedpyright",
        "tamasfe.even-better-toml"
    ]
}
```

---

## 🟢 Low — Polish & Ecosystem

### 27. `--ServerApp.port_retries=0` makes Jupyter fragile

If port 8888 is already in use (e.g., another notebook server), `jl` crashes instead of binding to an adjacent port.

**Fix:** Remove this flag or set it to a small positive value like `3`.

### 28. `pypurge` alias is nondeterministic and incomplete

`pip cache purge` calls whichever `pip` is first on `PATH` — system, mamba, or `.venv`. It also doesn't clean the `uv` cache.

**Fix:**
```bash
alias pypurge='python -m pip cache purge; mamba clean --all -y; uv cache clean'
```

### 29. The data-science one-liner is unmaintainable

The ~15-package `uv pip install` command in the documentation will break silently when any single package has a conflict, and it's impossible to diff or selectively update.

**Fix:** Move it to a `requirements-ds.txt` (or a documented `mamba env export` YAML). This enables version pinning, diffs, and selective updates.

### 30. Add `uvx` documentation to `daily-commands.md`

`uv` ships with `uvx` (equivalent to `pipx run`) for running ephemeral CLI tools without installation. This is incredibly useful for one-off utilities and bridges the gap between Level 0 and Level 2.

**Fix:** Add a section:
```bash
uvx httpie GET https://api.example.com   # run without installing
uvx ruff check some_file.py              # use latest ruff without project dependency
```

### 31. Add dependency vulnerability scanning

No part of the stack currently checks for known security vulnerabilities in dependencies — not in `just check`, not in pre-commit, not in CI.

**Fix:** Add `pip-audit` or `uv pip audit` (when available) to the CI pipeline and optionally to `just check`:
```just
audit:
    uv run pip-audit
```

### 32. Harden the bootstrap supply chain

The installer downloads and executes external installers directly (`curl ... | sh` for UV, Miniforge binary). This is common but worth tightening.

**Fix:**
- Pin versions where practical (e.g., specific Miniforge release).
- Verify checksums for Miniforge downloads.
- Log installed versions as a post-install summary.
- Allow environment variables to override pinned versions.

### 33. Add quality checks for the shell layer itself

Your Python quality story is excellent; your shell scripts deserve the same treatment.

**Fix:**
- Add `shellcheck` to validate all `.sh` scripts.
- Add `shfmt` for consistent formatting.
- Optionally add a small [Bats](https://github.com/bats-core/bats-core) test suite for `cw`, `act`, `pyinit.sh` idempotence, and `jl` argument parsing.

### 34. Generate `.editorconfig` for cross-editor consistency

When multiple agents and humans collaborate, editor defaults diverge.

**Fix:** Have `pyinit.sh` generate:
```ini
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
```

### 35. Document the Linux-only assumption explicitly

The stack assumes Bash, `apt`, Miniforge layout, `readlink -f`, and Linux-style paths. This is perfectly fine as a design choice, but it should be stated clearly.

**Fix:** Add a "System Requirements" section at the top of `luxus-python-stack.md`:
> **Platform:** This stack is designed for Linux (Debian/Ubuntu). macOS and other distros may require manual adaptation of the installer.

### 36. Consider adding a `Makefile` fallback

`just` is excellent but isn't installed everywhere. If someone clones a project on a machine without the stack, they can't run the quality gate at all.

**Fix:** Either document how to install `just` standalone (`cargo install just` or `brew install just`), or generate a minimal `Makefile` with the same targets as a fallback.

---

## 💡 Open Considerations

These are areas the stack doesn't currently address. They may not all be relevant to your workflow, but are worth acknowledging:

- **Monorepo / multi-package workspaces:** `uv` supports workspaces. If you ever manage multiple related packages, the stack doesn't currently address this pattern.
- **Documentation generation:** No tooling for Sphinx or MkDocs is scaffolded. For library projects (`--lib`), auto-generated API docs from your Google-style docstrings would be valuable.
- **Human team onboarding:** The stack has excellent AI agent onboarding (`AGENTS.md`) but no equivalent for new human developers. A `CONTRIBUTING.md` or "Developer Setup" guide would close this gap.
- **License file generation:** `pyinit.sh` creates comprehensive scaffolding but doesn't generate a `LICENSE` file or configure the `license` field in `pyproject.toml`.