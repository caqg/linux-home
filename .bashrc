# .bashrc

# Source global definitions
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

unalias -a

export LC_TIME="en_GB.UTF-8"

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

if [ "${INSIDE_EMACS}" ]; then
    . $HOME/.bash_under_emacs
fi

[ "$PS1" ] && {
    . ~/.bash_interactive
}

eval $( ~/cmd/path |
    /usr/bin/awk '
BEGIN { n = 0; }
{
	if ($0 in map) {
#		printf "REPEATED: %s\n", $0
	} else {
#		printf "NEW     :  %d\t%s\n", n, $0
		array[n] = $0
		map[$0] = n
		n += 1
	}
}
END {
	for (i = 0; i < n; ++i) {
		if (i == 0) {
			newpath=array[0]
#			print i, newpath
		} else {
			newpath=newpath":"array[i]
#			print i, newpath
		}
	}
	printf "export PATH=%s\n", newpath
}
' )

# User specific aliases and functions

#end .bashrc
