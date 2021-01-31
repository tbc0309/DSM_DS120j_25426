#! /usr/bin/php
<?php
function printfunc($rule, $str, $maxNum, $fh) {
    for ($i = 0 ; $i < $maxNum ; $i++) {
        if (!array_key_exists($str, $rule[$i])) {
            break;
        }
        fwrite($fh, $str.$i."=".$rule[$i][$str]."&");
    }
}

$stack = array();
$maxNum = $_SERVER["argv"][3];
$tmpStr = "";
foreach (file ($_SERVER["argv"][1]) as $value) {
    $tmpStr = trim($value, "\x00..\x1F");
    $tmpStr = preg_replace("/forward_port_proto=6/", "forward_port_proto=tcp", $tmpStr);
    $tmpStr = preg_replace("/forward_port_proto=17/", "forward_port_proto=udp", $tmpStr);
    $arr = preg_split("/&/", $tmpStr);
    $hash = array();
    for ($i = 0 ; $i < count($arr) ; $i++) {
        $keyValue = preg_split("/\=/", $arr[$i]);
        $hash[$keyValue[0]] = $keyValue[1];
    }
    $stack[] = $hash;
}
unset($value);

for ($i = count($stack) ; $i < $maxNum ; $i++) {
    $stack[] = array(
        "forward_port_desc" => "",
        "forward_port_from_end" => "",
        "forward_port_from_start" => "",
        "forward_port_proto" => "tcp",
        "forward_port_to_end" => "",
        "forward_port_to_ip" => "",
        "forward_port_to_start" => "",
        "protocol" => "6",
        "wan_ip" => "*");
}

$src_ip = preg_split("/\./", $stack[0]["forward_port_to_ip"]);

$fh = fopen($_SERVER["argv"][2], "w");

fwrite($fh, "arc_action=Apply%20Changes&b_port0=&b_port1=&clear_entry_list=all&e_port0=&e_port1=&enable=0&");
printfunc($stack, "enable", $maxNum, $fh);
fwrite($fh, "forward_port=20&");
printfunc($stack, "forward_port_desc", $maxNum, $fh);
printfunc($stack, "forward_port_enable", $maxNum, $fh);
printfunc($stack, "forward_port_from_end", $maxNum, $fh);
printfunc($stack, "forward_port_from_start", $maxNum, $fh);
printfunc($stack, "forward_port_proto", $maxNum, $fh);
printfunc($stack, "forward_port_to_end", $maxNum, $fh);
printfunc($stack, "forward_port_to_ip", $maxNum, $fh);
printfunc($stack, "forward_port_to_start", $maxNum, $fh);
fwrite($fh, "index=0&interface_num=7&interface_num=7&ip0=&ip_count0=&ip_range_count=&lan_b_port0=&lan_b_port1=&lan_e_port0=&lan_e_port1=&lan_ip=0&");
fwrite($fh, "lan_ip_prefix=".$src_ip[0].".".$src_ip[1].".".$src_ip[2]."&lan_port_range_count=&lan_protocol0=&lan_protocol1=&location_page=nat_v.stm&location_page=nat_v.stm&op_mode=apply&port_range_count=&protocol=0&");
printfunc($stack, "protocol", $maxNum, $fh);
fwrite($fh, "reload=0&reload=0&restart_page=&restart_page=&restart_time=0&restart_time=0&service_name=&virtual_server_list=Active%20Worlds&");
printfunc($stack, "wan_ip", $maxNum, $fh);

fclose($fh);

echo $_SERVER["argv"][2];
?>