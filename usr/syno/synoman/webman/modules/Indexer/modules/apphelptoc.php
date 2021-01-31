<?php
/* Copyright (c) 2010 Synology Inc. All rights reserved. */
class AppHelpToc {
	var $tocpath;
	var $jsonObj;
	var $translator;
	public function AppHelpToc($tocpath) {
		$this->tocpath = $tocpath;
	}
	public function loadObject($obj) {
		$this->jsonObj = $obj;
	}
	public function load() {
		$ret = FALSE;
		$jsonData = file_get_contents($this->tocpath);
		if($jsonData != FALSE) {
			$this->jsonObj = json_decode($jsonData, TRUE);
			if(!is_null($this->jsonObj)) {
				$ret = TRUE;
				//var_dump($this->jsonObj);
			}
		}
		return $ret;
	}
	// Check if the necessary nodes/elements are present in the helptoc.conf
	public function isValid() {
		$appclass = $this->jsonObj['app'];
		$title = $this->jsonObj['title'];
		$toc = $this->jsonObj['toc'];
		if(empty($appclass) || empty($title)) {
			syslog(LOG_ERR, $this->tocpath . ": Invalid help conf");
			return FALSE;
		}
		return TRUE;

	}
	public function getHelpTitle() {
		return $this->translate($this->jsonObj['title']);
	}
	public function getAppClass() {
		return $this->jsonObj['app'];
	}
	public function getHelpDesc() {
		return $this->getString($this->jsonObj, 'desc');
	}
	public function setTranslator($bundle) {
		$this->translator = $bundle;
	}
	function getStringSet() {
		return $this->jsonObj['stringset'];
	}
	function getHelpSet() {
		return $this->jsonObj['helpset'];
	}
	function getConfPath() {
		return $this->tocpath;
	}
	private function getNodeTopics($nodes, &$serial) {
		$topics = array();
		$appclass = $this->getAppClass();
		if(!is_null($nodes)) {
			foreach($nodes as $node) {
				$n = array();
				$topic = $node['content'];
				if(empty($topic)) {
					$n['id'] = $appclass . ':' . $serial;
					$serial += 1;
				}
				else {
					$n['id'] = $appclass. ':' . $topic;
					$n['topic'] =  $node['content'];
				}
				$n['owner'] = $appclass;
				$n['title'] = $this->getString($node, 'title');

				if (array_key_exists('enable', $node) && array_key_exists('disable', $node)) {
					echo "Error: " . $node['content'] . "\n";
					echo "Should not use enable and disable config at the same time !!!!\n";
					echo "For more information, please refer to:\n";
					echo "http://synowiki.synology.com/MediaWiki/index.php/DSM_3.0_Help_Format\n";
					exit(1);
				}

				if (array_key_exists('enable', $node)) {
					if (!$this->checkMatchNode($node['enable'])) {
						continue;
					}
				}

				if (array_key_exists('disable', $node)) {
					if($this->checkMatchNode($node['disable'])) {
						continue;
					}
				}

				array_push($topics, $n);
				if(array_key_exists('nodes', $node)) {
					$topics = array_merge($topics, $this->getNodeTopics($node['nodes'], $serial));
				}
			}
		}
		return $topics;

	}
	// Return topics array which has content
	public function getTopics() {
		$serial = 1;
		$nodes = $this->jsonObj['toc'];
		$topics = $this->getNodeTopics($nodes, $serial);
        $root['id'] = $this->getAppClass();
		$root['owner'] = $this->getAppClass();
        $root['title'] = $this->getHelpTitle();
        $rootcontent = $this->jsonObj['content'];
        if(is_string($rootcontent)) {
            $root['topic'] = $rootcontent;
        }
        array_push($topics, $root);
        return $topics;
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
	private function toExtTreeInternal($nodes, &$serial) {
		$extnodes = array();
		$appclass = $this->getAppClass();
		if(!is_null($nodes)) {
			foreach($nodes as $node) {
				$n = array();
				$topic = $node['content'];
				if(empty($topic)) {
					$n['id'] = $appclass . ':' . $serial;
					$serial += 1;
				}
				else {
					$n['id'] = $appclass. ':' . $topic;
					if($this->helpsetPath) {
						$n['base'] = $this->helpsetPath;
					}
					$n['topic'] = $node['content'];
				}
				$n['text'] = $this->getString($node, 'title');
				$n['desc'] = $this->getString($node, 'desc');

				if (array_key_exists('enable', $node) && array_key_exists('disable', $node)) {
					echo "Error: " . $node['content'] . "\n";
					echo "Should not use enable and disable config at the same time !!!!\n";
					echo "For more information, please refer to:\n";
					echo "http://synowiki.synology.com/MediaWiki/index.php/DSM_3.0_Help_Format\n";
					exit(1);
				}

				if (array_key_exists('enable', $node)) {
					if (!$this->checkMatchNode($node['enable'])) {
						continue;
					}
				}

				if (array_key_exists('disable', $node)) {
					if($this->checkMatchNode($node['disable'])) {
						continue;
					}
				}

				if(array_key_exists('nodes', $node)) {
					$children = $this->toExtTreeInternal($node['nodes'], $serial);
					if(count($children) > 0) {
						$n['children']  = $children;
					}
					else {
						$n['leaf'] = TRUE;
					}
				}
				else {
					$n['leaf'] = TRUE;
				}
				array_push($extnodes, $n);
			}
		}
		return $extnodes;

	}
	public function toExtTree() {
		$serial = 1;
		$data = array();
		$helpset = $this->getHelpSet();
		if(!empty($helpset)) {
			if (defined('PACKAGE_UIDIR')) {
				// pre-generate indexdb for package
				$this->helpsetPath = $helpset;
			} else {
				$this->helpsetPath = realpath(dirname($this->tocpath) . "/$helpset");
			}

			$data['base'] = $this->helpsetPath;
		}
		else {
			$this->helpsetPath = '';
		}

		$nodes = $this->jsonObj['toc'];
		$children = $this->toExtTreeInternal($nodes, $serial);
		
		$data['id'] = $this->getAppClass();
		$data['text'] = $this->getHelpTitle();
		$data['desc'] = $this->getHelpDesc();
		$rootcontent = $this->jsonObj['content'];
		if(is_string($rootcontent)) {
			$data['topic'] = $rootcontent;
		}
		if(count($children) > 0) {
			$data['children'] = $children;
		}
		else {
			$data['leaf'] = TRUE;
		}
		
		return json_encode($data);
	}

	private function translate($s) {
		if($this->translator) {
			$s = $this->translator->getString($s);
		}
		return $s;
	}

	private function getString($obj, $key) {
		$val = $obj[$key];
		return $this->translate($val);

	}


}

?>
