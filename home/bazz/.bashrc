# Bashrc

[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ ' # Default prompt

export HISTCONTROL="ignoreboth:erasedups"                      # No duplicate entries
export HISTFILESIZE="5000"                                     # History file size
export HISTIGNORE="ls:ll:exit:clear:cd:top:htop*:history*:rm*" # Ignore commands
export HISTSIZE="5000"                                         # History size
export LC_COLLATE="C"                                          # Collation order
export MANPAGER="nvim +Man!"                                   # Nvim as manpager

set -o vi # vi mode
bind -m vi-command "Control-l: clear-screen"
bind -m vi-insert "Control-l: clear-screen"

shopt -s autocd                  # Change to named directory
shopt -s cdspell                 # Autocorrects cd misspellings
shopt -s checkwinsize            # Checks term size when bash regains control
shopt -s histappend              # Do not overwrite history
shopt -s no_empty_cmd_completion # Do not TAB expand empty lines

bind "set show-all-if-ambiguous on"     # List available options in tab-menu
bind "set completion-ignore-case on"    # Ignore upper and lowercase in TAB-completion
bind "set colored-completion-prefix on" # Enable completion coloring
bind "TAB:menu-complete"                # Better tab-completion
bind '"\e[Z": menu-complete-backward'   # Shift-Tab cycle backwards

eval "$(dircolors ~/.config/shell/dircolors)" # Load dircolors
eval "$(fzf --bash)"                          # CTRL-t = fzf select | CTRL-r = fzf history |  ALT-c  = fzf cd
eval "$(starship init bash)"                  # Load prompt
eval "$(zoxide init --cmd cd bash)"           # Use zoxide to cd

# Cleaner titles
case ${TERM} in
st* | alacritty | foot | xterm* | rxvt* | kitty | kterm | gnome*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "${PWD/#$HOME/\~}"'
  export COLORTERM=truecolor
  ;;
tmux* | screen*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "tmux: ${PWD/#$HOME/\~}"'
  ;;
esac

# Aliases
alias ..="cd .."
alias cp="cp -iv"
alias duf="duf --hide special -theme ansi"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"
alias free="free -m"
alias grep="grep --color=auto"
alias mkdir="mkdir -pv"
alias mv="mv -iv"
alias rm="rm -vI"
# Pacman
alias cleanup="sudo pacman -Rns $(pacman -Qtdq)" # remove orphaned packages
alias pkglist="pacman -Qe > ~/Documents/projects/dotfiles/packages"
# Vim
alias vi="nvim"
alias vim="nvim"
# ls
alias ls="ls -ho --group-directories-first --color=auto"
alias la="ls -laho --group-directories-first --color=auto"
# Trash-cli
alias tp="trash-put"
alias tpe="trash-empty"
alias tpr="trash-restore"
# Random
alias hg="history | grep "
alias nvm="sudo nvme smart-log /dev/nvme0"
alias ex="extrac_helper"
# Systemd Journal
alias loger="journalctl -p 3 -xb"
alias logf="journalctl -f"
alias logr="sudo journalctl --rotate"
alias logs="journalctl --disk-usage"
alias logv="journalctl --verify"
alias logw="sudo journalctl --vacuum-time=1s"
# Grub
alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"
