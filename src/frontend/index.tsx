import { definePlugin, Field, DialogButton } from 'millennium';
import * as M from 'millennium';
import { useEffect, useState } from 'react';
import { VERSION, TEST_CHANNEL } from './build_info';

// Пераклад і даты ўбудоўваюцца ў Steam яшчэ пры загрузцы (гл. backend/main.lua).
// Тут — старонка налад з дыягностыкай і аўтаабнаўленне.

// ---------------------------------------------------------------------------
//  Аўтаабнаўленне. Усё (спампоўка, подпіс, SHA-256, замена файла) робіць бэкенд у be_update;
//  тут — толькі расклад праверак, кнопкі і паведамленні.
// ---------------------------------------------------------------------------

declare const backend: any;
const LOG = '[steam-be update]';
const LS_AUTO = 'steambe.autoupdate';        // '0' — выключана
const LS_LAST = 'steambe.lastcheck';         // час апошняй праверкі (мс)
// статус апошняй дзеі — толькі ў памяці гэтага сеанса Steam (пасля перазапуску ён ужо не актуальны)
let sessionStatus = '';
const LS_CHANNEL = 'steambe.channel';        // 'test' — толькі ў тэставых зборках
const LS_NOTIFIED = 'steambe.notified';      // пра якую версію ўжо паведамілі ў запасным рэжыме
const RELEASES = 'https://github.com/dzedahey/steam-pa-belarusku/releases/latest';
const PERIOD = 6 * 3600 * 1000;
const FIRST_DELAY = 2 * 60 * 1000;

const ls = {
	get: (k: string) => { try { return localStorage.getItem(k); } catch (e) { return null; } },
	set: (k: string, v: string) => { try { localStorage.setItem(k, v); } catch (e) { /* */ } },
	del: (k: string) => { try { localStorage.removeItem(k); } catch (e) { /* */ } },
};
// Выбар аўтаабнаўлення захоўваецца ў бэкендзе (%LOCALAPPDATA%\\SteamBE\\settings.txt), каб яго мог задаць
// і ўсталёўшчык. Тут — копія ў памяці; localStorage — толькі на выпадак, калі бэкенд не адказвае.
let autoCache: boolean | null = null;
const autoOn = () => (autoCache !== null ? autoCache : ls.get(LS_AUTO) !== '0');
function setAuto(on: boolean) {
	const prev = autoOn();
	autoCache = on;
	ls.set(LS_AUTO, on ? '1' : '0');
	notify();
	if (!hasBackend() || !backend.be_set_auto) return;
	// выбар павінен трапіць у settings.txt (яго чытае і сама праверка абнаўленняў); не атрымалася — вяртаем як было
	backend.be_set_auto(on).then((r: string) => {
		const rs = String(r);
		if (rs !== 'OK' && rs !== 'ERR_NOSUPPORT') {
			autoCache = prev;
			ls.set(LS_AUTO, prev ? '1' : '0');
			setStatus('не ўдалося захаваць выбар аўтаабнаўлення (' + rs + ') — паспрабуйце яшчэ раз');
		}
	}, (e: any) => {
		autoCache = prev;
		ls.set(LS_AUTO, prev ? '1' : '0');
		setStatus('не ўдалося захаваць выбар аўтаабнаўлення: ' + String(e?.message || e));
	});
}
// st.auto: '1' / '0' — выбар з файла; '' — файла яшчэ няма: пераносім туды выбар са старой версіі (localStorage)
function syncAuto(st: Record<string, string>) {
	if (st.auto === '1' || st.auto === '0') { autoCache = st.auto === '1'; ls.set(LS_AUTO, st.auto); }
	else if (st.auto === '' && autoCache === null && !st.nosupport) setAuto(ls.get(LS_AUTO) !== '0');
}
const channel = () => (TEST_CHANNEL && ls.get(LS_CHANNEL) === 'test' ? 'test' : 'stable');
const hasBackend = () => { try { return typeof backend !== 'undefined' && !!backend && !!backend.be_update; } catch (e) { return false; } };

function toast(title: string, body: string) {
	try {
		const t = (M as any).toaster;
		if (t && t.toast) { t.toast({ title, body, duration: 8000 }); return; }
	} catch (e) { /* */ }
	console.log(LOG, title, body);
}

const listeners = new Set<() => void>();
const notify = () => listeners.forEach((f) => f());
function setStatus(s: string) {
	sessionStatus = new Date().toLocaleString() + ' — ' + s;
	console.log(LOG, s);
	notify();
}

