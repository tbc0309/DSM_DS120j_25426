<?php
/* Copyright (c) 2010 Synology Inc. All rights reserved. */
require_once("modules/indexerinc.php");
require_once("modules/stringbundle.php");
require_once("modules/appindexconf.php");
require_once("modules/helpterms.php");
require_once("modules/apphelptoc.php");

function tempdir($dir, $prefix) {
	$tempfile=tempnam($dir, $prefix);
	if (file_exists($tempfile)) {
		unlink($tempfile);
	}
	mkdir($tempfile);
	return $tempfile;
}

class AppHelpConfParser {
	var $appindexobjs= array();
	var $confpath;
	var $type;
	function AppHelpConfParser($confpath, $type) {
		$this->confpath = $confpath;
		$this->type = $type;
	}
	private function addAppJson($appjson) {
		if(!is_null($appjson['app'])) {
			if($this->type == 'help') {
				$appindex = new AppHelpToc($this->confpath);
			}
			else {
				$appindex = new AppIndexConf($this->confpath);
			}
			$appindex->loadObject($appjson);
			array_push($this->appindexobjs, $appindex);
		}
	}
	function checkMatchType($conf, $types) {
		foreach ($types as $type) {
			$type = str_replace('+', 'p', strtolower($type));
			if (array_key_exists('platform', $conf)) {
				foreach ($conf['platform'] as $p) {
					$p = str_replace('+', 'p', strtolower($p));
					if ($p == $type) {
						return TRUE;
					}
				}
			}
			if (array_key_exists('model', $conf)) {
				foreach ($conf['model'] as $m) {
					$m = str_replace('+', 'p', strtolower($m));
					if ($m == $type) {
						return TRUE;
					}
				}
			}
			if (array_key_exists('os', $conf)) {
				foreach ($conf['os'] as $o) {
					if ($o == $type) {
						return TRUE;
					}
				}
			}
		}
		return FALSE;
	}

	function parseRootNode($jsonObj) {
		$ret = FALSE;

		// check root node needed or not
		$this->rootExist = TRUE;
		if (defined('CURRENT_TYPE')) {
			$types = explode(' ', CURRENT_TYPE);

			if (!is_null($jsonObj['enable']) && !is_null($jsonObj['disable'])) {
				echo "Error: " . $this->confpath ."\n";
				echo "Should not use enable and disable config at the same time\n";
				echo "For more information, please refer to:\n";
				echo "http://synowiki.synology.com/MediaWiki/index.php/DSM_3.0_Help_Format\n";
				exit(1);
			}

			if (!is_null($jsonObj['enable'])) {
				if(!$this->checkMatchType($jsonObj['enable'], $types)){
					$this->rootExist = FALSE;
				}
			}

			if (!is_null($jsonObj['disable'])) {
				if($this->checkMatchType($jsonObj['disable'], $types)){
					$this->rootExist = FALSE;
				}
			}
		}

		if (!is_null($jsonObj['helpcatalog'])) {
			$this->catalogType = $jsonObj['helpcatalog'];
		}

		if(!is_null($jsonObj) && $this->rootExist) {
			if(!is_null($jsonObj['app'])) {
				$this->addAppJson($jsonObj);
			}
			else {
				foreach($jsonObj as $obj) {
					$this->addAppJson($obj);
				}
			}
			$ret = TRUE;
		}
		return $ret;
	}

	function parse() {
		$ret = FALSE;
		$jsonData = file_get_contents($this->confpath);
		if($jsonData != FALSE) {
			$jsonObj = json_decode($jsonData, TRUE);

			if (is_null($jsonObj['app'])) {
				foreach($jsonObj as $root) {
					$ret = $this->parseRootNode($root);
					if ($this->rootExist == TRUE) {
						break;
					}
				}
			} else {
				$ret = $this->parseRootNode($jsonObj);
			}
		}
		return $ret;
	}
	function getObjects() {
		return $this->appindexobjs;
	}
	function getCatalogType() {
		return $this->catalogType;
	}
	function getRootStatus() {
		return $this->rootExist;
	}
}

