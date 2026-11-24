# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=ai
MODULE_DESC="Claude Code (CLI + Desktop), Oh My Pi, Herdr, graphify, Hermes Agent (Docker sandbox, profiles, Mnemosyne), Ollama (+ optional Open WebUI), ComfyUI (CLI + Desktop), Upscayl"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes dev)               # bun, uv; Docker for Hermes' terminal sandbox and Open WebUI
}

# --- Coding agents -----------------------------------------------------------

# Hermes Desktop: --build-only; entry only after success; GPU forced (NVIDIA fallback = SwiftShader)
_ai_hermes_desktop() {
  local entry="$HOME/.local/share/applications/com.nousresearch.hermes.desktop"
  if [[ -f "$entry" ]]; then
    info "Hermes Desktop already installed"
  else
    if ! is_dry && ! have hermes; then soft_fail "Hermes Desktop not built: the hermes command isn't available"; return 0; fi
    run hermes desktop --build-only || { soft_fail "Hermes Desktop build failed; retry with 'hermes desktop --build-only'"; return 0; }
  fi
  run hermes config set desktop.manage_launcher_entry false || { soft_fail "Couldn't set desktop.manage_launcher_entry; Hermes may rewrite its launcher entry"; return 0; }
  write_file "$entry" 0755 <<EOF
[Desktop Entry]
Type=Application
Name=Hermes
GenericName=Hermes Desktop
Comment=Launch Hermes Desktop
Exec=env HERMES_DESKTOP_DISABLE_GPU=0 HERMES_DESKTOP_NVIDIA_SWIFTSHADER=0 $HOME/.local/bin/hermes desktop --skip-build
Icon=hermes
Terminal=false
Categories=Utility;
StartupNotify=true
StartupWMClass=com.nousresearch.hermes
EOF
}

