# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=ai
MODULE_DESC="Claude Code (CLI + Desktop), Oh My Pi, Hermes Agent, Ollama (+ optional Open WebUI), LM Studio Bionic, ComfyUI (CLI + Desktop), Upscayl"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes)                   # bun, uv
if (( OPEN_WEBUI )); then MODULE_DEPS+=(dev); fi   # Open WebUI runs in Docker
}

# --- Coding agents -----------------------------------------------------------

_ai_cli() {
  if have claude; then info "Claude Code already installed"; else install_script https://claude.ai/install.sh bash; fi

  # Oh My Pi ('omp'). mise's GitHub backend is one of upstream's documented methods.
  mise_use "github:can1357/oh-my-pi"

  # Hermes Agent (Nous Research): upstream's installer, the only Linux install
  # (Hermes Desktop has no Linux package). It installs to ~/.hermes and links
  # ~/.local/bin/hermes. --non-interactive skips its setup wizard, which needs
  # a terminal; stdin is /dev/null while modules run.
  if have hermes; then
    info "Hermes Agent already installed"
  else
    install_script https://hermes-agent.nousresearch.com/install.sh bash --non-interactive
    followup manual "Hermes Agent: run 'hermes setup' to pick a model provider."
  fi

  # Hermes Desktop: built from the Hermes checkout. Plain 'hermes desktop'
  # builds and then runs the app in the foreground, which would block the
  # run; --build-only builds it and writes its launcher entry, then exits.
  # 'hermes update' rebuilds it from then on.
  if [[ -f "$HOME/.local/share/applications/com.nousresearch.hermes.desktop" ]]; then
    info "Hermes Desktop already installed"
  elif is_dry || have hermes; then
    run hermes desktop --build-only || soft_fail "Hermes Desktop build failed; retry with 'hermes desktop --build-only'"
  else
    soft_fail "Hermes Desktop not built: the hermes command isn't available"
  fi

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

# Claude Desktop (beta on Linux): Chat, Cowork and Claude Code in one app,
# from Anthropic's apt repo as https://code.claude.com/docs/en/desktop-linux
# describes, so it updates with 'apt upgrade'. The key is pinned by
# fingerprint and kept armored at the path the package writes its identical
# copy to. The package leaves a sources file without its marker line alone,
# so the two never rewrite each other's.
_AI_CLAUDE_KEY_FPR="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
_AI_CLAUDE_KEYRING=/usr/share/keyrings/claude-desktop-archive-keyring.asc
_ai_claude_desktop() {
  local key="$MODULE_TMP/claude-desktop.asc" changed=0 fresh=0
  if is_dry; then
    cmd "download https://downloads.claude.ai/claude-desktop/key.asc, check key fingerprint $_AI_CLAUDE_KEY_FPR -> $_AI_CLAUDE_KEYRING"
  elif download https://downloads.claude.ai/claude-desktop/key.asc "$key"; then
    install_keyring claude-desktop "$key" "$_AI_CLAUDE_KEY_FPR" "$_AI_CLAUDE_KEYRING"
    if write_changed; then changed=1; fi
  else
    soft_fail "Claude Desktop: couldn't download Anthropic's repo key; see https://code.claude.com/docs/en/desktop-linux"
    return 0
  fi
  write_file /etc/apt/sources.list.d/claude-desktop.list < <(
    printf 'deb [arch=amd64,arm64 signed-by=%s] https://downloads.claude.ai/claude-desktop/apt/stable stable main\n' "$_AI_CLAUDE_KEYRING")
  if write_changed; then changed=1; fi
  if (( changed )); then apt_update; fi

  # apt_install leaves out recommended packages, so the ones the app uses are
  # listed: sound, tray icon, bubblewrap/socat/ssh for Claude Code sessions,
  # QEMU + UEFI firmware + virtiofsd for Cowork's VM, and GNOME Keyring to
  # keep the sign-in (not on KDE: it conflicts with KDE Wallet there).
  local pkgs=(libasound2t64 libayatana-appindicator3-1 bubblewrap socat openssh-client qemu-system-x86 ovmf virtiofsd)
  if ! pkg_installed plasma-workspace; then pkgs+=(gnome-keyring); fi
  if ! pkg_installed claude-desktop; then fresh=1; fi
  if is_dry && ! apt_available claude-desktop; then
    cmd "apt-get install claude-desktop (from Anthropic's repo)"
    apt_install "${pkgs[@]}"
  else
    apt_install claude-desktop "${pkgs[@]}"
  fi
  add_user_to_group kvm                  # Cowork's VM: /dev/kvm and /dev/vhost-vsock
  if (( fresh )) && { is_dry || pkg_installed claude-desktop; }; then
    followup manual "Claude Desktop: open Claude from your launcher (or run 'claude-desktop') and sign in."
  fi
}

# --- Local models ------------------------------------------------------------

_ai_local() {
  if have ollama; then info "Ollama already installed"; else install_script https://ollama.com/install.sh sh; fi

  # Ollama tuning: 16k context, with flash attention and an 8-bit KV cache to
  # make it fit in VRAM. Drop-in, so Ollama's installer (which rewrites
  # ollama.service on updates) leaves it alone. Restarts only on a change, so
  # a loaded model isn't dropped on every run. Redirected, not piped:
  # write_file must run in this shell for write_changed.
  write_file /etc/systemd/system/ollama.service.d/override.conf < <(printf '%s\n' '[Service]' \
    'Environment="OLLAMA_CONTEXT_LENGTH=16384"' \
    'Environment="OLLAMA_FLASH_ATTENTION=1"' \
    'Environment="OLLAMA_KV_CACHE_TYPE=q8_0"')
  if write_changed; then
    run sudo systemctl daemon-reload
    run sudo systemctl restart ollama
  fi

  # LM Studio Bionic: LM Studio's agent app, official .deb (separate from the
  # classic LM Studio app). Its postinst adds an AppArmor profile so Electron's
  # sandbox works; unlike Comfy Desktop it adds no apt repo. ~1 GB download,
  # no checksum published; it's fetched over TLS.
  # if pkg_installed lmstudio-bionic; then
  #   info "LM Studio Bionic already installed"
  # else
  #   local deb="$MODULE_TMP/lmstudio-bionic.deb"
  #   if download 'https://lmstudio.ai/download/bionic/latest/linux/x64?format=deb&redirectVersion=2' "$deb"; then
  #     apt_install "$deb"
  #   else
  #     soft_fail "LM Studio Bionic download failed. Get the .deb from https://lmstudio.ai/download"
  #   fi
  # fi

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

  # Comfy Desktop: official .deb. It installs and launches its own ComfyUI
  # instances (in ~/ComfyUI-Installs). Its postinst adds Comfy's apt repo, so
  # updates come through apt, and an AppArmor profile so Electron's sandbox
  # works (the AppImage would need --no-sandbox). No checksum is published;
  # it's fetched over TLS.
  if pkg_installed comfyui-desktop-2; then
    info "Comfy Desktop already installed"
  else
    local deb="$MODULE_TMP/comfy-desktop.deb"
    if download https://download.comfy.org/linux/deb/x64 "$deb"; then
      apt_install "$deb"
    else
      soft_fail "Comfy Desktop download failed. Get the .deb from https://docs.comfy.org/installation/desktop/linux"
    fi
  fi

  flatpak_install org.upscayl.Upscayl     # AI image upscaler

  followup manual "Start ComfyUI: source $venv/bin/activate && comfy --workspace $AI_DIR/ComfyUI launch"
  followup manual "Comfy Desktop: on first launch pick Local for a managed install, or use ☰ > Add Existing Instance on $AI_DIR/ComfyUI and set its Virtual Environment to $venv."
  followup manual "Optional: Krita AI Diffusion plugin (uses your ComfyUI), Stability Matrix, LM Studio."
}

ai_run() {
  _ai_cli
  _ai_local
  _ai_creative
  _ai_claude_desktop                     # last: a key fingerprint mismatch stops the module
}
