# faahzsh - Play a "faaaah" sound when a command fails (Bash version)
# https://github.com/dgr8akki/faahzsh

# --- Configuration defaults ---
: ${FAAHZSH_ENABLED:=true}
: ${FAAHZSH_VOLUME:=5}

# --- Internal state ---
_FAAHZSH_PID=""
_FAAHZSH_PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_FAAHZSH_SOUND_FILE="${_FAAHZSH_PLUGIN_DIR}/sounds/faaaah.wav"

# --- Detect platform and available player ---
_faahzsh_detect_player() {
  case "$OSTYPE" in
    darwin*)
      echo "afplay"
      ;;
    linux*|freebsd*)
      if command -v paplay &>/dev/null; then
        echo "paplay"
      elif command -v aplay &>/dev/null; then
        echo "aplay"
      elif command -v ffplay &>/dev/null; then
        echo "ffplay"
      else
        echo "none"
      fi
      ;;
    msys*|cygwin*)
      if command -v powershell.exe &>/dev/null; then
        echo "powershell"
      elif command -v pwsh.exe &>/dev/null; then
        echo "pwsh"
      else
        echo "none"
      fi
      ;;
    *)
      echo "none"
      ;;
  esac
}

_FAAHZSH_PLAYER="$(_faahzsh_detect_player)"

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

  local vol=$FAAHZSH_VOLUME

  case "$_FAAHZSH_PLAYER" in
    afplay)
      local afplay_vol
      afplay_vol=$(awk "BEGIN {printf \"%.1f\", $vol * 0.2}")
      afplay -v "$afplay_vol" "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    paplay)
      local pa_vol=$(( vol * 6553 ))
      paplay --volume="$pa_vol" "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    aplay)
      aplay -q "$_FAAHZSH_SOUND_FILE" &>/dev/null &
      ;;
    ffplay)
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

# --- PROMPT_COMMAND hook: check last exit code ---
_faahzsh_prompt_command() {
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
      if [[ "$FAAHZSH_ENABLED" == true ]]; then
        echo "faahzsh: enabled"
      else
        echo "faahzsh: disabled"
      fi
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
      cat <<'EOF'
faahzsh - Play a "faaaah" sound when a command fails

Usage:
  faahzsh on              Enable the plugin
  faahzsh off             Disable the plugin
  faahzsh status          Show current status, volume and player
  faahzsh volume [0-10]   Get or set volume (0 = mute, 10 = max)
  faahzsh test            Play the sound once for testing
  faahzsh help            Show this help message

Configuration (set in .bashrc before sourcing the plugin):
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
# Prepend to PROMPT_COMMAND so we capture $? before anything else runs
if [[ -z "$PROMPT_COMMAND" ]]; then
  PROMPT_COMMAND="_faahzsh_prompt_command"
else
  PROMPT_COMMAND="_faahzsh_prompt_command;${PROMPT_COMMAND}"
fi
