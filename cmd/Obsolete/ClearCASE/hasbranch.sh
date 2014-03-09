#!/bin/sh

PATH=/usr/atria/bin:/usr/bin
export PATH

usage="`basename $0` branchtypename (on that branch, recursively down from .)"

case $# in
1)	case $1 in
	-h*|--h*|-?) echo $usage; exit 0;;
	esac
	;;
*)	echo $usage; exit 1;;
esac

#cleartool lstype -s -brtype $1  &&
exec cleartool find . -all -branch 'brtype('$1')' -print

#end hasbranch.sh


	
	
	