class IndexFinder {
	var $locations = array();
	var $appindexList = array();
	var $helptocList = array();
	function IndexFinder() {
		array_push($this->locations, DEFAULT_APPSTORE);
		for($x=1;$x<10;$x++) {
			$appstore = "/volume$x/@appstore";
			if(is_dir($appstore)) {
				array_push($this->locations, $appstore);
			}
		}
	}

	private function getSubDirectories($dir) {
		$subdirs = array();
		if (is_dir($dir)) {
			if ($dh = opendir($dir)) {
				while (($file = readdir($dh)) !== FALSE) {
					$path = $dir . "/" . $file;
					if(is_dir($path)) {
						array_push($subdirs, $path);
					}
				}
				closedir($dh);
			}
		}
		return $subdirs;
    }

	public function getAppIndexes() {
		return $this->appindexList;
	}
	public function getHelpTocs() {
		return $this->helptocList;
	}
	public function getStores() {
		return $this->locations;
	}
	public function saveStoreList($file) {
		file_put_contents($file, implode("\n", $this->locations) ."\n");
	}
	public function saveAppIndexList($file) {
		file_put_contents($file, implode("\n", $this->appindexList) ."\n");
	}
	public function saveHelptocList($file) {
		file_put_contents($file, implode("\n", $this->helptocList) . "\n");
	}

	public function find() {
		$this->appindexList = array();
		$this->helptocList = array();
		foreach($this->locations as $store) {
			$apps = $this->getSubDirectories($store);
			foreach($apps as $app) {
				$appindex = $app ."/index.conf";
				$helptoc = $app . "/helptoc.conf";
				if(is_file($appindex)) {
					array_push($this->appindexList, $app);
				}
				if(is_file($helptoc)) {
					array_push($this->helptocList, $app);
				}
			}
		}

		$modulesList = GetDsmModulesArray();
		if ($modulesList) {
			foreach ($modulesList as $app => $item) {
				$appindex = $app ."/index.conf";
				$helptoc = $app . "/helptoc.conf";
				if (is_file($appindex)) {
					array_push($this->appindexList, $app);
				}
				if (is_file($helptoc)) {
					array_push($this->helptocList, $app);
				}
			}
		}

		sort($this->appindexList);
		sort($this->helptocList);
	}
}

function RemoveIndexDoc($docid, $dbdir, $type) {
	$tmpname = tempnam('/tmp', 'rmindex');
	$handle = fopen($tmpname, "w");
	if($handle) {
		fwrite($handle, sprintf("id=%s\n\n", $docid));
		fclose($handle);
	}
	system(SCRIPT_INDEX_BIN . " --stemmer=english $dbdir " . (($type == 'app') ? APPINDEX_SCRIPT:HELPINDEX_SCRIPT) . " " . $tmpname);
	unlink($tmpname);
}

function CheckAppOrHelpConf($confpath) {
	$type = basename($confpath, '.conf');
	if($type == 'index') {
		return 'app';
	}
	else if($type == 'helptoc') {
		return 'help';
	}
	else {
		return '';
	}
}

