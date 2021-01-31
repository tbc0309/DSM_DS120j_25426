Ext.namespace('SYNO.SecurityAdvisor');

SYNO.SecurityAdvisor.RealTimeGridPanel = Ext.extend(Ext.Panel, {
	border: false,
	constructor: function(cfg) {
		var config = this.fillConfig(cfg);
		SYNO.SecurityAdvisor.RealTimeGridPanel.superclass.constructor.call(this, config);
		this.addClass('syno-traffic-report-gridpanel-style');
		this.addClass('syno-traffic-report-panel-style');
	},
	fillConfig: function(cfg) {
		var config = {
			cls: 'traffic-overview-event-grid',
			items: [
				this.getGridPanel()
			]
		};
		Ext.apply(config, cfg);
		return config;
	},
	getGridPanel: function() {
		if (!Ext.isDefined(this.gridPanel)) {
			var storeConfig = {
				fields: [
					{name: 'severity'},
					{name: 'severity_sortable'},
					{name: 'create_time'},
					{name: 'str_args'},
					{name: 'str_id'},
					{name: 'str_section'},
					{name: 'user'},
					{name: 'country', 
						convert: function(val, rec) {
							var strArgs = JSON.parse(rec[3]);  // get str_args
							if (strArgs.country_code) {
								return _T('Country', strArgs.country_code);
							} else if (strArgs.country_code_list) {
								if (0 === strArgs.country_code_list.length) {
									return '-';
								} else if (1 === strArgs.country_code_list.length) {
									return _T('Country', strArgs.country_code_list[0]);
								} else {
									return _T('securityscan', 'multiple_countries');
								}
							} else {
								return '-';
							}
						}
					}
				],
				sortInfo: {
					field: 'create_time',
					direction: 'DESC'
				}
			};
			var store = new Ext.data.ArrayStore(storeConfig);
			store.loadData(synoRealTimeGridData10);

			var renderSymptom = function(sec, key, args, bold) {
				var msg = _T(sec, key);

				for (var prop in args) {
					if (args.hasOwnProperty(prop)) {
						var regex = new RegExp('__' + prop + '__', 'ig');
						if (bold === true) {
							msg = msg.replace(regex, '<font class="securityscan-severity-font-highlight">' + args[prop] + '</font>');
						} else {
							msg = msg.replace(regex, args[prop]);
						}
					}
				}

				return msg;
			}

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
					header: _T('securityscan', 'securityscan_label_level'),
					dataIndex: 'severity_sortable',
					width: 140,
					sortable : true,
					renderer: function(val, cellmeta, rec, rowindex, colindex, store) {
						var severity = rec.get('severity')
						var severityI18n = _T('securityscan', 'idprotection_severity_' + severity);

						if (severity === 'high') {
							return '<div><div class="cell-outer"><div class="cell-middle"><div class="orange_circle"></div></div>' + severityI18n + '</div></div>';
						} else if (severity === 'medium') {
							return '<div><div class="cell-outer"><div class="cell-middle"><div class="yellow_circle"></div></div>' + severityI18n + '</div></div>';
						} else {
							return '<div><div class="cell-outer"><div class="cell-middle"><div class="gray_circle"></div></div> Unknown </div></div>';
						}
					}
				}, {
					header: _T('common', 'user'), 
					dataIndex: 'user',
					width: 180,
					sortable : true
				}, {
					header: _T('common', 'country'),
					dataIndex: 'country',
					width: 240,
					sortable : true
				}, {
					header: _T('securityscan', 'securityscan_label_desc'),
					dataIndex: 'str_id',
					width: 460,
					sortable: true,
					renderer: function(val, cellmeta, rec, rowindex, colindex, store) {
						var strVal = renderSymptom(rec.get('str_section'), val + '_symptom', JSON.parse(rec.get('str_args')));
						return strVal;
					}
				}, {
					header: _T('securityscan', 'idprotection_label_time'), 
					dataIndex: 'create_time',
					width: 158,
					sortable : true
				}]
			});

		}
		return this.gridPanel;
	}
});

function RealTimeClickHandler() {
	if (this.showRealTimeAllItems === false) {
		this.showRealTimeAllItems = true;
		Ext.get('realtime-show-btn').dom.innerText = _T('report', 'btn_show_latest_item');
		this.realTimeGridPanel.gridPanel.store.loadData(synoRealTimeGridData);
		Ext.get('realtime-dir-icon').dom.className = "up-icon";
	} else {
		this.showRealTimeAllItems = false;
		Ext.get('realtime-show-btn').dom.innerText = _T('report', 'btn_show_all_item');
		this.realTimeGridPanel.gridPanel.store.loadData(synoRealTimeGridData10);
		Ext.get('realtime-dir-icon').dom.className = "down-icon";
	}
}

function DrawRealTimeGrid() {
	if (typeof synoRealTimeBarChartNoData !== 'undefined') {
		return;
	}

	this.realTimeGridPanel = new SYNO.SecurityAdvisor.RealTimeGridPanel();
	this.realTimeGridPanel.render('realtime-grid-panel');
}
