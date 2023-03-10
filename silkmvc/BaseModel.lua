-- create class
BaseObject:subclass("BaseModel", {registry = {}})

function BaseModel:initialize()
    self.db = self.registry.db
    if self.db and self.name and self.name ~= "" and self.fields and
        not self.db:available(self.name) then
        self.db:createTable(self.name, self.fields)
    end
end

function BaseModel:create(m)
    if self.db and m then return self.db:insert(self.name, m) end
    return false
end

function BaseModel:update(m)
    if self.db and m then return self.db:update(self.name, m) end
    return false
end

function BaseModel:delete(cond)
    if self.db and cond then return self.db:delete(self.name, cond) end
    return false
end

function BaseModel:find(cond)
    if self.db and cond then return self.db:find(self.name, cond) end
    return false
end

function BaseModel:get(id)
    return self.db:get(self.name, id)
end

function BaseModel:findAll()
    if self.db then return self.db:getAll(self.name) end
    return false
end

function BaseModel:query(sql)
    if self.db then return self.db:query(sql) end
    return false
end

function BaseModel:select(sel, sql_cnd)
    local sql = string.format("SELECT %s FROM %s WHERE %s;", sel, self.name, sql_cnd)
    if self.db then return self.db:query(sql) end
    return nil
end
