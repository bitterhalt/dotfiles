# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# Enable colors and change prompt:
autoload -U colors && colors

# Some prompts. (Not needed at all if you are using starship)
#PS1="%{$fg[red]%}%n%{$reset_color%}@%{$fg[blue]%}%m %{$fg[yellow]%}%~ %{$reset_color%}%% "  #zsh style
#PROMPT="%F{blue}%~%f %F{green❯%f "
#PROMPT="%B%F{yellow}%~%f%b %B%F{blue}→%f%b "
#PS1="%F{green}%n%f@%m %F{green}%~%f> "  # fish style

# History
HISTFILE=~/.zsh_history                 # History filepath
HISTSIZE=5000                           # Maximum events for internal history
SAVEHIST=5000                           # Maximum events in history file
setopt APPEND_HISTORY                   # Immediately append history instead of overwriting
setopt HIST_IGNORE_ALL_DUPS             # If a new command is a duplicate, remove the older one
setopt HIST_SAVE_NO_DUPS                # Do not save duplicated command
setopt globdots

export EDITOR=nvim
export VISUAL=nvim
#export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zmodload zsh/complist
compinit

bindkey "^R" history-incremental-pattern-search-backward
bindkey "^F" history-incremental-pattern-search-forward
bindkey '^x' autosuggest-toggle

# Load aliases and functions if existent.
[ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"
[ -f "$HOME/.config/shell/functions" ] && source "$HOME/.config/shell/functions"

# Plugin list; put syntax-highlighting last!
# Put downloadet plugins to /home/zsh/plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt
eval "$(starship init zsh)"
