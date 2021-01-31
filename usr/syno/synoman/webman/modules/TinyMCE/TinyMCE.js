/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.ux.TinyMCE",{extend:"Ext.BoxComponent",constructor:function(a){this.callParent([this.fillConfig(a)]);this.addEvents("initialize","beforeAddAttach")},fillConfig:function(a){var b=Ext.apply({id:Ext.id(),editor:null,autoEditorResize:false},a);b.mceConfig=Ext.apply({language:"syno",selector:"",menubar:true,statusbar:true,toolbar:true,skin:"synostyle",plugins:[]},a.mceConfig||{});return b},adjustEditorSize:function(c,g,d,b,f){var a,e=0;if(Ext.isEmpty(this.getEditor())){return}a=Ext.get(this.getEditor().getContainer());a.setSize(g,d);a.select(".mce-toolbar-grp").each(function(h){if(!h.isVisible()){return}e+=h.getHeight()+h.getMargins("tb")});Ext.get(this.getEditor().id+"_ifr").setHeight(d-e);this.getEditor().nodeChanged()},onRender:function(){this.on("afterrender",function(){var a=this;this.mceConfig.selector="#"+this.id;this.mceConfig.height=this.height;this.mceConfig.width=this.width;this.mceConfig.init_instance_callback=function(b){b.owner=a.owner;b.ownerCt=a;a.editor=b;a.fireEvent("initialize",a,b)};if(!Ext.isEmpty(this.mceConfig.syno_base_url)){tinymce.baseURL=this.mceConfig.syno_base_url}tinymce.init(this.mceConfig)},this,{single:true});if(true===this.autoEditorResize){this.on("resize",this.adjustEditorSize,this)}this.callParent(arguments)},getEditor:function(){return this.editor},getDoc:function(){return this.editor.getDoc()},setEditorHeight:function(a){this.setEditorSize(undefined,a)},setEditorWidth:function(a){this.setEditorSize(a,undefined)},setEditorSize:function(c,a){var b=Ext.get(this.id+"_ifr");if(c){b.setWidth(c)}if(a){b.setHeight(a)}},onDestroy:function(a){if(this.editor){try{Ext.EventManager.removeFromSpecialCache(this.editor.getDoc())}catch(b){}this.editor.destroy()}this.callParent([a])}});Ext.reg("syno_tinymce",SYNO.ux.TinyMCE);