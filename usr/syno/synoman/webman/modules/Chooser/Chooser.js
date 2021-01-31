/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.ShareChooser",{extend:"SYNO.SDS.ModalWindow",pagingSize:20,constructor:function(a){if(a.setStoreConfig){this.setStoreConfig=a.setStoreConfig}if(a.setApiParams){this.setApiParams=a.setApiParams}if(a.setStoreField){this.setStoreField=a.setStoreField}if(a.setColModel){this.setColModel=a.setColModel}if(a.setTextFilterConfig){this.setTextFilterConfig=a.setTextFilterConfig}if(a.setGridPanelConfig){this.setGridPanelConfig=a.setGridPanelConfig}if(a.pagingSize){this.pagingSize=a.pagingSize}this.store=this.createStore(a);this.grid=this.createGridPanel(a);var b=this.fillModalWindowConfig(a);SYNO.LayoutConfig.fill(b);this.callParent([b]);this.on("show",function(){this.nameFilter.setValue();this.store.load()})},fillModalWindowConfig:function(a){var b={title:_T("user","select_users"),autoDestroy:true,width:560,height:450,minWidth:300,minHeight:250,layout:"fit",items:[this.grid],buttons:[{xtype:"syno_button",btnStyle:"blue",itemId:"ok",text:_T("common","ok"),scope:this,handler:this.collectSelected},{xtype:"syno_button",itemId:"cancel",text:_T("common","cancel"),scope:this,handler:this.cancelDialog}]};Ext.apply(b,a);return b},createStore:function(a){var c=Ext.apply({shareType:a.shareType||["def"],offset:0,limit:this.pagingSize},this.setApiParams());var b={baseParams:c,appWindow:a.appWindow||this,fields:this.setStoreField(),remoteSort:true,defaultSortable:true,autoDestroy:true,listeners:{exception:{scope:this,fn:this.onStoreException},beforeload:{scope:this,fn:this.onBeforeLoad},load:{scope:this,fn:this.onLoad}}};Ext.apply(b,this.setStoreConfig());return new SYNO.API.JsonStore(b)},createTBar:function(){var a={itemId:"searchTBar",emptyText:_T("share","search_share"),store:this.store,pageSize:this.pagingSize};Ext.apply(a,this.setTextFilterConfig());var b=new Ext.Toolbar({items:["->",this.nameFilter=new SYNO.ux.TextFilter(a)]});return b},createGridPanel:function(b){var c=new Ext.grid.RowSelectionModel({singleSelect:(b.singleSelect)?b.singleSelect:false,listeners:{selectionchange:{scope:this,fn:this.onSelectionChange}}});var a={itemId:"grid",border:false,autoDestroy:true,store:this.store,colModel:new Ext.grid.ColumnModel(this.setColModel()),tbar:this.createTBar(),selModel:c,bbar:new SYNO.ux.PagingToolbar({store:this.store,pageSize:this.pagingSize,displayInfo:true})};Ext.apply(a,this.setGridPanelConfig());return new SYNO.ux.GridPanel(a)},collectSelected:function(){this.records=this.grid.getSelectionModel().getSelections();this.hide()},cancelDialog:function(){this.grid.getSelectionModel().clearSelections();this.records=[];this.hide()},setBtnOkDisable:function(b){var c=this.getFooterToolbar();var a=c.getComponent("ok");a.setDisabled(b)},getRecords:function(){return this.records},onSelectionChange:function(a){var b=a.getCount();this.setBtnOkDisable((b===0))},onStoreException:function(d,e,f,c,b,a){this.clearStatusBusy();var g="";if(!b||!b.error){g="Error"}else{g="Error code("+b.error.code+")"}this.getMsgBox().alert(this.title,g,function(){},this)},onBeforeLoad:function(a,b){this.setStatusBusy();this.grid.getSelectionModel().clearSelections();this.setBtnOkDisable(true);this.records=[]},onLoad:function(c,a,b){this.clearStatusBusy()},setApiParams:function(){return{}},setStoreConfig:function(){return{api:"SYNO.Core.Share",method:"list",version:"1",id:"name",root:"shares",totalProperty:"total"}},setStoreField:function(){return["name","desc"]},setTextFilterConfig:function(){return{queryAction:"list",queryParam:"substr"}},setColModel:function(){return[{id:"name",header:_T("share","share_name"),dataIndex:"name",width:150},{id:"description",header:_T("share","share_comment"),dataIndex:"desc"}]},setGridPanelConfig:function(){return{autoExpandColumn:"description"}}});Ext.define("SYNO.SDS.UserChooser",{extend:"SYNO.SDS.ModalWindow",LOCAL_ROLES:[["local",_T("share","share_local_user")]],DOMAIN_ROLES:[["domain",_T("share","share_domain_user")]],LDAP_ROLES:[["ldap",_T("share","ldap_user")]],initEvents:function(){this.callParent(arguments);this.getRoleInformation()},constructor:function(a){this.owner=a.owner;if("yes"===this._D("usbstation","no")){a.localOnly=true}this.domainForceIgnore=false;this.ldapForceIgnore=false;this.pagingSize=SYNO.SDS.AdminCenter.USER_PAGING_SIZE;this.isFirstLoad=true;this.localOnly=(undefined===a.localOnly)?true:a.localOnly;this.resetDirectoryInfo();this.roleFilterDefVal="local";if(a.title){this.title=a.title}if(a.setStoreConfig){this.setStoreConfig=a.setStoreConfig}if(a.setApiParams){this.setApiParams=a.setApiParams}if(a.setStoreField){this.setStoreField=a.setStoreField}if(a.setColModel){this.setColModel=a.setColModel}if(a.setTextFilterConfig){this.setTextFilterConfig=a.setTextFilterConfig}if(a.setGridPanelConfig){this.setGridPanelConfig=a.setGridPanelConfig}if(a.pagingSize){this.pagingSize=a.pagingSize}if(a.domainForceIgnore){this.domainForceIgnore=a.domainForceIgnore}if(a.ldapForceIgnore){this.ldapForceIgnore=a.ldapForceIgnore}if(a.roleFilterDefVal){this.roleFilterDefVal=a.roleFilterDefVal}if(a.LOCAL_ROLES){this.LOCAL_ROLES=a.LOCAL_ROLES}if(a.DOMAIN_ROLES){this.DOMAIN_ROLES=a.DOMAIN_ROLES}if(a.LDAP_ROLES){this.LDAP_ROLES=a.LDAP_ROLES}this.userStore=this.createStore(a);this.grid=this.createGridPanel(a);var b=this.fillModalWindowConfig(a);this.callParent([b])},fillModalWindowConfig:function(a){var b={title:this.title||_T("user","select_users"),autoDestroy:true,width:670,height:300,minWidth:300,minHeight:250,layout:"fit",items:[this.grid],buttons:[{xtype:"syno_button",btnStyle:"blue",itemId:"ok",text:_T("common","ok"),btnStle:"blue",scope:this,handler:this.collectSelected},{xtype:"syno_button",btnStyle:"grey",itemId:"cancel",text:_T("common","cancel"),scope:this,handler:this.cancelDialog}]};Ext.apply(b,a);return b},createStore:function(a){var c=Ext.apply({offset:0,limit:this.pagingSize},this.setApiParams());var b={baseParams:c,appWindow:this.owner,fields:this.setStoreField(),remoteSort:true,defaultSortable:true,autoDestroy:true,listeners:{exception:{scope:this,fn:this.onStoreException},beforeload:{scope:this,fn:this.onBeforeLoad},load:{scope:this,fn:this.onLoad}}};Ext.apply(b,this.setStoreConfig());return new SYNO.API.JsonStore(b)},createTBar:function(){var a={itemId:"searchTBar",emptyText:_T("user","search_user"),store:this.userStore,pageSize:this.pagingSize};Ext.apply(a,this.setTextFilterConfig());var b=new Ext.Toolbar({items:[{xtype:"syno_combobox",itemId:"roleFilter",valueField:"role",displayField:"display",store:{xtype:"arraystore",autoDestroy:true,fields:["role","display"]},resizable:true,mode:"local",triggerAction:"all",editable:false,forceSelection:true,value:_T("share","share_local_user"),width:200,listeners:{beforeselect:{scope:this,fn:this.onRoleFilterSelect}}},"->",{xtype:"syno_displayfield",value:_T("helptoc","directory_service_domain")+": ",hidden:true,itemId:"domainListLabel"},{xtype:"syno_combobox",itemId:"domainFilter",valueField:"domain",displayField:"domain",store:{xtype:"arraystore",autoDestroy:true,fields:["domain"]},hidden:true,resizable:true,mode:"local",triggerAction:"all",editable:false,value:"",forceSelection:true,tpl:'<tpl for="."><div ext:qtip="{domain}" class="x-combo-list-item">{domain}</div></tpl>',listeners:{beforeselect:{scope:this,fn:this.onDomainFilterSelect}}}," ",this.nameFilter=new SYNO.ux.TextFilter(a)]});this.roleFilter=b.getComponent("roleFilter");this.domainFilter=b.getComponent("domainFilter");this.domainListLabel=b.getComponent("domainListLabel");return b},createGridPanel:function(b){var c=new Ext.grid.RowSelectionModel({singleSelect:(b.singleSelect)?b.singleSelect:false,listeners:{selectionchange:{scope:this,fn:this.onSelectionChange}}});var a={itemId:"grid",border:false,autoDestroy:true,store:this.userStore,colModel:new Ext.grid.ColumnModel(this.setColModel()),tbar:this.createTBar(),selModel:c,bbar:new SYNO.ux.PagingToolbar({store:this.userStore,pageSize:this.pagingSize,displayInfo:true})};Ext.apply(a,this.setGridPanelConfig());return new SYNO.ux.GridPanel(a)},listUser:function(b){var a=this.userStore.baseParams;a.type=b.type;if(b.domain_name){a.domain_name=b.domain_name}else{a.domain_name=""}this.userStore.load({params:b})},domainListSetVisible:function(a){if(0===this.domainList.size()||1===this.domainList.size()||true===this.domainForceIgnore){a=false}this.domainListLabel.setVisible(a);this.domainFilter.setVisible(a)},onDomainFilterSelect:function(c,a,b){if(!a.data||!a.data.domain){SYNO.Debug("onDomainFilterSelect error");return false}this.domainFilter.setValue(a.data.domain);this.nameFilter.reset();this.listUser({type:"domain",domain_name:a.data.domain});return true},onRoleFilterSelect:function(d,a,b){var e="";var c="";if(!a.data||!a.data.role){SYNO.Debug("onRoleFilterSelect error");return false}e=a.data.role;if("domain"===e){this.domainListSetVisible(true);c=this.domainFilter.getValue()}else{this.domainListSetVisible(false)}this.nameFilter.reset();this.listUser({type:e,domain_name:c});return true},collectSelected:function(){this.records=this.grid.getSelectionModel().getSelections();this.close()},cancelDialog:function(){this.grid.getSelectionModel().clearSelections();this.records=[];this.close()},chooseUsers:function(a){this.setBtnOkDisable(true);this.records=[];this.open()},setBtnOkDisable:function(b){var c=this.getFooterToolbar();var a=c.getComponent("ok");a.setDisabled(b)},getRecords:function(){return this.records},onSelectionChange:function(a){var b=a.getCount();this.setBtnOkDisable((b===0))},onStoreException:function(d,e,f,c,b,a){this.clearStatusBusy();this.grid.getTopToolbar().getComponent("searchTBar").reset();var g="";if(!b||!b.error){g="Error"}else{g="Error code("+b.error.code+")"}this.getMsgBox().alert(this.title,g,function(){if(this.isFirstLoad){this.close()}},this)},resetDirectoryInfo:function(){this.domainEnable=false;this.domainList=[];this.ldapEnable=false},getRoleInformation:function(){this.setStatusBusy({text:_T("common","msg_waiting")});if(false===this.localOnly){this.DirectoryServiceDataGet(true);return}this.resetDirectoryInfo();this.loadToolBarData();this.clearStatusBusy()},onBeforeLoad:function(a,b){this.setStatusBusy()},onLoad:function(c,a,b){this.clearStatusBusy();this.grid.getSelectionModel().clearSelections();this.isFirstLoad=false},domainFilterSetup:function(){var b=this.domainFilter.getStore();var c=[];if(this.localOnly){return}if(this.domainEnable&&this.domainList.size()&&false===this.domainForceIgnore){for(var a=0;a<this.domainList.size();a++){c.push([this.domainList[a]])}b.loadData(c);if(!this.domainFilter.getValue()){this.domainFilter.setValue(this.domainList[0])}}},roleFileterSetup:function(){var a=this.roleFilter.getStore();a.loadData(this.LOCAL_ROLES,true);if(this.localOnly){this.roleFilter.setVisible(false);return}if(this.domainEnable&&this.domainList.size()&&false===this.domainForceIgnore){a.loadData(this.DOMAIN_ROLES,true)}if(this.ldapEnable&&false===this.ldapForceIgnore){a.loadData(this.LDAP_ROLES,true)}this.roleFilter.setValue(this.roleFilterDefVal)},loadToolBarData:function(){this.nameFilter.reset();this.roleFileterSetup();this.domainFilterSetup();this.listUser({type:this.roleFilterDefVal,domain_name:""})},DirectoryServiceDataGet:function(a){var b=[{api:"SYNO.Core.Directory.Domain",method:"get",version:1,params:{additional:false}},{api:"SYNO.Core.Directory.Domain",method:"test_dc",version:1},{api:"SYNO.Core.Directory.LDAP",method:"get",version:1}];if(a){b=b.concat([{api:"SYNO.Core.Directory.Domain",method:"get_domain_list",version:1}])}this.sendWebAPI({params:{},compound:{stopwhenerror:true,params:b},timeout:360000,scope:this,callback:this.DirectoryServiceDataGetCB})},DirectoryServiceDataProcess:function(f,e,d){var c,b=_T("common","commfail");if(true===e.isTimeout){b=_T("directory_service","warr_db_not_ready");return{error:b}}else{if(true===e.has_fail){c=SYNO.API.Util.GetFirstError(e);if(SYNO.API.Erros.core[c.code]){b=SYNO.API.Erros.core[c.code]}return{error:b}}}var a={};if(SYNO.API.Util.GetValByAPI(e,"SYNO.Core.Directory.Domain","test_dc","test_join_success")){a.enable_domain=SYNO.API.Util.GetValByAPI(e,"SYNO.Core.Directory.Domain","get","enable_domain")}else{a.enable_domain=false}a.domain_list=SYNO.API.Util.GetValByAPI(e,"SYNO.Core.Directory.Domain","get_domain_list","domain_list");a.enable_ldap=SYNO.API.Util.GetValByAPI(e,"SYNO.Core.Directory.LDAP","get","enable_client");return a},DirectoryServiceDataGetCB:function(d,b,a){var c=this.DirectoryServiceDataProcess(d,b,a);this.clearStatusBusy();if(c.error){this.getMsgBox().alert(this.title,c.error,function(){if(this.isFirstLoad){this.close()}},this);return false}this.domainList=c.domain_list;this.domainEnable=c.enable_domain;this.ldapEnable=c.enable_ldap;this.loadToolBarData()},setApiParams:function(){return{additional:["description"]}},setStoreConfig:function(){return{api:"SYNO.Core.User",method:"list",version:"1",id:"uid",root:"users",totalProperty:"total"}},setStoreField:function(){return["uid","name","description"]},setTextFilterConfig:function(){return{queryAction:"list",queryParam:"substr"}},setColModel:function(){return[{id:"name",header:_T("user","user_account"),dataIndex:"name",width:200},{id:"description",header:_T("user","user_fullname"),dataIndex:"description",width:150,renderer:Ext.util.Format.htmlEncode}]},setGridPanelConfig:function(){return{autoExpandColumn:"description"}}});