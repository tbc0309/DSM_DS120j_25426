<?php
require_once("simple_html_dom.php");
/* Copyright (c) 2010 Synology Inc. All rights reserved. */
$HELPLANGMAP = array(
	"enu" => "english",
	"cht" => "english",
	"chs" => "english",
	"csy" => "english",
	"jpn" => "english",
	"krn" => "english",
	"fre" => "french",
	"ger" => "german",
	"ita" => "italian",
	"nld" => "dutch",
	"plk" => "english",
	"rus" => "russian",
	"spn" => "spanish"
);

$LANGMAP = array(
	"enu" => "english",
	"cht" => "english",
	"chs" => "english",
	"csy" => "english",
	"jpn" => "english",
	"krn" => "english",
	"dan" => "danish",
	"fre" => "french",
	"ger" => "german",
	"ita" => "italian",
	"nld" => "dutch",
	"nor" => "norwegian",
	"plk" => "english",
	"rus" => "russian",
	"spn" => "spanish",
	"sve" => "swedish",
	"hun" => "hungarian",
	"trk" => "turkish",
	"tha" => "english",
	"ptg" => "portuguese",
	"ptb" => "portuguese"
);

function SetupHostIndexDefines() {
	define("DSM_LOCATION", "/image/files/dsm");
	define("DEFAULT_APPSTORE", DSM_LOCATION . "/modules");
	define("DSM_INDEX_DIR", getcwd());
	define("DEFAULT_STORE_HELP", UIHELP_LOCATION . "/dsm");
	define("DEFAULT_STORE_STRINGS", "/source/uistring/dsm");
	define("APPINDEX_SCRIPT", DSM_INDEX_DIR . "/appindex.script");
	define("HELPINDEX_SCRIPT", DSM_INDEX_DIR . "/helpindex.script");
	define("DSM_INDEX_DBDIR", DSM_INDEX_DIR . "/indexdb");
	define("DSM_HELP_CATALOG", DSM_INDEX_DBDIR . "/help.catalog");
	define("DSM_APPINDEXDB", DSM_INDEX_DBDIR . "/appindexdb");
	define("DSM_HELPINDEXDB", DSM_INDEX_DBDIR . "/helpindexdb");
	define("SCRIPT_INDEX_BIN", "/usr/bin/scriptindex");
	define("COMPACT_INDEX_BIN", "/usr/bin/xapian-compact");
	define("CJKTERMS_BIN", "/usr/syno/bin/cjkterms");
	define("AUX_HELP_CATALOG", DSM_INDEX_DBDIR . "/auxhelp.catalog");
}
function SetupHostPackageIndexDefines() {
	define("DSM_LOCATION", "/source/dsm");
	define("DEFAULT_APPSTORE", DSM_LOCATION . "/modules");
	define("DSM_INDEX_DIR", "/source/dsm-Indexer/ui");
	define("DEFAULT_STORE_HELP", PACKAGE_UIDIR . "/help");
	define("DEFAULT_STORE_STRINGS", PACKAGE_UIDIR . "/texts");
	define("APPINDEX_SCRIPT", DSM_INDEX_DIR. "/appindex.script");
	define("HELPINDEX_SCRIPT", DSM_INDEX_DIR. "/helpindex.script");
	define("DSM_INDEX_DBDIR", PACKAGE_UIDIR . "/indexdb");
	define("DSM_HELP_CATALOG", DSM_INDEX_DBDIR . "/help.catalog");
	define("DSM_APPINDEXDB", DSM_INDEX_DBDIR . "/appindexdb");
	define("DSM_HELPINDEXDB", DSM_INDEX_DBDIR . "/helpindexdb");
	define("SCRIPT_INDEX_BIN", "/usr/bin/scriptindex");
	define("COMPACT_INDEX_BIN", "/usr/bin/xapian-compact");
	define("CJKTERMS_BIN", "/usr/syno/bin/cjkterms");
}
function SetupDSIndexDefines() {
	define("DSM_LOCATION", "/usr/syno/synoman/webman");
	define("DEFAULT_APPSTORE", DSM_LOCATION . "/modules");
	define("DEFAULT_STORE_HELP", DSM_LOCATION . "/help");
	define("DEFAULT_STORE_STRINGS", DSM_LOCATION . "/texts");
	define("APPINDEX_SCRIPT", DEFAULT_APPSTORE . "/Indexer/appindex.script");
	define("HELPINDEX_SCRIPT", DEFAULT_APPSTORE . "/Indexer/helpindex.script");
	define("DSM_INDEX_DBDIR", "/usr/syno/synoman/indexdb");
	define("DSM_HELP_CATALOG", DSM_INDEX_DBDIR . "/help.catalog");
	define("DSM_APPINDEXDB", DSM_INDEX_DBDIR . "/appindexdb");
	define("DSM_HELPINDEXDB", DSM_INDEX_DBDIR . "/helpindexdb");
	define("SCRIPT_INDEX_BIN", "/usr/bin/scriptindex");
	define("COMPACT_INDEX_BIN", "/usr/local/xapian/bin/xapian-compact");
	define("CJKTERMS_BIN", "/usr/syno/bin/cjkterms");
}
function SetupAuxIndexDefines() {
	define("DSM_LOCATION", "/usr/syno/synoman/webman");
	define("DEFAULT_APPSTORE", DSM_LOCATION . "/modules");
	define("DEFAULT_STORE_HELP", DSM_LOCATION . "/help");
	define("DEFAULT_STORE_STRINGS", DSM_LOCATION . "/texts");
	define("APPINDEX_SCRIPT", DEFAULT_APPSTORE . "/Indexer/appindex.script");
	define("HELPINDEX_SCRIPT", DEFAULT_APPSTORE . "/Indexer/helpindex.script");
	define("DSM_INDEX_DBDIR", "/usr/syno/etc/indexdb");
	define("DSM_HELP_CATALOG", DSM_INDEX_DBDIR . "/help.catalog");
	define("DSM_APPINDEXDB", DSM_INDEX_DBDIR . "/appindexdb");
	define("DSM_HELPINDEXDB", DSM_INDEX_DBDIR . "/helpindexdb");
	define("SCRIPT_INDEX_BIN", "/usr/bin/scriptindex");
	define("COMPACT_INDEX_BIN", "/usr/local/xapian/bin/xapian-compact");
	define("CJKTERMS_BIN", "/usr/syno/bin/cjkterms");
}