function describe(r: string): string {
	const [code, ...rest] = String(r || '').split(' ');
	const arg = rest.join(' ');
	switch (code) {
		case 'UPTODATE': return 'усталявана апошняя версія (' + arg + ')';
		case 'INSTALLED': return 'версія ' + arg + ' спампавана і праверана — уключыцца пры наступным запуску Steam';
		case 'PENDING': return 'версія ' + arg + ' ужо спампавана і чакае перазапуску Steam (новыя абнаўленні — пасля перазапуску)';
		case 'RESTART': return 'файл плагіна ўжо змяняўся за гэты сеанс (абнаўленне або адкат) — перазапусціце Steam';
		case 'ERR_STATE': return 'файл плагіна не адпавядае запушчанай версіі — перазапусціце Steam';
		case 'DECLINED': return 'версія ' + arg + ' прапушчана, бо вы вярнулі папярэднюю (усталяваць можна кнопкай «Праверыць»)';
		case 'NOTIFY': return 'выйшла версія ' + arg + '. Аўтаматычна ўсталяваць яе не атрымаецца (гэтая версія Millennium не дае праверыць подпіс) — спампуйце ўручную са старонкі выпускаў.';
		case 'BUSY': return 'праверка ўжо ідзе';
		case 'OFF': return 'аўтаабнаўленне выключана';
		case 'ERR_NET': return /http 404/.test(arg) ? 'на GitHub пакуль няма звестак пра абнаўленні' : 'няма сувязі з GitHub (' + arg + ')';
		case 'ERR_SIG': return 'ПАМЫЛКА: подпіс звестак пра абнаўленне не сышоўся — нічога не ўсталявана';
		case 'ERR_FORMAT': return 'ПАМЫЛКА: незразумелыя звесткі пра абнаўленне — нічога не ўсталявана';
		case 'ERR_HASH': return 'ПАМЫЛКА: спампаваны файл не супадае з падпісанымі звесткамі — нічога не ўсталявана';
		case 'ERR_WRITE': return 'не ўдалося запісаць файл плагіна (' + arg + ') — магчыма, няма правоў на запіс у папку плагінаў. Абнавіце ўсталёўшчыкам.';
		case 'ERR_NOPLUGIN': return 'не знойдзены файл плагіна';
		case 'ERR_NOSUPPORT': return 'гэтая версія Millennium не падтрымлівае аўтаабнаўленне';
		case 'ERR_NOKEY': return 'аўтаабнаўленне выключана ў гэтай зборцы';
		default: return 'не ўдалося праверыць: ' + r;
	}
}

let busy = false;
async function checkUpdate(manual: boolean): Promise<void> {
	if (busy) return;
	if (!hasBackend()) { setStatus('бэкенд плагіна недаступны'); return; }
	busy = true;
	notify();
	try {
		ls.set(LS_LAST, String(Date.now()));
		setStatus('правяраю…');
		const r: string = await backend.be_update(manual, channel());
		setStatus(describe(r));
		if (String(r).startsWith('INSTALLED ')) {
			toast('Спампавана версія ' + String(r).slice(10), 'Уключыцца пасля перазапуску Steam');
		}
		if (String(r).startsWith('NOTIFY ')) {
			const v = String(r).slice(7);
			if (manual || ls.get(LS_NOTIFIED) !== v) {
				ls.set(LS_NOTIFIED, v);
				toast('Выйшла версія ' + v, 'Спампуйце са старонкі выпускаў');
			}
		}
	} catch (e) {
		setStatus('не ўдалося праверыць: ' + String((e as any)?.message || e));
	} finally {
		busy = false;
		notify();
	}
}

function openReleases() {
	try {
		const sc = (window as any).SteamClient;
		if (sc && sc.System && sc.System.OpenInSystemBrowser) { sc.System.OpenInSystemBrowser(RELEASES); return; }
	} catch (e) { /* */ }
	try { window.open(RELEASES, '_blank'); } catch (e) { /* */ }
}

// што паказваць, пакуль у гэтым сеансе нічога не рабілі: бягучы стан з бэкенда + час апошняй праверкі
function idleStatus(st: Record<string, string>): string {
	if (st.nosupport) return 'гэтая версія Millennium не падтрымлівае аўтаабнаўленне';
	if (st.pending) return 'версія ' + st.pending + ' спампавана — уключыцца пасля перазапуску Steam';
	const last = Number(ls.get(LS_LAST) || 0);
	const when = last ? 'апошняя праверка: ' + new Date(last).toLocaleString() : 'яшчэ не правяралася';
	return st.declined ? when + '. Версія ' + st.declined + ' прапушчана (вы вярнулі папярэднюю).' : when;
}

function parseState(s: string): Record<string, string> {
	const o: Record<string, string> = {};
	String(s || '').split(';').forEach((kv) => { const i = kv.indexOf('='); if (i > 0) o[kv.slice(0, i)] = kv.slice(i + 1); });
	return o;
}

