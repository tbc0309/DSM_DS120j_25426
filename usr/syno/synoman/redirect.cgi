#!/bin/sh

echo -e "Content-Type: text/html\n"
[ -n "$1" ] && echo "<html><script type=\"text/javascript\">var URL=location.protocol+\"//\"+location.hostname+\":$1/\";location.replace(URL);</script></html>"
