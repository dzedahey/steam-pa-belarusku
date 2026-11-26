/**
 * Вэб-старонкі Steam (Крама, Супольнасць).
 * Крама захоўвае радкі ў некалькіх схаваных слоўніках (Map) — агульным
 * LocalizationManager і асобных "праектных". Таму перахопліваем Map.prototype.get:
 * калі запытваецца радок з нашым ID і яго тэкст супадае (па хэшы) з арыгіналам
 * на en/ru/uk/pl, аддаём беларускі.
 * Тэкст, які старонка паспела намаляваць да плагіна, і старыя (серверныя) часткі
 * старонак без ID замяняюцца па поўным супадзенні тэксту (на мове старонкі) —
 * АЛЕ толькі ўнутры зон інтэрфейсу (шапка, падвал, загалоўкі, кнопкі, службовыя
 * подпісы старонкі гульні). Назвы гульняў, апісанні, агляды, імёны — па-за зонамі
 * або ў спісе выключэнняў, туды плагін не заходзіць.
 * Слоўнік без ID — ліст web_dict мастар-файла (dictpack.json).
 * Плагін Millennium працуе ў асобным "свеце" старонкі, таму код устаўляецца праз <script>.
 */
import { T0, RS0 } from './t0';
import PACK from './webpack.json';
import DICT from './dictpack.json';
import TAGS from './tagspack.json';
import TAGNAMES from './tagnames.json';
import BANNERS from './bannerpack.json';

const LOG = '[steam-be web]';
const T1 = performance.now();   // слоўнікі разабраныя, пачынаецца код плагіна

