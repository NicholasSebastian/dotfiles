# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=ai_local
MODULE_DESC="Ollama (+ optional Open WebUI)"
MODULE_DEFAULT=1
if (( OPEN_WEBUI )); then MODULE_DEPS=(dev); fi   # Open WebUI runs in Docker
}

ai_local_run() {
  if have ollama; then info "Ollama already installed"; else install_script https://ollama.com/install.sh sh; fi

  if (( OPEN_WEBUI )); then
    if ! is_dry && sudo docker container inspect open-webui >/dev/null 2>&1; then
      info "Open WebUI container already exists"
    else
      run sudo docker run -d --name open-webui --restart always \
        -p 127.0.0.1:3000:8080 --add-host=host.docker.internal:host-gateway \
        -v open-webui:/app/backend/data \
        ghcr.io/open-webui/open-webui:main
      followup manual "Open WebUI: http://localhost:3000"
    fi
  fi

  local models=""
  if have ollama; then models="$(ollama list 2>/dev/null | tail -n +2 || true)"; fi
  if [[ -z "$models" ]]; then
    followup manual "Pull a model to start, e.g. 'ollama pull qwen3' (see ollama.com/library)."
  fi
}
