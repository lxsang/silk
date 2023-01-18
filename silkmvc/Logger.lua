Logger = Object:extends{levels = {}}

function Logger:initialize()
end

function Logger:log(msg,level)
    if self.levels[level] and ulib.exists(LOG_ROOT) then
        local path = LOG_ROOT..DIR_SEP..level..'.txt'
        local f = io.open(path, 'a')
        local text = '['..level.."]: "..msg
        if f then
            f:write(text..'\n')
            f:close()
        end
        print(text)
    end
end

function Logger:info(msg)
    self:log(msg, "INFO")
end

function Logger:debug(msg)
    self:log(msg, "DEBUG")
end


function Logger:error(msg)
    self:log(msg, "ERROR")
end