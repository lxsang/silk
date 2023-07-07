utils = {}

function utils.is_array(table)
    local max = 0
    local count = 0
    for k, v in pairs(table) do
        if type(k) == "number" then
            if k > max then
                max = k
            end
            count = count + 1
        else
            return false
        end
    end
    if max > count * 2 then
        return false
    end

    return true
end

function utils.escape(s, ignore_percent)
    local replacements = {
        ["\\"] = "\\\\",
        ['"'] = '\\"',
        ["\n"] = "\\n",
        ["\t"] = "\\t",
        ["\b"] = "\\b",
        ["\f"] = "\\f",
        ["\r"] = "\\r"
    }
    if not ignore_percent then
        replacements["%"] = "%%"
    end
    return (s:gsub("[\\'\"\n\t\b\f\r%%]", replacements))
end

function utils.escape_pattern(s)
    return s:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
end

function utils.unescape_pattern(s)
    return s:gsub("[%%]", "%%%%")
end

function utils.hex_to_char(x)
    return string.char(tonumber(x, 16))
end

function utils.decodeURI(url)
    return url:gsub("%%(%x%x)", utils.hex_to_char):gsub('+', ' ')
end

function utils.unescape(s)
    local str = ""
    local escape = false
    local esc_map = {
        b = '\b',
        f = '\f',
        n = '\n',
        r = '\r',
        t = '\t'
    }
    for c in s:gsub("%%%%", "%%"):gmatch "." do
        if c ~= '\\' then
            if escape then
                if esc_map[c] then
                    str = str .. esc_map[c]
                else
                    str = str .. c
                end
            else
                str = str .. c
            end
            escape = false
        else
            if escape then
                str = str .. c
                escape = false
            else
                escape = true
            end
        end
    end
    return str
end

function utils.file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function utils.parse_query(str, sep)
    if not sep then
        sep = '&'
    end

    local values = {}
    for key, val in str:gmatch(string.format('([^%q=]+)(=*[^%q=]*)', sep, sep)) do
        local key = utils.decodeURI(key)
        local keys = {}
        key = key:gsub('%[([^%]]*)%]', function(v)
            -- extract keys between balanced brackets
            if string.find(v, "^-?%d+$") then
                v = tonumber(v)
            else
                v = utils.decodeURI(v)
            end
            table.insert(keys, v)
            return "="
        end)
        key = key:gsub('=+.*$', "")
        key = key:gsub('%s', "_") -- remove spaces in parameter name
        val = val:gsub('^=+', "")

        if not values[key] then
            values[key] = {}
        end
        if #keys > 0 and type(values[key]) ~= 'table' then
            values[key] = {}
        elseif #keys == 0 and type(values[key]) == 'table' then
            values[key] = utils.decodeURI(val)
        elseif type(values[key]) == 'string' then
            values[key] = {values[key]}
            table.insert(values[key], utils.decodeURI(val))
        end

        local t = values[key]
        for i, k in ipairs(keys) do
            if type(t) ~= 'table' then
                t = {}
            end
            if k == "" then
                k = #t + 1
            end
            if not t[k] then
                t[k] = {}
            end
            if i == #keys then
                t[k] = val
            end
            t = t[k]
        end
    end
    return values
end

function utils.url_parser(uri)
    local pattern = "^(https?)://([%.%w]+):?(%d*)(/?[^#]*)#?.*$"
    local obj = {}
    obj.protocol = uri:gsub(pattern, "%1")
    obj.hostname = uri:gsub(pattern, "%2")
    obj.port = uri:gsub(pattern, "%3")
    obj.query = uri:gsub(pattern, "%4")

    if obj.port == "" then
        obj.port = 80
    else
        obj.port = tonumber(obj.port)
    end
    if obj.query == "" then
        obj.query = "/"
    end
    return obj
end

JSON = require("json")

function JSON.encode(obj)
    local t = type(obj)
    if t == 'table' then
        -- encode object
        if utils.is_array(obj) == false then
            local lst = {}
            for k, v in pairs(obj) do
                table.insert(lst, '"' .. k .. '":' .. JSON.encode(v))
            end
            return "{" .. table.concat(lst, ",") .. "}"
        else
            local lst = {}
            local a = {}
            for n in pairs(obj) do
                table.insert(a, n)
            end
            table.sort(a)
            for i, v in pairs(a) do
                table.insert(lst, JSON.encode(obj[v]))
            end
            return "[" .. table.concat(lst, ",") .. "]"
        end
    elseif t == 'string' then
        -- print('"'..utils.escape(obj)..'"')
        -- ignore % escape as this is for a LUA using
        return '"' .. utils.escape(obj, true) .. '"'
    elseif t == 'boolean' or t == 'number' then
        return tostring(obj)
    elseif obj == nil then
        return "null"
    else
        return '"' .. tostring(obj) .. '"'
    end
end

function explode(str, div) -- credit: http://richard.warburton.it
    if (div == '') then
        return false
    end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function()
        return string.find(str, div, pos, true)
    end do
        table.insert(arr, string.sub(str, pos, st - 1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
    table.insert(arr, string.sub(str, pos)) -- Attach chars right of last divider
    return arr
end
function implode(arr, div)
    return table.concat(arr, div)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"

function utils.generate_salt(length)
    local ret = {}
    local r
    for i = 1, length do
        r = math.random(1, #charset)
        table.insert(ret, charset:sub(r, r))
    end
    return table.concat(ret)
end

function utils.ext(path)
	return path:match("%.([^%.]*)$")
end

function utils.basename(str)
    local name = string.gsub(ulib.trim(str, "/"), "(.*/)(.*)", "%2")
    return name
end