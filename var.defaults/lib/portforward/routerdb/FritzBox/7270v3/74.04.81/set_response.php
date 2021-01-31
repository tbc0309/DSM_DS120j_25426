#! /usr/bin/php
<?php
$challenge = $_SERVER["argv"][1];
$pw = $_SERVER["argv"][2];
# $chrsz = 16; # bits per input character. 8 - ASCII; 16 - Unicode

setResponse($challenge, $pw);

function substr_unicode($str, $s, $l = null) {
    return join("", array_slice(
        preg_split("//u", $str, -1, PREG_SPLIT_NO_EMPTY), $s, $l));
}

function setResponse($challenge, $pw)
{
	$str = $challenge . "-" . makeDots($pw);
	$response = $challenge . "-" . hex_md5($str);
	echo $response;
}

function makeDots($pw)
{
	$newStr = "";
	$len = preg_match_all("/.{1}/us",$pw,$dummy);

	for ($i = 0; $i < $len; $i++) {
        $tmp = substr_unicode($pw, $i, 1);
		if (ord($tmp) > 255) {
			$newStr .= '.';
		}
		else {
			$newStr .= $tmp;
		}
	}
	return $newStr;
}

# These are the functions you'll usually want to call
# They take string arguments and return either hex or base-64 encoded strings
function hex_md5($str)
{
    $chrsz = 16;
	return binl2hex(core_md5(str2binl($str), strlen($str) * $chrsz));
}

# Calculate the MD5 of an array of little-endian words, and a bit length
function core_md5($x, $len)
{
	# append padding
	$x[$len >> 5] |= 0x80 << (($len) % 32);
	$x[((($len + 64) >> 9) << 4) + 14] = $len;

	$x_len = count($x);
    $a = 1732584193;
	$b = -271733879;
	$c = -1732584194;
	$d = 271733878;

	for($i = 0; $i < $x_len; $i += 16)
	{
		$olda = $a;
		$oldb = $b;
		$oldc = $c;
		$oldd = $d;

		$a = md5_ff($a, $b, $c, $d, $x[$i+ 0], 7 , -680876936);
		$d = md5_ff($d, $a, $b, $c, $x[$i+ 1], 12, -389564586);
		$c = md5_ff($c, $d, $a, $b, $x[$i+ 2], 17, 606105819);
		$b = md5_ff($b, $c, $d, $a, $x[$i+ 3], 22, -1044525330);
		$a = md5_ff($a, $b, $c, $d, $x[$i+ 4], 7 , -176418897);
		$d = md5_ff($d, $a, $b, $c, $x[$i+ 5], 12, 1200080426);
		$c = md5_ff($c, $d, $a, $b, $x[$i+ 6], 17, -1473231341);
		$b = md5_ff($b, $c, $d, $a, $x[$i+ 7], 22, -45705983);
		$a = md5_ff($a, $b, $c, $d, $x[$i+ 8], 7 , 1770035416);
		$d = md5_ff($d, $a, $b, $c, $x[$i+ 9], 12, -1958414417);
		$c = md5_ff($c, $d, $a, $b, $x[$i+10], 17, -42063);
		$b = md5_ff($b, $c, $d, $a, $x[$i+11], 22, -1990404162);
		$a = md5_ff($a, $b, $c, $d, $x[$i+12], 7 , 1804603682);
		$d = md5_ff($d, $a, $b, $c, $x[$i+13], 12, -40341101);
		$c = md5_ff($c, $d, $a, $b, $x[$i+14], 17, -1502002290);
		$b = md5_ff($b, $c, $d, $a, $x[$i+15], 22, 1236535329);
		$a = md5_gg($a, $b, $c, $d, $x[$i+ 1], 5 , -165796510);
		$d = md5_gg($d, $a, $b, $c, $x[$i+ 6], 9 , -1069501632);
		$c = md5_gg($c, $d, $a, $b, $x[$i+11], 14, 643717713);
		$b = md5_gg($b, $c, $d, $a, $x[$i+ 0], 20, -373897302);
		$a = md5_gg($a, $b, $c, $d, $x[$i+ 5], 5 , -701558691);
		$d = md5_gg($d, $a, $b, $c, $x[$i+10], 9 , 38016083);
		$c = md5_gg($c, $d, $a, $b, $x[$i+15], 14, -660478335);
		$b = md5_gg($b, $c, $d, $a, $x[$i+ 4], 20, -405537848);
		$a = md5_gg($a, $b, $c, $d, $x[$i+ 9], 5 , 568446438);
		$d = md5_gg($d, $a, $b, $c, $x[$i+14], 9 , -1019803690);
		$c = md5_gg($c, $d, $a, $b, $x[$i+ 3], 14, -187363961);
		$b = md5_gg($b, $c, $d, $a, $x[$i+ 8], 20, 1163531501);
		$a = md5_gg($a, $b, $c, $d, $x[$i+13], 5 , -1444681467);
		$d = md5_gg($d, $a, $b, $c, $x[$i+ 2], 9 , -51403784);
		$c = md5_gg($c, $d, $a, $b, $x[$i+ 7], 14, 1735328473);
		$b = md5_gg($b, $c, $d, $a, $x[$i+12], 20, -1926607734);
		$a = md5_hh($a, $b, $c, $d, $x[$i+ 5], 4 , -378558);
		$d = md5_hh($d, $a, $b, $c, $x[$i+ 8], 11, -2022574463);
		$c = md5_hh($c, $d, $a, $b, $x[$i+11], 16, 1839030562);
		$b = md5_hh($b, $c, $d, $a, $x[$i+14], 23, -35309556);
		$a = md5_hh($a, $b, $c, $d, $x[$i+ 1], 4 , -1530992060);
		$d = md5_hh($d, $a, $b, $c, $x[$i+ 4], 11, 1272893353);
		$c = md5_hh($c, $d, $a, $b, $x[$i+ 7], 16, -155497632);
		$b = md5_hh($b, $c, $d, $a, $x[$i+10], 23, -1094730640);
		$a = md5_hh($a, $b, $c, $d, $x[$i+13], 4 , 681279174);
		$d = md5_hh($d, $a, $b, $c, $x[$i+ 0], 11, -358537222);
		$c = md5_hh($c, $d, $a, $b, $x[$i+ 3], 16, -722521979);
		$b = md5_hh($b, $c, $d, $a, $x[$i+ 6], 23, 76029189);
		$a = md5_hh($a, $b, $c, $d, $x[$i+ 9], 4 , -640364487);
		$d = md5_hh($d, $a, $b, $c, $x[$i+12], 11, -421815835);
		$c = md5_hh($c, $d, $a, $b, $x[$i+15], 16, 530742520);
		$b = md5_hh($b, $c, $d, $a, $x[$i+ 2], 23, -995338651);
		$a = md5_ii($a, $b, $c, $d, $x[$i+ 0], 6 , -198630844);
		$d = md5_ii($d, $a, $b, $c, $x[$i+ 7], 10, 1126891415);
		$c = md5_ii($c, $d, $a, $b, $x[$i+14], 15, -1416354905);
		$b = md5_ii($b, $c, $d, $a, $x[$i+ 5], 21, -57434055);
		$a = md5_ii($a, $b, $c, $d, $x[$i+12], 6 , 1700485571);
		$d = md5_ii($d, $a, $b, $c, $x[$i+ 3], 10, -1894986606);
		$c = md5_ii($c, $d, $a, $b, $x[$i+10], 15, -1051523);
		$b = md5_ii($b, $c, $d, $a, $x[$i+ 1], 21, -2054922799);
		$a = md5_ii($a, $b, $c, $d, $x[$i+ 8], 6 , 1873313359);
		$d = md5_ii($d, $a, $b, $c, $x[$i+15], 10, -30611744);
		$c = md5_ii($c, $d, $a, $b, $x[$i+ 6], 15, -1560198380);
		$b = md5_ii($b, $c, $d, $a, $x[$i+13], 21, 1309151649);
		$a = md5_ii($a, $b, $c, $d, $x[$i+ 4], 6 , -145523070);
		$d = md5_ii($d, $a, $b, $c, $x[$i+11], 10, -1120210379);
		$c = md5_ii($c, $d, $a, $b, $x[$i+ 2], 15, 718787259);
		$b = md5_ii($b, $c, $d, $a, $x[$i+ 9], 21, -343485551);
		$a = safe_add($a, $olda);
		$b = safe_add($b, $oldb);
		$c = safe_add($c, $oldc);
		$d = safe_add($d, $oldd);
	}

	return array($a, $b, $c, $d);
}