_ai_cli() {
  if have claude; then info "Claude Code already installed"; else install_script https://claude.ai/install.sh bash; fi

  # Oh My Pi ('omp'). mise's GitHub backend is one of upstream's documented methods.
  mise_use "github:can1357/oh-my-pi"

  # Herdr: agent multiplexer; mise registry entry (aqua backend), an upstream-documented method. Update via mise, not 'herdr update'.
  mise_use herdr

  # graphify (PyPI 'graphifyy'): the skill is re-registered every run so it matches the package.
  need uv runtimes
  if have graphify; then info "graphify already installed"; else run uv tool install graphifyy; fi
  run graphify install --platform agents || soft_fail "graphify: registering the skill failed; retry with 'graphify install --platform agents'"

  # Hermes Agent: upstream installer (only Linux install); --non-interactive as stdin is /dev/null.
  if have hermes; then
    info "Hermes Agent already installed"
  else
    install_script https://hermes-agent.nousresearch.com/install.sh bash --non-interactive
    followup manual "Hermes Agent: run 'hermes setup' to pick a model provider."
  fi
  _ai_hermes_desktop

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

# Claude Desktop (beta): from Anthropic's apt repo (updates via apt); key pinned by fingerprint.
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
  write_file /etc/apt/sources.list.d/claude-desktop.list <<EOF
deb [arch=amd64,arm64 signed-by=$_AI_CLAUDE_KEYRING] https://downloads.claude.ai/claude-desktop/apt/stable stable main
EOF
  if write_changed; then changed=1; fi
  if (( changed )); then apt_update; fi

  # apt_install skips recommends, so the app's needs are listed; gnome-keyring skipped on KDE.
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

_AI_LOCAL_MODEL=qwen3.5:4b                # default local model
_AI_LOCAL_MODEL_64K=qwen3.5:4b-64k        # Hermes' auxiliary model (private_dot_hermes configs name it)
_AI_LOCAL_MODELFILE="$SETUP_DIR/files/ollama/qwen3.5-4b-64k.Modelfile"

_ai_local() {
  if have ollama; then info "Ollama already installed"; else install_script https://ollama.com/install.sh sh; fi

  # Ollama: 65k context (Hermes rejects <64k), flash attention + 8-bit KV cache to fit in VRAM.
  write_file /etc/systemd/system/ollama.service.d/override.conf <<'EOF'
[Service]
Environment="OLLAMA_CONTEXT_LENGTH=65536"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
EOF
  if write_changed; then
    run sudo systemctl daemon-reload
    run sudo systemctl restart ollama
  fi

  # LM Studio Bionic .deb: adds an AppArmor profile, no apt repo; ~1 GB, no checksum (TLS only).
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
      # Host network: Ollama listens on 127.0.0.1 only; HOST/PORT keep the UI on localhost:3000.
      run sudo docker run -d --name open-webui --restart always \
        --network=host -e HOST=127.0.0.1 -e PORT=3000 \
        -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
        -v open-webui:/app/backend/data \
        ghcr.io/open-webui/open-webui:main
      followup manual "Open WebUI: http://localhost:3000"
    fi
  fi

  # Default local model, plus a 64K-context variant for Hermes (Hermes refuses models under 64K).
  if is_dry || have ollama; then
    if ! is_dry && ollama show "$_AI_LOCAL_MODEL" >/dev/null 2>&1; then
      info "Ollama: $_AI_LOCAL_MODEL already pulled"
    else
      run ollama pull "$_AI_LOCAL_MODEL" || soft_fail "Ollama: pulling $_AI_LOCAL_MODEL failed; retry with 'ollama pull $_AI_LOCAL_MODEL'"
    fi
    local want_ctx
    want_ctx="$(awk '$1 == "PARAMETER" && $2 == "num_ctx" { print $3 }' "$_AI_LOCAL_MODELFILE")"
    if ! is_dry && ollama show "$_AI_LOCAL_MODEL_64K" --parameters 2>/dev/null | grep -Eq "^num_ctx[[:space:]]+$want_ctx\$"; then
      info "Ollama: $_AI_LOCAL_MODEL_64K already created"
    else
      run ollama create "$_AI_LOCAL_MODEL_64K" -f "$_AI_LOCAL_MODELFILE" || soft_fail "Ollama: creating $_AI_LOCAL_MODEL_64K failed"
    fi
  fi
}

# --- Hermes Agent setup ------------------------------------------------------

# Sandbox workspace + Obsidian vault, mounted at their host paths;
# keep paths in sync with private_dot_hermes' docker_volumes.
_AI_HERMES_WS="$HOME/hermes-workspace"
_AI_HERMES_MASK="$HOME/.local/share/hermes/vault-private-mask"
_AI_HERMES_IMAGE=nousresearch/hermes-sandbox:desktop   # Hermes' default terminal.docker_image
_AI_HERMES_MNEMOSYNE_PROFILE=bot-boss   # the profile whose config.yaml sets memory.provider: mnemosyne

# Profiles (config.yaml, SOUL.md) come from the dotfiles; this prepares the workspace and installs plugins.
_ai_hermes() {
  if ! is_dry && ! have hermes; then soft_fail "Hermes setup skipped: the hermes command isn't available"; return 0; fi

  # Before Docker's first run, or Docker creates the mount sources owned by root
  run mkdir -p "$_AI_HERMES_WS/research" "$_AI_HERMES_WS/vault/read-only" "$_AI_HERMES_WS/vault/read-write" \
    "$_AI_HERMES_WS/vault/private" "$_AI_HERMES_MASK"

  # The vault is its own git repo; its contents are never touched once there
  if [[ ! -d "$_AI_HERMES_WS/vault/.git" ]]; then run git -C "$_AI_HERMES_WS/vault" init -q; fi
  if [[ ! -e "$_AI_HERMES_WS/vault/.gitignore" ]]; then
    write_file "$_AI_HERMES_WS/vault/.gitignore" <<'EOF'
# Obsidian per-device workspace state
.obsidian/workspace.json
.obsidian/workspace-mobile.json
EOF
  fi

  # Pull the sandbox image now, or Hermes pulls it mid-first-message (60 s probe timeout, minutes).
  if ! is_dry && sudo docker image inspect "$_AI_HERMES_IMAGE" >/dev/null 2>&1; then
    info "Hermes sandbox image already pulled"
  else
    run sudo docker pull "$_AI_HERMES_IMAGE" || soft_fail "Hermes: pulling $_AI_HERMES_IMAGE failed; retry with 'docker pull $_AI_HERMES_IMAGE'"
  fi

  if [[ -d "$HOME/.hermes/plugins/advanced-delegation" ]]; then
    info "Hermes plugin advanced-delegation already installed"
  else
    run hermes plugins install advanced-delegation --enable --yes-deps || soft_fail "Hermes: installing advanced-delegation failed"
  fi

  _ai_hermes_mnemosyne
}

# Mnemosyne: pipx venv must match Hermes' Python major.minor; recreated if not.
_ai_hermes_mnemosyne() {
  local home="$HOME/.hermes/profiles/$_AI_HERMES_MNEMOSYNE_PROFILE" mm venv venv_mm
  local -a force=()
  apt_install pipx
  if is_dry; then
    cmd "pipx install mnemosyne-hermes; mnemosyne-hermes --hermes-home $home install --mode wrapper"
    return 0
  fi
  mm="$(hermes --version 2>/dev/null | sed -n 's/^Python: \([0-9]*\.[0-9]*\).*/\1/p')"
  [[ -n "$mm" ]] || { soft_fail "Mnemosyne: couldn't read Hermes' Python version"; return 0; }
  venv="$(pipx environment --value PIPX_LOCAL_VENVS)/mnemosyne-hermes"
  venv_mm="$("$venv/bin/python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || true)"
  if [[ "$venv_mm" != "$mm" ]]; then
    if [[ -n "$venv_mm" ]]; then run pipx uninstall mnemosyne-hermes; fi
    run pipx install --python "$mm" --fetch-python=missing mnemosyne-hermes || { soft_fail "Mnemosyne: pipx install failed"; return 0; }
    force=(--force)
  fi
  if (( ${#force[@]} )) || [[ ! -d "$home/plugins/mnemosyne" ]]; then
    run "$venv/bin/mnemosyne-hermes" --hermes-home "$home" install --mode wrapper --python "$venv/bin/python" --no-profile-links "${force[@]}" \
      || soft_fail "Mnemosyne: plugin install into the $_AI_HERMES_MNEMOSYNE_PROFILE profile failed"
  else
    info "Mnemosyne already installed for the $_AI_HERMES_MNEMOSYNE_PROFILE profile"
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

  # ComfyUI gets its own Python 3.12 venv: global Python is too new for PyTorch GPU builds.
  local venv="$AI_DIR/.venv"
  if [[ ! -x "$venv/bin/python" ]]; then
    run mkdir -p "$AI_DIR"
    run uv venv --python 3.12 "$venv"
  fi

  local gpu
  gpu="$(_ai_gpu)"
  if [[ "$gpu" == cpu ]]; then warn "No NVIDIA/AMD GPU found, ComfyUI will run on CPU"; fi

  # Checks main.py, not the folder, so a failed install is retried; runs in the venv for comfy-cli.
  if [[ -f "$AI_DIR/ComfyUI/main.py" ]]; then
    info "ComfyUI already installed in $AI_DIR/ComfyUI"
  else
    run env VIRTUAL_ENV="$venv" PATH="$venv/bin:$PATH" \
      comfy --skip-prompt --workspace "$AI_DIR/ComfyUI" install "--$gpu"
  fi

  # Comfy Desktop .deb: postinst adds Comfy's apt repo + AppArmor profile; no checksum, TLS only.
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
  _ai_hermes                             # after _ai_local: Hermes' aux tasks use its 64K model
  _ai_creative
  _ai_claude_desktop                     # last: a key fingerprint mismatch stops the module
}
