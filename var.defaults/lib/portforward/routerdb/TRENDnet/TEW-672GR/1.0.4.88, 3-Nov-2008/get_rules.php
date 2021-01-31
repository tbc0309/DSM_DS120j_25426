#! /usr/bin/php
<?php
if (2 != count($_SERVER["argv"])) {
	exit("error input");
}

$ret = 0;
$value = file_get_contents($_SERVER["argv"][1]);

while (preg_match('#<tr id="drawColor(\d+)">(.*)#s' ,$value , $match)) {
    $ret = $match[1];
    $value = $match[2];
    $ret = (int)$ret + 1;
}
unset($value);

echo $ret;
?>
