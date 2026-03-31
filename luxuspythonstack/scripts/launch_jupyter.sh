# Starts Jupyter Lab on localhost with specified port, allowing origin from colab, no browser, etc.
jl () { 
    # --- Directory Logic ---
    # Default to ~/labor if no arg provided; handle "." for current dir or specific path
    __notebookdir=$( [[ "${1:-$HOME/labor}" == "." ]] && pwd || echo "${1:-$HOME/labor}" )
    # --- UI Enhancement: Status Info ---
    local _env_msg=${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:-"(none)"}}
    echo -e "\n\e[95m Jupyter Lab is launching \e[0m"
    echo -e "URL:          \e[1;3;34mhttp://localhost:8888/lab/\e[0m"
    echo -e "Notebook-dir: \e[1;3;34m$__notebookdir\e[0m"
    echo -e "Environment:  $_env_msg"
    echo -e "Instance:     \e[1;3;34m$(which jupyter)\n"
    # --- Launch Jupyter Lab ---
    jupyter lab \
        --notebook-dir="$__notebookdir" --port=8888 --allow-root --no-browser \
        --NotebookApp.allow_origin='https://colab.research.google.com' \
        --NotebookApp.port_retries=0 --NotebookApp.token='' \
        --NotebookApp.disable_check_xsrf=True --NotebookApp.allow_credentials=True
}