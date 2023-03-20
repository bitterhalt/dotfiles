# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

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
setopt auto_cd                          # Changing directories without 'cd'
cdpath=($HOME/.config)
export EDITOR=nvim                       # use vim as editor
export VISUAL=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)               # Include hidden files.

# Enable searching through history
bindkey "^R" history-incremental-pattern-search-backward
bindkey "^F" history-incremental-pattern-search-forward

# bindkey -e  # force Emacs key bindings
# bindkey -v  # force Vim key bindings


# make auto/tab colors match ls-colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"


# Load aliases and functions if existent.
[ -f "$HOME/.config/shellconf/aliases" ] && source "$HOME/.config/shellconf/aliases"
[ -f "$HOME/.config/shellconf/functions" ] && source "$HOME/.config/shellconf/functions"

# Custom ZSH Binds
# bindkey '^ ' autosuggest-accept
bindkey '^x' autosuggest-toggle

# Plugin list; put syntax-highlighting last!
# Put downloadet plugins to /home/zsh/plugins
source ~/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt
eval "$(starship init zsh)"

