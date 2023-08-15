# If not running interactively, don't do anything
[[ $- != *i* ]] && return

autoload -U colors && colors
autoload -U compinit && compinit

# History
HISTFILE=~/.zsh_history                 # History filepath
HISTSIZE=5000                           # Maximum events for internal history
SAVEHIST=5000                           # Maximum events in history file
setopt APPEND_HISTORY                   # Immediately append history instead of overwriting
setopt HIST_IGNORE_ALL_DUPS             # If a new command is a duplicate, remove the older one
setopt HIST_SAVE_NO_DUPS                # Do not save duplicated command

export EDITOR=nvim
export VISUAL=nvim
#export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Basic auto/tab complete
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zmodload zsh/complist

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
