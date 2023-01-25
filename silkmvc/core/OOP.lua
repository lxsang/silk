Object = {}

function Object:prototype(o)
    o = o or {} -- create table if user does not provide one
    setmetatable(o, self)
    self.__index = self
	self.__tostring = o:tostring()
    return o
end

function Object:new(o)
    local obj = self:prototype(o)
    obj:initialize()
    return obj
end

function Object:tostring()
	return ""
end

function Object:print()
    print(self:tostring())
end

function Object:initialize()
end

function Object:asJSON()
    return '{}'
end

function Object:inherit(o)
    return self:prototype(o)
end

function Object:extends(o)
    return self:inherit(o)
end

