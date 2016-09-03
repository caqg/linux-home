# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs
umask 22

# INFOPATH
export INFOPATH=/usr/local/share/info:/usr/share/info
unset MANPATH

#end .bash_profile
