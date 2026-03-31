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

Tools (install_luxuspythonstack.sh):
- **Mamba**: A fast and efficient package manager that allows me to create and manage Python environments easily.
- **UV**: A tool for managing Python versions and virtual environments, which I use to switch between different Python versions and environments seamlessly.
- **direnv**: A tool that allows me to automatically load and unload environment variables based on the directory I am in, which is particularly useful for managing project-specific environments and dependencies.
- **Ruff & basedpyright**: Tools for linting, formatting, and type checking.
- **bump-my-version**: Automated publishing.

Scripts and Aliases (.bash_lib_luxuspythonstack):
- **cw**: `cw` -> change to working folder / `cw .` -> make current folder the working folder.
- **act**: Activates a Mamba environment and saves it in the file ~/.startenv.
- **pyinit**: Creates a Python project with all files and folders (src, tests, pyproject.toml, etc.) and initializes a UV environment.
- **pypurge**: An alias for purging the pip cache and cleaning the Mamba environment.
- **jl**: Starts Jupyter Lab in a default folder or optional in a specified folder. Use `jl -x [<folder>]` to keep the default Jupyter token enabled.


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
* An essential tool is Jupyter Lab (experiments, notes, prototypes). It is started with the script `jl`: `jl [-x] [<folder>]`.
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
* **SESSION.md** is not part of the repository and is in .gitignore. It is a volatile file that contains the summary of the last session and is recreated by the agent for each session.
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

* Run `bash scripts/install_luxuspythonstack.sh` to install the Level 0 tooling and wire your shell setup.
* The installer appends an absolute `source .../.bash_lib_luxuspythonstack` line, restores the saved Mamba environment from `~/.startenv`, and enables the `direnv` bash hook in `~/.bashrc`.
* Reload the shell afterwards with `source ~/.bashrc`.

### References

* **blueprint-AGENTS.md** - A blueprint for creating AGENTS.md so that the AI ​​agent can work with the project using the Luxus Python stack. 
* **daily-commands.md** - A reference for all the daily commands and their purpose.
  

### Scripts

*All scripts are located in the `scripts` folder of the skill.*

* **.bash_lib_luxuspythonstack** - A collection of shell aliases and functions for the Luxus Python Stack. 
* **install_luxuspythonstack.sh** - A script to set up the Level 0 tools and change the .bashrc for the Luxus Python Stack.
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
# act() { [ "$#" -ne 0 ] && echo $1 > ~/.startenv && mamba activate $1; }
```
