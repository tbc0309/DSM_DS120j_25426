/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.App.SASExpFwUpdateApp");SYNO.SDS.App.SASExpFwUpdateApp.Instance=Ext.extend(SYNO.SDS.AppInstance,{initInstance:function(a){if(!this.win){this.win=new SYNO.SDS.App.SASExpFwUpdateApp.Window({appInstance:this});this.addInstance(this.win);this.win.setTitle(_T("update","exp_fw_critical_update_title"))}this.sendWebAPI({api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update_list_get":"exp_fw_update_list_get",version:1,params:{},scope:this,callback:function(c,b){if((c)&&(0!==b.enclosures.length)&&(0!==b.update_sec)&&(!b.is_firm_updating)){this.win.updateDesc(b.enclosures,b.update_sec,b.all_rollback_error);if(true===this.win.hidden){this.win.show()}}}});this.pollReg({webapi:{api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update_list_get":"exp_fw_update_list_get",version:1,params:{}},interval:10,immediate:true,scope:this,status_callback:function(e,d,c,b){if((e)&&(0!==d.enclosures.length)&&(0!==d.update_sec)&&(!d.is_firm_updating)&&(d.need_notify)){this.win.updateDesc(d.enclosures,d.update_sec,d.all_rollback_error);if(true===this.win.hidden){this.win.show()}}}});this.sendWebAPI({api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update_status_get":"exp_fw_update_status_get",version:1,params:{},scope:this,callback:function(c,b){if((c)&&(true!==b.finished)){SYNO.SDS.App.SASExpFwUpdateApp.SASFwUpdProgressBar.setBackgroudTask()}}})},onOpen:function(a){this.initInstance(a)}});Ext.define("SYNO.SDS.App.SASExpFwUpdateApp.UpdateProgress",{extend:"SYNO.SDS.MessageBoxV5",extraMsg:null,onRender:function(){this.callParent(arguments);this.extraMsg=new SYNO.ux.DisplayField({xtype:"syno_displayfield",htmlEncode:false,value:"",renderTo:this.bodyEl,scope:this});this.addManagedComponent(this.extraMsg);this.addClass("syno_displayfield")},showMsg:function(){this.callParent(arguments);this.extraMsg.setVisible(true);this.extraMsg.setValue(arguments[0].extraMsg)}});Ext.define("SYNO.SDS.App.SASExpFwUpdateApp.SASFwUpdProgressBar",{extend:"SYNO.SDS.ModalWindow",statics:{startFWUpdProgress:function(b,a){var c=new SYNO.SDS.App.SASExpFwUpdateApp.SASFwUpdProgressBar({owner:b,updateMins:a});c.open()},setBackgroudTask:function(){SYNO.SDS.BackgroundTaskMgr.addWebAPITask({title:[_T("update","updating")+": "+_T("update","exp_fw_critical_update_backgroud_desc")],query:{api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update_status_get":"exp_fw_update_status_get",version:1,cancelable:false,params:{}}})}},constructor:function(a){this.updateMins=a.updateMins;this.callParent([a])},onOpen:function(){this.callParent(arguments);this.hide(true);this.updProgress=new SYNO.SDS.App.SASExpFwUpdateApp.UpdateProgress({modal:true,draggable:false,closable:false,renderTo:document.body,cls:"sas-exp-fw-update",scope:this});this.startPollingProgress()},startPollingProgress:function(){this.updProgress.getWrapper().show({title:"",msg:"",buttons:false,progress:true,closable:false,minWidth:480,progressText:"",extraMsg:String.format(_T("update","exp_fw_updating_desc"),this.updateMins)});SYNO.SDS.App.SASExpFwUpdateApp.SASFwUpdProgressBar.setBackgroudTask();this.updatePollingId=this.pollReg({webapi:{api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update_status_get":"exp_fw_update_status_get",version:1,params:{}},interval:5,immediate:true,scope:this,status_callback:function(e,d,c,b){var a="";if(!e){this.stopPollingProgress();SYNO.SDS.App.SASExpFWUpdFailApp.showAlertMsg(this);return false}if((d.finished)||(this.updProgress.isDestroyed)){this.stopPollingProgress();return false}else{a=String.format("{0}%",Math.floor(d.progress*100));this.updProgress.getWrapper().updateProgress(d.progress,a,String.format("<b>{0}...</b>",_T("update","updating")),true)}}})},stopPollingProgress:function(){this.pollUnreg(this.updatePollingId);this.updatePollingId=undefined;if(!this.updProgress.isDestroyed){this.updProgress.close()}this.close()}});SYNO.SDS.App.SASExpFwUpdateApp.Window=Ext.extend(SYNO.SDS.AppWindow,{updProgressBox:null,updateMins:0,updatePollingId:undefined,constructor:function(b){var a;this.owner=b.owner;this.module=b.module;a=Ext.apply({width:600,height:340,minWidth:600,minHeight:340,dsmStyle:"v5",layout:"fit",closable:false,maximizable:false,minimizable:false,showHelp:false,items:[{xtype:"syno_formpanel",itemId:"form",border:false,items:[{xtype:"syno_displayfield",itemId:"update_desc",htmlEncode:false,value:String.format(_T("update","exp_fw_critical_update_desc"),0,"")},{xtype:"syno_checkbox",htmlEncode:false,boxLabel:_T("update","exp_fw_critical_update_comfirm"),listeners:{check:{scope:this,fn:this.onCheckboxCheck}}}]}],buttons:[{text:_T("pkgmgr","pkgmgr_pkg_upgrade"),itemId:"update",scope:this,disabled:true,btnStyle:"blue",handler:this.onClickUpdate},{text:_T("common","cancel"),scope:this,btnStyle:"gray",handler:this.onClickCancel}]},b);SYNO.SDS.App.SASExpFwUpdateApp.Window.superclass.constructor.call(this,a)},onCheckboxCheck:function(c,b){var a=this.getFooterToolbar().getComponent("update");a.setDisabled(!b)},onClickUpdate:function(){this.cancelNotfiy();this.setStatusBusy();this.sendWebAPI({api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update":"exp_fw_update",version:1,params:{},scope:this,callback:function(b,a){this.clearStatusBusy();if(!b){if(407==a.code){this.getMsgBox().alert("",_T("update","exp_fw_upd_already_in_progress"));this.hide()}else{this.getMsgBox().alert("",_T("common","error_system"));this.hide()}}else{SYNO.SDS.App.SASExpFwUpdateApp.SASFwUpdProgressBar.startFWUpdProgress(this,this.updateMins);this.hide()}}})},onClickCancel:function(){this.hide();this.cancelNotfiy();SYNO.SDS.Desktop.getMsgBox().show({msg:_T("update","exp_fw_critical_update_cancel_desc"),minWidth:480,maxWidth:480,icon:Ext.MessageBox.INFORMATION,appWin:this,cls:"sas-exp-fw-update",buttons:{ok:{text:_T("common","ok")}}});SYNO.SDS.Desktop.getMsgBox().getDialog().fbButtons.ok.el.dom.style.cssText=""},updateDesc:function(b,d,c){var a=this.getComponent("form").getComponent("update_desc");this.updateMins=Math.ceil(d/60);a.setValue(c?String.format(_T("update","exp_fw_rollback_error_update_desc"),b):String.format(_T("update","exp_fw_critical_update_desc"),this.updateMins,b))},cancelNotfiy:function(){this.sendWebAPI({api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_update_cancel_notify":"exp_fw_update_cancel_notify",version:1,params:{},scope:this,callback:function(b,a){}})}});