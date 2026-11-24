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
