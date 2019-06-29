# .bashrc

if [[ "$-" = *i* ]]; then
	[ -f /etc/bash.bashrc ] && . /etc/bash.bashrc
	unalias -a

	. $HOME/.bash_interactive

	[ "$TERM" = "screen" ] && set -o vi
	set -o ignoreeof
	set -o pipefail

	shopt -s cmdhist
	shopt -s cdspell
	shopt -s checkwinsize
	shopt -s direxpand
	shopt -s globstar
	shopt -s globstar
	shopt -s histappend
	shopt -s histreedit
	shopt -s histverify
	shopt -s lithist
	shopt -s progcomp
fi

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

. $HOME/.bash_env

[ "${INSIDE_EMACS}" ] &&
    . $HOME/.bash_under_emacs


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
