-- Харнес: запускае main.lua з падробленымі модулямі Millennium (файлы — у /tmp/h)
local MAIN, VER = arg[1], arg[2]
local ROOT = "/tmp/h"
local function rd(p) local f = io.open(p, "rb"); if not f then return nil end; local s = f:read("a"); f:close(); return s end
local function wr(p, s) local f = assert(io.open(p, "wb")); f:write(s); f:close() end
local function mkdirp(p) os.execute("mkdir -p '" .. p .. "'") end
local VALID = {}
local function hexs(s) return (s:gsub(".", function(c) return string.format("%02x", c:byte()) end)) end
local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64e(data)
  return ((data:gsub('.', function(x) local r, b = '', x:byte(); for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end; return r end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end; local c = 0; for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end; return b64c:sub(c + 1, c + 1) end) .. ({ '', '==', '=' })[#data % 3 + 1])
end
local function b64d(data)
  data = data:gsub('[^' .. b64c .. '=]', '')
  return (data:gsub('.', function(x) if (x == '=') then return '' end; local r, f = '', (b64c:find(x) - 1); for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end; return r end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end; local c = 0; for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end; return string.char(math.floor(c)) end))
end
package.preload["logger"] = function() return { info = function() end } end
package.preload["millennium"] = function() return { version = function() return "v3.6.3" end, steam_path = function() return ROOT .. "/steam" end, ready = function() end } end
package.preload["utils"] = function() return {
  getenv = function(k) if k == "LOCALAPPDATA" then return ROOT .. "/lad" end end,
  read_file = function(p) local s = rd(p); if not s then error("no file " .. p) end; MAXREAD = math.max(MAXREAD or 0, #s); return s end,
  write_file = function(p, s) if FAILWRITE and p:find(FAILWRITE, 1, true) then return false, "denied" end; wr(p, s); return true end,
  append_file = function(p, s) local f = io.open(p, "ab"); f:write(s); f:close(); return true end,
  hex_encode = hexs, base64_decode = b64d, time_ms = function() return os.time() * 1000 end } end
package.preload["fs"] = function() return {
  exists = function(p) return rd(p) ~= nil or os.execute("test -d '" .. p .. "'") == true end,
  create_directories = function(p) mkdirp(p) end,
  copy = function(a, b, t) local s = rd(a); if not s then error("copy: no " .. a) end; wr(b, s); return true end,
  rename = function(a, b, t) local ok, e = os.rename(a, b); if not ok then error(e) end; return true end,
  remove = function(p) os.remove(p) end,
  file_size = function(p) local s = rd(p); return s and #s end,
  list = function(p) local t = {}; local h = io.popen("ls -1 '" .. p .. "' 2>/dev/null"); for l in h:lines() do t[#t + 1] = l end; h:close(); return t end } end
package.preload["http"] = function()
  local function local_of(url)
    local tag, name = url:match("/releases/download/([^/]+)/([^/]+)$")
    if not tag then tag, name = "latest", url:match("/releases/latest/download/([^/]+)$") end
    return ROOT .. "/remote/" .. tag .. "/" .. name
  end
  return {
    get = function(url) local s = rd(local_of(url)); if not s then return { status = 404, body = "Not Found" } end; return { status = 200, body = s } end,
    download = function(url, path) local s = rd(local_of(url)); if not s then return { success = false, status = 404 } end; wr(path, s); return { success = true, status = 200, bytes_written = #s } end }
end
package.loaded["ffi"] = nil; package.loaded["http"] = nil; package.loaded["fs"] = nil; package.loaded["utils"] = nil
package.preload["ffi"] = function()
  local ffi = {}
  function ffi.cdef() end
  function ffi.new(t) return { s = "" } end
  function ffi.string(b, n) return b.s end
  function ffi.load() if NOFFI then error("no bcrypt") end return {
    BCryptOpenAlgorithmProvider = function(h) h[0] = "alg"; return 0 end,
    BCryptHash = function(h, a, b, data, n, out) out.s = sha2.digest256(data); return 0 end,
    BCryptImportKeyPair = function(h, a, t, k) k[0] = "key"; return 0 end,
    BCryptVerifySignature = function(k, p, hash, n, sig) return VALID[hash.s] == sig and 0 or -1073700864 end } end
  return ffi
end
-- «падпісаць» маніфест: зарэгістраваць подпіс для яго хеша
function SIGN(data) local sig = sha2.digest256("sig" .. data) .. sha2.digest256("x" .. data); VALID[sha2.digest256(data)] = sig; return b64e(sig) end
function PUBLISH(tag, ver, star, opts)
  opts = opts or {}
  mkdirp(ROOT .. "/remote/" .. tag)
  local stag = opts.urltag or ("v" .. ver)
  mkdirp(ROOT .. "/remote/" .. stag)
  wr(ROOT .. "/remote/" .. stag .. "/by.dzedahey.steam-be.star", opts.served or star)
  local url = opts.url or ("https://github.com/dzedahey/steam-pa-belarusku/releases/download/" .. (opts.urltag or ("v" .. ver)) .. "/by.dzedahey.steam-be.star")
  local j = '{\n "id": "' .. (opts.id or "by.dzedahey.steam-be") .. '",\n "star": {\n  "sha256": "' .. hexs(sha2.digest256(star)) .. '",\n  "size": ' .. #star .. ',\n  "url": "' .. url .. '"\n },\n "version": "' .. ver .. '"\n}\n'
  local sig = SIGN(j)
  if opts.tamper then j = j:gsub('"version": "[^"]*"', '"version": "9.9.9"') end
  wr(ROOT .. "/remote/" .. tag .. "/latest.json", j)
  wr(ROOT .. "/remote/" .. tag .. "/latest.json.sig", sig)
end
function WR(p, s) wr(ROOT .. p, s) end
function RD(p) return rd(ROOT .. p) end
function STAR() return rd(ROOT .. "/steam/millennium/plugins/by.dzedahey.steam-be.star") end
function SETSTAR(s) mkdirp(ROOT .. "/steam/millennium/plugins"); wr(ROOT .. "/steam/millennium/plugins/by.dzedahey.steam-be.star", s) end
function LOAD(ver)
  local src = rd(MAIN):gsub('local VERSION   = "[^"]*"', 'local VERSION   = "' .. ver .. '"'):gsub("local TEST_CHAN = false", NOTEST and "local TEST_CHAN = false" or "local TEST_CHAN = true")
  local f = assert(load(src, "main.lua"))
  return f()
end
dofile(arg[3])
