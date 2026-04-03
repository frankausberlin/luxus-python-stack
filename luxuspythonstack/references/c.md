(1) luxus-python-stack.md
## 💎 Luxurious Python Stack

<table width=800><tr></tr><tr><td colspan=5><hr></td></tr><tr><td align=center>

&nbsp;&nbsp;&nbsp;🧱 Level 0&nbsp;&nbsp;&nbsp;<br><br>Global <br> System
</td><td align=center>

🧱 Level 1<br><br>Mamba <br> Jupyter
</td><td align=center>

🧱 Level 2<br><br>Projects <br> .venv
</td><td align=center>

🧱 Level 3<br><br>CI <br> Deployment
</td><td align=center>

🧱 Level 4<br><br>AI Agents <br> Vibe Coding
</td></tr><tr><td colspan=5><hr></td></tr></table>

Ultimately, it is a combination of tools, scripts and aliases that allow me to work efficiently and flexibly with Python. By separating it into different levels, I can ensure that I always have the right environment for my projects without causing conflicts between different projects or Python environments.

Tools (check-and-install.sh):
- **Mamba**: A fast and efficient package manager that allows me to create and manage Python environments easily.
- **UV**: A tool for managing Python versions and virtual environments, which I use to switch between different Python versions and environments seamlessly.
- **direnv**: A tool that allows me to automatically load and unload environment variables based on the directory I am in, which is particularly useful for managing project-specific environments and dependencies.
- **Ruff & basedpyright**: Tools for linting, formatting, and type checking.
- **bump-my-version**: Automated publishing.

Scripts and Aliases (.bash_lib_luxuspythonstack):
- **cw**: `cw` -> change to working folder / `cw .` -> make current folder the working folder. ⚠️ **Global state:** the saved folder is stored in `~/.config/current_working_folder` and is shared across all open terminals. Setting `cw .` in one terminal overwrites the saved path for all other terminals.
- **act**: Activates a Mamba environment and saves it in the file ~/.startenv.
- **pyinit**: Creates a Python project with all files and folders (src, tests, pyproject.toml, etc.) and initializes a UV environment. Supports `--lib`, `--python X.Y`, and `--force` flags.
- **pypurge**: An alias for purging the pip cache and cleaning the Mamba environment.
- **jl**: Starts Jupyter Lab securely (token enabled by default) in a default folder or specified folder. Use `jl -x [<folder>]` to disable the token (unsafe). Use `jl --colab [<folder>]` to allow Google Colab origin.


### Five-level concept

My workflow is based on a five-level concept:

0. **Global / System Level**

* The standard Python is available here (/usr/bin/python).
* Core bootstrap tools such as python3, git, curl and direnv are installed by the installer.
* Miniforge/Mamba, UV, just, ruff and basedpyright are then installed on top and wired into the shell.
* Tools like rg, fd or build essentials are recommended extras, but are not currently installed by the bootstrap script.
* The system level is automatically active as soon as no other environment is activated.

1. **Mamba Level**

* This level is for data science work and is set up using Mamba.
* It includes tools like Jupyter Lab, pytorch, tensorflow, scikit-learn, and other data science libraries.
* This level is always active if there is no .venv folder in the current location or you deactivate it.
* Using `act` to activate an environment will automatically activate it in new terminals (.startenv).
* An essential tool is Jupyter Lab (experiments, notes, prototypes). It is started with the script `jl`: `jl [-x] [--colab] [<folder>]`. Token is enabled by default; use `-x` to disable (unsafe).
* This level is highly volatile. The rule applies: **no updates, just delete and recreate**. This is the only way to eliminate the dependency conflicts that can occur when using uv in a Mamba environment.

2. **Project / .venv Level**

* This level is intended for folders with .venv, for example for projects.
* As soon as there is a .venv folder in the current folder, it will be automatically activated (after direnv activate).
* With `pyinit` you can quickly create a new project with a .venv folder and have the required files and folders created.
* The canonical implementation lives in `scripts/pyinit.sh`; this document links to the script instead of embedding it inline.
* If you prefer to work with uv venv / init yourself, this is not a problem, as direnv automatically activates .venv if you want.

3. **CI / Deployment Level**

