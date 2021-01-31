#!/usr/bin/php
<?php
error_reporting(0);

function str2KeyValue($str) {
    $rAry=array();
    foreach(split("&",$str) as $s) {
        $tAry=split("=",$s);
        $rAry[$tAry[0]]=$tAry[1];
    }
    return $rAry;
}

function makeRule($arr, $str) {
    $tmp="";
    for($i=0;$i<count($arr);$i++) {
        if(!array_key_exists($str , $arr[$i])) {
            break;
        } else {
            $j=$i+1;
            $tmp.=$str.$j."=".$arr[$i][$str]."&";
        }
    }
    return $tmp;
}

#ARGV[1]:input file ARGV[2]:rn ARGV[3]:output file
$filename=$_SERVER["argv"][3];
$rn=$_SERVER["argv"][2];
$attr=array();

$arr=file($_SERVER["argv"][1]) or exit("can't open $ARGV[0]\n");

#parse /tmp/routertemp into array
foreach ($arr as $v) {
    $tmp=trim($v);
    $attr[]=str2KeyValue($tmp);
}

#should follow this order
$rStr="rn=$rn&form_action=add&uniquecount=".count($attr)."&app_path=&origin_name=synology&app_name=synology&clone_enable=on&add_rangesel=TCP&add_triggersel=6&";
$rStr.=makeRule($attr, "hid_inbound_end_showrow");
$rStr.=makeRule($attr, "hid_inbound_showrow");
$rStr.=makeRule($attr, "hid_outbound_end_showrow");
$rStr.=makeRule($attr, "hid_outbound_showrow");
$rStr.=makeRule($attr, "hid_rangesel_showrow");
$rStr.=makeRule($attr, "hid_triggerport_showrow");
$rStr.=makeRule($attr, "hid_triggersel_showrow");

$i = file_put_contents($filename,$rStr);

echo $filename;
?>
