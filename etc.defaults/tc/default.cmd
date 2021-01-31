#!/bin/sh

######## Begin of wlan0 #######
#reset wlan0
tc qdisc del dev wlan0 root

#add root qdisc
tc qdisc add dev wlan0 root handle 90: htb default 500 r2q 1

#add level 1 class
tc class add dev wlan0 parent 90: classid 90:1 htb rate 4294967kbps ceil 4294967kbps quantum 2048

#add level 2 class
tc class add dev wlan0 parent 90:1 classid 90:500 htb rate 4294967kbps ceil 4294967kbps prio 0 quantum 2048

#add leaf qdisc
tc qdisc add dev wlan0 parent 90:500 handle 500: sfq

#add filter
tc filter add dev wlan0 parent 90: protocol ip handle 500 fw classid 90:500
tc filter add dev wlan0 parent 90: protocol ipv6 handle 500 fw classid 90:500
######## End of wlan0 #######