function Handle3rdPartyIndexDB($confPath, $confType, $dbPath, $action)
{
	// create symbolic link to indexdbdir in 3rdparty dir
	$thirdPartyDir = DSM_INDEX_DBDIR . '/3rdparty';
	if (!CheckCreateDir($thirdPartyDir)) {
		IndexerLog("Failed to create $thirdPartyDir");
		return FALSE;
	}

	$dbRealPath = realpath($dbPath);
	if (!$dbRealPath) {
		IndexerLog("Cannot get real path of $dbPath");
		return FALSE;
	}

	if ($confType === 'app') {
		$dbDir = $thirdPartyDir . '/appindexdb';
	} else if ($confType === 'help') {
		$dbDir = $thirdPartyDir . '/helpindexdb';
	} else {
		IndexerLog("Not support conf type: $confType");
		return FALSE;
	}

	if (!CheckCreateDir($dbDir)) {
		IndexerLog("Failed to create $dbDir");
		return FALSE;
	}

	$parser = new AppHelpConfParser($confPath, $confType);

	if (!$parser->parse()) {
		IndexerLog("Failed to load $confPath");
		return FALSE;
	}
	$confobjs = $parser->getObjects();
	foreach ($confobjs as $conf) {
		$appClass = $conf->getAppClass();
		$linkPath = $dbDir . '/' . $appClass;

		if ($action === 'add') {
			@unlink($linkPath);
			if (!symlink($dbRealPath, $linkPath)) {
				IndexerLog("Failed to create symbolic link $dbRealPath to $linkPath");
				return FALSE;
			}
		} else if ($action === 'del') {
			@unlink($linkPath);
		}
	}

	// update help catalog
	if ($confType === 'help') {
		$helpIndexer = new HelpIndexer();
		$helpIndexer->updateHelpCatalog($confPath, $action, $parser->getCatalogType());
	}
}

function Add3rdPartyIndexDB($confPath, $confType, $dbPath)
{
	Handle3rdPartyIndexDB($confPath, $confType, $dbPath, 'add');
}

function Del3rdPartyIndexDB($confPath, $confType, $dbPath)
{
	Handle3rdPartyIndexDB($confPath, $confType, $dbPath, 'del');
}

function GetDsmModulesArray()
{
	if (!defined('DSM_MODULES_LIST')) {
		return false;
	}

	$content = file_get_contents(DSM_MODULES_LIST);

	$modulesList = json_decode($content, true);
	if (!$modulesList) {
		echo "  !! JSON decode error:";
		echo json_last_error();
		echo "\n";
		return false;
	}

	return $modulesList;
}

class HelpIndexer {
	private $workingDir;

