#! /usr/bin/php
<?php
$ret = "0";

foreach (file ($_SERVER["argv"][1]) as $value) {
    if (preg_match('/<input type="hidden" name="entryData".*\#(\d+)">/i' ,$value , $match)) {
        $ret = $match[1];
        break;
    }
}
unset($value);

if ('' === $ret) {
	$ret=0;
}

echo $ret."\n";
?>
