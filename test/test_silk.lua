--- the binary shall be compiled with
--- make CFLAGS=-DLUA_SLICE_MAGIC=0x8AD73B9F
--- otherwise the tests unable to load C modules

require("lunit")

package.cpath = "/tmp/lib/lua/?.so"
package.path = "/tmp/lib/lua/?.lua"

test("IO setup", function()
    fcgio = { OUTPUT = "",
        LOG = {
            INFO = "",
            ERROR = "",
            DEBUG = "",
            WARN = ""
        }
    }
    function fcgio:flush()
        fcgio.OUTPUT = ""
        fcgio.LOG.INFO = ""
        fcgio.LOG.DEBUG = ""
        fcgio.LOG.WARN = ""
        fcgio.LOG.ERROR = ""
        RESPONSE_HEADER.sent = false
    end
    function fcgio:echo(...)
        local args = table.pack(...)
        for i=1,args.n do
            -- do something with args[i], careful, it might be nil!
            fcgio.OUTPUT = fcgio.OUTPUT..tostring(args[i])
        end
    end
    function fcgio:log_info(fmt,...)
        fcgio.LOG.INFO = string.format(fmt,...)
        io.stderr:write("INFO: ", fcgio.LOG.INFO)
        io.stderr:write("\n")
    end
    function fcgio:log_error(fmt,...)
        fcgio.LOG.ERROR = string.format(fmt,...)
        io.stderr:write("ERROR: ",fcgio.LOG.ERROR)
        io.stderr:write("\n")
    end
    function fcgio:log_debug(fmt,...)
        fcgio.LOG.DEBUG = string.format(fmt,...)
        io.stderr:write("DEBUG: ", fcgio.LOG.DEBUG)
        io.stderr:write("\n")
    end
    function fcgio:log_warn(fmt,...)
        fcgio.LOG.WARN = string.format(fmt,...)
        io.stderr:write("WARN: ", fcgio.LOG.WARN)
        io.stderr:write("\n")
    end
    function fcgio:send_file(path)
        local f = io.open(path, "rb")
        local content = f:read("*all")
        f:close()
        fcgio.OUTPUT = fcgio.OUTPUT..content
    end
end)

test("Setup request", function()
    local json = require("json")
    _SERVER = json.decodeFile("request.json")
    assert(_SERVER ~= nil, "Global _SERVER object not found")
end)

test("SEVER PATH", function()
    expect(_SERVER["LIB_DIR"], "/tmp/lib")
    expect(_SERVER["TMP_DIR"], "/tmp")
    expect(_SERVER["DB_DIR"], "/tmp")
    expect(_SERVER["DOCUMENT_ROOT"], "/tmp/www")
end)

test("Import the api", function()
    local ret = require("silk.api")
end)

test("Lua path", function()
    expect(package.cpath, "/tmp/lib/lua/?.so")
    expect(package.path, "/tmp/lib/lua/?.lua;/tmp/www/?.lua")
    unexpect(ulib, nil)
    unexpect(utils, nil)
    unexpect(std, nil)
end)

test("Logger", function()
    local logger = Logger:new{ level = Logger.ERROR}
    logger:info("Info message")
    logger:debug("Debug message")
    logger:warn("Warning message")
    logger:error("Error message")
    expect(fcgio.LOG.INFO, "")
    expect(fcgio.LOG.DEBUG, "")
    expect(fcgio.LOG.WARN, "")
    expect(fcgio.LOG.ERROR, "Error message")
    logger.level = Logger.INFO

    logger:info("Info message")
    logger:debug("Debug message")
    logger:warn("Warning message")
    logger:error("Error message")
    expect(fcgio.LOG.ERROR, "Error message")
    expect(fcgio.LOG.DEBUG, "")
    expect(fcgio.LOG.WARN, "Warning message")
    expect(fcgio.LOG.INFO, "Info message")
end)

test("BaseObject", function()
    fcgio:flush()
    local obj = BaseObject:new{ registry = {
        logger = Logger:new{level = Logger.DEBUG}
    } }
    obj:info('Info message')
    expect(fcgio.LOG.INFO, "Info message")
    obj:debug("Debug message")
    expect(fcgio.LOG.DEBUG, "Debug message")
    obj:warn("Warning message")
    expect(fcgio.LOG.WARN, "Warning message")
    obj:print()
    expect(fcgio.LOG.DEBUG, "BaseObject")
    --obj:error("Error message")
end)

