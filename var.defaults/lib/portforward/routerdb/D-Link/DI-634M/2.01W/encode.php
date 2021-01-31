#! /usr/bin/php
<?php
error_reporting(0);

# operations for base 64
#	$base64_string = convertToBase64(@byte_array);
#	@byte_array = convertFromBase64($base64_string);
{#{{{
	$b64 = ".ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
	function b64_char_to_6($myChar) {
		$i = strrpos($b64, $myChar);
		return (false === $i)? 0 : $i;
	}
	function convertToBase64($arr) {
        while (0 != (count($arr)%3)) { array_push($arr, "0"); } # padding "0"
		$str = '';
		for ($i = 0 ; $i < count($arr) ; $i += 3) {
			$x = ($arr[$i] << 16) | ($arr[$i+1] << 8) | $arr[$i+2];
			$str = $str.substr($b64, ($x >> 18) & 0x3f, 1);
			$str = $str.substr($b64, ($x >> 12) & 0x3f, 1);
			$str = $str.substr($b64, ($x >> 6)  & 0x3f, 1);
			$str = $str.substr($b64, ($x)       & 0x3f, 1);
		}
		return $str;
	}
	function convertFromBase64($str) {
        while (0 != (strlen($str)%4)) { $str = $str."."; } # padding "."
        $char_buff = preg_split('//', $str, -1, PREG_SPLIT_NO_EMPTY);
        $dst = array();
        for ($i = 0; $i < count($char_buff); $i += 4) {
            $cc = (b64_char_to_6($char_buff[i]) << 18) |
                    (b64_char_to_6($char_buff[i+1]) << 12) |
                	(b64_char_to_6($char_buff[i+2]) << 6) |
                	(b64_char_to_6($char_buff[i+3]));
            array_push($dst, ($cc >> 16) & 0xff, ($cc >> 8) & 0xff, ($cc) & 0xff);
        }
        return $dst;
	}
}#}}}

# generate encoded authentication string for login
#	$encode_string = login($file_data_page, "admin:password");
function login($file_data_page, $account) {
    list($user, $pass) = split(":", $account, 2);

    $arr = file($file_data_page) or exit(-1);
    foreach ($arr as $v) {
        if (preg_match('/data="(.*)"/i', $v, $m)) {
            $data = $m[1]; # data="smns5P.."
        }
    }

    $a = convertFromBase64( $data );
    $shex = '';
    for ($i=0 ; $i<4 ; $i++) {
        $shex = $shex.sprintf("%02X",$a[$i]);
    }

    $str = $shex . $pass;
    while (63 > strlen($str)) { $str .= '0'; }
	$str .= ($user === 'user') ? 'U' : '0';

	$hash = hash('md5', $str);
	$saltHash = $shex . $hash;

	$b = array();
    for ($j=0 ; $j<strlen($saltHash) ; $j+=2) {
        array_push($dst, hexdec(substr($b, $j, 2)));
    }

	return convertToBase64( $b );
}


# operations for byte array
#	@byte_array = putStr("hello", 10); # return (104, 101, 108, 108, 111, 0, 0, 0, 0, 0);
#	@byte_array = putIP("192.168.1.1); # return (192, 168, 1, 1);
#	@byte_array = putUInt(256, 2);     # return (1, 0);
function putStr($str, $cnt)  {
    $a = preg_split('//', $str, -1, PREG_SPLIT_NO_EMPTY);
    for ($i=0;$i<count($a);$i++) { $a[$i] = ord($a[$i]); }
    for ($j=count($a);$j<$cnt;$j++) { $a[$j] = 0; }

    return $a;
}

function putIP($ip)  { return preg_split('/\./', $ip, -1); }

function putUInt($value, $digi) {
    $a = array();
    $cnt = 1;
    while ($cnt <= $digi) {
        array_push($a, $value >> ($digi-$cnt)*8 & 0xff);
        $cnt++;
    }
    return $a;
}

function push_arr(&$taget_arr, $data_arr) {
    for ($i=0 ; $i<count($data_arr) ; $i++) { array_push($taget_arr, $data_arr[i]); }
}

