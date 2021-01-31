/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.PollingTask.BadgeInfo",{statics:{getInfoOfApp:function(a){if(this.data&&this.data[a]){return this.data[a].unread}else{return 0}},getInfoOfFn:function(b,a){if(this.data&&this.data[b]&&this.data[b].fn[a]){return this.data[b].fn[a].unread}else{return 0}},each:function(b,a){if(this.data){Ext.iterate(this.data,b,a||this)}},eachFnOfApp:function(b,c,a){if(this.data&&this.data[b]&&this.data[b].fn){Ext.iterate(this.data[b].fn,c,a||this)}}}});Ext.define("SYNO.SDS.AppNotify.Instance",{extend:"SYNO.SDS.AppInstance",constructor:function(){this.customList={};this.disabledAppMap={};this.callParent(arguments)},initInstance:function(){SYNO.SDS.StatusNotifier.fireEvent("appnotifyready");var a=new Ext.Component({appInstance:this});this.addInstance(a);this.startPollTask(true);this.mon(SYNO.SDS.StatusNotifier,"registerappnotify",this.onRegisterApp,this);this.mon(SYNO.SDS.StatusNotifier,"unregisterappnotify",this.unRegisterApp,this);this.mon(SYNO.SDS.StatusNotifier,"jsconfigLoaded",this.onJSConfigLoaded,this);this.mon(SYNO.SDS.StatusNotifier,"modifyHaveNtAppList",this.restartPollingTask,this);this.mon(SYNO.SDS.StatusNotifier,"apprecordupdated",this.restartPollingTask,this)},onRegisterApp:function(d,a,e,c){var b=(a)?a.api+a.method:d;if(this.customList[b]){return}this.customList[b]={callback:e,webapi:a,className:d,scope:c};this.startPollTask(true)},unRegisterApp:function(a){var b=a.api+a.method;if(this.customList[b]){delete this.customList[b];this.startPollTask(true)}},restartPollingTask:function(){this.startPollTask(true)},onJSConfigLoaded:function(a,c){var d,b=false;for(d in this.customList){if(this.customList.hasOwnProperty(d)&&this.customList[d].className&&!SYNO.SDS.StatusNotifier.isAppEnabled(this.customList[d].className)){delete this.customList[d];b=true}}if(b===true){this.startPollTask(true)}},startPollTask:function(c){var b=[{api:"SYNO.Core.AppNotify",method:"get",version:1}],d,a;this.stopPollTask();for(d in this.customList){if(this.customList.hasOwnProperty(d)){a=this.customList[d].webapi;b.push(a)}}this.pollTaskId=this.pollReg({interval:10,immediate:!!c,webapi:{api:"SYNO.Entry.Request",version:1,method:"request",stopwhenerror:true,params:{compound:b}},scope:this,status_callback:this.onAPIReturn})},stopPollTask:function(){if(Ext.isString(this.pollTaskId)&&this.pollUnreg(this.pollTaskId)){this.pollTaskId=null}},onAPIReturn:function(l,f,a){if(!l&&f.has_fail===false){return}var k,g,j,b,e,h,d,c;k=f.result[0].data||{};for(g=1;g<f.result.length;g++){b=f.result[g];e=b.api+b.method;h=this.customList[e];if(h&&h.callback){j=h.callback.call(h.scope||window,f.result[g].data);Ext.apply(k,j)}}d=SYNO.SDS.UserSettings.getProperty("SYNO.SDS.DSMNotify.Setting.Application","haveNtAppList");c=this.convertArrayToMap(d);Ext.iterate(k,function(i,n,m){if(false===c[i]){delete k[i]}},this);SYNO.SDS.PollingTask.BadgeInfo.data=null;SYNO.SDS.PollingTask.BadgeInfo.data=k;SYNO.SDS.StatusNotifier.fireEvent("badgenumget",SYNO.SDS.PollingTask.BadgeInfo);this.addBadgeToDesktopItems(k)},convertArrayToMap:function(a){var b={};Ext.each(a,function(c){if("on"===c.badge||"disabled"===c.badge){b[c.jsID]=true}else{b[c.jsID]=false}},this);return b},addBadgeToDesktopItems:function(l){var m=SYNO.SDS.Desktop.iconItems;var d=function(r,t){var p=!r.param,j=r.param&&r.param.fn,i=r.className,s=(j)?r.param.fn:undefined,q=t[i]?t[i].time||0:0,o=t[i]?t[i].lastView||0:0;if(t[i]&&(p===true)){return q>=o?t[i].unread:0}else{if(t[i]&&j&&t[i].fn&&t[i].fn[s]){return q>=o?t[i].fn[s].unread:0}}return 0};for(var e=0;e<m.length;e++){if(m[e].className!="SYNO.SDS.VirtualGroup"){var g=d(m[e],l),n=m[e].li_el.dom.firstChild;this.updateBadge(m[e],n,g)}else{var k=0;var f=m[e].subItems;for(var c=0;c<f.length;c++){var a=d(f[c],l),b=m[e].iconItems[c],h=(b)?b.li_el.dom.firstChild:null;k+=a;if(b){this.updateBadge(b,h,a)}}this.updateBadge(m[e],m[e].li_el.dom.firstChild,k)}}},updateBadge:function(a,b,c){if(!(a.badge instanceof SYNO.SDS.Utils.Notify.Badge)){a.badge=new SYNO.SDS.Utils.Notify.Badge({disableAnchor:true,renderTo:b});a.badge.setNum(c)}else{if(a.badge.badgeNum!=c){a.badge.setNum(c)}}}});