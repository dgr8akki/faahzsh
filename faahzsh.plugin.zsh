# faahzsh - Play a "faaaah" sound when a command fails
# https://github.com/dgr8akki/faahzsh

# --- Configuration defaults ---
: ${FAAHZSH_ENABLED:=true}
: ${FAAHZSH_VOLUME:=5}

# --- Internal state ---
typeset -g _FAAHZSH_PID=""
typeset -g _FAAHZSH_PLUGIN_DIR="${0:A:h}"
typeset -g _FAAHZSH_SOUND_FILE="${_FAAHZSH_PLUGIN_DIR}/sounds/faaaah.wav"

# --- Detect platform and available player ---
_faahzsh_detect_player() {
  if [[ "$OSTYPE" == darwin* ]]; then
    echo "afplay"
  elif [[ "$OSTYPE" == linux* ]] || [[ "$OSTYPE" == freebsd* ]]; then
    if command -v paplay &>/dev/null; then
      echo "paplay"
    elif command -v aplay &>/dev/null; then
      echo "aplay"
    elif command -v ffplay &>/dev/null; then
      echo "ffplay"
    else
      echo "none"
    fi
  elif [[ "$OSTYPE" == msys* ]] || [[ "$OSTYPE" == cygwin* ]]; then
    if command -v powershell.exe &>/dev/null; then
      echo "powershell"
    elif command -v pwsh.exe &>/dev/null; then
      echo "pwsh"
    else
      echo "none"
    fi
  else
    echo "none"
  fi
}

typeset -g _FAAHZSH_PLAYER="$(_faahzsh_detect_player)"

if [[ "$_FAAHZSH_PLAYER" == "none" ]]; then
  echo "faahzsh: no supported audio player found. Install one of: afplay (macOS), paplay/aplay (Linux), powershell (Windows)" >&2
fi

# --- Play the sound ---
_faahzsh_play() {
  if [[ ! -f "$_FAAHZSH_SOUND_FILE" ]]; then
    echo "faahzsh: sound file not found at $_FAAHZSH_SOUND_FILE" >&2
    return 1
  fi

  # Kill any still-playing previous sound
  if [[ -n "$_FAAHZSH_PID" ]] && kill -0 "$_FAAHZSH_PID" 2>/dev/null; then
    kill "$_FAAHZSH_PID" 2>/dev/null
    wait "$_FAAHZSH_PID" 2>/dev/null
  fi

  # Map volume 0-10 to player-specific scale
  local vol=$FAAHZSH_VOLUME

  case "$_FAAHZSH_PLAYER" in
    afplay)
      # afplay volume: 0.0 - 2.0
      local afplay_vol
      afplay_vol=$(printf '%.1f' "$(( vol * 0.2 ))")
      afplay -v "$afplay_vol" "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    paplay)
      # paplay volume: 0 - 65536 (100% = 65536)
      local pa_vol=$(( vol * 6553 ))
      paplay --volume="$pa_vol" "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    aplay)
      # aplay has no volume control; play at system volume
      aplay -q "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    ffplay)
      # ffplay volume: 0 - 100
      local ff_vol=$(( vol * 10 ))
      ffplay -nodisp -autoexit -volume "$ff_vol" "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    powershell|pwsh)
      local ps_cmd="${_FAAHZSH_PLAYER}.exe"
      "$ps_cmd" -NoProfile -Command "
        \$p = New-Object System.Media.SoundPlayer('${_FAAHZSH_SOUND_FILE//\//\\}');
        \$p.PlaySync()
      " &>/dev/null &
      ;;
    *)
      return 1
      ;;
  esac

  _FAAHZSH_PID=$!
}

# --- precmd hook: check last exit code ---
_faahzsh_precmd() {
  local last_exit=$?

  [[ "$FAAHZSH_ENABLED" != true ]] && return
  [[ $last_exit -eq 0 ]] && return

  _faahzsh_play
}

# --- CLI command ---
faahzsh() {
  case "${1:-}" in
    on)
      FAAHZSH_ENABLED=true
      echo "faahzsh: enabled"
      ;;
    off)
      FAAHZSH_ENABLED=false
      echo "faahzsh: disabled"
      ;;
    status)
      echo "faahzsh: $([ "$FAAHZSH_ENABLED" = true ] && echo "enabled" || echo "disabled")"
      echo "volume:  $FAAHZSH_VOLUME / 10"
      echo "player:  $_FAAHZSH_PLAYER"
      ;;
    volume)
      if [[ -z "${2:-}" ]]; then
        echo "faahzsh: current volume is $FAAHZSH_VOLUME / 10"
        return 0
      fi
      if [[ "$2" =~ ^[0-9]+$ ]] && (( $2 >= 0 && $2 <= 10 )); then
        FAAHZSH_VOLUME=$2
        echo "faahzsh: volume set to $FAAHZSH_VOLUME / 10"
      else
        echo "faahzsh: volume must be an integer between 0 and 10" >&2
        return 1
      fi
      ;;
    test)
      echo "faahzsh: playing test sound..."
      _faahzsh_play
      ;;
    help|--help|-h)
      command cat <<'EOF'
faahzsh - Play a "faaaah" sound when a command fails

Usage:
  faahzsh on              Enable the plugin
  faahzsh off             Disable the plugin
  faahzsh status          Show current status, volume and player
  faahzsh volume [0-10]   Get or set volume (0 = mute, 10 = max)
  faahzsh test            Play the sound once for testing
  faahzsh help            Show this help message

Configuration (set in .zshrc before loading the plugin):
  FAAHZSH_ENABLED=true    Enable/disable on load (default: true)
  FAAHZSH_VOLUME=5        Volume level 0-10 (default: 5)

Supported platforms:
  macOS     afplay (built-in)
  Linux     paplay (PulseAudio), aplay (ALSA), or ffplay (FFmpeg)
  Windows   powershell.exe / pwsh.exe (via WSL/MSYS2/Cygwin)
EOF
      ;;
    *)
      echo "faahzsh: unknown command '${1:-}'. Run 'faahzsh help' for usage." >&2
      return 1
      ;;
  esac
}

# --- Register the hook ---
autoload -Uz add-zsh-hook
add-zsh-hook precmd _faahzsh_precmd