function FilterEmptyLine($line) {
	return ($line != '');
}

function StripTagTrim($s) {
	return trim(strip_tags($s));
}

function GetFileAsArrayStripped($file) {
	$html = file_get_html($file);
	if (defined('CURRENT_TYPE')) {
		$types = explode(' ', CURRENT_TYPE);
		$enableClasses = array();
		foreach($types as $type) {
			$type = str_replace('+', 'p', strtolower($type));
			// remove content has disable classes and matched
			$disableCls = "disable-" . $type;
			$els = $html->find("." . $disableCls);
			foreach($els as $el) {
				if (strpos($el->class, "enable") !== false) {
					echo "Error: " . $file . "\n";
					echo "Should not use enable and disable class at the same time !!!!\n";
					echo "For more information, please refer to:\n";
					echo "http://synowiki.synology.com/MediaWiki/index.php/Help_Document_Format\n";
					exit(1);
				}
				$el->outertext = "";
			}

			// construct enable class array
			$enableCls = "enable-" . $type;
			$enableClasses[] = $enableCls;
		}

		// remove content has enable classes but not matched
		$els = $html->find('[class*=enable]');
		foreach ($els as $el) {
			$match = false;

			foreach ($enableClasses as $enableCls) {
				if (strpos($el->class, $enableCls) !== false) {
					$match = true;
				}
			}

			if ($match === false) {
				$el->outertext = "";
			}
		}
	}
	$content = html_entity_decode(strip_tags($html));
	$content = strtr($content, '*', ' ');
	$lines = explode("\n", $content);
	return array_filter(array_map("trim", $lines), "FilterEmptyLine");

}

function IsCJKLang($lang) {
	$supported = array("cht", "chs", "jpn", "krn");
	if(in_array($lang, $supported)) {
		return true;
	}
	return false;
}
function CJKConvert($s, $lang) {
	if(!IsCJKLang($lang)) {
		return trim($s);
	}
	$descriptorspec = array(
	   0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
	   1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
	   2 => array("file", "/tmp/error-output.txt", "a") // stderr is a file to write to
	);

	$result = "";
	$process = proc_open(CJKTERMS_BIN, $descriptorspec, $pipes);

	if (is_resource($process)) {
		// $pipes now looks like this:
		// 0 => writeable handle connected to child stdin
		// 1 => readable handle connected to child stdout
		// Any error output will be appended to /tmp/error-output.txt

		fwrite($pipes[0], $s);
		fclose($pipes[0]);


		while (!feof($pipes[1])) {
			$result .= fread($pipes[1], 8192);
		}

		fclose($pipes[1]);

		// It is important that you close any pipes before calling
		// proc_close in order to avoid a deadlock
		$return_value = proc_close($process);

	}
	return trim($result);

}

function CheckCreateDir($dirPath) {
	if(is_dir($dirPath)) {
		return TRUE;
	}
	else {
		@mkdir($dirPath, 0777);
		return is_dir($dirPath);
	}
}

function RemoveDir($sDir) {
	if (is_dir($sDir)) {
		$sDir = rtrim($sDir, '/');
		$oDir = dir($sDir);
		while (($sFile = $oDir->read()) !== false) {
			if ($sFile != '.' && $sFile != '..') {
				(!is_link("$sDir/$sFile") && is_dir("$sDir/$sFile")) ? RemoveDir("$sDir/$sFile") : unlink("$sDir/$sFile");
			}
		}
		$oDir->close();
		rmdir($sDir);
		return true;
	}
	return false;
}
function IndexerLog($msg) {
	syslog(LOG_ERR, $msg);
	echo $msg . "\n";
}

?>
