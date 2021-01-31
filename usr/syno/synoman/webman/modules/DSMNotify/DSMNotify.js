/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.DSMNotify.DetailDialog",{extend:"SYNO.SDS.ModalWindow",title:_T("notification","detail_window"),constructor:function(t){this.formPanel=new SYNO.ux.FormPanel({items:[{xtype:"syno_displayfield",name:"category",fieldLabel:_T("notification","category_title")},{ref:"event",xtype:"syno_displayfield",name:"event",fieldLabel:_T("notification","notification_title"),htmlEncode:!1,listeners:{afterrender:function(){this.el.on("click",function(t){SYNO.SDS.Utils.Notify.BindEvent(t)})}}},{xtype:"syno_displayfield",name:"time",fieldLabel:_T("log","log_time")},{xtype:"syno_displayfield",name:"desc",ref:"desc",fieldLabel:_T("notification","description_title"),htmlEncode:!1,listeners:{afterrender:function(){this.el.on("click",function(t){SYNO.SDS.Utils.Notify.BindEvent(t)})}}}]});var e={width:640,height:400,layout:"fit",modal:!1,closeAction:"hide",items:[this.formPanel],cls:"sds-notify-detail-window",buttons:[{text:_T("common","close"),handler:function(){this.hide()},scope:this}]};Ext.apply(e,t),this.callParent([e])},onOpen:function(t){this.setValues(t),this.callParent()},onRequest:function(t){this.setValues(t),this.callParent()},setValues:function(t){this.formPanel.desc.setVisible(!!t.desc),t.desc&&(t.desc=this.getDetailMsg(t.desc)),this.formPanel.getForm().setValues(t),this.formPanel.updateFleXcroll()},getDetailMsg:function(t){return t=t.replace(/(\r\n|\r|\n)/g,"<br>"),Object.keys(SYNO.SDS.DSMNotify.MailPhrase).forEach(function(e){var i=SYNO.SDS.DSMNotify.MailPhrase[e],s=new RegExp(i.salutation+"<br>","i"),n=Ext.form.VTypes.netbiosNameMask.toString().slice(1,-1),a=new RegExp("<br>"+("krn"===e?n+"+"+i.closing:i.closing+n+"+"),"i");s.test(t)&&a.test(t)&&(t=t.replace(s,"").replace(a,""))}.bind(this)),t.replace(/^(<br>|\s)*|(<br>|\s)+$/gi,"")}}),SYNO.SDS.DSMNotify.MailPhrase={chs:{salutation:"亲爱的用户，您好：",closing:"来自 "},cht:{salutation:"親愛的使用者，您好：",closing:"來自 "},csy:{salutation:"Vážený uživateli,",closing:"Od "},dan:{salutation:"Kære bruger",closing:"Fra "},enu:{salutation:"Dear user,",closing:"From "},fre:{salutation:"Cher utilisateur,",closing:"De "},ger:{salutation:"Sehr geehrter Benutzer,",closing:"Von "},hun:{salutation:"Kedves Felhasználó!",closing:"Forrás: "},ita:{salutation:"Gentile utente,",closing:"Da "},jpn:{salutation:"お客様各位、",closing:"送信元 "},krn:{salutation:"사용자님께,",closing:"에서 보냄"},nld:{salutation:"Beste gebruiker,",closing:"Van "},nor:{salutation:"Kjære bruker",closing:"Fra "},plk:{salutation:"Szanowny Użytkowniku,",closing:"Od "},ptb:{salutation:"Prezado usuário,",closing:"De "},ptg:{salutation:"Caro utilizador,",closing:"De "},rus:{salutation:"Уважаемый пользователь!",closing:"Из "},spn:{salutation:"Estimado usuario:",closing:"Desde "},sve:{salutation:"Bäste användare,",closing:"Från "},tha:{salutation:"เรียนผู้ใช้",closing:"จาก "},trk:{salutation:"Sayın kullanıcı,",closing:"Geldiği yer: "}},Ext.define("SYNO.SDS.DSMNotify.ShowAllDialog",{extend:"SYNO.SDS.AppWindow",itemsPerPage:50,constructor:function(t){this.callParent([this.fillConfig(t)]),this.on("show",function(){this.grid.getStore().load({params:{start:0,limit:this.itemsPerPage}})},this),this.mon(SYNO.SDS.StatusNotifier,"notificationPanelClearAll",function(){this.paging.changePage(1)},this)},fillConfig:function(t){var e={width:800,height:580,showHelp:!1,minimizable:!1,toggleMinimizable:!1,pinable:!1,layout:"fit",items:[this.getGridPanel()]};return Ext.apply(e,t),e},onClose:function(){return this.hide(),!1},getGridPanel:function(){var t=new SYNO.API.JsonStore({api:"SYNO.Core.DSMNotify",method:"notify",version:1,baseParams:{action:"load",all:!0},appWindow:this,root:"items",totalProperty:"total",fields:["title","msg","time","className","fn","mailContent","isEncoded"],sortInfo:{field:"time",direction:"DESC"},listeners:{scope:this,load:function(){_S("demo_mode")||Ext.getCmp(this.clearAllBtnId).setDisabled(0===this.grid.getStore().getCount())}}});return this.paging=new SYNO.ux.PagingToolbar({store:t,displayInfo:!0,pageSize:this.itemsPerPage,refreshText:_T("log","log_reload")}),this.grid=new SYNO.ux.GridPanel({title:_T("dsmnotify","title"),loadMask:!0,stripeRows:!0,store:t,colModel:new Ext.grid.ColumnModel({defaults:{width:50,sortable:!0},columns:[{header:_T("notification","category_title"),dataIndex:"title",renderer:this.titleRenderer},{width:120,header:_T("notification","notification_title"),dataIndex:"msg",id:"msg",renderer:this.msgRenderer},{header:_T("log","log_time"),dataIndex:"time",renderer:this.timeRenderer}]}),autoExpandColumn:"msg",sm:new Ext.grid.RowSelectionModel({singleSelect:!0,listeners:{rowselect:this.onRowSelect,scope:this}}),bbar:this.paging,tbar:new Ext.Toolbar({defaultType:"syno_button",items:[{text:_T("log","log_reload"),scope:this,handler:function(){this.paging.doRefresh()}},{text:_T("dsmnotify","clearall"),scope:this,handler:this.clearAll,id:this.clearAllBtnId=Ext.id(),disabled:_S("demo_mode"),tooltip:_S("demo_mode")?_JSLIBSTR("uicommon","error_demo"):""},{text:_T("notification","view"),itemId:"viewBtn",scope:this,disabled:!0,handler:this.showDetailMsgDialog}]}),listeners:{rowdblclick:this.showDetailMsgDialog,scope:this}}),this.grid},clearAll:function(){this.grid.getStore().removeAll(),SYNO.API.Request({api:"SYNO.Core.DSMNotify",method:"notify",version:1,params:{action:"apply",clean:"all"},scope:this,callback:function(t,e,i,s){t&&(this.paging.changePage(1),SYNO.SDS.StatusNotifier.fireEvent("checknotify"))}}),Ext.getCmp(this.clearAllBtnId).setDisabled(!0)},timeRenderer:function(t){var e=SYNO.SDS.DateTimeFormatter(new Date(1e3*t));return'<div ext:qtip="'+e+'">'+e+"</div>"},msgRenderer:function(t,e,i){var s=SYNO.SDS.DSMNotify.Utils.getMsg(t,!0,i.data.className,i.data.fn),n=Ext.util.Format.htmlEncode(s);return String.format('<div class="{0}" ext:qtip="{1}">{2}</div>',SYNO.SDS.Utils.SelectableCLS,n,s)},titleRenderer:function(t,e,i){var s=SYNO.SDS.DSMNotify.Utils.getTitle(t,!0,i.data.className),n=Ext.util.Format.htmlEncode(s);return String.format('<div class="{0}" ext:qtip="{1}">{2}</div>',SYNO.SDS.Utils.SelectableCLS,n,s)},onRowSelect:function(){this.grid.getTopToolbar().getComponent("viewBtn").setDisabled(!this.grid.getSelectionModel().getSelected().data)},showDetailMsgDialog:function(){var t=this.grid.getSelectionModel().getSelected(),e=SYNO.SDS.DSMNotify.Utils.getMsg(t.data.msg,!1,t.data.className,t.data.fn),i={category:Ext.util.Format.htmlEncode(SYNO.SDS.DSMNotify.Utils.getTitle(t.data.title,!0,t.data.className)),event:t.data.isEncoded?Ext.util.Format.htmlEncode(e):e,time:SYNO.SDS.DateTimeFormatter(new Date(1e3*t.data.time)),htmlEncode:t.data.isEncoded};t.data.mailContent&&(i.desc=SYNO.SDS.DSMNotify.Utils.getMsg(t.data.mailContent,!1,t.data.className,t.data.fn),t.data.isEncoded&&(i.desc=Ext.util.Format.htmlEncode(i.desc))),this.appInstance.detailDailogWindow.open(i)}}),Ext.define("SYNO.SDS.DSMNotify.CustomEnableColumn",{extend:"SYNO.ux.EnableColumn",constructor:function(t){this.callParent([Ext.apply({width:180},t)])},renderer:function(t,e,i){return"disabled"===i.get(this.dataIndex)&&(t="disabled"),this.renderCheckBox(t,e,i)},isIgnore:function(t,e){return"disabled"===e.get(this.dataIndex)},renderCheckBox:function(t,e,i){var s="disabled"===t?"disabled":"on"===t?"checked":"unchecked",n="disabled"!==s&&"checked"===s,a=i?i.id+"_"+this.dataIndex:Ext.id(),o="disabled"===s?_T("common","disabled"):_JSLIBSTR("uicommon","enable_column_"+s),l="disabled"===s;return(e=e||{}).cellAttr=String.format('aria-label="{0} {1}" aria-checked="{2}" aria-disabled="{3}" role="checkbox"',Ext.util.Format.stripTags(this.orgHeader),o,n,l),String.format('<div class="syno-ux-grid-enable-column-{0}" id="{1}"></div>',s,a)},toggleRec:function(t){var e=t.get(this.dataIndex);"on"===e?e="off":"off"===e&&(e="on"),t.set(this.dataIndex,e)},onSelectAll:function(){var t,e,i,s,n;if(this.box_el&&this.box_el.dom){for(t=this.getGrid().getStore(),n=this.box_el.hasClass("syno-ux-cb-checked")?"on":"off",this.enableFastSelectAll&&t.suspendEvents(),e=0,s=t.getCount();e<s;e++)"gray"!==(i=t.getAt(e).get(this.dataIndex))&&i===n||this.isIgnore("all",t.getAt(e))||this.toggleRec(t.getAt(e));this.enableFastSelectAll&&(this.getGrid().getView().refresh(),t.resumeEvents()),this.commitChanges&&t.commitChanges(),this.checkSelectAll(t)}},checkSelectAll:function(t){var e,i,s,n=t.getCount(),a=n>0,o=!0,l=!1;if(this.box_el&&this.box_el.dom){for(e=0;e<n;e++)this.isIgnore("check",t.getAt(e))||(o=!1,"gray"===(i=t.getAt(e).get(this.dataIndex))||"off"===i?a=!1:l=!0);s=this.box_el.up("td"),a&&!o?(this.box_el.removeClass("syno-ux-cb-grayed"),this.box_el.addClass("syno-ux-cb-checked"),s.setARIA({checked:!0})):a||o||!l?(this.box_el.removeClass("syno-ux-cb-checked"),this.box_el.removeClass("syno-ux-cb-grayed"),s.setARIA({checked:!1})):(this.box_el.removeClass("syno-ux-cb-checked"),this.box_el.addClass("syno-ux-cb-grayed"),s.setARIA({checked:"mixed"}))}}}),Ext.define("SYNO.SDS.DSMNotify.Setting.GridPanel",{extend:"SYNO.ux.DDGridPanel",constructor:function(t){this.callParent([this.fillConfig(t)]),this.addEvents("loadHaveNtAppList")},fillConfig:function(t){this.createActions(),this.ctxMenu=new SYNO.ux.Menu({items:[this.getAction("up"),this.getAction("down")]});var e={viewConfig:{ddGroup:"NtSettingGridDD",forceFit:!1},cm:this.getCM(),sm:this.getSM(),cls:"sds-notify-setting-grid without-dirty-red-grid",plugins:[this.notificationEnableCloumn,this.badgeEnableColumn],store:this.getDS(t),enableDragDrop:!0,enableColumnMove:!1,enableHdMenu:!1,region:"center",autoFlexScroll:!0,autoExpandColumn:this.titleID,listeners:{viewready:this.onGridViewReady,rowclick:this.onGridRowClick,rowcontextmenu:this.onRowCtxMenu,columnresize:this.onColumnResize,containercontextmenu:this.showCtxMenu}};return Ext.apply(e,t)},getDS:function(t){var e=t.owner.findAppWindow();return new SYNO.API.JsonStore({api:"SYNO.Core.DSMNotify",method:"notify",version:1,appWindow:e,baseParams:{action:"loadHaveNtAppList"},root:"items",totalProperty:"total",fields:["title","nt","badge","jsID"],pruneModifiedRecords:!0,listeners:{scope:this,beforeload:function(){this.owner.el.isMasked||this.owner.setStatusBusy(null,null,0)},load:function(t,e,i){this.isPriorityDirty=!1,this.fireEvent("loadHaveNtAppList",{data:t.reader.jsonData}),this.owner.clearStatusBusy(),t.suspendEvents();for(var s=0;s<e.length;s++)SYNO.SDS.DSMNotify.Utils.isAppEnabled(e[s].get("jsID"))||t.remove(e[s]);t.resumeEvents(),this.view.refresh()},exception:function(){this.owner.clearStatusBusy(),this.owner.getMsgBox().alert("","Fail to get the priority application list",this.owner.onHandleHide,this.owner)}}})},getCM:function(){return this.notificationEnableCloumn=new SYNO.SDS.DSMNotify.CustomEnableColumn({header:_T("dsmnotify","title"),align:"center",dataIndex:"nt",menuDisabled:!0,sortable:!1}),this.badgeEnableColumn=new SYNO.SDS.DSMNotify.CustomEnableColumn({header:_T("dsmnotify","badge"),dataIndex:"badge",hidden:!0,menuDisabled:!0,sortable:!1}),new Ext.grid.ColumnModel([{header:_T("dsmnotify","service"),id:this.titleID=Ext.id(),dataIndex:"title",editable:!1,sortable:!1,menuDisabled:!0,renderer:this.titleRenderer},this.notificationEnableCloumn,this.badgeEnableColumn])},getSM:function(){return new Ext.grid.RowSelectionModel},getTopTbar:function(){return new Ext.Toolbar({defaultType:"syno_button",items:[this.getAction("up"),this.getAction("down")]})},actions:null,createActions:function(){var t=function(t,e,i,s,n){return new Ext.Action(Ext.apply({text:t,itemId:e,handler:i,scope:s},n))};this.actions={up:t(_T("common","up"),"up",this.onClickUP,this),down:t(_T("common","down"),"down",this.onClickDown,this)}},getAction:function(t){return this.actions[t]},onGridRowClick:function(t,e,i){i&&e&&!i.hasModifier()&&t.getSelectionModel().selectRow(e)},onGridViewReady:function(){this.view.updateScroller()},onRowCtxMenu:function(t,e,i){i.preventDefault();var s=t.getSelectionModel();s.isSelected(e)||s.selectRow(e),this.showCtxMenu(t,i)},showCtxMenu:function(t,e){this.owner.isTime||this.ctxMenu.showAt(e.getXY())},sortSelectionComparator:function(t,e){var i=this.getStore();return i.indexOf(t)>i.indexOf(e)},moveSelectedRow:function(t){var e,i,s=this.getStore(),n=this.getSelectionModel().getSelections(),a=s.getCount(),o=-1;if(!Ext.isEmpty(n)){for(n.sort(function(t,e){return s.indexOf(t)>s.indexOf(e)}),t?(o=s.indexOf(n.first())-1)<=0&&(o=0):(o=s.indexOf(n.last())+1)>=a-1&&(o=a-1),s.suspendEvents(),e=0;e<n.length;e++)s.remove(n[e]),i=0===e?o:this.store.indexOf(n[e-1])+1,s.insert(i,n[e]),this.isPriorityDirty=!0;s.resumeEvents(),this.view.refresh(),this.view.focusEl.focus()}},onColumnResize:function(){this.getView().fitColumns()},onClickUP:function(){this.moveSelectedRow(!0)},onClickDown:function(){this.moveSelectedRow(!1)},titleRenderer:function(t,e,i){var s=SYNO.SDS.DSMNotify.Utils.getTitle(t,!0,i.data.jsID,i.data.fn),n=Ext.util.Format.htmlEncode(s);return String.format('<div ext:qtip="{0}">{1}</div>',n,s)},getApplyData:function(){var t=[];return this.getStore().each(function(e){var i=e.data;Ext.isString(i.jsID)&&t.push(i)},this),t},isDataDirty:function(){var t=this.getStore().getModifiedRecords();return this.isPriorityDirty||0!==t.length}}),Ext.define("SYNO.SDS.DSMNotify.Setting.Application",{extend:"SYNO.SDS.AppInstance",appWindowName:"SYNO.SDS.DSMNotify.Setting.Window",constructor:function(t){this.callParent(arguments)}}),Ext.define("SYNO.SDS.DSMNotify.Setting.Window",{extend:"SYNO.SDS.AppWindow",NtSortByName:"sortBy",constructor:function(t){this.callParent([this.fillConfig(t)]),this.mon(this.grid,"loadHaveNtAppList",function(t){this.northPanel.getForm().setValues(t.data),this.onCheckTimeManual("time"===t.data.sortBy)},this),this.mon(this,"show",function(){this.grid.getStore().load()},this),this.mon(this,"beforeshow",function(){this.el.isMasked()||this.setStatusBusy(null,null,0)},this)},fillConfig:function(t){this.northPanel=new SYNO.ux.FormPanel({height:108,region:"north",margins:"0 20",trackResetOnLoad:!0,items:[{xtype:"syno_displayfield",value:_T("dsmnotify","brief_desc"),height:63,hideLabel:!0},{xtype:"syno_radiogroup",fieldLabel:_T("dsmnotify","sort_by"),hideLabel:!1,columns:[150,150],items:[{name:this.NtSortByName,boxLabel:_T("dsmnotify","time"),inputValue:"time",checked:!0,listeners:{check:function(t,e,i){this.onCheckTimeManual(e)},scope:this}},{xtype:"syno_radio",name:this.NtSortByName,boxLabel:_T("time","time_manual"),inputValue:"manual"}]}]}),this.southPanel=new SYNO.ux.FormPanel({height:35,region:"south",margins:"0 20",hideMode:"visibility",items:[{xtype:"syno_displayfield",value:'<span class="syno-ux-note">'+_T("dsmnotify","hint")+_T("common","colon")+" </span>"+_T("dsmnotify","dd_desc"),htmlEncode:!1,hideLabel:!0}]});var e={width:625,height:580,minimizable:!1,maximizable:!1,toggleMinimizable:!1,pinable:!1,minWidth:595,cls:"sds-notify-setting-dialog",closeAction:"onHandleHide",fbar:this.getFbar(),layout:"border",items:[this.northPanel,this.getGridPanel({region:"center",flex:1,margins:"0 20",owner:this}),this.southPanel]};return Ext.apply(e,t),e},onCheckTimeManual:function(t){this.isTime=!0,t?(this.grid.disableDD(),this.southPanel.hide()):(this.grid.enableDD(),this.southPanel.show(),this.isTime=!1,this.doLayout())},getFbar:function(){return new Ext.ux.StatusBar({defaultType:"syno_button",cls:"x-statusbar",items:[{xtype:"syno_button",btnStyle:"blue",text:_T("common","ok"),handler:this.onClickOK,scope:this},{xtype:"syno_button",text:_T("common","cancel"),handler:this.onHandleHide,scope:this}]})},getGridPanel:function(t){return this.grid=new SYNO.SDS.DSMNotify.Setting.GridPanel(t),this.grid},onClickOK:function(){var t=this.grid.getApplyData(),e=this.northPanel.getForm().findField(this.NtSortByName).getGroupValue(),i={scope:this,callback:function(){this.clearStatusBusy(),this.grid.getStore().commitChanges()}};this.isDataDirty()&&(this.setStatusBusy(),this.appInstance.setUserSettings("haveNtAppList",t),this.appInstance.setUserSettings("haveNtAppSortBy",e),SYNO.SDS.UserSettings.syncSave(i),SYNO.SDS.StatusNotifier.fireEvent("modifyHaveNtAppList")),this.hide()},isDataDirty:function(){return this.grid.isDataDirty()||this.northPanel.getForm().isDirty()},onHandleHide:function(){this.isDataDirty()?this.getMsgBox().confirm(_T("tree","leaf_notification"),_T("common","confirm_lostchange"),function(t){"yes"===t&&this.hide()},this):this.hide()}}),Ext.define("SYNO.SDS.DSMNotify.Utils",{statics:{isAppEnabled:function(t){if(Ext.isEmpty(t))return!0;var e=SYNO.SDS.StatusNotifier.isAppEnabled(t);if(_S("systemdr_running")&&"recovery_site"===_S("systemdr_role")){var i=SYNO.SDS.Config.FnMap[t];if(i&&Ext.isDefined(i.config)&&"app"===i.config.type){var s=i.config.supportSdrRecoverySite;i.config.supportSdrRecoverySite=!0,e=SYNO.SDS.StatusNotifier.isAppEnabled(t),i.config.supportSdrRecoverySite=!0===s}else-1!==_S("systemdr_pkg_enabled_info").indexOf(t)&&(e=!0)}return e},getTitle:function(t,e,i,s){return!0!==this.isAppEnabled(i)?_T("dsmnotify","error_title"):this.localizeMsgByFn(s,e,i)||this.localizeMsg(t,e,i)},getMsg:function(t,e,i,s){return!0!==this.isAppEnabled(i)?_T("dsmnotify","error_msg"):this.localizeMsgByFn(s,e,i)||this.localizeMsg(t,e,i)},localizeMsgByFn:function(t,e,i){var s,n,a=[];Ext.isArray(t)||(t=[t]);for(var o=1;o<t.length;o++)a.push(SYNO.SDS.Utils.GetLocalizedString(t[o]+"",i));return n=Ext.isString(t[0])?Ext.getClassByName(t[0]):"",Ext.isEmpty(n)||(s=n.apply(window,a)),e?Ext.util.Format.stripTags(s):s},localizeMsg:function(t,e,i){var s,n=[];Ext.isArray(t)||(t=[t]);for(var a=0;a<t.length;a++)n.push(SYNO.SDS.Utils.GetLocalizedString(t[a],i));return s=String.format.apply(String,n),e?Ext.util.Format.stripTags(s):s}}}),Ext.define("SYNO.SDS.DSMNotify.Application",{extend:"SYNO.SDS.AppInstance",trayItem:[],initInstance:function(t){this.trayItem[0]||(this.trayItem[0]=new SYNO.SDS.DSMNotify.Tray({appInstance:this}),this.addInstance(this.trayItem),this.trayItem[0].open(t)),this.createDetailDailogWindow(),this.createShowAllWindow(),Ext.getCmp("sds-taskbar").doLayout()},createShowAllWindow:function(){this.showAllWindow||(this.showAllWindow=new SYNO.SDS.DSMNotify.ShowAllDialog({appInstance:this}),this.addInstance(this.showAllWindow))},createDetailDailogWindow:function(){this.detailDailogWindow||(this.detailDailogWindow=new SYNO.SDS.DSMNotify.DetailDialog,this.addManagedComponent(this.detailDailogWindow))},onRequest:function(t){"showPanel"==t.action&&this.trayItem[0].onClick()}}),Ext.define("SYNO.SDS.DSMNotify.Tray",{extend:"SYNO.SDS.AppTrayItem",panel:null,taskbarBtnId:"sds-taskbar-notification-button",constructor:function(t){SYNO.SDS.DSMNotify.Tray.superclass.constructor.apply(this,arguments),this.panel=new SYNO.SDS.DSMNotify.Panel({module:this,baseURL:this.jsConfig.jsBaseURL}),this.addManagedComponent(this.panel),this.mon(Ext.getDoc(),"mousedown",this.onMouseDown,this),this.mon(SYNO.SDS.StatusNotifier,"checknotify",this.panel.reload,this.panel),this.mon(SYNO.SDS.StatusNotifier,"systemTrayNotifyMsg",this.panel.hide.createDelegate(this.panel,[!0],!1),this.panel),Ext.EventManager.onWindowResize(this.adjustPos,this),SYNO.SDS.TaskBar.rightTaskBar.buttons.push(this.taskButton),this.taskButton.disable()},onMouseDown:function(t){t.within(this.taskButton.el)||this.panel.isVisible()&&!t.within(this.panel.el)&&this.panel.hideBox()},setTitle:function(t){this.taskButton.setTooltip(t),this.taskButton.btnEl.setARIA({label:t,role:"button",tabindex:-1})},onBeforeDestroy:function(){this.panel=null,SYNO.SDS.DSMNotify.Tray.superclass.onBeforeDestroy.apply(this,arguments)},adjustPos:function(){this.panel.isVisible()&&this.panel.el.alignTo(Ext.getBody(),"tr-tr",[0,SYNO.SDS.TaskBar.getHeight()])},onClick:function(){this.taskButton.disabled||(this.panel.isVisible()?(this.panel.hideBox(),SYNO.SDS.TaskBar.rightTaskBar.toolbarEl.focus()):(SYNO.SDS.StatusNotifier.fireEvent("taskBarPanelShow"),this.panel.show(),this.panel.el.alignTo(Ext.getBody(),"tr-tr",[0,SYNO.SDS.TaskBar.getHeight()]),this.panel.dataview.getAriaEl().focus(300)))},getTaskBarBtnId:function(){return this.taskbarBtnId}}),Ext.define("SYNO.SDS.DSMNotify.Panel",{statics:{OneWeekSeconds:604800},extend:"Ext.Panel",storeId:"NotificationCenterTray",maxUnreadNum:30,currentUnreadNum:0,lastSeen:0,lastRead:0,pollTask:null,pollTaskConfig:null,pollingInterval:3e4,reloadTask:null,reloadDelay:1e3,badgeNumberId:Ext.id(),currentData:null,isFirstDataGetted:!1,badge:null,constructor:function(t){SYNO.SDS.DSMNotify.Panel.superclass.constructor.call(this,Ext.apply({hidden:!0,floating:!0,shadow:!1,title:this.getTitleStr(),height:Ext.lib.Dom.getViewHeight()-SYNO.SDS.TaskBar.getHeight(),cls:"sds-notify-tray-panel",renderTo:"sds-desktop",layout:"fit",bbar:[{xtype:"syno_button",btnStyle:"blue",text:_T("common","show_all"),scope:this,handler:this.onClickShowAll,id:this.showAllBtnId=Ext.id()},{xtype:"tbfill"},{xtype:"syno_button",btnStyle:"grey",text:_T("dsmnotify","clearall"),scope:this,handler:this.onClickClear,disabled:_S("demo_mode"),tooltip:_S("demo_mode")?_JSLIBSTR("uicommon","error_demo"):""}],items:this.dataview=new SYNO.ux.FleXcroll.DataView({itemSelector:"div.item",setEmptyText:function(){var t=Ext.getCmp("sds-notify-tray-panel-dataview"),e=Ext.id();return t.getAriaEl().setARIA({describedby:e}),String.format('<div class="sds-notify-empty-text" id="{2}" aria-label="{1}" style="line-height:{0}px">{1}</div>',Ext.lib.Dom.getViewHeight()-SYNO.SDS.TaskBar.getHeight()-36-48,_T("dsmnotify","empty_text"),e)},emptyText:this.setEmptyText,"aria-label":_T("dsmnotify","title"),itemId:"dataview",singleSelect:!0,useARIA:!0,useDefaultKeyNav:!1,id:"sds-notify-tray-panel-dataview",cls:"sds-notify-tray-panel-dataview",refresh:function(){this.tpl.msgDetailValues=[],this.emptyText=this.setEmptyText(),SYNO.ux.FleXcroll.DataView.superclass.refresh.call(this),Object.keys(this.tpl.msgDetailValues).forEach(function(t){Ext.get(t).on("click",function(){var e=this.tpl.msgDetailValues[t];this.ownerCt.module.appInstance.detailDailogWindow.open({category:this.tpl.getMsgTitle(e),event:this.tpl.getMsg(e),time:this.tpl.getMsgDate(e,!0),desc:this.tpl.getDesc(e,e.mailContent)}),this.ownerCt.hideBox()},this)}.bind(this))},store:new Ext.data.JsonStore({autoDestory:!0,storeId:this.storeId,fields:["title","items","className","firstItem","remainItems","expanded","unread"]}),tpl:new Ext.XTemplate('<div class="sds-notify-tray-panel-dataview-wrapper">','<tpl for=".">','<div class="{[this.getItemCls(values)]}" aria-label="{[this.getAriaSummary(values)]}" id="{[Ext.id()]}">','<div class="title blue-status">','<div class="{[this.getItemContentCls(values)]}" tabindex="-1" data-syno-app="{values.className}" data-syno-bind="{values.firstItem.bindEvt}" ext:qtip="{[this.localizeTitleNoTags(values.title, true, values.className)]}">{[this.getMsgTitle(values)]}</div>','<div class="items-count">{[this.getSuffixOfItemsCount(values.items)]}</div>','<tpl if="this.hasRemainItems(values)">','<div class="expand-icon" data-xindex="{[xindex]}" is-expanded-icon></div>',"</tpl>","</div>",'<div class="time" ext:qtip="{[this.getMsgDate(values.firstItem, true)]}">{[this.getMsgDate(values.firstItem, false)]}</div>','<div class="msg {this.selectableCls}" ext:qtip="{[this.localizeNoTags(values.firstItem.msg, true, values.firstItem.className, values.firstItem.fn)]}">',"{[this.getMsg(values.firstItem)]}","{[this.getShowDetailLink(values.firstItem)]}","</div>",'<div class="{[values.expanded === true ? "remain-items expanded" : "remain-items"]}" id="{[Ext.id()]}">','<tpl for="values.remainItems">','<div class="time" ext:qtip="{[this.getMsgDate(values, true)]}">{[this.getMsgDate(values, false)]}</div>','<div class="msg {this.selectableCls}" ext:qtip="{[this.localizeNoTags(values.msg, true, values.className, values.fn)]}">',"{[this.getMsg(values)]}","{[this.getShowDetailLink(values)]}","</div>","</tpl>","</div>","</div>","</tpl>","</div>",{compiled:!0,disableFormats:!0,hasRemainItems:function(t){return t.remainItems.length>0},getItemCls:function(t){return"item "+(t.unread?"unread":"")},getItemContentCls:function(t){var e=t.firstItem,i="content";return!1!==e.bindEvt&&Ext.isBoolean(e.bindEvt)&&e.className||(i+=" cursor-no-pointer"),t.items.length>1&&(i+=" grouped"),i},getSuffixOfItemsCount:function(t){return t.length>1?" ("+t.length+")":""},getMsgTitle:function(t){return this.localizeTitleNoTags(t.title,!0,t.className)},getMsg:function(t){return!0===t.isEncoded?this.localizeNoTags(t.msg,!1,t.className,t.fn):this.localize(t.msg,!1,t.className,t.fn)},getDesc:function(t,e){return!0===t.isEncoded?this.localizeNoTags(e,!1,t.className,t.fn):this.localize(e,!1,t.className,t.fn)},getMsgDate:function(t,e){var i,s,n=t.time;return s=(i=this.getCurrentTime()-n)<0,i>SYNO.SDS.DSMNotify.Panel.OneWeekSeconds||e||s?SYNO.SDS.DateTimeFormatter(new Date(1e3*t.time)):Ext.util.Format.relativeTime(1e3*n)},getAriaSummary:function(t){var e=this.getMsgTitle(t),i=this.getMsg(t),s=this.getMsgDate(t.firstItem,!1),n=String.format("{0} {1} {2}",e,i,s);return n=Ext.util.Format.stripTags(n),n=Ext.util.Format.htmlEncode(n)},getShowDetailLink:function(t){if(t.mailContent){var e=Ext.id();return this.msgDetailValues[e]=t,' <a id="'+e+'">'+_T("notification","more")+"</a>"}return""},localizeTitle:this.getTitle.createDelegate(this,[!1],!0),localizeTitleNoTags:this.encodedTitle.createDelegate(this,[!0],!0),localize:this.getMsg.createDelegate(this,[!1],!0),localizeNoTags:this.encodedMsg.createDelegate(this,[!0],!0),showUnreadTagLeft:this.showUnreadTag.createDelegate(this,[!0],!0),showUnreadTagRight:this.showUnreadTag.createDelegate(this,[!1],!0),showUnreadBadgeNumber:this.showUnreadBadgeNumber.createDelegate(this,[!1],!0),selectableCls:SYNO.SDS.Utils.SelectableCLS,getCurrentTime:this.getCurrentTime.createDelegate(this,[!1],!0),msgDetailValues:[]}),listeners:{click:function(t,e,i,s){SYNO.SDS.Utils.Notify.BindEvent(s),this.bindExpandedEvent(s)},scope:this}})},t)),Ext.StoreMgr.get(this.storeId).removeAll(),this.lastRead=SYNO.SDS.UserSettings.getProperty(this.module.jsConfig.jsID,"lastRead")||0,this.lastSeen=this.lastRead,this.pollTaskConfig={interval:this.pollingInterval,api:"SYNO.Core.DSMNotify",method:"notify",version:1,params:{action:"load",lastRead:this.lastRead,lastSeen:this.lastSeen},scope:this,callback:this.onFirstData},this.pollTask=this.addWebAPITask(this.pollTaskConfig).start(!0),this.reloadTask=new Ext.util.DelayedTask(this.pollTask.restart,this.pollTask),this.mon(SYNO.SDS.StatusNotifier,"redirect",this.pollTask.stop,this.pollTask),this.mon(SYNO.SDS.StatusNotifier,"halt",this.pollTask.stop,this.pollTask),this.mon(Ext.get(this.settingId),"click",this.onClickSetting,this),this.mon(SYNO.SDS.StatusNotifier,"modifyHaveNtAppList",this.onModifyHaveNtAppList,this),this.keyNav=new Ext.KeyNav(this.el,{down:function(t){this.dataview.selectNextItem()},up:function(t){this.dataview.selectPreItem()},esc:function(){this.module.onClick()},scope:this})},bindExpandedEvent:function(t){if(t&&t.target&&t.target.hasAttribute("is-expanded-icon")){var e=t.target,i=parseInt(e.getAttribute("data-xindex"),10)-1,s=Ext.fly(e).parent(".item");this.expandRemainItems(s,this.groupedData[i])}},expandRemainItems:function(t,e){var i=t.child(".remain-items"),s=t.child(".expand-icon");e.expanded=!e.expanded,i&&(i.setVisibilityMode(Ext.Element.DISPLAY),e.expanded?(i.slideIn("t",{duration:.25,callback:this.afterExpandAnim.bind(this)}),s.addClass("expanded")):(i.slideOut("t",{duration:.25,callback:this.afterExpandAnim.bind(this)}),s.removeClass("expanded")))},afterExpandAnim:function(){this.dataview.updateFleXcroll()},onModifyHaveNtAppList:function(){this.pollTask.restart()},getTitleStr:function(){this.settingId=Ext.id();return String.format('<div class="sds-notify-setting-btn" id="{0}">&nbsp;</div><span class="x-panel-header-text" >{1}</span>',this.settingId,_T("dsmnotify","title"))},reload:function(){this.reloadTask.delay(this.reloadDelay)},showUnreadTag:function(t,e){return t?"":e?"<b>":"</b>"},getTitle:function(t,e,i,s){return SYNO.SDS.DSMNotify.Utils.getTitle(t,e,i,s)},getMsg:function(t,e,i,s){return SYNO.SDS.DSMNotify.Utils.getMsg(t,e,i,s)},encodedMsg:function(t,e,i,s){return Ext.util.Format.htmlEncode(this.getMsg(t,e,i,s))},encodedTitle:function(t,e,i,s){return Ext.util.Format.htmlEncode(this.getTitle(t,e,i,s))},sortMsg:function(t,e){if(!Ext.isObject(t)||"time"!==t.sortBy){var i=e||t.items,s=t.priorityMap;i.sort(function(t,e){var i=t.className,n=e.className;return Ext.isEmpty(s[i])&&Ext.isEmpty(s[n])?0:Ext.isEmpty(s[i])?1:Ext.isEmpty(s[n])?-1:s[i]-s[n]})}},sendNotify:function(t){if(Ext.isArray(t)){var e=t[0].time;Ext.each(t,function(t){var i=SYNO.SDS.AppMgr.getByAppName(t.className);t.time<=this.lastSeen||i.length>0&&!1===i[0].shouldNotifyMsg(t.tag,t)||t.time>e||(e=t.time,SYNO.SDS.SystemTray.notifyMsg(t.className,this.getTitle(t.title,!1,t.className),this.getMsg(t.msg,!1,t.className,t.fn),null,t.isEncoded))},this)}},bindClickEvent:function(t){this.mon(Ext.get(t),"click",function(){},this)},onClickSetting:function(){SYNO.SDS.AppLaunch("SYNO.SDS.DSMNotify.Setting.Application"),this.hideBox()},onClickClear:function(){Ext.StoreMgr.get(this.storeId).removeAll(),this.hideBox(),SYNO.API.Request({api:"SYNO.Core.DSMNotify",method:"notify",version:1,params:{action:"apply",clean:"all"},scope:this,callback:function(t,e,i,s){t&&(SYNO.SDS.UserSettings.setProperty(this.module.jsConfig.jsID,"lastRead",0),SYNO.SDS.StatusNotifier.fireEvent("notificationPanelClearAll"))}}),this.currentData=null},onClickShowAll:function(){this.module.appInstance.showAllWindow.open(),this.hideBox()},getItemKey:function(t){var e=t.className?t.className:"",i="";return t.msg.length>0&&(i=t.msg[0].hashCode()),e+":"+t.title+":"+i},getGroupedData:function(){var t={},e=[];if(!this.currentData||!this.currentData.total)return e;for(var i=0;i<this.currentData.total;i++){var s=this.currentData.items[i],n=this.getItemKey(s);t[n]||(t[n]={});var a=t[n];s.time>this.lastRead&&(s.unread=!0,a.unread=!0),a.title=s.title,a.className=s.className,a.items||(a.items=[]),a.items.push(s)}for(var o in t)t.hasOwnProperty(o)&&e.push({className:t[o].className,title:t[o].title,firstItem:t[o].items[0],remainItems:t[o].items.slice(1,t[o].items.length),items:t[o].items,unread:t[o].unread});return e},onShow:function(){if(!this.isFirstDataGetted)return!1;this.groupedData=this.getGroupedData(),this.lastRead=this.lastSeen,this.pollTaskConfig.params.lastRead=this.lastRead,SYNO.SDS.UserSettings.setProperty(this.module.jsConfig.jsID,"lastRead",this.lastRead),SYNO.SDS.DSMNotify.Panel.superclass.onShow.apply(this,arguments),this.pollTask.stop();var t=_T("common","show_all");this.currentUnreadNum>this.maxUnreadNum&&(t=_T("common","unread").replace("{@}",this.currentUnreadNum-this.maxUnreadNum)),Ext.getCmp(this.showAllBtnId).setText(t),Ext.isEmpty(this.currentData)||Ext.StoreMgr.get(this.storeId).loadData(this.groupedData),this.setHeight(Ext.lib.Dom.getViewHeight()-SYNO.SDS.TaskBar.getHeight()),this.badge&&this.badge.setNum(0)},onFirstData:function(t,e,i,s){if(t){var n={data:e};this.isFirstDataGetted=!0,this.module.taskButton.enable(),this.currentData=n.data,Ext.isArray(n.data.items)&&n.data.items.length&&(this.lastSeen=n.data.newestMsgTime,!_S("demo_mode")&&n.data.unread>0&&Ext.defer(this.updateUnreadNumber,500,this,[n.data.unread])),Ext.apply(this.pollTaskConfig,{interval:this.pollingInterval,params:{action:"load",lastRead:this.lastRead,lastSeen:this.lastSeen},callback:this.onPaddingData}),this.pollTask.applyConfig(this.pollTaskConfig),this.updateGroupSettingsMTime(n.data)}},onPaddingData:function(t,e,i,s){if(t){var n=e;if(this.updateGroupSettingsMTime(n),Ext.isArray(n.items)){if(0===n.items.length)return Ext.StoreMgr.get(this.storeId).removeAll(),void this.hideBox(!0);this.nowSec=(new Date).getTime()/1e3,this.sendNotify(n.items),this.lastSeen=n.newestMsgTime,this.pollTaskConfig.params.lastRead=this.lastRead,this.pollTaskConfig.params.lastSeen=this.lastSeen,this.pollTask.applyConfig(this.pollTaskConfig),this.currentData=n,this.isVisible()&&Ext.StoreMgr.get(this.storeId).loadData(this.getGroupedData()),this.isVisible()||Ext.defer(this.updateUnreadNumber,500,this,[n.unread])}}},getCurrentTime:function(){return Ext.isNumber(this.nowSec)?this.nowSec:(new Date).getTime()/1e3},updateGroupSettingsMTime:function(t){t&&t.admingrpsetmtime&&SYNO.SDS.GroupSettings.reload(t.admingrpsetmtime)},showUnreadBadgeNumber:function(t,e){if(!0===e)return"";var i=t.size();if(0===i)return"";i>99&&(i=100);var s=14*(i-1);return String.format("background-position: left -{0}px",s)},updateUnreadNumber:function(t){this.badge?this.badge&&this.badge.updateBadgePos():(this.badge=new SYNO.SDS.Utils.Notify.Badge({disableAnchor:!0,badgeClassName:"sds-notify-badge-num badge-fix-position",renderTo:this.module.taskButton.btnEl}),this.module.taskButton.badge=this.badge),this.badge.badgeNum!=t&&this.badge.setNum(t)},hideBox:function(t){!t&&this.isFirstDataGetted&&this.pollTask.start(),this.module.taskButton.toggle(!1,!0),this.hide()}});