COMMAND_QUEUE=/usr/syno/etc/synonotify.queue

if [ -f $COMMAND_QUEUE ]; then
	chmod u+x $COMMAND_QUEUE || true
	$COMMAND_QUEUE || true
	rm $COMMAND_QUEUE || true
fi