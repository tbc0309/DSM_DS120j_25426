/* Copyright (c) 2020 Synology Inc. All rights reserved. */

Ext.ns("SYNO.Encryption");SYNO.Encryption.SecureRandom=(function(){function g(){this.i=0;this.j=0;this.S=[]}function l(s){var r,p,q;for(r=0;r<256;++r){this.S[r]=r}p=0;for(r=0;r<256;++r){p=(p+this.S[r]+s[r%s.length])&255;q=this.S[r];this.S[r]=this.S[p];this.S[p]=q}this.i=0;this.j=0}function d(){var p;this.i=(this.i+1)&255;this.j=(this.j+this.S[this.i])&255;p=this.S[this.i];this.S[this.i]=this.S[this.j];this.S[this.j]=p;return this.S[(p+this.S[this.i])&255]}g.prototype.init=l;g.prototype.next=d;function j(){return new g()}var m=256;var k;var b;var f;function h(p){b[f++]^=p&255;b[f++]^=(p>>8)&255;b[f++]^=(p>>16)&255;b[f++]^=(p>>24)&255;if(f>=m){f-=m}}function o(){h(new Date().getTime())}if(Ext.isEmpty(b)){b=[];f=0;var n;if(navigator.appName=="Netscape"&&navigator.appVersion<"5"&&window.crypto){var i=window.crypto.random(32);for(n=0;n<i.length;++n){b[f++]=i.charCodeAt(n)&255}}while(f<m){n=Math.floor(65536*Math.random());b[f++]=n>>>8;b[f++]=n&255}f=0;o()}function c(){if(Ext.isEmpty(k)){o();k=j();k.init(b);for(f=0;f<b.length;++f){b[f]=0}f=0}return k.next()}function e(q){var p;for(p=0;p<q.length;++p){q[p]=c()}}function a(){}a.prototype.nextBytes=e;a.rng_seed_time=o;return a})();Ext.ns("SYNO.Encryption");SYNO.Encryption.BigInteger=(function(){var G;var Y=244837814094590;var f=((Y&16777215)==15715070);function d(aa,Z,ab){if(!Ext.isEmpty(aa)){if("number"==typeof aa){this.fromNumber(aa,Z,ab)}else{if(Ext.isEmpty(Z)&&"string"!=typeof aa){this.fromString(aa,256)}else{this.fromString(aa,Z)}}}}function l(){return new d(null)}function K(ad,Z,aa,ac,af,ae){while(--ae>=0){var ab=Z*this[ad++]+aa[ac]+af;af=Math.floor(ab/67108864);aa[ac++]=ab&67108863}return af}function J(ad,ai,aj,ac,ag,Z){var af=ai&32767,ah=ai>>15;while(--Z>=0){var ab=this[ad]&32767;var ae=this[ad++]>>15;var aa=ah*ab+ae*af;ab=af*ab+((aa&32767)<<15)+aj[ac]+(ag&1073741823);ag=(ab>>>30)+(aa>>>15)+ah*ae+(ag>>>30);aj[ac++]=ab&1073741823}return ag}function I(ad,ai,aj,ac,ag,Z){var af=ai&16383,ah=ai>>14;while(--Z>=0){var ab=this[ad]&16383;var ae=this[ad++]>>14;var aa=ah*ab+ae*af;ab=af*ab+((aa&16383)<<14)+aj[ac]+ag;ag=(ab>>28)+(aa>>14)+ah*ae;aj[ac++]=ab&268435455}return ag}if(f&&(navigator.appName=="Microsoft Internet Explorer")){d.prototype.am=J;G=30}else{if(f&&(navigator.appName!="Netscape")){d.prototype.am=K;G=26}else{d.prototype.am=I;G=28}}d.prototype.DB=G;d.prototype.DM=((1<<G)-1);d.prototype.DV=(1<<G);var m=52;d.prototype.FV=Math.pow(2,m);d.prototype.F1=m-G;d.prototype.F2=2*G-m;var t="0123456789abcdefghijklmnopqrstuvwxyz";var x=[];var D,o;D="0".charCodeAt(0);for(o=0;o<=9;++o){x[D++]=o}D="a".charCodeAt(0);for(o=10;o<36;++o){x[D++]=o}D="A".charCodeAt(0);for(o=10;o<36;++o){x[D++]=o}function w(Z){return t.charAt(Z)}function B(aa,Z){var ab=x[aa.charCodeAt(Z)];return(Ext.isEmpty(ab))?-1:ab}function n(aa){for(var Z=this.t-1;Z>=0;--Z){aa[Z]=this[Z]}aa.t=this.t;aa.s=this.s}function Q(Z){this.t=1;this.s=(Z<0)?-1:0;if(Z>0){this[0]=Z}else{if(Z<-1){this[0]=Z+DV}else{this.t=0}}}function b(Z){var aa=l();aa.fromInt(Z);return aa}function L(af,aa){var ac;if(aa==16){ac=4}else{if(aa==8){ac=3}else{if(aa==256){ac=8}else{if(aa==2){ac=1}else{if(aa==32){ac=5}else{if(aa==4){ac=2}else{this.fromRadix(af,aa);return}}}}}}this.t=0;this.s=0;var ae=af.length,ab=false,ad=0;while(--ae>=0){var Z=(ac==8)?af[ae]&255:B(af,ae);if(Z<0){if(af.charAt(ae)=="-"){ab=true}continue}ab=false;if(ad===0){this[this.t++]=Z}else{if(ad+ac>this.DB){this[this.t-1]|=(Z&((1<<(this.DB-ad))-1))<<ad;this[this.t++]=(Z>>(this.DB-ad))}else{this[this.t-1]|=Z<<ad}}ad+=ac;if(ad>=this.DB){ad-=this.DB}}if(ac==8&&(af[0]&128)!==0){this.s=-1;if(ad>0){this[this.t-1]|=((1<<(this.DB-ad))-1)<<ad}}this.clamp();if(ab){d.ZERO.subTo(this,this)}}function O(){var Z=this.s&this.DM;while(this.t>0&&this[this.t-1]==Z){--this.t}}function S(aa){if(this.s<0){return"-"+this.negate().toString(aa)}var ab;if(aa==16){ab=4}else{if(aa==8){ab=3}else{if(aa==2){ab=1}else{if(aa==32){ab=5}else{if(aa==4){ab=2}else{return this.toRadix(aa)}}}}}var ad=(1<<ab)-1,ag,Z=false,ae="",ac=this.t;var af=this.DB-(ac*this.DB)%ab;if(ac-->0){if(af<this.DB&&(ag=this[ac]>>af)>0){Z=true;ae=w(ag)}while(ac>=0){if(af<ab){ag=(this[ac]&((1<<af)-1))<<(ab-af);ag|=this[--ac]>>(af+=this.DB-ab)}else{ag=(this[ac]>>(af-=ab))&ad;if(af<=0){af+=this.DB;--ac}}if(ag>0){Z=true}if(Z){ae+=w(ag)}}}return Z?ae:"0"}function M(){var Z=l();d.ZERO.subTo(this,Z);return Z}function F(){return(this.s<0)?this.negate():this}function U(Z){var ab=this.s-Z.s;if(ab!==0){return ab}var aa=this.t;ab=aa-Z.t;if(ab!==0){return ab}while(--aa>=0){if((ab=this[aa]-Z[aa])!==0){return ab}}return 0}function T(Z){var ab=1,aa;if((aa=Z>>>16)!==0){Z=aa;ab+=16}if((aa=Z>>8)!==0){Z=aa;ab+=8}if((aa=Z>>4)!==0){Z=aa;ab+=4}if((aa=Z>>2)!==0){Z=aa;ab+=2}if((aa=Z>>1)!==0){Z=aa;ab+=1}return ab}function g(){if(this.t<=0){return 0}return this.DB*(this.t-1)+T(this[this.t-1]^(this.s&this.DM))}function a(ab,aa){var Z;for(Z=this.t-1;Z>=0;--Z){aa[Z+ab]=this[Z]}for(Z=ab-1;Z>=0;--Z){aa[Z]=0}aa.t=this.t+ab;aa.s=this.s}function y(ab,aa){for(var Z=ab;Z<this.t;++Z){aa[Z-ab]=this[Z]}aa.t=Math.max(this.t-ab,0);aa.s=this.s}function s(ag,ac){var aa=ag%this.DB;var Z=this.DB-aa;var ae=(1<<Z)-1;var ad=Math.floor(ag/this.DB),af=(this.s<<aa)&this.DM,ab;for(ab=this.t-1;ab>=0;--ab){ac[ab+ad+1]=(this[ab]>>Z)|af;af=(this[ab]&ae)<<aa}for(ab=ad-1;ab>=0;--ab){ac[ab]=0}ac[ad]=af;ac.t=this.t+ad+1;ac.s=this.s;ac.clamp()}function P(af,ac){ac.s=this.s;var ad=Math.floor(af/this.DB);if(ad>=this.t){ac.t=0;return}var aa=af%this.DB;var Z=this.DB-aa;var ae=(1<<aa)-1;ac[0]=this[ad]>>aa;for(var ab=ad+1;ab<this.t;++ab){ac[ab-ad-1]|=(this[ab]&ae)<<Z;ac[ab-ad]=this[ab]>>aa}if(aa>0){ac[this.t-ad-1]|=(this.s&ae)<<Z}ac.t=this.t-ad;ac.clamp()}function h(aa,ac){var ab=0,ad=0,Z=Math.min(aa.t,this.t);while(ab<Z){ad+=this[ab]-aa[ab];ac[ab++]=ad&this.DM;ad>>=this.DB}if(aa.t<this.t){ad-=aa.s;while(ab<this.t){ad+=this[ab];ac[ab++]=ad&this.DM;ad>>=this.DB}ad+=this.s}else{ad+=this.s;while(ab<aa.t){ad-=aa[ab];ac[ab++]=ad&this.DM;ad>>=this.DB}ad-=aa.s}ac.s=(ad<0)?-1:0;if(ad<-1){ac[ab++]=this.DV+ad}else{if(ad>0){ac[ab++]=ad}}ac.t=ab;ac.clamp()}function N(aa,ac){var Z=this.abs(),ad=aa.abs();var ab=Z.t;ac.t=ab+ad.t;while(--ab>=0){ac[ab]=0}for(ab=0;ab<ad.t;++ab){ac[ab+Z.t]=Z.am(0,ad[ab],ac,ab,0,Z.t)}ac.s=0;ac.clamp();if(this.s!=aa.s){d.ZERO.subTo(ac,ac)}}function z(ab){var aa,Z=this.abs();aa=ab.t=2*Z.t;while(--aa>=0){ab[aa]=0}for(aa=0;aa<Z.t-1;++aa){var ac=Z.am(aa,Z[aa],ab,2*aa,0,1);if((ab[aa+Z.t]+=Z.am(aa+1,2*Z[aa],ab,2*aa+1,ac,Z.t-aa-1))>=Z.DV){ab[aa+Z.t]-=Z.DV;ab[aa+Z.t+1]=1}}if(ab.t>0){ab[ab.t-1]+=Z.am(aa,Z[aa],ab,2*aa,0,1)}ab.s=0;ab.clamp()}function H(ai,af,ae){var ao=ai.abs();if(ao.t<=0){return}var ag=this.abs();if(ag.t<ao.t){if(!Ext.isEmpty(af)){af.fromInt(0)}if(!Ext.isEmpty(ae)){this.copyTo(ae)}return}if(Ext.isEmpty(ae)){ae=l()}var ac=l(),Z=this.s,ah=ai.s;var an=this.DB-T(ao[ao.t-1]);if(an>0){ao.lShiftTo(an,ac);ag.lShiftTo(an,ae)}else{ao.copyTo(ac);ag.copyTo(ae)}var ak=ac.t;var aa=ac[ak-1];if(aa===0){return}var aj=aa*(1<<this.F1)+((ak>1)?ac[ak-2]>>this.F2:0);var ar=this.FV/aj,aq=(1<<this.F1)/aj,ap=1<<this.F2;var am=ae.t,al=am-ak,ad=(Ext.isEmpty(af))?l():af;ac.dlShiftTo(al,ad);if(ae.compareTo(ad)>=0){ae[ae.t++]=1;ae.subTo(ad,ae)}d.ONE.dlShiftTo(ak,ad);ad.subTo(ac,ac);while(ac.t<ak){ac[ac.t++]=0}while(--al>=0){var ab=(ae[--am]==aa)?this.DM:Math.floor(ae[am]*ar+(ae[am-1]+ap)*aq);if((ae[am]+=ac.am(0,ab,ae,al,0,ak))<ab){ac.dlShiftTo(al,ad);ae.subTo(ad,ae);while(ae[am]<--ab){ae.subTo(ad,ae)}}}if(!Ext.isEmpty(af)){ae.drShiftTo(ak,af);if(Z!=ah){d.ZERO.subTo(af,af)}}ae.t=ak;ae.clamp();if(an>0){ae.rShiftTo(an,ae)}if(Z<0){d.ZERO.subTo(ae,ae)}}function j(Z){var aa=l();this.abs().divRemTo(Z,null,aa);if(this.s<0&&aa.compareTo(d.ZERO)>0){Z.subTo(aa,aa)}return aa}function V(Z){this.m=Z}function v(Z){if(Z.s<0||Z.compareTo(this.m)>=0){return Z.mod(this.m)}else{return Z}}function p(Z){return Z}function c(Z){Z.divRemTo(this.m,null,Z)}function W(Z,ab,aa){Z.multiplyTo(ab,aa);this.reduce(aa)}function X(Z,aa){Z.squareTo(aa);this.reduce(aa)}V.prototype.convert=v;V.prototype.revert=p;V.prototype.reduce=c;V.prototype.mulTo=W;V.prototype.sqrTo=X;function r(){if(this.t<1){return 0}var Z=this[0];if((Z&1)===0){return 0}var aa=Z&3;aa=(aa*(2-(Z&15)*aa))&15;aa=(aa*(2-(Z&255)*aa))&255;aa=(aa*(2-(((Z&65535)*aa)&65535)))&65535;aa=(aa*(2-Z*aa%this.DV))%this.DV;return(aa>0)?this.DV-aa:-aa}function A(Z){this.m=Z;this.mp=Z.invDigit();this.mpl=this.mp&32767;this.mph=this.mp>>15;this.um=(1<<(Z.DB-15))-1;this.mt2=2*Z.t}function q(Z){var aa=l();Z.abs().dlShiftTo(this.m.t,aa);aa.divRemTo(this.m,null,aa);if(Z.s<0&&aa.compareTo(d.ZERO)>0){this.m.subTo(aa,aa)}return aa}function R(Z){var aa=l();Z.copyTo(aa);this.reduce(aa);return aa}function E(Z){while(Z.t<=this.mt2){Z[Z.t++]=0}for(var ab=0;ab<this.m.t;++ab){var aa=Z[ab]&32767;var ac=(aa*this.mpl+(((aa*this.mph+(Z[ab]>>15)*this.mpl)&this.um)<<15))&Z.DM;aa=ab+this.m.t;Z[aa]+=this.m.am(0,ac,Z,ab,0,this.m.t);while(Z[aa]>=Z.DV){Z[aa]-=Z.DV;Z[++aa]++}}Z.clamp();Z.drShiftTo(this.m.t,Z);if(Z.compareTo(this.m)>=0){Z.subTo(this.m,Z)}}function k(Z,aa){Z.squareTo(aa);this.reduce(aa)}function i(Z,ab,aa){Z.multiplyTo(ab,aa);this.reduce(aa)}A.prototype.convert=q;A.prototype.revert=R;A.prototype.reduce=E;A.prototype.mulTo=i;A.prototype.sqrTo=k;function u(){return 0===((this.t>0)?(this[0]&1):this.s)}function e(ae,af){if(ae>4294967295||ae<1){return d.ONE}var ad=l(),Z=l(),ac=af.convert(this),ab=T(ae)-1;ac.copyTo(ad);while(--ab>=0){af.sqrTo(ad,Z);if((ae&(1<<ab))>0){af.mulTo(Z,ac,ad)}else{var aa=ad;ad=Z;Z=aa}}return af.revert(ad)}function C(aa,Z){var ab;if(aa<256||Z.isEven()){ab=new V(Z)}else{ab=new A(Z)}return this.exp(aa,ab)}d.prototype.copyTo=n;d.prototype.fromInt=Q;d.prototype.fromString=L;d.prototype.clamp=O;d.prototype.dlShiftTo=a;d.prototype.drShiftTo=y;d.prototype.lShiftTo=s;d.prototype.rShiftTo=P;d.prototype.subTo=h;d.prototype.multiplyTo=N;d.prototype.squareTo=z;d.prototype.divRemTo=H;d.prototype.invDigit=r;d.prototype.isEven=u;d.prototype.exp=e;d.prototype.toString=S;d.prototype.negate=M;d.prototype.abs=F;d.prototype.compareTo=U;d.prototype.bitLength=g;d.prototype.mod=j;d.prototype.modPowInt=C;d.ZERO=b(0);d.ONE=b(1);return d})();Ext.ns("SYNO.Encryption");SYNO.Encryption.CipherKey="";SYNO.Encryption.RSAModulus="";SYNO.Encryption.CipherToken="";SYNO.Encryption.TimeBias=0;SYNO.Encryption.RandomUint8=function(a){if(!Ext.getClassByName("Uint8Array")){return Math.floor(Math.random()*(a+1))}var b=new Uint8Array(1);if(!b||!(b.buffer instanceof ArrayBuffer)||undefined===b.byteLength){return Math.floor(Math.random()*(a+1))}if(!Ext.isIE11&&Ext.getClassByName("crypto.getRandomValues")){window.crypto.getRandomValues(b)}else{if(Ext.isIE11&&Ext.getClassByName("msCrypto.getRandomValues")){window.msCrypto.getRandomValues(b)}else{return Math.floor(Math.random()*(a+1))}}var c=a+1;var d=256;if(b[0]>=Math.floor(d/c)*c){return SYNO.Encryption.RandomUint8(a)}return(b[0]%c)};SYNO.Encryption.GenRandomKey=function(){var a="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()_+-/".split("");return function(b){var c=[];while(b>0){c.push(a[SYNO.Encryption.RandomUint8(a.length-1)]);b--}return c.join("")}}();SYNO.Encryption.EncryptParam=function(g){var e,c,b,d={},a={},f=SYNO.Encryption.GenRandomKey(501);if(!SYNO.Encryption.CipherKey||!SYNO.Encryption.RSAModulus||!SYNO.Encryption.CipherToken){return g}e=new SYNO.Encryption.RSA();e.setPublic(SYNO.Encryption.RSAModulus,"10001");d[SYNO.Encryption.CipherToken]=Math.floor(+new Date()/1000)+SYNO.Encryption.TimeBias;c=e.encrypt(f);if(!c){return g}Ext.apply(d,g);b=SYNO.Encryption.AES.encrypt(Ext.urlEncode(d),f).toString();if(!b){return g}a[SYNO.Encryption.CipherKey]=JSON.stringify({rsa:SYNO.Encryption.Base64.hex2b64(c),aes:b});return a};Ext.ns("SYNO.Encryption");SYNO.Encryption.RSA=(function(){function b(h,g){return new SYNO.Encryption.BigInteger(h,g)}function a(k,o){if(o<k.length+11){return null}var m=[];var j=k.length-1;while(j>=0&&o>0){var l=k.charCodeAt(j--);if(l<128){m[--o]=l}else{if((l>127)&&(l<2048)){m[--o]=(l&63)|128;m[--o]=(l>>6)|192}else{m[--o]=(l&63)|128;m[--o]=((l>>6)&63)|128;m[--o]=(l>>12)|224}}}m[--o]=0;var h=new SYNO.Encryption.SecureRandom();var g=[];while(o>2){g[0]=0;while(g[0]===0){h.nextBytes(g)}m[--o]=g[0]}m[--o]=2;m[--o]=0;return new SYNO.Encryption.BigInteger(m)}function d(){this.n=null;this.e=0;this.d=null;this.p=null;this.q=null;this.dmp1=null;this.dmq1=null;this.coeff=null}function e(h,g){if(!Ext.isEmpty(h)&&!Ext.isEmpty(g)&&h.length>0&&g.length>0){this.n=b(h,16);this.e=parseInt(g,16)}else{}}function f(g){return g.modPowInt(this.e,this.n)}function c(j){var g=a(j,(this.n.bitLength()+7)>>3);if(Ext.isEmpty(g)){return null}var k=this.doPublic(g);if(Ext.isEmpty(k)){return null}var i=k.toString(16);if((i.length&1)===0){return i}else{return"0"+i}}d.prototype.doPublic=f;d.prototype.setPublic=e;d.prototype.encrypt=c;return d})();Ext.ns("SYNO.Encryption");SYNO.Encryption.Base64=(function(){var b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";var a="=";return{hex2b64:function(f){var e;var g;var d="";for(e=0;e+3<=f.length;e+=3){g=parseInt(f.substring(e,e+3),16);d+=b.charAt(g>>6)+b.charAt(g&63)}if(e+1==f.length){g=parseInt(f.substring(e,e+1),16);d+=b.charAt(g<<2)}else{if(e+2==f.length){g=parseInt(f.substring(e,e+2),16);d+=b.charAt(g>>2)+b.charAt((g&3)<<4)}}while((d.length&3)>0){d+=a}return d},b64tohex:function(h){var f="";var g;var d=0;var e;for(g=0;g<h.length;++g){if(h.charAt(g)==a){break}var c=b.indexOf(h.charAt(g));if(c<0){continue}if(d===0){f+=int2char(c>>2);e=c&3;d=1}else{if(d==1){f+=int2char((e<<2)|(c>>4));e=c&15;d=2}else{if(d==2){f+=int2char(e);f+=int2char(c>>2);e=c&3;d=3}else{f+=int2char((e<<2)|(c>>4));f+=int2char(c&15);d=0}}}}if(d==1){f+=int2char(e<<2)}return f},b64toBA:function(f){var e=this.b64tohex(f);var d;var c=[];for(d=0;2*d<e.length;++d){c[d]=parseInt(e.substring(2*d,2*d+2),16)}return c}}})();Ext.ns("SYNO.Encryption");SYNO.Encryption.AES=(function(){var a=function(y,f){var i={},h=i.lib={},A=function(){},z=h.Base={extend:function(b){A.prototype=this;var d=new A;b&&d.mixIn(b);d.hasOwnProperty("init")||(d.init=function(){d.$super.init.apply(this,arguments)});d.init.prototype=d;d.$super=this;return d},create:function(){var b=this.extend();b.init.apply(b,arguments);return b},init:function(){},mixIn:function(b){for(var d in b){b.hasOwnProperty(d)&&(this[d]=b[d])}b.hasOwnProperty("toString")&&(this.toString=b.toString)},clone:function(){return this.init.prototype.extend(this)}},c=h.WordArray=z.extend({init:function(b,d){b=this.words=b||[];this.sigBytes=d!=f?d:4*b.length},toString:function(b){return(b||o).stringify(this)},concat:function(b){var p=this.words,n=b.words,l=this.sigBytes;b=b.sigBytes;this.clamp();if(l%4){for(var d=0;d<b;d++){p[l+d>>>2]|=(n[d>>>2]>>>24-8*(d%4)&255)<<24-8*((l+d)%4)}}else{if(65535<n.length){for(d=0;d<b;d+=4){p[l+d>>>2]=n[d>>>2]}}else{p.push.apply(p,n)}}this.sigBytes+=b;return this},clamp:function(){var b=this.words,d=this.sigBytes;b[d>>>2]&=4294967295<<32-8*(d%4);b.length=y.ceil(d/4)},clone:function(){var b=z.clone.call(this);b.words=this.words.slice(0);return b},random:function(b){for(var l=[],d=0;d<b;d+=4){l.push(4294967296*y.random()|0)}return new c.init(l,b)}}),m=i.enc={},o=m.Hex={stringify:function(b){var p=b.words;b=b.sigBytes;for(var n=[],l=0;l<b;l++){var d=p[l>>>2]>>>24-8*(l%4)&255;n.push((d>>>4).toString(16));n.push((d&15).toString(16))}return n.join("")},parse:function(b){for(var n=b.length,l=[],d=0;d<n;d+=2){l[d>>>3]|=parseInt(b.substr(d,2),16)<<24-4*(d%8)}return new c.init(l,n/2)}},j=m.Latin1={stringify:function(b){var n=b.words;b=b.sigBytes;for(var l=[],d=0;d<b;d++){l.push(String.fromCharCode(n[d>>>2]>>>24-8*(d%4)&255))}return l.join("")},parse:function(b){for(var n=b.length,l=[],d=0;d<n;d++){l[d>>>2]|=(b.charCodeAt(d)&255)<<24-8*(d%4)}return new c.init(l,n)}},k=m.Utf8={stringify:function(b){try{return decodeURIComponent(escape(j.stringify(b)))}catch(d){throw Error("Malformed UTF-8 data")}},parse:function(b){return j.parse(unescape(encodeURIComponent(b)))}},e=h.BufferedBlockAlgorithm=z.extend({reset:function(){this._data=new c.init;this._nDataBytes=0},_append:function(b){"string"==typeof b&&(b=k.parse(b));this._data.concat(b);this._nDataBytes+=b.sigBytes},_process:function(l){var t=this._data,s=t.words,p=t.sigBytes,n=this.blockSize,d=p/(4*n),d=l?y.ceil(d):y.max((d|0)-this._minBufferSize,0);l=d*n;p=y.min(4*l,p);if(l){for(var r=0;r<l;r+=n){this._doProcessBlock(s,r)}r=s.splice(0,l);t.sigBytes-=p}return new c.init(r,p)},clone:function(){var b=z.clone.call(this);b._data=this._data.clone();return b},_minBufferSize:0});h.Hasher=e.extend({cfg:z.extend(),init:function(b){this.cfg=this.cfg.extend(b);this.reset()},reset:function(){e.reset.call(this);this._doReset()},update:function(b){this._append(b);this._process();return this},finalize:function(b){b&&this._append(b);return this._doFinalize()},blockSize:16,_createHelper:function(b){return function(d,l){return(new b.init(l)).finalize(d)}},_createHmacHelper:function(b){return function(d,l){return(new g.HMAC.init(b,l)).finalize(d)}}});var g=i.algo={};return i}(Math);(function(){var b=a,c=b.lib.WordArray;b.enc.Base64={stringify:function(k){var f=k.words,j=k.sigBytes,h=this._map;k.clamp();k=[];for(var i=0;i<j;i+=3){for(var e=(f[i>>>2]>>>24-8*(i%4)&255)<<16|(f[i+1>>>2]>>>24-8*((i+1)%4)&255)<<8|f[i+2>>>2]>>>24-8*((i+2)%4)&255,g=0;4>g&&i+0.75*g<j;g++){k.push(h.charAt(e>>>6*(3-g)&63))}}if(f=h.charAt(64)){for(;k.length%4;){k.push(f)}}return k.join("")},parse:function(m){var g=m.length,j=this._map,i=j.charAt(64);i&&(i=m.indexOf(i),-1!=i&&(g=i));for(var i=[],k=0,f=0;f<g;f++){if(f%4){var h=j.indexOf(m.charAt(f-1))<<2*(f%4),e=j.indexOf(m.charAt(f))>>>6-2*(f%4);i[k>>>2]|=(h|e)<<24-8*(k%4);k++}}return c.create(i,k)},_map:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="}})();(function(m){function e(d,t,l,s,r,q,p){d=d+(t&l|~t&s)+r+p;return(d<<q|d>>>32-q)+t}function g(d,t,l,s,r,q,p){d=d+(t&s|l&~s)+r+p;return(d<<q|d>>>32-q)+t}function f(d,t,l,s,r,q,p){d=d+(t^l^s)+r+p;return(d<<q|d>>>32-q)+t}function o(d,t,l,s,r,q,p){d=d+(l^(t|~s))+r+p;return(d<<q|d>>>32-q)+t}for(var n=a,c=n.lib,j=c.WordArray,k=c.Hasher,c=n.algo,h=[],i=0;64>i;i++){h[i]=4294967296*m.abs(m.sin(i+1))|0}c=c.MD5=k.extend({_doReset:function(){this._hash=new j.init([1732584193,4023233417,2562383102,271733878])},_doProcessBlock:function(K,M){for(var V=0;16>V;V++){var U=M+V,T=K[U];K[U]=(T<<8|T>>>24)&16711935|(T<<24|T>>>8)&4278255360}var V=this._hash.words,U=K[M+0],T=K[M+1],P=K[M+2],O=K[M+3],b=K[M+4],I=K[M+5],F=K[M+6],l=K[M+7],p=K[M+8],L=K[M+9],J=K[M+10],H=K[M+11],s=K[M+12],G=K[M+13],y=K[M+14],d=K[M+15],S=V[0],N=V[1],R=V[2],Q=V[3],S=e(S,N,R,Q,U,7,h[0]),Q=e(Q,S,N,R,T,12,h[1]),R=e(R,Q,S,N,P,17,h[2]),N=e(N,R,Q,S,O,22,h[3]),S=e(S,N,R,Q,b,7,h[4]),Q=e(Q,S,N,R,I,12,h[5]),R=e(R,Q,S,N,F,17,h[6]),N=e(N,R,Q,S,l,22,h[7]),S=e(S,N,R,Q,p,7,h[8]),Q=e(Q,S,N,R,L,12,h[9]),R=e(R,Q,S,N,J,17,h[10]),N=e(N,R,Q,S,H,22,h[11]),S=e(S,N,R,Q,s,7,h[12]),Q=e(Q,S,N,R,G,12,h[13]),R=e(R,Q,S,N,y,17,h[14]),N=e(N,R,Q,S,d,22,h[15]),S=g(S,N,R,Q,T,5,h[16]),Q=g(Q,S,N,R,F,9,h[17]),R=g(R,Q,S,N,H,14,h[18]),N=g(N,R,Q,S,U,20,h[19]),S=g(S,N,R,Q,I,5,h[20]),Q=g(Q,S,N,R,J,9,h[21]),R=g(R,Q,S,N,d,14,h[22]),N=g(N,R,Q,S,b,20,h[23]),S=g(S,N,R,Q,L,5,h[24]),Q=g(Q,S,N,R,y,9,h[25]),R=g(R,Q,S,N,O,14,h[26]),N=g(N,R,Q,S,p,20,h[27]),S=g(S,N,R,Q,G,5,h[28]),Q=g(Q,S,N,R,P,9,h[29]),R=g(R,Q,S,N,l,14,h[30]),N=g(N,R,Q,S,s,20,h[31]),S=f(S,N,R,Q,I,4,h[32]),Q=f(Q,S,N,R,p,11,h[33]),R=f(R,Q,S,N,H,16,h[34]),N=f(N,R,Q,S,y,23,h[35]),S=f(S,N,R,Q,T,4,h[36]),Q=f(Q,S,N,R,b,11,h[37]),R=f(R,Q,S,N,l,16,h[38]),N=f(N,R,Q,S,J,23,h[39]),S=f(S,N,R,Q,G,4,h[40]),Q=f(Q,S,N,R,U,11,h[41]),R=f(R,Q,S,N,O,16,h[42]),N=f(N,R,Q,S,F,23,h[43]),S=f(S,N,R,Q,L,4,h[44]),Q=f(Q,S,N,R,s,11,h[45]),R=f(R,Q,S,N,d,16,h[46]),N=f(N,R,Q,S,P,23,h[47]),S=o(S,N,R,Q,U,6,h[48]),Q=o(Q,S,N,R,l,10,h[49]),R=o(R,Q,S,N,y,15,h[50]),N=o(N,R,Q,S,I,21,h[51]),S=o(S,N,R,Q,s,6,h[52]),Q=o(Q,S,N,R,O,10,h[53]),R=o(R,Q,S,N,J,15,h[54]),N=o(N,R,Q,S,T,21,h[55]),S=o(S,N,R,Q,p,6,h[56]),Q=o(Q,S,N,R,d,10,h[57]),R=o(R,Q,S,N,F,15,h[58]),N=o(N,R,Q,S,G,21,h[59]),S=o(S,N,R,Q,b,6,h[60]),Q=o(Q,S,N,R,H,10,h[61]),R=o(R,Q,S,N,P,15,h[62]),N=o(N,R,Q,S,L,21,h[63]);V[0]=V[0]+S|0;V[1]=V[1]+N|0;V[2]=V[2]+R|0;V[3]=V[3]+Q|0},_doFinalize:function(){var d=this._data,r=d.words,l=8*this._nDataBytes,q=8*d.sigBytes;r[q>>>5]|=128<<24-q%32;var p=m.floor(l/4294967296);r[(q+64>>>9<<4)+15]=(p<<8|p>>>24)&16711935|(p<<24|p>>>8)&4278255360;r[(q+64>>>9<<4)+14]=(l<<8|l>>>24)&16711935|(l<<24|l>>>8)&4278255360;d.sigBytes=4*(r.length+1);this._process();d=this._hash;r=d.words;for(l=0;4>l;l++){q=r[l],r[l]=(q<<8|q>>>24)&16711935|(q<<24|q>>>8)&4278255360}return d},clone:function(){var d=k.clone.call(this);d._hash=this._hash.clone();return d}});n.MD5=k._createHelper(c);n.HmacMD5=k._createHmacHelper(c)})(Math);(function(){var c=a,f=c.lib,g=f.Base,b=f.WordArray,f=c.algo,e=f.EvpKDF=g.extend({cfg:g.extend({keySize:4,hasher:f.MD5,iterations:1}),init:function(h){this.cfg=this.cfg.extend(h)},compute:function(l,h){for(var j=this.cfg,v=j.hasher.create(),m=b.create(),t=m.words,i=j.keySize,j=j.iterations;t.length<i;){k&&v.update(k);var k=v.update(l).finalize(h);v.reset();for(var o=1;o<j;o++){k=v.finalize(k),v.reset()}m.concat(k)}m.sigBytes=4*i;return m}});c.EvpKDF=function(j,h,i){return e.create(i).compute(j,h)}})();a.lib.Cipher||function(B){var g=a,j=g.lib,i=j.Base,D=j.WordArray,C=j.BufferedBlockAlgorithm,e=g.enc.Base64,z=g.algo.EvpKDF,A=j.Cipher=C.extend({cfg:i.extend(),createEncryptor:function(c,b){return this.create(this._ENC_XFORM_MODE,c,b)},createDecryptor:function(c,b){return this.create(this._DEC_XFORM_MODE,c,b)},init:function(l,d,c){this.cfg=this.cfg.extend(c);this._xformMode=l;this._key=d;this.reset()},reset:function(){C.reset.call(this);this._doReset()},process:function(b){this._append(b);return this._process()},finalize:function(b){b&&this._append(b);return this._doFinalize()},keySize:4,ivSize:4,_ENC_XFORM_MODE:1,_DEC_XFORM_MODE:2,_createHelper:function(b){return{encrypt:function(c,l,n){return("string"==typeof l?k:o).encrypt(b,c,l,n)},decrypt:function(c,l,n){return("string"==typeof l?k:o).decrypt(b,c,l,n)}}}});j.StreamCipher=A.extend({_doFinalize:function(){return this._process(!0)},blockSize:1});var m=g.mode={},y=function(p,n,l){var r=this._iv;r?this._iv=B:r=this._prevBlock;for(var q=0;q<l;q++){p[n+q]^=r[q]}},f=(j.BlockCipherMode=i.extend({createEncryptor:function(c,b){return this.Encryptor.create(c,b)},createDecryptor:function(c,b){return this.Decryptor.create(c,b)},init:function(c,b){this._cipher=c;this._iv=b}})).extend();f.Encryptor=f.extend({processBlock:function(n,l){var d=this._cipher,p=d.blockSize;y.call(this,n,l,p);d.encryptBlock(n,l);this._prevBlock=n.slice(l,l+p)}});f.Decryptor=f.extend({processBlock:function(p,n){var l=this._cipher,r=l.blockSize,q=p.slice(n,n+r);l.decryptBlock(p,n);y.call(this,p,n,r);this._prevBlock=q}});m=m.CBC=f;f=(g.pad={}).Pkcs7={pad:function(r,p){for(var u=4*p,u=u-r.sigBytes%u,s=u<<24|u<<16|u<<8|u,q=[],t=0;t<u;t+=4){q.push(s)}u=D.create(q,u);r.concat(u)},unpad:function(b){b.sigBytes-=b.words[b.sigBytes-1>>>2]&255}};j.BlockCipher=A.extend({cfg:A.cfg.extend({mode:m,padding:f}),reset:function(){A.reset.call(this);var l=this.cfg,d=l.iv,l=l.mode;if(this._xformMode==this._ENC_XFORM_MODE){var n=l.createEncryptor}else{n=l.createDecryptor,this._minBufferSize=1}this._mode=n.call(l,this,d&&d.words)},_doProcessBlock:function(d,c){this._mode.processBlock(d,c)},_doFinalize:function(){var d=this.cfg.padding;if(this._xformMode==this._ENC_XFORM_MODE){d.pad(this._data,this.blockSize);var c=this._process(!0)}else{c=this._process(!0),d.unpad(c)}return c},blockSize:4});var h=j.CipherParams=i.extend({init:function(b){this.mixIn(b)},toString:function(b){return(b||this.formatter).stringify(this)}}),m=(g.format={}).OpenSSL={stringify:function(d){var c=d.ciphertext;d=d.salt;return(d?D.create([1398893684,1701076831]).concat(d).concat(c):c).toString(e)},parse:function(l){l=e.parse(l);var d=l.words;if(1398893684==d[0]&&1701076831==d[1]){var n=D.create(d.slice(2,4));d.splice(0,4);l.sigBytes-=16}return h.create({ciphertext:l,salt:n})}},o=j.SerializableCipher=i.extend({cfg:i.extend({format:m}),encrypt:function(q,n,s,r){r=this.cfg.extend(r);var p=q.createEncryptor(s,r);n=p.finalize(n);p=p.cfg;return h.create({ciphertext:n,key:s,iv:p.iv,algorithm:q,mode:p.mode,padding:p.padding,blockSize:q.blockSize,formatter:r.format})},decrypt:function(n,l,q,p){p=this.cfg.extend(p);l=this._parse(l,p.format);return n.createDecryptor(q,p).finalize(l.ciphertext)},_parse:function(d,c){return"string"==typeof d?c.parse(d,this):d}}),g=(g.kdf={}).OpenSSL={execute:function(n,l,q,p){p||(p=D.random(8));n=z.create({keySize:l+q}).compute(n,p);q=D.create(n.words.slice(l),4*q);n.sigBytes=4*l;return h.create({key:n,iv:q,salt:p})}},k=j.PasswordBasedCipher=o.extend({cfg:o.cfg.extend({kdf:g}),encrypt:function(n,r,q,p){p=this.cfg.extend(p);q=p.kdf.execute(q,n.keySize,n.ivSize);p.iv=q.iv;n=o.encrypt.call(this,n,r,q.key,p);n.mixIn(q);return n},decrypt:function(n,r,q,p){p=this.cfg.extend(p);r=this._parse(r,p.format);q=p.kdf.execute(q,n.keySize,n.ivSize,r.salt);p.iv=q.iv;return o.decrypt.call(this,n,r,q.key,p)}})}();(function(){for(var C=a,K=C.lib.BlockCipher,Q=C.algo,M=[],E=[],D=[],I=[],m=[],A=[],S=[],h=[],J=[],L=[],T=[],R=0;256>R;R++){T[R]=128>R?R<<1:R<<1^283}for(var P=0,O=0,R=0;256>R;R++){var N=O^O<<1^O<<2^O<<3^O<<4,N=N>>>8^N&255^99;M[P]=N;E[N]=P;var f=T[P],B=T[f],o=T[B],g=257*T[N]^16843008*N;D[P]=g<<24|g>>>8;I[P]=g<<16|g>>>16;m[P]=g<<8|g>>>24;A[P]=g;g=16843009*o^65537*B^257*f^16843008*P;S[N]=g<<24|g>>>8;h[N]=g<<16|g>>>16;J[N]=g<<8|g>>>24;L[N]=g;P?(P=f^T[T[T[o^f]]],O^=T[T[O]]):P=O=1}var i=[0,1,2,4,8,16,32,64,128,27,54],Q=Q.AES=K.extend({_doReset:function(){for(var b=this._key,r=b.words,q=b.sigBytes/4,b=4*((this._nRounds=q+6)+1),p=this._keySchedule=[],n=0;n<b;n++){if(n<q){p[n]=r[n]}else{var l=p[n-1];n%q?6<q&&4==n%q&&(l=M[l>>>24]<<24|M[l>>>16&255]<<16|M[l>>>8&255]<<8|M[l&255]):(l=l<<8|l>>>24,l=M[l>>>24]<<24|M[l>>>16&255]<<16|M[l>>>8&255]<<8|M[l&255],l^=i[n/q|0]<<24);p[n]=p[n-q]^l}}r=this._invKeySchedule=[];for(q=0;q<b;q++){n=b-q,l=q%4?p[n]:p[n-4],r[q]=4>q||4>=n?l:S[M[l>>>24]]^h[M[l>>>16&255]]^J[M[l>>>8&255]]^L[M[l&255]]}},encryptBlock:function(d,c){this._doCryptBlock(d,c,this._keySchedule,D,I,m,A,M)},decryptBlock:function(b,j){var e=b[j+1];b[j+1]=b[j+3];b[j+3]=e;this._doCryptBlock(b,j,this._invKeySchedule,S,h,J,L,E);e=b[j+1];b[j+1]=b[j+3];b[j+3]=e},_doCryptBlock:function(ac,ab,aa,Z,Y,U,G,X){for(var F=this._nRounds,W=ac[ab]^aa[0],V=ac[ab+1]^aa[1],H=ac[ab+2]^aa[2],z=ac[ab+3]^aa[3],y=4,w=1;w<F;w++){var x=Z[W>>>24]^Y[V>>>16&255]^U[H>>>8&255]^G[z&255]^aa[y++],v=Z[V>>>24]^Y[H>>>16&255]^U[z>>>8&255]^G[W&255]^aa[y++],u=Z[H>>>24]^Y[z>>>16&255]^U[W>>>8&255]^G[V&255]^aa[y++],z=Z[z>>>24]^Y[W>>>16&255]^U[V>>>8&255]^G[H&255]^aa[y++],W=x,V=v,H=u}x=(X[W>>>24]<<24|X[V>>>16&255]<<16|X[H>>>8&255]<<8|X[z&255])^aa[y++];v=(X[V>>>24]<<24|X[H>>>16&255]<<16|X[z>>>8&255]<<8|X[W&255])^aa[y++];u=(X[H>>>24]<<24|X[z>>>16&255]<<16|X[W>>>8&255]<<8|X[V&255])^aa[y++];z=(X[z>>>24]<<24|X[W>>>16&255]<<16|X[V>>>8&255]<<8|X[H&255])^aa[y++];ac[ab]=x;ac[ab+1]=v;ac[ab+2]=u;ac[ab+3]=z},keySize:8});C.AES=K._createHelper(Q)})();return a.AES})();