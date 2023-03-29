#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

export EDITOR=vim
export VISUAL=vim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

PS1='\[\e[0;33m\]\w\[\e[0;1;31m\] ❯ \[\e[0m\]'

## Use the up and down arrow keys for finding a command in history
## (you can write some initial letters of the command first).
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# Load aliases and functions if existent.
[ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"
[ -f "$HOME/.config/shell/functions" ] && source "$HOME/.config/shell/functions"

# Starship prompt
eval "$(starship init bash)"
