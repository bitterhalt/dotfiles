[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin/appimages/:$PATH"
export PATH="$HOME/.local/share/cargo/bin/:$PATH"

# SHELL STUFF
export HISTFILE="$HOME/.cache/bash_history"
export INPUTRC="$XDG_CONFIG_HOME/shell/inputrc"
