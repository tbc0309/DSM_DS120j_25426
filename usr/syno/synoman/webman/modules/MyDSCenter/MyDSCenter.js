/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.namespace("SYNO.SDS.MyDSCenter");Ext.define("SYNO.SDS.MyDSCenter.LoginDialog",{extend:"SYNO.SDS.ModalWindow",constructor:function(a){this.userConfig=a;this.loginType=a.loginType||"login";this.iframePath=a.iframePath||"iframes/login";this.iframeId=String.format("synoaccount-{0}-iframe",this.loginType);this.receiveMsgFn=this.receiveMessage.createDelegate(this);this.apiKeyErrorRetryCount=0;var b={width:520,height:338,resizable:false,closable:true,title:_T("common","login"),fbar:null,items:[this.iframe=new Ext.BoxComponent({hidden:true,height:"100%",html:String.format('<iframe id="{0}" src="about:blank" frameborder="0" marginheight="0" marginwidth="0" width="100%" height="100%"></iframe>',this.iframeId)})]};Ext.apply(b,a);this.callParent([b]);this.addEvents("login_success","cancel_login");this.addListener("beforeshow",this.onBeforeShow,this,{single:true})},onClose:function(a){this.clearEventListeners();this.fireEvent("cancel_login")},onBeforeShow:function(){this.sendWebAPI({api:"SYNO.Core.MyDSCenter",version:2,method:"query",params:{},scope:this,callback:function(a,b,c){if(!a){this.findWindow().getMsgBox().alert("",_T("myds","error_query_info"),function(){this.close()},this);return}if(b.is_logged_in){this.findWindow().getMsgBox().alert("",String.format(_T("myds","already_logged_in"),b.account),function(){this.findWindow().fireEvent("login_success",b.account,b.auth_key,b.activated);this.close()},this);return}this.showIframe()}})},showIframe:function(){this.sendWebAPI({api:"SYNO.Core.MyDSCenter",version:2,method:"get_iframe_info",params:{},scope:this,callback:this.onGetIframeInfo})},onGetIframeInfo:function(a,b,c){if(!a){this.findWindow().getMsgBox().alert("",SYNO.API.getErrorString(b),function(){this.close()},this);return}this.serverUrl=b.server_url;this.urlParam=this.getIframeUrlParam(b);this.setupIframe(this.serverUrl,this.urlParam)},getIframeUrlParam:function(b){var a=window.location.origin;if(!a){a=window.location.protocol+"//"+window.location.hostname+(window.location.port?":"+window.location.port:"")}return{language:_S("lang"),origin:a,api_key:b.api_key,serial_no:b.serial_no,orig_serial_no:b.orig_serial_no,mac:b.mac,theme:_S("theme_cls")}},setupIframe:function(b,a){var c=this.iframe.el.child("#"+this.iframeId).dom;this.iframeUrl=String.format("{0}/{1}?{2}",b,this.iframePath,Ext.urlEncode(a));c.setAttribute("src","about:blank");this.registerIframeLoadEvent();this.addMessageEvent();c.setAttribute("src",this.iframeUrl)},registerIframeLoadEvent:function(){var a=this.iframe.el.child("#"+this.iframeId).dom;this.iframeLoadTimer=setTimeout((function(){a.src="about:blank";this.iframeLoadTimer=null;this.findWindow().getMsgBox().alert("",_T("support_center","error_connect"),function(){this.close()},this)}).createDelegate(this),60000);Ext.EventManager.on(a,"load",function(){if(this.iframeLoadTimer){clearTimeout(this.iframeLoadTimer);this.iframeLoadTimer=null;this.iframe.setVisible(true)}},this)},clearEventListeners:function(){if(this.iframeLoadTimer){clearTimeout(this.iframeLoadTimer);this.iframeLoadTimer=null}Ext.EventManager.removeAll(this.iframe.el.child("#"+this.iframeId).dom);this.removeMessageEvent()},addMessageEvent:function(){if(!Ext.isIE9m&&window.addEventListener){window.addEventListener("message",this.receiveMsgFn)}},removeMessageEvent:function(){if(window.removeEventListener){window.removeEventListener("message",this.receiveMsgFn)}},receiveMessage:function(a){if(!a||!a.data||this.iframeUrl.indexOf(a.origin)===-1){return}switch(a.data.code){case"cancel":this.close();break;case"login":case"signup":this.openDialog(a.data.code);break;case"apikey_expired":case"apikey_not_found":this.handleApiKeyError(a.data.code);break;case"badauth":case"badsys":this.findWindow().getMsgBox().alert("",_T("error","error_unknown_desc"),function(){this.close()},this);break;case"good":this.doOauthLogin(a.data.access_token);break;default:break}},openDialog:function(b){var a;if(b==="login"){a=new SYNO.SDS.MyDSCenter.LoginDialog(this.userConfig)}else{if(b==="signup"){a=new SYNO.SDS.MyDSCenter.RegisterDialog(this.userConfig)}}this.clearEventListeners();a.show();this.destroy()},handleApiKeyError:function(a){this.apiKeyErrorRetryCount++;if(this.apiKeyErrorRetryCount===3){this.findWindow().getMsgBox().alert("",_T("error","error_unknown_desc"),function(){this.close()},this);return}this.clearEventListeners();this.sendWebAPI({api:"SYNO.Core.MyDSCenter",version:2,method:"handle_apikey_error",params:{apikey_error:a},scope:this,callback:this.onHandleApiKeyError})},onHandleApiKeyError:function(a,b,c){if(!a){this.findWindow().getMsgBox().alert("",SYNO.API.getErrorString(b),function(){this.close()},this);return}this.urlParam.api_key=b.api_key;this.setupIframe(this.serverUrl,this.urlParam)},doOauthLogin:function(a){this.sendWebAPI({api:"SYNO.Core.MyDSCenter",version:2,method:"oauth_login",params:{access_token:a},scope:this,callback:this.onOauthLogin})},onOauthLogin:function(a,b,f){var e,d=this,c;if(!a){switch(b.code){case 3010:e=String.format(SYNO.API.getErrorString(b),b.errors.account);break;default:e=SYNO.API.getErrorString(b)}this.findWindow().getMsgBox().alert("",e,function(){this.close()},this);return}c=function(){d.fireEvent("login_success",b.account,b.auth_key,b.activated);d.clearEventListeners();d.destroy()};if(!b.activated){this.findWindow().getMsgBox().alert("",_T("myds","not_activated_alert"),function(){c()},this)}else{c()}}});Ext.define("SYNO.SDS.MyDSCenter.RegisterDialog",{extend:"SYNO.SDS.MyDSCenter.LoginDialog",constructor:function(a){var b={width:520,height:488,title:_T("myds","sign_up"),loginType:"register",iframePath:"iframes/register"};Ext.apply(b,a);this.callParent([b])}});