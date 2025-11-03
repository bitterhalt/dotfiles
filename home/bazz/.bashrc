# Bashrc

[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ ' # Default prompt

export HISTSIZE="10000"                                        # History size
export HISTFILESIZE="${HISTSIZE}"                              # History file size
export HISTCONTROL="ignoreboth:erasedups"                      # No duplicate entries
export HISTIGNORE="ls:ll:exit:clear:cd:top:htop*:history*:rm*" # Ignore commands
export LC_COLLATE="C"                                          # Collation order
export MANPAGER="nvim +Man!"                                   # Nvim as manpager

shopt -s autocd                  # Change to named directory
shopt -s cdspell                 # Autocorrects cd misspellings
shopt -s checkwinsize            # Checks term size when bash regains control
shopt -s histappend              # Do not overwrite history
shopt -s no_empty_cmd_completion # Do not TAB expand empty lines

eval "$(dircolors ~/.config/shell/dircolors)" # Load dircolors
eval "$(fzf --bash)"                          # CTRL-t = fzf select | CTRL-r = fzf history |  ALT-c  = fzf cd
eval "$(starship init bash)"                  # Load prompt
eval "$(zoxide init --cmd cd bash)"           # Use zoxide to cd

# Cleaner titles
case ${TERM} in
st* | alacritty | foot | xterm* | rxvt* | kitty | kterm | gnome*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "${PWD/#$HOME/\~}"'
  ;;
tmux* | screen*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "tmux: ${PWD/#$HOME/\~}"'
  ;;
esac

# Aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias cp="cp -iv"
alias duf="duf --hide special -theme ansi"
alias df="df -hT --total"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"
alias free="free -m"
alias grep="grep --color=auto"
alias mkdir="mkdir -pv"
alias mv="mv -iv"
alias rm="rm -vI"
# Pacman
alias cleanup="sudo pacman -Rns $(pacman -Qtdq)" # remove orphaned packages
alias pacdiff="sudo DIFFPROG=nvim pacdiff"
alias pkglist="pacman -Qe > ~/Documents/projects/dotfiles/packages"
alias rate-mirrors="rate-mirrors --protocol https --entry-country FI --country-test-mirrors-per-country 10 --country-neighbors-per-country 3 arch --max-delay=90 | sudo tee /etc/pacman.d/mirrorlist"
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
alias atop="amdgpu_top --smi"
alias ex="extrac_helper"
alias fzi="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
alias hg="history | grep "
alias nvm="sudo nvme smart-log /dev/nvme0"
alias tma="tmux attach-session -t"
alias tmn="tmux new-session -s"
alias tml="tmux list-session"
# Systemd Journal
alias loger="journalctl -p 3 -xb"
alias logf="journalctl -f"
alias logr="sudo journalctl --rotate"
alias logs="journalctl --disk-usage"
alias logv="journalctl --verify"
alias logw="sudo journalctl --vacuum-time=1s"
# Grub
alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"
