<?php
session_cache_limiter("must-revalidate");

if (!isset($_GET['ln']) || $_GET['ln'] == "") {
	$_GET['ln'] = GetHttpLang();
}

if (!isSuppLang($_GET['ln'])) {
	exit;
}

$file_path = "texts/".$_GET['ln']."/strings";

if (!file_exists($file_path)) {
	exit;
}

$signature = CreateSig($file_path);
if ($signature) {
	CheckSigExit($signature);
	@header("ETag: ".$signature[0]);
	@header("Last-Modified: ".$signature[1]);
}

echo "SYNOJSLIB_Strings={};\n";
echo "_s=SYNOJSLIB_Strings;\n";

$file = fopen($file_path, 'r');

$section = "";

while (!feof($file)) {
	$line = fgets($file, 4096);
	if ($line == "" || $line == "\n" || strstr($line, "#") != null) {
		continue;
	}
	if (strstr($line, "[") != null) {
		$line = str_replace("[", "", $line);
		$line = str_replace("]", "", $line);
		$section = trim($line, " \t\n");
		echo "_s.".$section."={};\n";
		continue;
	}
	$key_value = explode("=", $line);
	$key_value[0] = trim($key_value[0], " \t\n");
	$key_value[1] = trim($key_value[1], " \"\t\n'");
	echo "_s.".$section."['".$key_value[0]."']='".addslashes($key_value[1])."';\n";
}
fclose($file);

echo "delete _s;\n";
echo "function _JSLIBSTR(g, s) { ";
echo "try {";
echo "	return SYNOJSLIB_Strings[g][s]; ";
echo "} catch(e) { return '';}";
echo "}\n";

function GetHttpLang()
{
	$szLang = "enu";
	
	$HttpStr = $_SERVER["HTTP_ACCEPT_LANGUAGE"];

	$HttpLang = strtok($HttpStr, ",;\n");
	while ($HttpLang) {
		if (!strcasecmp($HttpLang, "zh-tw") || 
			!strcasecmp($HttpLang, "zh-hk") ||
			!strcasecmp($HttpLang, "zh-mo")) {
			$szTemp = "cht";
		}
		else if (!strncasecmp($HttpLang, "zh", 2)) {
			$szTemp = "chs";
		}
		else if (!strcasecmp($HttpLang, "en") ||
			 !strncasecmp($HttpLang, "en-", 3)) {
			$szTemp = "enu";
		}
		else if (!strcasecmp($HttpLang, "de") ||
			 !strncasecmp($HttpLang, "de-", 3)) {
			$szTemp = "ger";
		}
		else if (!strcasecmp($HttpLang, "ja") ||
			 !strncasecmp($HttpLang, "ja-", 3)) {
			$szTemp = "jpn";
		}
		else if (!strcasecmp($HttpLang, "ko") ||
			 !strncasecmp($HttpLang, "ko-", 3)) {
			$szTemp = "krn";
		}
		else if (!strcasecmp($HttpLang, "es") ||
			 !strncasecmp($HttpLang, "es-", 3)) {
			$szTemp = "spn";
		}
		else if (!strcasecmp($HttpLang, "fr") ||
			 !strncasecmp($HttpLang, "fr-", 3)) {
			$szTemp = "fre";
		}
		else if (!strcasecmp($HttpLang, "it") ||
			 !strncasecmp($HttpLang, "it-", 3)) {
			$szTemp = "ita";
		}
		else if (!strcasecmp($HttpLang, "ru") ||
			 !strncasecmp($HttpLang, "ru-", 3)) {
			$szTemp = "rus";
		}
		else if (!strcasecmp($HttpLang, "nl") ||
			 !strncasecmp($HttpLang, "nl-", 3)) {
			$szTemp = "nld";
		}
		else if (!strcasecmp($HttpLang, "no") ||
			 !strncasecmp($HttpLang, "no-", 3)||
			 !strcasecmp($HttpLang, "nb") ||
			 !strncasecmp($HttpLang, "nb-", 3) ||
			 !strcasecmp($HttpLang, "nn") ||
			 !strncasecmp($HttpLang, "nn-", 3)) {
			$szTemp = "nor";
		}
		else if (!strcasecmp($HttpLang, "sv") ||
			 !strncasecmp($HttpLang, "sv-", 3)) {
			$szTemp = "sve";
		}
		else if (!strcasecmp($HttpLang, "da") ||
			 !strncasecmp($HttpLang, "da-", 3)) {
			$szTemp = "dan";
		}
		else if (!strcasecmp($HttpLang, "pl") ||
			 !strncasecmp($HttpLang, "pl-", 3)) {
			$szTemp = "plk";
		}
		else if (!strncasecmp($HttpLang, "pt-br", 5)) {
			$szTemp = "ptb";
		}
		else if (!strcasecmp($HttpLang, "pt") ||
				 !strncasecmp($HttpLang, "pt-", 3)) {
			$szTemp = "ptg";
		}
		else if (!strcasecmp($HttpLang, "hu") ||
				 !strncasecmp($HttpLang, "hu-", 3)) {
			$szTemp = "hun";
		}
		else if (!strcasecmp($HttpLang, "tr") ||
				 !strncasecmp($HttpLang, "tr-", 3)) {
			$szTemp = "trk";
		}
		else if (!strcasecmp($HttpLang, "cs") ||
				 !strncasecmp($HttpLang, "cs-", 3)) {
			$szTemp = "csy";
		}

		if (isSuppLang($szTemp)) {
			$szLang = $szTemp;
			break;
		}
		$HttpLang = strtok(",;\n");
	}

	return $szLang;
}

function isSuppLang($szLang)
{
	$SYNO_DEF_CNF_FILE = "/etc.defaults/synoinfo.conf";

	$SuppLang = SystemInfoGet($SYNO_DEF_CNF_FILE, "supplang");

	if (strstr($SuppLang, $szLang) == NULL) {
		return FALSE;
	} else {
		return TRUE;
	}
}


function SystemInfoGet($conf_file, $conf_key)
{
	$result = "";
	$syno_conf_file = fopen($conf_file, 'r');
	
	while (!feof($syno_conf_file)){
		$line = fgets($syno_conf_file, 4096);
		if (strstr($line, $conf_key) != null) {
			$conf = explode("=", $line);
			if ($conf[0] == $conf_key && strlen($conf[1]) > 0){
				$result = $conf[1];
				break;
			}
		}
	}
	fclose($syno_conf_file);
	
	$result = trim($result, "\n");
	$result = substr($result, 1, strlen($result)-2);
	
	return $result;
}

function CreateSig($path)
{
	$filest = @stat($path);
	$etag = "";
	if ($filest != FALSE) {
		$etag = md5($path.$filest[1].$filest[9]);
		$lastmod = gmdate('D, d M Y H:i:s', $filest[9]) . ' GMT';
		return array($etag, $lastmod);
	}
	else {
		return FALSE;
	}
}

function CheckSigExit($signature)
{
	$etag = $signature[0];
	$lastmod = $signature[1];
	$token = $_SERVER['HTTP_IF_NONE_MATCH'];
	if ($token && ($token == $etag)) {
		@header("HTTP/1.1 304 Not Modified");
		exit;
	}	
	if (isset($_SERVER['HTTP_IF_MODIFIED_SINCE'])) {
		$ims = preg_replace('/;.*$/', '', $_SERVER['HTTP_IF_MODIFIED_SINCE'] );
		if ($ims == $lastmod) {
			@header("HTTP/1.1 304 Not Modified");
			exit;
		}
	}	
}
?>