	function HelpIndexer() {
		$this->workingDir = tempdir("/tmp", "helpIndex.");
	}
	function __destruct() {
		system("rm -rf ".$this->workingDir);
	}
    //PreCondition: the Configuration object strings are already translated.
	private function indexTopics($conf, $lang, $helpStore) {
		$topics = $conf->getTopics();
        if(!CheckCreateDir($this->workingDir)) {
            IndexerLog( "Failed to locate " . $this->workingDir);
            return FALSE;
        }
		$tmpname = $this->workingDir."/$lang";
		$handle = fopen($tmpname, "a");
		if($handle) {
			echo "Indexing " . count($topics) . " topics for " . $conf->getAppClass() .  ":$lang\n";
			foreach($topics as $topic) {
				fwrite($handle, sprintf("id=%s\n", $topic['id']));
				fwrite($handle, sprintf("title=%s\n", CJKConvert($topic['title'], $lang)));
				fwrite($handle, sprintf("orgtitle=%s\n", $topic['title']));

				fwrite($handle, sprintf("owner=%s\n", $topic['owner']));
				$content = $topic['topic'];
				if(!empty($content)) {
					fwrite($handle, sprintf("topic=%s\n", $content));
					$helpPath = $helpStore . "/$lang/" . $content;
					$helpTerms = new HelpTerms($helpPath, $lang);
					$terms = $helpTerms->getTerms();
					if(!empty($terms)) {
						fwrite($handle, "help=" . $terms);
					}
				}
				else {
					fwrite($handle, "help=");
				}
				fwrite($handle, "\n\n");
			}
			fclose($handle);
		}
		return TRUE;

    }
	function indexHelpCommit() {
		global $HELPLANGMAP;
		$langs = array_keys($HELPLANGMAP);
		$pwd = getcwd();

		foreach($langs as $lang) {
			$langval = $HELPLANGMAP[$lang];
			$file = $this->workingDir."/$lang";
			$dbdir = DSM_HELPINDEXDB . "/$lang";
			$tmpDbDir = $dbdir . ".tmp";
			if(!CheckCreateDir(DSM_HELPINDEXDB)) {
				IndexerLog( "Failed to locate " . DSM_HELPINDEXDB);
				return FALSE;
			}
			if(!CheckCreateDir($dbdir)) {
				IndexerLog( "Failed to locate " . $dbdir);
				return FALSE;
			}

			if (defined("USE_COMPRESSION") && (USE_COMPRESSION === false)) {
				print "\n".SCRIPT_INDEX_BIN . " --stemmer=$langval $dbdir " . APPINDEX_SCRIPT . " " . $file. "\n";
				system(SCRIPT_INDEX_BIN . " --stemmer=$langval $dbdir " . APPINDEX_SCRIPT . " " . $file);
			} else {
				print "\n".SCRIPT_INDEX_BIN . " --stemmer=$langval $tmpDbDir " . APPINDEX_SCRIPT . " " . $file. "\n";
				system(SCRIPT_INDEX_BIN . " --stemmer=$langval $tmpDbDir " . APPINDEX_SCRIPT . " " . $file);
				system(COMPACT_INDEX_BIN . " -F $tmpDbDir $dbdir");
				system("rm -rf $tmpDbDir");
				system("rm -f ".$this->workingDir."/$lang");
			}
		}
	}
	private function indexHelp($conf) {
		$confPath = $conf->getConfPath();
		$confDir = dirname($confPath);
		$cacheDir = $confDir . '/.helptoc';
		if(!CheckCreateDir($cacheDir)) {
			IndexerLog( "Failed to create $cacheDir");
			return FALSE;
		}
		$cacheDir .= '/' . $conf->getAppClass();
		if(!CheckCreateDir($cacheDir)) {
			IndexerLog( "Failed to create $cacheDir");
			return FALSE;
		}


		global $HELPLANGMAP;
		$bundleCache = StringBundleCache::instance();
		$langs = array_keys($HELPLANGMAP);
		$stringStore = DEFAULT_STORE_STRINGS;
		$helpStore = DEFAULT_STORE_HELP;

		if(!is_null($conf->getStringSet())) {
			$stringStore = realpath($confDir . '/' . $conf->getStringSet());
		}
		if(!is_null($conf->getHelpSet())) {
			$helpStore = realpath($confDir . '/' . $conf->getHelpSet());
		}


		foreach($langs as $lang) {
			$stringPath = $stringStore . "/$lang/strings";
			$bundle = $bundleCache->getStringBundle($stringPath);
			// Language is not aviailable
			if(is_null($bundle)) {
				IndexerLog( "No localized strings for $lang: " . $stringPath);
				continue;
			}

			// Create menu cache
			$conf->setTranslator($bundle);
			$jsonData = $conf->toExtTree();
			if(!empty($jsonData)) {
				$fp = fopen($cacheDir . "/helptoc." . $lang, "w");
				if($fp != FALSE) {
					fwrite($fp, $jsonData);
					fclose($fp);
				}
			}
			if(!$this->indexTopics($conf, $lang, $helpStore)) {
				IndexerLog( "Failed to index topics for $lang");
			}
		}
		return TRUE;

	}
	private function removeHelp($conf) {
		$confPath = $conf->getConfPath();
		$confDir = dirname($confPath);
		$cacheDir = $confDir . '/.helptoc';

		global $HELPLANGMAP;
		$langs = array_keys($HELPLANGMAP);


		foreach($langs as $lang) {
			$topics = $conf->getTopics();
			$dbdir = DSM_HELPINDEXDB . "/$lang";
			$tmpname = tempnam('/tmp', 'helpindex');
			foreach($topics as $topic) {
				RemoveIndexDoc($topic['id'], $dbdir, 'help');
			}
		}
		RemoveDir($cacheDir);

	}

