bytes = modules.bytes()
array = modules.array()

modules.sqlite = function()
    if not sqlite then
        sqlite = require("sqlitedb")
		sqlite.getdb = function(name)
			if name:find("%.db$") then
				return sqlite._getdb(name)
			elseif name:find("/") then
				LOG_ERROR("Invalid database name %s", name)
				return nil
			else
				return sqlite._getdb(__api__.dbpath.."/"..name..".db")
			end
		end
	end
	return sqlite
end

RESPONSE_HEADER = {
	status = 200,
	header = {},
	cookie = {},
	sent = false
}

function std.status(code)
	RESPONSE_HEADER.status=code
end
function std.custom_header(k,v)
	std.header(k,v)
end
function std.header_flush()
	std._send_header(HTTP_REQUEST.id,RESPONSE_HEADER.status, RESPONSE_HEADER.header, RESPONSE_HEADER.cookie)
	RESPONSE_HEADER.sent = true
end

function std.header(k,v)
	RESPONSE_HEADER.header[k] = v
end

function std.cjson(ck)
	for k,v in pairs(ck) do
		std.setCookie(k.."="..v.."; Path=/")
	end
	std.header("Content-Type","application/json; charset=utf-8")
	std.header_flush()
end
function std.chtml(ck)
	for k,v in pairs(ck) do
		std.setCookie(k.."="..v.."; Path=/")
	end
	std.header("Content-Type","text/html; charset=utf-8")
	std.header_flush()
end
function std.t(s)
	if RESPONSE_HEADER.sent == false then
		std.header_flush()
	end
	std._t(HTTP_REQUEST.id,s)
end
function std.b(s)
	if RESPONSE_HEADER.sent == false then
		std.header_flush()
	end
	std._b(HTTP_REQUEST.id,s)
end
function std.f(v)
	std._f(HTTP_REQUEST.id,v)
	--ulib.send_file(v, HTTP_REQUEST.socket)
end

function std.setCookie(v)
	RESPONSE_HEADER.cookie[#RESPONSE_HEADER.cookie] = v
end

function std.error(status, msg)
	std._error(HTTP_REQUEST.id, status, msg)
end
--_upload
--_route
function std.unknow(s)
	std.error(404, "Unknown request")
end

--_redirect
--[[ function std.redirect(s)
	std._redirect(HTTP_REQUEST.id,s)
end ]]

function std.html()
	std.header("Content-Type","text/html; charset=utf-8")
	std.header_flush()
end
function std.text()
	std.header("Content-Type","text/plain; charset=utf-8")
	std.header_flush()
end

function std.json()
	std.header("Content-Type","application/json; charset=utf-8")
	std.header_flush()
end
function std.jpeg()
	std.header("Content-Type","image/jpeg")
	std.header_flush()
end
function std.octstream(s)
	std.header("Content-Type","application/octet-stream")
	std.header("Content-Disposition",'attachment; filename="'..s..'"')
	std.header_flush()
end
--[[ function std.textstream()
	std._textstream(HTTP_REQUEST.id)
end ]]


function std.readOnly(t) -- bugging
    local proxy = {}
    local mt = {       -- create metatable
		__index = t,
        __newindex = function (t,k,v)
          error("attempt to update a read-only table", 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
 end
    

-- web socket
std.ws = {}
function std.ws.header()
	local h = std.ws_header(HTTP_REQUEST.id)
	if(h) then
		return h --std.readOnly(h)
	else
		return nil
	end
end

function std.ws.read(h)
	return std.ws_read(HTTP_REQUEST.id,h)
end
function std.ws.swrite(s)
	std.ws_t(HTTP_REQUEST.id,s)
end
function std.ws.fwrite(s)
	std.ws_f(HTTP_REQUEST.id,s)
end
function std.ws.write_bytes(arr)
	std.ws_b(HTTP_REQUEST.id,arr)
end
function std.ws.enable()
	return HTTP_REQUEST ~= nil and HTTP_REQUEST.request["__web_socket__"] == "1"
end
function std.ws.close(code)
	std.ws_close(HTTP_REQUEST.id,code)
end
function std.basename(str)
	local name = string.gsub(std.trim(str,"/"), "(.*/)(.*)", "%2")
	return name
end
function std.is_file(f)
	return  std.is_dir(f) == false
end

std.ws.TEXT = 1
std.ws.BIN = 2
std.ws.CLOSE = 8
