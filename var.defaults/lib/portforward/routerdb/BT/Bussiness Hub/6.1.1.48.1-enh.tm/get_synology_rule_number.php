#! /usr/bin/php
<?php
$arr = file($_SERVER["argv"][1]) or exit(-1);
$ret = "";
foreach ($arr as $value) {
        if (preg_match('#<option value="(\d+)">synology</option>#' ,$value , $match))  {
                $ret = $match[1];
                break;
	}
}
unset($value);
echo $ret;
?>
