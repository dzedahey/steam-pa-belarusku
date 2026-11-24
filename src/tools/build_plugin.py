# -*- coding: utf-8 -*-
r"""
Сборка плагина «Steam па-беларуску by Dzed Ahey» из таблицы перевода.

Что делает:
  1. Читает steam_be_strings.xlsx (колонка «Беларуская» на всех листах).
  2. Собирает из неё файлы перевода внутри папки plugin\:
         plugin\webview\webpack.json, dictpack.json, tagspack.json, tagnames.json — магазин и сообщество;
         plugin\inject\tokens.built.js — сам клиент Steam (библиотека, друзья, настройки…);
         plugin\backend\main.lua      — код, который встраивает перевод в Steam.
     Пустые ячейки «Беларуская» просто пропускаются: там останется язык Steam.
  3. Компилирует плагин программой starlight (лежит в plugin\tools\starlight\):
         build\plugin\by.dzedahey.steam-be.star
  4. Проверяет таблицу и результат и пишет, если что-то не так.
  5. Если ошибок нет — собирает в build\release два архива для раздачи:
     • ..._uruchnuyu.zip      — файл плагина + инструкция по ручной установке;
     • ..._ustalyoushchyk.zip — установщик exe + инструкция к нему
       (exe собирается программой Inno Setup 7 или 6, она должна быть установлена).
     Всё собирается сначала во временную папку; прежние архивы и плагин заменяются
     только если новая сборка прошла полностью. Номер версии — в строке VERSION ниже.

Запуск: двойной щелчок по «Собрать плагин.bat»
(или в консоли: python build_plugin.py).

Ключ --install (или «Собрать и установить в мой Steam.bat»): после сборки ещё и
кладёт плагин в ваш Steam. Steam при этом должен быть закрыт.
"""
import collections, io, json, os, platform, re, shutil, subprocess, sys, zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
XLSX = os.path.join(ROOT, "steam_be_strings.xlsx")
PLUGIN = os.path.join(ROOT, "plugin")
STARLIGHT_DIR = os.path.join(PLUGIN, "tools", "starlight")
BUILD = os.path.join(ROOT, "build")
BUILD_PLUGIN = os.path.join(BUILD, "plugin")
RELEASE = os.path.join(BUILD, "release")
INSTALLER_DIR = os.path.join(ROOT, "tools", "installer")
DOCS_DIR = os.path.join(ROOT, "tools", "release")
ISS_NAME = "SteamBE.iss"

VERSION = "0.8.2"   # версия плагина: попадает в плагин, имена архивов, установщик и инструкции
PLUGIN_ID = "by.dzedahey.steam-be"          # не менять: по нему Millennium узнаёт плагин
PLUGIN_NAME = "Steam па-беларуску by Dzed Ahey"
PLUGIN_DESC = "Неафіцыйны беларускі пераклад кліента, крамы і супольнасці Steam. Аўтар: Dzed Ahey."
STAR_NAME = PLUGIN_ID + ".star"
NAME_PREFIX = "Steam_pa-belarusku_v"
BASE_NAME = NAME_PREFIX + VERSION

LANGS = ["english", "russian", "ukrainian", "polish"]   # колонки C–F таблицы
CLIENT_SHEETS = ["steamui", "shared", "friendsui", "steampops"]
# Листы, без которых сборка не пойдёт (если лист пропал или переименован — перевод молча уменьшится)
WEB_SHEETS = ["web_store_main", "web_store_loyalty", "web_store_ui", "web_store_sales", "web_store_marketing",
              "web_comm_main", "web_comm_market", "web_shared", "web_comm_ssr", "web_comm_market_new",
              "web_comm_workshop", "web_store_new", "web_comm_edit"]
REQUIRED_SHEETS = CLIENT_SHEETS + WEB_SHEETS + ["web_dict", "tags"]
EXTRA_HASHES = os.path.join(ROOT, "tools", "client_extra_hashes.json")
LAST_STATS = os.path.join(BUILD, "last_stats.json")
OPENPYXL_REQ = "openpyxl>=3.1,<4"
COMM_SSR_SHEETS = ["web_comm_ssr", "web_shared"]

