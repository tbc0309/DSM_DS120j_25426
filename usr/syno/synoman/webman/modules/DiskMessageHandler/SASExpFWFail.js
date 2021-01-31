/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.App.SASExpFWUpdFailApp");SYNO.SDS.App.SASExpFWUpdFailApp.Instance=Ext.extend(SYNO.SDS.AppInstance,{initInstance:function(a){SYNO.SDS.App.SASExpFWUpdFailApp.showAlertMsg(this)},onOpen:function(a){this.initInstance(a)}});SYNO.SDS.App.SASExpFWUpdFailApp.showAlertMsg=function(b){var a=Ext.id();var c='&nbsp<a class="link-font" id="'+a+'" href="#">'+_T("common","syno_tech_support")+"</a>";b.sendWebAPI({api:"SYNO.Storage.CGI.Enclosure",method:_S("ha_running")?"sha_exp_fw_fail_get":"exp_fw_fail_get",version:1,params:{},scope:b,callback:function(e,d){if(e&&0!==d.enclosures.length){SYNO.SDS.Desktop.getMsgBox().show({msg:String.format(_T("update","exp_fw_critical_update_failed_desc"),c,d.enclosures),minWidth:480,maxWidth:480,icon:"ext-mb-error-red",cls:"sas-exp-fw-update",buttons:{cancel:{text:_T("common","ok")}}});SYNO.SDS.Desktop.getMsgBox().getDialog().fbButtons.cancel.el.dom.style.cssText="";b.mon(Ext.fly(a),"click",function(){SYNO.SDS.Desktop.getMsgBox().hide();SYNO.SDS.AppLaunch("SYNO.SDS.SupportForm.Application",{extra:{pkg_id:"SASExpFWUpdate"}})})}}})};