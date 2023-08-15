# If not running interactively, don't do anything
[[ $- != *i* ]] && return

autoload -U colors && colors

# History
HISTSIZE=5000                           # Maximum events for internal history
SAVEHIST=5000                           # Maximum events in history file
HISTFILE=~/.zsh_history                 # History filepath
setopt append_history                   # Immediately append history instead of overwriting
setopt hist_ignore_all_dups             # If a new command is a duplicate, remove the older one
setopt hist_save_no_dups                # Do not save duplicated command
setopt auto_cd                          # Move between directories without cd

# Defaults
export EDITOR=nvim
export VISUAL=nvim

# Basic auto/tab complete
autoload -U compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zmodload zsh/complist
#_comp_options+=(globdots)		# Include hidden files.

bindkey "^R" history-incremental-pattern-search-backward
bindkey "^F" history-incremental-pattern-search-forward
bindkey '^x' autosuggest-toggle

# Load aliases and functions if existent.
[ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"
[ -f "$HOME/.config/shell/functions" ] && source "$HOME/.config/shell/functions"

# Plugin list; put syntax-highlighting last!
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt
eval "$(starship init zsh)"