# Строки словаря, которые действуют только внутри определённого элемента страницы
DICT_SELS = {
    "dict.home.009": "#label_top_new_releases",
    "dict.app.064": ".communitylink_points_shop_item",
    "dict.app.075": ".steam_curators_block",
    "dict.app.021": "#queueActionsCtn",
    "dict.app.091": ".app_tag_modal_right",
    "dict.profile.025": ".showcase_stat",
    "dict.profile.073": "#reportAbuseModal .btn_green_white_innerfade",
    "dict.guides.156": ".filterOption, .tag_category_container",   # польскае «Poradniki» тут — «Праходжанні», а не «Кіраўніцтвы»
    # шаблоны і кароткія словы кіраўніцтваў, якія па-за сваім месцам зачапілі б чужы тэкст
    "dict.guides.002": ".apphub_ResponsiveMenuItem",               # «Достижения %1$s»
    "dict.guides.021": ".guides_home_view_all_link",               # «View All (%1$s)»
    "dict.guides.022": ".guides_home_section_title",               # «Popular Categories (%1$s)»
    "dict.guides.023": ".guide_home_category_count",               # «%1$s Guides» (інакш «More About Guides» → «Кіраўніцтваў: More About»)
    "dict.guides.151": ".searchTextContainer",                     # «Search %1$s Guides»
    "dict.guides.153": "#create_guide_btn",                        # «Create your own»
    "dict.guides.154": "#EditorTab",                               # «Edit» → «Рэдагаванне» толькі на ўкладцы рэдактара
    "dict.guides.155": "#URLInsertForm",                           # «URL» / «Ссылка»
    "dict.app.200": ".franchise_notice",                           # «Посмотрите все игры из коллекции %1$s в Steam»
    # 0.8.1: апісанні PEGI (англійскія словы ва ўсіх калонках) — толькі ў блоку рэйтынгу
    "dict.react.021": '[data-featuretarget="game-rating-block"]',
    "dict.react.022": '[data-featuretarget="game-rating-block"]',
    "dict.react.023": '[data-featuretarget="game-rating-block"]',
    "dict.react.024": '[data-featuretarget="game-rating-block"]',
    "dict.react.025": '[data-featuretarget="game-rating-block"]',
    "dict.react.026": '[data-featuretarget="game-rating-block"]',
    "dict.react.027": '[data-featuretarget="game-rating-block"]',
    "dict.react.028": '[data-featuretarget="game-rating-block"]',
    "dict.react.029": '[data-featuretarget="game-rating-block"]',
    "dict.react.041": "foreignObject",                             # «Dwarf» на дыяграме «Вынікаў года»
    "dict.app.201": ".game_area_purchase_game",                    # «Сыграть в %1$s»
}
# Строки словаря, где в некоторых языках число надо увеличить на 1 (1=en 2=ru 3=uk 4=pl)
DICT_PLUS1 = {"dict.app.042": [1, 2]}



def say(msg=""):
    print(msg, flush=True)


def need_openpyxl():
    try:
        import openpyxl  # noqa
        return
    except ImportError:
        pass
    say("Не хватает модуля openpyxl, устанавливаю (нужен интернет)...")
    subprocess.call([sys.executable, "-m", "pip", "install", "--user", OPENPYXL_REQ])
    try:
        import openpyxl  # noqa
    except ImportError:
        say("Не получилось установить openpyxl. Выполните вручную в консоли:")
        say('    python -m pip install "%s"' % OPENPYXL_REQ)
        sys.exit(1)


def fnv(s):
    """Тот же хэш, что считает плагин в Steam (FNV-1a по символам UTF-16)."""
    h = 0x811c9dc5
    b = s.encode("utf-16-le")
    for i in range(0, len(b), 2):
        h ^= b[i] | (b[i + 1] << 8)
        h = (h * 0x01000193) & 0xffffffff
    return format(h, "x")


PH = re.compile(r"%\d+\$[sd]|%[sd]|<\d+>|</\d+>|\{[A-Za-z0-9_]+\}")
TAG = re.compile(r"<(/?)(\d+)>")


def placeholders(s):
    return collections.Counter(PH.findall(s or ""))


def tags_ok(s):
    """<1>…</1>: каждый тег закрыт, и в правильном порядке."""
    st = []
    for close, n in TAG.findall(s or ""):
        if not close:
            st.append(n)
        elif not st or st.pop() != n:
            return False
    return not st


# ---------------------------------------------------------------------------
#  Чтение таблицы
# ---------------------------------------------------------------------------
def read_book(path):
    import openpyxl
    wb = openpyxl.load_workbook(path, read_only=True)
    book = {}
    for name in wb.sheetnames:
        rows = []
        for r in wb[name].iter_rows(values_only=True):
            rows.append(tuple(r) + (None,) * max(0, 9 - len(r)))
        book[name] = rows
    wb.close()
    return book


def be_rows(book, sheet):
    """Строки листа с заполненным переводом: (ID, [en, ru, uk, pl], be)."""
    for r in book.get(sheet, [])[1:]:
        key, be = r[1], r[6]
        if not key or be is None or str(be).strip() == "":
            continue
        src = [x if isinstance(x, str) else ("" if x is None else str(x)) for x in r[2:6]]
        yield str(key), src, str(be)


def check_row(sheet, key, src, be, warnings):
    """Сверяет подстановки (%1$s, %d, <1>…</1>, {name}) перевода с оригиналами.
    Языки иногда расходятся между собой (например, в русском %1$s спрятано в форме слова),
    поэтому ошибка — только если перевод не совпал НИ С ОДНИМ оригиналом,
    или потерял подстановку, которая есть во ВСЕХ оригиналах, или перепутал теги."""
    srcs = [placeholders(s) for s in src if s]
    if not srcs:
        return
    pb = placeholders(be)
    if not any(pb == x for x in srcs):
        common = srcs[0].copy()
        for x in srcs[1:]:
            common &= x
        lost = sorted((common - pb).elements())
        extra = sorted(set(pb) - set().union(*srcs))
        msg = []
        if lost:
            msg.append("потеряно: " + " ".join(lost))
        if extra:
            msg.append("лишнее: " + " ".join(extra))
        warnings.append("%s / %s: подстановки не совпадают с оригиналом (%s)" % (sheet, key, "; ".join(msg) or "другое количество"))
    if pb and any(x for x in srcs if "<" in "".join(x)) and not tags_ok(be):
        warnings.append("%s / %s: теги <1>…</1> не закрыты или перепутаны" % (sheet, key))


