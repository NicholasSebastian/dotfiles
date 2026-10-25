# shellcheck shell=bash
# GitHub releases and verified downloads. Nothing here touches the network
# in dry-run.

# Call the GitHub API. Uses $GITHUB_TOKEN or an existing `gh` login when
# available (the anonymous limit is 60 requests/hour). The token goes in a
# header file, so it never shows up in `ps`.
gh_api() {
  local path="$1" token="${GITHUB_TOKEN:-}" hdr="$SETUP_TMP/.gh-header"
  local -a auth=()
  if [[ -z "$token" ]] && have gh; then token="$(gh auth token 2>/dev/null || true)"; fi
  if [[ -n "$token" ]]; then
    ( umask 077; printf 'Authorization: Bearer %s\n' "$token" >"$hdr" )
    auth=(-H "@$hdr")
  fi
  curl -fsSL --retry 3 -H 'Accept: application/vnd.github+json' "${auth[@]}" \
    "https://api.github.com/$path"
}

# Latest release JSON, cached for the run (several modules ask twice). A
# failed request leaves no cache, so the caller sees the error.
gh_latest_json() {
  local repo="$1" cache="$SETUP_TMP/gh-${1//\//_}.json"
  if [[ ! -s "$cache" ]]; then
    gh_api "repos/$repo/releases/latest" >"$cache.part" || { rm -f "$cache.part"; return 1; }
    mv -f "$cache.part" "$cache"
  fi
  cat "$cache"
}

gh_latest_tag() { gh_latest_json "$1" | jq -r '.tag_name // empty'; }

# Print "URL<TAB>SHA256" of the first asset whose name matches REGEX (jq/
# Oniguruma syntax). The sha256 comes from the API's per-asset digest and is
# empty for old releases without one.
gh_latest_asset() {
  gh_latest_json "$1" | jq -r --arg re "$2" '
    [.assets[] | select(.name | test($re))][0] // empty
    | "\(.browser_download_url)\t\((.digest // "") | sub("^sha256:"; ""))"'
}

# download URL DEST [SHA256]
# Downloads to DEST.part and only moves it into place once complete and
# verified, so an interrupted download never looks like a finished one.
download() {
  local url="$1" dest="$2" sha="${3:-}" part="$2.part"
  if is_dry; then cmd "download $url -> $dest${sha:+ (sha256 ${sha:0:12}…)}"; return 0; fi
  mkdir -p "${dest%/*}"
  info "Downloading ${url##*/}"
  if ! curl -fsSL --retry 3 -o "$part" "$url"; then
    rm -f "$part"; err "Download failed: $url"; return 1
  fi
  if [[ -z "$sha" ]]; then
    warn "No checksum published for ${url##*/}"
  elif printf '%s  %s\n' "$sha" "$part" | sha256sum -c --quiet --status; then
    info "sha256 OK"
  else
    rm -f "$part"; err "Checksum mismatch for $url"; return 1
  fi
  mv -f "$part" "$dest"
}

# gh_download_latest REPO REGEX DEST
# Find the newest release asset matching REGEX and download it, verified.
gh_download_latest() {
  local repo="$1" re="$2" dest="$3" asset url sha
  if is_dry; then cmd "download latest $repo release asset /$re/ -> $dest (sha256 from GitHub)"; return 0; fi
  asset="$(gh_latest_asset "$repo" "$re")" || { err "Couldn't query $repo releases"; return 1; }
  [[ -n "$asset" ]] || { err "No asset matching /$re/ in the latest $repo release"; return 1; }
  IFS=$'\t' read -r url sha <<<"$asset"
  download "$url" "$dest" "$sha"
}
