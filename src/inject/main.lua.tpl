local logger     = require("logger")
local millennium = require("millennium")

-- Код, які ўстаўляецца ў library.js Steam яшчэ да загрузкі тэкстаў інтэрфейсу:
-- 1) беларускія назвы месяцаў і дзён тыдня ў датах;
-- 2) падмена радкоў інтэрфейсу беларускімі (з праверкай арыгінала).
-- Ужо сабраны адным радком, каб Lua не склейвала яго і не трымала лішніх копій.
-- Кампілятар starlight у рэжыме release сціскае Lua-код і пры гэтым псуе байты UTF-8
-- (кірыліца ператваралася ў «ÐÂ…»). Таму ў main.lua няма ніводнага не-ASCII сімвала:
-- сборшчык кадуе іх (гл. lua_ascii у build_plugin.py), а D() вяртае назад пры загрузцы.
-- @@CODEC@@ — радок з 2-байтавымі паслядоўнасцямі для кодаў «~!», «~"», … па парадку.
local function D(s)
    local K, T, n = "@@CODEC@@", {}, 0
    for i = 33, 126 do
        if i ~= 126 then
            n = n + 1
            T["~" .. string.char(i)] = K:sub(2 * n - 1, 2 * n)
        end
    end
    s = s:gsub("~~(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    s = s:gsub("~.", T)
    return s
end

local PATCHES = {
    {
        find = [[window\.LocalizationManager=]],
        file = [[library\.js]],
        transforms = {
            {
                match = [[window\.LocalizationManager=]],
                replace = D([==[@@INJECT@@]==]),
            }
        }
    }
}

-- АЎТААБНАЎЛЕННЕ. Усе праверкі робіць бэкенд сам, адной функцыяй be_update: старонка налад
-- толькі просіць «правер і абнаві» і паказвае вынік. Адрасы, ключ і бягучая версія ўшытыя
-- сборшчыкам; ад frontend не прымаюцца ні адрасы, ні версіі, ні шляхі.
--   1) latest.json і подпіс — па фіксаваным адрасе (апошні выпуск на GitHub);
--   2) подпіс ECDSA P-256 правяраецца ўшытым публічным ключом (крыптаграфія Windows, bcrypt);
--   3) строгія фарматы: id, версія x.y.z, памер, SHA-256, адрас файла толькі ў выпуску гэтага рэпазіторыя;
--   4) файл спампоўваецца на дыск, правяраецца памер і SHA-256 менавіта тых байтаў, што будуць запісаны;
--   5) рэзервовая копія, замена праз .new + rename; новая версія ўключаецца пры наступным запуску Steam.
-- Толькі ASCII у радках (гл. вышэй пра release-рэжым starlight).
-- Калі чагосьці няма (іншая версія Millennium) — выключаецца толькі абнаўленне, пераклад працуе.
local _, http  = pcall(require, "http")
local _, utils = pcall(require, "utils")
local _, fs    = pcall(require, "fs")
local CRYPTO_OK, ffi = pcall(require, "ffi")

local VERSION   = "@@VERSION@@"
local PUBKEY    = "@@PUBKEY@@"
local TEST_CHAN = @@TESTCHAN@@
local PLUGIN_ID = "by.dzedahey.steam-be"
local STAR      = PLUGIN_ID .. ".star"
local REPO      = "https://github.com/dzedahey/steam-pa-belarusku"
local MAX_JSON, MAX_SIG, MAX_STAR = 16384, 1024, 20 * 1024 * 1024

local bcrypt
if CRYPTO_OK then CRYPTO_OK = pcall(ffi.cdef, [[
typedef long BE_NTSTATUS;
BE_NTSTATUS __stdcall BCryptOpenAlgorithmProvider(void **phAlgorithm, const uint16_t *pszAlgId, const uint16_t *pszImplementation, unsigned long dwFlags);
BE_NTSTATUS __stdcall BCryptHash(void *hAlgorithm, const uint8_t *pbSecret, unsigned long cbSecret, const char *pbInput, unsigned long cbInput, uint8_t *pbOutput, unsigned long cbOutput);
BE_NTSTATUS __stdcall BCryptImportKeyPair(void *hAlgorithm, void *hImportKey, const uint16_t *pszBlobType, void **phKey, const char *pbInput, unsigned long cbInput, unsigned long dwFlags);
BE_NTSTATUS __stdcall BCryptVerifySignature(void *hKey, void *pPaddingInfo, const uint8_t *pbHash, unsigned long cbHash, const char *pbSignature, unsigned long cbSignature, unsigned long dwFlags);
]]) end
if CRYPTO_OK then CRYPTO_OK, bcrypt = pcall(ffi.load, "bcrypt") end
if not CRYPTO_OK then bcrypt = nil end

