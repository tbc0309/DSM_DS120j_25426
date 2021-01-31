#! /usr/bin/php
<?php
$output = exec("/usr/syno/bin/synoportforward --jobnum 'PF add port'");
$rule_num = "0";

if (preg_match("/num=(.*)$/" ,$output , $match)) {
	$rule_num = $match[1];
}
# rules except comment
echo("fwi=");
for($i=1; $i<=$rule_num; $i++) {
	echo("1-x-\${rport_start $i}-\${rport_end $i}-\${proto $i}-\${src_ip4 $i}-\${sport_start $i}-\${sport_end $i}%20");
}

echo("&");
# comment
echo("fwi_des=");
for($i=1; $i<=$rule_num; $i++) {
	echo("\${comment $i}%20");
}
?>
