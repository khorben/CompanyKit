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
DRYRUN=0
PACKAGE="CompanyKit"
PREFIX="/usr/local"
PROGNAME="sysadmin.sh"
SYSCONFDIR="$PREFIX/etc"
VENDOR="khorben"
VERBOSE=1
#substitutions
COMPANY_NAME="ACME"
COMPANY_NAME_LONG="ACME, Inc."
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

#load local settings
[ -f "$SYSCONFDIR/$VENDOR/$PACKAGE/$PROGNAME.conf" ] &&
	. "$SYSCONFDIR/$VENDOR/$PACKAGE/$PROGNAME.conf"
[ -n "$HOME" -a -f "$HOME/.config/$VENDOR/$PACKAGE/$PROGNAME.conf" ] &&
	. "$HOME/.config/$VENDOR/$PACKAGE/$PROGNAME.conf"


#functions
#sysadmin
_sysadmin()
{
	if [ $# -eq 0 ]; then
		_usage "A command must be provided"
		return $?
	fi
	command="$1"
	shift

	case "$command" in
		apply|import)
			"_sysadmin_$command" "$@"
			return $?
			;;
		*)
			_usage "$command: Command not supported"
			return $?
			;;
	esac
}

_sysadmin_apply()
{
	ret=0
	all=0

	#parse the arguments
	while getopts "anO:qu:v" name; do
		case "$name" in
			a)
				all=1
				;;
			n)
				DRYRUN=1
				;;
			O)
				export "${OPTARG%%=*}"="${OPTARG#*=}"
				;;
			q)
				VERBOSE=0
				;;
			u)
				SCP_ARGS="$SCP_ARGS -o User=$OPTARG"
				;;
			v)
				VERBOSE=$((VERBOSE + 1))
				;;
		esac
	done
	shift $((OPTIND - 1))
	domain="$1"
	shift

	#update substitutions
	domain1=${domain##*.}
	domain2=${domain%.$domain1}
	[ -n "$LDAP_SUFFIX" ] || LDAP_SUFFIX="dc=$domain2,dc=$domain1"

	if [ $all -ne 0 -a $# -eq 0 ]; then
		#apply all hosts
		for hostpath in hosts/*/; do
			host="${hostpath#hosts/}"
			host="${host%/}"

			_apply_host "$host" "$domain" "$hostpath" \
				|| ret=2
		done
	elif [ $all -eq 0 -a $# -ge 1 ]; then
		#apply specific hosts
		for host in $@; do
			host="${host%.$domain}"
			hostpath="hosts/$host/"

			_apply_host "$host" "$domain" "$hostpath" \
				|| ret=2
		done
	else
		_usage
		return $?
	fi

	return $ret
}

_apply_host()
{(
	ret=0
	host="$1"
	domain="$2"
	prefix="$3"

	_info "Applying $host.$domain"
	while read filename; do
		[ -n "$filename" ] || continue
		tmpfile=
		case "$filename" in
			*.in)
				remotefile="${filename#$prefix/files}"
				remotefile="${remotefile%.in}"
				tmpfile=$($DEBUG $MKTEMP)
				if [ $? -ne 0 ]; then
					ret=$?
					continue
				fi
				localfile="$tmpfile"
				;;
			*)
				remotefile="${filename#$prefix/files}"
				localfile="$filename"
				;;
		esac
		hostname="$host.$domain"
		_info "$hostname: Applying $remotefile"

		if [ -n "$tmpfile" ]; then
			#apply substitutions
			$DEBUG $SED \
				-e "s/@@COMPANY_NAME@@/$COMPANY_NAME/g" \
				-e "s/@@COMPANY_NAME_LONG@@/$COMPANY_NAME_LONG/g" \
				-e "s/@@LDAP_ADMIN_USERNAME@@/$LDAP_ADMIN_USERNAME/g" \
				-e "s/@@LDAP_SUFFIX@@/$LDAP_SUFFIX/g" \
				-e "s/@@HOSTNAME@@/$hostname/g" \
				-e "s/@@DOMAIN@@/$domain/g" \
				-e "s,@@PKGSRC_SYSCONFDIR@@,$PKGSRC_SYSCONFDIR," \
				-e "s,@@PKGSRC_PREFIX@@,$PKGSRC_PREFIX," \
				"$filename" > "$tmpfile"
			if [ $? -ne 0 ]; then
				ret=3
				$DEBUG $RM -- "$tmpfile"
				continue
			fi
		fi

		$DEBUG $SCP $SCP_ARGS "$localfile" "$hostname:$remotefile"
		if [ $? -ne 0 ]; then
			ret=4
			[ -n "$tmpfile" ] && $RM -- "$tmpfile"
			continue
		fi
	done << EOF
$([ -d "$prefix/files" ] && $DEBUG $FIND "$prefix/files" -type f)
EOF
	return $ret
)}

_sysadmin_import()
{
	ret=0
	all=0

	#parse the arguments
	while getopts "anO:qu:v" name; do
		case "$name" in
			a)
				all=1
				;;
			n)
				DRYRUN=1
				;;
			O)
				export "${OPTARG%%=*}"="${OPTARG#*=}"
				;;
			q)
				VERBOSE=0
				;;
			u)
				SCP_ARGS="$SCP_ARGS -o User=$OPTARG"
				;;
			v)
				VERBOSE=$((VERBOSE + 1))
				;;
		esac
	done
	shift $((OPTIND - 1))
	domain="$1"
	shift

	#update substitutions
	domain1=${domain##*.}
	domain2=${domain%.$domain1}
	[ -n "$LDAP_SUFFIX" ] || LDAP_SUFFIX="dc=$domain2,dc=$domain1"

	if [ $all -ne 0 -a $# -eq 0 ]; then
		#import all hosts
		for hostpath in hosts/*/; do
			host="${hostpath#hosts/}"
			host="${host%/}"

			_import_host "$host" "$domain" "$hostpath" \
				|| ret=2
		done
	elif [ $all -eq 0 -a $# -ge 1 ]; then
		#import specific hosts
		for host in $@; do
			host="${host%.$domain}"
			hostpath="hosts/$host/"

			_import_host "$host" "$domain" "$hostpath" \
				|| ret=2
		done
	else
		_usage
		return $?
	fi

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
				remotefile="${filename#$prefix/files}"
				remotefile="${remotefile%.in}"
				tmpfile=$($DEBUG $MKTEMP)
				if [ $? -ne 0 ]; then
					ret=$?
					continue
				fi
				localfile="$tmpfile"
				;;
			*)
				remotefile="${filename#$prefix/files}"
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
			-e "s/$COMPANY_NAME_LONG/@@COMPANY_NAME_LONG@@/g" \
			-e "s/$COMPANY_NAME/@@COMPANY_NAME@@/g" \
			-e "s/cn=$LDAP_ADMIN_USERNAME/cn=@@LDAP_ADMIN_USERNAME@@/g" \
			-e "s/$LDAP_SUFFIX/@@LDAP_SUFFIX@@/g" \
			-e "s/$hostname/@@HOSTNAME@@/g" \
			-e "s/$domain/@@DOMAIN@@/g" \
			-e "s,$PKGSRC_SYSCONFDIR,@@PKGSRC_SYSCONFDIR@@," \
			-e "s,$PKGSRC_PREFIX,@@PKGSRC_PREFIX@@," \
			"$tmpfile" > "$filename"
		[ $? -eq 0 ] || ret=4
		$DEBUG $RM -- "$tmpfile"
	done << EOF
$([ -d "$prefix/files" ] && $DEBUG $FIND "$prefix/files" -type f)
EOF
	return $ret
)}


#debug
_debug()
{
	[ $VERBOSE -ge 3 ] && echo "$@" 1>&2
	[ $DRYRUN -ne 0 ] || "$@"
}


#info
_info()
{
	echo "$PROGNAME: $@"
}


#usage
_usage()
{
	[ $# -ge 1 ] && echo "$PROGNAME: $@" 1>&2
	echo "Usage: $PROGNAME apply [-nqv][-u user] domain hostname..." 1>&2
	echo "       $PROGNAME apply -a [-nqv][-u user] domain" 1>&2
	echo "       $PROGNAME import [-nqv][-u user] domain hostname..." 1>&2
	echo "       $PROGNAME import -a [-nqv][-u user] domain" 1>&2
	return 1
}


#main
_sysadmin "$@"
