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

--- SQL generator
SQLQueryGenerator = Object:extends{}

function SQLQueryGenerator:initialize()
end

function SQLQueryGenerator:parse()
    local j, w, o, f
    j = self:sql_joins()
    if self.where then
        w = self:sql_where("$and", self.where)
    end
    f = self:sql_fields()
    o = self:sql_order()
    return f, w, j, o
end

function SQLQueryGenerator:sql_select()
    local v, f, w, j, o = pcall(SQLQueryGenerator.parse, self)
    if not v then
        return v, f
    end
    local segments = {"SELECT"}
    if f then
        table.insert(segments, f)
    else
        table.insert(segments, "*")
    end
    table.insert(segments, "FROM")
    table.insert(segments, self.table_name)
    if j then
        table.insert(segments, j)
    end
    if w then
        table.insert(segments, "WHERE")
        table.insert(segments, w)
    end

    if o then
        table.insert(segments, "ORDER BY")
        table.insert(segments, o)
    end

    return true, table.concat(segments, " ")
end

function SQLQueryGenerator:sql_delete()
    local v, f, w, j, o = pcall(SQLQueryGenerator.parse, self)
    if not v then
        return v, f
    end
    local segments = {"DELETE"}
    table.insert(segments, "FROM")
    table.insert(segments, self.table_name)
    if j then
        table.insert(segments, j)
    end
    if w then
        table.insert(segments, "WHERE")
        table.insert(segments, w)
    end
    return true, table.concat(segments, " ")
end

function SQLQueryGenerator:error(msg, ...)
    local emsg = string.format(msg or "ERROR", ...)
    LOG_ERROR(msg, ...)
    error(emsg)
end

function SQLQueryGenerator:infer_field(k)
    if not self.table_name then
        self:error("Unknown input table (specified by `table_name` field)")
    end
    if not self.joins then
        return k
    end
    if k:match("%.") then
        return k
    end
    return string.format("%s.%s", self.table_name, k)
end

function SQLQueryGenerator:sql_joins()
    if not self.joins then
        return nil
    end
    local joins = {}
    for k, v in pairs(self.joins) do
        local arr = explode(v, ".")
        if not arr[2] then
            self:error("SQL JOIN: Other table name parsing error: " .. v)
        end
        table.insert(joins, string.format("INNER JOIN %s ON %s = %s", arr[1], self:infer_field(k), v))
    end
    return table.concat(joins, " ")
end

function SQLQueryGenerator:sql_fields()
    if not self.fields then
        return nil
    end
    local arr = {}
    for k, v in ipairs(self.fields) do
        arr[k] = self:infer_field(v)
    end
    return string.format("(%s)", table.concat(arr, ","))
end

function SQLQueryGenerator:sql_order()
    local tb = {}
    for k, v in ipairs(self.order) do
        local arr = explode(v, "$")
        if #arr ~= 2 then
            self:error("Invalid field order format %s", v)
        end
        if arr[2] == "asc" then
            table.insert(tb, self:infer_field(arr[1]) .. " ASC")
        elseif arr[2] == "desc" then
            table.insert(tb, self:infer_field(arr[1]) .. " DESC")
        else
            self:error("Unknown order %s", arr[2])
        end
    end
    return table.concat(tb, ",")
end

function SQLQueryGenerator:sql_where(cond, obj)
    if not obj then
        self:error("%s condition is nil", cond)
    end
    local conds = {}
    local op = " AND "
    if cond == "$or" then
        op = " OR "
    end
    if type(obj) ~= 'table' then
        self:error("Invalid input data for operator " .. cond)
    end
    for k, v in pairs(obj) do
        if k == "$and" or k == "$or" then
            table.insert(conds, self:sql_where(k, v))
        else
            table.insert(conds, self:binary(k, v))
        end
    end

    return string.format("(%s)", table.concat(conds, op))
end

function SQLQueryGenerator:parse_value(v, types)
    if not types[type(v)] then
        self:error("Type error: unexpected type %d", type(v))
    end
    if type(v) == "number" then
        return tostring(v)
    end
    if type(v) == "string" then
        return string.format("'%s'", v:gsub("'", "''"))
    end
end
function SQLQueryGenerator:binary(k, v)
    local arr = explode(k, "$");
    if #arr > 2 then
        self:error("Invalid left hand side format: %s", k)
    end
    if #arr == 2 then
        if arr[2] == "gt" then
            return string.format("(%s > %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['number'] = true
            }))
        elseif arr[2] == "gte" then
            return string.format("(%s >= %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['number'] = true
            }))
        elseif arr[2] == "lt" then
            return string.format("(%s < %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['number'] = true
            }))
        elseif arr[2] == "lte" then
            return string.format("(%s <= %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['number'] = true
            }))
        elseif arr[2] == "ne" then
            return string.format("(%s != %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['number'] = true,
                ['string'] = true
            }))
        elseif arr[2] == "between" then
            return string.format("(%s BETWEEN %s AND %s)", self:infer_field(arr[1]), self:parse_value(v[1], {
                ['number'] = true
            }), self:parse_value(v[2], {
                ['number'] = true
            }))
        elseif arr[2] == "not_between" then
            return string.format("(%s NOT BETWEEN %s AND %s)", self:infer_field(arr[1]), self:parse_value(v[1], {
                ['number'] = true
            }), self:parse_value(v[2], {
                ['number'] = true
            }))
        elseif arr[2] == "in" then
            return string.format("(%s IN [%s,%s])", self:infer_field(arr[1]), self:parse_value(v[1], {
                ['number'] = true
            }), self:parse_value(v[2], {
                ['number'] = true
            }))
        elseif arr[2] == "not_in" then
            return string.format("(%s NOT IN [%s,%s])", self:infer_field(arr[1]), self:parse_value(v[1], {
                ['number'] = true
            }), self:parse_value(v[2], {
                ['number'] = true
            }))
        elseif arr[2] == "like" then
            return string.format("(%s LIKE %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['string'] = true
            }))
        elseif arr[2] == "not_like" then
            return string.format("(%s NOT LIKE %s)", self:infer_field(arr[1]), self:parse_value(v, {
                ['string'] = true
            }))
        else
            self:error("Unsupported operator `%s`", arr[2])
        end
    else
        return string.format("(%s=%s)", self:infer_field(arr[1]), self:parse_value(v, {
            ['number'] = true,
            ['string'] = true
        }))
    end
end

--- create class DBModel
--- TODO: This class shall use the SQLQueryGenerator to create the query
DBModel = Object:inherit{
    db = nil
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
    local records = self:query(string.format("SELECT * FROM %s WHERE id=%d", name, id))
    if records and #records == 1 then
        return records[1]
    end
    return nil
end

function DBModel:getAll(name)
    local data = self:query("SELECT * FROM " .. name)
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
    local data = self:query(string.format("SELECT %s FROM %s WHERE %s", sel, name, cnd))
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
    -- LOG_DEBUG(sql)
    if not data then
        LOG_ERROR("Error querying recorda SQL[%s]: %s", sql, error or "")
        return nil
    end
    return data
end

function DBModel:exec(sql)
    -- LOG_DEBUG(sql)
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