# ---------------------------------------------------------------------------
#  Пакеты перевода
# ---------------------------------------------------------------------------
def build_web_pack(book, warnings, conflicts):
    pack = collections.defaultdict(list)
    seen = {}
    sheets = [s for s in book if s.startswith("web_") and s != "web_dict"] + ["shared"]
    for s in sheets:
        for key, src, be in be_rows(book, s):
            hs = [fnv(x) if x else "" for x in src]
            if not any(hs):
                continue
            check_row(s, key, src, be, warnings)
            for i, h in enumerate(hs):           # один и тот же оригинал (ID + текст) — разные переводы?
                if h:
                    prev = seen.setdefault((key, i, h), (be, s))
                    if prev[0] != be:
                        conflicts.add((key, prev[1], prev[0], s, be))
            v = [be] + hs
            if v not in pack[key]:
                pack[key].append(v)
    return pack


def build_dict_pack(book, warnings):
    D = collections.defaultdict(list)
    for r in book.get("web_dict", [])[1:]:
        zone, _id, en, ru, uk, pl, be = r[:7]
        if not zone or be is None or str(be).strip() == "":
            continue
        src = [(x or "").strip() if isinstance(x, str) else ("" if x is None else str(x)) for x in (en, ru, uk, pl)]
        check_row("web_dict", _id or "?", src, str(be).strip(), warnings)
        D[zone].append([str(be).strip()] + src + [DICT_SELS.get(_id, ""), DICT_PLUS1.get(_id, [])])
    return D


def build_tags(book):
    T, N = {}, {l: {} for l in LANGS}
    for r in book.get("tags", [])[1:]:
        if not r[1]:
            continue
        tid = str(r[1])
        if r[6]:
            T[tid] = str(r[6]).strip()
        for i, l in enumerate(LANGS):
            if r[2 + i]:
                N[l][str(r[2 + i]).strip().lower()] = int(tid)
    return T, N


F0, F1, F2 = chr(0xE000), chr(0xE001), chr(0xE002)


def js_enc(s):
    return s.replace("\\", F1).replace("$", F0).replace("`", F2)


def lua_ascii(text):
    """Кадуе тэкст у чысты ASCII для main.lua (starlight --release псуе UTF-8 у Lua-кодзе).
    93 самыя частыя 2-байтавыя паслядоўнасці UTF-8 (кірыліца) -> «~» + адзін сімвал (той жа памер),
    астатнія байты > 127 -> «~~» + два hex-сімвалы. Сімвала «~» у кодзе перакладу няма (правяраецца).
    Вяртае (табліца для D() у main.lua.tpl у выглядзе Lua-радка з \\ddd, закадаваны тэкст)."""
    if "~" in text:
        raise ValueError("у кодзе для library.js ёсць сімвал ~ — ён заняты кадаваннем")
    b = text.encode("utf-8")
    cnt = collections.Counter()
    i = 0
    while i < len(b):
        if b[i] >= 0xC0 and i + 1 < len(b) and 0x80 <= b[i + 1] < 0xC0 and (b[i] < 0xE0):
            cnt[b[i:i + 2]] += 1
            i += 2
        else:
            i += 1
    codes = [chr(c) for c in range(33, 126)]                     # 93 коды: «!» … «}»
    top = [k for k, _ in cnt.most_common(len(codes))]
    m = {k: "~" + codes[n] for n, k in enumerate(top)}
    out = []
    i = 0
    while i < len(b):
        x = b[i]
        if x < 0x80:
            out.append(chr(x)); i += 1; continue
        k = b[i:i + 2]
        if k in m and x < 0xE0:
            out.append(m[k]); i += 2; continue
        out.append("~~%02x" % x); i += 1
    table = "".join("\\%d\\%d" % (k[0], k[1]) for k in top) + "\\0\\0" * (len(codes) - len(top))
    return table, "".join(out)


def js_dec(s):
    return s.replace(F1, "\\").replace(F0, "$").replace(F2, "`")


def extra_hashes(problems):
    """tools\\client_extra_hashes.json — дополнительные отпечатки оригиналов (см. описание внутри файла)."""
    if not os.path.isfile(EXTRA_HASHES):
        return {}
    try:
        return json.load(io.open(EXTRA_HASHES, encoding="utf-8")).get("keys", {})
    except Exception as e:
        problems.append("не удалось прочитать tools\\client_extra_hashes.json: %s" % e)
        return {}


