/*
This license text has to stay intact at all times:
Author: Emrah BASKAYA @ www.hesido.com

This script is registered for use by:
Synology Inc.
Under the following licence agreement:
http://www.hesido.com/licenses.php?page=flexcrollcommercialunlimited

Key for this license: 20111109013412901
MD5 hash for this license: abdb3120e42f86d3af038d81a2ef5d36
End of license text---
*/
//fleXcroll v2.0.0
/* Copyright (c) 2020 Synology Inc. All rights reserved. */

var fleXenv={fleXlist:[],fleXcrollInit:function(){if(document.getElementById){document.write('<style type="text/css">.flexcroll-hide-default { overflow: hidden !important; } </style>')}this.addTrggr(window,"load",this.globalInit)},fleXcrollMain:function(aD,E){var aB=document,M=window,A=navigator,L=(A.msPointerEnabled&&A.msMaxTouchPoints>0),am={};E=E||false;if(!aB.getElementById||!aB.createElement){return}if(typeof(aD)=="string"){aD=document.getElementById(aD)}if(aD==null||A.userAgent.indexOf("OmniWeb")!=-1||((A.userAgent.indexOf("AppleWebKit")!=-1||A.userAgent.indexOf("Safari")!=-1)&&!(typeof(HTMLElement)!="undefined"&&HTMLElement.prototype))||A.vendor=="KDE"||(A.platform.indexOf("Mac")!=-1&&A.userAgent.indexOf("MSIE")!=-1)){if(aD!=null){aq(aD,"flexcroll-failed","flexcroll-hide-default")}if(window.onfleXcrollFail){window.onfleXcrollFail(aD)}return}if(aD.fleXcroll){aD.fleXcroll.updateScrollBars();return}if(fleXenv.checkHidden(aD)){return}if(!aD.id||aD.id==""){var aA="flex__",aF=1;while(document.getElementById(aA+aF)!=null){aF++}aD.id=aA+aF}aD.fleXdata=new Object();aD.fleXcroll=new Object();var ay=aD.id,ak=aD.fleXdata,O=aD.fleXcroll;O.enableWillChange=false;ak.keyAct={_37:["-1s",0],_38:[0,"-1s"],_39:["1s",0],_40:[0,"1s"],_33:[0,"-1p"],_34:[0,"1p"],_36:[0,"-100p"],_35:[0,"+100p"]};ak.wheelAct=["-2s","2s"];ak.baseAct=["-2s","2s"];ak.scrollPosition=[[false,false],[false,false]];var ax=ag("contentwrapper",true),aE=ag("mcontentwrapper",true),r=ag("scrollwrapper",true),S=ag("copyholder",true);var aw=ag("domfixdiv",true),ai=ag("zoomdetectdiv",true),az=false;S.sY.border="1px solid blue";S.fHide();aD.style.overflow="hidden";ai.sY.fontSize="12px";ai.sY.height="1em";ai.sY.width="1em";ai.sY.position="absolute";ai.sY.zIndex="-999";ai.fHide();var av=aD.offsetHeight,H=aD.offsetWidth;aG(aD,S,"0px",["border-left-width","border-right-width","border-top-width","border-bottom-width"]);var ar=aD.offsetHeight,v=aD.offsetWidth,aC=H-v,ao=av-ar;var ap=(aD.scrollTop)?aD.scrollTop:0,Y=(aD.scrollLeft)?aD.scrollLeft:0;var an=document.location.href,N=/#([^#.]*)$/;var al=["textarea","input","select"];ak.scroller=[];ak.forcedBar=[];ak.containerSize=ak.cntRSize=[];ak.contentSize=ak.cntSize=[];ak.edge=[false,false];ak.touchPrevent=false;ak.touchFlick=false;ak.reqS=[];ak.barSpace=[0,0];ak.forcedHide=[];ak.forcedPos=[];ak.paddings=[];ak.externaL=[false,false];ak.touchPos=[0,0];while(aD.firstChild){ax.appendChild(aD.firstChild)}ax.appendChild(aw);aD.appendChild(aE);aD.appendChild(S);var af=ah(aD,"position");if(af!="absolute"&&af!="fixed"){aD.style.position=af="relative"}if(af=="fixed"){aD.style.position="absolute"}var ae=ah(aD,"text-align");aD.style.textAlign="left";aE.sY.width="100px";aE.sY.height="100px";aE.sY.top="0px";aE.sY.left="0px";aG(aD,S,"0px",["padding-left","padding-top","padding-right","padding-bottom"]);var ac=aD.offsetWidth,K=aD.offsetHeight,au;au=aE.offsetHeight;aE.sY.borderBottom="2px solid black";if(aE.offsetHeight>au){az=true}aE.sY.borderBottomWidth="0px";aG(S,aD,false,["padding-left","padding-top","padding-right","padding-bottom"]);Z(aE);Z(aD);ak.paddings[0]=aE.yPos-aD.yPos;ak.paddings[2]=aE.xPos-aD.xPos;aD.style.paddingTop=ah(aD,"padding-bottom");aD.style.paddingLeft=ah(aD,"padding-right");Z(aE);Z(aD);ak.paddings[1]=aE.yPos-aD.yPos;ak.paddings[3]=aE.xPos-aD.xPos;aD.style.paddingTop=ah(S,"padding-top");aD.style.paddingLeft=ah(S,"padding-left");var aa=ak.paddings[2]+ak.paddings[3],ab=ak.paddings[0]+ak.paddings[1];aD.style.position=af;aE.style.textAlign=ae;aG(aD,aE,false,["padding-left","padding-right","padding-top","padding-bottom"]);r.sY.width=aD.offsetWidth+"px";r.sY.height=aD.offsetHeight+"px";aE.sY.width=ac+"px";aE.sY.height=K+"px";r.sY.position="absolute";r.sY.top="0px";r.sY.left="0px";ak.tDivZ=r.sY.zIndex;aE.appendChild(ax);aD.appendChild(r);r.appendChild(ai);ax.sY.position="relative";aE.sY.position="relative";ax.sY.top="0";ax.sY.width="100%";aE.sY.overflow="hidden";aE.sY.left=""+(0-ak.paddings[2])+"px";aE.sY.top=""+(0-ak.paddings[0])+"px";ak.zTHeight=ai.offsetHeight;ak.getContentWidth=function(){var c=ax.childNodes,h=compPad=0;for(var g=0;g<c.length;g++){if(c[g].offsetWidth){h=Math.max(c[g].offsetWidth,h)}}ak.cntRSize[0]=((ak.reqS[1]&&!ak.forcedHide[1])||ak.forcedBar[1])?aD.offsetWidth-ak.barSpace[0]:aD.offsetWidth;ak.cntSize[0]=h+aa;return ak.cntSize[0]};ak.getContentHeight=function(){ak.cntRSize[1]=((ak.reqS[0]&&!ak.forcedHide[0])||ak.forcedBar[0])?aD.offsetHeight-ak.barSpace[1]:aD.offsetHeight;ak.cntSize[1]=ax.offsetHeight+ab-2;return ak.cntSize[1]};ak.fixIEDispBug=function(){ax.sY.display="none";ax.sY.display="block"};ak.setWidth=function(){aE.sY.width=(az)?(ak.cntRSize[0]-aa-aC)+"px":ak.cntRSize[0]+"px"};ak.setHeight=function(){aE.sY.height=(az)?(ak.cntRSize[1]-ab-ao)+"px":ak.cntRSize[1]+"px"};ak.isFocusProtectElement=function(c){if(!c){return false}return["textarea","input","select"].indexOf(c.tagName.toLowerCase())>=0||c.getAttribute("contenteditable")==="true"},ak.createScrollBars=function(){ak.getContentWidth();ak.getContentHeight();r.vrt=new Array();var g=r.vrt;I(g,"vscroller",1);g.barPadding=[parseInt(ah(g.sBr,"padding-top")),parseInt(ah(g.sBr,"padding-bottom"))];g.sBr.sY.padding="0px";g.sBr.curPos=0;g.sBr.vertical=true;g.sBr.indx=1;ax.vBar=g.sBr;f(g,0);ak.barSpace[0]=(ak.externaL[1])?0:g.sDv.offsetWidth;ak.setWidth();r.hrz=new Array();var c=r.hrz;I(c,"hscroller",0);c.barPadding=[parseInt(ah(c.sBr,"padding-left")),parseInt(ah(c.sBr,"padding-right"))];c.sBr.sY.padding="0px";c.sBr.curPos=0;c.sBr.vertical=false;c.sBr.indx=0;ax.hBar=c.sBr;if(M.opera){c.sBr.sY.position="relative"}f(c,0);ak.barSpace[1]=(ak.externaL[0])?0:c.sDv.offsetHeight;ak.setHeight();r.sY.height=aD.offsetHeight+"px";c.jBox=ag("scrollerjogbox");r.appendChild(c.jBox);c.jBox.onmousedown=function(){c.sBr.scrollBoth=true;ak.goScroll=c.sBr;c.sBr.clicked=true;c.sBr.moved=false;r.vrt.sBr.moved=false;fleXenv.addTrggr(aB,"selectstart",R);fleXenv.addTrggr(aB,"mousemove",W);fleXenv.addTrggr(aB,"mouseup",Q);return false}};ak.goScroll=null;ak.createScrollBars();this.putAway(aw,r);if(!this.addChckTrggr(aD,"mousewheel",b)||!this.addChckTrggr(aD,"DOMMouseScroll",b)){aD.onmousewheel=b}this.addChckTrggr(aD,"mousewheel",b);this.addChckTrggr(aD,"DOMMouseScroll",b);if(L){this.addChckTrggr(ax,"MSPointerCancel",ad);this.addChckTrggr(r,"MSPointerCancel",ad)}this.addChckTrggr(ax,L?"MSPointerDown":"touchstart",D);this.addChckTrggr(r,L?"MSPointerDown":"touchstart",D);if(typeof aD.getAttribute("tabindex")!=="string"){aD.setAttribute("tabIndex","-1")}this.addTrggr(aD,"keydown",function(g){if(aD.focusProtect){return}if(!g){var g=M.event}if(ak.isFocusProtectElement(g.target)){return}var c=g.keyCode;ak.pkeY=c;O.mDPosFix();if(ak.keyAct["_"+c]&&!window.opera){O.setScrollPos(ak.keyAct["_"+c][0],ak.keyAct["_"+c][1],true);if(g.preventDefault){g.preventDefault()}return false}});this.addTrggr(aD,"keyup",function(){ak.pkeY=false});this.addTrggr(aB,"mouseup",at);this.addTrggr(aB,"dragend",at);if(!E){this.addTrggr(aD,"mousedown",G)}function G(g){if(g.button!==undefined&&g.button!==0){return}if(!g){g=M.event}var c=(g.target)?g.target:(g.srcElement)?g.srcElement:false;if(!c||(c.className&&c.className.match&&c.className.match(RegExp("\\bscrollgeneric\\b")))){return}ak.inMposX=g.clientX;ak.inMposY=g.clientY;n();Z(aD);at();fleXenv.addTrggr(aB,"mousemove",i);ak.mTBox=[aD.xPos+10,aD.xPos+ak.cntRSize[0]-10,aD.yPos+10,aD.yPos+ak.cntRSize[1]-10]}function i(l){if(!l){l=M.event}var c=l.clientX,k=l.clientY,h=c+ak.xScrld,g=k+ak.yScrld;ak.mOnXEdge=(h<ak.mTBox[0]||h>ak.mTBox[1])?1:0;ak.mOnYEdge=(g<ak.mTBox[2]||g>ak.mTBox[3])?1:0;ak.xAw=c-ak.inMposX;ak.yAw=k-ak.inMposY;ak.sXdir=(ak.xAw>40)?1:(ak.xAw<-40)?-1:0;ak.sYdir=(ak.yAw>40)?1:(ak.yAw<-40)?-1:0;if((ak.sXdir!=0||ak.sYdir!=0)&&!ak.tSelectFunc){ak.tSelectFunc=M.setInterval(function(){if(ak.sXdir==0&&ak.sYdir==0){M.clearInterval(ak.tSelectFunc);ak.tSelectFunc=false;return}n();if(ak.mOnXEdge==1||ak.mOnYEdge==1){O.setScrollPos((ak.sXdir*ak.mOnXEdge)+"s",(ak.sYdir*ak.mOnYEdge)+"s",true)}},45)}}function at(){fleXenv.remTrggr(aB,"mousemove",i);if(ak.tSelectFunc){M.clearInterval(ak.tSelectFunc)}ak.tSelectFunc=false;if(ak.barClickRetard){M.clearTimeout(ak.barClickRetard)}if(ak.barClickScroll){M.clearInterval(ak.barClickScroll)}}function P(){if(ax.sY.willChange!=="top"){ax.sY.willChange="top"}if(ax.willChangeTask){clearTimeout(ax.willChangeTask)}ax.willChangeTask=setTimeout(J,3000)}function J(){ax.sY.willChange="";ax.willChangeTask=undefined}function F(c){if(ak.touchFlick){window.clearInterval(ak.touchFlick);ak.touchFlick=false}if(!c){r.sY.zIndex=ak.tDivZ}}function n(){ak.xScrld=(M.pageXOffset)?M.pageXOffset:(aB.documentElement&&aB.documentElement.scrollLeft)?aB.documentElement.scrollLeft:0;ak.yScrld=(M.pageYOffset)?M.pageYOffset:(aB.documentElement&&aB.documentElement.scrollTop)?aB.documentElement.scrollTop:0}O.formUpdate=function(){for(var h=0,g;g=al[h];h++){var c=aD.getElementsByTagName(g);for(var k=0,l;l=c[k];k++){if(!l.fleXprocess){fleXenv.addTrggr(l,"focus",function(){aD.focusProtect=true});fleXenv.addTrggr(l,"blur",onblur=function(){aD.focusProtect=false});l.fleXprocess=true}}}};aD.scrollUpdate=O.updateScrollBars=function(s){if(r.getSize[1]()===0||r.getSize[0]()===0){return}ax.sY.padding="1px";var p=ak.reqS[0],h=ak.reqS[1],o=r.vrt,m=r.hrz,k,g,q=[];r.sY.width=aD.offsetWidth-aC+"px";r.sY.height=aD.offsetHeight-ao+"px";q[0]=ak.cntRSize[0];q[1]=ak.cntRSize[1];ak.reqS[0]=ak.getContentWidth()>ak.cntRSize[0];ak.reqS[1]=ak.getContentHeight()>ak.cntRSize[1];var l=(p!=ak.reqS[0]||h!=ak.reqS[1]||q[0]!=ak.cntRSize[0]||q[1]!=ak.cntRSize[1])?true:false;o.sDv.setVisibility(ak.reqS[1]);m.sDv.setVisibility(ak.reqS[0]);k=(ak.reqS[1]||ak.forcedBar[1]);g=(ak.reqS[0]||ak.forcedBar[0]);ak.getContentWidth();ak.getContentHeight();ak.setHeight();ak.setWidth();if(!ak.reqS[0]||!ak.reqS[1]||ak.forcedHide[0]||ak.forcedHide[1]){m.jBox.fHide()}else{m.jBox.fShow()}if(k){X(o,(g&&!ak.forcedHide[0])?ak.barSpace[1]:0)}else{ax.sY.top="0"}if(g){X(m,(k&&!ak.forcedHide[1])?ak.barSpace[0]:0)}else{ax.sY.left="0"}if(l&&!s){O.updateScrollBars(true)}ax.sY.padding="0px";ak.edge[0]=ak.edge[1]=false};aD.contentScroll=O.setScrollPos=function(h,g,p,o,m){var l,k=1;if(O.enableWillChange){P()}if((h||h===0)&&ak.scroller[0]){h=C(h,0);h*=(typeof m!=="undefined")?m:k;l=r.hrz.sBr;l.trgtScrll=(p)?Math.min(Math.max(l.mxScroll,l.trgtScrll-h),0):-h;l.realScrollPos()}if((g||g===0)&&ak.scroller[1]){g=C(g,1);g*=(typeof m!=="undefined")?m:k;l=r.vrt.sBr;l.trgtScrll=((p)?Math.min(Math.max(l.mxScroll,l.trgtScrll-g),0):-g);l.realScrollPos()}if(!p){ak.edge[0]=ak.edge[1]=false}if(aD.onfleXcroll&&!o){aD.onfleXcroll()}return ak.scrollPosition};O.scrollContent=function(g,c){g=Math.abs(g)<0.001?0:g;c=Math.abs(c)<0.001?0:c;return O.setScrollPos(g,c,true)};O.scrollToElement=function(g){if(g==null||!V(g)){return}var c=B(g);O.setScrollPos(c[0]+ak.paddings[2],c[1]+ak.paddings[0],false);O.setScrollPos(0,0,true)};aG(S,aD,"0px",["border-left-width","border-right-width","border-top-width","border-bottom-width"]);this.putAway(S,r);aD.scrollTop=0;aD.scrollLeft=0;O.formUpdate();this.fleXlist[this.fleXlist.length]=aD;aq(aD,"flexcrollactive",false);O.updateScrollBars();O.setScrollPos(Y,ap,true);if(an.match(N)){O.scrollToElement(aB.getElementById(an.match(N)[1]))}ak.sizeChangeDetect=M.setInterval(function(){var c=ai.offsetHeight;if(c!=ak.zTHeight){O.updateScrollBars();ak.zTHeight=c}},2500);function C(g,h){var c=g.toString();g=parseFloat(c);return parseInt((c.match(/p$/))?g*ak.cntRSize[h]*0.9:(c.match(/s$/))?g*ak.cntRSize[h]*0.1:g)}function ah(g,c){return fleXenv.getStyle(g,c)}function aG(h,g,o,m){var l=new Array();for(var k=0;k<m.length;k++){l[k]=fleXenv.camelConv(m[k]);g.style[l[k]]=ah(h,m[k],l[k]);if(o){h.style[l[k]]=o}}}function ag(g,m,l,k){var h=(l)?l:aB.createElement("div");if(!l){h.id=ay+"_"+g;h.className=(m)?g:g+" scrollgeneric"}h.getSize=[function(){return h.offsetWidth},function(){return h.offsetHeight}];h.setSize=(k)?[R,R]:[function(c){h.sY.width=c},function(c){h.sY.height=c}];h.getPos=[function(){return ah(h,"left")},function(){return ah(h,"top")}];h.setPos=(k)?[R,R]:[function(c){h.sY.left=c},function(c){h.sY.top=c}];h.fHide=function(){h.sY.visibility="hidden"};h.fShow=function(c){h.sY.visibility=(c)?ah(c,"visibility"):"visible"};h.sY=h.style;return h}function I(h,g,m){var l=document.getElementById(ay+"-flexcroll-"+g);var k=(l!=null)?true:false;if(k){h.sDv=ag(false,false,l,true);ak.externaL[m]=true;h.sFDv=ag(g+"basebeg");h.sSDv=ag(g+"baseend");h.sBr=ag(false,false,fleXenv.getByClassName(l,"div","flexcroll-scrollbar")[0]);h.sFBr=ag(g+"barbeg");h.sSBr=ag(g+"barend")}else{h.sDv=ag(g+"base");h.sFDv=ag(g+"basebeg");h.sSDv=ag(g+"baseend");h.sBr=ag(g+"bar");h.sFBr=ag(g+"barbeg");h.sSBr=ag(g+"barend");r.appendChild(h.sDv);h.sDv.appendChild(h.sBr);h.sDv.appendChild(h.sFDv);h.sDv.appendChild(h.sSDv);h.sBr.appendChild(h.sFBr);h.sBr.appendChild(h.sSBr)}}function f(g,m){var l=g.sDv,k=g.sBr,h=k.indx;k.trgtScrll=0;k.minPos=g.barPadding[0];k.ofstParent=l;k.mDv=aE;k.scrlTrgt=ax;k.targetSkew=0;X(g,m,true);k.doBarPos=function(c){if(!c){k.curPos=parseInt((k.trgtScrll*k.maxPos)/k.mxScroll)}k.curPos=(Math.min(Math.max(k.curPos,0),k.maxPos));k.setPos[h](k.curPos+k.minPos+"px");if(!k.targetSkew){k.targetSkew=k.trgtScrll-parseInt((k.curPos/k.sRange)*k.mxScroll)}k.targetSkew=(k.curPos==0)?0:(k.curPos==k.maxPos)?0:(!k.targetSkew)?0:k.targetSkew;if(c){k.trgtScrll=parseInt((k.curPos/k.sRange)*k.mxScroll);ax.setPos[h](k.trgtScrll+k.targetSkew+"px");ak.scrollPosition[h]=[-k.trgtScrll-k.targetSkew,-k.mxScroll]}};k.realScrollPos=function(){k.curPos=parseInt((k.trgtScrll*k.sRange)/k.mxScroll);k.curPos=(Math.min(Math.max(k.curPos,0),k.maxPos));ax.setPos[h](k.trgtScrll+"px");ak.scrollPosition[h]=[-k.trgtScrll,-k.mxScroll];k.targetSkew=false;k.doBarPos(false)};ak.barZ=ah(k,"z-index");k.sY.zIndex=(ak.barZ=="auto"||ak.barZ=="0"||ak.barZ=="normal")?2:ak.barZ;aE.sY.zIndex=ah(k,"z-index");k.onmousedown=function(){k.clicked=true;ak.goScroll=k;k.scrollBoth=false;k.moved=false;fleXenv.addTrggr(aB,"selectstart",R);fleXenv.addTrggr(aB,"mousemove",W);fleXenv.addTrggr(aB,"mouseup",Q);return false};k.onmouseover=at;l.onmousedown=l.ondblclick=function(o){if(!o){var o=M.event}if(o.target&&(o.target==g.sFBr||o.target==g.sSBr||o.target==g.sBr)){return}if(o.srcElement&&(o.srcElement==g.sFBr||o.srcElement==g.sSBr||o.srcElement==g.sBr)){return}var c,p=[];n();O.mDPosFix();Z(k);c=(k.vertical)?o.clientY+ak.yScrld-k.yPos:o.clientX+ak.xScrld-k.xPos;p[k.indx]=(c<0)?ak.baseAct[0]:ak.baseAct[1];p[1-k.indx]=0;O.setScrollPos(p[0],p[1],true);if(o.type!="dblclick"){at();ak.barClickRetard=M.setTimeout(function(){ak.barClickScroll=M.setInterval(function(){O.setScrollPos(p[0],p[1],true)},80)},425)}return false};l.setVisibility=function(c){if(c){l.fShow(aD);ak.forcedHide[h]=(ah(l,"visibility")=="hidden")?true:false;if(!ak.forcedHide[h]){k.fShow(aD)}else{if(!ak.externaL[h]){k.fHide()}}ak.scroller[h]=true;aq(l,"","flexinactive")}else{l.fHide();k.fHide();ak.forcedBar[h]=(ah(l,"visibility")!="hidden")?true:false;ak.scroller[h]=false;k.curPos=0;ax.setPos[h]("0px");ak.scrollPosition[h]=[false,false];aq(l,"flexinactive","")}aE.setPos[1-h]((ak.forcedPos[h]&&(c||ak.forcedBar[h])&&!ak.forcedHide[h])?ak.barSpace[1-h]-ak.paddings[h*2]+"px":(""+(0-ak.paddings[h*2])+"px"))};l.onmouseclick=R}function X(t,s,q){var p=t.sDv,g=t.sBr,o=t.sFDv,l=t.sFBr,k=t.sSDv,h=t.sSBr,m=g.indx;p.setSize[m](r.getSize[m]()-s+"px");p.setPos[1-m](r.getSize[1-m]()-p.getSize[1-m]()+"px");ak.forcedPos[m]=(parseInt(p.getPos[1-m]())===0)?true:false;t.padLoss=t.barPadding[0]+t.barPadding[1];t.baseProp=parseInt((p.getSize[m]()-t.padLoss)*0.99);g.aSize=Math.min(Math.max(Math.min(parseInt(ak.cntRSize[m]/ak.cntSize[m]*p.getSize[m]()),t.baseProp),45),t.baseProp);g.setSize[m](g.aSize+"px");g.maxPos=p.getSize[m]()-g.getSize[m]()-t.padLoss;g.curPos=Math.min(Math.max(0,g.curPos),g.maxPos);g.setPos[m](g.curPos+g.minPos+"px");g.mxScroll=aE.getSize[m]()-ak.cntSize[m];g.sRange=g.maxPos;o.setSize[m](p.getSize[m]()-k.getSize[m]()+"px");l.setSize[m](g.getSize[m]()-h.getSize[m]()+"px");h.setPos[m](g.getSize[m]()-h.getSize[m]()+"px");k.setPos[m](p.getSize[m]()-k.getSize[m]()+"px");if(!q){g.realScrollPos()}ak.fixIEDispBug()}O.mDPosFix=function(){if(O.posFix===false){return}aE.scrollTop=0;aE.scrollLeft=0;aD.scrollTop=0;aD.scrollLeft=0};this.addTrggr(M,"load",function(){if(aD.fleXcroll){O.updateScrollBars()}});function R(){return false}function W(l){if(!l){var l=M.event}var g=ak.goScroll,o,m,k,c;if(g==null){return}if(!fleXenv.w3events&&!l.button){Q()}m=(g.scrollBoth)?2:1;for(var h=0;h<m;h++){o=(h==1)?g.scrlTrgt.vBar:g;if(g.clicked){if(!o.moved){O.mDPosFix();Z(o);Z(o.ofstParent);o.pointerOffsetY=l.clientY-o.yPos;o.pointerOffsetX=l.clientX-o.xPos;o.inCurPos=o.curPos;o.moved=true}o.curPos=(o.vertical)?l.clientY-o.pointerOffsetY-o.ofstParent.yPos-o.minPos:l.clientX-o.pointerOffsetX-o.ofstParent.xPos-o.minPos;if(g.scrollBoth){o.curPos=o.curPos+(o.curPos-o.inCurPos)}if(O.enableWillChange){P()}o.doBarPos(true);if(aD.onfleXcroll){aD.onfleXcroll()}}else{o.moved=false}}}function Q(){if(ak.goScroll!=null){ak.goScroll.clicked=false;ak.goScroll.trgtScrll+=ak.goScroll.targetSkew}ak.goScroll=null;fleXenv.remTrggr(aB,"selectstart",R);fleXenv.remTrggr(aB,"mousemove",W);fleXenv.remTrggr(aB,"mouseup",Q);if(window.scrollState){var g=!ak.scroller[1]||(ak.scroller[1]&&((scrollState[1][0]==scrollState[1][1])||(scrollState[1][0]==0))),c=!ak.scroller[0]||(ak.scroller[0]&&ak.scroller[1]&&g)||(ak.scroller[0]&&((scrollState[0][0]==scrollState[0][1])||(scrollState[0][0]==0)));if(!(g&&c)){ak.edge[0]=false;ak.edge[1]=false}}}function U(g){var h,c=0;if(g){for(h in g){c++}}return c}function D(h){if(!h){h=M.event}if(this==r){r.sY.zIndex=ak.tDivZ}if(L&&h.pointerId){am[h.pointerId]=[h.clientX,h.clientY]}aD.touchCount=U(am);if(((L&&aD.touchCount!==1)||(!L&&h.targetTouches.length!=1))||(!ak.scroller[0]&&!ak.scroller[1])){am={};return false}var c="",g=(h.target&&(h.target.href||(h.target.nodeType==3&&h.target.parentNode.href)))?true:false;ak.touchPos=L?[h.clientX,h.clientY]:[h.targetTouches[0].clientX,h.targetTouches[0].clientY];F();fleXenv.addChckTrggr(aD,L?"MSPointerMove":"touchmove",d);fleXenv.addChckTrggr(aD,L?"MSPointerUp":"touchend",j);ak.touchBar=(h.target&&h.target.id&&h.target.id.match(/_[vh]scrollerba[rs]e?/))?true:false;return false}function ad(c){am={}}function d(h){if(!h){h=M.event}if((L&&aD.touchCount!==1)||(!L&&h.targetTouches.length!=1)){return false}fleXenv.remTrggr(aD,"mousedown",G);var c=L?[h.clientX,h.clientY]:[h.targetTouches[0].clientX,h.targetTouches[0].clientY];ak.touchPrevent=true;ak.moveDelta=[ak.touchPos[0]-c[0],ak.touchPos[1]-c[1]];if(ak.touchBar){ak.moveDelta[0]*=-(ak.cntSize[0]/ak.cntRSize[0]);ak.moveDelta[1]*=-(ak.cntSize[1]/ak.cntRSize[1])}O.scrollContent(ak.moveDelta[0],ak.moveDelta[1]);ak.touchPos[0]=c[0];ak.touchPos[1]=c[1];for(var g=0;g<2;g++){if(ak.moveDelta[g]!==0&&ak.scroller[g]&&(ak.moveDelta[1-g]==0||!ak.scroller[1-g])){if((ak.moveDelta[g]>0&&ak.scrollPosition[g][1]==ak.scrollPosition[g][0])||(ak.moveDelta[g]<0&&ak.scrollPosition[g][0]==0)){ak.touchPrevent=false}}if(!ak.scroller[g]&&ak.moveDelta[1-g]!==0&&Math.abs(ak.moveDelta[g]/ak.moveDelta[1-g])>1.1){ak.touchPrevent=false}}if(ak.touchPrevent){h.preventDefault();if(!L){r.sY.zIndex="9999"}}else{r.sY.zIndex=ak.tDivZ}}function e(h,g){var c=h<0?-1:1,k=h*g.velocityRate,k=Math.abs(k)<1?c*1:k;tickCount=Math.abs(k*g.velocityRate)/0.8;tickCount=tickCount<g.minTickCount?g.minTickCount:tickCount;tickCount*=g.tickRate;return{distance:k,tickCount:tickCount}}function j(l){if(!l){l=M.event}if(am&&am[l.pointerId]){delete am[l.pointerId]}if((L&&U(am)>0)||(!L&&l.targetTouches&&l.targetTouches.length>0)){return false}fleXenv.remTrggr(aD,L?"MSPointerMove":"touchmove",d);fleXenv.remTrggr(aD,L?"MSPointerUp":"touchend",j);if((ak.scroller[0]&&(ak.moveDelta)&&Math.abs(ak.moveDelta[0])>6)||(ak.scroller[1]&&(ak.moveDelta)&&Math.abs(ak.moveDelta[1])>6)){var k=0,g={tickRate:1.5,minTickCount:65,velocityRate:4/5},m=e(ak.moveDelta[0],g),h=e(ak.moveDelta[1],g),c=parseInt(Math.max(m.tickCount,h.tickCount),10);F(true);ak.touchFlick=window.setInterval(function(){if(k==c){F();return}var o=aj(m.distance,0,c,k),p=aj(h.distance,0,c,k);O.scrollContent(o,p);k++},parseInt(25/g.tickRate,10))}}function a(c){var g=0;if(c.wheelDeltaX){g=(Math.abs(c.wheelDeltaX)>Math.abs(c.wheelDeltaY))?c.wheelDeltaX:c.wheelDeltaY;g=g/120}else{if(c.wheelDelta){g=c.wheelDelta/120}else{if(c.detail){g=-c.detail/3}}}return -g}function b(o){if(!o){o=M.event}if(!this.fleXcroll){return}var h=this,m,g,l=false,p=0,k,c;O.mDPosFix();c=(o.target)?o.target:(o.srcElement)?o.srcElement:this;if((c.id&&c.id.match(/_hscroller/))||(o.wheelDeltaX&&Math.abs(o.wheelDeltaX)>Math.abs(o.wheelDeltaY))){l=true}p=a(o);k=(p<0)?0:1;ak.edge[1-k]=false;if((ak.edge[k]&&!l)||(!ak.scroller[0]&&!ak.scroller[1])){return}if(ak.scroller[1]&&!l){scrollState=O.setScrollPos(false,ak.wheelAct[k],true,null,Math.abs(p))}m=!ak.scroller[1]||l||(ak.scroller[1]&&((scrollState[1][0]==scrollState[1][1]&&p>0)||(scrollState[1][0]==0&&p<0)));if(ak.scroller[0]&&(!ak.scroller[1]||l)){scrollState=O.setScrollPos(ak.wheelAct[k],false,true,null,Math.abs(p))}g=!ak.scroller[0]||(ak.scroller[0]&&ak.scroller[1]&&m&&!l)||(ak.scroller[0]&&((scrollState[0][0]==scrollState[0][1]&&p>0)||(scrollState[0][0]==0&&p<0)));if(m&&g&&!l){ak.edge[k]=true}else{ak.edge[k]=false}if(o.preventDefault&&!((g&&l)||(m&&!l))){o.preventDefault()}return false}function V(c){while(c.parentNode){c=c.parentNode;if(c==aD){return true}}return false}function Z(g){var c=g,h=curtop=0;if(c.offsetParent){while(c){h+=c.offsetLeft;curtop+=c.offsetTop;c=c.offsetParent}}else{if(c.x){h+=c.x;curtop+=c.y}}g.xPos=h;g.yPos=curtop}function B(g){var c=g;curleft=curtop=0;while(!c.offsetHeight&&c.parentNode&&c!=ax&&ah(c,"display")=="inline"){c=c.parentNode}if(c.offsetParent){while(c!=ax){curleft+=c.offsetLeft;curtop+=c.offsetTop;c=c.offsetParent}}return[curleft,curtop]}function aq(h,g,k){fleXenv.classChange(h,g,k)}function T(o,c,k,g,m){k=Math.max(k,1);var l=c-o,h=o+(Math.pow(((1/k)*g),m)*l);return(h>0)?Math.floor(h):Math.ceil(h)}function aj(k,c,h,g){return Math.easeOutQuint(g,k,(-1)*k,h-c)}Math.easeOutExpo=function(h,g,l,k){return l*(-Math.pow(2,-10*h/k)+1)+g};Math.easeOutQuint=function(h,g,l,k){h/=k;h--;return l*(h*h*h*h*h+1)+g};Math.easeOutQuad=function(h,g,l,k){h/=k;return -l*h*(h-2)+g}},globalInit:function(){if(fleXenv.catchFastInit){window.clearInterval(fleXenv.catchFastInit)}fleXenv.prepAnchors();fleXenv.initByClass();if(window.onfleXcrollRun){window.onfleXcrollRun()}},classChange:function(f,e,h){if(!f.className){f.className=""}var g=f.className;if(e&&!g.match(RegExp("(^|\\s)"+e+"($|\\s)"))){g=g.replace(/(\S$)/,"$1 ")+e}if(h){g=g.replace(RegExp("((^|\\s)+"+h+")+($|\\s)","g"),"$2").replace(/\s$/,"")}f.className=g},prepAnchors:function(){var e=/#([^#.]*)$/,k=/(.*)#.*$/,h=/(^|\s)flexcroll-in-page-link($|\s)/,j,f,c,g,a=document.getElementsByTagName("a"),b=document.location.href;if(b.match(k)){b=b.match(k)[1]}for(c=0;g=a[c];c++){f=(g.className)?g.className:"";if(g.href&&!g.fleXanchor&&g.href.match(e)&&((g.href.match(k)&&b===g.href.match(k)[1])||f.match(h))){g.fleXanchor=true;fleXenv.addTrggr(g,"click",function(m){if(!m){m=window.event}var i=(m.srcElement)?m.srcElement:this;while(!i.fleXanchor&&i.parentNode){i=i.parentNode}if(!i.fleXanchor){return}var d=document.getElementById(i.href.match(e)[1]),l=false;if(d==null){d=(d=document.getElementsByName(i.href.match(e)[1])[0])?d:null}if(d!=null){var n=d;while(n.parentNode){n=n.parentNode;if(n.fleXcroll){n.fleXcroll.scrollToElement(d);l=n}}if(l){if(m.preventDefault){m.preventDefault()}document.location.href=b+"#"+i.href.match(e)[1];l.fleXcroll.mDPosFix();return false}}})}}},initByClass:function(d){fleXenv.initialized=true;var c=fleXenv.getByClassName(document.getElementsByTagName("body")[0],"div",(d)?d:"flexcroll");for(var e=0,f;f=c[e];e++){if(!f.fleXcroll){fleXenv.fleXcrollMain(f)}}},scrollTo:function(e,d){if(typeof(e)=="string"){e=document.getElementById(e)}if(e==null){return false}var f=e;while(f.parentNode){f=f.parentNode;if(f.fleXcroll){if(d){document.location.href="#"+d}f.fleXcroll.scrollToElement(e);f.fleXcroll.mDPosFix();return true}}return false},updateScrollBars:function(d,c){for(var e=0,f;f=fleXenv.fleXlist[e];e++){f.fleXcroll.updateScrollBars();if(c){f.fleXcroll.formUpdate()}}if(d){fleXenv.prepAnchors()}},camelConv:function(b){var b=b.split("-"),c=b[0],d;for(d=1;parT=b[d];d++){c+=parT.charAt(0).toUpperCase()+parT.substr(1)}return c},getByClassName:function(o,n,m){if(typeof(o)=="string"){o=document.getElementById(o)}if(o==null){return false}var k=new RegExp("(^|\\s)"+m+"($|\\s)"),f,g=[],p=0;var j=o.getElementsByTagName(n);for(var h=0,l;l=j[h];h++){if(l.className&&l.className.match(k)){g[p]=l;p++}}return g},checkHidden:function(d){if(d==null){return true}var c;while(d.parentNode){c=fleXenv.getStyle(d,"display");if(c=="none"){return true}d=d.parentNode}return false},getStyle:function(d,c){if(window.getComputedStyle){return window.getComputedStyle(d,null).getPropertyValue(c)}if(d.currentStyle){return d.currentStyle[fleXenv.camelConv(c)]}return false},catchFastInit:window.setInterval(function(){var b=document.getElementById("flexcroll-init");if(b!=null){fleXenv.initByClass();window.clearInterval(fleXenv.catchFastInit)}},100),putAway:function(d,c){d.parentNode.removeChild(d);d.style.display="none";c.appendChild(d)},addTrggr:function(e,d,f){if(!fleXenv.addChckTrggr(e,d,f)&&e.attachEvent){e.attachEvent("on"+d,f)}},addChckTrggr:function(e,d,f){if(e.addEventListener){e.addEventListener(d,f,false);fleXenv.w3events=true;window.addEventListener("unload",function(){fleXenv.remTrggr(e,d,f)},false);return true}else{return false}},remTrggr:function(e,d,f){if(!fleXenv.remChckTrggr(e,d,f)&&e.detachEvent){e.detachEvent("on"+d,f)}},remChckTrggr:function(e,d,f){if(e.removeEventListener){e.removeEventListener(d,f,false);return true}else{return false}}};function CSBfleXcroll(b){fleXenv.fleXcrollMain(b)}fleXenv.fleXcrollInit();