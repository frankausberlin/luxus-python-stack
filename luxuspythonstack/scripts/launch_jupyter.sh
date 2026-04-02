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
