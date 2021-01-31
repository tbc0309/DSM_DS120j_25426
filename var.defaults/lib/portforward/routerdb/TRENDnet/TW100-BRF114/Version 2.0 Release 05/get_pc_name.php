#! /usr/bin/php
<?php
error_reporting(0);
$value = file_get_contents($_SERVER["argv"][1]);
$src_ip = $_SERVER["argv"][2];
$content = "";

if (preg_match('/<select name="vs_pc_list".*?>(.*)</select>/is' ,$value , $match)) {
    $content = $match[1];
    break;
}

$arr_opt = preg_split ('/<option>/', $content);
foreach ($arr_opt as $value) {
    $target = preg_split ('#</option>#', $content)[0];
    if (false !== strpos($target, "(".$src_ip.")") {
        echo $target
		exit(0);
	}
}
?>
