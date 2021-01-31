#! /usr/bin/php
<?php
$output = exec("/usr/syno/bin/synoportforward --jobnum 'PF add port'");
$rule_num = "0";

if (preg_match("/num=(.*)$/" ,$output , $match)) {
	$rule_num = $match[1];
}
#append rules
for($i=1; $i<=$rule_num; $i++) {
	if($i > 1) {
		echo("+");
	}
    echo("Name%3D%22\${comment $i}%22%2CPortRange%3D%22\${rport $i}%22%2CLocalIP%3D%22\${src_ip $i}%22%2CLocalPort%3D%22\${sport $i}%22%2CProtocol%3D%22\${proto $i}%22");
}
?>
