/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.SystemInfoApp");Ext.define("SYNO.SDS.SystemInfoApp.FileChangeLogWidget",{extend:"SYNO.SDS._Widget.GridPanel",addCmds:["put","upload","write","create","mkdir"],editCmds:["move","copy","rename","property set","property sets"],deleteCmds:["delete"],noLinkCmds:["delete","move","rename"],logType:"ftp,filestation,webdav,cifs,tftp,afp",usewebapi:true,constructor:function(a){Ext.apply(a,{loadMask:false});this.callParent([a]);this.mon(this,"cellclick",this.onGridCellClick,this,{buffer:100})},onGridCellClick:function(b,g,h,i){var c=b.getColumnModel().getIndexById("descr");var f=i.getTarget("div",1,true);var k;if(!f||!f.hasClass("syno-sysinfo-file-change-log-link")){return}k=this.dsSystemLog.getAt(g);if(h===c){var d=k.get("username");var e=k.get("descr");var j=" -> ";var a=e.indexOf(j);if(a!==-1){e=e.slice(a+j.length)}a=e.indexOf("/");if(a!==-1){e=e.substr(a)}if(true===_S("is_admin")){if(d!==_S("user")&&e.substr(0,6)==="/home/"){e=e.slice(0,5);e="/homes/"+d+e}}SYNO.SDS.AppLaunch("SYNO.SDS.App.FileStation3.Instance",{openfile:e});return false}},descRenderer:function(e,b,d){var c=d.data.cmd;var a=Ext.util.Format.htmlEncode(e);b.attr+='ext:qtip="'+(Ext.util.Format.htmlEncode(a))+'"';if(this.noLinkCmds.indexOf(c)===-1){a=String.format('<div class = "syno-sysinfo-file-change-log-link">{0}</div>',a)}return a},usernameRenderer:function(b,a){return'<div class = "syno-sysinfo-username"></div>'},actionIconRenderer:function(e,a,d){var c,b=d.data.cmd;if(this.addCmds.indexOf(b)!==-1){c="add"}else{if(this.editCmds.indexOf(b)!==-1){c="edit"}else{if(this.deleteCmds.indexOf(b)!==-1){c="delete"}}}return String.format('<div class = "syno-sysinfo-file-change-log {0}"></div>',c)},getColumnModel:function(){if(this.cmSystemLog){return this.cmSystemLog}var a=new Ext.grid.ColumnModel({columns:[{dataIndex:"descr",width:38,renderer:this.actionIconRenderer.createDelegate(this)},{dataIndex:"username",width:80,align:"left"},{id:"descr",dataIndex:"descr",css:"white-space:normal;",width:170,renderer:this.descRenderer.createDelegate(this)}]});this.cmSystemLog=a;return a},getStore:function(){if(this.dsSystemLog){return this.dsSystemLog}var a=new SYNO.API.JsonStore({api:"SYNO.Core.SyslogClient.Log",version:"1",method:"list",appWindow:this.appWin,baseParams:{start:0,limit:50,target:"LOCAL",logtype:this.logType,dir:"desc"},root:"items",sortInfo:{field:"time",direction:"DESC"},fields:["username","time","descr","cmd"],autoDestroy:false,autoLoad:false,listeners:{load:function(b,d,c){if(d.length!==0){this.getEl().unmask()}else{this.getEl().mask(_T("widget","no_log_available"))}},loadexception:function(b,d,e,c){if(!e.items){if(e.code===5014){this.getEl().mask(_T("log","error_pgsql_is_upgrading"))}else{this.getEl().mask(_T("widget","no_active_log"))}}},scope:this}});this.dsSystemLog=a;this.addManagedComponent(a);return a},getUpdateParams:function(){var a={start:this.gStart,limit:50};return a}});