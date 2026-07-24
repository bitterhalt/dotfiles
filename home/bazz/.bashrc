# Bashrc

[[ $- != *i* ]] && return

PS1="[\u@\h \W]\$ "

set -o vi

export HISTSIZE="50000"
export HISTFILESIZE="${HISTSIZE}"
export HISTCONTROL="ignoreboth:erasedups"
export HISTIGNORE="ls:ll:exit:clear:cd:top:htop*:history*:rm*"
export LC_COLLATE="C"
export MANPAGER="nvim +Man!"

shopt -s autocd
shopt -s cdspell
shopt -s checkwinsize
shopt -s histappend
shopt -s no_empty_cmd_completion

eval "$(fzf --bash)"
eval "$(starship init bash)"
eval "$(zoxide init --cmd cd bash)"

bind "set show-all-if-ambiguous on"
bind "set completion-ignore-case on"
bind "set colored-completion-prefix on"
bind "set bell-style none"
bind "TAB:menu-complete"
bind '"\ez":"cdi\C-m"'

case ${TERM} in
st* | alacritty | foot* | xterm* | rxvt* | kitty | kterm | gnome*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "${PWD/#$HOME/\~}"'
  ;;
tmux* | screen*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "tmux: ${PWD/#$HOME/\~}"'
  ;;
esac

source "$HOME/.config/shell/aliases"