# These functions implement the four basic operations the algorithm uses.
function md5_cmn($q, $a, $b, $x, $s, $t)
{
    return safe_add(bit_rol(safe_add(safe_add($a, $q), safe_add($x, $t)), $s),$b);
}
function md5_ff($a, $b, $c, $d, $x, $s, $t)
{
    return md5_cmn(($b & $c) | ((~$b) & $d), $a, $b, $x, $s, $t);
}
function md5_gg($a, $b, $c, $d, $x, $s, $t)
{
    return md5_cmn(($b & $d) | ($c & (~$d)), $a, $b, $x, $s, $t);
}
function md5_hh($a, $b, $c, $d, $x, $s, $t)
{
    return md5_cmn($b ^ $c ^ $d, $a, $b, $x, $s, $t);
}
function md5_ii($a, $b, $c, $d, $x, $s, $t)
{
    return md5_cmn($c ^ ($b | (~$d)), $a, $b, $x, $s, $t);
}

# Add integers, wrapping at 2^32. This uses 16-bit operations internally
# to work around bugs in some JS interpreters.
function safe_add($x, $y)
{
    return bindec(substr("00000000000000000000000000000000".decbin($x + $y), -32));
}

# Bitwise rotate a 32-bit number to the left.
function bit_rol($num, $cnt)
{
    $str = substr("00000000000000000000000000000000".decbin($num), -32);
    return bindec(substr($str, $cnt).substr($str, 0, $cnt));
}

# Convert a string to an array of little-endian words
# If chrsz is ASCII, characters >255 have their hi-byte silently ignored.
# !!!! Chinese word is fail now !!!!
function str2binl($str)
{
    $chrsz = 16;
	$bin = array();
	$strLength = strlen($str);
	$mask = 0xFFFF;#(1 << $chrsz) - 1;

	for ($i = 0; $i < $strLength * $chrsz; $i += $chrsz) {
		$tmpString = ord(substr($str, ($i / $chrsz), 1));
		$bin[$i>>5] |= ($tmpString & $mask) << ($i%32);
	}
	return $bin;
}

# Convert an array of little-endian words to a hex string.
function binl2hex($binarray)
{
    $hex_tab = "0123456789abcdef";
    $str = "";
    for($i = 0; $i < count($binarray) * 4; $i++)
    {
        $str .= substr($hex_tab, (($binarray[$i>>2] >> (($i%4)*8+4)) & 0xF), 1) .
                substr($hex_tab, (($binarray[$i>>2] >> (($i%4)*8 )) & 0xF), 1);
    }
    return $str;
}
?>
