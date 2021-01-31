<?php
/* Copyright (c) 2010 Synology Inc. All rights reserved. */
require_once("indexerinc.php");

class HelpTerms {
	var $terms;
	var $cjklangs = array("cht", "chs","jpn","krn");
	function HelpTerms($helpfile, $lang) {
		if(file_exists($helpfile)) {
			if(in_array($lang, $this->cjklangs)) {
				$this->terms = CJKConvert(implode("\n=", GetFileAsArrayStripped($helpfile)), $lang);
			}
			else {
				$this->terms = implode("\n=", GetFileAsArrayStripped($helpfile));
			}
		}
		else {
			if($lang == 'cht' || $lang == 'enu') {
				IndexerLog('File not found: ' . $helpfile);
			}
		}
	}
	function getTerms() {
		return $this->terms;
	}
}

?>
