BaseObject = Object:extends{registry = {}, class="BaseObject"}
function BaseObject:subclass(name, args)
    _G[name] = self:extends(args)
    _G[name].class = name
end

function BaseObject:log(level,msg,...)
    if self.registry.logger then
        self.registry.logger:log(level, msg,...)
    end
end

function BaseObject:debug(msg,...)
    self:log(Logger.DEBUG, msg,...)
end

function BaseObject:info(msg,...)
    self:log(Logger.INFO, msg,...)
end

function BaseObject:warn(msg,...)
    self:log(Logger.WARN, msg,...)
end

function BaseObject:print()
    self:debug(self.class)
end

function BaseObject:error(msg,...)
    html()
    --local line = debug.getinfo(1).currentline
    local emsg = string.format(msg or "ERROR",...)
    echo(emsg)
    self:log(Logger.ERROR, msg,...)
    error(emsg)
    return false
end