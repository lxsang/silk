sqlite = modules.sqlite()

if sqlite == nil then return 0 end
-- create class
BaseObject:subclass("DBHelper", {db = {}})

function DBHelper:createTable(tbl, m)
    if self:available(tbl) then return true end
    local sql = "CREATE TABLE " .. tbl .. "(id INTEGER PRIMARY KEY"
    for k, v in pairs(m) do
        if k ~= "id" then sql = sql .. "," .. k .. " " .. v end
    end
    sql = sql .. ");"
    return sqlite.query(self.db, sql) == 1
end

function DBHelper:insert(tbl, m)
    local keys = {}
    local values = {}
    for k, v in pairs(m) do
        if k ~= "id" then
            table.insert(keys, k)
            if type(v) == "number" then
                table.insert(values, v)
            else
                local t = "\"" .. v:gsub('"', '""') .. "\""
                table.insert(values, t)
            end
        end
    end
    local sql = "INSERT INTO " .. tbl .. " (" .. table.concat(keys, ',') ..
                    ') VALUES ('
    sql = sql .. table.concat(values, ',') .. ');'
    return sqlite.query(self.db, sql) == 1
end

function DBHelper:get(tbl, id)
    return sqlite.select(self.db, tbl, "*", "id=" .. id)[1]
end

function DBHelper:getAll(tbl)
    local data = sqlite.select(self.db, tbl, "*", "1=1")
    if data == nil then return nil end
    local a = {}
    for n in pairs(data) do table.insert(a, n) end
    table.sort(a)
    return data, a
end

function DBHelper:find(tbl, cond)
    local cnd = "1=1"
    local sel = "*"
    if cond.exp then cnd = self:gencond(cond.exp) end
    if cond.order then
        cnd = cnd .. " ORDER BY "
        local l = {}
        local i = 1
        for k, v in pairs(cond.order) do
            l[i] = k .. " " .. v
            i = i + 1
        end
        cnd = cnd .. table.concat(l, ",")
    end
    if cond.limit then cnd = cnd .. " LIMIT " .. cond.limit end
    if cond.fields then
        sel = table.concat(cond.fields, ",")
        -- print(sel)
    end
    local data = sqlite.select(self.db, tbl, sel, cnd)
    if data == nil then return nil end
    local a = {}
    for n in pairs(data) do table.insert(a, n) end
    table.sort(a)
    return data, a
end

function DBHelper:select(tbl, sel, cnd)
    local data = sqlite.select(self.db, tbl, sel, cnd)
    if data == nil then return nil end
    local a = {}
    for n in pairs(data) do table.insert(a, n) end
    table.sort(a)
    return data, a
end

function DBHelper:query(sql) return sqlite.query(self.db, sql) == 1 end

function DBHelper:update(tbl, m)
    local id = m['id']
    if id ~= nil then
        local lst = {}
        for k, v in pairs(m) do
            if (type(v) == "number") then
                table.insert(lst, k .. "=" .. v)
            else
                table.insert(lst, k .. "=\"" .. v:gsub('"', '""') .. "\"")
            end
        end
        local sql = "UPDATE " .. tbl .. " SET " .. table.concat(lst, ",") ..
                        " WHERE id=" .. id .. ";"
        return sqlite.query(self.db, sql) == 1
    end
    return false
end

function DBHelper:available(tbl) return sqlite.hasTable(self.db, tbl) == 1 end
function DBHelper:deleteByID(tbl, id)
    local sql = "DELETE FROM " .. tbl .. " WHERE id=" .. id .. ";"
    return sqlite.query(self.db, sql) == 1
end
function DBHelper:gencond(o)
    for k, v in pairs(o) do
        if k == "and" or k == "or" then
            local cnd = {}
            local i = 1
            for k1, v1 in pairs(v) do
                cnd[i] = self:gencond(v1)
                i = i + 1
            end
            return " (" .. table.concat(cnd, " " .. k .. " ") .. ") "
        else
            for k1, v1 in pairs(v) do
                local t = type(v1)
                if (t == "string") then
                    return
                        " (" .. k1 .. " " .. k .. ' "' .. v1:gsub('"', '""') ..
                            '") '
                end
                return " (" .. k1 .. " " .. k .. " " .. v1 .. ") "
            end
        end
    end
end
function DBHelper:delete(tbl, cond)
    local sql = "DELETE FROM " .. tbl .. " WHERE " .. self:gencond(cond) .. ";"
    return sqlite.query(self.db, sql) == 1
end

function DBHelper:lastInsertID() return sqlite.lastInsertID(self.db) end

function DBHelper:close() if self.db then sqlite.dbclose(self.db) end end
function DBHelper:open()
    if self.db ~= nil then self.db = sqlite.getdb(self.db) end
end
