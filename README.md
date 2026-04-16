# faahzsh

A zsh/bash plugin that plays a **"faaaah"** sound whenever a command exits with a non-zero status code. Because your failures deserve to be heard.

## Requirements

- **zsh** 4.3.11+ or **bash** 3.2+
- One of the following audio players:
  - **macOS**: `afplay` (built-in, no install needed)
  - **Linux**: `paplay` (PulseAudio), `aplay` (ALSA), or `ffplay` (FFmpeg)
  - **Windows** (WSL/MSYS2/Cygwin): `powershell.exe` or `pwsh.exe`

## Installation

### Homebrew

```sh
brew tap dgr8akki/tap
brew install faahzsh
```

Then add to your shell config as shown in `brew info faahzsh`.

### Antigen (zsh)

```zsh
antigen bundle dgr8akki/faahzsh
```

### Zinit (zsh)

```zsh
zinit light dgr8akki/faahzsh
```

### Oh-My-Zsh

Clone into your custom plugins directory:

```zsh
git clone https://github.com/dgr8akki/faahzsh.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/faahzsh
```

Then add it to your plugins in `~/.zshrc`:

```zsh
plugins=(... faahzsh)
```

### Bash

Clone the repo and source it in your `~/.bashrc`:

```bash
git clone https://github.com/dgr8akki/faahzsh.git ~/faahzsh
echo 'source ~/faahzsh/faahzsh.plugin.bash' >> ~/.bashrc
```

### Manual (zsh)

Clone the repo and source it in your `~/.zshrc`:

```zsh
git clone https://github.com/dgr8akki/faahzsh.git ~/faahzsh
echo 'source ~/faahzsh/faahzsh.plugin.zsh' >> ~/.zshrc
```

## Configuration

Set these in your shell config **before** the plugin is loaded:

```zsh
FAAHZSH_ENABLED=true   # Enable/disable (default: true)
FAAHZSH_VOLUME=5       # Volume 0-10 (default: 5)
```

## Usage

```
faahzsh on              Enable the plugin
faahzsh off             Disable the plugin
faahzsh status          Show current status and volume
faahzsh volume [0-10]   Get or set volume (0 = mute, 10 = max)
faahzsh test            Play the sound once for testing
faahzsh help            Show help message
```

## How It Works

The plugin hooks into your shell's prompt cycle (`precmd` in zsh, `PROMPT_COMMAND` in bash) to check the exit code of the last command. If the exit code is non-zero, it plays the bundled sound file in the background (non-blocking).

The sound file (`sounds/faaaah.wav`) is bundled with the plugin. The plugin auto-detects the best available audio player for your platform.

## License

MIT