function mainWorld(P: Record<string, string[][]>, D: Record<string, any[][]>, TB: Record<string, string>, TNM: Record<string, Record<string, number>>, TM: any) {
	const tMain = performance.now();
	const LOG = '[steam-be web]';   // асобна: гэты код выконваецца ўжо ў самой старонцы
	const w = window as any;
	if (w.__beWeb) return;
	const S: any = (w.__beWeb = { v: '0.8.3', tags: 0, get: 0, dom: 0, lang: '', url: location.href });
	const TIME: any = (w.__beTime = Object.assign({}, TM || {}, { main: tMain }));
	const HO = Object.prototype.hasOwnProperty;
	const h = (s: string) => { let x = 0x811c9dc5; for (let i = 0; i < s.length; i++) { x ^= s.charCodeAt(i); x = Math.imul(x, 0x01000193) >>> 0; } return (x % 2176782336).toString(36); };

	// --- 1. Перахоп слоўнікаў ---
	const CACHE: Record<string, string> = Object.create(null);
	function look(k: string, v: string): string {
		const kk = k.charCodeAt(0) === 35 ? k.slice(1) : k;
		if (!HO.call(P, kk)) return v;
		const ck = kk + '\u0001' + v;
		const c = CACHE[ck];
		if (c !== undefined) return c;
		const vs = P[kk];
		let r = v;
		let mine = false;
		for (const x of vs) if (x[0] === v) { mine = true; break; }
		if (!mine) {
			const hv = h(v);
			for (const x of vs) { if (x[1] === hv || x[2] === hv || x[3] === hv || x[4] === hv) { r = x[0]; break; } }
		}
		CACHE[ck] = r;
		if (r !== v) S.get++;
		return r;
	}
	const OG = Map.prototype.get;
	Map.prototype.get = function (this: Map<any, any>, k: any) {
		const v = OG.call(this, k);
		if (typeof v !== 'string' || typeof k !== 'string') return v;
		try { return look(k, v); } catch (e) { return v; }
	};

	// --- 2. Замена тэксту на старонцы — ТОЛЬКІ ў зонах інтэрфейсу ---
	// Мова старонкі: атрыбут lang, а калі яго няма (Майстэрня, стварэнне групы) — ?l= у адрасе або кука Steam_Language
	const LCODE: Record<string, string> = { english: 'en', russian: 'ru', ukrainian: 'uk', polish: 'pl' };
	const qs = (location.search.match(/[?&]l=([a-z]+)/) || [])[1] || '';
	const ck = (document.cookie.match(/(?:^|;\s*)Steam_Language=([a-z]+)/) || [])[1] || '';
	const lm = (document.documentElement.lang || LCODE[qs] || LCODE[ck] || '').toLowerCase();
	const col = /^ru/.test(lm) ? 2 : /^uk/.test(lm) ? 3 : /^pl/.test(lm) ? 4 : /^en/.test(lm) ? 1 : 0;
	S.lang = lm + ':' + col;
	// 2a. Радкі з ID (па тэксце) — калі адзін тэкст мае некалькі перакладаў, бярэм самы частый.
	const RV: Record<string, string | null> = Object.create(null);
	if (col) {
		const CNT: Record<string, Record<string, number>> = Object.create(null);
		for (const k in P) for (const x of P[k]) {
			const hv = x[col];
			if (!hv) continue;
			const c = CNT[hv] || (CNT[hv] = Object.create(null));
			c[x[0]] = (c[x[0]] || 0) + 1;
		}
		for (const hv in CNT) {
			let best: string | null = null, bn = 0, tie = false;
			for (const be in CNT[hv]) { const n = CNT[hv][be]; if (n > bn) { best = be; bn = n; tie = false; } else if (n === bn) tie = true; }
			RV[hv] = tie ? null : best;
		}
	}
	// 2b. Слоўнік старых частак старонак (ліст web_dict), па зонах.
	const esc = (t: string) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	type ZD = { exact: Map<string, string>; sel: [string, string, string][]; tpl: [RegExp, number[], string, boolean][] };
	const ZD: Record<string, ZD> = Object.create(null);
	function mkZD(rows: any[][], cols: number[]): ZD {
		const zd: ZD = { exact: new Map(), sel: [], tpl: [] };
		for (const c of cols) for (const r of rows) {
			const src = r[c];
			if (!src) continue;
			const be = r[0];
			if (r[5]) { zd.sel.push([r[5], src, be]); continue; }
			if (/%\d\$s/.test(src)) {
				const order: number[] = [];
				const re = '^' + esc(src).replace(/%(\d)\\\$s/g, (_m: string, d: string) => { order.push(+d); return '(.+?)'; }) + '$';
				zd.tpl.push([new RegExp(re), order, be, Array.isArray(r[6]) && (r[6] as any).indexOf(c) >= 0]);
			} else if (!zd.exact.has(src)) zd.exact.set(src, be);
		}
		// спачатку больш дакладныя шаблоны (больш пастаяннага тэксту): «Апублікавана … Адрэдагавана …» раней за «Апублікавана …»
		const lit = (re: RegExp) => re.source.replace(/\(\.\+\?\)/g, '').length;
		zd.tpl.sort((a, b) => lit(b[0]) - lit(a[0]));
		return zd;
	}
	for (const z in D as any) ZD[z] = col ? mkZD(D[z], [col]) : { exact: new Map(), sel: [], tpl: [] };
	// Галоўная Крамы часта паказвае загалоўкі блокаў не на мове інтэрфейсу (украінскі — па-англійску),
	// таму для яе дадаткова правяраем радкі на астатніх трох мовах.
	const ZD_HOME_ANY: ZD | null = col && D['Главная'] ? mkZD(D['Главная'], [1, 2, 3, 4].filter((c) => c !== col)) : null;
	// Значэнне падстаноўкі ў шаблоне: назва тэга, радок слоўніка той жа зоны (напрыклад, катэгорыя
	// кіраўніцтва ў «Выключыць вынікі з меткай: %1$s») або дата; інакш застаецца як ёсць.
	// Падстаўляны кавалак шаблону («Русский» у «Обзоры (%1$s):») — кароткі. Калі пераклад аргумента раптам
	// значна даўжэйшы за сам аргумент, гэта выпадковае супадзенне — пакідаем арыгінал.
	function sub(v: string, zd?: ZD, p?: Element): string {
		const r = sub0(v, zd, p);
		const k = v.trim();
		if (r !== v && r.length > Math.max(30, k.length * 3 + 10)) { try { console.warn(LOG, 'аргумент шаблону не перакладзены:', k, '→', r.slice(0, 60)); } catch (e) { /* */ } return v; }
		return r;
	}
	function sub0(v: string, zd?: ZD, p?: Element): string {
		const k = v.trim();
		// радок слоўніка, прывязаны да гэтага месца старонкі (напрыклад, катэгорыі ў фільтры кіраўніцтваў)
		if (zd && p) for (const [sel, src, be] of zd.sel) if (src === k && be.indexOf('%') < 0 && p.closest(sel)) return v.replace(k, be);
		const ex = (zd && OG.call(zd.exact, k)) || (ZD['Общее'] && OG.call(ZD['Общее'].exact, k));
		if (ex && ex.indexOf('%') < 0) return v.replace(k, ex);
		const tn = tagName(v);
		if (tn) return tn;
		const rv = RV[h(k)];
		if (rv && rv.indexOf('%') < 0) return v.replace(k, rv);
		const d = dateTr(v);
		// дата вялікімі літарамі («30 НОЯБ., 10 Ч. GMT-8» у загалоўку прэміі Steam)
		if (d === v && /\p{Lu}{2}/u.test(v) && v === v.toUpperCase()) { const dl = dateTr(v.toLowerCase()); if (dl !== v.toLowerCase()) return dl.toUpperCase(); }
		return d;
	}
	function tpl1(src: string, be: string, t: string, zd?: ZD, p?: Element): string | null {
		const order: number[] = [];
		const re = new RegExp('^' + esc(src).replace(/%(\d)\\\$s/g, (_m: string, d: string) => { order.push(+d); return '(.+?)'; }) + '$');
		const m = t.match(re);
		if (!m) return null;
		let out = be; order.forEach((n, i) => { out = out.split('%' + n + '$s').join(sub(m[i + 1], zd, p)); });
		return clean(out);
	}
	// 2c. Месяцы ў датах
	const MON: [RegExp, number][] = [];
	([
		['jan(uary)?', 'feb(ruary)?', 'mar(ch)?', 'apr(il)?', 'may', 'june?', 'july?', 'aug(ust)?', 'sep(t|tember)?', 'oct(ober)?', 'nov(ember)?', 'dec(ember)?'],
		['янв(\\.|аря|арь)?', 'фев(р?\\.|раля|раль)?', 'мар(\\.|та|т)?', 'апр(\\.|еля|ель)?', 'ма(я|й)', 'июн(\\.|я|ь)?', 'июл(\\.|я|ь)?', 'авг(\\.|уста|уст)?', 'сен(т?\\.|тября|тябрь)?', 'окт(\\.|ября|ябрь)?', 'ноя(б?\\.|бря|брь)?', 'дек(\\.|абря|абрь)?'],
		['січ(\\.|ня|ень)?', 'лют(\\.|ого|ий)?', 'бер(\\.|ез\\.|езня|езень)?', 'квіт(\\.|ня|ень)?', 'трав(\\.|ня|ень)?', 'черв(\\.|ня|ень)?', 'лип(\\.|ня|ень)?', 'серп(\\.|ня|ень)?', 'вер(\\.|ес\\.|есня|есень)?', 'жовт(\\.|ня|ень)?', 'лист(\\.|оп\\.|опада|опад)?', 'груд(\\.|ня|ень)?'],
		['sty(\\.|cznia|czeń)?', 'lut(\\.|ego|y)?', 'mar(\\.|ca|zec)?', 'kwi(\\.|etnia|ecień)?', 'maj(a)?', 'cze(\\.|rwca|rwiec)?', 'lip(\\.|ca|iec)?', 'sie(\\.|rpnia|rpień)?', 'wrz(\\.|eśnia|esień)?', 'paź(\\.|dziernika|dziernik)?', 'lis(\\.|topada|topad)?', 'gru(\\.|dnia|dzień)?'],
	] as string[][]).forEach((a) => a.forEach((m, i) => MON.push([new RegExp('^' + m + '$', 'i'), i])));
	const BE_SHORT = ['студз.', 'лют.', 'сак.', 'крас.', 'мая', 'чэрв.', 'ліп.', 'жн.', 'вер.', 'кастр.', 'ліст.', 'снеж.'];
	const BE_NOM = ['студзень', 'люты', 'сакавік', 'красавік', 'травень', 'чэрвень', 'ліпень', 'жнівень', 'верасень', 'кастрычнік', 'лістапад', 'снежань'];
	const WD_BE = ['панядзелак', 'аўторак', 'серада', 'чацвер', 'пятніца', 'субота', 'нядзеля'];
	const WD_SH = ['пн', 'аў', 'ср', 'чц', 'пт', 'сб', 'нд'];
	const WD: [RegExp, number, boolean][] = [];
	([
		['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
		['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'],
		['понеділок', 'вівторок', 'середа', 'четвер', 'пʼятниця|п’ятниця|п\'ятниця', 'субота', 'неділя'],
		['poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota', 'niedziela'],
	] as string[][]).forEach((a) => a.forEach((m, i) => WD.push([new RegExp('^(' + m + ')$', 'i'), i, false])));
	([
		['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
		['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
		['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'нд'],
		['pon\\.?', 'wt\\.?', 'śr\\.?', 'czw\\.?', 'pt\\.?', 'sob\\.?', 'niedz\\.?'],
	] as string[][]).forEach((a) => a.forEach((m, i) => WD.push([new RegExp('^(' + m + ')$', 'i'), i, true])));
	const caseLike = (src: string, out: string) => src === src.toUpperCase() && src !== src.toLowerCase() ? out.toUpperCase() : (/^\p{Lu}/u.test(src) ? out[0].toUpperCase() + out.slice(1) : out);
	function wdTr(t: string): string | null {
		for (const [re, i, sh] of WD) if (re.test(t)) return caseLike(t, (sh ? WD_SH : WD_BE)[i]);
		return null;
	}
	const mon = (w: string) => { for (const [re, i] of MON) if (re.test(w)) return i; return -1; };
	function dateTr(v: string): string {
		const t = v.trim();
		const w0 = wdTr(t); if (w0) return v.replace(t, w0);
		// Каляндар можа змяшчаць дзень тыдня і лікавую дату ў адным вузле.
		const numericDay = t.match(/^([^\d\s,]+)\s+(\d{1,2}[./]\d{1,2}(?:[./]\d{2,4})?)$/u);
		if (numericDay) { const day = wdTr(numericDay[1]); if (day) return v.replace(t, day + ' ' + numericDay[2]); }
		const wd = t.match(/^([^\d\s,]+),\s+(.+)$/u);
		if (wd) { const w1 = wdTr(wd[1]); if (w1) { const d = dateTr(wd[2]); return v.replace(t, w1 + ', ' + d); } }
		const dt = t.match(/^(.+?)\s+(?:@|в|о|o)\s+(\d{1,2}):(\d{2})(:\d{2})?\s*(am|pm)?(\s+[A-Z]{2,5})?$/iu);
		if (dt) {
			const d = dateTr(dt[1]);
			if (d !== dt[1]) {
				let hh = +dt[2]; const ap = (dt[5] || '').toLowerCase();
				if (ap === 'pm' && hh < 12) hh += 12; if (ap === 'am' && hh === 12) hh = 0;
				return v.replace(t, d + ' а ' + String(hh).padStart(2, '0') + ':' + dt[3] + (dt[4] || '') + (dt[6] || ''));
			}
			return v;
		}
		let m = t.match(/^(\d{1,2})\s+([^\d\s,]+),?\s+(\d{4})(\s*(г\.|р\.))?$/u);
		if (m) { const i = mon(m[2]); if (i >= 0) return v.replace(t, m[1] + ' ' + BE_SHORT[i] + ' ' + m[3] + ' г.'); }
		m = t.match(/^([^\d\s,]+)\s+(\d{1,2}),\s+(\d{4})$/u);
		if (m) { const i = mon(m[1]); if (i >= 0) return v.replace(t, m[2] + ' ' + BE_SHORT[i] + ' ' + m[3] + ' г.'); }
		// дата з часам: «30 нояб., 10 GMT-8», «30 НОЯБ., 10 Ч. GMT-8», «NOV 30, 10 AM PST» (прэмія Steam)
		m = t.match(/^(\d{1,2})\s+([^\d\s,]+),\s+(\d{1,2}(?::\d{2})?(?!\d).*)$/u) || null;
		if (m) { const i = mon(m[2]); if (i >= 0) return v.replace(t, m[1] + ' ' + caseLike(m[2], BE_SHORT[i]) + ', ' + m[3].replace(/^(\d{1,2}(?::\d{2})?)\s*(ч\.|год\.?)/iu, (_x: string, h1: string, u: string) => h1 + ' ' + caseLike(u, 'гадз.'))); }
		m = t.match(/^([^\d\s,]+)\s+(\d{1,2}),\s+(\d{1,2}(?::\d{2})?(?!\d).*)$/u);
		if (m) { const i = mon(m[1]); if (i >= 0) return v.replace(t, m[2] + ' ' + caseLike(m[1], BE_SHORT[i]) + ', ' + m[3]); }
		m = t.match(/^(\d{1,2})\s+([^\d\s,]+)$/u);
		if (m) { const i = mon(m[2]); if (i >= 0) return v.replace(t, m[1] + ' ' + BE_SHORT[i]); }
		m = t.match(/^([^\d\s,]+)\s+(\d{1,2})$/u);
		if (m) { const i = mon(m[1]); if (i >= 0) return v.replace(t, m[2] + ' ' + BE_SHORT[i]); }
		m = t.match(/^([^\d\s,]+)\s+(\d{4})(\s*(г\.|р\.))?$/u);
		if (m) { const i = mon(m[1]); if (i >= 0) { const n = BE_NOM[i]; return v.replace(t, (/^\p{Lu}/u.test(m[1]) ? n[0].toUpperCase() + n.slice(1) : n) + ' ' + m[2]); } }
		return v;
	}
	// 2c'. Даты, якія старонка фармуе праз toLocaleDateString (новыя старонкі Супольнасці)
	if (col) {
		const OLD = Date.prototype.toLocaleDateString;
		Date.prototype.toLocaleDateString = function (this: Date, ...a: any[]) {
			const r = OLD.apply(this, a as any);
			try { return dateTr(r); } catch (e) { return r; }
		};
		const OLDS = Date.prototype.toLocaleString;
		Date.prototype.toLocaleString = function (this: Date, ...a: any[]) {
			const r = OLDS.apply(this, a as any);
			try { return dateTr(r); } catch (e) { return r; }
		};
		try {
			const D = Object.getOwnPropertyDescriptor(Intl.DateTimeFormat.prototype, 'format');
			if (D && D.get) {
				const g = D.get;
				Object.defineProperty(Intl.DateTimeFormat.prototype, 'format', { configurable: true, get: function (this: any) {
					const f = g.call(this);
					return function (d?: any) { const r = f(d); try { return dateTr(r); } catch (e) { return r; } };
				} });
			}
		} catch (e) { /* */ }
	}
	// 2d. Зоны. Па-за імі тэкст не чапаем ніколі.
	const HOME = '.community_recommendations_block .view_more, .community_recommendations_block .hours, .content_hub_capsule_ctn .label, .info_ctn .reason, .ds_flag, #recommended_by_deep_dive_title, .home_content h2, .home_content_reason, .home_content .btnv6_white_transparent, .home_section_title, .home_section_subtitle, .home_title_ctn, .title_grid, .see_more_link, .home_tabs_row_ctn, .tab_controls_ctn, .home_gift_card_text, .more_content, .more_content_desc, #LoadingText, .topseller_title, .topseller_subtext, .main_reason, .tab_item_release_date, .broadcast_live_stream_icon, .discount_aria_label, .game_review_summary, .review_count';
	const APP = '.banner_open_in_steam, .page_title_area .btnv6_blue_hoverfade, .grid_label, #appHeaderGridContainer .grid_content, .user_reviews_summary_row .subtitle, .user_reviews_summary_row .nonresponsive_hidden, .responsive_reviewdesc_short, .release_date, .dev_row .subtitle, .responsive_block_header, .glance_tags_label, #reviewsHeader_responsive, .gamehighlight_desktopcarousel, #queueActionsCtn, .game_area_purchase_game > h1, .game_area_purchase_game > h2, .btn_addtocart, #gameAreaDLCSection .gradientbg, #category_block, .game_area_details_specs_ctn .label, #shareEmbedRow, #LanguagesHeader, .responsive_banner_link_title, #languageTable .checkcol, #languageTable .ellipsis, .all_languages, .Agency, .block_title, .communitylink_points_shop_item, .linkbar, #genresAndManufacturer b, .game_page_autocollapse_readmore, .game_area_sys_req strong, .sysreq_tab, #game_area_metalink, .steam_curators_block .block_header, #aboutThisGame h2:first-of-type, .game_area_sys_req_note, #EmbedModal, .app_tag_modal_right, .app_tag_modal_left, #game_area_reviews > h2, .breadcrumbs .blockbg > a:first-child, .notice_box_content, .franchise_notice .franchise_name, .game_area_already_owned, .game_area_play_stats .details_block, #review_create, .queue_menu_flyout, .DRM_notice, .recommendation_reasons, .responsive_apppage_details_right.heading, .game_purchase_options_editions_header_title, .package_contents > b, .package_contents_show_more, .btn_packageinfo, .package_in_library_flag, .bundle_label, .collectionComplete, .dlc_highlight_reason, .game_area_dlc_price, #dlc_footer, .sys_req > h2, .game_area_sys_req li, .breadcrumbs .blockbg > a[href*="/genre/"], .breadcrumbs .blockbg > a[href*="/franchise/"], #genresAndManufacturer a[href*="/genre/"], .app_tag_modal_content, .game_area_already_owned_btn, .package_contents_show_less, #earlyAccessHeader, .early_access_banner, .game_pt_note, .family_info, #game_area_content_descriptors > h2, #game_area_content_descriptors > p, .game_area_description > h2:not(.bb_tag), .game_purchase_discount_countdown, .ds_completetheset, .package_contents > div';
	// Кіраўніцтвы: галоўная і спіс кіраўніцтваў гульні, стварэнне і рэдагаванне свайго.
	// Назва кіраўніцтва і загалоўкі ўжо створаных раздзелаў — тэкст карыстальніка, у зону не ўваходзяць.
	const GUIDES = '.apphub_Guides .subtitle_ctn, .apphub_Guides #AppHubSearch .searchTextContainer, .guides_home_section_title, .guides_home_view_all_link, .guide_home_category_name, .guide_home_category_count, .apphub_responsive_menu .subheader, .apphub_ResponsiveMenuItem, .editGuideHeader, .editGuidePageTitle > span, .newCollectionDesc, #SubmitGuideForm, .editGuidePageControls, .editGuidePageSectionTitle, .editGuidePageSectionDesc, .editGuideEmptyDetailBox, .editGuideTOCSectionControls, .editGuideTOCControls, .editGuideTOCSection.empty .editGuideTOCSectionTitle, .editGuideSubSectionPageControlsContainer, .editGuideChangesDesc, .editGuideSubSectionLabel, .editGuideSubSectionPreviewImagesDesc, #UploadPreviewImages, .editGuideInsertOptionControls';
	// Старонка аплаты (checkout.steampowered.com) — уся службовая, акрамя назваў тавараў і імя акаўнта
	const CHECKOUT_HOST = location.hostname === 'checkout.steampowered.com';
	// старонка пра ранні доступ (store.steampowered.com/earlyaccessfaq): уласная зона, класы ў яе агульныя
	const EAFAQ = location.hostname === 'store.steampowered.com' && /^\/earlyaccessfaq/.test(location.pathname);
	const EXCL_CHECKOUT = '#review_account_body, .checkout_review_item_title, .checkout_review_cart_item a, .cart_item_desc, input, textarea';
	const HOME_LABELS = '#home_featured_and_recommended, #home_tags_section .home_title, #home_accountblocks_section .home_title';
	const ZONES: [string, string][] = [
		['Шапка', '#global_header, #responsive_page_menu, [data-featuretarget^="store-menu"], #StoreTemplate [role="navigation"], #CommunityTemplate [role="navigation"]'],
		['Подвал', '#footer, [data-featuretarget="footer"], #cookiePrefPopup'],
		// падарункавыя карты і ўліковы запіс (store.steampowered.com/digitalgiftcards, /account)
		['Аккаунт', 'body.account .page_header_ctn, body.account .page_content'],
		['Главная', HOME],
		['Страница игры', APP],
		['Всплывающее окно игры', '#global_hover_content, .tab_preview, #tab_preview_container'],
		// чарга рэкамендацый (store.steampowered.com/explore)
		['Список рекомендаций', '.page_header_ctn .header_area, .discovery_queue_apps, .discovery_queue_customize_ctn, .explore_rightcol_box, .rightcol > h2, .leftcol > .pageheader, .faq_question, .faq_answer, .discovery_queue_overlay_message, .dq_item_reason'],
		['Сообщество', GUIDES + ', .appHubSearchTextForm, .discussionSearchTextContainer, .apphub_CardRating, .apphub_CardControls, .received_compensation, .blotter_page_title, .friendslist_entry_content, .friends_link_block, .friends_add_block, .friends_launch_area .webchat_launch, .profile_friends_ingame, .blotter_eventsblock, #blotter_statuspost_submit, #blotter_appselect_app_activeoption, .blotter_author_block, .blotter_daily_rollup_line, .blotter_control_container, .blotter_viewallcomments_container, .commentthread_header, .commentthread_subscribe_ctn, .commentthread_entry_submitlink, .found_helpful, .vote_header, .control_block, .ss_spoiler_text, .share_ctn, #SharePopup, .dynamiclink_author, .community_home_header, .community_home_app_shortcuts_list_header, .new_items_num, .community_home_search_title, .apphub_sectionTab, .responsive_tab_select, .community_home_sort_options, #HeaderUserBreadcrumbs, .sharedfiles_usercontrols_label, .sharedfiles_usercontrol_ctn label, [id^="sharedfiles_filterselect_"][id$="_activeoption"], #sharedfiles_filterselect_app_option_0, [id^="sharedfiles_view_option_"], [id^="sharedfiles_filterselect_display_option_"], [id^="sharedfiles_privacy_option_"], .sectionTabs, #ScreenshotManagementControlsTop, #ScreenshotManagementControlsBottom, #NoItemsContainer, #BackToTop, #imgWallLoadingPageModal, #confirmBatchModalContents, #noSelectedShotsModalContents, #privacyFailedModalContents, #confirmUnlinkAccountModalContents, #confirmShowVideoPrivacyModalContents, .video_footer_ctn, #instructions_main, .image_grid_title, .rightSectionTopTitle, .workshopBrowsePaging, .rightbox_list_option_content, #hover_user_action_history, .ugc_show_warning_image, .profile_small_header_location, .review_stat .giantNumberSubhead, .review_list h1, .review_box .header, .vote_header .hours, .vote_header .title, .early_access_review, .review_box .posted, .control_block, .dselect_container, .dropcontainer, .review_app_actions, .review_gameoptions, .responsive_review_gameoptions, .review_page_content .panel, .ratingBar, .playTime, .recommendation_date, .ratingSummary, #ReviewEdit, .review_edit_received_compensation, .review_page_content .friendBlock + div, .commentthread_comment_timestamp, .sharedfiles_item_page_header .breadcrumbs, #bannedNotification, #incompatibleNotification, .currentVisibility, .visibilityDesc, #ItemControls, #JustFavorited, .sidebar .panel .title, .sidebar .general_btn, .sidebar .rightSectionTopTitle, .detailsStatsContainerLeft, .detailsStatsContainerRight, .stats_table, .commentthread_workshop_authorbadge, #AddToCollectionDialogLoading, #AddToCollectionDialogNoEligibleCollections, .descriptionLabel, .item_text_edit_button, .ratingSection, .guideAuthors, .workshopTags, .friends_favorited_text, .commentTabs, #GuideTableOfContents, #DeveloperComments, .responsive_local_menu .btnv6_blue_hoverfade, #visibilityselect, .friendBlock .friendSmallText, .share_controls_steam, .share_controls_page_link, .market_headertip, .inventory_rightnav, #inventory_more_dselect_container, #inventory_more_droplist, .filter_ctn, #inventory_pagecontrols, .inventory_msg_content, .pending_gifts_header, #gift_error_modal_content, #gift_unpack_install_modal, .giftcard_billing_required, #billing_info_form label, #market_sell_dialog, #market_buynow_dialog, #market_removelisting_dialog, #market_advancedsearch_dialog, .market_dialog_content, .trade_protection_description, .trade_protection_example, .market_headertip_text, .profile_subpage_selector, .tradeoffer_welcome_ctn, .rightcol_controls, .newtradeoffer, .inventory_history_pagingrow, .tradehistory_date, .tradehistory_event_description, .market_header_text, .user_info, #marketBetaNoteCtn, #myMarketTabs, .market_tab_well_tab_contents, .item_market_action_button_contents, .my_market_header, .market_listing_table_message, #escrow_description, #market_search_advanced_show, .market_search_sidebar_contents, .market_search_sidebar_section_tip_small, .market_show_more_games, .market_listing_table_header, #popularItemsMore, .market_paging_summary, .market_title_text, .apphub_Chat, .apphub_Stats, .apphub_friends_who_played_recently_title, .apphub_friend_block .ellipsis, .found_helpful, .apphub_CardContentType, .fiveStar, .date_posted, .responsive_tab_control, .forum_newtopic_header, .subforum_radios_label, .subforum_radio_topics, .forum_paging_summary, .forum_topic_lastpost, .forum_pagesize_options, .forum_search_notice, .forum_subscribe_button, .rightcol_minor_text, .forum_list_postcount, .forum_list_name, .rightbox .weblink, .rightbox_content_header, .breadcrumb_current_page, .forum_topic_pinned_notice, .popup_menu_item, .forum_comment_action, .forum_audit, .commentthread_entry_autosubscribe, .topicstats_label, .forum_topic, .large_title, .steam_discussions_intro, #tab_general, #tab_games, #tab_tools, .discussions_view_more_link, #forum_list_general h2, .recent_game_discussion_count, .discussions_forumlist_header, .discussions_forumlist_topiccount, .discussions_forumlist_lastpost, .discussions_forumlist_forumname, .group_breadcrumbs, .discussions_searchSort, .discussion_search_pagingcontrols, .searchresult_forumname, #report_modal_content, .browseApps, .appInfo, .current_player_workshop_title, .current_player_workshop_link, .subscribeRSS, .commentsLink, .numRatings, .workshop_item_header .col_right, .change_note_link, .sidebar .panel, #JustSubscribed, .game_area_purchase_game h1, #updateKVTagsForm, .itemContents, .follower_tt, .commentthread_entry, .commentthread_comment_actions, .commentthread_textarea, #manage_friends_control, .profile_friends.title_bar, .profile_friends .title, #search_results_sentinvites_empty, #state_ignored_friends, #state_blocked_friends, #friends_coplay_ctn .description, #friends_coplay_ctn #friends_list > div, .manage_action, #search_text_box, #search_text_box_sent, .profile_groups, .broadcast_moderators_header, #friends_broadcast_moderators .profile_friends, .badge_details_set_favorite, .badge_empty_right, .new_items_num, .gamecards_inventorylink, .badge_friends_have_earned_label, .badge_card_to_collect_links, .badge_card_to_collect_info, .badge_card_set_text, .badge_friendwithgamecard_actions, .badge_title, .badge_card_to_collect_header, .gamecard_badge_progress, #inventory_more_trigger, #filter_control, .workshopLink, #no_items, .community_search_container h2, #PromptModalForm, .creatorsBlock .friendBlock span, #content form .formRow, #content p.greyText, #abbreviation_info, #link_info, #public_info, .group_create_btn, #ig_bottom #mainContents > .title, #ig_bottom #mainContents > .subtitle, .menu_panel, #profileBlock > div:first-child, .workshop_apps_paging_summary, .rightbox_list_option_content, .apphub_OtherSiteInfo, .screenshotAppDesc, .sidebar .rightSectionTitle, #GetMoreContentBtn, #action_wait, #NoMoreContent, #appHubLoadingPageModal'],
		['Профиль', '.profile_summary_footer, .favorite_badge_description .xp, .btn_profile_action, .profile_in_game_header, .count_link_label, .profile_customization_editlink, .profile_customization_header, .myworkshop_playerName, .guide_showcase_author, .showcase_stat .label, .showcase_bodylabel, .games_played_title, #replay .stat_ctn, .profile_recentgame_header, .recentgame_quicklinks, .game_info_achievement_summary, .game_info_badge_description .xp, .published_file_link, .commentthread_header_label, #reportAbuseModal, .abuseOption, #profile_action_dropdown_link, #profile_action_dropdown .popup_menu_item, .profile_actions_follow, .persona_level, .profile_header_actions, #NamePopup, .profile_topfriends .friendBlock .friendSmallText, .profile_topfriends .friendBlock span, .game_info_details, .screenshot_showcase_stat, #abuseForm, .profile_small_header_location, .profile_in_game_header, .friends_nav, .profile_friends.title_bar, #manage_friends_control, #add_friends_button, #manage_friends, #search_results_empty, .state_block, .friend_last_online_text, .profile_xp_block, .profile_badges_sortoptions, .profile_badges_header_title, .profile_paging, .badge_title_stats_playtime, .badge_title_stats_drops, .how_to_get_card_drops_ctn, .card_drop_info_dialog, .badge_progress_info, .badge_title_playgame, a.btn_grey_black, .profile_customization'],
		['React', '[data-featuretarget]'],
		['SSR', '#StoreTemplate, #CommunityTemplate'],   // новыя старонкі (чарты, спіс жаданага, вынікі года): толькі дакладныя радкі са слоўнікаў
	];
	const EXCL = '[role="navigation"] a[href*="/app/"], .app_name, .tab_item_name, .tab_item_title, .persona_name, .persona, #account_pulldown, .username, .top_tag, .home_title, .discount_prices, .discount_pct, .discount_original_price, .discount_final_price, #language_dropdown, .playerAvatar, .friend_name, .info_ctn .reason .tags, .single_title, .home_content_reason a, #recommended_by_deep_dive_title a, #global_hover_content h4, #global_hover_content .app_tag, .tab_preview h2, .tab_preview .app_tag, .game_area_dlc_name, .game_purchase_price, #developers_list, .glance_tags .app_tag, a[href*="/sub/"], a[href*="/bundle/"], a[href*="/news/"], a[href*="/curator/"], a[href*="/developer/"], a[href*="/publisher/"], a[href*="/franchise/"], a[href*="/profiles/"], a[href*="/id/"], a[href*="/groups/"], [contenteditable="true"]';
	const EXCL_REACT = 'a[href*="/app/"]';
	const EXCL_SSR = 'a[href*="/app/"], a[href*="/sub/"], a[href*="/bundle/"], a[href*="/id/"], a[href*="/profiles/"], a[href*="/news/"], input, textarea';
	// Супольнасць і профіль: імёны, назвы гульняў, тэксты карыстальнікаў
	const EXCL_COMM = '.badge_card_set_title, .creatorsBlock .friendBlockContent > a, .forum_topic_name, .forum_topic_op, .searchresult_forum_link, .forum_op .content, .forum_op .topic, .commentthread_comment_author .hoverunderline, .commentthread_comment_author bdi, .apphub_friend_block .online a, .apphub_friend_block .offline a, .apphub_friend_block .in-game a, .sidebar .panel .friendBlock, .sidebar .panel .requiredItem, .tradehistory_event_description a, #gift_unpack_install_modal h2 b, .market_listing_item_name, .market_listing_game_name, .market_headertip a.market_headertip_item, [id^="guideSectionSelection_"]:not(#guideSectionSelection_0):not(#guideSectionSelection_-1), [id^="sharedfiles_filterselect_app_option_"]:not(#sharedfiles_filterselect_app_option_0), q.ellipsis, .workshopItemTitle, .review_box .content, .apphub_CardTextContent, .blotter_author_block a, .blotter_daily_rollup_line a, .blotter_voters_names a, .blotter_gamepurchase_details a, .blotter_gamepurchase_text, .dynamiclink_name, .dynamiclink_description, .dynamiclink_authorname, .commentthread_comment_text, .commentthread_comment_author, .guide_showcase_title, .favorite_badge_description .name, .game_name, .responsive_body_text, .blotter_screenshot_title, bdi, .actual_persona_name, .persona_name:not(.persona_level), .profile_summary, .showcase_notes, .showcase_item_detail_title, textarea, input, [contenteditable="true"]';
	const isComm = (z: string) => z === 'Сообщество' || z === 'Профиль';
	// Выключэнні з выключэнняў: службовы тэкст усярэдзіне блокаў з імёнамі (статус, дата, акно імёнаў)
	const INCL_COMM = '.apphub_CardTextContent .date_posted, .apphub_CardTextContent .received_compensation, .apphub_CardTextContent .early_access_review, #NamePopup, #abuseForm, .commentthread_comment_timestamp, .friendSmallText, .commentthread_comment_actions';
	const excluded = (el: Element, z: string) => {
		if (el.closest(HOME_LABELS)) return false; // службовы загаловак, а не назва гульні
		if (el.closest('.community_recommendations_block .view_more')) return false; // «Читать дальше» — спасылка на профіль, але тэкст службовы
		if (el.closest('.explore_rightcol_box')) return false; // кнопкі «Спіс жаданага», «Паглядзець падпіскі» вядуць на профіль
		// старонка гульні: службовыя тэксты ўнутры спасылак на набор, серыю, профілі сяброў
		if (el.closest('.btn_packageinfo, .franchise_notice .franchise_name, .recommendation_reasons p, .package_in_library_flag, .package_contents_show_more, .breadcrumbs a[href*="/franchise/"], .package_contents_show_less, .dlc_highlight_reason, .game_area_play_stats .details_block a')) return false;
		// карусэль «%1$s: іншыя прадукты» — загаловак з назвай распрацоўшчыка ўнутры спасылкі на яго старонку
		if (el.closest('[data-featuretarget="creatorhome-carousel"] a:not([href*="/app/"])')) return false;
		if (z === 'Оплата') return !!el.closest(EXCL_CHECKOUT);
		return isComm(z) ? (!el.closest(INCL_COMM) && !!el.closest(EXCL_COMM)) : (!!el.closest(EXCL) || (z === 'React' && !!el.closest(EXCL_REACT)) || (z === 'SSR' && !!el.closest(EXCL_SSR)));
	};
	// Тэксты карыстальнікаў (каментарыі, допісы форуму, агляды, апісанні профілю, імёны) — не чапаем
	// ні ў адной зоне і ні адным спосабам (поўны радок, складзены блок, загаловак, дакладнае супадзенне).
	// Выключэнне — толькі службовыя часткі ўнутры іх (INCL_COMM: дата, «Прадукт атрыманы бясплатна» і г.д.).
	const USER = '.commentthread_comment_text, .commentthread_comment_author, .forum_op .content, .forum_op .topic, .forum_topic_name, .forum_topic_op, .searchresult_forum_link, .review_box .content, .apphub_CardTextContent, .profile_summary, .showcase_notes, .blotter_gamepurchase_text, .dynamiclink_name, .dynamiclink_description, .dynamiclink_authorname, .workshopItemTitle, .guide_showcase_title, .blotter_screenshot_title, .actual_persona_name, .persona_name:not(.persona_level), .market_listing_item_name, bdi';
	const userText = (el: Element) => !!el.closest(USER) && !el.closest(INCL_COMM);
	const DATES = '.forum_topic_lastpost, .discussions_forumlist_lastpost span, .date_posted, .tradehistory_date, .commentthread_comment_timestamp, .detailsStatsContainerRight, .recommendation_date, .review_box .posted, #global_hover_content .hover_release span, .tab_item_release_date, .top_new_releases_date, .release_date .date, #appHeaderGridContainer .grid_content';
	const SKIP = /^(SCRIPT|STYLE|TEXTAREA|INPUT|NOSCRIPT|CODE|PRE)$/;
	const SKIPSEL = 'script, style, textarea, input, noscript, code, pre';
	// Элемент (або яго продак) — код, поле ўводу або рэдагаванае карыстальнікам месца: не чапаем
	const skipEl = (e: Element) => !!e.closest(SKIPSEL) || (e as HTMLElement).isContentEditable === true;
	// Што мы самі запісалі ў вузел/атрыбут. Калі там тое ж самае — гэта наш пераклад, другі раз не перакладаем
	// (абарона ад цыклаў кшталту ОК → OK → ОК і ад лішняй працы MutationObserver).
	const MINE = new WeakMap<Node, string>();
	const MINEA = new WeakMap<Element, Record<string, string>>();
	const ATTRS = ['placeholder', 'title', 'aria-label', 'data-tooltip-text'];
	// Спасылкі меню актыўнасці могуць весці праз /profiles/ID/, нават калі сама
	// старонка адкрытая праз /id/name/. Класы бакавой панэлі таксама змяняюцца.
	// Вызначаем службовыя спасылкі па прызначэнні, а не па класе ці базе URL.
	function activityMenu(p: Element): boolean {
		const page = /^\/(?:(?:id|profiles)\/[^/]+\/home|my(?:\/home)?|home)\/?$/.test(location.pathname);
		if (location.hostname !== 'steamcommunity.com' || !page) return false;
		const field = p.tagName === 'INPUT';   // поле пошуку (placeholder або «фальшывая падказка» ў value)
		const context = field ? p.parentElement : p;
		if (!context || context.closest(EXCL_COMM) || context.closest('.persona, [data-miniprofile], .friendBlock')) return false;
		if (field) return true;
		const a = p.closest('a[href]');
		if (!a) return false;
		try {
			const u = new URL(a.getAttribute('href') || '', location.href);
			if (u.origin !== location.origin) return false;
			const target = u.pathname.match(/^\/(?:(?:id|profiles)\/[^/]+|my)(?:\/(.*?))?\/?$/);
			if (!target) return false;
			const tail = (target[1] || '').replace(/\/$/, '');
			// Імя карыстальніка таксама спасылаецца на корань профілю.
			if (tail === '' && !/^(?:Открыть мой профиль|View my profile|Переглянути мій профіль|Wyświetl mój profil)$/i.test((a.textContent || '').trim())) return false;
			return /^(?:|edit|games|friends|groups|inventory|tradeoffers|screenshots|videos|guides|myworkshopfiles|commenthistory)$/.test(tail);
		} catch (e) { return false; }
	}
	function zoneOf(p: Element): string | null {
		// Старонка аплаты: усё, акрамя шапкі і падвала, — зона «Оплата» (класы кшталту .dselect_container
		// сустракаюцца і ў Супольнасці, але тут свае радкі: «Discover» — плацежная сістэма, а не «Агляд»)
		if (EAFAQ && p.closest('#main_content')) return 'Ранний доступ';
		if (CHECKOUT_HOST) {
			for (const [z, sel] of ZONES) if ((z === 'Шапка' || z === 'Подвал') && p.closest(sel)) return z;
			return p.closest('body') ? 'Оплата' : null;
		}
		if (p.closest(HOME_LABELS)) return 'Главная';
		if (activityMenu(p)) return 'Сообщество';
		// рэдактар вітрын: перадпрагляды вітрын і дыялогі выбару (гульня, прадмет, дасягненне…)
		if (location.hostname === 'steamcommunity.com' && /^\/(?:id|profiles)\/[^/]+\/edit\/showcases/.test(location.pathname) && p.closest('#showcases, .newmodal')) return 'Профиль';
		for (const [z, sel] of ZONES) if (p.closest(sel)) return z;
		return null;
	}
	// --- 3. Тэгі: па ID. Назвы тэгаў на мове старонкі бярэм у самога Steam (/tagdata/populartags).
	const LANGN = ['', 'english', 'russian', 'ukrainian', 'polish'][col] || '';
	let TN: Record<string, string> | null = null;
	const TAGSEL = 'a[href*="/tag/"], a[href*="/tags/"], .app_tag, .top_tag, .deep_dive_tag, .info_ctn .reason .tags span, .tab_preview .app_tag, #global_hover_content .app_tag';
	function buildTN(list: { tagid: number; name: string }[]) {
		const m: Record<string, string> = TN || Object.create(null);
		for (const t of list) { const be = TB[String(t.tagid)]; if (be && t.name) m[t.name.trim().toLowerCase()] = be; }
		TN = m;
		S.tags = Object.keys(m).length;
	}
	// Назва тэга можа прыйсці не на мове інтэрфейсу (англійская Крама паказвае «Ролевая стратегия games»,
	// калі ў акаўнце выбраная руская), таму ў запасе — назвы тэгаў на ўсіх чатырох мовах.
	let TNA: Record<string, string> | null = null;
	function tagAny(k: string): string | null {
		if (!TNA) {
			TNA = Object.create(null);
			for (const ln in TNM) for (const n in TNM[ln]) { const be = TB[String(TNM[ln][n])]; if (be && !(n in TNA!)) TNA![n] = be; }
		}
		return TNA![k] || null;
	}
	const tagName = (v: string): string | null => { const k = v.trim().toLowerCase(); return (TN && TN[k]) || tagAny(k); };
	// Шаблоны з назвай меткі («Гульні: %1$s», «Бо вы гуляеце ў гульні з меткай «%1$s»»): Steam бярэ ўжо перакладзены
	// шаблон, але падстаўляе ў яго назву меткі на мове інтэрфейсу — перакладаем гэтую назву.
	const TAG_TPL: [RegExp, string][] = [];
	for (const k of ['Sale_PersonalizedCarousel_Section_title', 'Sale_PersonalizedCarousel_Section_subtitle', 'SpecialsPage_ExploreTagGames']) {
		for (const v of (HO.call(P, k) ? P[k] : [])) {
			const be = v[0];
			if (be && be.indexOf('%1$s') >= 0 && !TAG_TPL.some((x) => x[1] === be)) TAG_TPL.push([new RegExp('^' + esc(be).replace(/%1\\\$s/, '(.+?)') + '$', 'i'), be]);
		}
	}
	function tagTpl(t: string): string | null {
		for (const [re, be] of TAG_TPL) { const m = t.match(re); if (m) { const tg = tagName(m[1]); if (tg) return be.replace('%1$s', tg); } }
		return null;
	}
	function trTag(raw: string): string | null {
		const m = raw.match(/^([\s,·•|]*)(.*?)([\s,·•|]*)$/);
		if (!m || !m[2]) return null;
		const be = tagName(m[2]);
		return be ? m[1] + be + m[3] : null;
	}
	(function loadTags() {
		if (!LANGN) return;
		// 1) убудаваны спіс назваў (працуе і ў Супольнасці); 2) свежы спіс з Крамы, калі ёсць
		const own = TNM[LANGN];
		if (own) { const m: Record<string, string> = Object.create(null); for (const n in own) { const be = TB[String(own[n])]; if (be) m[n] = be; } TN = m; S.tags = Object.keys(m).length; }
		const key = 'beTags_' + LANGN;
		try {
			const c = JSON.parse(localStorage.getItem(key) || 'null');
			if (c && c.list && Date.now() - c.ts < 3 * 864e5) { buildTN(c.list); return; }
		} catch (e) {}
		if (location.hostname !== 'store.steampowered.com') return;
		fetch('/tagdata/populartags/' + LANGN).then((r) => r.json()).then((list) => {
			if (!Array.isArray(list)) return;
			try { localStorage.setItem(key, JSON.stringify({ ts: Date.now(), list })); } catch (e) {}
			buildTN(list);
			if (document.body) document.body.querySelectorAll(TAGSEL).forEach((e) => fixNode(e));
		}).catch(() => {});
	})();
	// Падстаноўкі, для якіх у тэксце на мове старонкі няма значэння, прыбіраем
	// разам з дужкамі: «Паказаць усе (%1$s)» -> «Паказаць усе».
	const clean = (s: string) => s.replace(/\s*\(\s*%\d\$s\s*\)|\s*%\d\$s/g, '');
	const RATING = '[data-featuretarget="game-rating-block"]';
	function listTr(t: string, z: string, p: Element): string | null {
		const parts = t.split(', ');
		if (parts.length < 2) return null;
		const out: string[] = [];
		for (const x of parts) { const r = zd1(ZD[z], x, p) ?? zd1(ZD['React'], x, p) ?? zd1(ZD['Общее'], x, p); if (r === null) return null; out.push(r); }
		return out.join(', ');
	}
	function trText(t: string, z: string, p: Element): string | null {
		t = t.replace(/\s+/g, ' ');
		// Загаловак блока на галоўнай перакладаем толькі цалкам: «CRIME GAMES» па частках
		// ператварыўся б у «КРЫМІНАЛ Гульні».
		const hl = p.closest(HOME_LABELS);
		if (hl) {
			const whole = (hl.textContent || '').replace(/\s+/g, ' ').trim() === t;
			// частку загалоўка вялікімі літарамі («CRIME» з «CRIME GAMES») не перакладаем: выйдзе набор слоў
			if (!whole && t === t.toUpperCase()) return null;
			const u = whole ? upperTr(t) : null;
			if (u) return u;
		}
		if (p.closest(ITEMINFO)) { const ri = itemTr(t, p); if (ri) return ri; }
		const r1 = zd1(ZD[z], t, p);
		if (r1 !== null) return r1;
		if (isComm(z)) { const rz = zd1(ZD[z === 'Сообщество' ? 'Профиль' : 'Сообщество'], t, p); if (rz !== null) return rz; }
		const r2 = zd1(ZD['Общее'], t, p);   // радкі, што дзейнічаюць ва ўсіх зонах
		if (r2 !== null) return r2;
		const rv = RV[h(t)];
		if (rv) return rv;
		if (TAG_TPL.length && (z === 'SSR' || z === 'React')) { const tt = tagTpl(t); if (tt) return tt; }
		if (z === 'Главная' && ZD_HOME_ANY) { const r3 = zd1(ZD_HOME_ANY, t, p); if (r3 !== null) return r3; }
		// новыя старонкі: меткі ў радках спіса жаданага — кнопкі з назвай тэга, пігулкі «Вашы меткі» на старонцы зніжак
		// і загаловак выбранай меткі (асобны элемент без укладзеных тэгаў па-за карткамі гульняў)
		// (а таксама пункты выпадальнага спіса меткі ў календары і подпісы дыяграмы ў «Выніках года»)
		if ((z === 'SSR' && (p.tagName === 'BUTTON' || p.tagName === 'A' || p.closest('[role="option"]') || (p.childElementCount === 0 && !p.closest('.ImpressionTrackedElement')))) || (z === 'React' && p.closest('foreignObject'))) { const tg = tagName(t); if (tg) return tg; }
		// блок узроставага рэйтынгу: спіс праз коску («Внутриигровые покупки, Внутриигровой чат»)
		if (p.closest(RATING)) { const rl = listTr(t, z, p); if (rl) return rl; }
		// у React — толькі тэкст з лічбамі (каляндар), каб не чапаць назвы
		if (z === 'SSR' || z === 'Главная' || (z === 'React' && /\d/.test(t)) || p.closest(DATES)) { const d = dateTr(t); if (d !== t) return d; }
		return null;
	}
	// Загалоўкі блокаў меток на галоўнай Крамы Steam піша вялікімі літарамі («СЛЭШЕРЫ»).
	// Шукаем іх без уліку рэгістра сярод радкоў слоўніка і назваў тэгаў, вяртаем таксама вялікімі.
	let UPPER: Map<string, string> | null = null;
	function upperTr(t: string): string | null {
		if (t !== t.toUpperCase() || t === t.toLowerCase()) return null;
		if (!UPPER) {
			UPPER = new Map();
			for (const z in ZD) ZD[z].exact.forEach((be, src) => { const k = src.toLowerCase(); if (!UPPER!.has(k)) UPPER!.set(k, be); });
		}
		const k = t.toLowerCase();
		const be = tagName(t) || UPPER.get(k);
		return be && be.indexOf('%') < 0 ? be.toUpperCase() : null;
	}
	// Панэль прадмета ў інвентары: назвы метак і дзеянняў прыходзяць з даных самога прадмета.
	// Для іх асобны раздзел слоўніка «Инвентарь», які дзейнічае толькі тут (агульныя словы
	// кшталту «Common», «Normal» па-за панэллю не чапаем). Радок «Tags: a, b, c» перакладаем па частках.
	const ITEMINFO = '[data-featuretarget="iteminfo"], [id^="iteminfo"]';
	function itemTr(t: string, p: Element): string | null {
		const zi = ZD['Инвентарь'];
		const one = (w: string): string | null => {
			const k = w.trim(); if (!k) return null;
			const ex = (zi && OG.call(zi.exact, k)) || RV[h(k)];
			if (ex && ex.indexOf('%') < 0) return ex.trim();
			const r = zi ? zd1(zi, k, p) : null;   // шаблоны: «Праздничная распродажа %1$s года»
			return r && r !== k ? r : null;
		};
		const oneZ = (w: string): string | null => { const x = zi && OG.call(zi.exact, w.trim()); return x && x.indexOf('%') < 0 ? x.trim() : null; };
		const ex0 = oneZ(t);
		if (ex0) return ex0;
		// назва з колькасцю: «177 Самоцветы», «177 Gems», «177 szt. klejnotów» -> «Самацветы: 177»
		const qn = t.match(/^(\d[\d\s.,]*?)\s+(?:szt\.\s+)?(\S.*)$/u);
		if (qn) { const k = oneZ(qn[2]) || oneZ(qn[2].charAt(0).toUpperCase() + qn[2].slice(1)); if (k) return k + ': ' + qn[1]; }
		const ty = typeTr(t, oneZ);
		if (ty) return ty;
		const r = zi ? zd1(zi, t, p) : null;
		if (r) return r;
		const m = t.match(/^([^:,]{1,30}:)\s*(.+)$/);
		let label = m ? m[1] : '';
		const list = m ? m[2] : t;
		// React піша подпіс і спіс асобнымі тэкставымі вузламі: «Метки: », « », «Обычный, Steam, …»
		const whole = (p.textContent || '').replace(/\s+/g, ' ').trim();
		const afterLabel = !label && whole !== t && /^[^:,]{1,30}:/.test(whole) && whole.endsWith(t);
		const items = list.split(/,\s*/);
		if (items.length < 2 && !label) return null;
		let n = 0;
		const lb = label ? (one(label) || label) : '';
		if (lb !== label) n++;
		const out = items.map((w) => { const x = one(w); if (x) { n++; return x; } return w; });
		// без подпісу («Tags:») спіс перакладаем, толькі калі вядомыя ўсе часткі: інакш гэта звычайны сказ з коскамі
		if (!n || (!label && !afterLabel && n < items.length)) return null;
		return (lb ? lb + ' ' : '') + out.join(', ');
	}
	// Радок тыпу прадмета: «Коллекционная карточка — Hades II» (RU), «Hades II — Колекційна картка» (UK),
	// «Hades II - Karta kolekcjonerska» (PL), «Hades II Trading Card» (EN) -> «Калекцыйная картка — Hades II».
	// Рэдкасць: «Редкий Фон профиля», «Рідкісн. Тло профілю», «Tło profilu (Rzadkie)», «Rare Profile Background».
	function typeTr(t: string, one: (w: string) => string | null): string | null {
		if (t.length > 90 || /[.!?;]$/.test(t) || t.indexOf(', ') >= 0) return null;
		const lc = (x: string) => x.charAt(0).toLowerCase() + x.slice(1);
		const kind = (k: string): string | null => {
			k = k.trim();
			const x = one(k); if (x) return x;
			let m = k.match(/^(\S+\.?)\s+(.+)$/);
			if (m) { const a = one(m[1]), b = one(m[2]); if (a && b) return a + ' ' + lc(b); }
			m = k.match(/^(.+?)\s*\((.+)\)$/);
			if (m) { const a = one(m[2]), b = one(m[1]); if (a && b) return a + ' ' + lc(b); }
			return null;
		};
		let m = t.match(/^(.+?) — (.+)$/);          // RU: тып — гульня
		if (m) { const k = kind(m[1]); if (k) return k + ' — ' + m[2]; }
		m = t.match(/^(.+) [—-] (.+?)$/);           // UK, PL: гульня — тып
		if (m) { const k = kind(m[2]); if (k) return k + ' — ' + m[1]; }
		if (col === 1) {                            // EN: «Hades II Trading Card», «Steam Gems»
			const w = t.split(' ');
			for (let i = 1; i < w.length; i++) { const k = kind(w.slice(i).join(' ')); if (k && !/^[\d\s.,]+$/.test(w.slice(0, i).join(' '))) return k + ' — ' + w.slice(0, i).join(' '); }
		}
		return null;
	}
	function zd1(zd: ZD | undefined, t: string, p: Element): string | null {
		if (zd) {
			for (const [sel, src, be] of zd.sel) {
				if (!p.closest(sel)) continue;
				if (src === t) return clean(be);
				if (src.indexOf('%') >= 0) { const r = tpl1(src, be, t, zd, p); if (r !== null) return r; }
			}
			const ex = OG.call(zd.exact, t);
			if (ex !== undefined) return clean(ex);
			for (const [re, order, be, plus1] of zd.tpl) {
				const m = t.match(re);
				if (m) {
					let out = be;
					order.forEach((n, i) => {
						let v = m[i + 1];
						if (plus1 && /^\d+$/.test(v)) v = String(+v + 1);
						out = out.split('%' + n + '$s').join(sub(v, zd, p));
					});
					return clean(out);
				}
			}
		}
		return null;
	}
	function writeText(n: Node, v: string) {
		n.nodeValue = v;
		MINE.set(n, v);
		S.dom++;
	}
	// Загаловак блока на галоўнай, разбіты разметкай: «Игры с меткой «<b>Ролевая стратегия</b>»».
	// Перакладаем увесь тэкст шаблонам і раскладаем вынік назад па частках, захоўваючы вылучэнне.
	function fixTitle(hl: Element): boolean {
		const nodes: Text[] = [];
		const tw = document.createTreeWalker(hl, NodeFilter.SHOW_TEXT);
		let x: Node | null;
		while ((x = tw.nextNode())) if ((x.nodeValue || '').trim()) nodes.push(x as Text);
		if (nodes.length < 2 || nodes.every((n) => MINE.get(n) === n.nodeValue)) return false;
		if (userText(hl) || hl.querySelector(USER)) return false;
		const full = (hl.textContent || '').replace(/\s+/g, ' ').trim();
		if (full === full.toUpperCase()) return false;
		const be = trText(full, 'Главная', hl);
		if (!be || be === full) return false;
		// частка, якая вылучаная асобным элементам (назва меткі), і яе пераклад
		const k = nodes.findIndex((n) => n.parentElement !== hl && n.parentElement !== null && n.parentElement.closest(HOME_LABELS) === hl);
		const mid = k >= 0 ? (nodes[k].nodeValue || '').trim() : '';
		const tmid = mid ? sub(mid) : '';
		const at = tmid ? be.indexOf(tmid) : -1;
		if (k >= 0 && at >= 0) {
			const pre = be.slice(0, at), post = be.slice(at + tmid.length);
			// калі да або пасля вылучанай часткі няма свайго тэкставага вузла — ставім новы побач з вылучэннем
			const last = nodes.length - 1;
			let box: Element = nodes[k].parentElement as Element;
			while (box.parentElement && box.parentElement !== hl) box = box.parentElement;
			const add = (text: string, before: boolean) => { if (!text) return; const tn = document.createTextNode(text); MINE.set(tn, text); hl.insertBefore(tn, before ? box : box.nextSibling); };
			nodes.forEach((n, i) => writeText(n, i < k ? (i === 0 ? pre : '') : i === k ? (n.nodeValue || '').replace(mid, tmid) : (i === k + 1 ? post : '')));
			if (k === 0) add(pre, true);
			if (k === last) add(post, false);
		} else {
			nodes.forEach((n, i) => writeText(n, i === 0 ? be : ''));
		}
		return true;
	}
	// Службовыя абзацы, разбітыя разметкай. Увесь пераклад кладзём у вузел спасылкі (каб яна засталася
	// націскальнай), астатнія вузлы ачышчаем.
	const BLOCKS = '.recommendation_reasons p.reason';
	function fixBlock(bl: Element): boolean {
		const nodes: Text[] = [];
		const tw = document.createTreeWalker(bl, NodeFilter.SHOW_TEXT);
		let x: Node | null;
		while ((x = tw.nextNode())) if ((x.nodeValue || '').trim()) nodes.push(x as Text);
		if (nodes.length < 2 || nodes.every((m) => MINE.get(m) === m.nodeValue)) return false;
		if (userText(bl) || bl.querySelector(USER)) return false;
		const full = (bl.textContent || '').replace(/\s+/g, ' ').trim();
		const z = zoneOf(bl);
		if (!z || excluded(bl, z)) return false;
		const be = trText(full, z, bl);
		if (!be || be === full) return false;
		let k = nodes.findIndex((m) => !!(m.parentElement && m.parentElement.closest('a')));
		if (k < 0) k = 0;
		nodes.forEach((m, i) => writeText(m, i === k ? be : ''));
		return true;
	}
	function fixText(n: Node) {
		const raw = n.nodeValue || '';
		if (raw.length < 2 || raw.length > 600) return;
		if (MINE.get(n) === raw) return;
		const t = raw.trim();
		if (t.length < 2 || !/\p{L}/u.test(t)) return;
		const p = n.parentElement;
		if (!p || skipEl(p) || userText(p)) return;
		if (TN && p.closest(TAGSEL)) {
			const tb = trTag(raw);
			if (tb && tb !== raw) { writeText(n, tb); return; }
			// не назва тэга (загаловак блока «Игры с меткой «4X»», «Паказаць усе меткі») — далей па зоне
		}
		// старонка гульні: даты выхаду ў блоку «Назва / Жанр / Распрацоўшчык…» стаяць проста ў блоку побач з назвай гульні —
		// там перакладаем толькі дату («21 Nov, 2026»), астатняе (назва) не чапаем
		if (p.id === 'genresAndManufacturer') { const d = dateTr(raw); if (d !== raw) writeText(n, d); return; }
		const hl = p.closest(HOME_LABELS);
		if (hl && fixTitle(hl)) return;
		// абзац, складзены з некалькіх вузлоў («<a>2 friends</a> want this game:») — перакладаем цалкам
		const bl = p.closest(BLOCKS);
		if (bl && fixBlock(bl)) return;
		// новыя старонкі (React): «Вы номинировали игры в <!-- -->0<!-- --> из <!-- -->14<!-- --> категорий!» —
		// элемент без укладзеных тэгаў, але з некалькімі тэкставымі вузламі: перакладаем увесь тэкст разам
		if (p.childElementCount === 0 && p.childNodes.length > 1 && p.closest('#StoreTemplate, #CommunityTemplate, [data-featuretarget]') && fixBlock(p)) return;
		// апісанні PEGI ідуць праз перанос радка («Violence\nIn-Game Purchases»)
		if (raw.indexOf('\n') >= 0 && p.closest(RATING)) {
			const ls = raw.split('\n');
			const tr = ls.map((x) => { const k = x.trim(); return k ? zd1(ZD['React'], k, p) : ''; });
			if (tr.every((x, i) => x !== null) && tr.some((x, i) => x !== ls[i].trim())) { writeText(n, ls.map((x, i) => x.replace(x.trim(), tr[i] as string)).join('\n')); return; }
		}
		const z = zoneOf(p);
		if (!z) return;
		if (excluded(p, z)) {
			// новыя старонкі: службовыя подпісы ўнутры спасылак на гульню («ЛІДАР ПРОДАЖАЎ ЗАРАЗ») — толькі дакладны радок слоўніка
			// старонка аплаты: назва тавару «Номинал электронной подарочной карты» — таксама толькі дакладны радок
			const ex = (z === 'SSR' || z === 'Оплата') && ZD[z] ? OG.call(ZD[z].exact, t.replace(/\s+/g, ' ')) : undefined;
			if (ex && ex.indexOf('%') < 0 && ex !== t) writeText(n, raw.replace(t, ex));
			return;
		}
		const be = trText(t, z, p);
		if (!be || be === t) return;
		writeText(n, raw.replace(t, be));
	}
	function fixNode(n: Node | null) {
		if (!n || !col) return;
		if (n.nodeType === 3) { fixText(n); return; }
		if (n.nodeType !== 1) return;
		const el = n as Element;
		if (el.tagName === 'INPUT') fixFake(el);
		if (skipEl(el)) return;
		// Галіны з кодам, палямі ўводу і рэдагаваным тэкстам абыходзім цалкам
		const tw = document.createTreeWalker(el, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, {
			acceptNode: (x: Node) => x.nodeType === 1
				? ((SKIP.test((x as Element).tagName) || (x as HTMLElement).isContentEditable === true) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_SKIP)
				: NodeFilter.FILTER_ACCEPT,
		});
		let x: Node | null;
		while ((x = tw.nextNode())) fixText(x);
		fixAttrs(el);
	}
	function fixAttr(e: Element, a: string) {
		const v = e.getAttribute && e.getAttribute(a);
		if (!v) return;
		const mine = MINEA.get(e);
		if (mine && mine[a] === v) return;
		const t = v.trim();
		if (t.length < 2) return;
		const z = zoneOf(e);
		// у полі ўводу перакладаем толькі падказку (placeholder), пра выключэнні пытаемся ў бацькі
		const ee = (a === 'placeholder' && /^(INPUT|TEXTAREA)$/.test(e.tagName) && e.parentElement) ? e.parentElement : e;
		if (!z || excluded(ee, z)) return;
		if (!(a === 'placeholder' && ee !== e) && (skipEl(e) || userText(e))) return;
		const be = trText(t, z, e);
		if (!be || be === t) return;
		e.setAttribute(a, be);
		const m = mine || {};
		m[a] = be;
		MINEA.set(e, m);
		S.dom++;
	}
	function fixAttrs(root: Element) {
		const list = [root, ...Array.from(root.querySelectorAll('[placeholder],[title],[aria-label],[data-tooltip-text]'))];
		for (const e of list) for (const a of ATTRS) fixAttr(e, a);
		root.querySelectorAll('input[onfocus], ' + FAKE_IDS).forEach(fixFake);
	}
	// Старыя старонкі Супольнасці імітуюць падказку ў полі пошуку праз value
	// і onfocus/onblur, якія параўноўваюць value з арыгінальным тэкстам
	// («Search for friends»). Калі такую падказку можна перакласці, робім з яе
	// сапраўдны placeholder: інакш поле не ачышчалася б пры фокусе.
	// Палі, дзе тую ж «падказку ў value» вешае JS старонкі (без атрыбута onfocus)
	const FAKE_IDS = '#appHubsSearchText, #SearchPlayers';
	function fixFake(e: Element) {
		const i = e as HTMLInputElement;
		if (i.tagName !== 'INPUT' || !/^(text|search)$/i.test(i.type || 'text')) return;
		const v = i.getAttribute('value') || '';
		const p = i.parentElement;
		if (!v || !p || i.value !== v) return;
		if ((i.getAttribute('onfocus') || '').indexOf("'" + v + "'") < 0 && !i.matches(FAKE_IDS)) return;
		const z = zoneOf(i);
		if (!z || excluded(p, z)) return;
		const t = v.trim();
		const be = trText(t, z, p);
		if (!be || be === t) return;
		// з апрацоўшчыкаў прыбіраем толькі сам тэкст падказкі ('Поиск друзей' → ''), астатняя іх логіка застаецца
		for (const a of ['onfocus', 'onclick', 'onblur']) {
			const js = i.getAttribute(a);
			if (!js) continue;
			const nj = js.split("'" + v + "'").join("''").split('"' + v + '"').join('""');
			if (nj !== js) i.setAttribute(a, nj);
		}
		i.value = '';
		i.setAttribute('value', '');
		i.setAttribute('placeholder', be);
		// калі скрыпт старонкі пры страце фокусу верне арыгінальную падказку ў value — прыбіраем яе
		i.addEventListener('blur', () => { if (i.value === v) i.value = ''; });
		const m = MINEA.get(i) || {};
		m.placeholder = be;
		MINEA.set(i, m);
		S.dom++;
	}
	const start = () => {
		const sm = document.getElementById('selected_msg'), sc = document.getElementById('selected_count');
		if (col && sm && sc) { sm.textContent = ''; sm.append(sc, ' выбрана.'); }
		TIME.pass0 = performance.now();
		TIME.rs1 = document.readyState;
		fixNode(document.body);
		TIME.pass1 = performance.now();
		TIME.dom1 = S.dom;
		new MutationObserver((ms) => {
			for (const m of ms) {
				if (m.type === 'characterData') fixText(m.target);
				else if (m.type === 'attributes') { if (m.attributeName) fixAttr(m.target as Element, m.attributeName); }
				else m.addedNodes.forEach(fixNode);
			}
		}).observe(document.body, { childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ATTRS });
		try { document.documentElement.setAttribute('data-be-web', '1'); } catch (e) { /* */ }
	};
	if (document.body) start(); else document.addEventListener('DOMContentLoaded', start);

	// Рэжым адладкі: ?bedebug=1 у адрасе ўключае (і запамінае для гэтага сайта), ?bedebug=0 выключае.
	let dbg = !!w.__beDebug;
	try {
		const q = location.search + location.hash;
		if (/bedebug=1/.test(q)) localStorage.setItem('beDebug', '1');
		else if (/bedebug=0/.test(q)) localStorage.removeItem('beDebug');
		dbg = dbg || localStorage.getItem('beDebug') === '1';
	} catch (e) { dbg = dbg || /bedebug=1/.test(location.search + location.hash); }
	if (dbg) document.documentElement.setAttribute('data-be-debug', '1');
	const ms = (x: any) => (typeof x === 'number' ? Math.round(x) + ' мс' : '—');
	function timing(): string {
		const t = TIME, L: string[] = [];
		let nav: any = null, fcp: any = null, scr: any[] = [];
		try { nav = performance.getEntriesByType('navigation')[0]; } catch (e) { /* */ }
		try { fcp = performance.getEntriesByType('paint').find((p: any) => p.name === 'first-contentful-paint'); } catch (e) { /* */ }
		try { scr = performance.getEntriesByType('resource').filter((r: any) => /millennium|webkit|steamloopback|preload/i.test(r.name)).slice(0, 3); } catch (e) { /* */ }
		L.push('Час ад пачатку загрузкі старонкі:');
		if (nav) {
			L.push('  адказ сервера: ' + ms(nav.responseStart) + ', HTML загружаны: ' + ms(nav.responseEnd));
			L.push('  DOM гатовы (DOMContentLoaded): ' + ms(nav.domContentLoadedEventStart) + ', поўная загрузка (load): ' + ms(nav.loadEventStart || undefined));
		}
		L.push('  першае маляванне старонкі (FCP): ' + ms(fcp && fcp.startTime));
		for (const r of scr) L.push('  файл ' + String(r.name).split('/').pop()!.slice(0, 40) + ': запыт ' + ms(r.startTime) + ' → атрыманы ' + ms(r.responseEnd));
		L.push('  скрыпт плагіна запусціўся: ' + ms(t.t0) + ' (стан старонкі: ' + t.rs0 + ')');
		L.push('  слоўнікі разабраныя: ' + ms(t.t1) + ' (+' + ms(t.t1 - t.t0) + ')');
		L.push('  код устаўлены ў старонку: ' + ms(t.main) + ' (+' + ms(t.main - t.inj) + ' на ўстаўку, выклік: ' + t.src + ')');
		L.push('  першы праход: ' + ms(t.pass0) + ' → ' + ms(t.pass1) + ' (' + ms(t.pass1 - t.pass0) + ', замен: ' + t.dom1 + ', стан: ' + t.rs1 + ')');
		return L.join('\n');
	}
	w.__beTiming = timing;
	if (dbg) window.addEventListener('load', () => setTimeout(() => console.info(LOG + '\n' + timing()), 500));
	setTimeout(() => {
		if (!dbg) return;
		const d = document.createElement('div');
		d.style.cssText = 'position:fixed;left:4px;bottom:4px;z-index:99999;background:#000d;color:#0f0;font:11px monospace;padding:4px;max-width:640px;white-space:pre-wrap;pointer-events:none';
		document.body.appendChild(d);
		const upd = () => { d.textContent = 'steam-be ' + S.v + ': ' + JSON.stringify({ tags: S.tags, get: S.get, dom: S.dom, lang: S.lang }) + '\n' + timing(); };
		upd();
		setInterval(upd, 1000);
	}, 3000);
}

// Устаўляем код у саму старонку. Сцяжок «уже ўстаўлена» ставім толькі пасля таго,
// як код сапраўды запусціўся (ён пазначае <html data-be-web-run="1">), інакш пры
// наступным выкліку main() паспрабуем зноў і напішам у кансоль, што пайшло не так.
function injectMainWorld(src: string) {
	const w = window as any;
	const root = document.documentElement;
	if (w.__beWebInjected || (root && root.getAttribute('data-be-web-run'))) { w.__beWebInjected = true; return; }
	if (!root) return;
	// Службовыя старонкі (data:, about:, акно налад Millennium) не перакладаем: на іх
	// нельга ўставіць скрыпт, а спроба выглядала ў логах як памылка плагіна.
	if (!/^https?:$/.test(location.protocol)) { w.__beWebInjected = true; return; }
	// толькі сайты Steam: на староннія старонкі ва ўбудаваным браўзеры Steam нічога не ўстаўляем
	if (!/(^|\.)(steampowered|steamcommunity)\.com$/.test(location.hostname)) { w.__beWebInjected = true; return; }
	const inj = performance.now();
	const TM = { t0: T0, rs0: RS0, t1: T1, inj, src };
	const sc = document.createElement('script');
	sc.textContent = '(' + mainWorld.toString() + ')(' + JSON.stringify(PACK) + ',' + JSON.stringify(DICT) + ',' + JSON.stringify(TAGS) + ',' + JSON.stringify(TAGNAMES) + ',' + JSON.stringify(TM) + ');'
		+ 'document.documentElement.setAttribute("data-be-web-run","1");';
	(document.head || root).appendChild(sc);
	sc.remove();
	if (root.getAttribute('data-be-web-run')) w.__beWebInjected = true;
	else if (!w.__beWebWarned) { w.__beWebWarned = true; console.warn(LOG, 'код перакладу не запусціўся на старонцы (магчыма, яго заблакавала CSP або адбылася памылка); паспрабую яшчэ раз', location.href); }
}

// Банеры на галоўнай Крамы з тэкстам, намаляваным у самой выяве: вялікі банер зверху (карцінка, часам відэа)
// і паласа пад каруселлю (takeunder). Для вядомых банераў падстаўляем беларускую версію з plugin/webview/banners
// (id — тэчка банера ў адрасе .../clusters/frontpage/<id>/... або .../clusters/takeunder/<id>/...).
// Калі Steam зменіць банер, id не супадзе — застанецца арыгінал.
type Banner = { id: string; k: string; d: string; m: string; v?: string; vm?: string };
function swapBanners() {
	if (location.hostname !== 'store.steampowered.com' || !/^\/?$/.test(location.pathname)) return;
	const list = BANNERS as Banner[];
	if (!list || !list.length) return;
	const byId = (k: string, id: string) => list.find((x) => x.k === k && x.id === id);
	const find = (u: string) => { const m = u.match(/\/clusters\/frontpage\/([0-9a-f]+)\/[^'")]*?page_bg_(mobile_)?[a-z]+\.jpg[^'")]*/); if (!m) return null; const b = byId('frontpage', m[1]); return b ? { url: m[0], data: m[2] ? b.m : b.d } : null; };
	// відэа — праз blob: адрас (ствараецца адзін раз, data: для відэа браўзер чытае горш)
	const blobs: Record<string, string> = {};
	const blobOf = (data: string) => {
		if (blobs[data]) return blobs[data];
		const i = data.indexOf(','); const bin = atob(data.slice(i + 1)); const u8 = new Uint8Array(bin.length);
		for (let j = 0; j < bin.length; j++) u8[j] = bin.charCodeAt(j);
		return (blobs[data] = URL.createObjectURL(new Blob([u8], { type: data.slice(5, data.indexOf(';')) })));
	};
	const fixVideo = (v: HTMLVideoElement) => {
		if ((v as any).__be) return;
		const srcs = [v.getAttribute('src') || ''].concat(Array.from(v.querySelectorAll('source')).map((x) => x.getAttribute('src') || ''));
		let id = '', mob = false;
		for (const u of srcs) { const m = u.match(/\/clusters\/frontpage\/([0-9a-f]+)\/[^'")]*?page_bg_(mobile_)?[a-z]+\.(?:webm|mp4)/); if (m) { id = m[1]; mob = !!m[2]; break; } }
		const b = id ? byId('frontpage', id) : undefined;
		if (!b) return;
		(v as any).__be = true;
		if (b.v) {
			v.querySelectorAll('source').forEach((x) => x.remove());
			v.src = blobOf(mob ? (b.vm as string) : b.v);
			try { v.load(); const pr = v.play(); if (pr && pr.catch) pr.catch(() => { /* */ }); } catch (e) { /* */ }
		} else {
			// беларускага відэа няма — хаваем арыгінальнае, застаецца перакладзеная карцінка пад ім
			v.pause(); v.style.display = 'none';
		}
	};
	const fixStyle = (st: HTMLStyleElement) => {
		const t = st.textContent || '';
		if (t.indexOf('/clusters/takeunder/') < 0) return;
		const r = t.replace(/url\(\s*['"]?([^'")]*\/clusters\/takeunder\/([0-9a-f]+)\/[^'")]*?takeunder_(desktop|mobile)_[a-z]+\.jpg[^'")]*)['"]?\s*\)/g, (all, _u, id, kind) => {
			const b = byId('takeunder', id);
			return b ? 'url("' + (kind === 'mobile' ? b.m : b.d) + '")' : all;
		});
		if (r !== t) st.textContent = r;
	};
	const fix = () => {
		document.querySelectorAll('.page_background_holder, .page_background_holder_mobile').forEach((e) => {
			const st = (e as HTMLElement).style;
			const bg = st.backgroundImage || '';
			const f = find(bg);
			if (f) st.backgroundImage = bg.replace(/url\(\s*['"]?[^'")]*?page_bg_[^'")]*['"]?\s*\)/, 'url("' + f.data + '")');
		});
		document.querySelectorAll('.menu_takeover_background img').forEach((e) => {
			const i = e as HTMLImageElement;
			const f = find(i.getAttribute('src') || '');
			if (f) i.setAttribute('src', f.data);
		});
		document.querySelectorAll('#takeover_videos video, video.fullscreen-bg__video, video.fullscreen-bg__video_mobile').forEach((v) => fixVideo(v as HTMLVideoElement));
		document.querySelectorAll('style').forEach((st) => fixStyle(st as HTMLStyleElement));
	};
	let queued = false;
	const run = () => { if (queued) return; queued = true; requestAnimationFrame(() => { queued = false; try { fix(); } catch (e) { /* */ } }); };
	try { fix(); } catch (e) { /* */ }
	document.addEventListener('DOMContentLoaded', run);
	// старонка можа дамаляваць банер пазней — сочым да поўнай загрузкі
	try {
		const mo = new MutationObserver(run);
		mo.observe(document.documentElement, { childList: true, subtree: true });
		window.addEventListener('load', () => { run(); setTimeout(() => mo.disconnect(), 3000); });
	} catch (e) { /* */ }
}
try { swapBanners(); } catch (e) { console.error(LOG, e); }

try { injectMainWorld('адразу'); } catch (e) { console.error(LOG, e); }

export default async function main() {
	try { injectMainWorld('main()'); } catch (e) { console.error(LOG, e); }
}
