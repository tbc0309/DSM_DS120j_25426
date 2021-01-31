/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.ns("SYNO.SDS._Widget.Config");Ext.define("SYNO.SDS._Widget.ViewConfig",{statics:{ModuleOrder:["SYNO.SDS.SystemInfoApp.SystemHealthWidget","SYNO.SDS.ResourceMonitor.Widget","SYNO.SDS.SystemInfoApp.StorageUsageWidget","SYNO.SDS.SystemInfoApp.ConnectionLogWidget","SYNO.SDS.BackupApp.ScheduleBackupWidget","SYNO.SDS.TaskScheduler.TaskSchedulerWidget","SYNO.SDS.SystemInfoApp.FileChangeLogWidget","SYNO.SDS.SystemInfoApp.RecentLogWidget"],ModuleList:["SYNO.SDS.SystemInfoApp.SystemHealthWidget","SYNO.SDS.ResourceMonitor.Widget"]}});Ext.define("SYNO.SDS._JustViewWindowManager",{extend:"SYNO.SDS._WindowMgr",orderWindows:Ext.emptyFn,register:function(a){this.callParent(arguments);a.un("hide",this.activateLast,this)},getWindow:function(a){var b=this,c=null;b.each(function(d){if(a===d.widgetClassName){c=d;return false}},b);return c}});SYNO.SDS.WidgetViewWindowManager=new SYNO.SDS._JustViewWindowManager();Ext.define("SYNO.SDS.ModuleLoader",{extend:"Ext.util.Observable",constructor:function(){var a=this;a.callParent(arguments);a.addEvents("load")},loadModule:function(a,b){try{var d=SYNO.SDS.Config.FnMap[a];if(!d){return false}if(b){return true}SYNO.SDS.JSLoad(a,function(){this.fireEvent("load",this,a,d)},this)}catch(c){SYNO.Debug("Fail to add module"+c);return false}return true}});Ext.define("SYNO.SDS.WidgetList.WidgetItem",{constructor:function(a){var b=this;Ext.apply(b,a||{})}});Ext.define("SYNO.SDS.Widget.ModuleLoader",{extend:"SYNO.SDS.ModuleLoader",constructor:function(){var a=this;a.addEvents("add");a.callParent(arguments);a.on("load",a.onLoadModule,a)},createWidget:function(name){if(!SYNO.SDS.Config.FnMap[name]){this.loadModule(name);return null}var app=SYNO.SDS.Config.FnMap[name];var config=app.config;var title=SYNO.SDS.Utils.GetLocalizedString(config.title,[name,config.appInstance]);var genCfg={name:name,jsConfig:config,owner:this,getJSConfig:function(){return config}};var cfg={itemId:name,windowTitle:title,baseCls:"sds-widget-panel",headerCssClass:"sds-widget-panel-title",bodyCssClass:"sds-widget-panel-body",height:172,widgetParams:config,iconURL:SYNO.SDS.UIFeatures.IconSizeManager.getIconPath(encodeURI(config.jsBaseURL)+"/"+config.icon,""),shadow:false},panel;Ext.apply(cfg,genCfg);eval(String.format("var panel = new {0}(cfg);",name));Ext.apply(panel,genCfg);return panel},onLoadModule:function(a,b){this.onLoadWidgetModule(b)},onLoadWidgetModule:function(b){var c=this,a=c.createWidget(b);c.fireEvent("add",c,a,b);return true}});Ext.define("SYNO.SDS.WidgetList.Model",{getWidgetList:function(c){if(!c&&this.allWidgetList){return this.allWidgetList}var a=[],i=SYNO.SDS._Widget.ViewConfig.ModuleOrder,f=this.getSelectedWidgetList(),e=-1,h,g={},b={},d={};for(h in SYNO.SDS.Config.FnMap){if(SYNO.SDS.Config.FnMap.hasOwnProperty(h)){g=SYNO.SDS.Config.FnMap[h];b=g.config;if(g&&b&&"widget"===b.type){e=f.indexOf(h);d=new SYNO.SDS.WidgetList.WidgetItem({name:h,index:e,selected:(e!==-1),jsConfig:b,menuOrder:i.indexOf(h),title:SYNO.SDS.Utils.GetLocalizedString(b.title,[name,b.appInstance])});a.push(d)}}}a.sort(function(k,j){if(k.menuOrder<0){return 1}if(j.menuOrder<0){return -1}return(k.menuOrder-j.menuOrder)>0?1:-1});this.allWidgetList=a;return this.allWidgetList},reloadWidgetList:function(){return this.getWidgetList(true)},setSelectedWidgetList:function(a){this.selectedWidgetList=Ext.isArray(a)?(Ext.isArray(a)?a:[]):SYNO.SDS._Widget.ViewConfig.ModuleList},getSelectedWidgetList:function(){var b=this,a=b.selectedWidgetList;return Ext.isArray(a)?a:[]},addSelectedWidget:function(c){var b=this,a=b.getSelectedWidgetList();if(a.indexOf(c)===-1){a.unshift(c)}},removeSelectedWidget:function(d){var c=this,a=c.getSelectedWidgetList(),b=a.indexOf(d);if(b!==-1){a.splice(b,1)}},getIndex:function(b){var a=this.getSelectedWidgetList();return a.indexOf(b)}});Ext.define("SYNO.SDS.WidgetList.Controller",{extend:"Ext.util.Observable",moduleListString:"modulelist",constructor:function(a){var b=this;Ext.apply(b,a);b.callParent(arguments);b.init()},init:function(){var a=this;a.initComponent();a.initEvents();a.initLoaderEvents();a.initViewEvents();a.initModel()},initComponent:function(){var a=this;a.model=new SYNO.SDS.WidgetList.Model();a.widgetLoader=new SYNO.SDS.Widget.ModuleLoader()},initViewEvents:function(){var b=this,a=b.view;if(!Ext.isDefined(a)){return}a.on("getwidgetlist",b.onGetWidgetList,b);a.on("removewidget",b.onRemoveWidget,b);a.on("addwidget",b.onAddWidget,b)},initEvents:function(){var a=this;a.addEvents("reload")},initLoaderEvents:function(){var a=this;a.widgetLoader.on("add",a.onLoadWidgets,a)},initModel:function(){var c=this,b=c.model,a=c.view,d=[];if(a){b.setSelectedWidgetList(a.getWidgetList())}c.widgets=[];d=b.getWidgetList(true);c.validWidgetList=Ext.partition(d,function(e){return e.selected===true})[0];c.validWidgetList.each(function(e){this.loadWidget(e.name)},c)},onLoadWidgets:function(h,c,a){var e=this,f=e.view,d=e.model,i=e.validWidgetList,g=e.widgets,b=d.getIndex(a);c.index=b;g.push({widget:c,index:b});if(i.length===0||g.length===i.length){g.sort(function(k,j){if(k.index<0){return 1}if(j.index<0){return -1}return(k.index-j.index)>0?1:-1});f.addWidgets(Ext.pluck(g,"widget"));e.widgetLoader.un("add",e.onLoadWidgets,e);e.widgetLoader.on("add",e.onLoadWidget,e)}},onLoadWidget:function(a,f,e){var d=this,b=d.view,c=d.model;b.addWidgetItem(f,c.getIndex(e))},loadWidget:function(c){var b=this,a=b.widgetLoader;a.loadModule(c)},onAddWidget:function(a,d){var c=this,b=c.model;b.addSelectedWidget(d);c.loadWidget(d)},onRemoveWidget:function(a,d){var c=this,b=c.model;b.removeSelectedWidget(d)},onGetWidgetList:function(){var c=this,a=c.view,b=c.model;a.initAddWidgetContextMenu(b.getWidgetList())}});Ext.define("SYNO.SDS.WidgetWindowFactory",{createWidgetWindow:function(b,a){var c=Ext.apply({},a||{});c=Ext.applyIf(c,{anchor:"100%",manager:SYNO.SDS.WidgetViewWindowManager,draggable:true,layout:b.widgetLayout,title:b.windowTitle,renderTo:undefined,addable:false,maximizable:true,minimizable:b.minimizable,pinned:false,pinable:false,closable:true,onlyView:false,floating:false,widget:b,items:[b],widgetClassName:b.name,itemId:b.name,onItemDeactivate:b.onDeactivate.createDelegate(b),onItemActivate:b.onActivate.createDelegate(b)});c=Ext.apply(c,{hidden:b.minimizable&&c.hidden});var d=new SYNO.SDS.WidgetWindow(c);return d},addWidgetWindowToDesktop:function(c,a){var b=this,d=null;a=Ext.applyIf(a,{manager:b.widgetWindowManager,onlyView:false,draggable:true,pinable:true,hidden:true,addable:false,closable:true,cls:"",maximizable:true,minimizable:c.minimizable});if(c){d=b.createWidgetWindow(c,a);return d}}});Ext.define("SYNO.SDS._WidgetPanel",{animateMoveClass:"animate-move",lastItemCls:"last-item",extend:"SYNO.SDS.AppWindow",widgetListString:"restoreParams",moduleListString:"modulelist",constructor:function(a){var b=this,c=164;a=a||{};a=Ext.apply({cls:"syno-sds-widget "+(SYNO.SDS.ThemeProvider.getThemeCls()===SYNO.SDS.DSM.Themer.BUSINESS?"white-scrollerbar":""),autoScroll:false,height:466,width:344,minWidth:340,minHeight:c,pinable:true,dockable:true,closable:false,minimizable:true,maximizable:false,resizable:true,constrainHeader:true,resizeHandles:"n s",layout:{type:"auto",extraCls:"syno-sds-widget-item"},hidden:true,autoFlexcroll:true,showHelp:false,trayIconConfig:{enableToggle:true,tooltip:_T("widget","widget_view"),renderTo:"sds-taskbar-widget-button",listeners:{afterrender:{fn:function(d){d.getEl().child("button").set({tabindex:-1})}}}}},a);if(a.trayIconConfig){b.initTrayIconButton(a.trayIconConfig)}if(Ext.isNumber(a.height)){a.height=Math.max(a.height,c)}b.callParent([a]);this.preventFocus()},preventFocus:function(){var a=Ext.urlDecode(location.search.substr(1)),b=a.accessible;if(b){this.onClose()}this.el.addKeyListener(Ext.EventObject.TAB,function(){this.onClose();Ext.get("sds-taskbar-showall").child("button").focus()},this)},initDraggable:function(){var a=this;a.dd=new SYNO.SDS.WidgetPanel.DD(a)},registerDD:function(){this.dropZone=new SYNO.SDS.WidgetPanel.DropZone(this.body,{owner:this,ddGroup:"WidgetReorderAndShortCut"})},initComponent:function(){var a=this;a.callParent();a.widgetListController=new SYNO.SDS.WidgetList.Controller({view:a});a.widgetWindowFactory=new SYNO.SDS.WidgetWindowFactory();a.fireEvent("getwidgetlist",a);a.initDockContextMenu()},initTrayIconButton:function(a){if(!_S("standalone")){a=a||{};a=Ext.applyIf(a,{toggleHandler:this.onToggle.createDelegate(this)});this.taskBarButton=SYNO.SDS.TaskBar.addTrayIconViewButton(a)}},onMinimize:function(){if(this.minimizable){this.hide((Ext.isIE9m&&!Ext.isIE9)?undefined:this.taskBarButton.el)}else{this.el.frame()}SYNO.SDS.AppWindow.superclass.onMinimize.apply(this,arguments)},toggleButton:function(d,c){var b=this,a=b.taskBarButton;if(a){a.toggle(d,c)}},onToggle:function(a,b){this[b?"show":"hide"]((Ext.isIE9m&&!Ext.isIE9)?undefined:this.taskBarButton.el)},onClose:function(){this.hide();return false},hide:function(){var a=this;a.callParent(arguments);a.toggleButton(false,true)},show:function(){var a=this;a.callParent(arguments);a.toggleButton(true,true)},createWidgetWindow:function(b,a){return this.widgetWindowFactory.createWidgetWindow(b,a)},getWidgetList:function(){var a=this;return a.appInstance.getUserSettings(a.moduleListString)},addWidgetItem:function(b,c){var e=this,d,a={};if(Ext.isNumber(c)){a.index=c}d=e.createWidgetWindow(b,a);d.addClass("syno-sds-widget-item");e.insert((Ext.isNumber(c)?c:0),d);e.doLayout();e.openWidget(d);e.doLayout()},runScrollTo:function(b){var a=this;a.runTask("doScrollTo",a.fleXcrollTo,100,[b])},findWidgetParam:function(f){var e=this,c=0,g=e.appInstance.getUserSettings(e.widgetListString)||{},b=g.windowState?g.windowState.widgets||[]:[],d=b.length,a={};for(c=0;c<d;c++){a=b[c];if(f!==a.widgetClassName){continue}return a}return{}},addWidgets:function(f){var h=this,e=0,g,c=f.length,b,a={},d=h.minimizeWidgets||[];h.removeAll();for(e=0;e<c;e++){a={};b=f[e];a=h.findWidgetParam(b.name);g=h.createWidgetWindow(b,a);if(a.minimized===true){d.push(g)}else{h.add(g)}}h.doLayout();h.items.each(function(i){h.openWidget(i)},h);d.each(function(i){h.openWidget(i,true)},h);h.minimizeWidgets=d;h.innerDoLayout()},openWidget:function(c,a){var b=this;b.setWidgetBehavior(c);c.onOpen();b[(b.isVisible()||a)?"onMoudleActivate":"onMoudleDeactivate"](c);c.setIcon(c.widget.iconURL)},setWidgetBehavior:function(b){var a=this;a.mon(b,"close",a.onWidgetClose,a);a.mon(b,"show",a.onWidgetShow,a);a.mon(b,"restore",a.innerDoLayout,a);a.mon(b,"minimize",a.onWidgetMinimize,a);a.mon(b,"maximize",a.innerDoLayout,a)},onWidgetShow:function(d){var c=this,b=c.minimizeWidgets||[],a=b.indexOf(d);if(c.items.indexOf(d)===-1&&a!==-1){c.add(d);if(!c.isVisible()){c.show()}}if(a!==-1){b.splice(a,1)}d.getEl().setStyle({visibility:"inherit"});c.doLayout();d.addClass("syno-sds-widget-item");c.minimizeWidgets=b},onWidgetMinimize:function(c){var b=this,a=b.minimizeWidgets||[];b.remove(c,false);a.push(c);b.innerDoLayout();b.minimizeWidgets=a},onWidgetClose:function(c){var b=this,d=b.initAddWidgetContextMenu(),a;a=d.getComponent(c.itemId);if(a){a.setChecked(false)}},removeWidget:function(a){var f=this,d=0,c=f.minimizeWidgets||[],e=c.length,g,b=-1;for(d=0;d<e;d++){if(a===c[d].widgetClassName){b=d;g=c[d];break}}if(b!==-1){c.splice(b,1);f.minimizeWidgets=c;f.onMoudleDeactivate(g)}else{g=f.items.get(a);f.onMoudleDeactivate(g);f.remove(a,false)}g.close();f.innerDoLayout();f.fireEvent("removewidget",f,a)},addWidget:function(a){var b=this;b.fireEvent("addwidget",b,a)},innerDoLayout:function(){var a=this;a.runTask("doLayoutTask",a.doLayout,250)},getAddWidgetActions:function(g){var b=0,e,f=g||[],d=f.length,a=[],c=function(h,i){this[i?"addWidget":"removeWidget"](h.widgetClassName)};for(b=0;b<d;b++){e=f[b];a.push(new Ext.menu.CheckItem({checked:e.selected,text:e.title,widgetClassName:e.name,itemId:e.name,hideOnClick:false,scope:this,checkHandler:c}))}return a},refreshWidgetContextMenu:function(b){var a=this;a.addWidgetMenu=undefined;a.initAddWidgetContextMenu(b||[])},initAddWidgetContextMenu:function(b){if(this.addWidgetMenu){return this.addWidgetMenu}var a=new SYNO.ux.Menu({cls:"syno-ux-groupcheck-menu",items:this.getAddWidgetActions(b)||[]});this.addWidgetMenu=a;this.addManagedComponent(this.addWidgetMenu);return a},onClickWidgetContextMenu:function(c){var a=this,d=a.initAddWidgetContextMenu(),b=c.getTarget();d.show(b,"tl-bl")},onDockRightTop:function(a,b){if(b===true){this.setDocked(0)}},onDockLeftTop:function(a,b){if(b===true){this.setDocked(2)}},onDockRightBottom:function(a,b){if(b===true){this.setDocked(1)}},onDockLeftBottom:function(a,b){if(b===true){this.setDocked(3)}},dockTo:function(e,b){var d=this,c=8,f=8,a=e?c:Math.max(d.container.getWidth()-d.getWidth()-c,c),g=!b?f:Math.max(d.container.getHeight()-d.getHeight()-f,f);d.setPosition(a,g)},getDockActions:function(){var b=0,d,e=[["righttop","RightTop"],["rightbottom","RightBottom"],["lefttop","LeftTop"],["leftbottom","LeftBottom"]],c=e.length,a=[];for(b=0;b<c;b++){d=e[b];a.push(new Ext.menu.CheckItem({group:"widget-dock",scope:this,text:_T("widget","dock_"+d[0]),checkHandler:this["onDock"+d[1]]}))}return a},initDockContextMenu:function(){var a=this;if(a.dockMenu){return a.dockMenu}var b=new SYNO.ux.Menu({cls:"syno-ux-groupcheck-menu",items:a.getDockActions()||[]});a.dockMenu=b;a.addManagedComponent(a.dockMenu);return b},initTools:function(){var a=this;a.callParent(arguments);if(a.pinable){a.addTool({id:"pin",qtip:Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(_T("widget","widget_on_top"))),handler:a.onPin.createDelegate(this)})}if(a.dockable){a.addTool({id:"dock",qtip:Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(_T("widget","dock_to"))),handler:a.onClickDock.createDelegate(this)})}},onClickDock:function(c){var a=this,d=a.initDockContextMenu(),b=c.getTarget();d.show(b,"tr-br")},setDockToolToggled:function(b){var a=this;if(a.dockable){this.tools.dock[b?"addClass":"removeClass"]("x-tool-toggled")}},dock:function(a){this.setDocked(Ext.isNumber(a)?a:this.docked)},undock:function(){this.setDocked(false)},setDocked:function(d){var c=this,a=c.initDockContextMenu(),b;c.docked=d;c.setDockToolToggled(Ext.isNumber(d));if(Ext.isNumber(d)){c.dockTo(d>>1,d%2);b=a.items.item(d);if(b&&b.setChecked){b.setChecked(true,true)}}else{a.items.each(function(e){e.setChecked(false,true)},c)}},setPinToolToggled:function(b){var a=this;if(a.pinable){this.tools.pin[b?"addClass":"removeClass"]("x-tool-toggled");this.tools.pin.dom.qtip=Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(b?_T("widget","cancal_on_top"):_T("widget","widget_on_top")))}},isAlwaysOnTop:function(){return this.pinned},setPinStatus:function(a){this[a===true?"pin":"unpin"]()},onPin:function(){this[this.pinned===true?"unpin":"pin"]()},pin:function(){this.setPinned(true)},unpin:function(){this.setPinned(false)},setPinned:function(a){var b=this;b.pinned=a;b.setPinToolToggled(a);b.manager.orderWindows()},initEvents:function(){var a=this;a.callParent(arguments);if(a.resizable){if(a.resizer){a.resizer.destroy()}a.resizer=new SYNO.SDS.WidgetPanel.Resizeable(a.el,{minWidth:a.minWidth,minHeight:a.minHeight,handles:a.resizeHandles||"all",pinned:a,resizeElement:a.resizerAction,handleCls:"x-window-handle"});a.resizer.window=a;a.mon(a.resizer,"beforeresize",a.beforeResize,a)}},setAddWidgetIcon:function(){var a=this;a.addWidgetIcon=a.header.createChild({cls:"widget-panel-icon-click","ext:qtip":Ext.util.Format.htmlEncode(Ext.util.Format.htmlEncode(_T("widget","add_widget")))});a.mon(a.addWidgetIcon,"click",a.onClickWidgetContextMenu,a)},handleMsg:function(){var c=this,b=c.minimizeWidgets||[],a=Ext.util.Format.htmlEncode(_T("widget","plz_add_widget"));if((c.items.getCount()+b.length)===0){c.msgEl=c.msgEl||c.getEl().createChild({cls:"widget-panel-msg",html:String.format('<div class="icon"></div><div class="msg disable-font" ext:qtip="{0}">{1}</div>',Ext.util.Format.htmlEncode(a),a),"ext:qtip":Ext.util.Format.htmlEncode(a)});c.msgEl.setVisibilityMode(Ext.Element.DISPLAY);c.msgEl.show()}else{if(c.msgEl){c.msgEl.hide()}}},registerWindowResizeEvent:function(){var a=this;Ext.EventManager.onWindowResize(a.runDockTask,a)},registerWindowOrientationChangeEvent:function(){var a=this;Ext.EventManager.on(window,"orientationchange",a.runDockTask,a)},registerEvents:function(){var a=this;a.mon(a,"resize",function(){this.runDockTask()},a);a.mon(a,"hide",function(){this.onShowHide();this.removeClass(a.animateMoveClass)},a);a.mon(a,"show",function(){this.onShowHide();this.innerDoLayout();this.addClass(a.animateMoveClass)},a);a.registerWindowResizeEvent();a.registerWindowOrientationChangeEvent()},loadParams:function(b){var a=this;a.show();if(!b){a.setDocked(1)}if(b&&b.windowState){b=b.windowState;if(b.minimized){a.hide()}a.setDocked(Ext.isDefined(b.docked)?b.docked:1);a.setPinned(b.pinned)}},afterRender:function(){var a=this,b={};a.header.addClass("widget-panel-header");a.setAddWidgetIcon();a.callParent(arguments);if(_S("ha_safemode")){a.hide();return}a.mon(a,"afterlayout",function(){this.handleMsg();this.setItmeStyle();this.runAdjustWidthTask()},a);a.mon(a,"added",function(){this.setItmeStyle()},a);a.mon(a,"removed",function(){this.setItmeStyle()},a);a.registerEvents();a.registerDD();b=a.appInstance.getUserSettings(a.widgetListString);a.loadParams(b);a.addClass(a.animateMoveClass)},setItmeStyle:function(){var e=this,a=e.items,b=0,d=a.length,c;for(b=0;b<d;b++){c=a.get(b);if(c){c[(b===d-1)?"addClass":"removeClass"](e.lastItemCls)}}},runAdjustWidthTask:function(){var a=this;a.runTask("adjustWidthTask",a.adjustWidthWithScrollBar,250)},runDockTask:function(){var a=this;a.runTask("dockTask",a.dock.createDelegate(a,[]),250)},adjustWidthWithScrollBar:function(){var c=this,b=c.getEl(),a=344,d={};if(!c.rendered||!c.body){return c}c.updateFleXcroll();d=c.getFleXcrollInfo(c.body.dom);if(!d.hasVerticalScroll){a-=4;b.setWidth(a);c.body.setWidth(a)}else{b.setWidth(a);c.body.setWidth(a);c.updateScroller()}c.runDockTask();return c},isSkipActive:function(){return this.isAlwaysOnTop()},isSkipUnexpose:function(){return true},onDeactivate:function(){var a=this;a.callParent(arguments);this.el.removeClass("deactive-win")},onResize:function(){var a=this;a.callParent(arguments);a.runAdjustWidthTask();return a},onShowHide:function(){var a=this;a.runTask("runAllTask",a.runAll)},runAll:function(){var a=this;a.items.each(function(b){this[this.isVisible()?"onMoudleActivate":"onMoudleDeactivate"](b)},a)},onMoudleActivate:function(a){if(!a){return}if(Ext.isFunction(a.onItemActivate)){this.onMoudleDeactivate(a);a.onItemActivate()}},onMoudleDeactivate:function(a){if(!a){return}if(Ext.isFunction(a.onItemDeactivate)){a.onItemDeactivate()}},getStateParam:function(){var c=this,d=c.callParent(arguments),b=[],a=c.minimizeWidgets||[];c.saveWidgetOrder();c.items.each(function(e){b.push(e.getStateParam())},c);a.each(function(e){b.push(e.getStateParam())},c);if(c.pinned){d.pinned=c.pinned}if(Ext.isNumber(d.height)){d.height=Math.max(c.minHeight,d.height)}d.docked=c.docked;d.widgets=b;return d},destroy:function(){var a=this,b=["runAllTask","adjustWidthTask","doScrollTo","doLayoutTask","dockTask"];Ext.each(b,function(c){this.removeDelayedTask(c)},a);Ext.destroy(a.dropZone);a.callParent(arguments)},saveWidgetOrder:function(){var f=this,c=0,d=f.items,e=d.length,a=[],b=f.minimizeWidgets||[];for(c=0;c<e;c++){a.push(d.get(c).widgetClassName)}e=b.length;for(c=0;c<e;c++){a.push(b[c].widgetClassName)}f.appInstance.setUserSettings(f.moduleListString,a)}});Ext.define("SYNO.SDS.WidgetPanel.DD",{extend:"Ext.Window.DD",startDrag:function(a,d){var b=this,c=b.win;c.removeClass(c.animateMoveClass);b.callParent(arguments);b.win.undock()},endDrag:function(c){var a=this,b=a.win;a.callParent(arguments);b.addClass(b.animateMoveClass)}});Ext.define("SYNO.SDS.WidgetPanel.DropZone",{extend:"Ext.dd.DropZone",constructor:function(b,a){this.callParent(arguments);this.win=a.owner},createEvent:function(a,c,b,d){return{win:this.win,panel:b.panel,position:d,data:b,source:a,rawEvent:c,status:this.dropAllowed}},notifyOver:function(r,l,d){var n=this,s=l.getXY(),j=n.win,q=r.proxy,k=0;if(!n.boxArray){n.boxArray=n.getBoxArray()}var a,g=false,o=0,m=j.items,i=false,c,b=false;for(k=m.getCount();o<k;o++){a=m.get(o);if(o===(k-1)){b=true}var f=a.el.getHeight();if(a.id===d.panel.id){i=true}else{if((a.el.getY()+(f/2))>s[1]){g=true;break}}}o=(g&&a?o:k)+(i?-1:0);c=n.createEvent(r,l,d,o);if(j.fireEvent("validatedrop",c)!==false&&j.fireEvent("beforedragover",c)!==false){if(a){if(b&&!g){q.getProxy().addClass(j.lastItemCls)}else{q.getProxy().removeClass(j.lastItemCls)}q.moveProxy(a.el.dom.parentNode,g?a.el.dom:null)}n.lastPos={p:i||(g&&a)?o:false};j.fireEvent("dragover",c);return c.status}else{return c.status}},notifyOut:function(){delete this.boxArray},notifyDrop:function(a,h,f){delete this.boxArray;if(!this.lastPos){return}var d=this,g=d.win,i=d.lastPos.p,b=a.panel,c=d.createEvent(a,h,f,i!==false?i:g.items.getCount());if(b&&g.fireEvent("validatedrop",c)!==false&&g.fireEvent("beforedrop",c)!==false){a.proxy.getProxy().remove();g.remove(b,false);if(i!==false){g.insert(i,b)}else{g.add(b)}g.doLayout();g.fireEvent("drop",c);b.addClass("syno-sds-widget-item");return true}delete d.lastPos},getBoxArray:function(){var a=this.win.bwrap.getBox();a.columnY=[];this.win.items.each(function(b){a.columnY.push({x:b.el.getY(),w:b.el.getHeight()})});return a}});Ext.define("SYNO.SDS.WidgetPanel.Resizeable",{extend:"Ext.Resizable",snapHeight:function(d,a,c){var f=this.window,b=0;if(!d){return d}var e=d;f.items.each(function(i,h){var k=b,j=8,g=10;b+=i.getHeight()+j;if((b-j)>=(e-32)){e=((k+b-j)/2)-(e-32)>0?k:b;e+=(32-j+g);return false}},this);return Math.min(a,Math.max(c,e))},onMouseMove:function(s){if(this.enabled&&this.activeHandle){try{if(this.resizeRegion&&!this.resizeRegion.contains(s.getPoint())){return}var p=this.curSize||this.startBox,g=this.startBox.x,f=this.startBox.y,i=p.width,q=p.height,a=i,k=q,j=this.minWidth,t=this.minHeight,n=this.maxWidth,z=this.maxHeight,c=this.widthIncrement,u=s.getXY(),o=-(this.startPoint[0]-Math.max(this.minX,u[0])),l=-(this.startPoint[1]-Math.max(this.minY,u[1])),d=this.activeHandle.position,A,b;switch(d){case"east":i+=o;i=Math.min(Math.max(j,i),n);break;case"south":q+=l;q=Math.min(Math.max(t,q),z);break;case"southeast":i+=o;q+=l;i=Math.min(Math.max(j,i),n);q=Math.min(Math.max(t,q),z);break;case"north":l=this.constrain(q,l,t,z);f+=l;q-=l;break;case"west":o=this.constrain(i,o,j,n);g+=o;i-=o;break;case"northeast":i+=o;i=Math.min(Math.max(j,i),n);l=this.constrain(q,l,t,z);f+=l;q-=l;break;case"northwest":o=this.constrain(i,o,j,n);l=this.constrain(q,l,t,z);f+=l;q-=l;g+=o;i-=o;break;case"southwest":o=this.constrain(i,o,j,n);q+=l;q=Math.min(Math.max(t,q),z);g+=o;i-=o;break}var m=this.snap(i,c,j);var v=this.snapHeight(q,z,t);if(m!=i||v!=q){switch(d){case"northeast":f-=v-q;break;case"north":f-=v-q;f=Math.max(f,this.minY);break;case"southwest":g-=m-i;break;case"west":g-=m-i;break;case"northwest":g-=m-i;f-=v-q;break}i=m;q=v}if(this.preserveRatio){switch(d){case"southeast":case"east":q=k*(i/a);q=Math.min(Math.max(t,q),z);i=a*(q/k);break;case"south":i=a*(q/k);i=Math.min(Math.max(j,i),n);q=k*(i/a);break;case"northeast":i=a*(q/k);i=Math.min(Math.max(j,i),n);q=k*(i/a);break;case"north":A=i;i=a*(q/k);i=Math.min(Math.max(j,i),n);q=k*(i/a);g+=(A-i)/2;break;case"southwest":q=k*(i/a);q=Math.min(Math.max(t,q),z);A=i;i=a*(q/k);g+=A-i;break;case"west":b=q;q=k*(i/a);q=Math.min(Math.max(t,q),z);f+=(b-q)/2;A=i;i=a*(q/k);g+=A-i;break;case"northwest":A=i;b=q;q=k*(i/a);q=Math.min(Math.max(t,q),z);i=a*(q/k);f+=b-q;g+=A-i;break}}this.proxy.setBounds(g,f,i,q);if(this.dynamic){this.resizeElement()}}catch(r){}}}});SYNO.SDS._Widget.Instance=Ext.extend(SYNO.SDS.AppInstance,{constructor:function(){SYNO.SDS._Widget.Instance.superclass.constructor.apply(this,arguments)},initInstance:function(c){var a=this,b=a.getUserSettings("restoreParams");if(!a.appItem){if(b&&b.windowState&&Ext.isArray(b.windowState)){b.windowState={}}a.appItem=new SYNO.SDS._WidgetPanel(Ext.apply({appInstance:a},c||{}));a.addInstance(a.appItem)}},onOpen:function(a){this.initInstance(a)},getStateParam:function(){return{windowState:this.appItem?this.appItem.getStateParam():{}}}});Ext.ns("SYNO.SDS._Widget.Utils");Ext.apply(SYNO.SDS._Widget.Utils,{getWidgetBox:function(g){var e=SYNO.SDS._Widget.Config;var h=Ext.lib.Dom.getViewHeight();var n=SYNO.SDS.Desktop.getEl();var k=n.getHeight();var i=n.getWidth();var c;if(!(g&&g.height&&g.width)){c=e.moduleTitleHeight+e.moduleHeight;var a=Math.floor((k-e.moduleTopPadding-e.moduleBottomPadding-16)/c);e.numModule=(e.maxModule<a)?e.maxModule:a}var o=(g&&g.height)?g.height:(c*e.numModule+e.moduleTopPadding+e.moduleBottomPadding);var d=(g&&g.width)?g.width:e.moduleWidth;var b=n.getStyle("overflow-y");var f=n.dom;var j=(b&&b!="hidden"&&(f.scrollWidth>=f.clientWidth))?Ext.getScrollBarWidth()-1:0;b=n.getStyle("overflow-x");var p=(b&&b!="hidden"&&(f.scrollHeight>=f.clientHeight))?Ext.getScrollBarWidth()-1:0;var l=h-o-p;var m=i-d-j;return{x:m,y:l,width:d,height:o}},getGridBasicCfg:function(){return{loadMask:true,border:false,disableSelection:true,stripeRows:true,hideHeaders:true,trackMouseOver:false,cls:"sds-widget-gridpanel"}}});Ext.ns("SYNO.SDS._Widget");Ext.define("SYNO.SDS._Widget.MiniWidget",{extend:"SYNO.SDS._SystemTray.Component",constructor:function(a){var b=this;a=Ext.applyIf(a,{cls:"sds-mini-widget",width:32,height:32});b.callParent(arguments)},setTooltip:function(b){var a=this;a.getEl().set({"ext:qtip":b})},setIcon:function(a){var b=this;b.getEl().setStyle("background-image",a?"url("+a+")":"")}});Ext.define("SYNO.SDS._Widget.GridView",{extend:"Ext.grid.GridView",pageScroll:true,autoScrollHide:false,afterRender:function(){var a=this;a.callParent(arguments);if(!a.pageScroll){return}a.scroller.setStyle({overflow:"hidden"});a.arrowScroller=a.mainWrap.createChild({cls:"arrow-scroller",cn:[{cls:"up",cn:[{cls:"arrow-up"}]},{cls:"down",cn:[{cls:"arrow-down"}]}]});a.arrowScroller.setVisibilityMode(Ext.Element.DISPLAY);a.upButton=a.arrowScroller.child("div.up");a.downButton=a.arrowScroller.child("div.down");a.upButton.on("click",a.onScrollToTop,a);a.downButton.on("click",a.onScrollToBottom,a);a.updateArrowScroller();a.grid.mon(a.grid,"afterlayout",a.updateArrowScroller,a)},onScrollToTop:function(){var b=this,a=b.scroller,d=a.dom,c=b.getArrowScrollState(),e=0;if(c.canScrollToTop){e=d.scrollTop-a.getHeight();d.scrollTop=Math.max(e,0);b.updateArrowScroller()}},onScrollToBottom:function(){var c=this,a=c.scroller,e=a.dom,f=a.getHeight(),b=e.scrollHeight,d=c.getArrowScrollState(),g=0;if(d.canScrollToBottom){g=e.scrollTop+f;e.scrollTop=Math.min(g,b-f);c.updateArrowScroller()}},onLayout:function(b,d){var a=this,c=a.scroller.dom;if(!a.autoFlexcroll){return}if(c.clientWidth===c.offsetWidth){a.scrollOffset=28}else{a.scrollOffset=undefined}this.fitColumns(false)},onLoad:function(){this.updateArrowScroller()},updateArrowScroller:function(){var a=this,b=a.getArrowScrollState();if(!a.pageScroll){return}if(a.autoScrollHide&&!b.canScrollToTop&&!b.canScrollToBottom){a.arrowScroller.hide()}else{a.arrowScroller.show()}a.upButton[b.canScrollToTop?"removeClass":"addClass"]("arrow-disabled");a.downButton[b.canScrollToBottom?"removeClass":"addClass"]("arrow-disabled")},getArrowScrollState:function(){var d=this,a=d.scroller,c=a.dom.scrollHeight,b=d.getScrollState(),e={};e.canScrollToTop=(b.top!==0);e.canScrollToBottom=b.top<(c-a.getHeight());return e},destroy:function(){var a=this;if(a.upButton){a.upButton.un("click",a.onScrollToTop,a)}if(a.downButton){a.downButton.un("click",a.onScrollToBottom,a)}a.callParent(arguments)}});SYNO.SDS._Widget.GridPanel=Ext.extend(Ext.grid.GridPanel,{gStart:0,NUM_REC_PER_PAGE:5,TotalRecords:50,poolingInterval:60*1000,widgetLayout:"fit",usewebapi:false,constructor:function(a){var c,b;this.jsConfig=a.jsConfig;c=Ext.getBody().child(".syno-sds-widget").id;this.appWin=Ext.getCmp(c);b=this.fillConfig(a);SYNO.SDS._Widget.GridPanel.superclass.constructor.call(this,b);if(!this.toggleButtonCls){this.setDefaultMiniWidget()}},setDefaultMiniWidget:function(){var a=this;a.toggleButtonCls=SYNO.SDS._Widget.MiniWidget},fillConfig:function(a){var b={store:this.getStore(),colModel:this.getColumnModel(a),autoExpandColumn:this.autoExpandColumn,frame:false,listeners:{scop:this,afterlayout:{fn:this.initPollingTask,scope:this,single:true,buffer:80}}};Ext.apply(b,SYNO.SDS._Widget.Utils.getGridBasicCfg());Ext.apply(b,a);return SYNO.LayoutConfig.fill(b)},initPollingTask:function(){this.updateRecords(true)},onWidgetShow:function(){this.getView().layout()},onBeforeStartUpdateRecords:function(a){if(this.updateTask===a){a.reqConfig.params=this.getUpdateParams()}},updateRecords:function(a){if(this.updateTask&&this.updateTask.running===true){this.updateTask.stop()}if(!this.usewebapi){if(!this.updateTask||this.updateTask.removed){this.updateTask=this.addAjaxTask({interval:this.poolingInterval,url:this.cgiHandler,params:this.getUpdateParams(),method:"POST",single:false,autoJsonDecode:true,success:this.onStoreUpdated,scope:this});var b=this.getTaskRunner();this.mon(b,"beforestart",this.onBeforeStartUpdateRecords,this)}}else{this.updateTask=this.updateTask||this.addTask({interval:this.poolingInterval,immedate:a,run:this.loadStoreTask,scope:this})}this.updateTask.start(a||false)},loadStoreTask:function(){var a=this.getStore(),b=this.getUpdateParams();if(this.isDestroyed||!a){return}a.load(b)},onStoreUpdated:function(c,b){var a=this.getStore();if(this.isDestroyed||!a){return}else{if(!c||c.errno){this.updateRecords(false);return}}this.onBeforeUpdate(c);a.loadData(c,false)},onActivate:function(){this.updateRecords(true)},onDeactivate:function(){if(this.updateTask){this.updateTask.stop()}},getView:function(){if(!this.view){this.view=new SYNO.SDS._Widget.GridView(this.viewConfig)}return this.view},getUpdateParams:Ext.emptyFn,onBeforeUpdate:Ext.emptyFn,onUpdate:Ext.emptyFn});