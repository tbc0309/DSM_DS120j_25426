/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.SystemInfoApp");SYNO.SDS.SystemInfoApp.RecentLogWidget=Ext.extend(SYNO.SDS._Widget.GridPanel,{usewebapi:true,constructor:function(a){Ext.apply(a,{loadMask:false});SYNO.SDS.SystemInfoApp.RecentLogWidget.superclass.constructor.apply(this,arguments)},actionRender:function(b){var a=b;if(b==="download"){a=_WFT("filetable","filetable_download")}else{if(b==="upload"){a=_WFT("filetable","filetable_upload")}else{if(b==="delete"){a=_WFT("filetable","filetable_delete")}else{if(b==="rename"){a=_WFT("filetable","filetable_rename")}else{if(b==="move"){a=_WFT("filetable","filetable_move")}else{if(b==="copy"){a=_WFT("filetable","filetable_copy")}else{if(b==="property set"){a=_WFT("filetable","filetable_propertyset")}else{if(b==="property sets"){a=_WFT("filetable","filetable_propertyset")}else{if(b==="mkdir"){a=_WFT("filetable","filetable_create_folder")}}}}}}}}}return a},descRenderer:function(e,b,d){var c=this.actionRender(d.data.cmd||"");if(d.data.cmd){c+=":&nbsp;"}var a=Ext.util.Format.htmlEncode(e);b.attr='ext:qtip="'+(c+Ext.util.Format.htmlEncode(a))+'"';return c+a},LogLevelRenderer:function(a){if(a=="warn"){return'<div class="sds-recentlog-loglevel log-warn">&nbsp;</div>'}else{if(a=="err"){return'<div class="sds-recentlog-loglevel log-err">&nbsp;</div>'}else{return'<div class="sds-recentlog-loglevel log-info">&nbsp;</div>'}}},getColumnModel:function(){if(this.cmSystemLog){return this.cmSystemLog}var a=new Ext.grid.ColumnModel({columns:[{dataIndex:"llevel",width:38,align:"center",renderer:this.LogLevelRenderer.createDelegate(this)},{id:"msg",width:252,dataIndex:"msg",css:"white-space:normal;",renderer:this.descRenderer.createDelegate(this)}]});this.cmSystemLog=a;return a},getStore:function(){if(this.dsSystemLog){return this.dsSystemLog}var a=new SYNO.API.JsonStore({api:"SYNO.Core.SyslogClient.Status",version:"1",method:"latestlog_get",appWindow:this.appWin,baseParams:{start:0,limit:this.TotalRecords,widget:true,dir:"desc"},root:"logs",fields:["llevel","ltime","msg","utcsec"],autoDestroy:false,autoLoad:false,sortInfo:{field:"utcsec",direction:"DESC"}});this.dsSystemLog=a;this.addManagedComponent(a);return a}});