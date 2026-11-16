# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=ai
MODULE_DESC="Claude Code (CLI + Desktop), Oh My Pi, Hermes Agent (Docker sandbox, profiles, Mnemosyne), Ollama (+ optional Open WebUI), ComfyUI (CLI + Desktop), Upscayl"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes dev)               # bun, uv; Docker for Hermes' terminal sandbox and Open WebUI
}

# --- Coding agents -----------------------------------------------------------

# Hermes Desktop: built from the Hermes checkout. Plain 'hermes desktop' builds
# and then runs the app in the foreground, which would block the run;
# --build-only builds it, then exits. 'hermes update' rebuilds it from then on.
# The launcher entry is only written after a build succeeds, so a failed build
# is retried on the next run.
#
# Hermes rewrites its .desktop entry on every launch unless desktop.manage_launcher_entry
# is false. The dotfiles' config.yaml declares that too, but this module has no dotfiles
# dependency, so set it in the live config first. The entry then forces the GPU on: the
# app's sticky NVIDIA fallback otherwise renders in software (SwiftShader) and the UI lags.
# Electron flags come from desktop.electron_flags in the dotfiles' config.yaml.
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
  write_file /etc/apt/sources.list.d/claude-desktop.list <<EOF
deb [arch=amd64,arm64 signed-by=$_AI_CLAUDE_KEYRING] https://downloads.claude.ai/claude-desktop/apt/stable stable main
EOF
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

_AI_LOCAL_MODEL=qwen3.5:4b                # default local model
_AI_LOCAL_MODEL_64K=qwen3.5:4b-64k        # Hermes' auxiliary model (private_dot_hermes configs name it)
_AI_LOCAL_MODELFILE="$SETUP_DIR/files/ollama/qwen3.5-4b-64k.Modelfile"

_ai_local() {
  if have ollama; then info "Ollama already installed"; else install_script https://ollama.com/install.sh sh; fi

  # Ollama tuning: 65k context, with flash attention and an 8-bit KV cache to fit in VRAM.
  # Hermes Agent rejects models whose context is under 64k.
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

# Workspace the Docker sandbox sees as /workspace, with an Obsidian vault in it.
# vault/read-only is mounted read-only and vault/private is masked by an empty
# folder, both via terminal.docker_volumes in private_dot_hermes' configs,
# which name these paths under {{ .chezmoi.homeDir }}: keep them in sync.
_AI_HERMES_WS="$HOME/hermes-workspace"
_AI_HERMES_MASK="$HOME/.local/share/hermes/vault-private-mask"
_AI_HERMES_IMAGE=nousresearch/hermes-sandbox:desktop   # Hermes' default terminal.docker_image
_AI_HERMES_PROFILES=(orchestrator researcher librarian)
declare -gA _AI_HERMES_DESC=(
  [orchestrator]="Clarifies outcomes and acceptance criteria, routes research to researcher and approved material to librarian, reviews results. Does no research itself."
  [researcher]="Answers bounded research questions with cited briefs (uncertainty, counter-evidence, gaps) saved to /workspace/research/."
  [librarian]="Sole writer of the Obsidian wiki at /workspace/vault via llm-wiki; stages new material in review/ and applies it only after approval."
)

# Profiles get their config.yaml and SOUL.md from the dotfiles (the dotfiles
# module runs later); this creates them, sets the non-secret .env keys and
# installs the plugins.
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

  # Pull the sandbox image now. Hermes otherwise pulls it inside your first
  # message, behind a 60 s probe timeout: that turn then takes minutes.
  # sudo: the docker group doesn't apply until the next login.
  if ! is_dry && sudo docker image inspect "$_AI_HERMES_IMAGE" >/dev/null 2>&1; then
    info "Hermes sandbox image already pulled"
  else
    run sudo docker pull "$_AI_HERMES_IMAGE" || soft_fail "Hermes: pulling $_AI_HERMES_IMAGE failed; retry with 'docker pull $_AI_HERMES_IMAGE'"
  fi

  local p
  for p in "${_AI_HERMES_PROFILES[@]}"; do
    if [[ -d "$HOME/.hermes/profiles/$p" ]]; then
      info "Hermes profile $p already exists"
    else
      run hermes profile create "$p" --clone --description "${_AI_HERMES_DESC[$p]}" || soft_fail "Hermes: creating profile $p failed"
    fi
    run hermes profile describe "$p" --text "${_AI_HERMES_DESC[$p]}" || soft_fail "Hermes: describing profile $p failed"
  done

  # Each profile reads only its own .env; the agent sees the vault at /workspace/vault
  local -a sel
  local key
  for p in "" "${_AI_HERMES_PROFILES[@]}"; do
    sel=()
    if [[ -n "$p" ]]; then sel=(-p "$p"); fi
    for key in OBSIDIAN_VAULT_PATH WIKI_PATH; do
      run hermes "${sel[@]}" config set "$key" /workspace/vault || soft_fail "Hermes: setting $key${p:+ for $p} failed"
    done
  done

  if [[ -d "$HOME/.hermes/plugins/advanced-delegation" ]]; then
    info "Hermes plugin advanced-delegation already installed"
  else
    run hermes plugins install advanced-delegation --enable --yes-deps || soft_fail "Hermes: installing advanced-delegation failed"
  fi

  _ai_hermes_mnemosyne
}

# Mnemosyne memory for the orchestrator profile only (memory.provider is set in
# its dotfiles config). pipx keeps it out of Hermes' runtime venv, which
# 'hermes update' replaces; wrapper mode writes a real plugin folder into the
# profile that imports from the pipx venv. That venv must run Hermes' Python
# major.minor, so a Hermes update that changes it gets a fresh venv here.
_ai_hermes_mnemosyne() {
  local home="$HOME/.hermes/profiles/orchestrator" mm venv venv_mm
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
      || soft_fail "Mnemosyne: plugin install into the orchestrator profile failed"
  else
    info "Mnemosyne already installed for the orchestrator profile"
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
  _ai_hermes                             # after _ai_local: Hermes' aux tasks use its 64K model
  _ai_creative
  _ai_claude_desktop                     # last: a key fingerprint mismatch stops the module
}
