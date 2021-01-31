#!/bin/sh
# ----------------------------------------------------------------------
#    Copyright (c) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007
#    NOVELL (All rights reserved)
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of version 2 of the GNU General Public
#    License published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, contact Novell, Inc.
# ----------------------------------------------------------------------
# rc.apparmor.functions by Steve Beattie
#
# NOTE: rc.apparmor initscripts that source this file need to implement
# the following set of functions:
#	aa_action
#	aa_log_action_start
#	aa_log_action_end
#	aa_log_success_msg
#	aa_log_warning_msg
#	aa_log_failure_msg
#	aa_log_skipped_msg
#	aa_log_daemon_msg
#	aa_log_end_msg

# Some nice defines that we use

CONFIG_DIR=/etc/apparmor
MODULE=apparmor
OLD_MODULE=subdomain
if [ -f "${CONFIG_DIR}/${MODULE}.conf" ] ; then
	APPARMOR_CONF="${CONFIG_DIR}/${MODULE}.conf"
elif [ -f "${CONFIG_DIR}/${OLD_MODULE}.conf" ] ; then
	APPARMOR_CONF="${CONFIG_DIR}/${OLD_MODULE}.conf"
elif [ -f "/etc/immunix/subdomain.conf" ] ; then
	aa_log_warning_msg "/etc/immunix/subdomain.conf is deprecated, use ${CONFIG_DIR}/subdomain.conf instead"
	APPARMOR_CONF="/etc/immunix/subdomain.conf"
elif [ -f "/etc/subdomain.conf" ] ; then
	aa_log_warning_msg "/etc/subdomain.conf is deprecated, use ${CONFIG_DIR}/subdomain.conf instead"
	APPARMOR_CONF="/etc/subdomain.conf"
else
	aa_log_warning_msg "Unable to find config file in ${CONFIG_DIR}, installation problem?"
fi

# Read configuration options from /etc/subdomain.conf, default is to
# warn if subdomain won't load.
SUBDOMAIN_MODULE_PANIC="warn"
SUBDOMAIN_ENABLE_OWLSM="no"
APPARMOR_ENABLE_AAEVENTD="no"

if [ -f "${APPARMOR_CONF}" ] ; then
	#parse the conf file to see what we should do
	. "${APPARMOR_CONF}"
fi

PARSER=/usr/sbin/apparmor_parser
UNAME=/usr/bin/uname
MV=/usr/bin/mv
LN=/usr/bin/ln
TOUCH=/usr/bin/touch

PROFILE_DIR=/etc/apparmor.d
ABSTRACTIONS="-I${PROFILE_DIR}"
AA_EV_BIN=/usr/sbin/aa-eventd
AA_EV_PIDFILE=/var/run/aa-eventd.pid
AA_STATUS=/usr/sbin/aa-status
SD_EV_BIN=/usr/sbin/sd-event-dispatch.pl
SD_EV_PIDFILE=/var/run/sd-event-dispatch.init.pid
SD_STATUS=/usr/sbin/subdomain_status
SECURITYFS=/sys/kernel/security
CACHE_DIR=/etc/apparmor.d/cache
INCLUDE_DIR=/etc/apparmor.d/httpd
SYNOSCGI_PROFILE=usr.syno.sbin.synoscgi

SUBDOMAINFS_MOUNTPOINT=$(grep subdomainfs /etc/fstab  | \
	sed -e 's|^[[:space:]]*[^[:space:]]\+[[:space:]]\+\(/[^[:space:]]*\)[[:space:]]\+subdomainfs.*$|\1|' 2> /dev/null)

# keep exit status from parser during profile load.  0 is good, 1 is bad
STATUS=0

