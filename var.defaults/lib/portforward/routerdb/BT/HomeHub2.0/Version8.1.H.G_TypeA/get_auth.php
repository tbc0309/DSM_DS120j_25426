#! /usr/bin/php
<?php
error_reporting(0);
$arr = file($_SERVER["argv"][1]) or exit("can't open file");

foreach ($arr as $v) {
    if (preg_match('/xAuth_SESSION_ID=(\S+);/', $v, $m)) {
        echo $m[1];
        break;
    }
}
echo "";
?>