function startUpdater() {
	if (hasBackend()) backend.be_state().then((s: string) => syncAuto(parseState(s)), () => { /* */ });
	setTimeout(() => {
		if (!hasBackend()) return;
		backend.be_state().then((s: string) => {
			const st = parseState(s);
			if (st.updated) toast('Steam па-беларуску', 'Пераклад абноўлены да версіі ' + st.updated + '.');
		}, () => { /* */ });
	}, 15000);
	const tick = () => {
		if (!autoOn()) return;
		const last = Number(ls.get(LS_LAST) || 0);
		if (Date.now() - last >= PERIOD - 60000) checkUpdate(false);
	};
	setTimeout(tick, FIRST_DELAY);
	setInterval(tick, 15 * 60 * 1000);   // раз на 15 хвілін: ці не прайшло 6 гадзін
}

// ---------------------------------------------------------------------------
//  Старонка налад
// ---------------------------------------------------------------------------

const Updates = () => {
	const [, force] = useState(0);
	const [st, setSt] = useState<Record<string, string>>({});
	const reload = () => { if (hasBackend()) backend.be_state().then((s: string) => { const o = parseState(s); syncAuto(o); setSt(o); }, () => { /* */ }); };
	useEffect(() => {
		const f = () => { force((x) => x + 1); reload(); };
		listeners.add(f);
		reload();
		return () => { listeners.delete(f); };
	}, []);
	const on = autoOn();
	const test = channel() === 'test';
	const canRollback = !!st.pending || (st.backups || '').split(',').some((v) => v && v !== VERSION);
	return (
		<>
			<Field label="Версія плагіна" description={VERSION + (st.pending ? ' (спампавана ' + st.pending + ' — уключыцца пасля перазапуску Steam)' : '')} />
			<Field label="Аўтаабнаўленне" description={on ? 'уключана: праверка праз 2 хвіліны пасля запуску Steam і кожныя 6 гадзін' : 'выключана'}>
				<DialogButton onClick={() => { setAuto(!on); force((x) => x + 1); }}>
					{on ? 'Выключыць' : 'Уключыць'}
				</DialogButton>
			</Field>
			<Field label="Праверыць абнаўленні" description={sessionStatus || idleStatus(st)}>
				<DialogButton disabled={busy} onClick={() => checkUpdate(true)}>{busy ? 'Правяраю…' : 'Праверыць'}</DialogButton>
			</Field>
			<Field label="Старонка выпускаў" description="усе версіі, апісанні змен і файлы для ўсталявання ўручную">
				<DialogButton onClick={openReleases}>Адкрыць</DialogButton>
			</Field>
			{canRollback && (
				<Field label="Вярнуць папярэднюю версію"
					description={(st.pending ? 'адмяніць спампаванае абнаўленне ' + st.pending : 'захаваныя копіі: ' + st.backups) + '. Адкочаная версія больш не ставіцца аўтаматычна.'}>
					<DialogButton onClick={() => {
						backend.be_rollback().then((r: string) => {
							setStatus(String(r).startsWith('OK ') ? 'вернута версія ' + String(r).slice(3) + ' — перазапусціце Steam'
								: String(r).startsWith('RESTART') ? 'файл плагіна ўжо змяняўся за гэты сеанс — спачатку перазапусціце Steam'
								: String(r).startsWith('ERR_BACKUP_CHANGED') ? 'рэзервовая копія змянілася або пашкоджана — адкат не выкананы. Усталюйце патрэбную версію ўручную са старонкі выпускаў.'
								: 'не ўдалося вярнуць: ' + r);
						});
					}}>Вярнуць</DialogButton>
				</Field>
			)}
			{TEST_CHANNEL && (
				<Field label="Тэставы канал (толькі ў тэставай зборцы)" description={test ? 'уключаны: выпуск з тэгам test' : 'выключаны'}>
					<DialogButton onClick={() => { if (test) ls.del(LS_CHANNEL); else ls.set(LS_CHANNEL, 'test'); force((x) => x + 1); }}>
						{test ? 'Выключыць' : 'Уключыць'}
					</DialogButton>
				</Field>
			)}
		</>
	);
};

const Settings = () => {
	const w = window as any;
	const s = w.__beStats || {};
	const d = new Date(2026, 7, 30);
	return (
		<>
			<Updates />
			<Field label="Пераклад" description={w.__beTok ? 'уключаны' : 'НЕ ўключаны'} />
			<Field label="Файлаў тэксту апрацавана" description={String(s.files ?? '?')} />
			<Field label="Радкоў падменена" description={`${s.applied ?? '?'} (у пакеце: ${s.total ?? '?'})`} />
			<Field label="Прапушчана (Valve змяніла тэкст)" description={(s.skipped || []).join(', ') || 'няма'} />
			<Field label="Даты" description={w.__beDates ? 'уключаны' : 'НЕ ўключаны'} />
			<Field label="Праверка даты" description={d.toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'long' }) + ' / ' + d.toLocaleDateString(undefined, { day: 'numeric', month: 'short' })} />
		</>
	);
};

export default definePlugin(() => {
	try { startUpdater(); } catch (e) { console.error(LOG, e); }
	return { title: 'Steam па-беларуску by Dzed Ahey', icon: <span>BY</span>, content: <Settings /> };
});
