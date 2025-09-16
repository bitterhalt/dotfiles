# Get the aliases and functions
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Get exports from .profile (they are in .profile because greetd can't read bash profile)
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
