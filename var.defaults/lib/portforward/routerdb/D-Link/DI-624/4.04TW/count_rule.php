#! /usr/bin/php
<?php
$rule = "0";
foreach (file ($_SERVER["argv"][1]) as $value) {
    if (preg_match("/rDat\[(\d+?)\]/" ,$value , $match))  {
	    $rule = $match[1];
        break;
	}
}
unset($value);
exit((int)$rule);
?>
