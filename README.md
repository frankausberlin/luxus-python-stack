# luxus-python-stack

This is my personal Python stack that I use for <b>project development, data science with Jupyter and Vibe coding</b>. It contains a collection of <b>libraries and tools</b> that I find useful for working efficiently, a complete installation guide for a Linux base system (Ubuntu) and is also available as an <b>agent skill</b>. First of all, I define a <b>five-level concept</b>:

<table><tr></tr><tr><td colspan=5><hr></td></tr><tr><td align=center>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;🧱 Level 0&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br><br>Global <br> System
</td><td align=center>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;🧱 Level 1&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br><br>Mamba <br> Jupyter
</td><td align=center>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;🧱 Level 2&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br><br>Projects <br> .venv
</td><td align=center>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;🧱 Level 3&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br><br>Continuous Integration<br>Continuous Deployment
</td><td align=center>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;🧱 Level 4&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br><br>AI Agents <br> Vibe Coding
</td></tr><tr><td colspan=5><hr></td></tr></table>

The Python stack provides specific <b>tools, rules and best practices</b> for each level. The complete stack is contained in the documents <b>luxus-python-stack.md</b> and <b>daily-commands.md</b> and is located in the <b>references</b> directory of the <b>agent skill</b>.

The stack also contains the description of a complete Linux system. The Linux base system setup instructions are described in the reference <b>basesystem.md</b>. This is the basis for the Python stack environment.

⚠️ **Important note:**<br>There is a lot of script code in the documents. It is strongly discouraged to run this code without checking it first. Follow these guidelines:
* Execute only one piece of code at a time.
* Adjust the code before execution (e.g. bash or zsh, the correct token, paths, etc.).
* Append the code in a simple text document (e.g. cmdhist.txt) before execution.
* If problems occur, this history can be given to a troubleshooting agent.

## Content

```
├── luxuspythonstack                     # Skill-Folder
│   ├── references                       # References for the agent skill
│   │   ├── basesystem.md                # Linux Base system setup
│   │   ├── blueprint-AGENTS.md          # Blueprint for the AGENTS.md
│   │   ├── daily-commands.md            # For the daily workflow and commands
│   │   └── luxus-python-stack.md        # The complete Python stack
│   ├── scripts                          # Scripts for the agent skill
│   │   └── .luxuspythonstacklib.sh      # pyinit: Initialize a Luxus Python Stack Project 
│   │                                    # jl:     A Launcher for Jupyter Lab
│   └── SKILL.md                         # The agent skill
└── README.md                            # This file
```

## Direct links

* Document [basesystem.md](luxuspythonstack/references/basesystem.md)
* Document [luxus-python-stack.md](luxuspythonstack/references/luxus-python-stack.md)
* Document [daily-commands.md](luxuspythonstack/references/daily-commands.md)
* Document [blueprint-AGENTS.md](luxuspythonstack/references/blueprint-AGENTS.md)
* Script [luxuspythonstacklib.sh](luxuspythonstack/scripts/luxuspythonstacklib.sh)


## Installation

To use the agent skill in an agent you <b>simply have to copy</b> the luxuspythonstack/ folder <b>into the agent's skill folder</b> (e.g.: ~/.claude/skills, ~/.opencode/skills, ~/.kilocode/skills).
