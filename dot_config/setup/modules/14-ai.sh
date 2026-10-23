# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=ai
MODULE_DESC="Claude Code, Oh My Pi, Ollama (+ optional Open WebUI), ComfyUI, Upscayl"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes)                   # bun, uv
if (( OPEN_WEBUI )); then MODULE_DEPS+=(dev); fi   # Open WebUI runs in Docker
}

# --- Coding agents -----------------------------------------------------------

_ai_cli() {
  if have claude; then info "Claude Code already installed"; else install_script https://claude.ai/install.sh bash; fi

  # Oh My Pi ('omp'). mise's GitHub backend is one of upstream's documented methods.
  mise_use "github:can1357/oh-my-pi"

  # Extra agents via bun; uncomment to add
  local extra=(
    # @openai/codex
    # @google/gemini-cli
    # opencode-ai
  )
  if (( ${#extra[@]} )); then
    need bun runtimes
    run bun add -g "${extra[@]}"
  fi
}

# --- Local models ------------------------------------------------------------

_ai_local() {
  if have ollama; then info "Ollama already installed"; else install_script https://ollama.com/install.sh sh; fi

  if (( OPEN_WEBUI )); then
    if ! is_dry && sudo docker container inspect open-webui >/dev/null 2>&1; then
      info "Open WebUI container already exists"
      followup manual "Open WebUI: if it shows no models, recreate it: sudo docker rm -f open-webui, then re-run './setup.sh --only ai'"
    else
      # Host network: Ollama only listens on 127.0.0.1:11434, which the
      # bridge network can't reach. HOST/PORT keep the UI on localhost:3000.
      run sudo docker run -d --name open-webui --restart always \
        --network=host -e HOST=127.0.0.1 -e PORT=3000 \
        -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
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

# --- Image generation --------------------------------------------------------

_ai_gpu() {
  local gpus
  gpus="$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' || true)"
  # Word boundaries matter: "Intel Corporation" contains "ati".
  if   grep -qi  'nvidia'               <<<"$gpus"; then echo nvidia
  elif grep -Eqi '\b(amd|ati|radeon)\b' <<<"$gpus"; then echo amd
  else echo cpu
  fi
}

_ai_creative() {
  need uv runtimes
  if have comfy; then info "comfy-cli already installed"; else run uv tool install comfy-cli; fi

  # ComfyUI gets its own Python 3.12 environment. Your global Python (from
  # mise) tracks the newest release, which PyTorch's GPU builds usually
  # don't support yet, and this keeps PyTorch's ~5 GB out of it anyway.
  local venv="$AI_DIR/.venv"
  if [[ ! -x "$venv/bin/python" ]]; then
    run mkdir -p "$AI_DIR"
    run uv venv --python 3.12 "$venv"
  fi

  local gpu
  gpu="$(_ai_gpu)"
  if [[ "$gpu" == cpu ]]; then warn "No NVIDIA/AMD GPU found, ComfyUI will run on CPU"; fi

  # Checks for ComfyUI's main.py rather than the folder, so a failed install
  # is retried on the next run. Running inside the venv (what 'activate'
  # does) makes comfy-cli install ComfyUI's packages there.
  if [[ -f "$AI_DIR/ComfyUI/main.py" ]]; then
    info "ComfyUI already installed in $AI_DIR/ComfyUI"
  else
    run env VIRTUAL_ENV="$venv" PATH="$venv/bin:$PATH" \
      comfy --skip-prompt --workspace "$AI_DIR/ComfyUI" install "--$gpu"
  fi

  flatpak_install org.upscayl.Upscayl     # AI image upscaler

  followup manual "Start ComfyUI: source $venv/bin/activate && comfy --workspace $AI_DIR/ComfyUI launch"
  followup manual "Optional: Krita AI Diffusion plugin (uses your ComfyUI), Stability Matrix, LM Studio."
}

ai_run() {
  _ai_cli
  _ai_local
  _ai_creative
}
