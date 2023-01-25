--- the binary shall be compiled with
--- make CFLAGS=-DLUA_SLICE_MAGIC=0x8AD73B9F
--- otherwise the tests unable to load C modules

require("lunit")

package.cpath = "/tmp/lib/lua/?.so"
package.path = ""

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

test("Import the hook", function()
    package.path = "../silkmvc/?.lua"
    local ret = require("core.hook")
    expect(ret, true)
end)

test("Lua path", function()
    expect(package.cpath, "/tmp/lib/lua/?.so")
    expect(package.path, "/tmp/lib/lua/?.lua;/tmp/www/?.lua")
    unexpect(ulib, nil)
    unexpect(utils, nil)
    unexpect(std, nil)
end)

test("HTTP Headers", function()
    expect(HEADER["mobile"], false)
    for k,v in pairs(_SERVER) do
        if k:match("^HTTP_.*") then
            local key = (k:gsub("HTTP_",""):gsub("_","-")):lower()
            expect(HEADER[key],v)
        end
    end
end)

test("HTTP request", function()
    expect(REQUEST.method, "POST")
    expect(REQUEST.r, "post/id/1")
    expect(REQUEST.id, "3")
    expect(REQUEST.name, "John")
    expect(REQUEST.firstname, "Dany")
    expect(REQUEST.lastname, "LE")
    expect(REQUEST.form_submitted, "1")
end)

test('HTTP COOKIE', function()
    unexpect(SESSION, nil)
    expect(SESSION.PHPSESSID, "298zf09hf012fh2")
    expect(SESSION.csrftoken, "u32t4o3tb3gg43")
    expect(SESSION._gat, "1")
end)

test("Echo", function()
    echo("Hello ", "World: ", 10, true)
    expect(fcgio.OUTPUT, "Hello World: 10true")
end)

test("STD response", function()
    std.status(500)
    expect(RESPONSE_HEADER.status, 500)
    std.header("Content-Type", "text/html")
    expect(RESPONSE_HEADER.header["Content-Type"], "text/html")
end)

test("STD Error", function()
    fcgio:flush()
    std.error(404, "No page found")
    expect(fcgio.OUTPUT, "Status: 404 Not Found\r\nContent-Type: text/html\r\n\r\n<HTML><HEAD><TITLE>No page found</TITLE></HEAD><BODY><h2>No page found</h2></BODY></HTML>")
end)

test("STD header with cookie", function()
    RESPONSE_HEADER.sent = false
    fcgio:flush()
    
    std.status(200)
    std.header("Content-Type", "text/html")
    std.setCookie("sessionid=12345;user=dany; path=/")
    std.setCookie("date=now", "_gcat=1")
    --print(JSON.encode(RESPONSE_HEADER))
    std.header_flush()
    echo("hello")
    expect(fcgio.OUTPUT, "Status: 200 OK\r\nContent-Type: text/html\r\nSet-Cookie: sessionid=12345;user=dany; path=/\r\nSet-Cookie: date=now;_gcat=1\r\n\r\nhello")
end)
--- mimes test
test("STD Mime", function()
    expect(std.mimeOf("request.json"), "application/json")
    expect(std.mimeOf("test.exe"), "application/octet-stream")
end)

test("STD send file", function()
    RESPONSE_HEADER.sent = false
    fcgio:flush()
    std.sendFile("request.json")
    print(fcgio.OUTPUT)
end)

test("utils.is_array", function()
    local tb = { name = "Dany", test = true}
    expect(utils.is_array(tb), false)
    local arr = {[1] = "Dany", [2] = true}
    expect(utils.is_array(arr), true)
end)

test("utils.escape and utils.unescape", function()
    local before = 'this is a escape string \\ " % \n \t \r'
    local escaped = utils.escape(before)
    expect(escaped, 'this is a escape string \\\\ \\" %% \\n \\t \\r')
    expect(utils.unescape(escaped), before)
end)

test("utils.decodeURI", function()
    local uri = "https://mozilla.org/?x=%D1%88%D0%B5%D0%BB%D0%BB%D1%8B"
    local decoded = utils.decodeURI(uri)
    expect(decoded, "https://mozilla.org/?x=шеллы")
end)

test("utils.file_exists", function()
    expect(utils.file_exists("request.json"), true)
    expect(utils.file_exists("test1.json"), false)
end)

test("utils.parse_query", function()
    local query = "r=1&id=3&name=John&desc=some%20thing&enc=this+is+encode"
    local tb = utils.parse_query(query)
    expect(tb.r, "1")
    expect(tb.id, "3")
    expect(tb.desc, "some thing")
    expect(tb.enc, "this is encode")
    expect(tb.name, "John")
end)

test("utils.url_parser", function()
    local uri = "https://mozilla.org:9000/?x=%D1%88%D0%B5%D0%BB%D0%BB%D1%8B"
    local obj = utils.url_parser(uri)
    expect(obj.query, "/?x=%D1%88%D0%B5%D0%BB%D0%BB%D1%8B")
    expect(obj.hostname, "mozilla.org")
    expect(obj.protocol, "https")
    expect(obj.port, 9000)
end)

