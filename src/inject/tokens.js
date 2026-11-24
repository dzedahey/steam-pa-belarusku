(function(){if(window.__beTok)return;window.__beTok=1;
var S=window.__beStats={files:0,applied:0,skipped:[]};
var F=String.fromCharCode,P=JSON.parse(`@@PACK@@`.split(F(0xE001)).join(F(92)).split(F(0xE000)).join(F(36)).split(F(0xE002)).join(F(96)));
S.total=Object.keys(P).length;
function h(s){var x=0x811c9dc5;for(var i=0;i<s.length;i++){x^=s.charCodeAt(i);x=Math.imul(x,0x01000193)>>>0;}return (x%2176782336).toString(36);}
var MK=["Generic_Close","Steam_Platform","WindowTitle_FriendsList","sdrpop_bl2"];
var HO=Object.prototype.hasOwnProperty;
function fix(o){S.files++;for(var k in o){if(!HO.call(P,k))continue;var v=o[k];if(typeof v!=="string")continue;var vs=P[k],hv=h(v),hit=null;
var hp=' '+hv+' ';for(var i=0;i<vs.length&&!hit;i++){if((' '+vs[i][1]+' ').indexOf(hp)>=0)hit=vs[i][0];}
if(hit!==null){o[k]=hit;S.applied++;}else{var mine=false;for(var j=0;j<vs.length;j++){if(vs[j][0]===v)mine=true;}if(!mine&&S.skipped.length<500)S.skipped.push(k);}}}
var OP=JSON.parse;
JSON.parse=function(t,r){var o=OP.call(JSON,t,r);try{if(o&&typeof o==="object"&&!Array.isArray(o)){for(var i=0;i<MK.length;i++){if(HO.call(o,MK[i])){fix(o);break;}}}}catch(err){}return o;};
var P2=JSON.parse(`@@PACK2@@`.split(F(0xE001)).join(F(92)).split(F(0xE000)).join(F(36)).split(F(0xE002)).join(F(96)));
var C2=Object.create(null),OG=Map.prototype.get;S.get=0;
Map.prototype.get=function(k){var v=OG.call(this,k);if(typeof v!=="string"||typeof k!=="string")return v;
try{var kk=k.charCodeAt(0)===35?k.slice(1):k;if(!HO.call(P2,kk))return v;var ck=kk+F(1)+v,c=C2[ck];if(c!==undefined)return c;
var vs=P2[kk],r=v,hv=h(v);for(var i=0;i<vs.length;i++){var x=vs[i];if(x[0]===v)break;if((' '+x[1]+' ').indexOf(' '+hv+' ')>=0){r=x[0];break;}}
C2[ck]=r;if(r!==v)S.get++;return r;}catch(e){return v;}};
})()
