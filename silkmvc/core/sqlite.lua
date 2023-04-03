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
    if f and f~= "" then
        table.insert(segments, f)
    else
        table.insert(segments, "*")
    end
    table.insert(segments, "FROM")
    table.insert(segments, self.table_name)
    if j and j~= "" then
        table.insert(segments, j)
    end
    if w  and j ~="" then
        table.insert(segments, "WHERE")
        table.insert(segments, w)
    end

    if o and o ~= "" then
        table.insert(segments, "ORDER BY")
        table.insert(segments, o)
    end

    if self.limit then
        table.insert(segments, "LIMIT "..self.limit)
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
    if j and j ~= "" then
        table.insert(segments, j)
    end
    if w and w ~= "" then
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
    return string.format("%s", table.concat(arr, ","))
end

function SQLQueryGenerator:sql_order()
    if not self.order then return nil end
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
            if type(v) == "table" and not (k:match("%$.*in") or k:match("%$.*between") ) then
                for i,el in ipairs(v) do
                    table.insert(conds, self:binary(k, el))
                end
            else
                table.insert(conds, self:binary(k, v))
            end
        end
    end

    return string.format("(%s)", table.concat(conds, op))
end

function SQLQueryGenerator:parse_value(v, types)
    if not types[type(v)] then
        self:error("Type error: unexpected type %s", type(v))
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
    local vals = {}
    local gen = SQLQueryGenerator:new({})
    for k,v in pairs(m) do
        if k ~= "id" then
            table.insert(keys,k)
            table.insert(vals,gen:parse_value(v, {[type(v)] = true}))
        end
    end
    local sql = string.format("INSERT INTO  %s (%s) VALUES(%s)", name, table.concat(keys,","), table.concat(vals,","))
    LOG_DEBUG("Execute query: [%s]", sql)
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
    local filter = {}
    if cond then
        filter = cond
    end
    filter.table_name = name
    
    local generator = SQLQueryGenerator:new(filter)
    local r,sql = generator:sql_select()
    if not r then
        LOG_ERROR(sql)
        return nil,sql
    end
    LOG_DEBUG("Execute query: %s", sql);

    local data = self:query(sql)
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
        local tb = {}
        local gen = SQLQueryGenerator:new({})
        for k,v in pairs(m) do
            if k ~= "id" then
                table.insert(tb, string.format("%s=%s", k, gen:parse_value(v, {[type(v)] = true})))
            end
        end
        local sql = string.format("UPDATE  %s SET %s  WHERE id = %d", name, table.concat(tb,","), m.id)
        LOG_DEBUG("Execute query: [%s]", sql)
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

function DBModel:delete(name, cond)
    local filter = {}
    if cond then
        filter = cond
    end
    filter.table_name = name

    local generator = SQLQueryGenerator:new(filter)
    local r,sql = generator:sql_delete()
    if not r then
        return error(sql)
    end
    LOG_DEBUG("Execute query: %s", sql);
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
