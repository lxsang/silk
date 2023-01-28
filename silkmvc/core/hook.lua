math.randomseed(os.time())
-- define some legacy global variables to provide backward support
-- for some old web application
__api__ = {
    apiroot = string.format("%s/lua", _SERVER["LIB_DIR"]),
    tmpdir = _SERVER["TMP_DIR"],
    dbpath = _SERVER["DB_DIR"]
}
-- root dir
__ROOT__ = _SERVER["DOCUMENT_ROOT"]
-- set require path
package.cpath = __api__.apiroot .. '/?.so'
package.path = string.format("%s/?.lua;%s/?.lua",__api__.apiroot,__ROOT__)

ulib = require("ulib")
slice = require("slice")
require("silk.core.utils")
require("silk.core.std")


-- global helper functions for lua page script
function has_module(m)
    if utils.file_exists(__ROOT__ .. '/' .. m) then
        if m:find("%.ls$") then
            return true, true, __ROOT__ .. '/' .. m
        else
            return true, false, m:gsub(".lua$", "")
        end
    elseif utils.file_exists(__ROOT__ .. '/' .. string.gsub(m, '%.', '/') .. '.lua') then
        return true, false, m
    elseif utils.file_exists(__ROOT__ .. '/' .. string.gsub(m, '%.', '/') .. '.ls') then
        return true, true, __ROOT__ .. '/' .. string.gsub(m, '%.', '/') .. '.ls'
    end
    return false, false, nil
end

--- Send data to client
function echo(...)
    fcgio:echo(...)
end

--- luad lua page script
function loadscript(file, args)
    local f = io.open(file, "rb")
    local content = ""
    if f then
        local html = ""
        local pro = "local fn = function(...)"
        local s, e, mt
        local mtbegin = true -- find begin of scrit, 0 end of scrit
        local i = 1
        if args then
            pro = "local fn = function(" .. table.concat(args, ",") .. ")"
        end
        for line in io.lines(file) do
            line = ulib.trim(line, " ")
            if (line ~= "") then
                if (mtbegin) then
                    mt = "^%s*<%?lua"
                else
                    mt = "%?>%s*$"
                end
                s, e = line:find(mt)
                if (s) then
                    if mtbegin then
                        if html ~= "" then
                            pro = pro .. "echo(\"" .. utils.escape(html) .. "\")\n"
                            html = ""
                        end
                        local b, f = line:find("%?>%s*$")
                        if b then
                            pro = pro .. line:sub(e + 1, b - 1) .. "\n"
                        else
                            pro = pro .. line:sub(e + 1) .. "\n"
                            mtbegin = not mtbegin
                        end
                    else
                        pro = pro .. line:sub(0, s - 1) .. "\n"
                        mtbegin = not mtbegin
                    end
                else -- no match
                    if mtbegin then
                        -- detect if we have inline lua with format <?=..?>
                        local b, f = line:find("<%?=")
                        if b then
                            local tmp = line
                            pro = pro .. "echo("
                            while (b) do
                                -- find the close
                                local x, y = tmp:find("%?>")
                                if x then
                                    pro = pro .. "\"" .. utils.escape(html .. tmp:sub(0, b - 1):gsub("%%", "%%%%")) ..
                                              "\".."
                                    pro = pro .. tmp:sub(f + 1, x - 1) .. ".."
                                    html = ""
                                    tmp = tmp:sub(y + 1)
                                    b, f = tmp:find("<%?=")
                                else
                                    error("Syntax error near line " .. i)
                                end
                            end
                            pro = pro .. "\"" .. utils.escape(tmp:gsub("%%", "%%%%")) .. "\")\n"
                        else
                            html = html .. ulib.trim(line, " "):gsub("%%", "%%%%") .. "\n"
                        end
                    else
                        if line ~= "" then
                            pro = pro .. line .. "\n"
                        end
                    end
                end
            end
            i = i + 1
        end
        f:close()
        if (html ~= "") then
            pro = pro .. "echo(\"" .. utils.escape(html) .. "\")\n"
        end
        pro = pro .. "\nend \n return fn"
        local r, e = load(pro)
        if r then
            return r(), e
        else
            return nil, e
        end
    end
end

-- logging helpers
function LOG_INFO(fmt, ...)
    fcgio:log_info(string.format(fmt or "LOG", ...))
end

function LOG_ERROR(fmt, ...)
    fcgio:log_error(string.format(fmt or "ERROR", ...))
end

function LOG_DEBUG(fmt, ...)
    fcgio:log_debug(string.format(fmt or "ERROR", ...))
end

function LOG_WARN(fmt, ...)
    fcgio:log_warn(string.format(fmt or "ERROR", ...))
end

-- decode post data if any
local decode_request_data = function()
    -- decode POST request data
    if _SERVER["RAW_DATA"] then
        if REQUEST.method == "POST" and HEADER["Content-Type"] == "application/x-www-form-urlencoded" then
            for k, v in pairs(utils.parse_query(tostring(_SERVER["RAW_DATA"]))) do
                REQUEST[k] = v
            end
        else
            local ctype = HEADER['Content-Type']
            local clen = HEADER['Content-Length'] or -1
            if clen then
                clen = tonumber(clen)
            end
            if not ctype or clen == -1 then
                LOG_ERROR("Invalid content type %s or content length %d", ctype, clen)
                return 400, "Bad Request, missing content description"
            end
            if ctype:find("application/json") then
                REQUEST.json = tostring(_SERVER["RAW_DATA"])
            else
                REQUEST[ctype] = _SERVER["RAW_DATA"]
            end
        end
    end
    return 0
end

-- define old fashion global request object
HEADER = {}
setmetatable(HEADER, {
    __index = function(o, data)
        local key = "HTTP_" .. string.upper(data:gsub("-", "_"))
        return _SERVER[key]
    end
})
HEADER.mobile = false
if HEADER["User-Agent"] and HEADER["User-Agent"]:match("Mobi") then
    HEADER.mobile = true
end

REQUEST = {}
-- decode GET request
if _SERVER["QUERY_STRING"] then
    REQUEST = utils.parse_query(_SERVER["QUERY_STRING"])
end
REQUEST.method = _SERVER["REQUEST_METHOD"]

-- set session
SESSION = {}
if HEADER["Cookie"] then
    for key, val in HEADER["Cookie"]:gmatch("([^;=]+)=*([^;]*)") do
        SESSION[ulib.trim(key," ")] = ulib.trim(val, " ")
    end
end

-- multipart request
REQUEST.multipart = {}
for key,val in pairs(_SERVER) do
    local s,e,v = key:find("MULTIPART%[(.*)%]")
    if s then
        REQUEST.multipart[v] = val
    end
end

local code, error = decode_request_data()

if code ~= 0 then
    LOG_ERROR(error)
    std.error(code, error)
    return false
end

return true
