#! /usr/bin/php
<?php
if (4 != count($_SERVER["argv"])) {
	exit("error input");
}

if ("UDP" === $_SERVER["argv"][1]) {
	echo "TCPPorts=&UDPPorts=".$_SERVER["argv"][2]."-".$_SERVER["argv"][3];
} else if ("TCP" === $_SERVER["argv"][1]) {
	echo "TCPPorts=".$_SERVER["argv"][2]."-".$_SERVER["argv"][3]."&UDPPorts=";
} else {
	echo "TCPPorts=".$_SERVER["argv"][2]."-".$_SERVER["argv"][3]."&UDPPorts=".$_SERVER["argv"][2]."-".$_SERVER["argv"][3];
}
?>
