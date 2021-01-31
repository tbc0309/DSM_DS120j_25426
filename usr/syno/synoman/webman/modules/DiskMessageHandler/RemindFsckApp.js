/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.App.RemindFsckApp");SYNO.SDS.App.RemindFsckApp.Instance=Ext.extend(SYNO.SDS.AppInstance,{shouldNotifyMsg:function(a,b){this.win.show();return false},initInstance:function(a){if(!this.win){this.win=new SYNO.SDS.App.RemindFsckApp.Fsck({appInstance:this});this.addInstance(this.win);this.win.setTitle(_T("volume","volume_scan_notification"))}if(_S("shouldAskForFSCK")===true){this.win.show()}},onOpen:function(a){this.initInstance(a)}});SYNO.SDS.App.RemindFsckApp.Fsck=Ext.extend(SYNO.SDS.AppWindow,{resetAskForFsck:function(){this.sendWebAPI({api:"SYNO.Storage.CGI.Check",method:"remove_ask_for_fsck",version:1})},changeCheckBoxHandler:function(b,a){if(Ext.getCmp(this.remindFsckCheckboxID).getValue()===true){Ext.getCmp(this.rebootButtonID).enable();Ext.getCmp(this.rebootLaterButtonID).enable();Ext.getCmp(this.ignoreButtonID).disable()}else{Ext.getCmp(this.rebootButtonID).disable();Ext.getCmp(this.rebootLaterButtonID).disable();Ext.getCmp(this.ignoreButtonID).enable()}},sendHandler:function(a){this.setStatusBusy();this.sendWebAPI({api:"SYNO.Storage.CGI.Check",method:a,version:1,scope:this,callback:function(c,b){this.clearStatusBusy();if(!c){this.setStatusError()}}})},reboot:function(){SYNO.SDS.System.Reboot()},rebootNowHandler:function(){this.resetAskForFsck();this.sendHandler("do_disk_scan");this.reboot();this.hide()},rebootAfterBuildHandler:function(){this.resetAskForFsck();this.sendHandler("do_disk_scan");this.sendHandler("reboot_after_rebuild");this.hide()},rebootLaterHandler:function(){this.resetAskForFsck();this.sendHandler("do_disk_scan");this.hide()},ignoreHandler:function(){this.resetAskForFsck();this.hide()},constructor:function(b){this.owner=b.owner;this.module=b.module;this.panel=this.createPanel();this.form=this.panel.getForm();var a=Ext.apply({title:_T("volume","raid_force_notification"),width:700,height:330,minimizable:false,maximizable:false,showHelp:false,resizable:false,cls:"syno-diskremap",items:[this.panel],buttons:[{xtype:"syno_button",btnStyle:"blue",id:this.rebootButtonID=Ext.id(),scope:this},{xtype:"syno_button",text:_T("volume","volume_scan_reboot_later"),id:this.rebootLaterButtonID=Ext.id(),handler:this.rebootLaterHandler,scope:this},{xtype:"syno_button",text:_T("common","alt_ignore"),id:this.ignoreButtonID=Ext.id(),handler:this.ignoreHandler,scope:this}]},b);SYNO.SDS.App.RemindFsckApp.Fsck.superclass.constructor.call(this,a);this.on("beforeclose",function(c){this.hide();return false});this.on("beforeshow",function(c){Ext.getCmp(this.remindFsckCheckboxID).setValue(false);Ext.getCmp(this.rebootButtonID).disable();Ext.getCmp(this.rebootLaterButtonID).disable();Ext.getCmp(this.ignoreButtonID).enable();this.sendWebAPI({api:"SYNO.Storage.CGI.Check",method:"is_data_scrubbing",version:1,scope:this,callback:function(e,d){if(!e){return}if(d.isBuilding){Ext.getCmp(this.fsckLabelID).setValue(String.format(_T("hddsleep","dcache_fsck_wait4building")));Ext.getCmp(this.rebootButtonID).setText(_T("volume","volume_scan_reboot_after_rebuild"));Ext.getCmp(this.rebootButtonID).setHandler(this.rebootAfterBuildHandler,this)}else{if(d.wasDataScrubbing){Ext.getCmp(this.fsckLabelID).setValue(String.format(_T("volume","volume_scan_fsck")))}else{Ext.getCmp(this.fsckLabelID).setValue(String.format(_T("hddsleep","dcache_notification_reboot")))}Ext.getCmp(this.rebootButtonID).setText(_T("volume","volume_scan_reboot_immediately"));Ext.getCmp(this.rebootButtonID).setHandler(this.rebootNowHandler,this)}}});return true})},createPanel:function(){var a={border:false,items:[{xtype:"syno_displayfield",id:this.fsckLabelID=Ext.id()},{xtype:"syno_displayfield",htmlEncode:false,value:_T("volume","volume_scan_fsck_note")},{xtype:"syno_displayfield",value:""},{xtype:"syno_checkbox",id:this.remindFsckCheckboxID=Ext.id(),handler:this.changeCheckBoxHandler,boxLabel:_T("volume","volume_scan_confirmed"),scope:this}]};return new Ext.form.FormPanel(a)}});