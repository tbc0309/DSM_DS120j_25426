/* Copyright (c) 2000-2016 Synology Inc. All rights reserved. */

/*global
  report_data
*/
Ext.override(Ext.Element, {
	getText: function() {
		return this.dom.textContent || this.dom.innerText || "";
	},
	addTip: function(tip) {
		this.set({'ext:qtip': tip});
		return this;
	}
});


Ext.namespace('SYNO.REPORT');

SYNO.REPORT.COLOR_CRITICAL = "#dd4040";
SYNO.REPORT.COLOR_HIGH = "#f47f17";
SYNO.REPORT.COLOR_MEDIAN = "#f1c207";
SYNO.REPORT.COLOR_NORMAL = "#31629b";

Ext.onReady(function(){

	SYNO.REPORT.init();

});

SYNO.REPORT.init = function() {
	var isRetina = function() {
		var ret = false;
		var mediaQuery = "(-webkit-min-device-pixel-ratio: 1.5),(min--moz-device-pixel-ratio: 1.5)," +
			"(-o-min-device-pixel-ratio: 3/2),(min-resolution: 1.5dppx)";
		if (window.devicePixelRatio >= 1.5) {
			ret = true;
		}
		if (window.matchMedia && window.matchMedia(mediaQuery).matches) {
			ret = true;
		}
		return ret;
	};

	var initRetina = function() {
		if (isRetina()) {
			 Ext.get(document.documentElement).addClass('synohdpack');
		}
	};

	SYNO.REPORT.initData();
	initRetina();

	//Ext.QuickTips.init();
};

SYNO.REPORT.initData = function() {
	function updateUIString() {
		var eles = Ext.select('.UIS');
		eles.each(function(ele) {
			if (!ele || !ele.dom) {
				return true;
			}
			var text = ele.getText();
			var keys = text.split(',');
			var section = keys[0];
			var key = keys[1];

			ele.update(_T(section, key));
		});
	}

	function updateBannerTitle() {
		var e = Ext.get('banner-title');
		if (synoRealTimeDatatime.length === 7) {
			e.dom.innerText = _T('helptoc', 'securityscan') + ' - ' + _T('report', 'monthly_report');
		} else {
			e.dom.innerText = _T('helptoc', 'securityscan') + ' - ' + _T('report', 'daily_report');
		}
	}

	function updateDataTime() {
		var e = Ext.get('data-time');
		e.dom.innerText = _T('report', 'title_report_date_range') + ' : ' + synoDataTime;
	}

	function updateHostName() {
		var e = Ext.get('banner-info-hostname');
		e.dom.innerText = synoHostName;
		e = Ext.get('banner-info-gentime');
		e.dom.innerText = _T('report', 'generated_at') + ' : ' + synoCreateTime;
	}

	function updateSummaryTitle() {
		var e = Ext.get('summary-title');
		e.dom.innerText = _T('report', 'summary');
	}

	function updateSummaryData() {
		var e = Ext.get('summary-sche-scan-title');
		e.dom.innerText = _T('helptoc', 'securityscan_result_name');
		e = Ext.get('severity-sche-scan-critical-title');
		e.dom.innerText = _T('securityscan', 'securityscan_severity_danger');
		e = Ext.get('severity-sche-scan-high-title');
		e.dom.innerText = _T('securityscan', 'securityscan_severity_risk');
		e = Ext.get('severity-sche-scan-medium-title');
		e.dom.innerText = _T('securityscan', 'securityscan_severity_warning');

		e = Ext.get('summary-realtime-title');
		e.dom.innerText = _T('helptoc', 'securityscan_idprotection_name');
		e = Ext.get('severity-realtime-high-title');
		e.dom.innerText = _T('securityscan', 'idprotection_severity_high');
		e = Ext.get('severity-realtime-medium-title');
		e.dom.innerText = _T('securityscan', 'idprotection_severity_medium');

		e = Ext.get('severity-sche-scan-critical-number');
		e.dom.innerText = String(synoScheScanCriticalNum);
		if (synoScheScanCriticalNum === 0) {
			e.setStyle('color', SYNO.REPORT.COLOR_NORMAL);
		} else {
			e.setStyle('color', SYNO.REPORT.COLOR_CRITICAL);
		}

		e = Ext.get('severity-sche-scan-high-number');
		e.dom.innerText = String(synoScheScanHighNum);
		if (synoScheScanHighNum === 0) {
			e.setStyle('color', SYNO.REPORT.COLOR_NORMAL);
		} else {
			e.setStyle('color', SYNO.REPORT.COLOR_HIGH);
		}

		e = Ext.get('severity-sche-scan-medium-number');
		e.dom.innerText = String(synoScheScanMediumNum);
		if (synoScheScanMediumNum === 0) {
			e.setStyle('color', SYNO.REPORT.COLOR_NORMAL);
		} else {
			e.setStyle('color', SYNO.REPORT.COLOR_MEDIAN);
		}

		e = Ext.get('severity-realtime-high-number');
		e.dom.innerText = String(synoRealTimeHighNum);
		if (synoRealTimeHighNum === 0) {
			e.setStyle('color', SYNO.REPORT.COLOR_NORMAL);
		} else {
			e.setStyle('color', SYNO.REPORT.COLOR_HIGH);
		}

		e = Ext.get('severity-realtime-medium-number');
		e.dom.innerText = String(synoRealTimeMediumNum);
		if (synoRealTimeMediumNum === 0) {
			e.setStyle('color', SYNO.REPORT.COLOR_NORMAL);
		} else {
			e.setStyle('color', SYNO.REPORT.COLOR_MEDIAN);
		}
	}

	function updateScheScanDiv() {
		var e = Ext.get('sche-scan-title');
		e.dom.innerText = _T('helptoc', 'securityscan_result_name');
		e = Ext.get('sche-scan-result-title');
		e.dom.innerText = _T('securityscan', 'scan_result');
	}

	function updateRealtimeDiv() {
		if (typeof synoRealTimeBarChartNoData !== 'undefined') {
			Ext.get('realtime-grid').dom.style.display = 'none';
			return;
		}

		var e = Ext.get('realtime-title');
		e.dom.innerText = _T('helptoc', 'securityscan_idprotection_name');
		e = Ext.get('realtime-stack-bar-chart-title');
		if (synoRealTimeDatatime.length === 7) {
			e.dom.innerText = _T('securityscan', 'idprotection_result_monthly');
		} else {
			e.dom.innerText = _T('securityscan', 'idprotection_result_daily');
		}
	}

	function updateShowBtn() {
		if (synoRealTimeCriticalNum + synoRealTimeHighNum + synoRealTimeMediumNum <= 10) {
			Ext.get('realtime-show-btn-control').dom.style.display = 'none';
		}
	}

	updateUIString();

	updateBannerTitle();
	updateDataTime();
	updateHostName();
	updateSummaryTitle();
	updateSummaryData();
	updateScheScanDiv();
	updateRealtimeDiv();

	updateShowBtn();

	Ext.select('.wrapper').removeClass('hidden');
	Ext.select('.banner .TRS').removeClass('hidden');
};
