import { definePlugin, Field } from 'millennium';

// Пераклад і даты ўбудоўваюцца ў Steam яшчэ пры загрузцы (гл. backend/main.lua).
// Тут толькі старонка налад з дыягностыкай.
const Settings = () => {
	const w = window as any;
	const s = w.__beStats || {};
	const d = new Date(2026, 7, 30);
	return (
		<>
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
	return { title: 'Steam па-беларуску by Dzed Ahey', icon: <span>BY</span>, content: <Settings /> };
});
