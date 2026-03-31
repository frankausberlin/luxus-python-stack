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
3. **Quality Gate:** 
     - Linting & Formatting: `uv run ruff check .` and `uv run ruff check --fix .`
     - Type Checking: `uv run basedpyright`
     - Testing: `uv run pytest`
    - Unified gate: `just check`

## 🚀 Versioning & Releases
We use `bump-my-version` for automated semantic versioning.
- **NEVER** change versions manually in `pyproject.toml` or `__init__.py`. This breaks the CI/CD pipeline!
- To bump a version, ensure the working tree is clean and run: `just bump patch|minor|major`.
- Do **not** use `commit_args = "-m ..."` in the config, as it breaks internal commit management.

## 🧑‍💻 The "Vibe Coding" Workflow (Session Lifecycle)
As an AI Agent, you must adhere to the following session state management:

1. **Initialization:** At the absolute beginning of your task, read `SESSION.md` (if it exists) to understand the context, recent changes, and current roadmap.
2. **Execution:** Perform your coding tasks, run tests, and ensure `just check` passes without errors.
3. **Finalization:** Before ending your interaction or completing the task, **overwrite** `SESSION.md` with a concise summary of what was just achieved, any open issues, and the immediate next steps.

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
