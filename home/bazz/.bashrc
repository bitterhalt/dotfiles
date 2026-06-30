# Bashrc

[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ ' # Default prompt

export HISTSIZE="50000"                                        # History size
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
st* | alacritty | foot* | xterm* | rxvt* | kitty | kterm | gnome*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "${PWD/#$HOME/\~}"'
  ;;
tmux* | screen*)
  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s\007" "tmux: ${PWD/#$HOME/\~}"'
  ;;
esac

# Load aliases
source "$HOME/.config/shell/aliases"
