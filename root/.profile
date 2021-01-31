
#This fixes the backspace when telnetting in.
#if [ "$TERM" != "linux" ]; then
#        stty erase
#fi

HOME=/root
export HOME

#only for console (ssh/telnet works w/o resize)
isTTY=$(ps | grep $$ | grep tty)
#only for bash (bash needs to resize and can support these commands)
isBash=$(echo $BASH_VERSION)
#only for interactive (not necessary for "su -")
isInteractive=$(echo $- | grep i)

if [ -n "$isTTY" -a -n "$isBash" -a -n "$isInteractive" ]; then
	shopt -s checkwinsize
	checksize='echo -en "\E7 \E[r \E[999;999H \E[6n"; read -sdR CURPOS;CURPOS=${CURPOS#*[}; IFS="?; \t\n"; read lines columns <<< "$(echo $CURPOS)"; unset IFS'
	eval $checksize
	# columns is 1 in Procomm ANSI-BBS
	if [ 1 != "$columns" ]; then
		export_stty='export COLUMNS=$columns; export LINES=$lines; stty columns $columns; stty rows $lines'
		alias resize="$checksize; columns=\$((\$columns - 1)); $export_stty"
		eval "$checksize; columns=$(($columns - 1)); $export_stty"

		alias vim='function _vim(){ eval resize; TERM=xterm vi $@; }; _vim'
	else
		alias vim='TERM=xterm vi $@'
	fi
	alias vi='vim'
	alias ps='COLUMNS=1024 ps'
fi