test("Silk define env", function()
    DIR_SEP = "/"
    BASE_FRW = ""
    WWW_ROOT = "/tmp/www"
    HTTP_ROOT = "https://apps.localhost:9195/"
    CONTROLLER_ROOT = ""
    -- class path: path.to.class
    MODEL_ROOT = BASE_FRW
    -- file path: path/to/file
    VIEW_ROOT = WWW_ROOT
    ulib.delete(WWW_ROOT)
    expect(ulib.mkdir(WWW_ROOT), true)
    expect(ulib.mkdir(WWW_ROOT.."/post"), true)
    expect(ulib.send_file("request.json", WWW_ROOT.."/rq.json"), true)
    expect(ulib.send_file("layout.ls", WWW_ROOT.."/layout.ls"), true)
    expect(ulib.send_file("detail.ls", WWW_ROOT.."/post/detail.ls"), true)
    expect(ulib.send_file("ad.ls", WWW_ROOT.."/post/ad.ls"), true)
end)

test("Define model", function()
    BaseModel:subclass("NewsModel",{
        registry = {},
        name = "news",
        fields = {
            content =	"TEXT"
        }
    })
    local REGISTRY = {}
    ulib.delete("/tmp/news.db")
    -- set logging level
    REGISTRY.logger = Logger:new{ level = Logger.INFO }
    REGISTRY.layout = '/'
    REGISTRY.db = DBModel:new {db = "news"}
    REGISTRY.db:open()
    local model = NewsModel:new{registry = REGISTRY}
    -- insert data
    expect(model:create({content = "Hello HELL"}), true)
    expect(model:create({content = "Goodbye"}), true)
    local records = model:findAll()
    expect(#records, 2)
    expect(model:update({id =1, content = "Hello World"}), true)
    expect(model:delete({ ["="] = {id = 2} }), true)
    records = model:findAll()
    expect(#records, 1)
    local record = model:get(1)
    unexpect(record, nil)
    expect(record.content, "Hello World")
    records = model:select("id as ID, content", "1=1")
    unexpect(records, nil)
    expect(#records, 1)
    expect(records[1].ID,1)
    REGISTRY.db:close()
    
end)

test("Define controller", function()
    BaseController:subclass("PostController",{
        registry = {},
        models = {"news"}
    })
    function PostController:id(n)
        local record = self.news:get(n)
        self.template:set("data", record)
        --self.template:set("id", n)
        self.template:setView("detail")
        return true
    end

    function PostController:ad()
        self.template:set("ad", "AD HERE")
        return true
    end
end)

test("Router infer controller", function()
    local router = Router:new{}
    local action = router:infer()
    expect(action.controller.class, "PostController")
    expect(action.action, "id")
    expect(action.args[1], "1")
end)

test("Router infer asset", function()
    fcgio:flush()
    local router = Router:new{registry = {
        fileaccess = true
    }}
    local action = router:infer("/rq.json")
    expect(action.controller.class, "AssetController")
    expect(action.action, "get")
    expect(action.args[1], "rq.json")
    local ret = router:call(action)
    expect(ret, false)
    io.stderr:write(fcgio.OUTPUT)
    io.stderr:write("\n")
end)

test("Router fetch views with dependencies", function()
    fcgio:flush()
    local REGISTRY = {}
    REGISTRY.db = DBModel:new {db = "news"}
    REGISTRY.db:open()
    -- set logging level
    REGISTRY.logger = Logger:new{ level = Logger.INFO }
    REGISTRY.layout = '/'
    local default_routes_dependencies = {
        ad = {
            url = "post/ad",
            visibility = {
                shown = true,
                routes = {
                    ["post/id"] = true
                }
            }
        }
    }
    local router = Router:new{registry = REGISTRY}
    router:route('/', default_routes_dependencies )
    router:delegate()
    REGISTRY.db:close()
    expect(fcgio.OUTPUT, "Status: 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n\r\nPost ID:1.0\nContent:Hello World\nAD HERE")
end)

test("Controller action not found", function()
    fcgio:flush()
    REQUEST.r = "/post/all"
    local router = Router:new{registry = {}}
    local s,e = pcall(router.delegate, router)
    expect(s, false)
    expect(fcgio.OUTPUT,"Status: 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n\r\n#action all is not found in controller PostController")
end)

test("Controller not found", function()
    fcgio:flush()
    REQUEST.r = "/user/dany"
    local REGISTRY = {}
    -- set logging level
    --REGISTRY.logger = Logger:new{ level = Logger.INFO }
    REGISTRY.layout = '/'
    local router = Router:new{registry = REGISTRY}
    local s,e = pcall(router.delegate, router)
    expect(s, false)
    print(fcgio.OUTPUT)
end)
-- run all test
run()