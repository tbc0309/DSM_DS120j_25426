/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.ns("SYNO.SDS.App.FlashUploader.Componet");var SwiffUploader={CallBacks:{}};SYNO.SDS.App.FlashUploader.Componet=Ext.extend(Ext.FlashComponent,{constructor:function(d){Ext.apply(this.options,d||{});this.addEvents("onLoad");var a=this.options.callBacks||this;if(a.onLoad){this.mon(this,"onLoad",a.onLoad,this)}if(!a.onBrowse){a.onBrowse=function(){return this.options.typeFilter}}var c={},b=this;Ext.each(["onBrowse","onSelect","onAllSelect","onCancel","onBeforeOpen","onOpen","onProgress","onComplete","onError","onAllComplete","onLog"],function(g){var h=a[g]||Ext.emptyFn;c[g]=function(){return h.apply(b,arguments)}},this);c.onLoad=(function(){this.load.createDelegate(this).defer(10)}).createDelegate(this);var f=this.generateCallBacks({callBacks:c});f.allowedDomain="*";var e=this.options.path;e+=("?v="+_S("fullversion")+"&_dc="+(new Date().getTime()));SYNO.SDS.App.FlashUploader.Componet.superclass.constructor.call(this,Ext.apply(d,{id:"swfuploadobject",url:e,wmode:"transparent",backgroundColor:"",flashParams:{swLiveConnect:"true"},flashVars:f,renderTo:document.body}));this.box=this.el.wrap({style:{position:"absolute",visibility:"visible",zIndex:99999},title:_T("upload","upload_open_file"),alt:_T("upload","upload_open_file")});this.box.setBox({x:0,y:0,width:15,height:15});return this},generateCallBacks:function(c){this.instance="Swiff_"+(+(new Date()));SwiffUploader.CallBacks[this.instance]={};var e={},a=c.callBacks,b=this;for(var d in a){if(a.hasOwnProperty(d)){SwiffUploader.CallBacks[this.instance][d]=(function(f){return function(){return f.apply(b.el,arguments)}})(a[d]);e[d]="SwiffUploader.CallBacks."+this.instance+"."+d}}return e},setLowZindex:function(){if(this.box){this.box.setStyle.createDelegate(this.box,["zIndex",-1]).defer(500)}},setHighZindex:function(){if(this.box){this.box.setStyle("zIndex",99999)}},load:function(){this.remote("register",this.instance,this.options.multiple,this.options.queued);this.target=this.options.target;this.fireEvent("onLoad");this.swiffyReposition();this.setHighZindex()},reposition:function(a){var b=this.target.getBox();if(a){b.height=a}this.box.setBox(b)},setTarget:function(a){this.target=a},browse:function(a){this.options.typeFilter=a||this.options.typeFilter;if(!this.options.typeFilter){this.options.typeFilter=null}return this.remote("browse")},upload:function(a){var c=this.options;var b={data:c.data,url:c.url,method:c.method,fieldName:c.fieldName};a=Ext.apply(b,a);if(Ext.type(a.data)=="element"){a.data=Ext.urlEncode(a.data)}return this.remote("upload",a)},removeFile:function(a){if(a){a={name:a.name,size:a.size}}return this.remote("removeFile",a)},getFileList:function(){return this.remote("getFileList")},restartOneTask:function(a){return this.remote("restartOneTask",{name:a.name})},setParameters:function(a){if(a){this.remote("setParameters",a)}}});Ext.ns("SYNO.SDS.App.FlashUploader.Uploader");SYNO.SDS.App.FlashUploader.Uploader=Ext.extend(SYNO.SDS.App.FlashUploader.Componet,{options:{limitSize:2147482624,limitFiles:100,instantStart:true,multiple:true,queued:true,typeFilter:null,url:null,method:"post",fieldName:"Filedata",target:null,height:"100%",width:"100%",callBacks:null},flashParams:null,blSwiffyReady:false,gExceedCount:0,gFormtWrongCount:0,gServerErrorCount:0,arrExceedFile:[],arrFormtWrongFile:[],arrBigFile:[],arrZeroFile:[],objServerErrorFiles:{},files:[],constructor:function(a){var b=SYNO.SDS.Utils.getPunyBaseURL();a.url=b+a.url;a.path=b+"modules/Uploader/Swiff.Uploader.swf";this.addEvents("onOpen","onSelect","onErrorStr","onAllSelect","onProgress","onComplete","onAllComplete","onError","onCancel");this.files=[];SYNO.SDS.App.FlashUploader.Uploader.superclass.constructor.call(this,a);this.onSetTarget(a.eventtarget,a.target)},onSetTarget:function(b,a){this.mon(b,"show",this.onShow,this);this.mon(b,"move",this.swiffyReposition,this);this.mon(b,"resize",this.swiffyReposition,this);this.mon(b,"hide",this.setLowZindex,this);this.mon(a,"disable",this.setLowZindex,this);this.mon(a,"enable",this.setHighZindex,this);this.mon(b,"destroy",function(){this.onDestroy(b,a)},this);this.setTarget(a)},onDestroy:function(b,a){this.mun(b,"show",this.onShow,this);this.mun(b,"move",this.swiffyReposition,this);this.mun(b,"resize",this.swiffyReposition,this);this.mun(b,"hide",this.setLowZindex,this);this.mun(b,"destroy",this.onDestroy,this);this.mun(a,"disable",this.setLowZindex,this);this.mun(a,"enable",this.setHighZindex,this)},onShow:function(){this.swiffyReposition();this.setHighZindex()},isSwiffyReady:function(){return this.blSwiffyReady},swiffyReposition:function(){if(this.isSwiffyReady()){this.reposition()}},onLoad:function(){this.blSwiffyReady=true},onBeforeOpen:function(b,a){return a},onOpen:function(a,b){this.fireEvent("onOpen",this,a,b)},onProgress:function(a,c,b){},onBrowse:function(){var b,a;for(b=0,a=this.files.length;b<a;b++){this.removeFile(this.files[0])}this.gExceedCount=0;this.gFormtWrongCount=0;this.gServerErrorCount=0;return this.options.typeFilter},getFile:function(b){var a=null;this.files.some(function(c){if((c.name!=b.name)||(c.size!=b.size)){return false}a=c;return true});return a},checkAllowFiletype:function(a){if(0===this.allowfilters.length){return true}for(var b=0;b<this.allowfilters.length;b++){if(SYNO.SDS.Utils.isValidExtension(a,"."+this.allowfilters[b])){return true}}return false},onSelect:function(b,a,c){this.fireEvent("onSelect",this,b,a,c);this.files.push(b);if(0===b.size){this.arrZeroFile.push(b)}else{if(this.options.limitSize&&(b.size>this.options.limitSize)){this.arrBigFile.push(b)}else{if(this.options.limitFiles&&(this.countFiles()>this.options.limitFiles)){this.gExceedCount++;this.arrExceedFile.push(b)}else{if(!this.checkAllowFiletype(b.name)){this.gFormtWrongCount++;this.arrFormtWrongFile.push(b)}else{return true}}}}return false},onAllSelect:function(d,e,c){var f="";var b,a;if(this.gExceedCount){f+=(1==this.gExceedCount)?_T("download","download_unselect_file"):String.format(_T("download","download_unselect_files"),this.gExceedCount);f+="<br>";for(b=0,a=this.arrExceedFile.length;b<a;b++){if(this.arrExceedFile.length>0){this.removeFile(this.arrExceedFile[b])}}this.gExceedCount=0;this.arrExceedFile=[]}if(this.arrBigFile&&0<this.arrBigFile.length){f+=String.format(_T("download","download_upload_exceed_maximum_filesize"),this.calculatesize(this.options.limitSize)+_T("common","size_mb"));f+=" <br>";for(b=0;(b<this.arrBigFile.length&&b<5);b++){f+=this.arrBigFile[b].name+"<br>"}if(5<this.arrBigFile.length){f+="...<br>"}f+="<br>";for(b=0,a=this.arrBigFile.length;b<a;b++){if(this.arrBigFile.length>0){this.removeFile(this.arrBigFile[b])}}this.arrBigFile=[]}if(this.arrZeroFile&&0<this.arrZeroFile.length){f+=String.format(_T("download","download_upload_zerobyte_filesize"),this.calculatesize(this.options.limitSize)+_T("common","size_mb"));f+=" <br>";for(b=0;(b<this.arrZeroFile.length&&b<5);b++){f+=this.arrZeroFile[b].name+"<br>"}if(5<this.arrZeroFile.length){f+="...<br>"}f+="<br>";for(b=0,a=this.arrZeroFile.length;b<a;b++){if(this.arrZeroFile.length>0){this.removeFile(this.arrZeroFile[b])}}this.arrZeroFile=[]}if(this.gFormtWrongCount){f+=String.format(_T("download","download_error_wrong_files_format"),this.gFormtWrongCount);for(b=0;b<this.gFormtWrongCount;b++){if(this.arrFormtWrongFile.length>0){this.removeFile(this.arrFormtWrongFile[b])}}this.gFormtWrongCount=0;this.arrFormtWrongFile=[]}if(f){this.fireEvent("onErrorStr",this,f)}this.fireEvent("onAllSelect",this);return true},onComplete:function(d,a){a=decodeURIComponent(a);var c=Ext.util.JSON.decode(a);var b;if(!c.success){this.gServerErrorCount++;b=c.errno;if(this.objServerErrorFiles[b.key]){this.objServerErrorFiles[b.key].files.push(d)}else{this.objServerErrorFiles[b.key]={section:b.section,files:[d]}}}this.fireEvent("onComplete",this,c)},onError:function(b,a,c){this.fireEvent("onError",this,b,a,c)},onCancel:function(){this.fireEvent("onCancel",this)},onAllComplete:function(d){var b,f,c,a;if(this.gServerErrorCount>0){var e="";e+=String.format(_T("download","download_upload_erro_files"),this.gServerErrorCount);e+=" <br>";for(b in this.objServerErrorFiles){if(this.objServerErrorFiles.hasOwnProperty(b)){f=this.objServerErrorFiles[b].files;c=f.length;e+=_T(this.objServerErrorFiles[b].section,b)+"<br>";for(a=0;a<c;a++){e+=f[a].name+"<br>"}e+="<br>"}}this.objServerErrorFiles={};if(e){this.fireEvent("onErrorStr",this,e)}}this.fireEvent("onAllComplete",this);this.gExceedCount=0;this.gFormtWrongCount=0;this.gServerErrorCount=0},countFiles:function(){return(this.files.length-this.arrZeroFile.length-this.arrBigFile.length-this.arrExceedFile.length-this.arrFormtWrongFile.length)},removeFile:function(b){if(!b){this.files.empty()}else{if(!b.element){b=this.getFile(b)}for(var a=this.files.length;a--;a){if(this.files[a]===b){this.files.splice(a,1)}}}SYNO.SDS.App.FlashUploader.Uploader.superclass.removeFile.call(this,b)},calculatesize:function(a){a=(a/(1024*1024));return a},setParameters:function(a){SYNO.SDS.App.FlashUploader.Uploader.superclass.setParameters.call(this,a)},onSubmit:function(a){var d=a.getForm().findField("MultiText").getValue();if(d===""){this.fireEvent("onErrorStr",this,_T("download","download_empty_input_file"));return}var c=Ext.util.Cookies.get("id");if(Ext.isEmpty(c)){this.fireEvent("onErrorStr",this,_T("error","error_unknown"));return}else{var b=this.options.url;this.options.url=Ext.urlAppend(b+"?session="+c);if(false!==this.fireEvent("onBeforeSubmit",this)){this.upload()}this.options.url=b}},getServerErrorCount:function(){return this.gServerErrorCount}});Ext.ns("SYNO.SDS.App.Uploader.HTML5Uploader");SYNO.SDS.App.Uploader.HTMLUploaderTaskMgr=Ext.extend(Object,{taskList:new Hash(),taskUploadingIndex:0,constructor:function(a){this.uploader=a.uploader;SYNO.SDS.App.Uploader.HTMLUploaderTaskMgr.superclass.constructor.apply(this,arguments)},initTaskData:function(){this.taskList=new Hash();this.taskUploadingIndex=0},getTaskSize:function(){return this.taskList?this.taskList.keys().length:0},getUploadingTaskIndex:function(){return this.taskUploadingIndex},addUploadTask:function(a){this.taskList.set(this.getTaskSize(),a)},removeOneTask:function(b){var a=this.taskList.get(b);if(a){if(a.status==="PROCESSING"){if(this.uploader&&this.uploader.conn){this.uploader.conn.abort(a.reqId)}this.blUploading=false;if(this.uploader.clearFolderFiles){this.uploader.clearFolderFiles(a)}this.taskUploadingIndex++;this.uploader.uploadNext()}a.file=null;a.status="CANCEL"}},restartOneTask:function(b){var a=this.taskList.get(b);if(a){this.uploader.addFiles([a.file],true,false,a.params,[a.dtItem],a.isDirectory);this.removeOneTask(b)}}});SYNO.SDS.App.Uploader.HTML5Uploader=Ext.extend(Ext.Component,{MAX_POST_FILESIZE:(Ext.isWebKit)?-1:((window.console&&window.console.firebug)?20971521:4294963200),FileObj:function(a,d,e,b){var c=SYNO.Util.copy(d||{});if(a.lastModifiedDate){c=Ext.apply(c,{mtime:a.lastModifiedDate.getTime()})}return{id:e,file:a,dtItem:b,name:a.name||a.fileName,size:a.size||a.fileSize,progress:0,status:"NOT_STARTED",params:c,chunkmode:false}},constructor:function(b,a){this.initDefData();this.HTMLUploaderTask=new SYNO.SDS.App.Uploader.HTMLUploaderTaskMgr({uploader:this});Ext.apply(this.opts,b);SYNO.SDS.App.Uploader.HTML5Uploader.superclass.constructor.apply(this,arguments);this.init(a)},initDefData:function(){this.blAppenddata=false;this.nbExceed=0;this.nbWrongType=0;this.arrFolder=[];this.arrExceedFile=[];this.arrWrongType=[];this.arrBigFile=[];this.objErrFiles={};this.nbErrFiles=0;this.opts={bldropBody:false,instantStart:false,chunkmode:false,chunksize:10485760,filefiledname:"file",params:{}}},init:function(a){a.container.on("destroy",this.onDestroy,this);a.container.mon(this,a.opts.listeners);this.initButtonEl(a.container,a.opts);this.initDragDropEl(a.container,a.opts);if(a.files){a.container.mon(a.container.ownerCt,"show",function(){this.dropFiles(a.files);a.files=null},this,{single:true})}},onDestroy:function(a){a.un("destroy",this.onDestroy,this)},onMask:function(a){if(this.opts.dropcss){a.addClass(this.opts.dropcss)}a.addClass("file-drag-over");a.mask(this.opts.droptext||_T("filetable","drop_file"))},onUnmask:function(a){if(this.opts.dropcss){a.removeClass(this.opts.dropcss)}a.unmask();a.removeClass("file-drag-over")},initButtonEl:function(b,a){var d=this;if(Ext.isFunction(b.getForm)){var e=b.getForm().findField(this.opts.filefiledname);if(e){var c=e.el;if(c&&c.is("input[type=file]")){this.textEl=b.getForm().findField("MultiText");this.mon(c,"change",function(){d.blFolderEabled=false;d.addFiles.call(d,this.dom.files,true,false,undefined,undefined,false);var g=this.dom,f=g.disabled;g.disabled=true;g.value="";g.disabled=f})}}}},initDragDropEl:function(b,a){var c=(b.getXType()==="grid")?b.getView().scroller:(b.getViewEl?b.getViewEl():b.el);var d=this.opts.bldropBody?(b.body||c):c;if(!d){return}b.mon(d,"dragover",function(f){if(SYNO.SDS.App.Uploader.Utils.isDragFile(f.browserEvent)){if(!this.isDragMask){return}f.preventDefault();f.stopPropagation();f.browserEvent.dataTransfer.dropEffect="copy";this.dragstarttime=new Date().getTime()}},this);b.mon(Ext.getDoc(),"dragover",function(f){if(SYNO.SDS.App.Uploader.Utils.isDragFile(f.browserEvent)){this.dragstarttime=new Date().getTime();if(!this.isDragMask){if(!b.isVisible()||b.owner&&b.owner.maskCnt>=1||b.el.isMasked()||this.isDragMask||(b.owner&&b.owner.el.isMasked())||(b.owner&&b.owner.owner&&b.owner.owner.el.isMasked())||Ext.getBody().hasClass("x-body-masked")){return}if(false===this.fireEvent("onBeforeDragEnter",this,b,f)){return false}this.isDragMask=true;if(!this.dragPollTask){this.dragPollTask=this.addTask({interval:300,run:function(){if(800<new Date().getTime()-this.dragstarttime){this.onDragEnd(b,d)}},scope:this})}this.dragPollTask.start();if(false===this.fireEvent("onDragEnter",this,b)){return false}this.onMask(d);return}else{this.fireEvent("onDragOver",this,b)}}},this);b.mon(Ext.getDoc(),"dragend",this.onDragEnd.createDelegate(this,[b,d],true));b.mon(Ext.getDoc(),"drop",this.onDragEnd.createDelegate(this,[b,d],true));b.mon(d,"drop",function(g){if(SYNO.SDS.App.Uploader.Utils.isDragFile(g.browserEvent)){this.dragstarttime=undefined;this.isDragMask=false;if(false===this.fireEvent("onDrop",this,b)){return}this.onUnmask(d);g.stopPropagation();g.preventDefault();g.stopEvent();if(_S("demo_mode")){this.fireEvent("onError",this,_JSLIBSTR("uicommon","error_demo"));return}var f=g.browserEvent.dataTransfer;if(f&&f.files&&f.files.length>0){if(f.items&&f.items[0]&&f.items[0].webkitGetAsEntry){this.blFolderEabled=!!this.blFolderEabled&&true}else{this.blFolderEabled=false}this.addFiles.call(this,f.files,false,false,null,f.items)}else{this.fireEvent("onError",this,_T("error","upload_folder_error"))}}},this)},onDragEnd:function(){if(this.dragPollTask&&this.dragPollTask.running){this.dragPollTask.stop();var b=arguments[arguments.length-1];var a=arguments[arguments.length-2];if(this.isDragMask&&b.isMasked()){this.onUnmask(b)}this.isDragMask=false;if(false===this.fireEvent("onDragEnd",this,a)){return false}}},initTaskData:function(){this.HTMLUploaderTask.initTaskData()},checkDirectory:function(h,b){var c=h.file,f=null;if(b&&b.getAsEntry){f=b.getAsEntry();if(f){return f.isDirectory}}else{if(b&&b.webkitGetAsEntry){f=b.webkitGetAsEntry();if(f){return f.isDirectory}}else{if(Ext.isGecko){try{var d;if(!!(File&&File.prototype.slice)){d=c.slice(0,1)}else{if(!!(File&&File.prototype.webkitSlice)){d=c.webkitSlice(0,1)}else{if(!!(File&&File.prototype.mozSlice)){d=c.mozSlice(0,1)}else{return false}}}if(d&&window.FileReader){var a=new FileReader();a.readAsBinaryString(d)}}catch(g){return true}return false}else{if(Ext.isSafari){return false}}}}return(c.size===0)},addFiles:function(w,a,e,t,g,r,k){var u,q,p,o,h=[],v=[],n=g?g:null;if(!w||0===w.length){this.fireEvent("onError",this,_T("upload","empty_input_file"));return}if(k){this.blForceHtmlUpload=true}else{this.blForceHtmlUpload=false}if(!this.blAppenddata){this.initTaskData()}this.nbExceed=0;this.nbWrongType=0;this.objErrFiles={};this.nbErrFiles=0;this.arrExceedFile=[];this.arrWrongType=[];this.arrBigFile=[];var f=0;var l;var b=this.getTaskSize();var d=[];for(q=0;q<w.length;q++){u=w[q];o=u.name||u.fileName;if(v[o]&&false!==this.fireEvent("onNameDuplicate")){continue}var m;v[o]=true;if(u instanceof File){var s=(n&&n[q])?n[q]:null;if(s){s=(s.webkitGetAsEntry)?s.webkitGetAsEntry():s}m=new this.FileObj(u,t,null,s);if(Ext.isBoolean(r)){if(Ext.isModernIE){m.isDirectory=(m.file.size===0)}else{m.isDirectory=r}}else{m.isDirectory=false;if(n){for(p=q;p<n.length;p++){if(n[p]&&n[p].getAsFile&&n[p].getAsFile()===u){m.isDirectory=this.checkDirectory(m,n[p]);break}}}else{m.isDirectory=this.checkDirectory(m)}}d.push(m)}else{m=u;if(t){Ext.apply(m.params,t)}}if(false!==this.onSelect(m)){if(a){l=this.getTaskSize();m.id=l;if(false!==this.fireEvent("onSelect",this,m)){this.HTMLUploaderTask.addUploadTask(m)}}else{h.push(m.name)}f++}}if(false!==e&&this.textEl){this.setInputFieldValue("")}l=this.getTaskSize();if(a){if(this.textEl){var c=(f>0)?String.format(_T("upload","files_selected"),f):"";this.setInputFieldValue(c)}this.onAllSelect(b,l)}else{if(f===0){this.onAllSelect(b,l)}else{this.fireEvent("onBeforeDropfile",this,h,w,{fn:this.dropFiles,files:d,scope:this},this.onAllSelectStr())}}},dropFiles:function(a,b){this.addFiles(a,true,true,b)},checkAllowFiletype:function(a){return SYNO.SDS.App.Uploader.Uploader.prototype.checkAllowFiletype.apply(this,arguments)},onSelect:function(b){var a=Ext.util.Format.htmlEncode(b.name);if(this.opts.limitSize&&(b.size>this.opts.limitSize)){this.arrBigFile.push(a)}else{if(this.opts.limitFiles&&((this.getTaskSize()-this.HTMLUploaderTask.taskUploadingIndex)>=this.opts.limitFiles)){this.nbExceed++;this.arrExceedFile.push(a)}else{if(!this.checkAllowFiletype(a)){this.nbWrongType++;this.arrWrongType.push(a)}else{if(!this.blFolderEabled&&b.isDirectory){this.arrFolder.push(a)}else{return true}}}}return false},getTaskSize:function(){return this.HTMLUploaderTask.getTaskSize()},onAllSelectStr:function(c){var d="",a=c?"<br>":"";var b=0;if(this.nbExceed){d+=(1==this.nbExceed)?_T("common","common_unselect_file"):_T("common","common_unselect_files");d+=a;if(1<this.nbExceed){d=d.replace("_NFILES_",this.nbExceed)}this.nbExceed=0;this.arrExceedFile=[]}if(this.arrBigFile&&0<this.arrBigFile.length){d+=_T("upload","upload_exceed_maximum_filesize")+": "+a;for(b=0;(b<this.arrBigFile.length&&b<5);b++){d+=this.arrBigFile[b]+a}if(5<this.arrBigFile.length){d+="..."+a}d+=a;this.arrBigFile=[]}if(!this.blFolderEabled&&this.arrFolder&&0<this.arrFolder.length){d+=_T("upload",Ext.isMac?"no_folder_upload_action":"upload_folder_error")+a;for(b=0;(b<this.arrFolder.length&&b<5);b++){d+=this.arrFolder[b]+a}if(5<this.arrFolder.length){d+="..."+a}this.arrFolder=[]}if(this.nbWrongType){d+=String.format(_T("upload","wrong_files_format"),this.nbWrongType);this.nbWrongType=0;this.arrWrongType=[]}return d},onAllSelect:function(b,a){var c=this.onAllSelectStr(true);if(c&&c!==""){this.fireEvent("onError",this,c)}this.fireEvent("onAllSelect",this,b,a);if(this.getTaskSize()&&this.opts.instantStart){this.uploadNext.createDelegate(this).defer(10)}return true},onUploadFile:function(d){var b;var c=false;if(Ext.isFunction(SYNO.webfm.VFS.isVFSPath)){c=SYNO.webfm.VFS.isVFSPath(d.params.path)}if(-1!==this.MAX_POST_FILESIZE&&d.size>this.MAX_POST_FILESIZE&&c){this.onError({errno:{section:"error",key:"upload_too_large"}},d);return}b=this.prepareStartFormdata(d);if(d.chunkmode){var e=this.opts.chunksize;var a=Math.ceil(d.size/e);this.onUploadPartailFile(b,d,{start:0,index:0,total:a})}else{this.sendArray(b,d)}},prepareStartFormdata:function(d){var f;var c;if(this.opts.chunkmode||(-1!==this.MAX_POST_FILESIZE&&d.size>this.MAX_POST_FILESIZE)){d.chunkmode=true;var e="----html5upload-"+new Date().getTime().toString()+Math.floor(Math.random()*65535).toString();var a="";if(this.opts.params){for(c in this.opts.params){if(this.opts.params.hasOwnProperty(c)){a+="--"+e+'\r\nContent-Disposition: form-data; name="'+c+'"\r\n\r\n';a+=unescape(encodeURIComponent(this.opts.params[c]))+"\r\n"}}}if(d.params){for(c in d.params){if(d.params.hasOwnProperty(c)){a+="--"+e+'\r\nContent-Disposition: form-data; name="'+c+'"\r\n\r\n';a+=unescape(encodeURIComponent(d.params[c]))+"\r\n"}}}var b=unescape(encodeURIComponent(d.name));a+="--"+e+'\r\nContent-Disposition: form-data; name="'+(this.opts.filefiledname||"file")+'"; filename="'+b+'"\r\nContent-Type: application/octet-stream\r\n\r\n';return{formdata:a,boundary:e}}f=new FormData();if(this.opts.params){for(c in this.opts.params){if(this.opts.params.hasOwnProperty(c)){f.append(c,this.opts.params[c])}}}if(d.params){for(c in d.params){if(d.params.hasOwnProperty(c)){f.append(c,d.params[c])}}}return f},onUploadPartailFile:function(f,a,d,h){d.start=d.index*this.opts.chunksize;var c=Math.min(this.opts.chunksize,a.size-d.start);if(a.status!=="PROCESSING"){return}var b;if(!!(File&&File.prototype.slice)){if((1>d.total)||(d.index===d.total-1)){b=a.file.slice(d.start)}else{b=a.file.slice(d.start,d.start+c)}}else{if(!!(File&&File.prototype.webkitSlice)){if((1>d.total)||(d.index===d.total-1)){b=a.file.webkitSlice(d.start)}else{b=a.file.webkitSlice(d.start,d.start+c)}}else{if(!!(File&&File.prototype.mozSlice)){if((1>d.total)||(d.index===d.total-1)){b=a.file.mozSlice(d.start)}else{b=a.file.mozSlice(d.start,d.start+c)}}else{if(!!(File&&File.prototype.slice)){b=a.file.slice(d.start,c)}else{this.onError({},a);return}}}}if(window.FileReader){var i=this;var e=new FileReader();var g=false;if(!Ext.isFunction(e.readAsBinaryString)){g=true}e.onload=function(j){if(j.target.readyState==FileReader.DONE){i.sendArray(f,a,j.target.result,d,h)}};e.onerror=function(){i.onError({errno:{section:"error",key:"error_privilege_not_enough"}},a)};if(g){e.readAsArrayBuffer(b)}else{e.readAsBinaryString(b)}}else{this.onError({},a);return}},sendArray:function(q,d,g,l,s){if("CANCEL"===d.status){return}var c={};var o={};var k;if(true===d.chunkmode){o={"Content-Type":"multipart/form-data; boundary="+q.boundary};c={"X-TYPE-NAME":"SLICEUPLOAD","X-FILE-SIZE":d.size,"X-FILE-CHUNK-END":(1>l.total)||(l.index===l.total-1)?"true":"false"};if(s){Ext.apply(c,{"X-TMP-FILE":s})}if(window.XMLHttpRequest.prototype.sendAsBinary){var r=q.formdata+(""!==g?g:"")+"\r\n--"+q.boundary+"--\r\n";k=r}else{if(window.Blob){var h=0,f=0,b=0;var a="\r\n--"+q.boundary+"--\r\n";var n=q.formdata.length+a.length;var e;if(!Ext.isString(g)){b=(new Uint8Array(g)).byteLength}else{b=g.length}n+=b;e=new Uint8Array(n);for(h=0;h<q.formdata.length;h++){e[h]=q.formdata.charCodeAt(h)}if(!Ext.isString(g)){e.set(new Uint8Array(g),h)}else{for(f=0;f<g.length;f++){e[h+f]=g.charCodeAt(f)}}h+=b;for(f=0;f<a.length;f++){e[h+f]=a.charCodeAt(f)}k=e}else{var p;if(window.MSBlobBuilder){p=new MSBlobBuilder()}else{if(window.BlobBuilder){p=new BlobBuilder()}}p.append(q.formdata);if(""!==g){p.append(g)}p.append("\r\n--"+q.boundary+"--\r\n");k=p.getBlob();p=null}}}else{q.append("size",d.size);if(d.name){q.append(this.opts.filefiledname,d.file,d.name)}else{q.append(this.opts.filefiledname,d.file)}k=q}this.conn=new Ext.data.Connection({method:"POST",url:this.url,defaultHeaders:o,timeout:null});var m=this.conn.request({headers:c,html5upload:true,chunkmode:d.chunkmode,uploadData:k,success:this.onSuccess.createDelegate(this,[q,d,l],true),failure:this.onFail.createDelegate(this,[d],true),progress:this.onProgress.createDelegate(this,[d,d.chunkmode?l.start:0],true)});d.reqId=m;if(d.isSubFile&&d.rootObj){d.rootObj.reqId=m}k=null},onProgress:function(d,c,b){if(d.lengthComputable){c.size=c.size||0;var a=Math.min(c.size,b+d.loaded);this.fireEvent("onProgress",this,c,a,c.size)}},onSuccess:function(b,c,e,g,a){var d=Ext.util.JSON.decode(b.responseText);if(d.success){if(true===g.chunkmode&&a.index<a.total-1){var f=d.tmpfile||d.data.tmpfile;if(!f||""===f){this.onError({},g);return}a.index++;this.onUploadPartailFile(e,g,a,f);return}this.onFinish(d,g)}else{this.onError(d,g)}},onFinishFolderTask:function(a,b){var c=this.HTMLUploaderTask.taskList.get(b.id);b.file=null;c.finishedFile=(b.isSubFile)?c.finishedFile+1:c.finishedFile;if(c.status!=="CANCEL"){this.sendNextFile(b)}if(c.finishedFile!=c.fileNum){return}b.rootObj.status=(b.rootObj.errors)?"FAIL":"SUCCESS";this.HTMLUploaderTask.taskUploadingIndex++;this.HTMLUploaderTask.blUploading=false;this.fireEvent("onComplete",this,a,b);this.uploadNext()},onFinish:function(a,b){if(b.isSubFile||b.isSubFolder){this.fireEvent("onCompleteFolderFile",this,a,b);this.onFinishFolderTask(a,b);return}this.HTMLUploaderTask.taskUploadingIndex++;this.HTMLUploaderTask.blUploading=false;b.status="SUCCESS";this.fireEvent("onComplete",this,a,b);b.file=null;this.uploadNext()},onError:function(d,e){var b=e.isSubFile,a=e.isSubFolder;if(!b&&!a){this.HTMLUploaderTask.taskUploadingIndex++;this.HTMLUploaderTask.blUploading=false;e.status="FAIL"}if(this.blAppenddata){if(!d){d={errno:{section:"error",key:"upload_folder_error"}}}this.fireEvent("onError",this,d,e)}else{this.nbErrFiles++;var c=(d&&d.errno)?d.errno:({section:"error",key:"upload_folder_error"});if(c&&this.objErrFiles[c.key]){this.objErrFiles[c.key].files.push(e)}else{this.objErrFiles[c.key]={section:c.section,files:[e]}}}if(a){this.sendNextFile(e);return}else{if(b){this.onFinishFolderTask(d,e);return}}this.uploadNext()},onFail:function(a,b,d){var c={};if(Ext.isSafari&&a&&0===a.status){c={errno:{section:"error",key:"upload_folder_error"}}}if(Ext.isChrome&&a&&0===a.status&&"communication failure"===a.statusText){c={errno:{section:"error",key:"error_source_no_file"}}}if(a&&a.responseText){try{c=Ext.util.JSON.decode(a.responseText)}catch(f){c={errno:{section:"common",key:"commfail"}}}}this.onError(c,d)},onAllComplete:function(){var b,g,c,a;this.setInputFieldValue("");if(!this.blAppenddata&&this.getServerErrorCount()>0){var f="";f+=String.format(_T("download","download_upload_erro_files"),this.nbErrFiles);f+=" <br>";for(b in this.objErrFiles){if(this.objErrFiles.hasOwnProperty(b)){g=this.objErrFiles[b].files;c=g.length;var e="";try{e=_T(this.objErrFiles[b].section,b)}catch(d){e=_WFT(this.objErrFiles[b].section,b)}f+=(e||"")+"<br>";for(a=0;a<c;a++){f+=g[a].name+"<br>"}f+="<br>"}}this.objErrFiles={};if(f){this.fireEvent("onError",this,f)}}this.fireEvent("onAllComplete",this)},getServerErrorCount:function(){return this.nbErrFiles},uploadNext:function(){if(true===this.HTMLUploaderTask.blUploading){return}if(false===this.fireEvent("onBeforeSubmit",this)){return}var c,a;var b=this.getTaskSize();for(a=this.HTMLUploaderTask.taskUploadingIndex;a<b;a++){c=this.HTMLUploaderTask.taskList.get(a);if(c&&c.status==="NOT_STARTED"){this.HTMLUploaderTask.blUploading=true;c.status="PROCESSING";this.fireEvent("onOpen",this,c);this.onSendFile(c);break}this.HTMLUploaderTask.taskUploadingIndex++}if(a>=b){this.onAllComplete()}},onSendFile:function(a){this.onUploadFile(a)},onSubmit:function(){if(this.HTMLUploaderTask.taskUploadingIndex>=this.getTaskSize()){this.fireEvent("onError",this,_T("upload","empty_input_file"));return}this.uploadNext()},setInputFieldValue:function(a){if(this.textEl){this.textEl.setValue(a)}}});Ext.ns("SYNO.SDS.App.Uploader.HTMLUploader");SYNO.SDS.App.Uploader.HTMLUploader=Ext.extend(SYNO.SDS.App.Uploader.HTML5Uploader,{constructor:function(b,a){this.initDefData();this.HTMLUploaderTask=new SYNO.SDS.App.Uploader.HTMLUploaderTaskMgr({uploader:this});Ext.apply(this.opts,b);SYNO.SDS.App.Uploader.HTML5Uploader.superclass.constructor.apply(this,arguments);a.container.mon(this,a.opts.listeners);this.initButtonEl(a.container,a.opts)},initButtonEl:function(b,a){if(Ext.isIE||Ext.isMordenIE){return}var e=b.getForm().findField("htmlfield");var d=e.el;var c=this;if(d&&d.is("input[type=file]")){this.inputEl=e;d.dom.onchange=function(){c.addFiles.call(c,[this.files[0]])}}},onAllSelect:function(){SYNO.SDS.App.Uploader.HTMLUploader.superclass.onAllSelect.apply(this,arguments);this.initTaskData()},onSubmit:function(a){if(false!==this.fireEvent("onBeforeSubmit",this)){var b=a.getForm().findField("htmlfield").getValue();if(b===""){this.fireEvent("onError",this,_T("download","download_empty_input_file"));return}else{if(!this.checkAllowFiletype(b)){this.fireEvent("onError",this,_T("download","download_error_wrong_file_format"));return}}a.getForm().doAction("apply",{waitMsg:_T("common","saving")})}}});Ext.ns("SYNO.SDS.App.Uploader");SYNO.SDS.App.Uploader.Utils={};SYNO.SDS.App.Uploader.Utils=Ext.apply({getButtonTemplate:function(a){if(SYNO.SDS.App.Uploader.Utils.isSupportHTML5Upload()){var b=Ext.id();return{itemId:"htmlfield",name:"htmlfield",synotype:"indent",xtype:"compositefield",defaultMargins:"0 2 0 0",hideMode:"display",fieldLabel:_T("download","download_lbl_input_file"),defaults:{hideLabel:true},items:[{xtype:"textfield",readOnly:true,name:"MultiText",width:157},{xtype:"button",text:_T("download","upload_browse"),handler:function(c,d){d.preventDefault();Ext.fly(b).dom.click()}},Ext.apply({itemId:"htmlfield",xtype:"textfield",hideMode:"display",inputType:"file",autoCreate:{id:b,tag:"input",type:"file",multiple:"multiple",style:"width:1px;height:1px;z-index:-1;"}},a||{})]}}else{if(SYNO.SDS.Utils.Flash.isSupport()){return Ext.apply({itemId:"flashfield",synotype:"indent",xtype:"compositefield",defaultMargins:"0 2 0 0",hideMode:"display",fieldLabel:_T("download","download_lbl_input_file"),defaults:{hideLabel:true},items:[{xtype:"textfield",readOnly:true,name:"MultiText",width:157},{id:a.btnFlashId,xtype:"button",itemId:"flashbtn",text:_T("download","upload_browse")}]},a||{})}else{return Ext.apply({itemId:"htmlfield",xtype:"textfield",hideMode:"display",inputType:"file",style:{"padding-top":Ext.isWebKit?"3px":"0"},width:Ext.isSafari?221:Ext.isChrome?218:Ext.isIE?213:220,autoCreate:{tag:"input",type:"file",size:Ext.isGecko?Ext.isMac?18:24:undefined}},a||{})}}}},SYNO.SDS.HTML5Utils);SYNO.SDS.App.Uploader.Uploader=Ext.extend(Ext.util.Observable,{constructor:function(a){this.initDefData();SYNO.SDS.App.Uploader.Uploader.superclass.constructor.call(this,a.cfg);Ext.apply(this.opts,a.cfg||{});Ext.apply(this.htmlopts,a.htmlcfg||{});Ext.apply(this.flashopts,a.flashcfg||{});this.blInputEl=a.cfg.blInputEl;this.files=a.files},initDefData:function(){this.opts={limitSize:2147482624,limitFiles:100,startId:"",url:""};this.flashopts={};this.htmlopts={}},init:function(a){a.mon(a,"afterlayout",this.onAfterLayout,this,{single:true});if(false!==this.blInputEl&&Ext.isFunction(a.getForm)){this.blInputEl=true}},onAfterLayout:function(a){this.initUploader(a)},initUploader:function(a){if(this.opts.startId){var b=Ext.getCmp(this.opts.startId);if(b){a.mon(b,"click",function(d){this.onSubmit(a)},this)}}var c;if(SYNO.SDS.App.Uploader.Utils.isSupportHTML5Upload()){this.initHTML5Uploader(a);if(this.blInputEl){c=a.getForm().findField("flashfield")}}else{if(this.blInputEl&&SYNO.SDS.Utils.Flash.isSupport()){this.initFlashUploader(a);c=a.getForm().findField("htmlfield")}else{if(this.blInputEl){this.initHTMLUploader(a);c=a.getForm().findField("flashfield")}}}if(c){c.label.enableDisplayMode();c.label.hide();c.hide();c.disable()}},initHTML5Uploader:function(a){if(!this.html5uploader){this.html5uploader=new SYNO.SDS.App.Uploader.HTML5Uploader(Ext.apply({limitSize:this.opts.limitSize,limitFiles:this.opts.limitFiles},this.htmlopts||{}),{container:a,opts:this.opts,files:this.files})}},initHTMLUploader:function(a){if(!this.htmluploader){this.htmluploader=new SYNO.SDS.App.Uploader.HTMLUploader(Ext.apply({limitSize:this.opts.limitSize},this.htmlopts||{}),{container:a,opts:this.opts})}},initFlashUploader:function(a){if(!this.btnFlash){this.btnFlash=Ext.get(this.flashopts.btnFlashId)}if(!SwiffUploader.swiffy){SwiffUploader.swiffy=new SYNO.SDS.App.FlashUploader.Uploader({url:this.flashopts.url,typeFilter:this.flashopts.typeFilter,target:this.btnFlash,fieldName:a.getForm().findField("flashfield").name,limitSize:this.opts.limitSize,limitFiles:this.opts.limitFiles,multiple:true,eventtarget:this.flashopts.eventtarget,blSwiffyReady:false})}else{SwiffUploader.swiffy.onSetTarget(this.flashopts.eventtarget,this.btnFlash)}this.swiffy=SwiffUploader.swiffy;a.mon(this.swiffy,this.opts.listeners)},onSubmit:function(a){if(SYNO.SDS.App.Uploader.Utils.isSupportHTML5Upload()){this.html5uploader.onSubmit(a)}else{if(SYNO.SDS.Utils.Flash.isSupport()){this.swiffy.onSubmit(a)}else{this.htmluploader.onSubmit(a)}}},checkAllowFiletype:function(a){var c=this.opts.allowfilters;if(!c||0===c.length){return true}var b=false;Ext.each(c,function(d){if(SYNO.SDS.Utils.isValidExtension(a,"."+d)){b=true;return false}});return b}});