local function W(s)
    local b = ffi.new("uint16_t[?]", #s + 1)
    for i = 1, #s do b[i - 1] = s:byte(i) end
    return b
end

local h_sha, h_ecdsa, h_key
local function sha256_raw(data)
    if not h_sha then
        local h = ffi.new("void*[1]")
        assert(bcrypt.BCryptOpenAlgorithmProvider(h, W("SHA256"), nil, 0) == 0, "sha256 provider")
        h_sha = h[0]
    end
    local out = ffi.new("uint8_t[32]")
    assert(bcrypt.BCryptHash(h_sha, nil, 0, data, #data, out, 32) == 0, "sha256")
    return out
end
local function sha256_hex(data)
    return utils.hex_encode(ffi.string(sha256_raw(data), 32))
end
local function verify_sig(data, sig)
    if #sig ~= 64 then return false end
    if not h_key then
        local xy = utils.base64_decode(PUBKEY)
        if #xy ~= 64 then return false end
        local blob = "ECS1" .. string.char(32, 0, 0, 0) .. xy
        local h = ffi.new("void*[1]")
        assert(bcrypt.BCryptOpenAlgorithmProvider(h, W("ECDSA_P256"), nil, 0) == 0, "ecdsa provider")
        h_ecdsa = h[0]
        local k = ffi.new("void*[1]")
        assert(bcrypt.BCryptImportKeyPair(h_ecdsa, nil, W("ECCPUBLICBLOB"), k, blob, #blob, 0) == 0, "import key")
        h_key = k[0]
    end
    return bcrypt.BCryptVerifySignature(h_key, nil, sha256_raw(data), 32, sig, #sig, 0) == 0
end

local function vparse(v)
    if type(v) ~= "string" or #v > 20 then return nil end
    local a, b, c = v:match("^(%d+)%.(%d+)%.(%d+)$")
    if not a then return nil end
    return { tonumber(a), tonumber(b), tonumber(c) }
end
local function vcmp(x, y)
    local a, b = vparse(x), vparse(y)
    if not a or not b then return nil end
    for i = 1, 3 do
        if a[i] ~= b[i] then return a[i] > b[i] and 1 or -1 end
    end
    return 0
end

local function data_dir()
    local base = utils.getenv("LOCALAPPDATA") or ""
    if base == "" then error("LOCALAPPDATA is not set") end   -- no writes to a guessed folder
    local d = base .. "/SteamBE"
    pcall(fs.create_directories, d .. "/backup")
    pcall(fs.create_directories, d .. "/staging")
    return d
end
local function log(msg)
    local okd, ts = pcall(function() return os.date("%Y-%m-%d %H:%M:%S ") end)
    pcall(utils.append_file, data_dir() .. "/update.log", (okd and ts or "") .. msg .. "\n")
end

-- надзейны запіс файла: часовы файл -> параўнанне прачытанага -> rename -> параўнанне
local function write_exact(path, body)
    local ok, w = pcall(utils.write_file, path .. ".tmp", body)
    if not ok or not w then return false end
    local okr, back = pcall(utils.read_file, path .. ".tmp")
    if not okr or back ~= body then pcall(fs.remove, path .. ".tmp"); return false end
    if not pcall(fs.rename, path .. ".tmp", path, true) then pcall(fs.remove, path .. ".tmp"); return false end
    local okc, fin = pcall(utils.read_file, path)
    return okc and fin == body
end

-- Стан (state.txt): pending/pending_sha — новая версія ўжо на дыску і чакае перазапуску;
-- declined — версія, ад якой адкаціліся; updated — для аднаразовага апавяшчэння;
-- baseline_ver/baseline_sha — хеш версіі, усталяванай уручную (да першага аўтаабнаўлення).
-- Запіс: часовы файл -> праверка зместу -> rename. Памылка запісу НЕ ігнаруецца.
local STATE_KEYS = { "pending", "pending_sha", "declined", "updated", "baseline_ver", "baseline_sha" }
local function state_read()
    local st = {}
    local ok, txt = pcall(utils.read_file, data_dir() .. "/state.txt")
    if ok and type(txt) == "string" then
        for k, v in txt:gmatch("([%w_]+)=([^\r\n]*)") do st[k] = v end
    end
    return st
end
local function state_write(st)
    local t = {}
    for _, k in ipairs(STATE_KEYS) do
        if st[k] and st[k] ~= "" then t[#t + 1] = k .. "=" .. st[k] end
    end
    return write_exact(data_dir() .. "/state.txt", table.concat(t, "\n") .. "\n")
end

-- Налады карыстальніка (settings.txt): autoupdate=1|0. Файл можа пакласці і ўсталёўшчык
-- (выбар «аўтаабнаўленне» пры ўсталяванні); няма файла — рашае старонка налад (па змаўчанні ўключана).
local function settings_read()
    local st = {}
    local ok, txt = pcall(utils.read_file, data_dir() .. "/settings.txt")
    if ok and type(txt) == "string" then
        for k, v in txt:gmatch("([%w_]+)=([^\r\n]*)") do st[k] = v end
    end
    return st
end

local function star_path()
    for _, p in ipairs({ millennium.steam_path() .. "/millennium/plugins/" .. STAR,
                         (utils.getenv("LOCALAPPDATA") or "") .. "/Millennium/plugins/" .. STAR }) do
        if fs.exists(p) then return p end
    end
    return nil
end

-- sha256 файла; спачатку памер (каб не чытаць у памяць празмерна вялікі файл)
local function file_sha(path, limit)
    local okz, sz = pcall(fs.file_size, path)
    if not okz or type(sz) ~= "number" then return nil end
    if sz > (limit or MAX_STAR) then return nil, sz end
    local ok, data = pcall(utils.read_file, path)
    if not ok or type(data) ~= "string" then return nil end
    return sha256_hex(data), #data
end

-- рэзервовыя копіі: backup/<id>.star.<версія>; для версій, атрыманых аўтаабнаўленнем, побач
-- захоўваецца падпісаны маніфест: backup/<версія>.manifest і backup/<версія>.sig
local function bdir() return data_dir() .. "/backup/" end
local function backup_file(v) return bdir() .. STAR .. "." .. v end
local function backups()
    local t = {}
    local okl, lst = pcall(fs.list, bdir())
    if okl and type(lst) == "table" then
        for _, e in ipairs(lst) do
            local n = tostring(type(e) == "table" and (e.path or e.name or e[1]) or e)
            local v = n:match("%.star%.(%d+%.%d+%.%d+)$")
            if v then t[#t + 1] = v end
        end
    end
    table.sort(t, function(a, b) return vcmp(a, b) == 1 end)
    return t
end

-- разбор падпісанага маніфеста (тэкст ужо правераны подпісам)
local function manifest_fields(text)
    local function one(pat)
        local v, n = nil, 0
        for m in text:gmatch(pat) do v = m; n = n + 1 end
        return n == 1 and v or nil
    end
    local f = {
        id = one('"id"%s*:%s*"([^"]*)"'), version = one('"version"%s*:%s*"([^"]*)"'),
        sha = one('"sha256"%s*:%s*"([^"]*)"'), size = tonumber(one('"size"%s*:%s*(%d+)')),
        url = one('"url"%s*:%s*"([^"]*)"'),
    }
    if f.id ~= PLUGIN_ID or not vparse(f.version) or not f.sha or #f.sha ~= 64 or not f.sha:match("^%x+$")
        or not f.size or f.size < 1 or f.size > MAX_STAR or not f.url then
        return nil
    end
    f.sha = f.sha:lower()
    return f
end

local function sig_ok(text, sigtxt)
    local okd, sig = pcall(utils.base64_decode, (tostring(sigtxt):gsub("%s", "")))
    return okd and type(sig) == "string" and verify_sig(text, sig)
end

-- давераны хеш версіі v: з падпісанага маніфеста (праверка подпісу зараз жа) або базавы
local function trusted_sha(v, st)
    local okm, m = pcall(utils.read_file, bdir() .. v .. ".manifest")
    local oks, sg = pcall(utils.read_file, bdir() .. v .. ".sig")
    if okm and oks and type(m) == "string" and type(sg) == "string" then
        if not sig_ok(m, sg) then return nil, "badsig" end
        local f = manifest_fields(m)
        if not f or f.version ~= v then return nil, "badmanifest" end
        return f.sha
    end
    if st.baseline_ver == v and st.baseline_sha and #st.baseline_sha == 64 then return st.baseline_sha end
    return nil, "none"
end

-- копія src -> dst.new, праверка sha256 менавіта гэтых байтаў, затым rename на месца dst
local function put_file(src, dst, sha, size)
    local tmp = dst .. ".new"
    pcall(fs.remove, tmp)
    if not pcall(fs.copy, src, tmp, true) then return false, "copy" end
    local h, n = file_sha(tmp)
    if h ~= sha or (size and n ~= size) then pcall(fs.remove, tmp); return false, "verify" end
    if not pcall(fs.rename, tmp, dst, true) then pcall(fs.remove, tmp); return false, "rename" end
    local h2 = file_sha(dst)
    if h2 ~= sha then return false, "after" end
    return true
end

-- pending сапраўдны, толькі калі на дыску менавіта той файл
local function check_pending(st)
    if not st.pending then return false end
    local dst = star_path()
    if dst and st.pending_sha and file_sha(dst) == st.pending_sha then return true end
    st.pending, st.pending_sha = nil, nil
    state_write(st)
    return false
end

local busy = false

-- Хеш файла плагіна на момант запуску Steam (= код, які зараз працуе). Калі файл на дыску
-- за гэты сеанс змяніўся (абнаўленне, адкат або ручная замена), новых змен да перазапуску не робім.
local SESSION_SHA
local function session_sha()
    if SESSION_SHA == nil then
        local ok, h = pcall(function() local p = star_path(); return p and file_sha(p) end)
        SESSION_SHA = (ok and h) or false
    end
    return SESSION_SHA or nil
end
pcall(function() if CRYPTO_OK and type(fs) == "table" and type(utils) == "table" then session_sha() end end)


-- ЗАЎВАГА: http.get і http.download у Millennium не маюць ліміту аб'ёму. Памер правяраецца
-- адразу пасля атрымання (і да чытання файла ў памяць), але саму загрузку перапыніць нельга.
local function get_small(url, limit)
    local res, err = http.get(url, { timeout = 60, follow_redirects = true })
    if not res then return nil, "net " .. tostring(err) end
    if res.status ~= 200 then return nil, "http " .. tostring(res.status) end
    local b = res.body or ""
    if #b == 0 or #b > limit then return nil, "size" end
    return b
end

local function update(manual, channel)
    if not manual and type(utils) == "table" and settings_read().autoupdate == "0" then return "OFF" end
    local base = REPO .. "/releases/latest/download/"
    if TEST_CHAN and channel == "test" then base = REPO .. "/releases/download/test/" end
    if not CRYPTO_OK or PUBKEY == "" or type(http) ~= "table" or type(http.download) ~= "function"
        or type(utils) ~= "table" or type(fs) ~= "table" then
        -- Запасны рэжым «толькі паведаміць»: правяраць подпіс няма чым, таму нічога не ставім,
        -- толькі чытаем нумар версіі (ён паказваецца карыстальніку, больш ні на што не ўплывае).
        if type(http) ~= "table" or type(http.get) ~= "function" then return "ERR_NOSUPPORT" end
        local text, e = get_small(base .. "latest.json", MAX_JSON)
        if not text then return "ERR_NET " .. e end
        local ver = text:match('"version"%s*:%s*"([^"]*)"')
        if not vparse(ver) then return "ERR_FORMAT" end
        if vcmp(ver, VERSION) > 0 then return "NOTIFY " .. ver end
        return "UPTODATE " .. VERSION
    end
    local text, e1 = get_small(base .. "latest.json", MAX_JSON)
    if not text then return "ERR_NET " .. e1 end
    local sigtxt, e2 = get_small(base .. "latest.json.sig", MAX_SIG)
    if not sigtxt then return "ERR_NET sig " .. e2 end
    if not sig_ok(text, sigtxt) then
        log("bad signature of latest.json")
        return "ERR_SIG"
    end
    local f = manifest_fields(text)
    if not f then return "ERR_FORMAT" end
    local tag = f.url:match("^https://github%.com/dzedahey/steam%-pa%-belarusku/releases/download/([%w%._%-]+)/by%.dzedahey%.steam%-be%.star$")
    if not tag or tag:find("..", 1, true) then return "ERR_FORMAT url" end
    local ver, sha, size = f.version, f.sha, f.size
    local st = state_read()
    -- «прапушчаная» версія мае сэнс, толькі пакуль яна і ёсць апошні выпуск: калі выйшла іншая
    -- (або выпуск знялі), адмова састарэла і больш не паказваецца
    if st.declined and st.declined ~= ver then
        st.declined = nil
        state_write(st)
    end
    if vcmp(ver, VERSION) <= 0 then return "UPTODATE " .. VERSION end
    -- пакуль адно абнаўленне чакае перазапуску, другое не ставім (інакш сапсуецца рэзервовая копія)
    if check_pending(st) then return "PENDING " .. st.pending end
    if st.declined == ver and not manual then return "DECLINED " .. ver end
    local dst = star_path()
    if not dst then return "ERR_NOPLUGIN" end
    -- файл на дыску павінен быць менавіта тым, што запушчаны (нічога не мянялася за сеанс)
    local cur_sha, cur_n = file_sha(dst)
    if not cur_sha then return "ERR_WRITE read" end
    if cur_sha ~= session_sha() then return "RESTART" end
    -- (pending тут ужо няма, а стан пішацца надзейна, значыць адрозненне ад даверанага хеша —
    -- гэта ручная пераўсталёўка той жа версіі; тады бягучы файл становіцца новай базай)
    local t_sha = trusted_sha(VERSION, st)
    if t_sha ~= cur_sha then
        if t_sha then log("plugin file changed outside updater; new baseline for " .. VERSION) end
        pcall(fs.remove, bdir() .. VERSION .. ".manifest")
        pcall(fs.remove, bdir() .. VERSION .. ".sig")
        st.baseline_ver, st.baseline_sha = VERSION, cur_sha
    end
    -- спампоўка на дыск; памер правяраецца да чытання ў памяць
    local stg = data_dir() .. "/staging/" .. STAR
    pcall(fs.remove, stg)
    local res, err = http.download(f.url, stg, { timeout = 300, follow_redirects = true })
    if not res or not res.success or res.status ~= 200 then
        pcall(fs.remove, stg)
        return "ERR_NET star " .. tostring(res and res.status or err)
    end
    local h, n = file_sha(stg, size)
    if n ~= size or h ~= sha then
        pcall(fs.remove, stg)
        log("downloaded file does not match signed manifest (" .. tostring(n) .. ")")
        return "ERR_HASH"
    end
    -- рэзервовая копія запушчанай версіі (толькі з правераным змесцівам)
    local bak = backup_file(VERSION)
    if file_sha(bak) ~= cur_sha then
        local okb, wb = put_file(dst, bak, cur_sha, cur_n)
        if not okb then pcall(fs.remove, stg); log("backup failed: " .. wb); return "ERR_WRITE backup" end
    end
    -- падпісаны маніфест новай версіі — для будучага адкату
    if not write_exact(bdir() .. ver .. ".manifest", text) or not write_exact(bdir() .. ver .. ".sig", sigtxt) then
        pcall(fs.remove, bdir() .. ver .. ".manifest")
        pcall(fs.remove, bdir() .. ver .. ".sig")
        pcall(fs.remove, stg)
        return "ERR_WRITE manifest"
    end
    -- журнал: спачатку стан (pending), потым замена. Без запісанага стану не замяняем.
    st.pending, st.pending_sha = ver, sha
    if st.declined == ver then st.declined = nil end
    if not state_write(st) then pcall(fs.remove, stg); return "ERR_WRITE state" end
    local okp, wp = put_file(stg, dst, sha, size)
    pcall(fs.remove, stg)
    if not okp then
        st.pending, st.pending_sha = nil, nil
        state_write(st)
        log("replace failed: " .. wp)
        return "ERR_WRITE " .. wp
    end
    -- старыя копіі: дзве самыя новыя (+ іх маніфесты)
    local bl = backups()
    for k = 3, #bl do
        pcall(fs.remove, backup_file(bl[k]))
        pcall(fs.remove, bdir() .. bl[k] .. ".manifest")
        pcall(fs.remove, bdir() .. bl[k] .. ".sig")
    end
    log("updated " .. VERSION .. " -> " .. ver .. (manual and " (manual)" or ""))
    collectgarbage("collect")
    return "INSTALLED " .. ver
end

---@ffi
---@param manual boolean
---@param channel string
---@return string
function be_update(manual, channel)
    if busy then return "BUSY" end
    busy = true
    local ok, r = pcall(update, manual == true, tostring(channel))
    busy = false
    if not ok then log("error: " .. tostring(r)); return "ERR " .. tostring(r) end
    return r
end

-- стан для старонкі налад: version, pending, declined, backups, updated (апошняе — адзін раз)
---@ffi
---@return string
function be_state()
    local ok, r = pcall(function()
        if not CRYPTO_OK or type(utils) ~= "table" or type(fs) ~= "table" then
            return "version=" .. VERSION .. ";nosupport=1;test=" .. tostring(TEST_CHAN)
        end
        local st = state_read()
        local upd
        if st.pending and vcmp(VERSION, st.pending) >= 0 then
            upd = (VERSION == st.pending) and VERSION or nil
            st.pending, st.pending_sha = nil, nil
            state_write(st)
        else
            check_pending(st)
        end
        if st.updated then upd = upd or st.updated; st.updated = nil; state_write(st) end
        -- адмова ад версіі, якая ўжо запушчана або старэйшая за яе, больш нічога не значыць
        if st.declined and (not vparse(st.declined) or vcmp(st.declined, VERSION) <= 0) then st.declined = nil; state_write(st) end
        return "version=" .. VERSION .. ";pending=" .. (st.pending or "") .. ";declined=" .. (st.declined or "")
            .. ";backups=" .. table.concat(backups(), ",") .. ";updated=" .. (upd or "")
            .. ";test=" .. tostring(TEST_CHAN) .. ";auto=" .. (settings_read().autoupdate or "")
    end)
    return ok and r or ("ERR " .. tostring(r))
end

-- уключыць/выключыць аўтаабнаўленне (запамінаецца ў settings.txt)
---@ffi
---@param on boolean
---@return string
function be_set_auto(on)
    local ok, r = pcall(function()
        if type(utils) ~= "table" or type(fs) ~= "table" then return "ERR_NOSUPPORT" end
        return write_exact(data_dir() .. "/settings.txt", "autoupdate=" .. (on == true and "1" or "0") .. "\n") and "OK" or "ERR_WRITE"
    end)
    return ok and r or ("ERR " .. tostring(r))
end

-- адкат. Калі новая версія спампавана і чакае перазапуску — вяртаем бягучую (і адмяняем pending).
-- Інакш — самую новую копію, старэйшую за бягучую версію. Копія павінна супадаць з даверам:
-- з падпісаным маніфестам (подпіс правяраецца зараз) або з базавым хешам ручной усталёўкі.
-- Адкочаную версію памятаем як адхіленую: аўтаматычна яна больш не ставіцца.
---@ffi
---@return string
function be_rollback()
    if busy then return "BUSY" end
    busy = true
    local ok, r = pcall(function()
        if not CRYPTO_OK then return "ERR_NOSUPPORT" end
        local dst = star_path()
        if not dst then return "ERR_NOPLUGIN" end
        local st = state_read()
        local target, declined
        if check_pending(st) then
            target, declined = VERSION, st.pending
        elseif file_sha(dst) ~= session_sha() then
            return "RESTART"
        else
            for _, v in ipairs(backups()) do
                if vcmp(v, VERSION) < 0 then target = v; break end
            end
            declined = VERSION
        end
        if not target then return "ERR_NOBACKUP" end
        local src = backup_file(target)
        local want = trusted_sha(target, st)
        local h, n = file_sha(src)
        if not h then return "ERR_NOBACKUP" end
        if not want or h ~= want then
            log("backup " .. target .. " does not match trusted hash")
            return "ERR_BACKUP_CHANGED"
        end
        local old = { pending = st.pending, pending_sha = st.pending_sha, declined = st.declined }
        st.pending, st.pending_sha, st.declined = nil, nil, declined
        if not state_write(st) then return "ERR_WRITE state" end
        local okp, why = put_file(src, dst, h, n)
        if not okp then
            st.pending, st.pending_sha, st.declined = old.pending, old.pending_sha, old.declined
            state_write(st)
            return "ERR_WRITE " .. why
        end
        log("rollback to " .. target .. ", declined " .. declined)
        return "OK " .. target
    end)
    busy = false
    return ok and r or ("ERR " .. tostring(r))
end

local function on_load()
    logger:info("steam-be loaded, Millennium " .. millennium.version())
    millennium.ready()
    -- вызваліць памяць, якая засталася пасля загрузкі модуля
    collectgarbage("collect")
end

local function on_unload() end
local function on_frontend_loaded() collectgarbage("collect") end

return {
    on_frontend_loaded = on_frontend_loaded,
    on_load = on_load,
    on_unload = on_unload,
    patches = PATCHES
}
