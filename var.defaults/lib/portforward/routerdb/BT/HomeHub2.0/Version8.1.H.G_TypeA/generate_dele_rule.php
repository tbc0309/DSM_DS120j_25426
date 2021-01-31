#! /usr/bin/php
<?php
error_reporting(0);
$arr = file($_SERVER["argv"][1]) or exit("can't open file");
$arrDel = array();
$gameNumber = "";
$result= "";

foreach ($arr as $v) {
    if (preg_match('/<tr class="\S+"><td class="indence w3 fixedtd">synology<input name="delete(\d+)" type="hidden" value="(\d+)"\/>/', $v, $m)) {
        $arrDel[] = $m[2];
        $gameNumber = $m[1];
    } else if (preg_match('/<tr class="\S+"><td class="indence w3 fixedtd">\S+<input name="delete(\d+)" type="hidden" value="(\d+)"\/>/', $v, $m)) {
        $arrDel[] = $m[2];
    }
}
$Tcount = count(ArrDel);
for($i = 1 ; $i <= $Tcount ; $i++) {
	$result = $result . "&delete" . $i . "=" . $arrDel[$i-1];
}

echo $result . "&form_action=delete" . $gameNumber."&rn=" . $_SERVER["argv"][2];

?>