test("utils explode/implode", function()
    local str = "this is a test"
    tbl = explode(str, " ")
    expect(tbl[1], "this")
    expect(tbl[2], "is")
    expect(tbl[3], "a")
    expect(tbl[4], "test")
    local str1 = implode(tbl, "|")
    expect(str1, "this|is|a|test")
end)

test("utils firstToUpper", function()
    local str = "this is a test"
    expect(firstToUpper(str), "This is a test")
end)

test("utils.ext", function()
    expect(utils.ext("foo.bar"), "bar")
    expect(utils.ext("foo.bar.baz"), "baz")
    expect(utils.ext("foo"), nil)
end)

test("utils.basename", function()
    expect(utils.basename("path/to/foo.bar"), "foo.bar")
end)
--- Test for sqlite database
test("sqlite.getdb", function()
    require("silk.core.sqlite")
    local path = "/tmp/test.db"
    local db = sqlite.getdb("/tmp/test.db")
    sqlite.dbclose(db)
    expect(ulib.exists(path), true)

    db = sqlite.getdb("system")
    sqlite.dbclose(db)
    expect(ulib.exists("/tmp/system.db"), true)

    ulib.delete("/tmp/secret.db")
    expect(ulib.exists("/tmp/secret.db"), false)
    DB = DBModel:new{db="secret"}
    DB:open()
    
    expect(ulib.exists("/tmp/secret.db"), true)
    unexpect(DB.db, nil)
    unexpect(DB.db,"secret")
end)

test("DBModel:createTable", function()
    ret = DB:createTable("test", {
        first_name  = "TEXT NOT NULL",
	    last_name =  "TEXT NOT NULL",
	    age = "INTEGER"
    })
    expect(ret, true)
end)

test("DBModel:available", function()
    expect(DB:available("test"), true)
end)

test("DBModel:insert", function()
    local data = {
        first_name = "Dany",
        last_name = "LE",
        age = 30,
        phone = "Unknown"
    }
    expect(DB:insert("test",data), false)
    data.phone = nil
    expect(DB:insert("test",data), true)
    data = {
        first_name = "Lisa",
        last_name = "LE",
        age = 5
    }
    expect(DB:insert("test",data), true)
end)

test("DBModel:lastInsertID", function()
    local id = DB:lastInsertID()
    expect(id, 2)
end)

test("DBModel:get", function()
    local record = DB:get("test", 2)
    expect(record.id, 2)
    expect(record.first_name, "Lisa")
    expect(record.last_name, "LE")
    expect(record.age, 5)
end)

test("DBModel:getAll", function()
    local records = DB:getAll("test")
    expect(#records, 2)

    expect(records[1].id, 1)
    expect(records[1].first_name, "Dany")
    expect(records[1].last_name, "LE")
    expect(records[1].age, 30)

    expect(records[2].id, 2)
    expect(records[2].first_name, "Lisa")
    expect(records[2].last_name, "LE")
    expect(records[2].age, 5)
end)

test("DBModel:find", function()
    local cond = {
        exp = {
            ["and"] = {
                {
                    ["="] = {
                    first_name = "Dany"
                    }
                },
                {
                    ["="] = {
                        age = 25
                    }
                }
            }
        }
    }
    local records = DB:find("test", cond)
    expect(#records, 0)

    cond.exp["and"][2]["="].age = 30
    records = DB:find("test", cond)
    expect(#records, 1)

    cond = {
        exp = {
            ["="] = {
            last_name = "LE"
            }
        },
        order = {
            id = "DESC"
        }
    }
    records = DB:find("test", cond)
    expect(#records, 2)
    expect(records[1].id, 2)
    expect(records[1].first_name, "Lisa")
    expect(records[1].last_name, "LE")
    expect(records[1].age, 5)
end)

test("DBModel:update", function()
    local data = {
        id = 1,
        first_name = "Dany Xuan-Sang",
        age = 35,
    }
    expect(DB:update("test", data), true)
    local record = DB:get("test", 1)
    unexpect(record, nil)
    expect(record.age , 35)
    expect(record.first_name, "Dany Xuan-Sang")
end)

test("DBModel:deleteByID", function()
    expect(DB:deleteByID("test", 1), true)
    local record = DB:get("test", 1)
    expect(record, nil)
end)

test("DBModel:delete", function()
    local cond = {
        ["="] = {
            last_name = "LE"
        }
    }
    expect(DB:delete("test", cond), true)
    local records = DB:getAll("test")
    expect(#records, 0)
end)

--- test enc module
test("Base64 encode/decode", function()
    enc = require("enc")
    local string = "this is the test"
    local encode = enc.b64encode(string)
    expect(encode,"dGhpcyBpcyB0aGUgdGVzdA==")
    local buf = enc.b64decode(encode)
    unexpect(buf,nil)
    expect(tostring(buf), string)
end)

test("md5 encode", function()
    expect(enc.md5("this is a test"), "54b0c58c7ce9f2a8b551351102ee0938")
end)

test("sha1 encode", function()
    expect(enc.sha1("this is a test"), "fa26be19de6bff93f70bc2308434e4a440bbad02")
end)
--- run all unit tests
run()