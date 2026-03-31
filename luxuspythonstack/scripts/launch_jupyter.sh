# Starts Jupyter Lab on localhost.
# Usage: jl [-x] [folder]
#   -x      start with the default Jupyter token enabled
#   folder  notebook directory (defaults to ~/labor, "." means current directory)
jl () {
    local _use_token=0
    local _notebookdir="$HOME/labor"
    local _env_msg

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -x)
                _use_token=1
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Usage: jl [-x] [folder]" >&2
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

    _env_msg=${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:-"(none)"}}

    echo -e "\n\e[95m Jupyter Lab is launching \e[0m"
    echo -e "URL:          \e[1;3;34mhttp://localhost:8888/lab/\e[0m"
    echo -e "Notebook-dir: \e[1;3;34m$_notebookdir\e[0m"
    echo -e "Environment:  $_env_msg"
    echo -e "Token:        $([[ $_use_token -eq 1 ]] && echo enabled || echo disabled)"
    echo -e "Instance:     \e[1;3;34m$(command -v jupyter)\n"

    if [[ $_use_token -eq 1 ]]; then
        jupyter lab \
            --notebook-dir="$_notebookdir" --port=8888 --allow-root --no-browser \
            --ServerApp.allow_origin='https://colab.research.google.com' \
            --ServerApp.port_retries=0
    else
        jupyter lab \
            --notebook-dir="$_notebookdir" --port=8888 --allow-root --no-browser \
            --ServerApp.allow_origin='https://colab.research.google.com' \
            --ServerApp.port_retries=0 --ServerApp.token='' \
            --ServerApp.disable_check_xsrf=True --ServerApp.allow_credentials=True
    fi
}
