<?php
/* Copyright (c) 2010 Synology Inc. All rights reserved. */
class StringBundle {
	var $strings = array();
	var $strfilepath;
	function StringBundle($strPath) {
		$this->strfilepath = $strPath;
	}
	function getString() {
		$nargs = func_num_args();
		if($nargs > 1) {
			$sec = func_get_arg(0);
			$key = func_get_arg(1);
			return $this->ReplaceStringByProduct($this->strings[$sec][$key]);
		}
		else if($nargs == 1) {
			$s = func_get_arg(0);
			$keyval = explode(':', $s , 2);
			if(count($keyval) == 2) {
				$s = $this->strings[$keyval[0]][ $keyval[1]];				
			}
			return $this->ReplaceStringByProduct($s);

		}
		return NULL;
	}

	function getSectionStrings($sec) {
		return array_values($this->strings[$sec]);
		
	}
	function getSections() {
		return array_keys($this->strings);

	}
	/**
		Search strings for a given key pattern.
		Return an arry of matched string value
	*/
	function getSectionStringsByReg($sec, $keyreg) {
		$keys = array_keys($this->strings[$sec]);
		$resultkeys = preg_grep($keyreg, $keys);
		$results = array();
		foreach($resultkeys as $key) {
			array_push($results, $this->strings[$sec][$key]);
		}
		return $results;

	}
	function load() {
		$patstr = '/(\w+)\s*=\s*\"(.*)\"/';
		$patsec = '/^\[(\w+)\]/';
		$handle = fopen($this->strfilepath, "r");
		$currsec = "";
		if ($handle) {
			while (!feof($handle)) {
				$buffer = trim(fgets($handle, 4096));
				if($buffer) {
					if(preg_match($patsec, $buffer, $matches)) {
						$section = $matches[1];
						$this->strings[$section] = array();
						$currsec = $section;
						//echo "$currsec\n";
					}
					else if(preg_match($patstr, $buffer, $matches)) {
						$key = $matches[1];
						$val = $matches[2];
						$this->strings[$currsec][$key] = $val;
						//echo "$currsec, $key = $val\n";
					}
				}
			}
			fclose($handle);
			return true;
		}
		else {
			return false;
		}
		

	}
	function ReplaceStringByProduct($s) {
		$origin = array("_OSNAME_", "_DISKSTATION_");
		if ("SRM" === CURRENT_PRODUCT) {
			$result = array("SRM", "Synology Router");
		} else if ("NVR" === CURRENT_PRODUCT) {
                        $result = array("DSM", "Synology NVR");
		} else {
			$result = array("DSM", "Synology NAS");
		}
		return str_replace($origin, $result, $s);
	}
}

class StringBundleCache {
	private static $bundleCache = NULL;
	private $pathBundleDict;

	public static function instance() {
		if(is_null(self::$bundleCache)) {
			self::$bundleCache = new StringBundleCache();
		}
		return self::$bundleCache;
	}
	function StringBundleCache() {
		$this->pathBundleDict = array();
	}
	function getStringBundle($path) {
		$cpath = realpath($path);
		if(!file_exists($cpath)) {
			return NULL;
		}
		if(array_key_exists($cpath, $this->pathBundleDict)) {
			return $this->pathBundleDict[$cpath];
		}
		$bundle = new StringBundle($cpath);
		if(!$bundle->load()) {
			return NULL;
		}
		$this->pathBundleDict[$cpath] = $bundle;
		return $bundle;
	}
}

?>
