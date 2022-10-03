#!/bin/sh



#variables
#settings
PROGNAME="import.sh"
VERBOSE=1

#executables
DEBUG="_debug"
FIND="find"
SCP="scp"


#functions
#import
_import()
{
	ret=0
	domain="$1"

	for hostpath in hosts/*/; do
		host="${hostpath#hosts/}"
		host="${host%/}"

		_import_host "$host" "$domain" "$hostpath"	|| ret=2
	done
	return $ret
}

_import_host()
{(
	ret=0
	host="$1"
	domain="$2"
	prefix="$3"

	_info "Importing $host.$domain"
	while read filename; do
		[ -n "$filename" ] || continue
		_info "$host.$domain: Importing ${filename#$prefix}"
		$DEBUG $SCP "$host.$domain:${filename#$prefix}" "$filename"
		if [ $? -ne 0 ]; then
			ret=2
			continue
		fi
	done << EOF
$($DEBUG $FIND "$prefix" -type f)
EOF
	return $ret
	)}


#debug
_debug()
{
	[ $VERBOSE -ge 3 ] && echo "$@" 1>&2
	"$@"
}


#info
_info()
{
	echo "$PROGNAME: $@"
}


#usage
_usage()
{
	echo "Usage: $PROGNAME domain" 1>&2
	return 1
}


#main
if [ $# -ne 1 ]; then
	_usage
	exit $?
fi

_import "$1"
