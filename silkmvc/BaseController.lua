-- create class
BaseObject:subclass("BaseController",
    {
        registry = {},
        models = {},
        main = false
    })
    
-- set the name here in each subclasses
function BaseController:initialize()
    for k, v in pairs(self.models) do
        --- infer the class here
        local modelname = firstToUpper(v).."Model"
        local path = MODEL_ROOT.."."..modelname
        -- require it
        pcall(require, path)
        --require(controller_path)
        if not _G[modelname] then
            self:modelnotfound(v)
        else
            -- create new model object
            self[v] = _G[modelname]:new{registry = self.registry}
        end
    end
    -- create template
    self.template = Template:new{registry = self.registry}
end

function BaseController:print(...)
    return self:actionnotfound("print")
end

function BaseController:redirect(url)
    std.status(301, "Moved Permanently")
    std.custom_header("Content-Type","text/html")
    std.custom_header("Location", url)
    std.header_flush()
end

function BaseController:switchLayout(name)
    if self.main then
        self.registry.layout = name
    else
        self:log("Cannot switch layout since the controller "..self.class.." is not the main controller")
    end
end

function BaseController:setSession(key, value)
    SESSION[key] = value
end
function BaseController:getSession(key)
    return SESSION[key]
end
function BaseController:removeSession(key)
    self:setSession(key, nil)
end
function BaseController:index(...)
    self:error("#index: subclasses responsibility")
end

-- not found action
function BaseController:actionnotfound(...)
    local args = {...}
    self:error("#action "..args[1].." is not found in controller "..self.class)
end
-- not found model
function BaseController:modelnotfound(...)
    local args = {...}
    self:error("Model "..firstToUpper(args[1]).."Model is not found in controller "..self.class)
end
-- The not found controller

BaseController:subclass("NotfoundController",{ registry = {}, models = {} })

function NotfoundController:index(...)
    local args = {...}
    local error = args[2] or ""
    if self.template:path() then
        self.template:set("error", error)
        self.template:set("title", "404 not found")
        return true
    end
    self:error("404: Controller "..args[1].." not found : "..error)
    return false
end

-- The asset controller for the static file
BaseController:subclass("AssetController", {registry={}, models={}})
function AssetController:index(...)
    local args = {...}
    return self:get(table.unpack(args))
end

function AssetController:get(...)
    local path = WWW_ROOT..DIR_SEP..implode({...}, DIR_SEP)

    if self.registry.fileaccess and ulib.exists(path) then
        local mime = std.mimeOf(path)
        if POLICY.mimes[mime] then
            std.sendFile(path)
        else 
            self:error("Access forbidden: "..path)
        end
    else
        self:error("Asset file not found or access forbidden: "..path)
    end
    return false
end