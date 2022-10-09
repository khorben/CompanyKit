#!/bin/sh
#$Id$
#Copyright (c) 2022 Pierre Pronchery <khorben@defora.org>
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



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
		_info "$host.$domain: Importing /${filename#$prefix}"
		$DEBUG $SCP "$host.$domain:/${filename#$prefix}" \
			"$filename"
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
