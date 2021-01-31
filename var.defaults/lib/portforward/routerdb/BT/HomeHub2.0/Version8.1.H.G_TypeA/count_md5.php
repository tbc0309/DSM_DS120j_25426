#! /usr/bin/php
<?php
$nonce = "";
foreach (file ($_SERVER["argv"][2]) as $value) {
        if (preg_match("/var nonce = \"(.*)\";/i" ,$value , $match))  {
                $nonce = $match[1];
                break;
	}
}

$ha_data = "admin:SpeedTouch:".$_SERVER["argv"][1];
$HA1 = hash("md5", $ha_data);
$HA2 = hash("md5", "GET:/login.lp");
$ha_data= $HA1.":".$nonce.":00000001:xyz:auth:".$HA2;
$HA3 = hash("md5", $ha_data);

echo $HA3;
?>
