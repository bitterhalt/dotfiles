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

PS1='\[\e[0;33m\]\w\[\e[0;1;31m\] ❯ \[\e[0m\]'

## Use the up and down arrow keys for finding a command in history
## (you can write some initial letters of the command first).
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# Load aliases and functions if existent.
[ -f "$HOME/.config/shellconf/aliases" ] && source "$HOME/.config/shellconf/aliases"
[ -f "$HOME/.config/shellconf/functions" ] && source "$HOME/.config/shellconf/functions"

# Starship prompt
eval "$(starship init bash)"
