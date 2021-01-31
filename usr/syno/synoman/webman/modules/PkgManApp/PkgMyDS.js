/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.ns("SYNO.SDS.PkgManApp");SYNO.SDS.PkgManApp.Config={};Ext.apply(SYNO.SDS.PkgManApp.Config,{RECOMMEND_LIST_BIG_NUMBER:4,LIST_PKG_CELL_WIDTH:152,DEFAULT_CURRENCY:"USD",DEFICON_72:"images/package_center_72.png",DEFICON_256:"images/package_center_256.png",myDSRemindPassURL:"https://myds.synology.com/support/register_password_remind.php",myDSRegister:"https://myds.synology.com/support/register_form.php",agreed_tos_hash_key:"agreed_tos_hash",tos_hash_key:"tos_hash",tos_hash_timestamp_key:"tos_hash_timestamp"});SYNO.SDS.PkgManApp.SERVICE={};Ext.apply(SYNO.SDS.PkgManApp.SERVICE,{PKG_SERVICES_SSH:8,PKG_SERVICES_PGSQL:16});SYNO.SDS.PkgManApp.TOFURL="http://www.synology.com/company/term_packagecenter.php";Ext.ns("SYNO.SDS.PkgManApp");SYNO.SDS.PkgManApp.CustMyDSDialog=Ext.extend(SYNO.SDS.ModalWindow,{dsmStyle:"v5",_SYNOMyDSParams:{},constructor:function(a){a=a||{};this._SYNOMyDSObj={_blSetTransparent:false,_blInitMydsWrong:false,timeoutDuration:60000,type:0,appId:a.appId,params:{},blBuyItem:false};var c=SYNO.SDS.Config.FnMap["SYNO.SDS.PkgManApp.MyDSDialog"];if(!c){return}this._SYNOMyDSObj._iframeMyDSId=Ext.id();var d=function(f){try{Ext.EventManager.removeAll(f);Ext.destroy(f);f=undefined}catch(g){}};var e;var b=function(){var g=function(k,i){var l="";if(k&&k.errinfo&&k.errinfo.sec&&k.errinfo.key&&k.errinfo.key==="myds_register"){this.fireEvent("payfailed",this);this.close();var j=new SYNO.SDS.MyDSCenter.LoginDialog({owner:this.owner});j.show()}else{if(k&&Ext.isObject(k.result)&&!Ext.isEmpty(k.result.msg)&&k.result.code!=="badauth"&&k.result.code!=="good"){this.getMsgBox().alert(this.title,k.result.msg,function(){this.fireEvent("payfailed",this);this.close()},this)}else{if(k&&Ext.isObject(k.result)&&k.result.code){switch(k.result.code){case"good":if(k.info&&0===k.info.way){this.fireEvent("payfailed",this);this.close.defer(100,this);return}var h=(function(m){this.fireEvent("payevent",this,m);this.close()}).createDelegate(this);if(k.result&&!Ext.isEmpty(k.result.msg)){this.getMsgBox().alert(this.title,k.result.msg,function(m){if("ok"===m){h(k)}else{this.fireEvent("payfailed",this);this.close()}},this)}else{h.defer(100,this,[k])}if(2===this._SYNOMyDSObj.type&&this._SYNOMyDSObj.appId){this.sendWebAPI({api:"SYNO.Core.Package.MyDS.Purchase",method:"save",version:1,params:{appId:this._SYNOMyDSObj.appId}})}return;case"account_unverified":l=_T("pkgmgr","myds_error_activate");break;case"badconn":case"badsys":l=_T("pkgmgr","fail_connect_server");break;default:l=_T("pkgmgr","myds_error_illegal");SYNO.Debug(k);break}this.getMsgBox().alert(this.title,l,function(){this.fireEvent("payfailed",this);this.close()},this)}else{if(k&&k.errinfo&&k.errinfo.sec&&k.errinfo.key){l=_T(k.errinfo.sec,k.errinfo.key)}this.getMsgBox().alert(this.title,l||_T("error","error_error_system"),function(){this.fireEvent("payfailed",this);this.close()},this)}}}};var f=function(i){if(!i){this.setTitle(" ");this.layout.setActiveItem(this.get("syno-myds-connect"));this.setStatusBusy()}if(!this._SYNOMyDSObj._blMyDSIframeLoad){f.defer(100,this,[true]);return}var j=this._SYNOMyDSObj.iframeDom?this._SYNOMyDSObj.iframeDom:Ext.get(this._SYNOMyDSObj._iframeMyDSId).dom;var l=Ext.isIE?j.contentWindow.document:(j.contentDocument||window.frames[j.id].document);if(!l.blready){this.clearStatusBusy();this.getMsgBox().alert(this.title,_T("error","error_error_system"),function(){this.fireEvent("payfailed",this);this.close()},this);return}var k=function(q,o){try{if(window.postMessage){q.postMessage(Ext.encode(o),SYNO.SDS.PkgManApp.Config.myPayBaseURL)}else{q.location.hash="#"+(new Date().getTime())+"&"+Ext.encode(o)}}catch(p){if(window.console){console.log(p)}}};var h=function(p,o){if(window.postMessage){Ext.EventManager.on(p,"message",function(q){if(q.browserEvent.origin!==SYNO.SDS.PkgManApp.Config.myPayBaseURL){this.getMsgBox().alert(this.title,_T("error","error_error_system"),function(){this.fireEvent("payfailed",this);this.close()},this);return}if(Ext.isString(q.browserEvent.data)){g.call(this,Ext.decode(q.browserEvent.data),true)}else{g.call(this,q.browserEvent.data,true)}},this)}else{if(!this._SYNOMyDSObj.msgTask||this._SYNOMyDSObj.msgTask.removed){this._SYNOMyDSObj.msgTask=this.addTask({interval:500,run:function(){if(this.isDestroyed){this._SYNOMyDSObj.msgTask.stop();return}var r=o.location.hash,q=/^#?\d+&/;if(r!==this._SYNOMyDSObj.last_hash&&q.test(r)){this._SYNOMyDSObj.last_hash=r;g.call(this,Ext.decode(decodeURIComponent(r.replace(q,""))),true);o.location.hash=""}},scope:this});this.mon(this,"beforeclose",function(){if(this._SYNOMyDSObj._blMyDSIframeLoad&&this._SYNOMyDSObj.msgTask){this._SYNOMyDSObj.msgTask.remove()}},this)}this._SYNOMyDSObj.msgTask.start(true)}};var n=function(r,s,q){var o=r.getElementById(s);var p=o||r.createElement("iframe");p.setAttribute("id",s);p.setAttribute("name",s);p.setAttribute("src",q);p.setAttribute("frameBorder","0");p.setAttribute("style","background-color: transparent;border: 0px none; width: 100%; height: 100%;");if(Ext.isIE8){p.setAttribute("allowTransparency","true")}if(p.style.setAttribute){p.style.setAttribute("cssText","background-color: transparent;border: 0px none; width: 100%; height: 100%;")}if(!o){r.body.appendChild(p)}return p};e=n(l,"myds_iframe",SYNO.SDS.PkgManApp.Config.myDSURL+"?d="+new Date().getTime());var m=setTimeout((function(){d.call(this,e);if(this.isDestroyed){return}this.clearStatusBusy();var o=_T("pkgmgr","fail_connect_to_buy");if(0===this._SYNOMyDSObj.type){this.getMsgBox().confirm(this.title,o,function(p){if("yes"===p&&0===this._SYNOMyDSObj.type){}this.fireEvent("payfailed",this);this.close()},this)}else{this.getMsgBox().alert(this.title,o,function(p){this.fireEvent("payfailed",this);this.close()},this)}}).createDelegate(this),this._SYNOMyDSObj.timeoutDuration);Ext.EventManager.on(e,"load",function(){if(m){clearTimeout(m);m=null}else{return}if(this.isDestroyed){d.call(this,e);return}this.clearStatusBusy();Ext.EventManager.on(window,"unload",function(){d.call(this,e)},this);this.mon(this,"beforeclose",function(){d.call(this,e)},this);(function(){if(this.isDestroyed){return}if(this.layout.activeItem!==this.get("syno-myds-login")){this.maximize();this.layout.setActiveItem(this.get("syno-myds-iframe"))}}).defer(1000,this);if(!this._SYNOMyDSObj.blInitMsg){this._SYNOMyDSObj.blInitMsg=true;h.call(this,j.contentWindow,l)}this._SYNOMyDSParams=this._SYNOMyDSParams||{};var o=SYNO.Util.copy(this._SYNOMyDSParams);k.call(this,e.contentWindow,Ext.apply(Ext.apply(o,this.get("syno-myds-login").form.getValues()),this._SYNOMyDSObj.params))},this,{single:true});Ext.EventManager.on(e,"error",function(){if(m){clearTimeout(m);m=null}else{return}if(this.isDestroyed){d.call(this,e);return}this.clearStatusBusy();Ext.EventManager.on(window,"unload",function(){d.call(this,e)},this);this.mon(this,"beforeclose",function(){d.call(this,e)},this);this.getMsgBox().alert(this.title,_T("pkgmgr","fail_connect_server"),function(){this.fireEvent("payfailed",this);this.close()},this)},this,{single:true})};this.get("syno-myds-login").form.setValues(this._SYNOMyDSParams);if(!Ext.isEmpty(this._SYNOMyDSObj._MyDSIdField.getValue())){f.call(this)}else{this.setStatusBusy();this.sendWebAPI({api:"SYNO.Core.Package.MyDS",method:"get",version:1,params:{appId:a.appId||""},callback:function(k,i){if(this.isDestroyed){return}this.clearStatusBusy();if(k&&Ext.isDefined(i)){Ext.apply(SYNO.SDS.PkgManApp.Config,i);Ext.apply(SYNO.SDS.PkgManApp.Config,{myPayBaseURL:i.myPayBaseURL});Ext.apply(SYNO.SDS.PkgManApp.Config,{myDSURL:SYNO.SDS.PkgManApp.Config.myPayBaseURL+"/api/purchase5_1.html"});delete i.ds_sn;this.get("syno-myds-login").form.setValues(i);f.call(this)}else{if(Ext.isDefined(i)&&4571==i.code){this.fireEvent("payfailed",this);this.close();var h=new SYNO.SDS.MyDSCenter.LoginDialog({owner:this.owner});h.show()}else{var j=_T("common","error_system");if(i.code){j=SYNO.API.getErrorString(i.code)}this.getMsgBox().alert(this.title,j,function(){this.fireEvent("payfailed",this);this.close()},this)}}},scope:this})}};a.tools=a.tools||[];a.tools.push({id:"close",handler:function(){this.fireEvent("payfailed",this);this.close()},scope:this});a.items=a.items||[];a.items.push.apply(a.items,[{itemId:"syno-myds-connect",trackResetOnLoad:true,xtype:"syno_formpanel",border:false,items:[{xtype:"container",width:450,height:260,style:"display:table;height:300px;text-align:center;",html:'<div class=\'syno-pkg-connect-text\' style=\'display:table-cell;vertical-align:middle;\'><table cellspacing="0" style="width: auto;margin: auto;"><tbody><tr><td><div class="syno-pkg-connect-icon"></div></td><td>&nbsp;'+_T("pkgmgr","myds_connecting")+"</td></tr></tbody></table></div>"}]},{itemId:"syno-myds-iframe",xtype:"container",html:String.format('<iframe id="{0}" src="{1}" frameborder="0" allowTransparency="true" style="background-color: transparent;border: 0px none; width: 100%; height: 100%;"></iframe>',this._SYNOMyDSObj._iframeMyDSId,Ext.urlAppend(SYNO.API.currentManager.getBaseURL("SYNO.Core.Package.FakeIFrame","get",1))),listeners:{scope:this,single:true,afterlayout:function(f){var g=this._SYNOMyDSObj.iframeDom?this._SYNOMyDSObj.iframeDom:Ext.get(this._SYNOMyDSObj._iframeMyDSId).dom;Ext.EventManager.on(g,"load",function(){if(this.isDestroyed){d.call(this,e);return}Ext.EventManager.on(window,"unload",function(){d.call(this,g)},this);this.mon(this,"beforeclose",function(){d.call(this,g)},this);this._SYNOMyDSObj._blMyDSIframeLoad=true},this);Ext.EventManager.on(g,"error",function(){if(this.isDestroyed){d.call(this,e);return}Ext.EventManager.on(window,"unload",function(){d.call(this,g)},this);this.mon(this,"beforeclose",function(){d.call(this,g)},this);this._SYNOMyDSObj._blMyDSIframeLoad=true},this)}}},{hidden:true,itemId:"syno-myds-login",trackResetOnLoad:true,xtype:"syno_formpanel",border:false,items:[{xtype:"hidden",name:"serial"},{xtype:"hidden",name:"language",value:_S("lang")},{xtype:"hidden",name:"ds_timezone"},{xtype:"hidden",name:"ds_unique"},{xtype:"hidden",name:"ds_major"},{xtype:"hidden",name:"ds_minor"},{xtype:"hidden",name:"ds_build"},this._SYNOMyDSObj._MyDSIdField=new Ext.form.Hidden({xtype:"hidden",name:"myds_id"}),{xtype:"hidden",name:"auth_key"}],listeners:{scope:this,activate:function(){if(this._SYNOMyDSObj.blBuyItem){b.call(this)}}}}]);Ext.each(a.items,function(f){f.tools=[{id:"close",handler:function(){this.fireEvent("payfailed",this);this.close()},scope:this}]},this);SYNO.SDS.PkgManApp.CustMyDSDialog.superclass.constructor.call(this,Ext.apply(a,{title:a.title||this.title||_T("pkgmgr","myds_title"),cls:"syno-pkg-myds-dailog "+(a.cls||""),layout:"card",resizable:false,useStatusBar:false,modal:true,constrain:true,constrainHeader:true,renderTo:document.body}));Ext.EventManager.onWindowResize(this.center,this);this.mon(this,"beforeshow",function(){if(Ext.isIE6||Ext.isIE7){window.alert(_T("pkgmgr","upgrade_ie_browser"));return false}return true},this);this.mon(this,"afterlayout",this.center,this);this.mon(this,"beforeclose",function(){Ext.EventManager.removeResizeListener(this.center,this)},this);this.mon(this,"show",function(){this.maskEl.addClass("syno-pkg-myds-mask")},this,{single:true});Ext.apply(this._SYNOMyDSObj,{type:a.type||0});Ext.apply(this._SYNOMyDSObj,{timeoutDuration:(0===this._SYNOMyDSObj.type)?60000:60000});if(a.myds_params){Ext.apply(this._SYNOMyDSParams,a.myds_params||{});this.get("syno-myds-login").form.setValues(a.myds_params);b.call(this)}if(Ext.isEmpty(this._SYNOMyDSObj._MyDSIdField.getValue())){this.mon(this,"beforeshow",function(){this.setStatusBusy();this.sendWebAPI({api:"SYNO.Core.Package.MyDS",method:"get",version:1,params:{appId:a.appId||""},callback:function(i,g){if(this.isDestroyed){return}this.clearStatusBusy();if(i&&Ext.isDefined(g)){Ext.apply(SYNO.SDS.PkgManApp.Config,g);Ext.apply(SYNO.SDS.PkgManApp.Config,{myPayBaseURL:g.myPayBaseURL});Ext.apply(SYNO.SDS.PkgManApp.Config,{myDSURL:SYNO.SDS.PkgManApp.Config.myPayBaseURL+"/api/purchase5_1.html"});delete g.ds_sn;this.get("syno-myds-login").form.setValues(g);if(this.layout.activeItem===this.get("syno-myds-login")){b.call(this)}}else{if(Ext.isDefined(g)&&4571==g.code){this.fireEvent("payfailed",this);this.close();var f=new SYNO.SDS.MyDSCenter.LoginDialog({owner:this.owner});f.show()}else{var h=_T("common","error_system");if(g.code){h=SYNO.API.getErrorString(g.code)}this.getMsgBox().alert(this.title,h,function(){this.fireEvent("payfailed",this);this.close()},this)}}},scope:this})})}},_onGoMyDS:function(b){b=b||{};if(b&&b.appId){this._SYNOMyDSObj.appId=b.appId}if(!this._SYNOMyDSObj.appId){SYNO.Debug("Can't get appId");return}if(Ext.isEmpty(this._SYNOMyDSObj._MyDSIdField.getValue())){this.fireEvent("payfailed",this);this.close();var a=new SYNO.SDS.MyDSCenter.LoginDialog({owner:this.owner});a.show();return}this._SYNOMyDSObj.type=2;this._SYNOMyDSObj.blBuyItem=true;this._SYNOMyDSObj.timeoutDuration=60000;Ext.apply(this._SYNOMyDSObj.params,b||{});this.layout.setActiveItem(this.get("syno-myds-login"))},center:function(){var a=this.el.getAlignToXY(Ext.getBody(),"c-c");this.setPagePosition(a[0],a[1]);return this}});SYNO.SDS.PkgManApp.MyDSDialog=Ext.extend(SYNO.SDS.PkgManApp.CustMyDSDialog,{constructor:function(a){Ext.apply(this,a);SYNO.SDS.PkgManApp.MyDSDialog.superclass.constructor.call(this,Ext.apply(a,{dsmStyle:"v5",resizable:false,width:480,height:330,border:false,activeItem:0,layout:"card"}))}});