#!/bin/sh

LOCALE_ROOT="/usr/syno/locale"

if [ ! -f /usr/bin/locale ]; then
	ln $LOCALE_ROOT/locale /usr/bin/locale
fi
if [ ! -f /usr/bin/localedef ]; then
	ln $LOCALE_ROOT/localedef /usr/bin/localedef
fi
if [ ! -d /usr/lib/locale ]; then
	mkdir /usr/lib/locale
fi
if [ ! -f /usr/lib/locale/locale-archive ]; then
	ln $LOCALE_ROOT/locale-archive /usr/lib/locale
fi
