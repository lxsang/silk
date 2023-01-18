sqlite =  modules.sqlite()

if sqlite == nil then return 0 end
require("OOP")
-- create class
DBModel = Object:inherit{db=nil, name=''}

function DBModel:createTable(m)
	if self:available() then return true end
	local sql = "CREATE TABLE "..self.name.."(id INTEGER PRIMARY KEY"
	for k, v in pairs(m) do
		if k ~= "id" then
			sql = sql..","..k.." "..v
		end
	end
	sql = sql..");"
	return sqlite.query(self.db,sql) == 1 
end

function DBModel:insert(m)
	local keys = {}
	local values = {}
	for k,v in pairs(m) do
		if k ~= "id" then
			table.insert(keys,k)
			if type(v) == "number" then
				table.insert(values, v)
			elseif type(v) == "boolean" then
				table.insert( values, v and 1 or 0 )
			else
				local t = "\""..v:gsub('"', '""').."\""
				table.insert(values,t)
			end
		end
	end
	local sql = "INSERT INTO "..self.name.." ("..table.concat(keys,',')..') VALUES ('
	sql = sql..table.concat(values,',')..');'
	return sqlite.query(self.db, sql) == 1
end

function DBModel:get(id)
	return sqlite.select(self.db, self.name, "*","id="..id)[1]
end

function DBModel:getAll()
	--local sql = "SELECT * FROM "..self.name
	--return sqlite.select(self.db, self.name, "1=1")
	local data = sqlite.select(self.db, self.name, "*", "1=1")
	if data == nil then return nil end
	local a = {}
	for n in pairs(data) do table.insert(a, n) end
	table.sort(a)
	return data, a
end

function DBModel:find(cond)
	local cnd = "1=1"
	local sel = "*"
	if cond.exp then
		cnd = self:gencond(cond.exp)
	end
	if cond.order then
		cnd = cnd.." ORDER BY "
		local l = {}
		local i = 1
		for k,v in pairs(cond.order) do
			l[i] = k.." "..v
			i = i+1
		end
		cnd = cnd..table.concat(l, ",")
	end
	if cond.limit then
		cnd = cnd.." LIMIT "..cond.limit
	end
	if cond.fields then
		sel = table.concat(cond.fields, ",")
		--print(sel)
	end
	--print(cnd)
	local data = sqlite.select(self.db, self.name, sel, cnd)
	if data == nil then return nil end
	local a = {}
	for n in pairs(data) do table.insert(a, n) end
	table.sort(a)
	return data, a
end

function DBModel:query(sql)
	return sqlite.query(self.db, sql) == 1
end

function DBModel:update(m)
	local id = m['id']
	if id ~= nil then
		local lst = {}
		for k,v in pairs(m) do
			if(type(v)== "number") then
				table.insert(lst,k.."="..v)
			elseif type(v) == "boolean" then
				table.insert( lst, k.."="..(v and 1 or 0) )
			else
				table.insert(lst,k.."=\""..v:gsub('"', '""').."\"")
			end
		end
		local sql = "UPDATE "..self.name.." SET "..table.concat(lst,",").." WHERE id="..id..";"
		return sqlite.query(self.db, sql) == 1
	end
	return false
end

function DBModel:available()
	return sqlite.hasTable(self.db, self.name) == 1
end
function DBModel:deleteByID(id)
	local sql = "DELETE FROM "..self.name.." WHERE id="..id..";"
	return sqlite.query(self.db, sql) == 1
end
function DBModel:gencond(o)
	for k,v	in pairs(o) do
		if k == "and" or k == "or" then
			local cnd = {}
			local i = 1
			for k1,v1 in pairs(v) do
				cnd[i] = self:gencond(v1)
				i = i + 1
			end
			return " ("..table.concat(cnd, " "..k.." ")..") "
		else
			for k1,v1 in pairs(v) do
				local t = type(v1)
				if(t == "string") then
					return " ("..k1.." "..k..' "'..v1:gsub('"','""')..'") '
				end
				return  " ("..k1.." "..k.." "..v1..") "
			end 
		end
	end
end
function DBModel:delete(cond)
	local sql = "DELETE FROM "..self.name.." WHERE "..self:gencond(cond)..";"
	return sqlite.query(self.db, sql) == 1
end

function DBModel:lastInsertID()
	return sqlite.lastInsertID(self.db)
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