# append port forwarding parameters to byte array
#	*_append_rule(\@rule, %params);		# append a rule setting to @rule
#	*_fill_rest_by_empty(\@rule, $num) 	# fill all rule in the table. if table has 32 rule,
#						# it will append 32 - $num rules;
{#{{{
	# default parameters
	$alg_assoc = array_fill(1, 31, 0);
	$filter    = array(65, 108, 108, 111, 119,  32, 65, 108, 108, 0, 0, 0, 0, 0, 0, 0, 0);
	$schedule  = array(65, 108, 119,  97, 121, 115,  0,   0,   0, 0, 0, 0, 0, 0, 0, 0, 0);
	$enable    = 1;
    $used      = 1;

	function vs_append_rule(&$rule, $data) {
        push_arr($rule, $alg_assoc);
        push_arr($rule, array($enable));
        push_arr($rule, putStr($data['c'], 16));
        push_arr($rule, $filter);
        push_arr($rule, putIP($data['ip']));
        push_arr($rule, putUInt($data['sp'], 2));
        push_arr($rule, putUInt($data['p'], 1));
        push_arr($rule, putUInt($data['rp'], 2));
        push_arr($rule, $schedule);
        push_arr($rule, array($used));
		return 1;
	}

	function vs_fill_rest_by_empty(&$rule, $num) {
        $cnt = 32-$num;
        for ($i=0 ; $i<$cnt ; $i++) {
            push_arr($rule, $alg_assoc);
            push_arr($rule, array_fill(0, 17, 0));
            push_arr($rule, $filter);
            push_arr($rule, array_fill(0, 9, 0));
            push_arr($rule, $schedule);
            push_arr($rule, array(0));
        }
        return $cnt;
	}

	function pf_append_rule(&$rule, $data) {
        push_arr($rule, array($enable));
        push_arr($rule, putStr($data['c'], 41));
        push_arr($rule, putIP($data['ip']));
        push_arr($rule, $filter);
        push_arr($rule, $schedule);

        if ('0' === $data['p'] or '6' === $data['p']) {
			push_arr($rule, putStr($data['sp'], 61));
		} else {
			push_arr($rule, array_fill(0, 61, 0));
		}
        if ('0' === $data['p'] or '17' === $data['p']) {
			push_arr($rule, putStr($data['sp'], 61));
		} else {
			push_arr($rule, array_fill(0, 61, 0));
		}

        push_arr($rule, array($used));
		return 1;
	}

	function pf_fill_rest_by_empty(&$rule, $data) {
        $cnt = 16-$num;
        for ($i=0 ; $i<$cnt ; $i++) {
            push_arr($rule, array_fill(0, 46, 0));
            push_arr($rule, $filter);
            push_arr($rule, $schedule);
    		push_arr($rule, array_fill(0, 123, 0));
        }
        return $cnt;
	}
}#}}}

function string_to_hash($str) {
    $a = explode ('&', $str, -1);
    $b = array();
    foreach ($a as $v) {
        $tmp_arr = explode ('=', $v, 2);
        if (count($tmp_arr) != 2) continue;
        $b[$tmp_arr[0]] = $tmp_arr[1];
    }
    return $b;
}

########################### main ###############################
$action = $_SERVER["argv"][1];
if ("login" === $action) {
	echo login($_SERVER["argv"][2], $_SERVER["argv"][3]);
	exit(0);
} elsif ( "vs" !== $action and "pf" !== $action) {
	exit(-1);
}

$param_file = $_SERVER["argv"][2];
$data_file = $_SERVER["argv"][3];

# read table data from router
$data = file_get_contents($data_file);
if (false === $data) {
    exit(-1);
}
list($dummy, $data) = explode ('=' , $data, 2);
$data = trim($data);
$datalen = strlen($data);

if ('"' === substr($data, 0, 1) && '"' === substr($data, $datalen-1, 1) ) {
    $data_arr[1] = substr($data, 1, $datalen-2);
}

# get ip and mask
$head = convertFromBase64(substr($data, 0, 12));
array_pop($head);

# append rules
$rule = array();
$c = 0;

$arr = file($param_file) or exit(-1);
foreach ($arr as $v) {
    $tmp = trim($v);
    if ('vs' === $action) {
		$c += vs_append_rule($rule, string_to_hash($v));
		if ($c == 32) break;
	} elsif ('pf' === $action) {
		$c += pf_append_rule($rule, string_to_hash($v));
		if ($c == 16) break;
	}
}

if ('vs' === $action) vs_fill_rest_by_empty($head, $c);
if ('pf' === $action) pf_fill_rest_by_empty($head, $c);

$rest = array();
if ('pf' === $action) {
	$rest = convertFromBase64(substr($data, 4340, 4));
	array_shift($rest);
}

$tmp_arr = array();
push_arr($tmp_arr, $head);
push_arr($tmp_arr, $rule);
push_arr($tmp_arr, $rest);
$str = convertToBase64($tmp_arr);
substr_replace($data, $str, 0, strlen($str));

$fh = fopen($param_file.".out", 'w') or die(-1);;
fwrite($fh, 'data='.$data);
fclose($fh);

print $param_file.".out";


?>
