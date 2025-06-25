# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin/personal/:$PATH"
export PATH="$HOME/.local/share/cargo/bin/:$PATH"

# Defaults
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="foot"
export BROWSER="firefox"

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Tidy ~/
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/fzf/fzf-opts"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export GOPATH="$XDG_DATA_HOME/go"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export HISTFILE="$XDG_DATA_HOME/history"
export INPUTRC="$XDG_CONFIG_HOME/shell/inputrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js"
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export SSH_AUTH_SOCK="$XDG_DATA_HOME/ssh-agent.sock"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"

# Don't forget DBUS address
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
