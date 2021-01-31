Ext.namespace('SYNO.SecurityAdvisor');

SYNO.SecurityAdvisor.ScheScanGridPanel = Ext.extend(Ext.Panel, {
	border: false,
	constructor: function(cfg) {
		var config = this.fillConfig(cfg);
		SYNO.SecurityAdvisor.ScheScanGridPanel.superclass.constructor.call(this, config);
		this.addClass('syno-traffic-report-gridpanel-style');
		this.addClass('syno-traffic-report-panel-style');
	},
	fillConfig: function(cfg) {
		var config = {
			viewConfig: this.createViewConf(),
			items: [
				this.getGridPanel()
			]
		};
		Ext.apply(config, cfg);
		return config;
	},
	createViewConf: function() {
		return {
			forceFit: true,
			trackResetOnLoad: false // to disable updatescrollbar
		};
	},
	tplAdd: function(val, show) {
		return "<div ext:qtip='" + val + "'>" + show + "</div>";
	},
	getGridPanel: function() {
		if (!Ext.isDefined(this.gridPanel)) {
			var storeConfig = {
				fields: [
					{name: 'Status'},
					{name: 'StatusSortable'},
					{name: 'StatusRawValue'},
					{name: 'Severity'},
					{name: 'SeveritySortable'},
					{name: 'Category'},
					{name: 'Description'},
					{name: 'ScanTime'}
				]
			};
			var store = new Ext.data.ArrayStore(storeConfig);
			store.loadData(synoScheScanGridData);

			store.multiSort([
				{
					field: 'StatusSortable',
					direction: 'ASC'
				}, {
					field: 'SeveritySortable',
					direction: 'ASC'
				}
			]);

			store.filter([
				{
					fn : function(record) {
						return record.get('StatusRawValue') !== 'pass';
					}
				}
			]);

			this.gridPanel = new Ext.grid.GridPanel({
				border: false,
				store: store,
				stripeRows: true,
				width: 1200,
				autoHeight: true,
				enableColumnResize: false,
				enableHdMenu: false,
				enableColumnHide: false,
				enableColumnMove: false,
				layout: {
					type: 'accordion',
					autoWidth: true
				},
				columns: [{
					header: _T('securityscan', 'securityscan_label_status'), 
					dataIndex: 'StatusSortable',
					align: 'left',
					width: 120,
					sortable : true,
					renderer: function(val, cellmeta, rec, rowindex, colindex, store) {
						var severity_sortable = rec.get('SeveritySortable');
						var statusRaw = rec.get('StatusRawValue');
						var status = rec.get('Status');

						if (statusRaw === "pass") {
							return '<div><div class="cell-outer"><div class="cell-middle"><div class="green_circle"></div></div>' + status + '</div></div>';
						} else if (statusRaw === "skip" || statusRaw === "running") {
							return '<div><div class="cell-outer"><div class="cell-middle"><div class="gray_circle"></div></div>' + status + '</div></div>';
						} else if (statusRaw === "nonChecked" ) {
							return '<div><div class="cell-outer"><div class="cell-middle"><div class="gray_circle"></div></div>' + status + '</div></div>';
						} else {
							if (severity_sortable === 4) {  // info
								return '<div><div class="cell-outer"><div class="cell-middle"><div class="gray_circle"></div></div>' + status + '</div></div>';
							} else if (severity_sortable === 2 || severity_sortable === 3) {  // outOfDate / warning
								return '<div><div class="cell-outer"><div class="cell-middle"><div class="yellow_circle"></div></div>' + status + '</div></div>';
							} else if (severity_sortable === 1) {  // risk
								return '<div><div class="cell-outer"><div class="cell-middle"><div class="orange_circle"></div></div>' + status + '</div></div>';
							} else if (severity_sortable === 0) {  // danger
								return '<div><div class="cell-outer"><div class="cell-middle"><div class="red_circle"></div></div>' + status + '</div></div>';
							} else {
								return '<div><div class="cell-outer"><div class="cell-middle"><div class="gray_circle"></div></div> Unknown </div></div>';
							}
						}
					}
				}, {
					header: _T('securityscan', 'securityscan_label_level'),
					dataIndex: 'SeveritySortable',
					align: 'left',
					width: 150,
					sortable : true,
					renderer: function(val, cellmeta, rec, rowindex, colindex, store) {
						var strVal = rec.get('Severity');
						return strVal;
					}
				}, {
					header: _T('securityscan', 'securityscan_label_category'), 
					dataIndex: 'Category',
					align: 'left',
					width: 220,
					sortable : true
				}, {
					header: _T('securityscan', 'securityscan_label_desc'), 
					tooltip: _T('securityscan', 'securityscan_label_desc'),
					dataIndex: 'Description',
					align: 'left',
					width: 530,
					renderer: function(val, meta) {
						var ret = Ext.util.Format.htmlEncode(val);
						meta.attr += String.format('ext:qtip="{0}";', Ext.util.Format.htmlEncode(ret));
						return ret;
					}
				}, {
					header: _T('securityscan', 'securityscan_label_update'),
					tooltip: _T('securityscan', 'securityscan_label_desc'),
					dataIndex: 'ScanTime',
					align: 'left',
					width: 158,
					sortable : true,
					scope: this,
					renderer: function(val, meta) {
						if (val) {
							return val;
						} else {
							return "";
						}
					}
				}]
			});

		}
		return this.gridPanel;
	}
});

function ScheScanClickHandler() {
	if (this.showScheScanPassItems === false) {
		this.showScheScanPassItems = true;
		Ext.get('schescan-show-btn').dom.innerText = _T('report', 'btn_hide_pass_item');
		this.scheScanGridPanel.gridPanel.store.loadData(synoScheScanGridData);
		Ext.get('schescan-dir-icon').dom.className = "up-icon";
	} else {
		this.showScheScanPassItems = false;
		Ext.get('schescan-show-btn').dom.innerText = _T('report', 'btn_show_pass_item');
		this.scheScanGridPanel.gridPanel.store.filter([
			{
				fn : function(record) {
					return record.get('StatusRawValue') != 'pass';
				}
			}
		]);
		Ext.get('schescan-dir-icon').dom.className = "down-icon";
	}
}

function DrawScheduledScanGrid() {
	this.scheScanGridPanel = new SYNO.SecurityAdvisor.ScheScanGridPanel();
	this.scheScanGridPanel.render('sche-scan-grid-panel');

	Ext.select('#sche-scan-grid-panel .device-empty-list').remove();
}
