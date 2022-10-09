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
#substitutions
LDAP_ADMIN_USERNAME="root"
LDAP_SUFFIX=
PKGSRC_PREFIX="/usr/pkg"
PKGSRC_SYSCONFDIR="$PKGSRC_PREFIX/etc"

#executables
DEBUG="_debug"
FIND="find"
MKTEMP="mktemp"
RM="rm -f"
SCP="scp"
SCP_ARGS=
SED="sed"


#functions
#import
_import()
{
	ret=0
	domain="$1"

	#update substitutions
	domain1=${domain##*.}
	domain2=${domain%.$domain1}
	[ -n "$LDAP_SUFFIX" ] || LDAP_SUFFIX="dc=$domain2,dc=$domain1"

	for hostpath in hosts/*/; do
		host="${hostpath#hosts/}"
		host="${host%/}"

		_import_host "$host" "$domain" "$hostpath"	|| ret=2
		return $ret
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
		tmpfile=
		case "$filename" in
			*.in)
				remotefile="/${filename#$prefix}"
				remotefile="${remotefile%.in}"
				tmpfile=$($DEBUG $MKTEMP)
				if [ $? -ne 0 ]; then
					ret=$?
					continue
				fi
				localfile="$tmpfile"
				;;
			*)
				remotefile="/${filename#$prefix}"
				localfile="$filename"
				;;
		esac
		hostname="$host.$domain"
		_info "$hostname: Importing $remotefile"
		$DEBUG $SCP $SCP_ARGS "$hostname:$remotefile" \
			"$localfile"
		if [ $? -ne 0 ]; then
			ret=3
			[ -n "$tmpfile" ] && $RM -- "$tmpfile"
			continue
		fi
		[ -z "$tmpfile" ] && continue

		#apply substitutions
		$DEBUG $SED \
			-e "s/cn=$LDAP_ADMIN_USERNAME/cn=@LDAP_ADMIN_USERNAME@/g" \
			-e "s/$LDAP_SUFFIX/@LDAP_SUFFIX@/g" \
			-e "s/$hostname/@HOSTNAME@/g" \
			-e "s/$domain/@DOMAIN@/g" \
			-e "s,$PKGSRC_SYSCONFDIR,@PKGSRC_SYSCONFDIR," \
			-e "s,$PKGSRC_PREFIX,@PKGSRC_PREFIX," \
			"$tmpfile" > "$filename"
		[ $? -eq 0 ] || ret=4
		$DEBUG $RM -- "$tmpfile"
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
	echo "Usage: $PROGNAME [-u user] domain" 1>&2
	return 1
}


#main
while getopts "O:u:" name; do
	case "$name" in
		O)
			export "${OPTARG%%=*}"="${OPTARG#*=}"
			;;
		u)
			SCP_ARGS="$SCP_ARGS -o User=$OPTARG"
			;;
	esac
done
shift $((OPTIND - 1))
if [ $# -ne 1 ]; then
	_usage
	exit $?
fi

_import "$1"
