Logger = Object:extends{}

Logger.ERROR = 1
Logger.WARN = 2
Logger.INFO = 3
Logger.DEBUG = 4
Logger.handles = {
    [1] = LOG_ERROR,
    [2] = LOG_WARN,
    [3] = LOG_INFO,
    [4] = LOG_DEBUG
}

function Logger:initialize()
    if not self.level then
        self.level = Logger.INFO
    end
end

function Logger:log(verb,msg,...)
    local level = verb
    if level > self.level then return end
    if level > Logger.DEBUG then
        level = Logger.DEBUG
    end
    Logger.handles[level](msg,...)
end

function Logger:info(msg,...)
    self:log(Logger.INFO, msg,...)
end

function Logger:debug(msg,...)
    self:log(Logger.DEBUG, msg,...)
end

function Logger:error(msg,...)
    self:log(Logger.ERROR, msg,...)
end

function Logger:warn(msg,...)
    self:log(Logger.WARN, msg,...)
end