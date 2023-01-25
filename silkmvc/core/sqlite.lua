sqlite = require("sqlitedb")

if sqlite == nil then
    return 0
end

require("silk.core.OOP")

sqlite.getdb = function(name)
    if name:find("%.db$") then
        return sqlite.db(name)
    elseif name:find("/") then
        LOG_ERROR("Invalid database name %s", name)
        return nil
    else
        return sqlite.db(__api__.dbpath .. "/" .. name .. ".db")
    end
end

-- create class
DBModel = Object:inherit{
    db = nil,
}

function DBModel:createTable(name, m)
    if self:available() then
        return true
    end
    local sql = "CREATE TABLE " .. name .. "(id INTEGER PRIMARY KEY"
    for k, v in pairs(m) do
        if k ~= "id" then
            sql = sql .. "," .. k .. " " .. v
        end
    end
    sql = sql .. ");"
    return self:exec(sql)
end

function DBModel:insert(name, m)
    local keys = {}
    local values = {}
    for k, v in pairs(m) do
        if k ~= "id" then
            table.insert(keys, k)
            if type(v) == "number" then
                table.insert(values, v)
            elseif type(v) == "boolean" then
                table.insert(values, v and 1 or 0)
            else
                local t = "\"" .. v:gsub('"', '""') .. "\""
                table.insert(values, t)
            end
        end
    end
    local sql = "INSERT INTO " .. name .. " (" .. table.concat(keys, ',') .. ') VALUES ('
    sql = sql .. table.concat(values, ',') .. ');'
    return self:exec(sql)
end

function DBModel:get(name, id)
    local records = self:query( string.format("SELECT * FROM %s WHERE id=%d", name, id))
    if records and #records == 1 then
        return records[1]
    end
    return nil
end

function DBModel:getAll(name)
    local data = self:query( "SELECT * FROM " .. name)
    if not data then
        return nil
    end
    local a = {}
    for n in pairs(data) do
        table.insert(a, n)
    end
    table.sort(a)
    return data, a
end

function DBModel:find(name, cond)
    local cnd = "1=1"
    local sel = "*"
    if cond.exp then
        cnd = self:gencond(cond.exp)
    end
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
    if cond.limit then
        cnd = cnd .. " LIMIT " .. cond.limit
    end
    if cond.fields then
        sel = table.concat(cond.fields, ",")
        -- print(sel)
    end
    -- print(cnd)
    local data = self:query( string.format("SELECT %s FROM %s WHERE %s", sel, name, cnd))
    if data == nil then
        return nil
    end
    local a = {}
    for n in pairs(data) do
        table.insert(a, n)
    end
    table.sort(a)
    return data, a
end

function DBModel:query(sql)
    local data, error = sqlite.query(self.db, sql)
    --LOG_DEBUG(sql)
    if not data then
        LOG_ERROR("Error querying recorda SQL[%s]: %s", sql, error or "")
        return nil
    end
    return data
end

function DBModel:exec(sql)
    --LOG_DEBUG(sql)
    local ret, err = sqlite.exec(self.db, sql)
    if not ret then
        LOG_ERROR("Error execute [%s]: %s", sql, err or "")
    end
    return ret == true
end

function DBModel:update(name, m)
    local id = m['id']
    if id ~= nil then
        local lst = {}
        for k, v in pairs(m) do
            if (type(v) == "number") then
                table.insert(lst, k .. "=" .. v)
            elseif type(v) == "boolean" then
                table.insert(lst, k .. "=" .. (v and 1 or 0))
            else
                table.insert(lst, k .. "=\"" .. v:gsub('"', '""') .. "\"")
            end
        end
        local sql = "UPDATE " .. name .. " SET " .. table.concat(lst, ",") .. " WHERE id=" .. id .. ";"
        return self:exec(sql)
    end
    return false
end

function DBModel:available(name)
    local records = self:query(string.format("SELECT * FROM sqlite_master WHERE type='table' and name='%s'", name))
    return #records == 1
end
function DBModel:deleteByID(name, id)
    local sql = "DELETE FROM " .. name .. " WHERE id=" .. id .. ";"
    return self:exec(sql)
end
function DBModel:gencond(o)
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
                    return " (" .. k1 .. " " .. k .. ' "' .. v1:gsub('"', '""') .. '") '
                end
                return " (" .. k1 .. " " .. k .. " " .. v1 .. ") "
            end
        end
    end
end
function DBModel:delete(name, cond)
    local sql = "DELETE FROM " .. name .. " WHERE " .. self:gencond(cond) .. ";"
    return self:exec(sql)
end

function DBModel:lastInsertID()
    return sqlite.last_insert_id(self.db)
end

function DBModel:close()
    if self.db then
        sqlite.dbclose(self.db)
    end
end
function DBModel:open()
    if self.db ~= nil then
        self.db = sqlite.getdb(self.db)
    end
end