* This level acts as the automated gatekeeper between local development and production/publishing. It is primarily powered by GitHub Actions.
* Environment Parity: Thanks to uv.lock, the CI server exactly mirrors the Level 2 project environment. The CI pipeline runs uv sync to ensure 100% reproducible builds.
* Continuous Integration (CI): On every push or Pull Request, automated workflows run the identical code quality checks used locally through `just check`. Code that fails here cannot be merged.
* Release Automation: Versioning and Git tagging are fully automated to prevent human error. `bump-my-version` should use `message = "..."` in the configuration and must not use `commit_args = "-m ..."`.
* Automated building and publishing to PyPI via uv build and uv publish.


4. **AI Agents / Vibe Coding Level**

* **AGENTS.md** is part of the repository. Here you will find relevant information for an AI agent to understand and work on the project.
* **SESSION.md** is not part of the repository and is in `.gitignore`. It is a volatile file overwritten each session with current state and next steps.
* **JOURNAL.md** is also in `.gitignore` and is append-only. Each session appends a dated entry so the sequence of decisions and progress is preserved for debugging and context. Never overwrite it.
* **LuxusPythonStack Skill** is a [Agents Skill](https://agentskills.io/home) (`luxus-python-stack`) that turns any AI coding agent into an expert on this stack. It provides:
  - Full knowledge of the five-level architecture and which tool to use when
  - A bundled `pyinit.sh` script for deterministic project initialization
  - Session workflow: reading `AGENTS.md` on start, writing `SESSION.md` on end
  - Quick command reference for all daily operations
* **Mcphub** is on [Github repo](https://github.com/samanhappy/mcphub) and provides a unified API for different MCP servers (uvx, npx, docker, etc.). 
  - Offers various interface types: Stdio, SSE, Open Api
  - Bearer authentication and OAuth support
  - Smart routing with your own embedding model (ollama)
* **Ollama** is used to perform light machine learning tasks such as embedding (mcphub, codebase indexing), image description (RAG), Whisper, OCR, etc.
* **Coding Agents**: There are a lot of good ones. I personally like Kilo Code (VS Code Extension) and Open Code. But Claude, Gemini cli, Mistral Vibe, Codex are also recommended. They work directly with the Mcphub and the LuxusPythonStack skill.

⚠️ **Important Note Regarding the "Mamba Level":**<br>
> <b><font color=blue>It doesn't necessarily have to be data science. Any domain is possible here;</font></b> it just happens to be mine.<br>
> It's generally not recommended to use `uv` in a Mamba environment, as the packages installed this way are not under Mamba's control. This can lead to conflicts when updating packages with Mamba.<br>
> I use the data science environment in a way that makes this problem irrelevant. I'm constantly installing new libraries, deleting old ones, and experimenting. But just as frequently (sometimes twice a day), I completely wipe the environment (reinstall it).

```shell
mamba deactivate && mamba remove -y -n <envname> --all && mamba create -y -n <envname> ...
```
> That's why I use `uv`; it's so incredibly fast.

### Installation

* Run `bash scripts/check-and-install.sh` to install the Level 0 tooling and wire your shell setup.
* The installer **copies** the shell library and scripts to `~/.local/share/luxuspythonstack/`, so the stack remains functional even if the source repository is moved or deleted.
* The managed block in `~/.bashrc` sources from this stable path and is **replaced** (not appended) on re-runs.
* The startup block is failure-tolerant: if `mamba` is unavailable or `~/.startenv` contains a missing environment, the shell opens normally instead of erroring.
* Reload the shell afterwards with `source ~/.bashrc`.

### Tool Version Precedence

`ruff` and `basedpyright` are installed both globally via `uv tool install` (for convenience in ad-hoc use) and as per-project dev dependencies in each project's `pyproject.toml`.

**Precedence rule:** When `direnv` activates a project's `.venv`, the project-local binaries in `.venv/bin/` take precedence over global `uv tool` binaries. This means `ruff check .` in a project directory uses the project-pinned version automatically.

**Best practice:** Always use `uv run ruff ...` and `uv run basedpyright ...` in scripts, CI, and automation. This guarantees the project-pinned version runs regardless of PATH order or which environment is active.

### Documentation Generation (Library Projects)

For library projects (`pyinit --lib`), the stack scaffolds a complete documentation site using the state-of-the-art Python documentation toolchain:

- **[MkDocs](https://www.mkdocs.org/)** — a fast, simple static site generator optimized for project documentation.
- **[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)** — the most widely used MkDocs theme. Used by FastAPI, Pydantic, SQLModel, and hundreds of popular Python libraries. Offers search, navigation tabs, and beautiful rendering.
- **[mkdocstrings](https://mkdocstrings.github.io/)** — automatically generates API reference pages from your Python docstrings. Since the stack already enforces Google-style docstrings via `ruff`, there is no extra work — documentation is a side-effect of good code.

Generated by `pyinit --lib`:
```
docs/
  index.md     ← narrative intro (edit freely)
  api.md       ← auto-rendered API reference (uses ::: package_name directive)
mkdocs.yml     ← site config with Material theme + mkdocstrings
```

Workflow:
```bash
just docs-serve   # live preview at http://127.0.0.1:8000
just docs         # build static site into site/
```

### Shell Quality

The stack's Python quality story is backed by `ruff`, `basedpyright`, and `pytest`. The shell scripts themselves get the same treatment:

- **`shellcheck`** — static analysis for all `.sh` scripts. Catches common pitfalls (unquoted variables, word-splitting bugs, etc.).
- **`shfmt`** — consistent formatting for shell scripts (like `ruff format` for Bash).

Both are installable via `bash scripts/check-and-install.sh` (listed as recommended extras). To lint all shell scripts manually:

```bash
shellcheck luxuspythonstack/scripts/*.sh
shfmt -d luxuspythonstack/scripts/*.sh   # diff mode: show formatting changes
shfmt -w luxuspythonstack/scripts/*.sh   # write mode: apply formatting
```

### System Requirements

> **Platform:** This stack is designed for **Linux (Debian/Ubuntu)**. macOS and other distributions may require manual adaptation of the installer. The `check-and-install.sh` script detects the platform and shows equivalent manual commands for non-apt systems.

### References

* **blueprint-AGENTS.md** - A blueprint for creating AGENTS.md so that the AI ​​agent can work with the project using the Luxus Python stack. 
* **daily-commands.md** - A reference for all the daily commands and their purpose.
  

### Scripts

*All scripts are located in the `scripts` folder of the skill.*

* **.bash_lib_luxuspythonstack** - A collection of shell aliases and functions for the Luxus Python Stack. 
* **check-and-install.sh** - The unified Level 0 installer: checks tools, installs missing ones, deploys scripts to `~/.local/share/luxuspythonstack/`, and wires the `.bashrc`.
* **pyinit.sh** - A script to initialize a new Python project with a standard structure for the Luxus Python Stack.
* **launch_jupyter.sh** - A script to start Jupyter Lab.

### Data Science Environment (example)

```shell
#                     (re)create a data science environment with all the goodies and activate it
# _________________________________________________________________________________________________________________________________
py=3.12 && ENV_NAME="ds${py: -2}" && mamba deactivate && mamba remove -y -n $ENV_NAME --all 2>/dev/null # python 3.XY --> 'dsXY'
mamba   create -y -n $ENV_NAME python=$py google-colab && mamba activate $ENV_NAME # testet with python 3.11/12/13
uv pip  install torch torchvision scikit-learn jax jupyterlab jupytext jupyter_http_over_ws jupyter-ai jupyterlab-github fastai\
        numba langchain langchain-openai langchain-ollama transformers evaluate accelerate nltk tf-keras hrid huggingface-hub\
        rouge_score datasets unstructured[all-docs] opencv-python soundfile nbdev llama-index tensorflow setuptools wheel mcp\
        graphviz PyPDF2 xeus-python ipywidgets==7.7.1 --extra-index-url https://download.pytorch.org/whl/cu126 # use your cuda
jupyter labextension enable jupyter_http_over_ws && echo $ENV_NAME > ~/.startenv
python  -m ipykernel install --user --name $ENV_NAME --display-name $ENV_NAME
# _____________________________insert_in_.bashrc_and_use_'act'_instead_of_'mamba_activate'_________________________________________
# mamba activate $(cat ~/.startenv)
# act() { [ "$#" -ne 0 ] && echo $1 > .startenv && mamba activate $1; }
```






(2) blueprint-AGENTS.md
# 🤖 Agent Guide: {{PROJECT_NAME}}

Welcome, AI Agent! You are operating within the **Luxurious Python Stack** (Level 2: Project Environment). This means strict rules apply to dependency management, environment activation, and versioning. Read this document carefully before making any changes.

## 🎯 Project Goal
{{INSERT_PROJECT_DESCRIPTION_HERE}}

## 🏗️ Architecture & Conventions
- **Core Logic:** Located in `src/{{PACKAGE_NAME}}/`.
- **Tests:** Located in `tests/`.
- **Typing:** Strict type hinting is mandatory. `basedpyright` is the primary type checker.
- **Docstrings:** Use Google-style docstrings for all public functions and classes.
- **Import style:** We use `__init__.py` as a facade. External imports should run via the main package.

## 🛠️ Stack & Tooling (CRITICAL RULES)
This project is strictly managed by `uv`. **Do not use `pip`, `poetry`, or standard `venv` commands.**

1. **Dependencies:** 
   - Add packages: `uv add <package>`
   - Add dev tools: `uv add --dev <package>`
   - Sync environment: `uv sync`
2. **Execution:** In scripts, automation, and CI, ALWAYS prefix commands with `uv run` to guarantee reproducibility (e.g., `uv run ruff check .`). In an interactive terminal with `direnv`-activated `.venv`, direct commands are acceptable.
3. **Quality Gate:** Run `just check` — this executes the full gate (lint, format check, type check, tests) in one step. Individual commands if needed:
     - Linting & Formatting: `uv run ruff check .` / `uv run ruff format --check .`
     - Auto-fix: `uv run ruff check --fix .` / `uv run ruff format .`
     - Type Checking: `uv run basedpyright`
     - Testing: `uv run pytest`

## 🚀 Versioning & Releases
We use `bump-my-version` for automated semantic versioning.
- **NEVER** change versions manually in `pyproject.toml` or `__init__.py`. This breaks the CI/CD pipeline!
- To bump a version, ensure the working tree is clean and run: `just bump patch|minor|major`.
- Do **not** use `commit_args = "-m ..."` in the config, as it breaks internal commit management.

## 🧑‍💻 The "Vibe Coding" Workflow (Session Lifecycle)
As an AI Agent, you must adhere to the following session state management:

1. **Initialization:** At the absolute beginning of your task, read `SESSION.md` (if it exists) to understand the context, recent changes, and current roadmap.
2. **Execution:** Perform your coding tasks, run tests, and ensure `just check` passes without errors.
3. **Finalization:** Before ending your interaction or completing the task:
   - **Overwrite** `SESSION.md` with a concise summary of what was just achieved, any open issues, and the immediate next steps (current snapshot — volatile).
   - **Append** a dated entry to `JOURNAL.md` with a brief summary of what was accomplished (persistent history — never overwrite).

## 🐞 Debugging Protocol (Level 2)
When encountering errors, test failures, or unexpected behavior, follow this structured debugging approach:

1. **Test-Driven Debugging:** Do not guess. Write or isolate a failing test first.
   - Run specific tests with stdout enabled: `uv run pytest -k <test_name> -s`
   - The `-s` flag is crucial so you can read `print()` statements and logs in the terminal output.
2. **Logging over Printing:** 
   - This project uses `colorlog` (installed via dev-dependencies).
   - For complex state tracking, configure a basic logger instead of scattering `print()` statements, as logs provide module context and timestamps.
3. **Traceback Analysis:**
   - Always read the FULL traceback. Identify if the error originates from the core logic (`src/`) or a third-party dependency.
   - If a third-party library throws an error, verify the installed version with `uv pip list` or check the `pyproject.toml`.
4. **Interactive State (If supported):**
   - If your agent framework supports interactive code execution, you may use `breakpoint()` (standard `pdb`) to inspect local variables, but ensure you step through or exit properly so the process doesn't hang.

## 🧑‍🔧 Troubleshooting
- **ModuleNotFoundError:** You probably forgot `uv run` or need to run `uv sync`.
- **Test Failures:** Prioritize fixing core logic in `src/` over altering the tests, unless the tests are explicitly flawed.
- **Linting errors:** Run `uv run ruff check --fix .` before attempting manual formatting fixes.






(3) daily-commands.md
# Daily Commands Reference — Luxurious Python Stack

Quick lookup for all common operations. For full documentation, see `luxus-python-stack.md`.

---

## Level 0 Setup

```bash
bash scripts/check-and-install.sh
source ~/.bashrc
```

The installer copies scripts to `~/.local/share/luxuspythonstack/`, writes the managed block into `~/.bashrc`, and enables the `direnv` hook. Re-running replaces the block instead of appending.

---

## Project Initialization

```bash
pyinit                              # app in current directory
pyinit my-project                   # app in new directory
pyinit my-lib --lib                 # library in new directory
pyinit my-project --python 3.11    # specify Python version (default: 3.12)
pyinit my-project --force          # re-run and overwrite generated files
```

---

## Environment Management

### Mamba (Level 1 — Data Science)
```bash
act <envname>                        # activate + save to ~/.startenv
mamba activate <envname>             # activate without saving
mamba deactivate                     # deactivate
mamba activate base                  # back to base
jl [folder]                          # start Jupyter Lab (secure, token enabled)
jl -x [folder]                       # start Jupyter Lab without token (unsafe)
jl --colab [folder]                  # start Jupyter Lab with Colab origin

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

## Ephemeral Tools (uvx)

`uvx` runs a CLI tool in a temporary environment without installing it — perfect for one-off utilities:

```bash
uvx httpie GET https://api.example.com   # run without installing
uvx ruff check some_file.py              # use latest ruff without project dependency
uvx pip-audit                            # audit dependencies for vulnerabilities
uvx twine check dist/*                   # check package before publishing
```

> `uvx` is equivalent to `pipx run` but powered by `uv`. The tool is cached locally after first use, so subsequent runs are instant.

---

## Running Code

```bash
just run                            # run the main script
uv run python src/<project>/main.py # guaranteed sync (use in scripts/CI)
uv run <tool> <args>                # run tool from project environment
```

> **`uv run` vs. `direnv`:** The stack uses `direnv` to auto-activate `.venv`, which makes `uv run` optional in local terminal use. However, `uv run` also triggers a dependency sync if things have changed (e.g., after a `git pull`). Always use `uv run` in scripts, aliases, and CI/CD pipelines to guarantee reproducibility. If module errors arise locally, run `uv sync`.

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
just audit                  # check dependencies for known vulnerabilities

# Manual commands:
ruff check .                # lint: show errors
ruff check --fix .          # lint: auto-fix what's possible
ruff format .               # format code
uv run basedpyright         # type checking
uvx pip-audit               # dependency vulnerability scan (no install needed)
```

---

## Documentation (library projects)

```bash
just docs-serve         # preview docs locally with live reload
just docs               # build static docs into site/
```

Generated by `pyinit --lib`. Uses **MkDocs** + **Material theme** + **mkdocstrings** — the stack auto-generates API reference pages from Google-style docstrings. Edit `docs/` for narrative content; `docs/api.md` auto-renders your public API.

---

## Version & Release

A project exists in two states: **development** (fluid code, static version, relying on dev-dependencies) and **release** (frozen snapshot with an incremented version number and a Git tag marking the exact commit). Releasing requires keeping the version in `pyproject.toml` and Git tags perfectly synchronized — doing this manually is error-prone and can break CI/CD pipelines.

> **Rule:** Never edit the version or create tags manually. `bump-my-version` updates the config, creates a commit, and sets the Git tag in one atomic step.

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
pyinit [name] [--lib] [--python X.Y] [--force]  # create project
act <envname>            # activate mamba env + save to ~/.startenv
cw                       # cd to saved working folder (global state — one folder per machine)
cw .                     # save current folder as working folder
pypurge                  # clean pip, mamba, and uv caches
rlb                      # source ~/.bashrc (reload)
```

> **Note on `cw`:** The working folder is stored globally in `~/.config/current_working_folder`. It is shared across all terminals — setting `cw .` in Terminal B overwrites Terminal A's saved folder. For per-session navigation, prefer `cd` with shell history or a terminal multiplexer (tmux).

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

# 3. Overwrite SESSION.md with current state (volatile — not tracked by git)
cat > SESSION.md << 'SESSION_EOF'
# Session Summary — $(date +%Y-%m-%d)

## What was accomplished
- ...

## Current state
- ...

## Next steps
- ...
SESSION_EOF

# 4. Append a dated entry to JOURNAL.md (append-only history — not tracked by git)
cat >> JOURNAL.md << 'JOURNAL_EOF'

## $(date +%Y-%m-%d) — Session Notes
- ...
JOURNAL_EOF
```

> **SESSION.md vs JOURNAL.md:** Both are in `.gitignore`. `SESSION.md` is overwritten each session with current state. `JOURNAL.md` is append-only and preserves historical context across sessions.

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





