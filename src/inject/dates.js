(function(){if(window.__beDates)return;window.__beDates=1;
var M={"января":"студзеня","февраля":"лютага","марта":"сакавіка","апреля":"красавіка","мая":"мая","июня":"чэрвеня","июля":"ліпеня","августа":"жніўня","сентября":"верасня","октября":"кастрычніка","ноября":"лістапада","декабря":"снежня",
"январь":"студзень","февраль":"люты","март":"сакавік","апрель":"красавік","май":"май","июнь":"чэрвень","июль":"ліпень","август":"жнівень","сентябрь":"верасень","октябрь":"кастрычнік","ноябрь":"лістапад","декабрь":"снежань",
"янв.":"студз.","февр.":"лют.","мар.":"сак.","апр.":"крас.","июн.":"чэрв.","июл.":"ліп.","авг.":"жн.","сент.":"вер.","окт.":"кастр.","нояб.":"ліст.","дек.":"снеж.",
"понедельник":"панядзелак","вторник":"аўторак","среда":"серада","четверг":"чацвер","пятница":"пятніца","суббота":"субота","воскресенье":"нядзеля",
"пн":"пн","вт":"аў","ср":"ср","чт":"чц","пт":"пт","сб":"сб","вс":"нд"};
var RE=new RegExp("[А-Яа-яЁё]+[.]?","g");
function tr(s){if(typeof s!=="string")return s;return s.replace(RE,function(w){var l=w.toLowerCase(),b=M[l],dot="";
if(b===undefined&&l.charAt(l.length-1)==="."){b=M[l.slice(0,-1)];dot=".";}
if(b===undefined)return w;b=b+dot;if(w.charAt(0)!==l.charAt(0))b=b.charAt(0).toUpperCase()+b.slice(1);if(w===w.toUpperCase()&&w.length>1)b=b.toUpperCase();return b;});}
var O=Intl.DateTimeFormat,DP=Date.prototype;
/* Падмяняем мову толькі для выклікаў інтэрфейсу Steam: без мовы або з мовай самога кліента.
   Калі код яўна просіць іншую мову ці рэгіён (напрыклад en-CA), фармат не чапаем. */
var UI={"be":1,"be-by":1,"ru":1,"ru-ru":1,"uk":1,"uk-ua":1,"en":1,"en-us":1,"en-gb":1,"pl":1,"pl-pl":1};
function ui(a){if(a===undefined||a===null||a==="")return true;if(Array.isArray(a)){if(!a.length)return true;a=a[0];}
if(typeof a!=="string")return false;return UI[a.toLowerCase()]===1;}
/* Фармуем па-руску і замяняем назвы беларускімі: уласныя скарачэнні ICU для «be» (жні, 30.08.26)
   горшыя і адрозніваюцца ад тых, што ўжо паказваюць старонкі крамы і супольнасці. */
var L="ru-RU";
["toLocaleDateString","toLocaleTimeString","toLocaleString"].forEach(function(n){var o=DP[n];DP[n]=function(a,opt){if(!ui(a))return o.call(this,a,opt);return tr(o.call(this,L,opt));};});
function parts(arr){return arr.map(function(p){var q={};for(var k in p)q[k]=p[k];q.value=tr(p.value);return q;});}
var W=function(a,opt){if(!ui(a))return new O(a,opt);var f=new O(L,opt),fm=f.format,fp=f.formatToParts,fr=f.formatRange,frp=f.formatRangeToParts;
Object.defineProperty(f,"format",{value:function(d){return tr(fm.call(f,d));}});
Object.defineProperty(f,"formatToParts",{value:function(d){return parts(fp.call(f,d));}});
if(fr)Object.defineProperty(f,"formatRange",{value:function(x,y){return tr(fr.call(f,x,y));}});
if(frp)Object.defineProperty(f,"formatRangeToParts",{value:function(x,y){return parts(frp.call(f,x,y));}});
return f;};
W.prototype=O.prototype;W.supportedLocalesOf=O.supportedLocalesOf;Intl.DateTimeFormat=W;
window.__beDatesLocale=L;window.__beDatesTr=tr;})()
