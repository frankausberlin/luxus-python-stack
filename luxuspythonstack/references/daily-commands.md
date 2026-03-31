# Daily Commands Reference — Luxurious Python Stack

Quick lookup for all common operations. For full documentation, see `luxus-python-stack.md`.

---

## Level 0 Setup

```bash
bash scripts/install_luxuspythonstack.sh
source ~/.bashrc
```

The installer bootstraps the global tools, sources `scripts/.bash_lib_luxuspythonstack` from `~/.bashrc`, restores the saved Mamba environment from `~/.startenv`, and enables the `direnv` bash hook.

---

## Project Initialization

```bash
# App project in current directory
bash scripts/pyinit.sh

# App project in new directory
bash scripts/pyinit.sh <project-name>

# Library project
bash scripts/pyinit.sh <project-name> --lib

# Alternative: manual uv init
export UV_PYTHON_PREFERENCE=only-managed
uv init --app --python 3.12    # or --lib
echo "3.12" > .python-version
uv add --dev ruff pytest basedpyright colorlog bump-my-version pre-commit
echo "source .venv/bin/activate" > .envrc && direnv allow
```

---

## Environment Management

### Mamba (Level 1 — Data Science)
```bash
act <envname>                        # activate + save to ~/.startenv
mamba activate <envname>             # activate without saving
mamba deactivate                     # deactivate
mamba activate base                  # back to base

# Recreate environment
py=3.12 && ENV_NAME="ds${py: -2}"
mamba deactivate
mamba remove -y -n $ENV_NAME --all 2>/dev/null
mamba create -y -n $ENV_NAME python=$py <packages...>
mamba activate $ENV_NAME
```

### UV/direnv (Level 2 — Project)
```bash
# direnv auto-activates .venv when entering directory
direnv allow          # allow .envrc (run once per project)
uv sync               # sync environment after git pull / pyproject changes
```

---

## Dependencies

```bash
uv add <package>              # add runtime dependency
uv add --dev <package>        # add dev-only dependency
uv remove <package>           # remove dependency
uv sync                       # sync .venv with lock file
uv pip install <package>      # install directly (Level 1 / Level 3 only)
```

---

## Running Code

```bash
just run                            # run the main script
uv run python src/<project>/main.py # guaranteed sync (use in scripts/CI)
uv run <tool> <args>                # run tool from project environment
```

---

## Testing

```bash
just test                   # run all tests
pytest tests/               # run specific directory
pytest -v                   # verbose output
pytest -k "test_name"       # run specific test
pytest --tb=short           # short traceback
uv run pytest               # guaranteed sync (CI/CD)
```

---

## Code Quality

```bash
just lint                   # lint: show errors (ruff + basedpyright)
just typecheck              # type checking only
just check                  # lint + typecheck + tests
just fix                    # lint: auto-fix what's possible (ruff)

# Manual commands:
ruff check .                # lint: show errors
ruff check --fix .          # lint: auto-fix what's possible
ruff format .               # format code
uv run basedpyright         # type checking
```

---

## Version & Release

```bash
# ALWAYS use bump-my-version (never edit manually, never git tag manually)
just bump patch                 # 0.2.0 → 0.2.1  (bugfixes)
just bump minor                 # 0.2.1 → 0.3.0  (new features)
just bump major                 # 0.3.0 → 1.0.0  (breaking changes)

# Push code AND tags together
git push origin main --tags

# Build and publish (if not via CI)
uv build        # creates dist/
uv publish      # upload to PyPI
```

---

## CI/CD (GitHub Actions)

```bash
# In GitHub Actions workflows:
uv sync --dev               # install all dependencies (uses uv.lock)
just check                  # full quality gate
uv build && uv publish      # build and publish (release workflow)

# Releases can also be triggered manually via workflow_dispatch.
```

---

## Git Workflow

```bash
# Feature development
git checkout -b feature/my-feature
# ... make changes ...
just check
git add -A && git commit -m "feat: description" # pre-commit hooks will run
git push origin feature/my-feature

# Release
just bump patch
git push origin main --tags

# After git pull
uv sync     # always sync after pulling changes
```

---

## Bash Aliases & Functions

```bash
# ~/.bashrc functions (already defined if stack is set up):
pyinit [name] [--lib]    # create project (uses scripts/pyinit.sh)
act <envname>            # activate mamba env + save to ~/.startenv
cw                       # cd to saved working folder
cw .                     # save current folder as working folder
pypurge                  # clean pip cache + mamba environment
rlb                      # source ~/.bashrc (reload)
```

