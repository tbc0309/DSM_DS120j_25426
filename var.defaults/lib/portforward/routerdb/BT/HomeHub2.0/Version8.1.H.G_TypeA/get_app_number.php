#! /usr/bin/php
<?php
error_reporting(0);
$arr = file($_SERVER["argv"][1]) or exit("can't open file");

foreach ($arr as $v) {
    if (preg_match('/<tr class="\S+"><td class="indence w3 fixedtd">synology<input name="(\S+)" type="hidden" value="(\d+)"\/>/', $v, $m)) {
        echo $m[2];
        break;
    }
}
echo "";
?>
