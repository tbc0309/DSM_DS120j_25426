<?php
/* Copyright (c) 2010 Synology Inc. All rights reserved. */
class AppIndexConf {
	var $confpath;
	var $jsonObj;
	var $translator;

	function AppIndexConf($confpath) {
		$this->confpath = $confpath;
	}
	private function translate($s) {
		if($this->translator) {
			$s = $this->translator->getString($s);
		}
		return $s;
	}
	function getConfPath() {
		return $this->confpath;
	}
	function getModuleCount() {
		$cnt = 0;
		if(is_array($this->jsonObj['modules'])) {
			$cnt = count($this->jsonObj['modules']);
		}
		return $cnt;
	}
	private function checkMatchNode($conf) {
		if (!defined('CURRENT_TYPE')) {
			return FALSE;
		}
		$types = explode(' ', CURRENT_TYPE);
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
	function getModuleConf($idx) {
		if(is_array($this->jsonObj['modules'])) {
			$cnt = count($this->jsonObj['modules']);
			if($idx < $cnt) {
				$conf = $this->jsonObj['modules'][$idx];
				if (array_key_exists('enable', $conf)) {
					if (!$this->checkMatchNode($conf['enable'])) {
						return NULL;
					}
				}

				if (array_key_exists('disable', $conf)) {
					if($this->checkMatchNode($conf['disable'])) {
						return NULL;
					}
				}
				$obj = array();
				$obj['title'] = $this->getString($conf, 'title');
				$obj['desc'] = $this->getString($conf, 'desc');
				$obj['keywords'] = $this->getArray($conf, 'keywords');
				$obj['help'] = $this->extractHelps($conf['help']);
				$obj['params'] = $conf['params'];
				return $obj;
			}
		}
		return NULL;
	}
	function getStringSet() {
		return $this->jsonObj['stringset'];
	}
	function getHelpSet() {
		return $this->jsonObj['helpset'];
	}
	function getHelp() {
		return $this->extractHelps($this->jsonObj['help']);
	}
	function getAppClass() {
		return $this->jsonObj['app'];
	}
	function getAppDesc() {
		return $this->getString($this->jsonObj, 'desc');
	}
	private function getString($obj, $key) {
		$val = $obj[$key];
		return $this->translate($val);

	}
	private function getArray($obj, $key) {
		$ret = array();
		$arr = $obj[$key];
		if(is_array($arr)) {
			foreach($arr as $word) {
				$ret[] = $this->translate($word);
			}
		}
		return $ret;

	}

	private function extractHelps($helps) {
		if (is_array($helps)) {
			$ret = array();
			foreach($helps as $help => $item) {
				if (is_array($item)) {
					if (array_key_exists('enable', $item)) {
						if ($this->checkMatchNode($item['enable'])) {
							$ret[] = $help;
						}
					} else if (array_key_exists('disable', $item)) {
						if(!$this->checkMatchNode($item['disable'])) {
							$ret[] = $help;
						}
					} else {
						$ret[] = $help;
					}
				} else if (is_string($item)) {
					$ret[] = $item;
				}
			}
			return $ret;
		} else {
			return $helps;
		}
	}

	function getKeywords() {
		return $this->getArray($this->jsonObj, 'keywords');
	}
	function getAppTitle() {
		return $this->translate($this->jsonObj['title']);
	}
	function setTranslator($bundle) {
		$this->translator = $bundle;
	}
	function loadObject($obj) {
		$this->jsonObj = $obj;
	}
	function load() {
		$ret = FALSE;
		$jsonData = file_get_contents($this->confpath);
		if($jsonData != FALSE) {
			$this->jsonObj = json_decode($jsonData, TRUE);
			if(!is_null($this->jsonObj)) {
				$ret = TRUE;
				//var_dump($this->jsonObj);
			}
		}
		return $ret;
	}

}


?>
