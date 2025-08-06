# Bashrc

[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ ' # Default prompt

export MANPAGER="nvim +Man!"                      # Nvim as manpager
export HISTFILESIZE="5000"                        # History file size
export HISTSIZE="5000"                            # History size
export HISTCONTROL="ignoredups:erasedups"         # No duplicate entries
export HISTIGNORE="ls:ll:exit:clear:rm*:history*" # Ignore commands

set -o vi # vi mode
bind -m vi-command "Control-l: clear-screen"
bind -m vi-insert "Control-l: clear-screen"

shopt -s autocd                  # Change to named directory
shopt -s cdspell                 # Autocorrects cd misspellings
shopt -s checkwinsize            # Checks term size when bash regains control
shopt -s histappend              # Do not overwrite history
shopt -s no_empty_cmd_completion # Do not TAB expand empty lines

bind "set show-all-if-ambiguous on"     # Lis available options in tab-menu
bind "set completion-ignore-case on"    # Ignore upper and lowercase in TAB-completion
bind "set colored-completion-prefix on" # Enable completion coloring
bind "TAB:menu-complete"                # Better tab-completion
bind '"\e[Z": menu-complete-backward'   # Shift-Tab cycle backwards

eval "$(fzf --bash)"                # CTRL-t = fzf select | CTRL-r = fzf history |  ALT-c  = fzf cd
eval "$(starship init bash)"        # Load prompt
eval "$(zoxide init --cmd cd bash)" # Use zoxide to cd

# Extract helper
function ex {
  if [ -z "$1" ]; then
    echo "Usage: ex <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
  else
    for n in "$@"; do
      if [ -f "$n" ]; then
        case "${n%,}" in
        *.cbt | *.tar.bz2 | *.tar.gz | *.tar.xz | *.tbz2 | *.tgz | *.txz | *.tar)
          tar xvf "$n"
          ;;
        *.lzma) unlzma ./"$n" ;;
        *.bz2) bunzip2 ./"$n" ;;
        *.cbr | *.rar) unrar x -ad ./"$n" ;;
        *.gz) gunzip ./"$n" ;;
        *.cbz | *.epub | *.zip) unzip ./"$n" ;;
        *.z) uncompress ./"$n" ;;
        *.7z | *.arj | *.cab | *.cb7 | *.chm | *.deb | *.dmg | *.iso | *.lzh | *.msi | *.pkg | *.rpm | *.udf | *.wim | *.xar)
          7z x ./"$n"
          ;;
        *.xz) unxz ./"$n" ;;
        *.exe) cabextract ./"$n" ;;
        *.cpio) cpio -id <./"$n" ;;
        *.cba | *.ace) unace x ./"$n" ;;
        *)
          echo "ex: '$n' - unknown archive method"
          return 1
          ;;
        esac
      else
        echo "'$n' - file does not exist"
        return 1
      fi
    done
  fi
}

# Aliases
alias ..="cd .."
alias cp="cp -iv"
alias df="df -h"
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
# Dir / eza
alias la="eza -a --group-directories-first --color=always"
alias ll="eza -l --group-directories-first --color=always"
alias ls="eza -al --group-directories-first --color=always"
# Trash-cli
alias tp="trash-put"
alias tpe="trash-empty"
alias tpr="trash-restore"
# Random
alias hg="history | grep "
alias nvm="sudo nvme smart-log /dev/nvme0"
# Systemd Journal
alias loger="journalctl -p 3 -xb"
alias logf="journalctl -f"
alias logr="sudo journalctl --rotate"
alias logs="journalctl --disk-usage"
alias logv="journalctl --verify"
alias logw="sudo journalctl --vacuum-time=1s"
