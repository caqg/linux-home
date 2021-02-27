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

prepend_to_PATH_if_absent () {
	case $# in 
	1)	dir="$1"
		;;
	*)	echo >&2 "prepend_to_PATH_if_absent takes one arg., a directory"
		exit 1
		;; 
	esac
	if [ -d "$dir" ]; then
		case "$PATH" in
		"$dir":* | *:"$dir" | *:"$dir":*)
			;;
		*)
			export PATH="$dir:$PATH" ;;
		esac
	else
		echo >&2 "$dir" is not a directory
		exit 1
	fi
}

# add personal prefixes to the PATH, but only if they are not already there.
prepend_to_PATH_if_absent $HOME/bin
prepend_to_PATH_if_absent $HOME/cmd

. $HOME/.bash_env

[ "${INSIDE_EMACS}" ] &&
    . $HOME/.bash_under_emacs


eval $( ~/cmd/path | /usr/bin/awk '
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
			newpath="\""array[0]"\""
#			print i, newpath
		} else {
			newpath=newpath":\""array[i]"\""
#			print i, newpath
		}
	}
	printf "export PATH=%s\n", newpath
}
' )

# User specific aliases and functions

#end .bashrc
