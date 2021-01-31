#! /usr/bin/php
<?php
$arr_file = file($_SERVER["argv"][1]) or exit(-1);
$i = 0;
$ret = "";
for ($i = 0 ; $i < count($arr_file) ; $i++) {
    if (preg_match('/<select name="HOSTAPPS" multiple="multiple" size="10" class="textmono">/' ,$arr_file[$i]))  {
		break;
    }
}
for ( ; $i < count($arr_file) ; $i++) {
    if (preg_match('/<option value="(\d+)"/', $arr_file[$i], $matches))  {
		$ret .= "&HOSTAPPS=".$matches[1];
    }
    if (preg_match("#</select>#", $arr_file[$i])) {
		break;
	}
}
echo $ret;
?>
