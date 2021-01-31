#! /usr/bin/php
<?php
$output = exec("/usr/syno/bin/synoportforward --jobnum 'PF add port'");
$rule_num = "0";

if (preg_match("/num=(.*)$/" ,$output , $match)) {
	$rule_num = $match[1];
}
#append rules
for($i=1; $i<=$rule_num; $i++) {
    echo("1%3C\${proto $i}%3C%3C\${rport $i}%3C%3C\${src_ip $i}%3C\${comment $i}%3E");
}
?>