# Test if the apparmor "module" is present.
is_apparmor_present() {
	local modules=$1
	shift

	while [ $# -gt 0 ] ; do
		modules="$modules|$1"
		shift
	done

	# check for subdomainfs version of module
	grep -qE "^($modules)[[:space:]]" /proc/modules

	[ $? -ne 0 -a -d /sys/module/apparmor ]

	return $?
}

# This set of patterns to skip needs to be kept in sync with
# AppArmor.pm::isSkippableFile()
# returns 0 if profile should NOT be skipped
# returns 1 on verbose skip
# returns 2 on silent skip
skip_profile() {
	local profile=$1
	if [ "${profile%.rpmnew}" != "${profile}" -o \
	     "${profile%.rpmsave}" != "${profile}" -o \
	     -e "${PROFILE_DIR}/disable/`basename ${profile}`" -o \
	     "${profile%\~}" != "${profile}" ] ; then
		return 1
	fi
	# Silently ignore the dpkg files
	if [ "${profile%.dpkg-new}" != "${profile}" -o \
	     "${profile%.dpkg-old}" != "${profile}" -o \
	     "${profile%.dpkg-dist}" != "${profile}" -o \
	     "${profile%.dpkg-bak}" != "${profile}" ] ; then
		return 2
	fi

	return 0
}

force_complain() {
	local profile=${1}
	return 1
}

apparmor_add_packages_profile() {
	to_reload_profile="$1"
	shift
	for pkg_name in "$@"; do
		package_apparmor_dir="/var/packages/$pkg_name/target/apparmor"
		package_profile_name="pkg_$pkg_name"
		package_include_file="$package_apparmor_dir/httpd/${package_profile_name}.inc"
		package_cache_file=""
		kernel_major="$($UNAME -r | cut -d. -f1)"
		kernel_minor="$($UNAME -r | cut -d. -f2)"

		for file in $package_apparmor_dir/*; do
			base_name=$(basename "$file")
			echo "$base_name" | grep "\-linux\-" > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				continue
			fi
			start_version=$(echo "$base_name" | grep -o '[^-]*$' | cut -d_ -f1)
			end_version=$(echo "$base_name" | grep -o '[^-]*$' | cut -d_ -f2)
			start_version_major=$(echo "$start_version" | cut -d. -f1)
			start_version_minor=$(echo "$start_version" | cut -d. -f2)
			end_version_major=$(echo "$end_version" | cut -d. -f1)
			end_version_minor=$(echo "$end_version" | cut -d. -f2)

			if [ "$kernel_major" -ge "$start_version_major" -a "$kernel_minor" -ge "$start_version_minor" -a \
				"$kernel_major" -le "$end_version_major" -a "$kernel_minor" -le "$end_version_minor" ]; then
				package_cache_file="$file"
				break
			fi
		done

		if [ ! -z "$package_cache_file" -a -s "$package_cache_file" ]; then
			$LN -s "$package_cache_file" "$CACHE_DIR/$package_profile_name"
		fi

		if [ -f "$package_include_file" ]; then
			$LN -sf "$package_include_file" "$INCLUDE_DIR/"
		fi
		$LN -sf "$package_apparmor_dir/$package_profile_name" "$PROFILE_DIR/"
		parse_package_profile "$pkg_name"
		msg="$($PARSER -B -r "$CACHE_DIR/$package_profile_name" 2>&1)"
		if [ $? -ne 0 ]; then
			print_to_console_and_log "$msg"
		fi
	done
	if [ "$INCLUDE_DIR" -nt "$CACHE_DIR/$SYNOSCGI_PROFILE" ]; then
		$TOUCH "$PROFILE_DIR/$SYNOSCGI_PROFILE"
		if [ "$to_reload_profile" = "yes" ]; then
			load_synoscgi_profile
		fi
	fi
}

apparmor_remove_packages_profile() {
	to_reload_profile="$1"
	shift
	for pkg_name in "$@"; do
		package_apparmor_dir="/var/packages/$pkg_name/target/apparmor"
		package_profile_name="pkg_$pkg_name"
		msg="$($PARSER -I "$package_apparmor_dir" --fast-remove -R "$package_apparmor_dir/$package_profile_name" 2>&1)"
		if [ $? -ne 0 ]; then
			print_to_console_and_log "$msg"
		fi
		rm -f "$INCLUDE_DIR/${package_profile_name}.inc"
		rm -f "$CACHE_DIR/$package_profile_name"
		rm -f "$PROFILE_DIR/$package_profile_name"
	done
	if [ "$INCLUDE_DIR" -nt "$CACHE_DIR/$SYNOSCGI_PROFILE" ]; then
		$TOUCH "$PROFILE_DIR/$SYNOSCGI_PROFILE"
		if [ "$to_reload_profile" = "yes" ]; then
			load_synoscgi_profile
		fi
	fi
}

backup_package_cache() {
	local package=$1
	local cache_link="$2"
	local kernel_major kernel_minor cache_name cache

	kernel_major="$($UNAME -r | cut -d. -f1)"
	kernel_minor="$($UNAME -r | cut -d. -f2)"
	cache_name="pkg_${package}-linux-${kernel_major}.${kernel_minor}_${kernel_major}.${kernel_minor}"
	cache="/var/packages/$package/target/apparmor/$cache_name"

	$MV "$cache_link" "$cache"
	$LN -s "$cache" "$cache_link"
}

parse_package_profile() {
	local package=$1
	local parsedFlag="/var/packages/$package/target/apparmor/parsedAppArmorProfile"
	local profile="$PROFILE_DIR/pkg_$package"
	local cache_link="$CACHE_DIR/pkg_$package"

	if [ -e "$parsedFlag" ]; then
		return
	fi

	msg="$($PARSER -W -I "/var/packages/$package/target/apparmor" -r "$profile" 2>&1)"
	if [ $? -eq 0 ]; then
		$TOUCH "$parsedFlag"
		if [ ! -L "$cache_link" ]; then
			# package did not provide cache for this kernel
			backup_package_cache "$package" "$cache_link"
		fi
	else
		print_to_console_and_log "$msg"
		print_to_console_and_log "Failed to re-gen cache for package: $package"
		exit 1
	fi
}

load_synoscgi_profile() {
	if [ -r "$PROFILE_DIR/$SYNOSCGI_PROFILE" ]; then
		msg="$($PARSER -W -r "$PROFILE_DIR/$SYNOSCGI_PROFILE" 2>&1)"
		if [ $? -ne 0 ]; then
			print_to_console_and_log "$msg"
		fi
	else
		msg="$($PARSER -B -r "$CACHE_DIR/$SYNOSCGI_PROFILE" 2>&1)"
		if [ $? -ne 0 ]; then
			print_to_console_and_log "$msg"
		fi
	fi
}

reload_profile() {
	if [ ! -f "${PARSER}" ]; then
		aa_log_failure_msg "AppArmor parser not found"
		aa_log_action_end 1
		return 1
	fi

	if [ ! -d "${CACHE_DIR}" ]; then
		aa_log_failure_msg "Cache directory not found"
		aa_log_action_end 1
		return 1
	fi

	if [ -z "$(ls ${PROFILE_DIR}/)" ]; then
		aa_log_failure_msg "No profiles found"
		aa_log_action_end 1
		return 1
	fi

	#Always load synoscgi first to prevent webapi_hat loading fail
	load_synoscgi_profile

	local profiles=""
	for file in "$PROFILE_DIR"/*; do
		if [ ! -d "$file" -a -r "$file" ]; then
			base_name=$(basename "$file")
			if [ pkg_ = ${base_name:0:4} ]; then
				parse_package_profile "${base_name:4}"
			else
				profiles="$file $profiles"
			fi
		fi
	done
	msg="$($PARSER -W -r $profiles 2>&1)"
	if [ $? -ne 0 ]; then
		print_to_console_and_log "$msg"
	fi

	local caches=""
	for file in "$CACHE_DIR"/*; do
		caches="$file $caches"
	done
	msg="$($PARSER -B -r $caches 2>&1)"
	if [ $? -ne 0 ]; then
		print_to_console_and_log "$msg"
	fi

	error_log "apparmor_reload_profile finish"
	return 0
}

profiles_names_list() {
	# run the parser on all of the apparmor profiles
	if [ ! -f "$PARSER" ]; then
		aa_log_failure_msg "- AppArmor parser not found"
		exit 1
	fi

	if [ ! -d "$PROFILE_DIR" ]; then
		aa_log_failure_msg "- Profile directory not found"
		exit 1
	fi

	for profile in $PROFILE_DIR/*; do
	        if skip_profile "${profile}" && [ -f "${profile}" ] ; then
			LIST_ADD=$($PARSER $ABSTRACTIONS -N "$profile" )
			if [ $? -eq 0 ]; then
				echo "$LIST_ADD"
			fi
		fi
	done
}

failstop_system() {
	level=$(runlevel | cut -d" " -f2)
	if [ $level -ne "1" ] ; then
		aa_log_failure_msg "- could not start AppArmor.  Changing to runlevel 1"
		telinit 1;
		return -1;
	fi
	aa_log_failure_msg "- could not start AppArmor."
	return -1
}

module_panic() {
	# the module failed to load, determine what action should be taken

	case "$SUBDOMAIN_MODULE_PANIC" in
		"warn"|"WARN")
			return 1 ;;
		"panic"|"PANIC") failstop_system
			rc=$?
			return $rc ;;
		*) aa_log_failure_msg "- invalid AppArmor module fail option"
			return -1 ;;
	esac
}

is_apparmor_loaded() {
	if ! is_securityfs_mounted ; then
		mount_securityfs
	fi

	mount_subdomainfs

	if [ -f "${SECURITYFS}/${MODULE}/profiles" ]; then
		SFS_MOUNTPOINT="${SECURITYFS}/${MODULE}"
		return 0
	fi

	if [ -f "${SECURITYFS}/${OLD_MODULE}/profiles" ]; then
		SFS_MOUNTPOINT="${SECURITYFS}/${OLD_MODULE}"
		return 0
	fi

	if [ -f "${SUBDOMAINFS_MOUNTPOINT}/profiles" ]; then
		SFS_MOUNTPOINT=${SUBDOMAINFS_MOUNTPOINT}
		return 0
	fi

	# check for subdomainfs version of module
	is_apparmor_present apparmor subdomain

	return $?
}

is_securityfs_mounted() {
	test -d ${SECURITYFS} -a -d /sys/fs/cgroup/systemd || grep -q securityfs /proc/filesystems && grep -q securityfs /proc/mounts
	return $?
}

mount_securityfs() {
	if grep -q securityfs /proc/filesystems ; then
		aa_action "Mounting securityfs on ${SECURITYFS}" \
				mount -t securityfs securityfs "${SECURITYFS}"
		return $?
	fi
	return 0
}


mount_subdomainfs() {
	# for backwords compatibility
	if grep -q subdomainfs /proc/filesystems && \
	   ! grep -q subdomainfs /proc/mounts && \
	   [ -n "${SUBDOMAINFS_MOUNTPOINT}" ]; then
		aa_action "Mounting subdomainfs on ${SUBDOMAINFS_MOUNTPOINT}" \
				mount "${SUBDOMAINFS_MOUNTPOINT}"
		return $?
	fi
	return 0
}

unmount_subdomainfs() {
	SUBDOMAINFS=$(grep subdomainfs /proc/mounts  | cut -d" " -f2 2> /dev/null)
	if [ -n "${SUBDOMAINFS}" ]; then
		aa_action "Unmounting subdomainfs" umount ${SUBDOMAINFS}
	fi
}

load_module() {
	local rc=0
	if modinfo -F filename apparmor > /dev/null 2>&1 ; then
		MODULE=apparmor
	elif modinfo -F filename ${OLD_MODULE} > /dev/null 2>&1 ; then
		MODULE=${OLD_MODULE}
	fi

	if ! is_apparmor_present apparmor subdomain ; then
		aa_action "Loading AppArmor module" /sbin/modprobe -q $MODULE $1
		rc=$?
		if [ $rc -ne 0 ] ; then
			module_panic
			rc=$?
			if [ $rc -ne 0 ] ; then
				exit $rc
			fi
		fi
	fi

	if ! is_apparmor_loaded ; then
		return 1
	fi

	return $rc
}

apparmor_start() {
	aa_log_daemon_msg "Starting AppArmor"
	if ! is_apparmor_loaded ; then
		load_module
		rc=$?
		if [ $rc -ne 0 ] ; then
			aa_log_end_msg $rc
			return $rc
		fi
	fi

	if [ ! -w "$SFS_MOUNTPOINT/.load" ] ; then
		aa_log_failure_msg "Loading AppArmor profiles - failed, Do you have the correct privileges?"
		aa_log_end_msg 1
		return 1
	fi

	configure_owlsm
	reload_profile
	aa_log_end_msg 0
	return 0
}

remove_profiles() {

	# removing profiles as we directly read from subdomainfs
	# doesn't work, since we are removing entries which screws up
	# our position.  Lets hope there are never enough profiles to
	# overflow the variable
	if ! is_apparmor_loaded ; then
		aa_log_failure_msg "AppArmor module is not loaded"
		return 1
	fi

	if [ ! -w "$SFS_MOUNTPOINT/.remove" ] ; then
		aa_log_failure_msg "Root privileges not available"
		return 1
	fi

	if [ ! -x "${PARSER}" ] ; then
		aa_log_failure_msg "Unable to execute AppArmor parser"
		return 1
	fi

	retval=0
	# We filter child profiles as removing the parent will remove
	# the children
	sed -e "s/ (\(enforce\|complain\))$//" "$SFS_MOUNTPOINT/profiles" | \
	LC_COLLATE=C sort | grep -v // | while read profile ; do
		echo -n "$profile" > "$SFS_MOUNTPOINT/.remove"
		rc=$?
		if [ ${rc} -ne 0 ] ; then 
			retval=${rc}
		fi
	done
	return ${retval}
}

apparmor_stop() {
	aa_log_daemon_msg "Unloading AppArmor profiles "
	remove_profiles
	rc=$?
	aa_log_end_msg $rc
	return $rc
}

apparmor_kill() {
	aa_log_daemon_msg "Unloading AppArmor modules "
	if ! is_apparmor_loaded ; then
		aa_log_failure_msg "AppArmor module is not loaded"
		return 1
	fi

	unmount_subdomainfs
	if is_apparmor_present apparmor ; then
		MODULE=apparmor
	elif is_apparmor_present subdomain ; then
		MODULE=subdomain
	else
		aa_log_failure_msg "AppArmor is builtin"
		return 1
	fi
	/sbin/modprobe -qr $MODULE
	rc=$?
	aa_log_end_msg $rc
	return $rc
}

__apparmor_restart() {
	if [ ! -w "$SFS_MOUNTPOINT/.load" ] ; then
		aa_log_failure_msg "Loading AppArmor profiles - failed, Do you have the correct privileges?"
		return 4
	fi

	aa_log_daemon_msg "Restarting AppArmor.."

	configure_owlsm
	reload_profile
	# Clean out running profiles not associated with the current profile
	# set, excluding the libvirt dynamically generated profiles.
	# Note that we reverse sort the list of profiles to remove to
	# ensure that child profiles (e.g. hats) are removed before the
	# parent. We *do* need to remove the child profile and not rely
	# on removing the parent profile when the profile has had its
	# child profile names changed.
	profiles_names_list | awk '
BEGIN {
  while (getline < "'${SFS_MOUNTPOINT}'/profiles" ) {
    str = sub(/ \((enforce|complain)\)$/, "", $0);
    if (match($0, /^libvirt-[0-9a-f\-]+$/) == 0)
      arr[$str] = $str
  }
}

{ if (length(arr[$0]) > 0) { delete arr[$0] } }

END {
  for (key in arr)
    if (length(arr[key]) > 0) {
      printf("%s\n", arr[key])
    }
}
' | LC_COLLATE=C sort -r | while IFS= read profile ; do
		echo -n "$profile" > "$SFS_MOUNTPOINT/.remove"
	done
	# will not catch all errors, but still better than nothing
	rc=$?
	aa_log_end_msg $rc
	return $rc
}

__apparmor_reload() {
	reload_profile
}

apparmor_restart() {
	if ! is_apparmor_loaded ; then
		apparmor_start
		rc=$?
		return $rc
	fi

	__apparmor_restart
	return $?
}

apparmor_try_restart() {
	if ! is_apparmor_loaded ; then
		return 0
	fi

	__apparmor_restart
	return $?
}

apparmor_reload() {
	if ! is_apparmor_loaded ; then
		apparmor_start
		rc=$?
		return $rc
	fi

	__apparmor_reload
	return $?
}

configure_owlsm () {
	if [ "${SUBDOMAIN_ENABLE_OWLSM}" = "yes" -a -f ${SFS_MOUNTPOINT}/control/owlsm ] ; then
		# Sigh, the "sh -c" is necessary for the SuSE aa_action
		# and it can't be abstracted out as a seperate function, as
		# that breaks under RedHat's action, which needs a
		# binary to invoke.
		aa_action "Enabling OWLSM extension" sh -c "echo -n \"1\" > \"${SFS_MOUNTPOINT}/control/owlsm\""
	elif [ -f "${SFS_MOUNTPOINT}/control/owlsm" ] ; then
		aa_action "Disabling OWLSM extension" sh -c "echo -n \"0\" > \"${SFS_MOUNTPOINT}/control/owlsm\""
	fi
}

apparmor_status () {
	if test -x ${AA_STATUS} ; then
		${AA_STATUS} --verbose
		return $?
	fi
	if test -x ${SD_STATUS} ; then
		${SD_STATUS} --verbose
		return $?
	fi
	if ! is_apparmor_loaded ; then
		echo "AppArmor is not loaded."
		rc=1
	else
		echo "AppArmor is enabled."
		rc=0
	fi
	echo "Install the apparmor-utils package to receive more detailed"
	echo "status information here (or examine ${SFS_MOUNTPOINT} directly)."

	return $rc
}



# ----------------------------------------------------------------------
# rc.apparmor by Steve Beattie
#
# /etc/init.d/apparmor
#
# chkconfig: 2345 01 99
# description: AppArmor rc file. This rc script inserts the apparmor \
# 	       module and runs the parser on the /etc/apparmor.d/ \
#	       directory.
#
### BEGIN INIT INFO
# Provides: apparmor
# Required-Start:
# Required-Stop:
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Short-Description: AppArmor initialization
# Description: AppArmor rc file. This rc script inserts the apparmor
#	module and runs the parser on the /etc/apparmor.d/
#	directory.
### END INIT INFO

aa_action() {
	STRING=$1
	shift
	$*
	rc=$?
	if [ $rc -eq 0 ] ; then
		aa_log_success_msg $"$STRING "
	else
		aa_log_failure_msg $"$STRING "
	fi
	return $rc
}

aa_log_success_msg() {
 	[ -n "$1" ] && echo -n $1
        echo ": done."
}

aa_log_warning_msg() {
 	[ -n "$1" ] && echo -n $1
        echo ": Warning."
}

aa_log_failure_msg() {
 	[ -n "$1" ] && echo -n $1
        echo ": Failed."
}

aa_log_skipped_msg() {
 	[ -n "$1" ] && echo -n $1
        echo ": Skipped."
}

aa_log_action_start() {
    echo -n
}

aa_log_action_end() {
    echo -n
}

aa_log_daemon_msg() {
    echo -e "$@ "
}

aa_log_skipped_msg() {
    echo -e "$@"
}

aa_log_end_msg() {
    v="-v"
    if [ "$1" != '0' ]; then
        rc="-v$1"
    fi
}

print_to_console_and_log() {
	error_log "$1"
}

error_log() {
	echo "AppArmor: $1"
	/usr/bin/logger -p err "AppArmor: $1"
}

usage() {
    echo "Usage: $0 {start|stop|restart|try-restart|reload|force-reload|status|kill|add_packages_profile|remove_packages_profile}"
}

test -x ${PARSER} || exit 0 # by debian policy

## do not run any apparmor command inside container
if cat /proc/1/cgroup | grep docker >/dev/null 2>&1; then
	exit 0
fi

case "$1" in
	start)
		apparmor_start
		aa-status
		rc=$?
		;;
	stop)
		apparmor_stop
		rc=$?
		;;
	restart|force-reload)
		apparmor_restart
		rc=$?
		;;
	try-restart)
		apparmor_try_restart
		rc=$?
		;;
	reload)
		apparmor_reload ${2}
		rc=$?
		;;
	kill)
		apparmor_kill
		rc=$?
		;;
	status)
		apparmor_status
		rc=$?
		;;
	add_packages_profile)
		shift
		apparmor_add_packages_profile "$@"
		rc=$?
		;;
	remove_packages_profile)
		shift
		apparmor_remove_packages_profile "$@"
		rc=$?
		;;
	*)
		usage
		exit 1
		;;
esac
exit $rc
