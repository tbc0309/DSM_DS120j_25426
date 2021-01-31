#! /usr/bin/php
<?php
error_reporting(0);
file_put_contents($_SERVER["argv"][1], $_SERVER["argv"][2]."\n", FILE_APPEND | LOCK_EX);
?>