	public function updateHelpCatalog($confpath, $action, $type) {
		$catalogPath;
		if (!defined('AUX_HELP_CATALOG')) {
			$catalogPath = DSM_HELP_CATALOG;
		} else {
			$catalogPath = ($type == "aux") ? AUX_HELP_CATALOG : DSM_HELP_CATALOG;
		}

		$lines = @file($catalogPath, FILE_SKIP_EMPTY_LINES | FILE_IGNORE_NEW_LINES);
		if($lines == FALSE) {
			$lines = array();
		}

		$path = realpath($confpath);
		if($path == FALSE) {
			return;
		}
		$path = $confpath;
		$dirpath = dirname($path);
		if($action == 'add') {
			if(!in_array($dirpath, $lines)) {
				array_push($lines, $dirpath);
			}
		}
		else if($action == 'del') {
			$index = array_search($dirpath, $lines);
			if($index !== FALSE) {
				array_splice($lines, $index, 1);
			}
		}
		file_put_contents($catalogPath, implode("\n", $lines));

	}
	function delHelp($confPath) {
		$parser = new AppHelpConfParser($confPath, 'help');

		if(!$parser->parse()) {
			IndexerLog( "Failed to load $confPath");
			return FALSE;
		}

		if ($parser->getRootStatus()) {
			$confobjs = $parser->getObjects();
			foreach($confobjs as $conf) {
				$this->removeHelp($conf);
			}
			$this->updateHelpCatalog($confpath, 'del', $parser->getCatalogType());
		}

		return TRUE;
	}
	function addHelp($confPath, $notaddCatalog) {
		$parser = new AppHelpConfParser($confPath, 'help');

		if(!$parser->parse()) {
			IndexerLog( "Failed to load $confPath");
			return FALSE;
		}

		if ($parser->getRootStatus()) {
			$confobjs = $parser->getObjects();
			foreach($confobjs as $conf) {
				$this->indexHelp($conf);
			}
			if(!$notaddCatalog) {
				$this->updateHelpCatalog($confPath, 'add', $parser->getCatalogType());
			}
		}

		return TRUE;
	}
	function replacePathInHelpCatalog() {
		$modulesList = GetDsmModulesArray();
		if (!$modulesList) {
			return;
		}

		$lines = @file(DSM_HELP_CATALOG, FILE_SKIP_EMPTY_LINES | FILE_IGNORE_NEW_LINES);
		if ($lines === FALSE) {
			return;
		}

		foreach ($modulesList as $path => $item) {
			$key = array_search($path, $lines);
			if ($key === false) {
				continue;
			}

			$locationOnDs = sprintf("/usr/syno/synoman/webman/modules/%s", $item['name']);
			$lines[$key] = $locationOnDs;
		}
		file_put_contents(DSM_HELP_CATALOG, implode("\n", $lines));
	}

}
class AppIndexer {
	private $workingDir;

