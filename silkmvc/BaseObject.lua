BaseObject = Object:extends{registry = {}, class="BaseObject"}
function BaseObject:subclass(name, args)
    _G[name] = self:extends(args)
    _G[name].class = name
end

function BaseObject:log(msg, level)
    level = level or "INFO"
    if self.registry.logger then
        self.registry.logger:log(msg,level)
    end
end

function BaseObject:debug(msg)
    self:log(msg, "DEBUG")
end

function BaseObject:print()
    print(self.class)
end

function BaseObject:error(msg, trace)
    html()
    --local line = debug.getinfo(1).currentline
    echo(msg)
    self:log(msg,"ERROR")
    if trace then
        debug.traceback=nil
        error(msg)
    else
        error(msg)
    end
    return false
end