#!/bin/sh

PKGS_READY_CONF="/etc/init/syno-packages-ready.override"

main() {
    local start_on="start on stopped 3rdparty-services"
    local to_upgrade_pkg=($(/usr/syno/etc/rc.sysv/syno-pkg-upgrade.sh get_queue))
    local installed_pkgs=$(/usr/syno/bin/synopkg list --name)

    while read pkg; do
        [[ " ${to_upgrade_pkg[*]} " == *" $pkg "* ]] && continue
        [[ "HighAvailability" == "$pkg" ]] && continue # ha controls whole bootup procedure, so it is started before this script run
        /usr/syno/sbin/synoservice --is-enabled "pkgctl-$pkg"
        if [[ 1 == $? ]]; then
            start_on+=" and (started \"pkgctl-$pkg\" or stopped \"pkgctl-$pkg\")"
        fi
    done <<< "$installed_pkgs"

    /bin/echo $start_on > $PKGS_READY_CONF
}


main
