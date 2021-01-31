/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.Utils.canvas.Circle",{extend:"Ext.BoxComponent",circleCls:"syno-ux-circle-canvas",circleLabelCls:"syno-ux-circle-canvas-label",constructor:function(a){var b=this;a=a||{};Ext.applyIf(a,{radius:32,lineWidth:10,fallbackColor:"#1792F2",fontColor:"#0086E6",canvasConfig:{height:64,width:64}});b.callParent(arguments)},onRender:function(c,b){var e=this,d=e.canvasConfig.width,a=e.canvasConfig.height;var f=function(g){return Ext.isNumber(g)?g:64};e.callParent(arguments);e.canvas=e.el.createChild({"class":e.circleCls,tag:"canvas",style:String.format("width: {0}px; height: {1}px;",f(d),f(a))});e.label=e.el.createChild({tag:"div","class":e.circleLabelCls})},getRatio:function(a){if(Ext.isNumber(this.ratio)){return this.ratio}this.ratio=SYNO.SDS.Utils.HiDPI.getRatio(a);return this.ratio},clearCanvas:function(b){var e=this,d=e.getRatio(b),c=e.lineWidth*d,a=(e.radius-e.lineWidth/2)*d;b.clearRect(-c,-c,a*2+c*2,a*2+c*2);b.setTransform(1,0,0,1,0,0)},updateLabel:function(b,d){var c=this,a="<span>{0}</span>{1}";c.label.setStyle({color:c.fontColor});c.label.update(String.format(a,b,d||""))},getCanvas:function(){var a=this;if(Ext.isIE9m&&!Ext.isIE9&&window.G_vmlCanvasManager){try{window.G_vmlCanvasManager.initElement(a.canvas.dom)}catch(b){window.G_vmlCanvasManager.initElement(a.canvas.dom)}}return a.canvas.dom},setCanvasSize:function(c,b,e){var f=this,d=f.canvasConfig.width,a=f.canvasConfig.height;c.width=d*e;c.height=a*e;b.scale(e,e)},getCtx:function(){return this.ctx},innerDraw:function(){var f=this,e=f.getCanvas(),b=e.getContext("2d"),d=f.getRatio(b),c=f.lineWidth*d,a=(f.radius-f.lineWidth/2)*d;f.setCanvasSize(e,b,d);f.clearCanvas(b);if(Ext.isDefined(f.rotateAngle)){b.translate((f.canvasConfig.width*d)/2,(f.canvasConfig.width*d)/2);b.rotate(f.rotateAngle*Math.PI/180);b.translate(-((f.canvasConfig.width*d)/2),-((f.canvasConfig.width*d)/2))}b.translate(c/2,c/2);b.lineWidth=c;b.save();f.ctx=b;b.beginPath();b.rect(-c,-c,a*2+c*2,a*2+c*2);b.clip();if(Ext.isDefined(f.fillColor)){b.strokeStyle=f.fillColor;b.beginPath();b.arc(a*1,a*1,a*1,Math.PI*0,Math.PI*2,true);b.stroke();b.restore()}}});Ext.define("SYNO.SDS.Utils.canvas.circlegradient",{extend:"SYNO.SDS.Utils.canvas.Circle",circleCls:"syno-ux-circle-canvas-gradient",circleLabelCls:"syno-ux-circle-canvas-gradient-label",constructor:function(a){var b=this;a=a||{};Ext.applyIf(a,{lineWidth:a.gradientWidth,stopColor:"#2E7AE5",middleColor:"#1792F2",startColor:"#00AAFF",fillColor:"#CDD7E1"});b.callParent(arguments)},afterRender:function(){var a=this;a.callParent(arguments);if(a.value){a.draw(a.value)}},updateLabel:function(c,b){var a=this;c=Ext.isNumber(c)?Math.min(c,1):1;a.callParent([Math.ceil(c*100),(b||"%")]);a.label[(c===1)?"addClass":"removeClass"]("syno-ux-circle-canvas-gradient-label-maxValue")},getStartLinearGradient:function(c){var e=this,d=e.getRatio(c),b=(e.radius-e.lineWidth/2)*d,a=null;if(Ext.isIE9m&&!Ext.isIE9){a=e.fallbackColor}else{a=c.createLinearGradient(0,0,0,b*2);a.addColorStop(0,e.startColor);a.addColorStop(1,e.middleColor)}return a},getStopLinearGradient:function(c){var e=this,d=e.getRatio(c),b=(e.radius-e.lineWidth/2)*d,a=null;if(Ext.isIE9m&&!Ext.isIE9){a=e.fallbackColor}else{a=c.createLinearGradient(0,b*2,0,0);a.addColorStop(0,e.middleColor);a.addColorStop(1,e.stopColor)}return a},draw0To50Arc:function(i,e){var g=this,f=g.getRatio(i),c=(g.radius-g.lineWidth/2)*f,d=g.getStartLinearGradient(i),a=0,h=1.5,b=2.5;a=1.5+e*2;i.strokeStyle=d;i.beginPath();if(e===1){i.arc(c*1,c*1,c*1,Math.PI*b,Math.PI*h,true)}else{i.arc(c*1,c*1,c*1,Math.PI*(Math.min(a,b)),Math.PI*h,true)}i.stroke();i.restore()},draw50To100Arc:function(i,e){var g=this,f=g.getRatio(i),c=(g.radius-g.lineWidth/2)*f,d=g.getStopLinearGradient(i),a=0,h=2.5,b=3.5;a=1.5+e*2;i.strokeStyle=d;i.beginPath();if(e===1){i.arc(c*1,c*1,c*1,Math.PI*b,Math.PI*h,true)}else{i.arc(c*1,c*1,c*1,Math.PI*(Math.max(a,h)),Math.PI*h,true)}i.stroke();i.restore()},draw:function(c){var b=this,a;b.value=c;c=Ext.isNumber(c)?Math.min(c,1):1;b.updateLabel(c);b.innerDraw();a=b.getCtx("2d");b.draw0To50Arc(a,c);if(c>0.5){b.draw50To100Arc(a,c)}}});Ext.define("SYNO.SDS.Utils.canvas.IncrementalCircle",{extend:"SYNO.SDS.Utils.canvas.Circle",afterRender:function(){var b=this,f,d,c,a=0,e=0;b.callParent(arguments);b.innerDraw();if(b.labelTitle){b.updateLabel(b.labelTitle,b.labelUnit)}d=Ext.isObject(b.data)?b.data:{};for(f in d){if(d.hasOwnProperty(f)){c=d[f];if(!Ext.isObject(c)){continue}a+=(Ext.isNumber(c.value)?c.value:0)}}if(a===0){return}for(f in d){if(d.hasOwnProperty(f)){c=d[f];if(!Ext.isObject(c)){continue}b.drawWithRange(e/a,(e+c.value)/a,c.color);e+=(Ext.isNumber(c.value)?c.value:0)}}},drawWithRange:function(h,d,c){var f=this,b=f.getCtx(),e=f.getRatio(b),a=(f.radius-f.lineWidth/2)*e,g=1.5;d=(Ext.isNumber(d)?d:1).constrain(0,1);h=(Ext.isNumber(h)?h:0).constrain(0,1);b.strokeStyle=c||f.fallbackColor;b.beginPath();if((h===0)&&(d===1)){b.arc(a*1,a*1,a*1,Math.PI*2.5,Math.PI*g,true);b.arc(a*1,a*1,a*1,Math.PI*3.5,Math.PI*2.5,true)}else{if(d>h){b.arc(a*1,a*1,a*1,Math.PI*(1.5+d*2),Math.PI*(1.5+h*2),true)}else{b.arc(a*1,a*1,a*1,Math.PI*(1.5+h*2),Math.PI*(1.5+d*2),true)}}b.stroke();b.restore();return f}});Ext.define("SYNO.SDS.Utils.canvas.ColorCircleGradient",{extend:"SYNO.SDS.Utils.canvas.circlegradient",applyColorByPercent:function(a){a=Ext.isNumber(a)?Math.min(a,1):1;if(a>0.9){Ext.apply(this,{stopColor:"#E52E2E",middleColor:"#F25056",startColor:"#FF737E",fallbackColor:"#F25056",fontColor:"#FA4B4B"})}else{if(a>0.8){Ext.apply(this,{stopColor:"#F27900",middleColor:"#F99100",startColor:"#FFAA00",fallbackColor:"#F99100",fontColor:"#FF7F00"})}else{Ext.apply(this,{fallbackColor:"#1792F2",stopColor:"#2E7AE5",middleColor:"#1792F2",startColor:"#00AAFF",fontColor:"#0086E6"})}}},draw:function(b){var a=this;a.applyColorByPercent(b);a.callParent(arguments)}});