Толькі для Steam для Windows. Працуе праз [Millennium](https://steambrew.app) — усталёўшчык паставіць яго сам. Інструкцыя — у [README](https://github.com/dzedahey/steam-pa-belarusku#readme).

**Што спампоўваць**

- `{BASE}_ustalyoushchyk.zip` — усталёўшчык (прасцей).
- `{BASE}_uruchnuyu.zip` — файл плагіна для ўсталявання ўручную.

Файлы `.star`, `latest.json` і `latest.json.sig` патрэбныя для аўтаабнаўлення, спампоўваць іх не трэба. З 0.8.2 і старэйшых версій трэба адзін раз абнавіцца ўручную, далей пераклад абнаўляецца сам.

**Што новага ў {VERSION}**

{CHANGES}

Поўны спіс змен — у [CHANGELOG.md](https://github.com/dzedahey/steam-pa-belarusku/blob/main/CHANGELOG.md).

**Кантрольныя сумы SHA-256**

| Файл | SHA-256 |
|---|---|
{SUMS}

Праверыць у PowerShell: `Get-FileHash .\назва_файла`. Подпіс выпуску можна праверыць скрыптам `verify_release.ps1` (гл. README).

---

*Па-руску.* Только для Steam для Windows. Работает через [Millennium](https://steambrew.app) — установщик поставит его сам. Инструкция — в [README](https://github.com/dzedahey/steam-pa-belarusku/blob/main/README.ru.md). Установщик — `…_ustalyoushchyk.zip`, ручная установка — `…_uruchnuyu.zip`. Файлы `.star`, `latest.json` и `latest.json.sig` нужны для автообновления, скачивать их не надо. Начиная с 0.8.3 перевод обновляется сам; с 0.8.2 и более старых версий нужно один раз обновиться вручную. Контрольные суммы — в таблице выше.
