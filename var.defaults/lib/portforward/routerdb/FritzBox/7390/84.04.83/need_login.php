#! /usr/bin/php
<?php
if (false !== strpos($_SERVER["argv"][1], "0000000000000000")) {
    #user has setup password
	echo "1";
} else {
    echo "0";
}
?>
