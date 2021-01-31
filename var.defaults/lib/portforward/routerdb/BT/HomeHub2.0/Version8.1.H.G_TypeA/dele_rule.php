#!/usr/bin/php
<?php
error_reporting(0);
#unassign all application in router. It's may be over max_number in assigned app.
$filename = $_SERVER["argv"][1];
$rn = $_SERVER["argv"][2];
$dev_ip = $_SERVER["argv"][3];
$header = $_SERVER["argv"][4];
$pass = $_SERVER["argv"][5];
$url = $_SERVER["argv"][6];
$dev_name ="";
$synologyNo;
$deletenow;
$App = array();
$appDev = array();
$deleDev = array();
$szCmd;

foreach (file ($filename) as $value) {
	#get DS's Device Name
    if (preg_match("/<option value=\"".$dev_ip."\">(\S+)<\/option>/i" ,$value , $match))  {
        $dev_name = $match[1];
	#Application defined by synology.
	} else if (preg_match("/<tr class=\"\S+\"><td class=\"indence fixedtdwidth fixedtd\">synology<input name=\"delete\d+\" type=\"hidden\" value=\"(\d+)\"/i" ,$value , $match)) {
        $synologyNo = $match[1];
		$App[] = $match[1];
	#All Assigned Application Name.
    } else if (preg_match("/<tr class=\"\S+\"><td class=\"indence fixedtdwidth fixedtd\">.+<input name=\"delete\S+\" type=\"hidden\" value=\"(\d+)\"/i" ,$value , $match)) {
        $App[] = $match[1];
	#All Assigned Application Name.
    } else if (preg_match("/td class=\"indence fixedtdwidth fixedtd\" style=\"position:relative; z-index:1;\">(\S+)<\/td><td class/i" ,$value , $match)) {
        $appDev[] = $match[1];
	#All Assigned Application's Device Name.
    } else if (preg_match("/<\/table>/i" ,$value , $match)) {
		break;
    } else {
    }
}
unset($value);

#scalar(@APP) must the same with scalar(@appDev)
#according to $dev_name, decide which Application need be delete.
$app_count = count($appDev);
for ($i=0; $i<$app_count; $i++) {
	if(preg_match("/^".$dev_name."$/", $appDev[$i]) || preg_match("/^".$synologyNo."$/", $App[$i])) {
		$deleDev[] = $App[$i];
	}
}

$dele_count = count($deleDev);
$deleStr="";
for ($i=0; $i<$dele_count; $i++) {
	$app_count = count($App);
	$deleStr="";
	for ($t = 1 ; $t <= $app_count ; $t++) {
		$deleStr=$deleStr."&delete".$t."=".$App[$t-1];	
		if (preg_match("/".preg_quote($App[$t-1])."/", $deleDev[$i], $m)) {
			$deletenow=$t;
		}
	}
	$data = 'app_name=-".$deleStr."&device_ip=-&form_action=delete".$deletenow."&rn=".$rn."';
	$tuCurl = curl_init();
	curl_setopt($tuCurl, CURLOPT_URL, '".$url."');
	curl_setopt($tuCurl, CURLOPT_POSTFIELDS, $data);
	curl_setopt($tuCurl, CURLOPT_USERPWD, 'admin:'.$pass);
	curl_exec($tuCurl);
	curl_close($tuCurl);
	$tmparray=$App;
	$App=array();
	for($j = 0 ; $j < $app_count ; $j++) {
		if($tmparray[$j] !== $deleDev[$i]) {
			$App[] = $tmparray[$j];
		}
	}
}
exit(0);
?>