---

## AI Agent Session Workflow

### Session Start
```bash
# 1. Read project context
cat AGENTS.md

# 2. Read last session summary (if exists)
cat SESSION.md 2>/dev/null || echo "No previous session"

# 3. Sync environment
uv sync

# 4. Check project status
git status
git log --oneline -5
```

### Session End
```bash
# 1. Run quality checks
just check

# 2. Commit all changes
git add -A && git commit -m "chore: end of session" # pre-commit hooks will run

# 3. Update SESSION.md with summary
cat > SESSION.md << 'SESSION_EOF'
# Session Summary — $(date +%Y-%m-%d)

## What was accomplished
- ...

## Current state
- ...

## Next steps
- ...
SESSION_EOF

git add SESSION.md   # SESSION.md is in .gitignore, this won't commit it
```

---

## Navigation

```bash
cw .          # set current dir as working folder
cw            # cd to saved working folder
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Modules not found after `git pull` | `uv sync` |
| Wrong Python version in project | `uv python pin 3.12` |
| direnv not activating | `direnv allow` |
| Mamba env conflicts | `mamba clean --all` or recreate env |
| Type errors | Check `basedpyright` output |
| Lint errors | `just fix` |
| bump-my-version fails | Ensure clean git state (`git status`) |
| Can't publish to PyPI | Check `uv publish --token <token>` |





## 🧑‍💻 <font color=blue><b>The Daily Workflow</b></font>

### **A handful of fundamental concepts and considerations**

* **`uv run` vs. `direnv`**<br>
The luxury Python stack uses `direnv`. This theoretically eliminates the need for `uv run` when executing commands in the terminal. However, it's important to note that `direnv` just activates the environment, while `uv run` automatically triggers a dependency sync if things have changed (e.g., after a `git pull`).<br>
> **Recommendation:** Always use `uv run` in scripts, aliases, and CI/CD pipelines to guarantee 100% reproducibility. In everyday local terminal use, you can safely omit it to save keystrokes. If module errors arise, simply run `uv sync`.

* **Dev & Release**<br>
A project generally exists in two states: development and release. These are the most important differences:
  * **Dev State:** Your everyday working mode. The code is fluid, and you rely heavily on your dev-dependencies (`pytest`, `ruff`, `basedpyright`). The version in your `pyproject.toml` remains static while you build features.
  * **Release State:** A frozen, stable snapshot in time. The version number is officially incremented, and a Git tag (e.g., `v0.2.0`) marks the exact commit. This is the state that CI/CD pipelines expect in order to build, test, and deploy your code reliably.

* **Bump a Release (`bump-my-version`)**<br>
Releasing a new version requires keeping the code version (in `pyproject.toml`) and the Git tags perfectly synchronized. Doing this manually (editing the file, committing, and tagging) is highly error-prone and can easily break CI/CD pipelines.<br>
> **Recommendation:** Never edit the version or create tags manually. Use `bump-my-version` with `message = "..."` in the configuration to automatically update the configuration, create a clean commit, and set the Git tag in one atomic step. <br>
> **Workflow:** When a feature or bugfix is ready, run `just bump patch|minor|major`. Afterwards, push the code and the new tag to your remote repository via `git push origin main --tags`.
---

### **Daily Usecases**

**1. Dependencies & Environment**
* Add package: `uv add <package>`
* Add dev tool: `uv add --dev <package>`
* Sync environment: `uv sync`

**2. Execution & Testing**
* Run code: `python src/my_project/main.py`
* Run tests: `pytest`

**3. Code Quality**
* Linting (find errors): `ruff check .`
* Linting (auto-fix): `ruff check --fix .`
* Formatting check: `ruff format --check .`
* Type checking: `basedpyright`
* Unified quality gate: `just check`

**4. Release & Deployment**
* **Bump Version (Git Commit & Tag):**
  * Patch (Bugfixes, e.g., 0.2.0 -> 0.2.1): `just bump patch`
  * Minor (Features, e.g., 0.2.1 -> 0.3.0): `just bump minor`
* **Sync to Remote:**
  * Push code and tags: `git push origin main --tags`
* **Package & Publish (If not handled by CI/CD):**
  * Build the package (creates `dist/`): `uv build`
  * Upload to PyPI / Registry: `uv publish`
