/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.ns("SYNO.SDS.ResourceMonitor.Performance.Chart");Ext.define("SYNO.SDS.ResourceMonitor.Performance.Detail.Header",{extend:"Ext.Container",constructor:function(a){var c=this;var b=Ext.apply({layout:{type:"hbox",pack:"end"},height:32,style:"margin: 5px 0px 0px 0px;",topLayer:a.topLayer,items:[],listeners:{activate:this.onActivate,scope:this}},a.config);if(!Ext.isEmpty(a.lun_button)){if(a.lun_button.title){c.button_label=c.createCustomLabel(a.lun_button.title,false);b.items.push(c.button_label)}c.lun_button=c.createLunButton(a.lun_button.text,a.lun_button.handler,a.lun_button.scope);b.items.push(c.lun_button)}if(!Ext.isEmpty(a.type_combo)){c.type_label=c.createCustomLabel(_T("rsrcmonitor","chart"),false);c.type_combo=c.createTypeCombo(a.type_combo.data);b.items.push(c.type_label);b.items.push(c.type_combo)}if(!Ext.isEmpty(a.lun_combo)){c.lun_label=c.createCustomLabel(_T("rsrcmonitor","lun_name"),false);c.lun_combo=c.createLunCombo();b.items.push(c.lun_label);b.items.push(c.lun_combo)}c.history_label=c.createCustomLabel(_T("rsrcmonitor","time_range"),true);c.history_combo=c.createHistoryCombo();b.items.push(c.history_label);b.items.push(c.history_combo);this.callParent([b])},createHistoryCombo:function(){return new SYNO.ux.ComboBox({xtype:"syno_combobox",itemId:"history_combo",width:150,margins:{top:0,right:0,bottom:0,left:10},triggerAction:"all",editable:false,valueField:"history",displayField:"displayText",value:"current",mode:"local",autoScroll:false,hidden:true,store:new Ext.data.ArrayStore({fields:["history","displayText"],data:[["current",_T("rsrcmonitor","realtime")],["day",_T("rsrcmonitor","last_24_hours")],["week",_T("rsrcmonitor","last_7_days")],["month",_T("rsrcmonitor","last_30_days")],["year",_T("rsrcmonitor","last_12_months")]]}),listeners:{select:{scope:this,fn:this.headerChange}}})},createTypeCombo:function(a){return new SYNO.ux.ComboBox({itemId:"type_combo",width:185,margins:{top:0,right:0,bottom:0,left:10},triggerAction:"all",editable:false,mode:"local",autoScroll:false,valueField:"type",displayField:"displayText",value:a[0][0],store:new Ext.data.ArrayStore({fields:["type","displayText"],data:a}),listeners:{select:{scope:this,fn:this.headerChange}}})},createLunCombo:function(){return new SYNO.ux.ComboBox({itemId:"lun_combo",width:185,margins:{top:0,right:0,bottom:0,left:10},triggerAction:"all",editable:false,mode:"local",autoScroll:false,valueField:"uuid",displayField:"displayText",store:new Ext.data.ArrayStore({fields:["uuid",{name:"displayText",sortType:"asNaturalUCString"}],sortInfo:{field:"displayText",direction:"ASC"}}),listeners:{select:{scope:this,fn:this.headerChange}}})},createCustomLabel:function(b,a){return new SYNO.ux.DisplayField({margins:{top:0,right:0,bottom:0,left:20},style:"text-align: right;",value:b+":",hidden:a})},createLunButton:function(c,b,a){return new SYNO.ux.Button({cls:"absolute-left",itemId:"type-button",xtype:"syno_button",margins:{top:0,right:0,bottom:0,left:10},text:c,scope:a,handler:b})},headerChange:function(){var a=this.getContentConfig();this.topLayer.setTimeRange(a.history);this.fireEvent("contentSelect",a)},reloadContent:function(a){if(this.history_combo){this.history_combo.setValue(a.history)}if(this.type_combo){this.type_combo.setValue(a.type)}this.fireEvent("contentSelect",a)},getContentConfig:function(){var a={};if(this.history_combo){a.history=this.history_combo.value}else{a.history="current"}if(this.type_combo){a.type=this.type_combo.value}if(this.lun_combo){a.lun=this.lun_combo.value}return a},setToRealTime:function(){var a=this;if(!a.history_combo){return}a.history_combo.setValue("current");a.headerChange()},onActivate:function(){var a=this.getContentConfig();if(this.history_combo.hidden){return}if(a.history!==this.topLayer.time_range){a.history=this.topLayer.time_range;this.reloadContent(a)}}});Ext.define("SYNO.SDS.ResourceMonitor.Performance.Chart.Current",{extend:"Ext.Panel",totalTime:180,constructor:function(d){var e=this,b={},a,c=0;b={store:[],border:false,topLayer:d.topLayer,dataType:"normal"};Ext.apply(b,d);this.callParent([b]);if(d.lines){for(c=0;c<d.lines.length;++c){a=d.lines[c];e.store.push(new SYNO.SDS.ResourceMonitor.Performance.DataSet({totalTime:e.totalTime,lineType:a.lineType,itemId:a.itemId||"store"+c,color:a.color,trackColor:a.trackColor||a.color,trackOrder:a.trackOrder||0,lineName:a.lineName}))}}},initEvents:function(){var a=this;SYNO.SDS.ResourceMonitor.Performance.Chart.Current.superclass.initEvents.call(this,arguments);a.mon(a,"resize",a.drawChart,a);a.mon(a.topLayer.appWin,"server_change",a.clearStoreData,a)},drawChart:function(){var c=this,b=[],a=0;if(c.isDestroyed||!c.body||c.body.getSize(true).width<=1||c.body.getSize(true).height<=1){return}for(a=0;a<c.store.length;++a){b.push(c.store[a].genSeries())}Flotr.draw(c.body.dom,b,c.getChartType())},updateStores:function(d){var c=this,a=0,b=false;Ext.each(c.store,function(e){b=d.every(function(g,f,h){return e.itemId!==g.itemId});if(b){return false}});if(!b&&d.length===c.store.length){return}c.store=[];for(a=0;a<d.length;++a){c.store.push(new SYNO.SDS.ResourceMonitor.Performance.DataSet({totalTime:c.totalTime,lineType:d[a].lineType,color:d[a].color,itemId:d[a].itemId,lineName:d[a].lineName}))}},pushValueById:function(c,d){var b=this,a=0;Ext.each(c,function(f,e,g){for(a=0;a<b.store.length;++a){if(b.store[a].itemId===f.itemId){b.store[a].pushData(f.value,d);return}}})},pushValue:function(d,e){var c=this,b=0,a=0;for(b=c.store.length-1;b>=0;--b){c.store[b].pushData(d[b]+a,e);if(c.aggregate){a+=d[b]}}},clearStoreData:function(){var b=this,a=0;for(a=b.store.length-1;a>=0;--a){b.store[a].clear()}},getChartType:function(){var d=this,c={},a=0,b=0,e=0;c.mouse={track:true,trackAll:true,position:"nw",sensibility:2,radius:0,lineColor:null,trackFormatter:d.trackFormatter.createDelegate(d),trackStyle:""};c.crosshair={mode:"x",color:"#FA4444",hideCursor:false,lineWidth:2};c.shadowSize=0;a=(d.store[0])?d.store[0].getLastTime():0;b=a-d.totalTime;c.xaxis={min:b,max:a,noTicks:0,minLabelHeight:14};c.grid={verticalLines:false,horizontalLines:true,color:"#b4bec8",outlineWidth:1,backgroundColor:"#f5faff"};switch(d.dataType){case"percent":c.yaxis={min:0,max:100,noTicks:5,minLabelWidth:21,color:"#505a64"};break;case"byte":case"bytes":e=d.getMaxDataValue();if(!Ext.isNumber(e)||e<100*1024){e=100*1024}else{e=e*1.1}c.yaxis={max:e,min:0,tickDecimals:0,noTicks:5,minLabelWidth:32,mode:d.dataType,color:"#505a64"};break;case"timeus":e=d.getMaxDataValue();if(!Ext.isNumber(e)||e<10){e=10}else{e=e*1.1}c.yaxis={max:e,min:0,tickDecimals:0,noTicks:5,minLabelWidth:32,mode:"timeus",color:"#505a64"};break;case"normal":e=d.getMaxDataValue();if(!Ext.isNumber(e)||e<10){e=10}else{e=e*1.1}c.yaxis={max:e,min:0,tickDecimals:0,noTicks:5,minLabelWidth:32,color:"#505a64"};break;default:return}c.y2axis={showLabels:false};if(d.chartTitle){c.title=d.chartTitle;c.titleCls="performance-chart-title"}return c},getMaxDataValue:function(){var c=this,a=0,b=0;for(b=0;b<c.store.length;++b){if(a<c.store[b].getMaxDataValue()){a=c.store[b].getMaxDataValue()}}return a},trackFormatter:function(e){var j=this,g=e.nearest.allSeries,h=e.index,f=[],c,d=0,i=0,k,b=[];if(0===e.index&&e.mx+1<e.x){return""}c=new Date(g[0].data[h][0]*1000);c=SYNO.SDS.DateTimeFormatter(c,{type:"datetimesec"});for(i=g.size()-1;i>=0;--i){f[i]=g[i].data[h][1]-d;if(j.aggregate){d+=f[i]}}for(i=0;i<g.size();++i){if("percent"===j.dataType){k=f[i]+"%"}else{if("byte"===j.dataType){k=Ext.util.Format.fileSize(f[i])}else{if("bytes"===j.dataType){k=Ext.util.Format.fileSize(f[i])+"/s"}else{if("normal"===j.dataType){k=f[i]}else{if("timeus"===j.dataType){var a=j.topLayer.numberUnit(f[i],j.dataType);k=a.num+" "+a.unit}}}}}b.push({name:g[i].lineName,value:k,color:g[i].trackColor||g[i].color,order:g[i].trackOrder||0})}b=b.sort(function(m,l){return(m.order>l.order)?1:-1});return SYNO.SDS.ResourceMonitor.Performance.Chart.Util.getStyledInfoList(c,b)}});Ext.define("SYNO.SDS.ResourceMonitor.Performance.Chart.History",{extend:"Ext.Panel",aggregate:false,lines:[],timeAxis:"day",dataType:"percent",dataBase:1,data:{},dataSize:0,constructor:function(b){var a={topLayer:b.topLayer,border:false};Ext.apply(a,b);this.callParent([a])},initEvents:function(){var a=this;SYNO.SDS.ResourceMonitor.Performance.Chart.History.superclass.initEvents.call(this,arguments);a.mon(a,"resize",function(){if(a.data){a.drawChart()}},a)},setChartConfig:function(a){var b=this;if(!a){return false}if(Ext.isDefined(a.aggregate)){b.aggregate=a.aggregate}if(Ext.isDefined(a.lines)){b.lines=a.lines}if(Ext.isDefined(a.timeAxis)){b.timeAxis=a.timeAxis}if(Ext.isDefined(a.dataType)){b.dataType=a.dataType}if(Ext.isDefined(a.dataBase)){b.dataBase=a.dataBase}if(Ext.isDefined(a.data)){b.data=a.data}if(Ext.isDefined(a.dataSize)){b.dataSize=a.dataSize}if(Ext.isDefined(a.endTime)){b.endTime=a.endTime}if(Ext.isDefined(a.timeInterval)){b.timeInterval=a.timeInterval}if(Ext.isDefined(a.chartTitle)){b.chartTitle=a.chartTitle}else{b.chartTitle=null}},drawChart:function(){var b=this,c=0,a;if(b.isDestroyed||!b.body||b.body.getSize(true).width<=1||b.body.getSize(true).height<=1){return}a=b.genSeries();c=b.getMaxDataValue(a);Flotr.draw(b.body.dom,a,b.getChartType(c))},genSeries:function(){var m=this,g=[],f=m.data,h=0,e=0,n=m.lines.length,d=[],k,c=new Date(),a=m.endTime,l=c.getTimezoneOffset()*60,b=1;if("bytes"===m.dataType){b=m.dataBase}if(m.aggregate){f=m.aggregateData()}for(h=0;h<n;++h){d=[];k=m.lines[h].itemId;a=m.endTime;if(!Ext.isDefined(f[k])){continue}for(e=f[k].size()-1;e>=0;--e){d.push([(a-l)*1000,f[k][e]*b]);a-=m.timeInterval}g.push({data:d.reverse(),lines:m.lines[h].lineType,color:m.lines[h].color,lineName:m.lines[h].lineName,trackColor:m.lines[h].trackColor||m.lines[h].color,trackOrder:m.lines[h].trackOrder||0})}return g},aggregateData:function(){var d=this,c=0,b=0,a=d.lines.length,f=0,e=SYNO.Util.copy(d.data);for(c=0;c<d.dataSize;++c){f=0;for(b=a-1;b>=0;--b){f+=e[d.lines[b].itemId][c];e[d.lines[b].itemId][c]=f}}return e},getChartType:function(c){var b=this,a={};a.mouse={track:true,trackAll:true,position:"nw",sensibility:2,radius:0,lineColor:null,trackFormatter:b.trackFormatter.createDelegate(b),trackStyle:""};a.crosshair={mode:"x",color:"#FA4444",hideCursor:false,lineWidth:2};a.shadowSize=0;a.grid={verticalLines:false,horizontalLines:true,color:"#b4bec8",outlineWidth:1,backgroundColor:"#f5faff"};switch(b.timeAxis){case"day":a.xaxis={mode:"time",timeFormat:"%H",noTicks:12,minLabelHeight:14};break;case"week":a.xaxis={mode:"time",timeFormat:"%d",noTicks:7,minLabelHeight:14};break;case"month":a.xaxis={mode:"time",timeFormat:"%d",noTicks:15,minLabelHeight:14};break;case"year":a.xaxis={mode:"time",timeFormat:"%b",noTicks:12,minLabelHeight:14};break;default:return}switch(b.dataType){case"percent":a.yaxis={min:0,max:100,minLabelWidth:21,noTicks:5,color:"#505a64"};break;case"byte":case"bytes":if(!Ext.isNumber(c)||c<100*1024){c=100*1024}else{c=c*1.1}a.yaxis={max:c,min:0,tickDecimals:0,noTicks:5,minLabelWidth:32,mode:b.dataType,color:"#505a64"};break;case"timeus":if(!Ext.isNumber(c)||c<10){c=10}else{c=c*1.1}a.yaxis={max:c,min:0,tickDecimals:0,noTicks:5,minLabelWidth:32,mode:"timeus",color:"#505a64"};break;case"normal":if(!Ext.isNumber(c)||c<10){c=10}else{c=c*1.1}a.yaxis={max:c,min:0,tickDecimals:0,noTicks:5,minLabelWidth:32,color:"#505a64"};break;default:return}a.y2axis={showLabels:false};if(b.chartTitle){a.title=b.chartTitle;a.titleCls="performance-chart-title"}return a},getMaxDataValue:function(d){var c=0,b=0,a=0;for(c=0;c<d.length;++c){for(b=0;b<d[c].data.length;++b){if(a<d[c].data[b][1]){a=d[c].data[b][1]}}}return a},trackFormatter:function(e){var k=this,g=e.nearest.allSeries,h=e.index,f=[],d=0,i=0,c=new Date(),j=c.getTimezoneOffset()*60*1000,b=[],l;for(i=g.size()-1;i>=0;--i){f[i]=g[i].data[h][1]-d;if(k.aggregate){d+=f[i]}}for(i=0;i<g.size();++i){if("percent"===k.dataType){l=f[i]+"%"}else{if("byte"===k.dataType){l=Ext.util.Format.fileSize(f[i])}else{if("bytes"===k.dataType){l=Ext.util.Format.fileSize(f[i])+"/s"}else{if("normal"===k.dataType){l=f[i]}else{if("timeus"===k.dataType){var a=k.topLayer.numberUnit(f[i],k.dataType);l=a.num+" "+a.unit}}}}}b.push({name:g[i].lineName,color:g[i].trackColor||g[i].color,order:g[i].trackOrder||0,value:l})}b=b.sort(function(n,m){return(n.order>m.order)?1:-1});c=new Date(g[0].data[h][0]+j);c=SYNO.SDS.DateTimeFormatter(c,{type:"datetime"});return SYNO.SDS.ResourceMonitor.Performance.Chart.Util.getStyledInfoList(c,b)}});SYNO.SDS.ResourceMonitor.Performance.Chart.Util={getStyledInfoList:function(b,d){var c,a;c='<table class="info-list-table">';c+='<tr><td class="info-list-top-l"></td><td colspan="2" class="info-list-top-m"></td><td class="info-list-top-r"></td></tr>';c+='<tr><td class="info-list-time-l"></td><td colspan="2" class="info-list-time-text">'+b+'</td><td class="info-list-time-r"></td></tr>';for(a=0;a<d.size();++a){c+='<tr style="color:'+d[a].color+'"><td class="info-list-content-l"></td><td class="info-list-content-name">'+d[a].name+'</td><td align="right" class="info-list-content-value">'+d[a].value+'</td><td class="info-list-content-r"></td></tr>'}c+='<tr><td class="info-list-bottom-l"></td><td colspan="2" class="info-list-bottom-m"></td><td class="info-list-bottom-r"></td></tr>';c+="</table>";return c}};Ext.define("SYNO.SDS.ResourceMonitor.Performance.DataSet",{extend:"Ext.util.Observable",constructor:function(b){this.data=[];var a=Ext.apply({totalTime:180,lineType:{}},b);Ext.apply(this,a);this.callParent([a])},pushData:function(d,e){var c=this,a=e-c.totalTime,b=0;if(c.getLastTime()>=e){c.data=[]}c.data.push([e,d]);for(b=0;c.data[b][0]<a;++b){}if(2<=b){c.data=c.data.slice(b-2)}},genSeries:function(){var a=this;return{data:a.data,lines:a.lineType,lineName:a.lineName,color:a.color,trackColor:a.trackColor||a.color,trackOrder:a.trackOrder||1}},getLastTime:function(){var a=this;if(a.data.length>0){return a.data[a.data.length-1][0]}else{return 0}},getMaxDataValue:function(){var b=this,c=0,a=0;for(a=0;a<b.data.length;++a){if(b.data[a][1]>c){c=b.data[a][1]}}return c},clear:function(){this.data.clear()},getLastDataValue:function(){if(this.data.last()){return this.data.last()[1]}return 0}});Ext.ns("SYNO.SDS.ResourceMonitor");Ext.define("SYNO.SDS.ResourceMonitor.MiniWidget",{extend:"SYNO.SDS._SystemTray.Component",constructor:function(a){var b=this;a=Ext.apply(a,{baseCls:"resource-monitor-widget-mini",height:24});b.callParent(arguments)},onRender:function(c,a){var d=this,b=new Ext.Template('<div class="{cls}">','<div class="{cls}-wrap">','<div class="{cls}-cpu">','<div class="{cls}-cpu-text">',"</div>",'<div class="{cls}-cpu-bar">','<div class="{cls}-cpu-value">',"</div>","</div>",'<div class="x-clear"></div>',"</div>",'<div class="{cls}-mem">','<div class="{cls}-mem-text">',"</div>",'<div class="{cls}-mem-bar">','<div class="{cls}-mem-value">',"</div>","</div>",'<div class="x-clear"></div>',"</div>","</div>",'<div class="{cls}-wrap">','<div class="{cls}-upload">','<div class="{cls}-upload-text">',"</div>",'<div class="{cls}-upload-value">',"</div>",'<div class="x-clear"></div>',"</div>",'<div class="{cls}-download">','<div class="{cls}-download-text">',"</div>",'<div class="{cls}-download-value">',"</div>",'<div class="x-clear"></div>',"</div>","</div>","</div>");d.el=a?b.insertBefore(a,{cls:d.baseCls},true):b.append(c,{cls:d.baseCls},true);if(d.id){d.el.dom.id=d.id}d.memValueBar=d.el.child(String.format("div.{0}-mem-value",d.baseCls));d.cpuValueBar=d.el.child(String.format("div.{0}-cpu-value",d.baseCls));d.uploadValue=d.el.child(String.format("div.{0}-upload-value",d.baseCls));d.downloadValue=d.el.child(String.format("div.{0}-download-value",d.baseCls));d.callParent(arguments)},afterRender:function(){var a=this;a.callParent(arguments);a.setCpuValue(0);a.setMemValue(0)},setCpuValue:function(a){this.setValueBar(a,this.cpuValueBar)},setMemValue:function(a){this.setValueBar(a,this.memValueBar)},setUploadValue:function(b,a){this.setTransferValue(this.uploadValue,b,a)},setDownloadValue:function(b,a){this.setTransferValue(this.downloadValue,b,a)},setTransferValue:function(f,g,h){var a=[],b=0,c="",e='<div class="num-{0}" ext:qtip="{1}"></div>',d='<div class="unit-{0}" ext:qtip="{1}"></div>',k="",j="";g=Ext.isNumber(g)?g:0;h=Ext.isString(h)?h:"KB";g+="";a=g.split("");k=Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(g+" "+h));for(b=0;b<a.length;b++){j=a[b];if(j==="."){j="dot"}c+=String.format(e,Ext.util.Format.htmlEncode(j),k)}c+=String.format(d,h,k);f.set({"ext:qtip":k});f.update(c)},setValueBar:function(c,b){var a=b.parent().getWidth();c=Ext.isNumber(c)?Math.min(c,100):100;b.removeClass(["high","very-high"]);if(c>90){b.addClass("very-high")}else{if(c>80){b.addClass("high")}}b.setWidth(a*c/100);b.set({"ext:qtip":Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(c))+"&#37;"});b.parent().set({"ext:qtip":Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(c))+"&#37;"})}});SYNO.SDS.ResourceMonitor.WidgetBriefChartMaxTime=3*60;SYNO.SDS.ResourceMonitor.PollingInterval=5;SYNO.SDS.ResourceMonitor.Widget=Ext.extend(Ext.Panel,{prevText:_JSLIBSTR("extlang","prevpage"),nextText:_JSLIBSTR("extlang","nextpage"),layout:"vbox",style:"padding-top: 8px",activeNetworkTrafficIndex:0,cls:"resource-monitor-widget",minimizable:true,toggleButtonCls:SYNO.SDS.ResourceMonitor.MiniWidget,taskButton:undefined,constructor:function(a){var b=SYNO.SDS.UserSettings.getProperty("SYNO.SDS._Widget.Instance","restoreParams"),c=b&&b.windowState&&b.windowState.widgets?b.windowState.widgets:[];Ext.each(c,function(d){if(d.widgetClassName==="SYNO.SDS.ResourceMonitor.Widget"&&d.widgetParams){this.activeNetworkTrafficIndex=d.widgetParams.networkInterfaceIdx||0;return false}},this);SYNO.SDS.ResourceMonitor.Widget.superclass.constructor.apply(this,arguments);this.initPanels()},onActivate:function(){this.isActive=true;if(this.pollTaskID){this.networkCharts.items.each(function(a){a.clearValues()})}this.startPollingTask();this.mask(_T("common","loading"))},onDeactivate:function(){this.isActive=false;this.stopPollingTask()},getDefChartCfg:function(){return{collapsed:false,baseCls:"resource-Monitor-widget-panel",totalRecords:SYNO.SDS.ResourceMonitor.BriefTotalRecords}},getStateParam:function(){return{networkInterfaceIdx:this.activeNetworkTrafficIndex}},startPollingTask:function(){var a=this;if(a.pollTaskID){return}a.pollTaskID=a.pollReg({webapi:{api:"SYNO.Core.System.Utilization",method:"get",version:1,params:{type:"current",resource:["cpu","memory","network"]}},immediate:true,interval:SYNO.SDS.ResourceMonitor.PollingInterval,scope:a,status_callback:a.onAjaxRequestDone})},stopPollingTask:function(){if(this.pollTaskID){this.pollUnreg(this.pollTaskID);this.pollTaskID=undefined}},mask:Ext.emptyFn,unmask:Ext.emptyFn,initPanels:function(){this.cpuChart=this.initCpuChart();this.memChart=this.initMemChart();this.networkCharts=this.initNetworkPanel();this.networkIOCmp=this.initNetworkIOCmp();this.add([this.cpuChart,this.memChart,this.networkIOCmp,this.networkCharts]);this.doLayout()},initNetworkIOCmp:function(){return new SYNO.SDS.ResourceMonitor.NetworkInOutComponent({widget:this,selBtnWidth:96,width:320,height:24})},initCpuChart:function(){return new SYNO.SDS.ResourceMonitor.PercentageComponent(Ext.apply(this.getDefChartCfg(),{itemId:"cpuUsage",title:"CPU",width:322,height:24}))},doCollapse:function(){var a=this;a.getEl().setHeight(84);a.doLayout()},doExpand:function(){var a=this;a.getEl().setHeight(172);a.doLayout()},initMemChart:function(){return new SYNO.SDS.ResourceMonitor.PercentageComponent(Ext.apply(this.getDefChartCfg(),{itemId:"memoryUsage",title:"RAM",width:322,height:24}))},setActivePanel:function(){var c=this,b=c.networkCharts.get(c.activeNetworkTrafficIndex),a=c.networkCharts.getLayout();if(!b){c.activeNetworkTrafficIndex=0}c.networkIOCmp.selBtn.setText(b.deviceName);a.setActiveItem(c.activeNetworkTrafficIndex);c.networkCharts.get(c.activeNetworkTrafficIndex).drawChart();c.updateNetworkIOValue()},initNetworkPanel:function(){var a=new Ext.Panel(Ext.apply(this.getDefChartCfg(),{layout:"card",itemId:"network",activeItem:0,collapsible:false,border:false,defaults:{border:false},columnWidth:1}));return a},onAjaxRequestDone:function(a,f,g,e){var d=this,b=0,c=null;if(d.isDestroyed||!a){return}d.unmask();b=f.cpu.user_load+f.cpu.system_load;d.cpuChart.setValue(b);d.memChart.setValue(f.memory.real_usage);d.updateNetworkCharts(f.network,f.time);if(d.taskButton){c=d.networkIOCmp;d.taskButton.setMemValue(f.memory.real_usage);d.taskButton.setCpuValue(b);d.taskButton.setUploadValue(c.getConvertSize(c.TxValue),c.getUnit(c.TxValue));d.taskButton.setDownloadValue(c.getConvertSize(c.RxValue),c.getUnit(c.RxValue));d.taskButton.updateLayout()}},updateNetworkCharts:function(d,e){var c=this,b=c.networkCharts,a;if(_S("ha_running_xa")){c.removeNTBInterfaces(d)}c.updateNetworkInterfaces(d);Ext.each(d,function(f){a=b.get(f.device);if(a){a.pushValue([f.tx,f.rx],e)}},c);c.updateNetworkIOValue()},removeNTBInterfaces:function(b){var c,a;c=b.find(function(d){return"total"===d.device});a=b.find(function(d){return"ntb_eth0"===d.device});if(c&&a){c.rx=c.rx-a.rx;c.tx=c.tx-a.tx;b.remove(a)}},updateNetworkIOValue:function(){var d=this,c=d.networkIOCmp,b=d.networkCharts,a=b.get(d.activeNetworkTrafficIndex);if(!a){return}c.update(a.RxSet.getLastDataValue(),a.TxSet.getLastDataValue())},updateNetworkInterfaces:function(s){var o=this,g=o.networkCharts,m=false,f=0,e=0,c=0,b,a,r=[];g.items.each(function(i){var j=Ext.each(s,function(k){if(k.device===i.itemId){return false}return true});if(!Ext.isDefined(j)){r.push(i)}});Ext.each(r,function(i){g.remove(i)});var d=this.networkIOCmp.selMenu;var l;var n=function(i){return parseInt(i.replace(/[^\d.]/g,""),10)||0};var p=function(j,i){for(c=i.length-1;c>=0;c--){if(n(j)>=n(i[c].text)){return c+1}}};for(f=0,e=0;f<s.length;++f){if("total"===s[f].device){continue}b=g.get(s[f].device);if(!b){l=SYNO.SDS.Utils.Network.idToString(s[f].device);a=new SYNO.SDS.ResourceMonitor.Widget.NetworkInterface({itemId:s[f].device,deviceName:l,widget:this});g.insert(e,a);m=true;var h=new Ext.menu.Item({text:l,index:(d.items)?d.items.items.length:0,scope:this,hidden:false});var q=(d.items)?p(l,d.items.items):0;d.insert(q,h)}e++}if(m||r.size()>0){this.setActivePanel();this.doLayout()}}});SYNO.SDS.ResourceMonitor.NetworkInOutComponent=Ext.extend(Ext.Panel,{RxValue:0,TxValue:0,constructor:function(a){Ext.apply(this,a);SYNO.SDS.ResourceMonitor.NetworkInOutComponent.superclass.constructor.call(this,this.fillConfig());this.mon(this,"afterrender",function(){this.drawChart()},this);this.inLabel=this.getComponent("in");this.outLabel=this.getComponent("out")},fillConfig:function(){this.selBtn=new SYNO.ux.Button({itemId:"select-button",xtype:"syno_button",boxMaxWidth:90,cls:"interface-selection-button",menuAlign:"tr-br",menu:this.selMenu=new Ext.menu.Menu({cls:"resource-monitor-widget",listeners:{itemclick:{fn:this.onMenuClick,scope:this}}})});var a={cls:"resource-Monitor-networkio-cmp",width:this.width,height:this.height,border:false,items:[{xtype:"container",width:this.selBtnWidth,height:24,items:[this.selBtn],style:"float: left;"},{itemId:"out-graphic",xtype:"displayfield",cls:"networkio-cmp-icon out"},{itemId:"out",xtype:"displayfield",cls:"networkio-cmp-label blue-status out",value:0+"KB/s"},{itemId:"in-graphic",xtype:"displayfield",cls:"networkio-cmp-icon in"},{itemId:"in",xtype:"displayfield",cls:"networkio-cmp-label green-status",value:0+"KB/s"}]};return a},onMenuClick:function(a){this.widget.activeNetworkTrafficIndex=a.index;this.widget.setActivePanel()},update:function(c,a){var b=this;b.TxValue=a;b.RxValue=c;b.drawChart()},drawChart:function(){var a=this;a.inLabel.setValue(this.convertSize(a.RxValue));a.outLabel.setValue(this.convertSize(a.TxValue));a.doLayout()},convertSize:function(a){var b=this.getUnit(a)+"/s";return this.getConvertSize(a)+" "+b},getConvertSize:function(b){if(!b){return 0}var a=parseInt(Math.floor(Math.log(b)/Math.log(1024)),10);if(a===0){return(b/Math.pow(1024,a))}return parseFloat((b/Math.pow(1024,a)).toFixed(1))},getUnit:function(b){if(!b){return"KB"}var c=["KB","MB","GB","TB","PB","EB","ZB","YB"];var a=parseInt(Math.floor(Math.log(b)/Math.log(1024)),10);return c[a]}});SYNO.SDS.ResourceMonitor.Widget.NetworkInterface=Ext.extend(Ext.Panel,{constructor:function(b){this.RxSet=new SYNO.SDS.ResourceMonitor.Performance.DataSet({totalTime:SYNO.SDS.ResourceMonitor.WidgetBriefChartMaxTime,color:"#1EB300"});this.TxSet=new SYNO.SDS.ResourceMonitor.Performance.DataSet({totalTime:SYNO.SDS.ResourceMonitor.WidgetBriefChartMaxTime,color:"#0086E6"});this.chart=new Ext.Container({baseCls:"resource-Monitor-widget-base",cls:"flotrchart-wrapper"});this.deviceName=b.deviceName;var a={baseCls:"resource-Monitor-widget-panel",border:false,width:250,items:[{xtype:"panel",baseCls:"resource-Monitor-widget-base",height:92,items:[this.chart]}]};Ext.apply(a,b);SYNO.SDS.ResourceMonitor.Widget.NetworkInterface.superclass.constructor.call(this,a)},pushValue:function(b,d){var a=Math.round(b[0]/1024),c=Math.round(b[1]/1024);this.TxSet.pushData(a,d);this.RxSet.pushData(c,d);this.drawChart()},drawChart:function(){var a=0;a=this.RxSet.getMaxDataValue();if(a<this.TxSet.getMaxDataValue()){a=this.TxSet.getMaxDataValue()}if(a<100){a=100}else{a=a*1.1}var c={lines:{show:true},xaxis:{max:this.RxSet.getLastTime(),min:this.RxSet.getLastTime()-this.RxSet.totalTime,noTicks:0},yaxis:{max:a,min:0,tickDecimals:0,noTicks:5},grid:{color:"#E1EBF5",backgroundColor:"#FFFFFF",tickColor:"#E1EBF5",labelMargin:10,outlineWidth:1},shadowSize:0};var b=[this.RxSet.genSeries(),this.TxSet.genSeries()];if(this.chart.getWidth()>0&&this.chart.getHeight()>0){Flotr.draw(this.chart.getEl().dom,b,c)}},clearValues:function(){this.RxSet.clear();this.TxSet.clear()}});Ext.define("SYNO.SDS.ResourceMonitor.PercentageComponent",{extend:"Ext.BoxComponent",title:"",value:0,type:"horizontal",constructor:function(a){Ext.apply(this,a);SYNO.SDS.ResourceMonitor.PercentageComponent.superclass.constructor.call(this,this.fillConfig())},fillConfig:function(a){var b={width:this.width,height:this.height,layout:"column",cls:"resource-monitor-percentage-cmp "+this.type,autoEl:{tag:"div",cn:[{tag:"div",cls:"percentage-cmp-title",html:this.title},{tag:"div",cls:"percentage-cmp-hbar-background",cn:[{tag:"div",cls:"percentage-cmp-hbar-fill"}]},{tag:"div",cls:"percentage-cmp-value",html:this.value+"%"}]}};return b},setValue:function(a){this.value=a;this.fillPercent(a)},fillPercent:function(d){var b=this.el.child("div.percentage-cmp-value");var c=this.el.child("div.percentage-cmp-hbar-fill");var f=this.el.child("div.percentage-cmp-hbar-background");var e=d*1.5;var a=d*0.74;c.removeClass("high");c.removeClass("very-high");if(d>90){c.addClass("very-high")}else{if(d>80){c.addClass("high")}}b.update(d+"%");if(this.type==="vertical"){c.dom.style.height=a+"px"}else{c.dom.style.width=e+"px"}c.dom.setAttribute("ext:qtip",d+"%");f.dom.setAttribute("ext:qtip",d+"%")}});