def build_client_pack(book, warnings, conflicts, problems):
    P = collections.defaultdict(list)
    seen = {}
    for s in CLIENT_SHEETS:
        for key, src, be in be_rows(book, s):
            hs = {LANGS[i]: fnv(x) for i, x in enumerate(src) if x}
            if not hs:
                continue
            check_row(s, key, src, be, warnings)
            for l, h in hs.items():
                prev = seen.setdefault((key, l, h), (be, s))
                if prev[0] != be:
                    conflicts.add((key, prev[1], prev[0], s, be))
            same = [v for v in P[key] if v[0] == be]
            if same:
                for l, h in hs.items():
                    if h not in same[0][1].setdefault(l, []):
                        same[0][1][l].append(h)
            else:
                P[key].append([be, {l: [h] for l, h in hs.items()}])
    # дополнительные отпечатки из отдельного файла (добавляются к первому варианту перевода)
    for key, hs in extra_hashes(problems).items():
        if key not in P:
            continue
        cur = P[key][0][1]
        for l, lst in hs.items():
            for h in lst:
                if h not in cur.setdefault(l, []):
                    cur[l].append(h)
    return P


def build_comm_pack(book):
    P2 = collections.defaultdict(list)
    for s in COMM_SSR_SHEETS:
        for key, src, be in be_rows(book, s):
            v = [be] + [fnv(x) if x else "" for x in src]
            if any(v[1:]) and v not in P2[key]:
                P2[key].append(v)
    return P2


H6 = 36 ** 6


def b36(hexh):
    """Адбітак FNV для плагіна: астача ад дзялення на 36^6, запісаная 36-коднымі лічбамі (да 6 знакаў).
    Так яго лічаць і tokens.js, і preload.ts: (x % 2176782336).toString(36)."""
    n = int(hexh, 16) % H6
    d = "0123456789abcdefghijklmnopqrstuvwxyz"
    out = ""
    while True:
        n, r = divmod(n, 36)
        out = d[r] + out
        if not n:
            return out


def compact_client(P):
    """Кампактны пакет для library.js: {ключ: [[пераклад, "адбітак адбітак …"], …]}.
    Адбіткі ўсіх моў у адным радку праз прабел: мова для праверкі не патрэбная."""
    out = {}
    for key, variants in P.items():
        out[key] = []
        for be, hs in variants:
            seen = []
            for lst in hs.values():
                for h in lst:
                    x = b36(h)
                    if x not in seen:
                        seen.append(x)
            out[key].append([be, " ".join(seen)])
    return out


def compact_comm(P2):
    out = {}
    for key, variants in P2.items():
        out[key] = []
        for v in variants:
            seen = []
            for h in v[1:]:
                if h and b36(h) not in seen:
                    seen.append(b36(h))
            out[key].append([v[0], " ".join(seen)])
    return out


