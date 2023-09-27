# Defaults
export EDITOR="nvim"
export TERMINAL="st"
export BROWSER="librewolf"

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin/statusbar:$PATH"

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ~/ Clean-up:
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GOPATH="$XDG_DATA_HOME/go"
export XINITRC="$XDG_CONFIG_HOME/x11/xinitrc"


# Start graphical server and output stout & stderr
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
   exec startx -- -keeptty >~/.xorg.log 2>&1
fi


