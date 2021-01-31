/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.ns("SYNO.SDS.SystemInfoApp");SYNO.SDS.SystemInfoApp.StorageUsageWidget=Ext.extend(Ext.Panel,{isUSBStation:null,supportBuildinStorage:null,widgetLayout:"fit",toggleButtonCls:SYNO.SDS._Widget.MiniWidget,charts:[],constructor:function(a){this.individualVols=[];this.storageGrid=new SYNO.SDS._Widget.GridPanel({itemId:"storageGrid",cls:"sds-widget-gridpanel sys-storage-grid",store:this.store=this.getStorageDataStore(),cm:this.getStorageColumnModel(a),autoLoad:false,autoDestroy:false,listeners:{afterrender:{fn:this.activateStorageView,scope:this,single:true,buffer:80}}});this.isUSBStation=("yes"===_D("usbstation","no"));this.supportBuildinStorage=("yes"===_D("support_buildin_storage","no"));this.cgiHandler=this.jsConfig.jsBaseURL+"/SystemInfo.cgi";var b=Ext.apply(this.getConfig(),a);SYNO.SDS.SystemInfoApp.StorageUsageWidget.superclass.constructor.call(this,b);this.volinfos=null;this.isActive=false;this.mon(this.store,"load",this.drawPieChart,this)},getConfig:function(){return{border:false,layout:"fit",defaults:{border:false},items:[this.storageGrid]}},activateStorageView:function(){var a=null;var b={};a=this.cgiHandler;b={query:"storage"};this.pollTask=this.pollTask||this.addAjaxTask({id:"storage_widget_pooling_task",interval:60*1000,url:a,params:b,method:"POST",success:this.loadStorageInfo,failure:function(c,d){SYNO.Debug("Ajax load failure "+c.responseText)},scope:this});if(this.isActive){this.mask(_T("common","loading"));this.pollTask.start()}},drawPieChart:function(h,b,j){var f=this,c=0,e=null,a=null,g=null,d=null;if(f.charts){Ext.each(f.charts,function(i){i.destroy()});f.charts=[]}for(c=0;c<b.length;c++){d=b[c].get("storageVolInfo");a=Ext.get("widget-storage-"+f.getEl().id+d.volume);if(!a){continue}e=new SYNO.SDS.Utils.canvas.ColorCircleGradient({width:64,height:64,renderTo:a.getAttribute("id"),cls:""});g=parseInt(d.total_size,10);e.draw(Math.min(parseInt(d.used_size,10)/g,1));f.charts.push(e)}},loadStorageInfo:function(b,h){if(!this.isActive){return}var g=Ext.decode(b.responseText);var a=null;var f,c;var e=null;var d=0;if(this.isUSBStation){a=[];for(f=0;g.devices&&f<g.devices.length;++f){e=g.devices[f];if(e.partitions&&e.partitions.length>0){for(c=0;c<e.partitions.length;++c){if(!Ext.isDefined(e.partitions[c].share_name)||Ext.isEmpty(e.partitions[c].share_name)){continue}a.push({status:e.partitions[c].status,total_size:parseInt(e.partitions[c].total_size_mb,10)*1024*1024,used_size:parseInt(e.partitions[c].used_size_mb,10)*1024*1024,volume:e.partitions[c].share_name,volstr:e.partitions[c].share_name});++d}}else{++d}}}else{a=g.vol_info}if(a===null||a===""){a=[]}if(this.supportBuildinStorage&&this.isUSBStation){a.unshift({status:g.vol_info[0].status,total_size:g.vol_info[0].total_size,used_size:g.vol_info[0].used_size,volume:g.vol_info[0].volume,volstr:_T("system","system_volume")})}d=a.length;if(this.isDestroyed){return}this.total_vols=d;this.volinfos=a;this.volinfos.sort(function(j,i){var l,k;if(-1<j.volume.indexOf("volume")&&-1===i.volume.indexOf("volume")){return -1}if(-1===j.volume.indexOf("volume")&&-1<i.volume.indexOf("volume")){return 1}if(-1<j.volume.indexOf("volume")&&-1<i.volume.indexOf("volume")){if(parseInt(j.volume.replace("volume_",""),10)>parseInt(i.volume.replace("volume_",""),10)){return 1}else{return -1}}l=j.volume.replace("usbshare","").replace("-","");k=i.volume.replace("usbshare","").replace("-","");while(l.length<4){l+="0"}while(k.length<4){k+="0"}if(l>k){return 1}return -1});this.loadInfo()},onActivate:function(){this.isActive=true;var a=this.pollTask;if(a){a.start()}},onDeactivate:function(){this.isActive=false;var a=this.pollTask;if(a){a.stop()}this.unmask()},mask:function(a){this.getEl().mask(a)},unmask:function(){this.getEl().unmask()},getStorageColumnModel:function(b){if(this.cmSystemLog){return this.cmSystemLog}var a=new Ext.grid.ColumnModel({columns:[{dataIndex:"storageVolInfo",width:b.cmWidth||290,renderer:function(f,e,c){var d=this.convertPieChartConfig(f,f.total_size||1,f.used_size||0,0);d.volume=f.volume;var g=this.getChartDisplayText(d);return g},scope:this}]});this.cmSystemLog=a;return a},getStorageDataStore:function(){if(this.dsSystemLog){return this.dsSystemLog}var a=new Ext.data.Store({reader:new Ext.data.ArrayReader({},[{name:"id"},{name:"storageVolInfo"}])});this.dsSystemLog=a;return a},loadInfo:function(){var b=this.total_vols||0;if(0===b){this.mask(_T("volume","volume_novolume"))}else{this.unmask()}this.individualVols=[];for(var a=0;a<this.total_vols;a++){this.individualVols.push([a,this.volinfos[a]])}this.storageGrid.store.loadData(this.individualVols)},doLoad:function(){if(this.rendered){this.mask();this.loadInfo();this.unmask()}},drawPie:function(a,k,b,g){var e=0;var h=0;var l=a.items.getCount();var d,f={};b=b?b:1;if(l!=b){a.removeAll();var j=a.getHeight();for(e=0;e<b;e++){var c=new Ext.Container({autoEl:{tag:"div"},columnWidth:1/this.NUM_REC_PER_PAGE,height:j,layout:"hbox"});a.add(c)}a.doLayout()}for(e=0;e<k.length;e++){if(e<g.start||e>=g.end){continue}d=k[e];f=this.convertPieChartConfig(d,d.total_size||1,d.used_size||0,h);this.creatFlotrPieChart(f);++h}},convertPieChartConfig:function(d,e,j,g){var b={};var h=SYNO.SDS.Utils.StorageUtils;var f,i;var a="";a=d.volstr||h.SpaceIDParser(d.volume).str||"";f=parseInt(e,10);i=parseInt(j,10);var c=null;if(this.isUSBStation){c=SYNO.SDS.Utils.ExternalDevices.getStatus(d.status)}else{c=h.UiRenderHelper.StatusNameRender(d.status)}b={volstr:a,diskUsed:i,diskAvailable:f-i,diskTotal:f,volStatus:c};return b},getTooltip:function(a){var b=String.format("{0}{1} {2} {3}",_T("volume","volume_totalsize"),_T("common","colon"),a.total.toFixed(2),_T("common","size_gb"));return String.format("{0}",String.format("{0}<br>{1}<br>{2}",b,a.usedText,a.freeText))},getOverlayContainer:function(b,d,a){var e=String.format("{0}{1} {2} {3}",_T("volume","volume_totalsize"),_T("common","colon"),b.total.toFixed(2),_T("common","size_gb"));var c=String.format('<div ext:qtip="{0}" style="height:{1}px; width:{2}px;"></div>',String.format("{0}<br>{1}<br>{2}",e,b.usedText,b.freeText),a,d);if(this.overlay){this.overlay.update(c)}else{this.overlay=new Ext.Component({autoEl:"div",height:a,width:d,html:c,cls:"syno-sysinfo-storage-usage-chart-oveylay"})}return this.overlay},encode:function(a){return Ext.util.Format.htmlEncode(a)},formatSize:function(a){return Ext.util.Format.fileSize(a)},getChartDisplayText:function(d){var b=this.getEl().id+d.volume;var f=String.format("{0} ({1})",d.volstr,d.volStatus);var c=this.formatSize(d.diskUsed);var a=this.formatSize(d.diskAvailable);var e=String.format('<div><div class = "syno-sysinfo-storage-usage-chart-pie" id="widget-storage-{0}"> </div><div class = "syno-sysinfo-storage-usage-chart-text"><div class = "syno-sysinfo-storage-usage-chart-title" ext:qtip="{1}">{2}</div><div class = "syno-sysinfo-storage-usage-chart-info" ext:qtip="{3}: {4}">{3}: {4}</div><div class = "syno-sysinfo-storage-usage-chart-info" ext:qtip="{5}: {6}">{5}: {6}</div></div></div>',this.encode(b),this.encode(f),f,_T("volume","volume_usedsize"),this.encode(c),_T("volume","volume_freesize"),this.encode(a));return e}});