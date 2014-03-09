# .bashrc

# Source global definitions
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

unalias -a

# Add personal prefixes to the PATH, but only if they are not already there.
[ -d $HOME/bin ] &&
case "$PATH" in
$HOME/bin:* | *:$HOME/bin | *:$HOME/bin:*)
    ;;
*)
    PATH=$HOME/bin:$PATH;; 
esac

[ -d $HOME/cmd ] &&
case "$PATH" in
$HOME/cmd:* | *:$HOME/cmd | *:$HOME/cmd:*)
    ;;
*)
    PATH=$HOME/cmd:$PATH;;
esac

export PATH

if [ "${ALREADY_IN:-0}" = 0 ]; then
    . $HOME/.bash_env
    export ALREADY_IN=1;
fi

if [ "${EMACS:-nil}" = t ]; then
    . $HOME/.bash_under_emacs
fi

[ "$PS1" ] && {
    . ~/.bash_interactive
}


# User specific aliases and functions
