/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.Utils.PasswordConfirmDialog",{extend:"SYNO.SDS.ModalWindow",statics:{openDialog:function(c,d,a){if("SynologyCMS"===c._S("user")){d.apply(c,a);return}var b=new SYNO.SDS.Utils.PasswordConfirmDialog({module:c,owner:c,callback:d,args:a});b.open()}},constructor:function(a){a.callback=a.callback||function(){};a.args=a.args||[];var b=this.fillConfig(a);this.callParent([b])},fillConfig:function(a){var b={title:_T("common","enter_password_to_continue"),width:500,height:200,resizable:false,layout:"fit",buttons:[{xtype:"syno_button",text:_T("common","submit"),btnStyle:"red",scope:this,handler:this.confirmPassword},{xtype:"syno_button",text:_T("common","alt_cancel"),scope:this,handler:this.close}],items:[{xtype:"syno_formpanel",itemId:"password_form_panel",items:[{xtype:"syno_displayfield",value:String.format(_T("common","enter_user_password"))},{xtype:"syno_textfield",fieldLabel:_T("common","password"),textType:"password",itemId:"confirm_password"}]}]};Ext.apply(b,a);return b},getForm:function(){var a=this.getComponent("password_form_panel");return a.getForm()},confirmPassword:function(){var a=this.getForm();var b=a.findField("confirm_password");this.setStatusBusy({text:_T("common","msg_waiting")});this.sendWebAPI({api:"SYNO.Core.User.PasswordConfirm",version:1,method:"auth",params:{password:b.getValue()},encryption:["password"],scope:this,callback:this.doAction})},doAction:function(c,b,a){this.clearStatusBusy();if(!c){this.setStatusError({text:SYNO.API.Errors.core[b.code]});return}this.close();this.callback.apply(this.module,this.args)}});