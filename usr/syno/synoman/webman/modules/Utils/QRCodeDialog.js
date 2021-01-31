/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.Utils.QRCodeDialog",{extend:"SYNO.SDS.ModalWindow",constructor:function(a){this.panel=this.createPanel(a);var b={width:500,height:350,resizable:false,collapsible:false,layout:"fit",title:_T("sharing","qrcode_links"),buttons:[{text:_T("common","close"),scope:this,handler:this.close}],items:[this.panel]};Ext.apply(b,a);this.callParent([b])},createPanel:function(a){var b=[];if(Ext.isArray(a.qrcode)&&Ext.isArray(a.url)){Ext.iterate(a.qrcode,function(d,c){b.push(this.createQRComp(a.url[c],d))},this)}else{b.push(this.createQRComp(a.url,a.qrcode))}return new SYNO.ux.Panel({autoFlexcroll:true,layout:{type:"hbox",align:"center",pack:"center"},items:b})},createQRComp:function(a,b){return new Ext.Container({layout:{type:"vbox",align:"center",pack:"center"},margins:{top:0,right:20,bottom:0,left:20},items:[{xtype:"box",itemId:"qrcode",width:135,height:135,cls:"allowDefCtxMenu selectabletext",autoEl:{tag:"img",src:b}},{xtype:"syno_textarea",width:260,itemId:"url",readOnly:true,autoFlexcroll:true,selectOnFocus:true,hideLabel:true,value:a}]})}});