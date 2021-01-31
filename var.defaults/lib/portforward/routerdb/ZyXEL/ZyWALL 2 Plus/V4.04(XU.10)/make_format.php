#!/usr/bin/php
<?php
$i = 0;
$j = 0;
$ruleCountStr = exec("/usr/syno/bin/synoportforward --jobnum 'PF add port'");
$ruleCount = 0;
$str = '';

if (preg_match("/num=(.*)$/" ,$ruleCountStr , $match)) {
    $ruleCount = $match[1];
}

$str .= "Rule_per_page=10&SUADefault_1=0&SUADefault_2=0&SUADefault_3=0&SUADefault_4=0&sysSubmit=Apply&";

#Page1

if ("Page1" === $_SERVER["argv"][1]) {
	if ($ruleCount > 10) {$ruleCount = 10;}
	for ($i=1; $i<=$ruleCount; $i++) {
		$str .= "SUAName?".$i."=\${comment ".$i."}&".
                "SUAPortNo?".$i."=\${rport_start ".$i."}&SUAPortNoEnd?".$i."=\${rport_end ".$i."}&".
                "SUAServerAddr_1?".$i."=\${src_ip1}&SUAServerAddr_2?".$i."=\${src_ip2}&SUAServerAddr_3?".$i."=\${src_ip3}&SUAServerAddr_4?".$i."=\${src_ip4}&".
                "SUA_forwardPort?".$i."=\${sport_start ".$i."}&SUA_forwardPortEnd?".$i."=\${sport_end ".$i."}&".
                "SUA_Active?".$i."=?".$i."&";
	}
	for ($i=$ruleCount+1; $i<=10; $i++) {
		$str .= "SUAName?".$i."=&SUAPortNo?".$i."=0&SUAPortNoEnd?".$i."=0&SUAServerAddr_1?".$i."=0&".
                "SUAServerAddr_2?".$i."=0&SUAServerAddr_3?".$i."=0&SUAServerAddr_4?".$i."=0&SUA_forwardPort?".$i."=0&".
                "SUA_forwardPortEnd?".$i."=0&";
	}
	$str .= "NAT_GotoPage=00000000";
}

#Page2

if ("Page2" === $_SERVER["argv"][1]) {
	if ($ruleCount <= 10) {
		for ($i=1; $i<=9; $i++) {
			$str .= "SUAName?".$i."=&SUAPortNo?".$i."=0&SUAPortNoEnd?".$i."=0&SUAServerAddr_1?".$i."=0&".
                    "SUAServerAddr_2?".$i."=0&SUAServerAddr_3?".$i."=0&SUAServerAddr_4?".$i."=0&SUA_forwardPort?".$i."=0&".
                    "SUA_forwardPortEnd?".$i."=0&";
		}
	} else {
		$ruleCount -= 10;
		for ($i=1,$j=11; $i<=$ruleCount; $i++,$j++) {
			$str .= "SUAName?".$i."=\${comment ".$j."}&".
                    "SUAPortNo?".$i."=\${rport_start ".$j."}&SUAPortNoEnd?".$i."=\${rport_end ".$j."}&".
                    "SUAServerAddr_1?".$i."=\${src_ip1}&SUAServerAddr_2?".$i."=\${src_ip2}&SUAServerAddr_3?".$i."=\${src_ip3}&SUAServerAddr_4?".$i."=\${src_ip4}&".
                    "SUA_forwardPort?".$i."=\${sport_start ".$j."}&SUA_forwardPortEnd?".$i."=\${sport_end ".$j."}&".
                    "SUA_Active?".$i."=?".$i."&";
		}
		for ($i=$ruleCount+1; $i<=9; $i++) {
			$str .= "SUAName?".$i."=&SUAPortNo?".$i."=0&SUAPortNoEnd?".$i."=0&SUAServerAddr_1?".$i."=0&".
                    "SUAServerAddr_2?".$i."=0&SUAServerAddr_3?".$i."=0&SUAServerAddr_4?".$i."=0&SUA_forwardPort?".$i."=0&".
                    "SUA_forwardPortEnd?".$i."=0&";
		}
	}
	$str .= "NAT_GotoPage=00000001";
}

echo $str;
?>
