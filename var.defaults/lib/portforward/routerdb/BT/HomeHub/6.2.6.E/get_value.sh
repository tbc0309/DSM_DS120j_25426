#!/bin/sh

`curl --digest -u "$1:$2" "$3" > "$4"`

eval $(grep -o "name='2' value='[0-9]\+'" "$4" | cut -d' ' -f2)
echo -n "$value"
