--define the class
BaseObject:subclass("Router", {registry = {}})
function Router:setPath(path)
    self.path = path
end

function Router:initialize()
    self.routes = {}
    self.remaps = {}
end

--function Router:setArgs(args)
--    self.args = args
--end

--function Router:arg(name)
--    return self.args[name]
--end

function Router:infer(url)
    -- a controller is like this /a/b/c/d/e
    -- a is controller name
    -- b is action
    -- c,d,e is parameters
    -- if user dont provide the url, try to infer it
    -- from the REQUEST
    url = url or REQUEST.r or ""
    url = std.trim(url, "/")
    local args = explode(url, "/")
    local data = {
        name = "index",
        action = "index",
        args = {}
    }
    if args and #args > 0 and args[1] ~= "" then
        data.name = args[1]:gsub("%.", "")
        if args[2] then
            data.action = args[2]:gsub("%.", "")
        end
        for i = 3, #args do
            table.insert(data.args, args[i])
        end
    end

    -- remap if needed
    if self.remaps[data.name] ~= nil then
        data.name = self.remaps[data.name]
    end
    -- find the controller class and init it
    local controller_name = firstToUpper(data.name) .. "Controller"
    local controller_path = self.path .. "." .. controller_name
    -- require the controller module
    -- ignore the error
    local r, e = pcall(require, controller_path)
    --require(controller_path)
    if not _G[controller_name] then
        -- verify if it is an asset
        url = url:gsub("/", DIR_SEP)
        local filepath = WWW_ROOT..DIR_SEP..url
        if ulib.exists(filepath)  then -- and not std.is_dir(filepath)
            data.controller = AssetController:new {registry = self.registry}
            data.action = "get"
            data.name = "asset"
            data.args ={url}
        else
            -- let the notfound controller handle the error
            data.controller = NotfoundController:new {registry = self.registry}
            data.args = {controller_name, e}
            data.action = "index"
            data.name = "notfound"
        end
    else
        -- create the coresponding controller
        data.controller = _G[controller_name]:new {registry = self.registry}
        if not data.controller[data.action] then
            --data.args = {data.action}
            table.insert(data.args, 1, data.action)
            data.action = "actionnotfound"
        end
    end

    self:log("Controller: " .. data.controller.class .. ", action: "..data.action..", args: ".. JSON.encode(data.args))
    return data
end

function Router:delegate()
    local views = {}
    local data = self:infer()
    -- set the controller to the main controller
    data.controller.main = true
    views.__main__ = self:call(data)
    if not views.__main__ then
        --self:error("No view available for this action")
        return
    end
    -- get all visible routes
    local routes = self:dependencies(data.name .. "/" .. data.action)
    for k, v in pairs(routes) do
        data = self:infer(v)
        views[k] = self:call(data)
    end
    -- now require the main page to put the view
    local view_args = {}
    local view_argv = {}
    for k,v in pairs(views) do
        table.insert( view_args, k )
        table.insert( view_argv, v )
    end

    local fn, e = loadscript(VIEW_ROOT .. DIR_SEP .. self.registry.layout .. DIR_SEP .. "layout.ls", view_args)
    html()
    if fn then
        local r, o = pcall(fn, table.unpack(view_argv))
        if not r then
            self:error(o)
        end
    else
        e = e or ""
        self:error("The index page is not found for layout: " .. self.registry.layout..": "..e)
    end
end

function Router:dependencies(url)
    if not self.routes[self.registry.layout] then
        return {}
    end
    local list = {}
    --self:log("comparing "..url)
    for k, v in pairs(self.routes[self.registry.layout]) do
        v.url = std.trim(v.url, "/")
        if v.visibility == "ALL" then
            list[k] = v.url
        elseif v.visibility.routes then
            if v.visibility.shown == true or v.visibility.shown == nil then
                if v.visibility.routes[url] then
                    list[k] = v.url
                end
            else
                if not v.visibility.routes[url] then
                    list[k] = v.url
                end
            end
        end
    end
    return list
end

function Router:call(data)
    data.controller.template:setView(data.action, data.name)
    local obj = data.controller[data.action](data.controller, table.unpack(data.args))
    if obj then
        return data.controller.template
    else
        return false
    end
end

function Router:remap(from, to)
    self.remaps[from] = to
end

function Router:route(layout, dependencies)
    self.routes[layout] = dependencies
end
