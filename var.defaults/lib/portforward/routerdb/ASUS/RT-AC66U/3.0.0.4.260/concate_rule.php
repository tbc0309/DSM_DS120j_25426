#! /usr/bin/php
<?php
$output = exec("/usr/syno/bin/synoportforward --jobnum 'PF add port'");
$rule_num = "0";

if (preg_match("/num=(.*)$/" ,$output , $match)) {
	$rule_num = $match[1];
}
$str = "&vts_rulelist=";
#append rules
for($i=1; $i<=$rule_num; $i++) {
    $str .= "%3C\${comment $i}%3E\${rport $i}%3E\${src_ip}%3E%3E\${proto $i}";
}
echo $str;
?>