	function AppIndexer() {
		$this->workingDir = tempdir("/tmp", "appIndex.");
	}
	function __destruct() {
		system("rm -rf ".$this->workingDir);
	}
	// Validate the index.conf object. Return TRUE if it's valid.
	private function validateAppConf($conf) {
		$appclass = $conf->getAppClass();
		$title = $conf->getAppTitle();
		if(empty($appclass) || empty($title)) {
			IndexerLog( $conf->getConfPath() . ": Invalid app conf");
			return FALSE;
		}

		return TRUE;
	}
	function indexAppCommit() {
		global $LANGMAP;
		$langs = array_keys($LANGMAP);

		if(!CheckCreateDir(DSM_APPINDEXDB)) {
			IndexerLog( "Failed to locate " . DSM_HELPINDEXDB);
			return FALSE;
		}

		foreach($langs as $lang) {
			$langval = $LANGMAP[$lang];
			$file = $this->workingDir."/$lang";

			$dbdir = DSM_APPINDEXDB . "/$lang";
			$tmpDbDir = $dbdir.".tmp";
			if(!CheckCreateDir($dbdir)) {
				IndexerLog( "Failed to locate " . $dbdir);
				return FALSE;
			}
			@mkdir($dbdir, 0777, TRUE);

			if (defined("USE_COMPRESSION") && (USE_COMPRESSION === false)) {
				print "\n".SCRIPT_INDEX_BIN . " --stemmer=$langval $dbdir " . APPINDEX_SCRIPT . " " . $file. "\n";
				system(SCRIPT_INDEX_BIN . " --stemmer=$langval $dbdir " . APPINDEX_SCRIPT . " " . $file);
			} else {
				print "\n".SCRIPT_INDEX_BIN . " --stemmer=$langval $tmpDbDir " . APPINDEX_SCRIPT . " " . $file. "\n";
				system(SCRIPT_INDEX_BIN . " --stemmer=$langval $tmpDbDir " . APPINDEX_SCRIPT . " " . $file);
				system(COMPACT_INDEX_BIN . " -F $tmpDbDir $dbdir");
				system("rm -rf $tmpDbDir");
				system("rm -rf $file");
			}
		}
	}
	private function updateRecord($id, $title, $desc, $keywords, $helps, $helpStore, $owner, $lang) {
		CheckCreateDir($this->workingDir);
		$file = $this->workingDir."/$lang";
		$handle = fopen($file, "a");
		if($handle) {
			fwrite($handle, sprintf("id=%s\n", $id));
			fwrite($handle, sprintf("title=%s\n", CJKConvert($title, $lang)));
			fwrite($handle, sprintf("orgtitle=%s\n", $title));
			fwrite($handle, sprintf("desc=%s\n", CJKConvert($desc, $lang) ));
			fwrite($handle, sprintf("orgdesc=%s\n", $desc));
			fwrite($handle, sprintf("keywords=%s\n", CJKConvert($keywords, $lang) ));
			fwrite($handle, sprintf("owner=%s\n", $owner));

/*
			if(!empty($helps)) {
				$helpfiles = array();
				if(is_array($helps)) {
                    $helpfiles = $helps;
                }
				else if(is_string($helps)) {
					array_push($helpfiles, $helps);
                }
				$helplinesArray = array();
				foreach($helpfiles as $help) {
                    $helpPath = $helpStore . "/$lang/" . $help;
                    $helpTerms = new HelpTerms($helpPath, $lang);
                    $terms = $helpTerms->getTerms();
					if(!empty($terms)) {
						array_push($helplinesArray, $terms);
                    }
                }
				if(count($helplinesArray) > 0) {
					$helpdata = implode("\n=", $helplinesArray);
					fwrite($handle, "help=" . $helpdata);
				}
			}
			else {
				fwrite($handle, "help=" . $helpdata);
			}
*/

			fwrite($handle,"\n\n");
			fclose($handle);
		}
	}
	private function indexModules($conf, $appclass, $lang, $helpStore) {
		$count = $conf->getModuleCount();
		for($i=0;$i<$count;$i++) {
			$module = $conf->getModuleConf($i);
			if (is_null($module)) {
				continue;
			}
			$title = $module['title'];
			$params = $module['params'];
			$helps = $module['help'];
			if(empty($title)) {
				IndexerLog( "Module title is missing");
				continue;
			}
			if(empty($params)) {
				IndexerLog( "Module params is missing");
				continue;
			}

			$keywords = $module['keywords'];
			if(!empty($keywords)) {
				$keywords = implode(' ', $keywords);
			}
			else {
				$keywords = '';
			}
			$id = $appclass . '?' . $params;
			$this->updateRecord($id, $title, $module['desc'], $keywords, $helps, $helpStore, $appclass, $lang);
		}

	}
	private function indexApp($conf) {
		if(!$this->validateAppConf($conf)) {
			return FALSE;
		}
		if(!CheckCreateDir(DSM_APPINDEXDB)) {
			IndexerLog( "Failed to locate " . DSM_APPINDEXDB);
			return FALSE;
        }

		global $LANGMAP;
		$cache = StringBundleCache::instance();
		$langs = array_keys($LANGMAP);
		$appclass = $conf->getAppClass();

		$stringStore = DEFAULT_STORE_STRINGS;
		$helpStore = DEFAULT_STORE_HELP;
		if(!is_null($conf->getStringSet())) {
			$confDir = dirname($conf->getConfPath());
			$stringStore = realpath($confDir . '/' . $conf->getStringSet());
		}
		if(!is_null($conf->getHelpSet())) {
			$confDir = dirname($conf->getConfPath());
			$helpStore = realpath($confDir . '/' . $conf->getHelpSet());
		}

		foreach($langs as $lang) {
			$stringPath = $stringStore . "/$lang/strings";
			$bundle = $cache->getStringBundle($stringPath);
			$helps = $conf->getHelp();
			// Language is not aviailable
			if(is_null($bundle)) {
				IndexerLog( "No localized strings for $lang: " . $stringPath);
				continue;
			}
			$conf->setTranslator($bundle);
			$title = $conf->getAppTitle();
			$keywords = $conf->getKeywords();
			array_push($keywords, $title);

			if(!empty($keywords)) {
				$keywords = implode(' ', $keywords);
			}
			else {
				$keywords = '';
			}
			$this->updateRecord($appclass, $conf->getAppTitle(), $conf->getAppDesc(), $keywords, $helps, $helpStore, NULL, $lang);
			$this->indexModules($conf, $appclass, $lang, $helpStore);

		}
		return TRUE;

	}

