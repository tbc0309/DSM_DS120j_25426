/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.SystemInfoApp");Ext.define("SYNO.SDS.SystemInfoApp.ConnectionProxy",{extend:"SYNO.API.Proxy",onRequestAPI:function(a,c,b){this.owner.systemTime=(a)?c.systime:null;this.callParent(arguments)}});Ext.define("SYNO.SDS.SystemInfoApp.ConnectionLogWidget",{extend:"SYNO.SDS._Widget.GridPanel",usewebapi:true,constructor:function(a){Ext.apply(a,{loadMask:false});this.callParent(arguments);this.mon(this,"cellclick",this.onGridCellClick,this,{buffer:500});this.systemTime=""},baseRenderer:function(d,b,c){var a=Ext.util.Format.htmlEncode(d);b.attr='ext:qtip="'+(Ext.util.Format.htmlEncode(a))+'"';return a},timeRenderer:function(c,g,e){var a=new Date(this.systemTime);var b=new Date(c);var j=Math.round((a.getTime()-b.getTime())/1000);j=Math.max(j,0);var k=(j)%(60*60)%(60);var d=(j-k)%(60*60)/60;var f=(j-d*60-k)/60/60;f=String.leftPad(f,2,"0");d=String.leftPad(d,2,"0");k=String.leftPad(k,2,"0");var i=Ext.util.Format.htmlEncode([f,d,k].join(":"));g.attr='ext:qtip="'+i+'"';return i},kickRenderer:function(c){var b=_T("connections","kick_connection");if(false===c){return""}if(_S("demo_mode")){b=_T("common","error_demo")}var d='<div class = "syno-crrentconn-split"></div>';var a=String.format('<div class = "syno-sysinfo-disconn-button" ext:qtip = "{0}"></div>',b);return d+a},usernameRenderer:function(e,c,d){var b,a;if(e.empty()){b=d.get("from");a='<div class = "syno-sysinfo-ip"></div>'+Ext.util.Format.htmlEncode(d.get("from"))}else{b=String.format("{0} - {1}",e,d.get("from"));a='<div class = "syno-sysinfo-username"></div>'+Ext.util.Format.htmlEncode(e)}c.attr='ext:qtip="'+(Ext.util.Format.htmlEncode(b))+'"';return a},onGridCellClick:function(a,g,h,i){if(_S("demo_mode")){return}var d=a.getColumnModel().getIndexById("kick");var f=i.getTarget("div",1,true);var j=null;if(!f){return}j=this.dsSystemLog.getAt(g);if(h===d){if(false===j.get("can_be_kicked")){return}var b=[],e=[],c=false;if("HTTP/HTTPS"===j.get("type")){e.push({who:j.get("who"),from:j.get("from")})}else{b.push({pid:j.get("pid"),type:j.get("type"),who:j.get("who"),from:j.get("from")})}if(_S("user")===j.get("who")){c=true}if(c){this.getMsgBox().confirm(_T("connections","connections_title"),_T("connections","confirm_kick_self"),function(k,l){if(k=="yes"){this.kickConnection(b,e)}},this)}else{this.kickConnection(b,e)}}},getMsgBox:function(a){if(!this.msgBox||this.msgBox.isDestroyed){this.msgBox=new SYNO.SDS.MessageBoxV5({modal:true,draggable:false,renderTo:document.body})}return this.msgBox.getWrapper()},kickConnection:function(b,a){this.mask(_T("common","loading"));this.appWin.sendWebAPI({api:"SYNO.Core.CurrentConnection",method:"kick_connection",timeout:450000,params:{service_conn:b,http_conn:a},version:1,scope:this,callback:function(c,d){this.unmask();if(!c){}else{this.getStore().load()}}})},mask:function(a){this.getEl().mask(a)},unmask:function(){this.getEl().unmask()},getColumnModel:function(){if(this.cmSystemLog){return this.cmSystemLog}var a=new Ext.grid.ColumnModel({columns:[{width:38,renderer:function(){return'<div class = "syno-crrentconn-icon"></div>'}},{id:"who",dataIndex:"who",width:80,renderer:this.usernameRenderer.createDelegate(this)},{id:"type",dataIndex:"type",width:72,renderer:{fn:this.baseRenderer,scope:this}},{id:"time",dataIndex:"time",width:72,renderer:{fn:this.timeRenderer,scope:this}},{id:"kick",dataIndex:"can_be_kicked",width:28,renderer:this.kickRenderer.createDelegate(this)}]});this.cmSystemLog=a;return a},getStore:function(){if(this.dsSystemLog){return this.dsSystemLog}var a=new SYNO.API.JsonStore({fields:["pid","who","time","descr","type","from","can_be_kicked"],root:"items",totalProperty:"total",sortInfo:{field:"time",direction:"DESC"},proxy:new SYNO.SDS.SystemInfoApp.ConnectionProxy({api:"SYNO.Core.CurrentConnection",method:"list",version:"1",appWindow:this.appWin,owner:this}),remoteSort:true,autoLoad:false});this.dsSystemLog=a;this.addManagedComponent(a);return a},getUpdateParams:function(){var a={start:0,limit:this.TotalRecords,sort:"time"};return a}});