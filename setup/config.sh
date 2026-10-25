# shellcheck shell=bash
# Settings. Each one can be overridden from the environment for a single run:
#   OPEN_WEBUI=1 ./setup.sh --only ai
# Package lists live in the modules (comment lines out there to drop items).

: "${JAVA_VERSION:=27}"                  # Temurin major version (falls back to OpenJDK)
: "${SET_ZSH_DEFAULT:=1}"                # personal module: 1 = make zsh your login shell
: "${SHELL_GREETING:=1}"                 # personal module: 1 = run fastfetch when a terminal opens
: "${OPEN_WEBUI:=0}"                     # 1 = run Open WebUI in Docker for Ollama (adds dep: dev)

: "${AI_DIR:=$HOME/AI}"                  # ComfyUI workspace
: "${APPS_DIR:=$HOME/Applications}"      # AppImages
: "${SRC_DIR:=$HOME/src}"                # source builds (Aseprite)
: "${VM_DIR:=$HOME/VMs}"                 # virtio driver ISO

: "${LOG_DIR:=${XDG_STATE_HOME:-$HOME/.local/state}/setup}"