	private function removeApp($conf) {
		 global $LANGMAP;
		 $langs = array_keys($LANGMAP);
		 $count = $conf->getModuleCount();
		 $appclass = $conf->getAppClass();
		 foreach($langs as $lang) {
			 $dbdir = DSM_APPINDEXDB . "/$lang";
			 for($i=0;$i<$count;$i++) {
				 $module = $conf->getModuleConf($i);
				 $params = $module['params'];
				 $helps = $module['help'];
				 if(empty($params)) {
					 IndexerLog( "Module params is missing");
					 continue;
				 }

				 $id = $appclass . '?' . $params;
				 RemoveIndexDoc($id, $dbdir, 'app');
			 }
			 RemoveIndexDoc($appclass, $dbdir, 'app');
		 }


	}
	public function delApplication($appconf) {
		$parser = new AppHelpConfParser($appconf, 'app');

		if(!$parser->parse()) {
			IndexerLog( "Failed to load $appconf");
			return FALSE;
		}
		$confobjs = $parser->getObjects();
		foreach($confobjs as $conf) {
			$this->removeApp($conf);
		}
		return TRUE;

	}
	public function addApplication($appconf) {
		$parser = new AppHelpConfParser($appconf, 'app');

		if(!$parser->parse()) {
			IndexerLog( "Failed to load $appconf");
			return FALSE;
		}
		$confobjs = $parser->getObjects();
		foreach($confobjs as $conf) {
		 	$this->indexApp($conf);
		}
		return TRUE;

	}
}

