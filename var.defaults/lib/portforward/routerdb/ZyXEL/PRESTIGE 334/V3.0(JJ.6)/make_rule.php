#! /usr/bin/php
<?php
error_reporting(0);
$rule_num = $_SERVER["argv"][1] + 1;
$out_string = "";
$count = 1;

$arr = file($_SERVER["argv"][2]) or exit(-1);
foreach ($arr as $v) {
    $out_string .= preg_replace("/SUAServerAddr%3F=/","SUAServerAddr%3F".$count."=", trim($v));
    $count++;
}

for ($rule_num;$rule_num<11;$rule_num++) {
    $out_string = $out_string."SUAName=&SUAPortNo=0&SUAPortNoEnd=0&SUAServerAddr%3F".($rule_num+1)."=0.0.0.0&";
}

echo $out_string;
?>