def dump(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def write_text(path, text):
    with io.open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


def check_cycles(web, D, warnings):
    """Ищет переводы, которые на странице перевелись бы ещё раз во что-то другое
    (как было с ОК → OK → ОК). Повторно плагин свой текст уже не трогает, но такие
    строки — признак разнобоя в таблице, их стоит согласовать."""
    found = []
    for col in range(1, 5):                      # язык страницы: en, ru, uk, pl
        cnt = collections.defaultdict(collections.Counter)
        for variants in web.values():
            for v in variants:
                if v[col]:
                    cnt[v[col]][v[0]] += 1
        RV = {}
        for hv, c in cnt.items():
            (be, n), = c.most_common(1)
            if list(c.values()).count(n) == 1:
                RV[hv] = be
        common = {row[col]: row[0] for row in D.get("Общее", []) if row[col] and not row[5]}
        for zone, rows in D.items():
            exact = {row[col]: row[0] for row in rows if row[col] and not row[5]}
            for src, be in exact.items():
                nxt = exact.get(be) or common.get(be) or RV.get(fnv(be))
                if nxt and nxt != be:
                    found.append("словарь «%s»: %s → %s → %s" % (zone, src, be, nxt))
        for hv, be in RV.items():
            nxt = RV.get(fnv(be))
            if nxt and nxt != be:
                found.append("строки с ID (%s): … → %s → %s" % (LANGS[col - 1], be, nxt))
    for f in sorted(set(found)):
        warnings.append("цикл перевода: " + f)


def generate(book, problems, warnings):
    """Пишет все файлы перевода в папку plugin. Возвращает статистику."""
    stats = {}
    conflicts = set()
    web = build_web_pack(book, warnings, conflicts)
    D = build_dict_pack(book, warnings)
    T, N = build_tags(book)
    P = build_client_pack(book, warnings, conflicts, problems)
    P2 = build_comm_pack(book)
    for key, s1, be1, s2, be2 in sorted(conflicts):
        warnings.append("%s: один и тот же оригинал переведён по-разному — «%s» (%s) и «%s» (%s); в Steam победит первый"
                        % (key, be1, s1, be2, s2))
    check_cycles(web, D, warnings)
    stats["клиент Steam"] = len(P)
    stats["магазин и сообщество"] = len(web) - 1 + len(P2)
    stats["словарь старых страниц"] = sum(len(v) for v in D.values())
    stats["метки игр"] = len(T)

    wv = os.path.join(PLUGIN, "webview")
    webc = {k: [[v[0]] + [b36(h) if h else "" for h in v[1:]] for v in vs] for k, vs in web.items()}
    write_text(os.path.join(wv, "webpack.json"), dump(webc))
    write_text(os.path.join(wv, "dictpack.json"), dump(D))
    # Банеры галоўнай Крамы: plugin\webview\banners\<id>.jpg (1850×450) і <id>_mobile.jpg (500×350),
    # id — тэчка банера ў адрасе .../clusters/frontpage/<id>/page_bg_*.jpg
    import base64
    bdir = os.path.join(wv, "banners")
    banners = []
    if os.path.isdir(bdir):
        for fn in sorted(os.listdir(bdir)):
            m = re.match(r"^([0-9a-f]+)\.jpg$", fn)
            if not m:
                continue
            mob = os.path.join(bdir, m.group(1) + "_mobile.jpg")
            enc = lambda p: "data:image/jpeg;base64," + base64.b64encode(open(p, "rb").read()).decode("ascii")
            banners.append({"id": m.group(1), "d": enc(os.path.join(bdir, fn)), "m": enc(mob) if os.path.exists(mob) else enc(os.path.join(bdir, fn))})
    write_text(os.path.join(wv, "bannerpack.json"), dump(banners))
    stats["банеры галоўнай"] = len(banners)
    write_text(os.path.join(wv, "tagspack.json"), dump(T))
    write_text(os.path.join(wv, "tagnames.json"), dump(N))

    inj = os.path.join(PLUGIN, "inject")
    tpl = io.open(os.path.join(inj, "tokens.js"), encoding="utf-8").read()
    if "@@PACK@@" not in tpl or "@@PACK2@@" not in tpl or "S.total=" not in tpl:
        problems.append("plugin\\inject\\tokens.js повреждён (нет меток @@PACK@@ / @@PACK2@@)")
        return stats
    tok = (tpl.replace("@@PACK@@", js_enc(dump(compact_client(P))))
              .replace("@@PACK2@@", js_enc(dump(compact_comm(P2)))))
    dates = io.open(os.path.join(inj, "dates.js"), encoding="utf-8").read().replace("\r", "").replace("\n", "")
    for name, js in (("tokens", tok), ("dates", dates)):
        if "$" in js or "\\" in js or "]==]" in js:
            problems.append("в собранном %s.js остались запрещённые символы ($, \\ или ]==])" % name)
    write_text(os.path.join(inj, "tokens.built.js"), tok)

    lua = io.open(os.path.join(inj, "main.lua.tpl"), encoding="utf-8").read()
    lua = re.sub(r"(?m)^[ \t]*--[^\n]*\n", "", lua)          # каментары (у іх кірыліца) у плагін не ідуць
    codec, inject = lua_ascii(dates + "," + tok + ",window.LocalizationManager=")
    lua = lua.replace("@@CODEC@@", codec).replace("@@INJECT@@", inject)
    bad = sorted({c for c in lua if ord(c) > 126})
    if bad or "]==]" in inject:
        problems.append("main.lua: засталіся не-ASCII сімвалы або ]==] (%s)" % "".join(bad[:20]))
    write_text(os.path.join(PLUGIN, "backend", "main.lua"), lua)

    # millennium.toml: название, версия, описание
    toml_p = os.path.join(PLUGIN, "millennium.toml")
    toml = io.open(toml_p, encoding="utf-8").read()
    toml = re.sub(r'(?m)^name = ".*"$', 'name = "%s"' % PLUGIN_NAME, toml, count=1)
    toml = re.sub(r'(?m)^version = ".*"$', 'version = "%s"' % VERSION, toml, count=1)
    toml = re.sub(r'(?m)^description = ".*"$', 'description = "%s"' % PLUGIN_DESC, toml, count=1)
    write_text(toml_p, toml)

    # preload.ts: нумар версіі для адладкі старонак (?bedebug=1) — той жа, што ў VERSION
    pre_p = os.path.join(PLUGIN, "webview", "preload.ts")
    with io.open(pre_p, encoding="utf-8", newline="") as fh:
        pre = fh.read()
    pre2 = re.sub(r"(__beWeb = \{ v: ')[^']*(')", lambda m: m.group(1) + VERSION + m.group(2), pre, count=1)
    if pre2 == pre and ("v: '%s'" % VERSION) not in pre:
        problems.append("plugin\\webview\\preload.ts: не найдено место для номера версии (v: '...')")
    elif pre2 != pre:
        with io.open(pre_p, "w", encoding="utf-8", newline="") as fh:
            fh.write(pre2)
    return stats


# ---------------------------------------------------------------------------
#  Компиляция плагина (starlight)
# ---------------------------------------------------------------------------
def find_starlight():
    sysname = platform.system().lower()
    names = ["starlight-win32-x64.exe"] if sysname == "windows" else ["starlight-linux-x64"]
    for n in names:
        p = os.path.join(STARLIGHT_DIR, n)
        if os.path.isfile(p):
            return p
    return None


def compile_plugin(problems):
    exe = find_starlight()
    if not exe:
        problems.append("не найден компилятор starlight в plugin\\tools\\starlight")
        return None
    # собираем во временную папку: прежний плагин в build\plugin остаётся, пока новый не готов
    tmp = BUILD_PLUGIN + "_new"
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    os.makedirs(tmp)
    say("Компилирую плагин (starlight)...")
    # --release: без sourcemap. У рэжыме debug starlight уписвае ў плагін спасылкі
    # «sourceMappingURL=file://D:\\...\\plugin\\.millennium/sourcemaps/...» — гэта лакальны шлях
    # да папкі праекта на вашым камп'ютары, яму не месца ў публічным файле.
    res = subprocess.run([exe, "pack", "--release", "-o", tmp], cwd=PLUGIN,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out = res.stdout.decode("utf-8", "replace")
    if res.returncode != 0 and "release" in out.lower():
        problems.append("starlight не прыняў --release, плагін сабраны ў рэжыме debug: у ім будуць "
                        "лакальныя шляхі sourcemap — НЕ публікуйце гэтую зборку. Яго паведамленне:\n" + out[-1500:])
        res = subprocess.run([exe, "pack", "-o", tmp], cwd=PLUGIN,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        out = res.stdout.decode("utf-8", "replace")
    star = os.path.join(tmp, STAR_NAME)
    if res.returncode != 0 or not os.path.isfile(star):
        problems.append("starlight не смог собрать плагин (код %s). Его сообщения:\n%s" % (res.returncode, out[-3000:]))
        return None
    if os.path.getsize(star) < 500000:
        problems.append("собранный плагин подозрительно маленький (%d байт)" % os.path.getsize(star))
    return star


def promote_plugin(star):
    """Новый плагин готов — заменяем им прежний в build\\plugin."""
    if os.path.exists(BUILD_PLUGIN):
        shutil.rmtree(BUILD_PLUGIN)
    os.replace(os.path.dirname(star), BUILD_PLUGIN)
    return os.path.join(BUILD_PLUGIN, STAR_NAME)


# ---------------------------------------------------------------------------
#  Архивы для раздачи
# ---------------------------------------------------------------------------
def find_iscc():
    """Ищет компилятор Inno Setup (ISCC.exe) версии 7 или 6 на всех дисках."""
    found = shutil.which("ISCC") or shutil.which("ISCC.exe")
    if found:
        return found
    versions = ("7", "6")
    try:
        import winreg
        for ver in versions:
            for hive in (winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER):
                for view in (winreg.KEY_WOW64_32KEY, winreg.KEY_WOW64_64KEY):
                    try:
                        key = winreg.OpenKey(hive, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup %s_is1" % ver,
                                             0, winreg.KEY_READ | view)
                        loc = winreg.QueryValueEx(key, "InstallLocation")[0]
                        cand = os.path.join(loc, "ISCC.exe")
                        if os.path.isfile(cand):
                            return cand
                    except OSError:
                        pass
    except ImportError:
        pass
    bases = [os.environ.get(e) for e in ("ProgramFiles(x86)", "ProgramFiles", "ProgramW6432")]
    bases.append(os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs"))
    for d in "CDEFGHIJ":
        bases += [d + r":\Program Files", d + r":\Program Files (x86)"]
    for ver in versions:
        for base in bases:
            if base:
                cand = os.path.join(base, "Inno Setup " + ver, "ISCC.exe")
                if os.path.isfile(cand):
                    return cand
    return None


def add_docs(zf, kind):
    """Кладёт в архив инструкции (BE и RU) с подставленным номером версии и меткой автора."""
    folder = os.path.join(DOCS_DIR, kind)
    for name in sorted(os.listdir(folder)):
        with io.open(os.path.join(folder, name), encoding="utf-8-sig", newline="") as fh:
            text = fh.read().replace("{VERSION}", VERSION)
        zf.writestr(name, ("﻿" + text).encode("utf-8"))


def make_release(star):
    """Собирает оба архива во временной папке build\\release_new. Прежние архивы в build\\release
    заменяются только когда готовы ОБА новых; при любой ошибке прежние остаются как были."""
    tmp = RELEASE + "_new"
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    os.makedirs(tmp)
    try:
        code = _make_release(star, tmp)
        if code == 0:
            os.makedirs(RELEASE, exist_ok=True)
            for name in os.listdir(RELEASE):          # прежние архивы — только теперь
                if name.startswith(NAME_PREFIX):
                    os.remove(os.path.join(RELEASE, name))
            for name in os.listdir(tmp):
                os.replace(os.path.join(tmp, name), os.path.join(RELEASE, name))
            say()
            say("Оба архива лежат в build\\release.")
        else:
            say("  Архивы в build\\release НЕ обновлены — там остались прежние.")
        return code
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def _make_release(star, out):
    say()
    say("Упаковка для раздачи (версия %s)..." % VERSION)

    # 1) архив для ручной установки: файл плагина + инструкция
    manual = os.path.join(out, BASE_NAME + "_uruchnuyu.zip")
    with zipfile.ZipFile(manual, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        zf.write(star, STAR_NAME)
        add_docs(zf, "manual")
    say("  готово: " + os.path.basename(manual))

    # 2) установщик exe (Inno Setup) + инструкция
    iscc = find_iscc()
    if not iscc:
        say("  Установщик НЕ собран: не найдена программа Inno Setup 7 или 6 (ISCC.exe).")
        say("  Установите её с https://jrsoftware.org/isdl.php и запустите сборку ещё раз.")
        return 1
    exe = os.path.join(out, BASE_NAME + ".exe")
    say("  собираю установщик (Inno Setup)...")
    res = subprocess.run([iscc, "/Q", "/DAppVersion=" + VERSION, "/DStarFile=" + star,
                          "/DOutDir=" + out, "/DOutName=" + BASE_NAME,
                          os.path.join(INSTALLER_DIR, ISS_NAME)])
    if res.returncode != 0 or not os.path.isfile(exe):
        say("  ОШИБКА: Inno Setup не смог собрать установщик (код %s). Текст ошибки — выше." % res.returncode)
        return 2
    inst = os.path.join(out, BASE_NAME + "_ustalyoushchyk.zip")
    with zipfile.ZipFile(inst, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        zf.write(exe, os.path.basename(exe))
        add_docs(zf, "installer")
    os.remove(exe)
    for z in (manual, inst):                  # проверка архивов: читаются, CRC сходится
        with zipfile.ZipFile(z) as zf:
            if zf.testzip() is not None:
                say("  ОШИБКА: архив %s повреждён" % os.path.basename(z))
                return 2
    say("  готово: " + os.path.basename(inst))
    return 0


# ---------------------------------------------------------------------------
#  Установка в свой Steam (ключ --install)
# ---------------------------------------------------------------------------
def find_steam():
    try:
        import winreg
        for hive, path, name in ((winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam", "SteamPath"),
                                 (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath"),
                                 (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Valve\Steam", "InstallPath")):
            try:
                d = winreg.QueryValueEx(winreg.OpenKey(hive, path), name)[0].replace("/", "\\")
                if os.path.isfile(os.path.join(d, "steam.exe")):
                    return d
            except OSError:
                pass
    except ImportError:
        pass
    return None


def find_millennium(steam):
    """Та же логика, что в установщике: <Steam>\\millennium, а в новых версиях — %LOCALAPPDATA%\\Millennium."""
    for d in (os.path.join(steam, "millennium"), os.path.join(os.environ.get("LOCALAPPDATA", ""), "Millennium")):
        if d and os.path.isdir(d):
            return d
    return None


def steam_running():
    try:
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq steam.exe", "/NH"],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("cp866", "replace")
        return "steam.exe" in out.lower()
    except Exception:
        return False


def install_to_my_steam(star):
    steam = find_steam()
    if not steam:
        say("Не нашёл Steam на этом компьютере — плагин в Steam не скопирован.")
        return 1
    mill = find_millennium(steam)
    if not mill:
        say("Не найден Millennium (ни %s\\millennium, ни %%LOCALAPPDATA%%\\Millennium) — плагин не скопирован." % steam)
        return 1
    plugins = os.path.join(mill, "plugins")
    while steam_running():
        say("Steam запущен. Закройте его полностью (Steam → Выход) и нажмите Enter...")
        try:
            input()
        except EOFError:
            return 1
    os.makedirs(plugins, exist_ok=True)
    shutil.copy2(star, os.path.join(plugins, STAR_NAME))
    say("Плагин скопирован в " + plugins)
    return 0


# ---------------------------------------------------------------------------
#  Уборка старых файлов разработки (один раз; ничего не удаляется, только переносится)
# ---------------------------------------------------------------------------
OLD_DEV_TOOLS = ["append_dict_rows.py", "append_dict_rows3.py", "build_dict_pack.py", "build_pack_xlsx.py",
                 "build_pack.py", "build_tags_pack.py", "build_tokens.py", "build_web_pack.py", "dump_loc.js",
                 "export_xlsx.py", "make_dict_sheet.py", "make_lua.py", "pack.b64", "tags_be.tsv", "test_tr.json"]


def archive_old_files():
    moved = []
    arch = os.path.join(PLUGIN, "_archive")
    tools = os.path.join(PLUGIN, "tools")
    names = [n for n in (os.listdir(tools) if os.path.isdir(tools) else [])
             if n in OLD_DEV_TOOLS or re.match(r"dict_rows\d*\.py$", n)]
    for n in names:
        dst = os.path.join(arch, "dev_tools", n)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        os.replace(os.path.join(tools, n), dst)
        moved.append("plugin\\tools\\" + n)
    old = os.path.join(PLUGIN, "build")            # старый тестовый плагин 0.5.x — его легко спутать с настоящим
    if os.path.isdir(old):
        dst = os.path.join(arch, "old_test_build")
        os.makedirs(arch, exist_ok=True)
        if os.path.exists(dst):
            shutil.rmtree(dst)
        os.replace(old, dst)
        moved.append("plugin\\build")
    if moved:
        note = os.path.join(arch, "ПРОЧТИ.txt")
        with io.open(note, "w", encoding="utf-8-sig", newline="\r\n") as fh:
            fh.write("Старые файлы разработки, перенесённые сборщиком. Для сборки они не нужны и в плагин не попадают.\n"
                     "dev_tools — прежние разрозненные скрипты (с путями от машины разработки; dump_loc.js выполняет\n"
                     "входной файл через eval — запускать только на доверенных файлах Steam). Их работу теперь делает build_plugin.py.\n"
                     "old_test_build — старый тестовый плагин 0.5.x. Настоящий собранный плагин — build\\plugin\\.\n"
                     "Эту папку можно удалить целиком.\n")
        say("Перенёс старые файлы разработки в plugin\\_archive: " + ", ".join(moved))


def main():
    install = "--install" in sys.argv
    for p in (XLSX, os.path.join(PLUGIN, "millennium.toml"), os.path.join(PLUGIN, "inject", "tokens.js"),
              os.path.join(PLUGIN, "inject", "main.lua.tpl"), os.path.join(PLUGIN, "webview", "preload.ts")):
        if not os.path.exists(p):
            say("Не найдено: " + p)
            say("Скрипт должен лежать в папке проекта рядом с таблицей steam_be_strings.xlsx и папками plugin и tools.")
            return 1
    need_openpyxl()
    try:
        archive_old_files()
    except Exception as e:
        say("(не удалось перенести старые файлы в plugin\\_archive: %s — на сборку это не влияет)" % e)

    say("Читаю таблицу...")
    try:
        book = read_book(XLSX)
    except PermissionError:
        say("ОШИБКА: таблица занята другой программой. Закройте её в Excel и запустите сборку ещё раз.")
        return 2
    except Exception as e:
        say("ОШИБКА: не удалось прочитать таблицу: %s" % e)
        return 2
    bad = [s for s in REQUIRED_SHEETS if s not in book]
    if bad:
        say("ОШИБКА: в таблице нет листов: %s." % ", ".join(bad))
        say("Если лист переименовали или удалили намеренно — поправьте список WEB_SHEETS в build_plugin.py.")
        return 2
    for s in REQUIRED_SHEETS:                 # колонки на своих местах?
        hdr = [str(x or "").strip() for x in book[s][0]] if book[s] else []
        if len(hdr) < 7 or hdr[6] != "Беларуская":
            say("ОШИБКА: на листе «%s» седьмая колонка (G) должна называться «Беларуская», а там «%s»."
                % (s, hdr[6] if len(hdr) > 6 else ""))
            return 2

    problems, warnings = [], []
    say("Собираю файлы перевода...")
    try:
        stats = generate(book, problems, warnings)
    except Exception as e:
        say("ОШИБКА при сборке файлов перевода: %s" % e)
        return 2
    # заметное падение количества переведённых строк по сравнению с прошлой сборкой
    try:
        last = json.load(io.open(LAST_STATS, encoding="utf-8"))
    except Exception:
        last = {}
    for k, v in stats.items():
        if last.get(k) and v < last[k] * 0.98:
            warnings.insert(0, "ВНИМАНИЕ: строк «%s» стало %d, а в прошлой сборке было %d. Не пропала ли часть таблицы?"
                            % (k, v, last[k]))
    star = None
    if not problems:
        star = compile_plugin(problems)

    say()
    say("Строк с переводом: " + ", ".join("%s — %d" % kv for kv in stats.items()) + ".")
    os.makedirs(BUILD, exist_ok=True)
    wfile = os.path.join(BUILD, "warnings.txt")
    if warnings:
        with io.open(wfile, "w", encoding="utf-8-sig", newline="\r\n") as fh:
            fh.write("\n".join(warnings) + "\n")
        say()
        say("Предупреждения (%d) — плагин работает, но эти строки стоит проверить в таблице:" % len(warnings))
        for w in warnings[:40]:
            say("  - " + (w if len(w) < 300 else w[:300] + "…"))
        if len(warnings) > 40:
            say("  ... и ещё %d" % (len(warnings) - 40))
        say("  Полный список: build\\warnings.txt")
    elif os.path.exists(wfile):
        os.remove(wfile)
    if problems:
        say()
        say("ОШИБКИ (%d) — плагин не собран:" % len(problems))
        for p in problems:
            say("  - " + p)
        return 2
    star = promote_plugin(star)
    with io.open(LAST_STATS, "w", encoding="utf-8") as fh:
        json.dump(stats, fh, ensure_ascii=False)
    say("Плагин: %s (%d КБ)" % (star, os.path.getsize(star) // 1024))
    say()
    say("Ошибок нет.")
    code = make_release(star)
    if install:
        say()
        code = install_to_my_steam(star) or code
    return code


if __name__ == "__main__":
    sys.exit(main())