$cmdOpts = getopt('rnuh:d:a:p:t:', array('indexdbdir:'));
if(array_key_exists('h', $cmdOpts)) {
	define("UIHELP_LOCATION", $cmdOpts['h']);
	define("DSM_MODULES_LIST", '/image/files/dsm/modules/dsm.modules');
	SetupHostIndexDefines();
}
else if(array_key_exists('u', $cmdOpts)) {
	SetupAuxIndexDefines();
	define("USE_COMPRESSION", false);
}
else if(array_key_exists('p', $cmdOpts)) {
	define("PACKAGE_UIDIR", $cmdOpts['p']);
	SetupHostPackageIndexDefines();
}
else {
	SetupDSIndexDefines();
}
if(array_key_exists('r', $cmdOpts)) {
	echo "Removing " . DSM_INDEX_DBDIR ."\n";
	RemoveDir(DSM_INDEX_DBDIR);
}
if (array_key_exists('t', $cmdOpts)) {
	// remove prefix for platforms
	$cur_type = str_replace('PPC_', '', $cmdOpts['t']);
	$cur_type = str_replace('MARVELL_', '', $cur_type);
	$cur_type = str_replace('TI_', '', $cur_type);
	$cur_type = str_replace('PLX_', '', $cur_type);
	$cur_type = str_replace('KVM_', '', $cur_type);
	$cur_type = str_replace('MINDSPEED_', '', $cur_type);
	$cur_type = str_replace('BROADCOM_', '', $cur_type);
	$cur_type = str_replace('HISILICON_', '', $cur_type);

	echo "CURRENT_TYPE: " . $cur_type . "\n";
	define("CURRENT_TYPE", $cur_type);
	if ("hi3535" === strtolower($cur_type)) {
		define("CURRENT_PRODUCT", "NVR");
	} else if ("northstarplus" === strtolower($cur_type)) {
		define("CURRENT_PRODUCT", "SRM");
	}
}

if(!CheckCreateDir(DSM_INDEX_DBDIR)) {
	IndexerLog( "Failed to create " . DSM_INDEX_DBDIR);
	exit(1);
}

$notToAddHelpCatalog = FALSE;
$notToAddHelpCatalog = array_key_exists('n', $cmdOpts) ? TRUE: FALSE;

if(array_key_exists('a', $cmdOpts)) {
	$confpath = $cmdOpts['a'];
	$conftype = CheckAppOrHelpConf($confpath);
	if(empty($conftype)) {
		echo "$confpath is neither helptoc.conf nor index.conf\n";
		exit(1);
	}

	$confpath = realpath($confpath);
	if (array_key_exists('indexdbdir', $cmdOpts)) {
		Add3rdPartyIndexDB($confpath, $conftype, $cmdOpts['indexdbdir']);
		exit(0);
	}

	if($conftype == 'app') {
		$appindexer = new AppIndexer();
		$appindexer->addApplication($confpath);
		$appindexer->indexAppCommit();
	}
	else {
		$helpindexer = new HelpIndexer();
		$helpindexer->addHelp($confpath, $notToAddHelpCatalog);
		$helpindexer->indexHelpCommit();
	}
	exit(0);
}

if(array_key_exists('d', $cmdOpts)) {
	$confpath = $cmdOpts['d'];
	$conftype = CheckAppOrHelpConf($confpath);
	if(empty($conftype)) {
		echo "$confpath is neither helptoc.conf nor index.conf\n";
		exit(1);
	}

	$confpath = realpath($confpath);
	if (array_key_exists('indexdbdir', $cmdOpts)) {
		Del3rdPartyIndexDB($confpath, $conftype, $cmdOpts['indexdbdir']);
		exit(0);
	}

	if($conftype == 'app') {
		$appindexer = new AppIndexer();
		$appindexer->delApplication($confpath);
	}
	else {
		$helpindexer = new HelpIndexer();
		$helpindexer->delHelp($confpath);
	}
	exit(0);
}

$finder = new IndexFinder();
$finder->find();
//$finder->saveHelptocList(DSM_HELP_CATALOG);
$helptocLocations = $finder->getHelpTocs();
$apps = $finder->getAppIndexes();

print "Number of apps to index: " . count($apps) . "\n";
print "Number of helps to index: " .count($helptocLocations) . "\n";

$helpindexer = new HelpIndexer();
foreach($helptocLocations as $helptoc) {
	echo "Processing helptoc on $helptoc\n";
	$helpindexer->addHelp($helptoc . "/helptoc.conf", $notToAddHelpCatalog);
}
$helpindexer->indexHelpCommit();
$helpindexer->replacePathInHelpCatalog();

$appindexer = new AppIndexer();

foreach($apps as $app) {
	echo "Processing application on $app\n";
	$appindexer->addApplication("$app/index.conf");
}
$appindexer->indexAppCommit();

?>
