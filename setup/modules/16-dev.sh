# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=dev
MODULE_DESC="Docker, GitHub CLI, delta, Postman, Wireshark"
MODULE_DEFAULT=1
}

dev_run() {
  apt_install docker.io docker-compose docker-buildx gh git-delta sqlite3

  # Docker writes its own firewall rules and bypasses ufw, so '-p 3000:3000'
  # would be reachable from any network you join. Bind published ports to
  # localhost by default; use '-p 0.0.0.0:3000:3000' when you mean it.
  # An existing daemon.json is yours and left alone.
  if [[ ! -e /etc/docker/daemon.json ]]; then
    printf '{ "ip": "127.0.0.1" }\n' | write_file /etc/docker/daemon.json
    if systemctl is-active -q docker.service 2>/dev/null; then
      run sudo systemctl restart docker.service   # only when the config is new
    fi
  fi
  enable_now docker.service
  add_user_to_group docker

  # Wireshark, with packet capture allowed for the wireshark group (no sudo)
  if ! pkg_installed wireshark; then
    debconf_preseed 'wireshark-common wireshark-common/install-setuid boolean true'
    apt_install wireshark
  fi
  add_user_to_group wireshark

  local apps=(
    com.getpostman.Postman
    # io.dbeaver.DBeaverCommunity
    # io.beekeeperstudio.Studio
    # com.usebruno.Bruno
  )
  flatpak_install "${apps[@]}"

  # Optional CLIs
  # have turso || install_script https://get.tur.so/install.sh bash

  # Git defaults (kept from your old .gitconfig, with modern tweaks).
  # Format: "key value"; everything after the first space is the value.
  local git_settings=(
    "merge.conflictStyle zdiff3"           # diff3, minus the duplicated lines
    "diff.colorMoved default"
    "init.defaultBranch main"
    "pull.rebase true"
    "push.autoSetupRemote true"
    "rerere.enabled true"                  # remember conflict resolutions
  )
  # Only point git at delta if it's actually there, or git log/diff break
  if is_dry || have delta; then
    git_settings+=(
      "core.pager delta"
      "interactive.diffFilter delta --color-only"
      "delta.navigate true"
      "delta.side-by-side true"
    )
  fi
  # Only fills in keys you haven't set, so re-runs never undo your own changes
  local setting key
  for setting in "${git_settings[@]}"; do
    key="${setting%% *}"
    if git config --global --get "$key" >/dev/null; then continue; fi
    run git config --global "$key" "${setting#* }"
  done

  if ! git config --global user.name >/dev/null; then
    followup manual "Set your git identity: git config --global user.name '...' && git config --global user.email '...'"
  fi
  if ! gh auth token >/dev/null 2>&1; then           # local check, no network
    followup manual "Run 'gh auth login' then 'gh auth setup-git' (stores GitHub credentials safely, unlike the old credential.helper=store)."
  fi
}
