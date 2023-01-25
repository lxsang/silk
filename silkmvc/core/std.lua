std = {}
require("silk.core.mimes")

RESPONSE_HEADER = {
    status = 200,
    header = {},
    cookie = {},
    sent = false
}

local http_status = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [102] = "Processing",
    [103] = "Early Hints",

    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [207] = "Multi-Status",
    [208] = "Already Reported",
    [226] = "IM Used",

    [300] = "Multiple Choices",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [305] = "Use Proxy",
    [306] = "Switch Proxy",
    [307] = "Temporary Redirect",
    [308] = "Permanent Redirect",

    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Payload Too Large",
    [414] = "URI Too Long",
    [415] = "Unsupported Media Type",
    [416] = "Range Not Satisfiable",
    [417] = "Expectation Failed",
    [421] = "Misdirected Request",
    [422] = "Unprocessable Entity",
    [423] = "Locked",
    [424] = "Failed Dependency",
    [425] = "Too Early",
    [426] = "Upgrade Required",
    [428] = "Precondition Required",
    [429] = "Too Many Requests",
    [431] = "Request Header Fields Too Large",
    [451] = "Unavailable For Legal Reasons",

    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
    [505] = "HTTP Version Not Supported",
    [506] = "Variant Also Negotiates",
    [507] = "Insufficient Storage",
    [508] = "Loop Detected",
    [510] = "Not Extended",
    [511] = "Network Authentication Required"
}
setmetatable(http_status, {
    __index = function(this, key)
        return "Unofficial Status"
    end
})

function std.status(code)
    RESPONSE_HEADER.status = code
end

function std.custom_header(k, v)
    std.header(k, v)
end

function std.header(k, v)
    RESPONSE_HEADER.header[k] = v
end

function std.header_flush()
    -- send out status
    echo("Status: ", RESPONSE_HEADER.status, " ", http_status[RESPONSE_HEADER.status], "\r\n")
    -- send out header
    for key, val in pairs(RESPONSE_HEADER.header) do
        echo(key, ": ", val, "\r\n")
    end
    -- send out cookie
    for key, val in ipairs(RESPONSE_HEADER.cookie) do
        echo("Set-Cookie: ", val, "\r\n")
    end
    echo("\r\n")
    RESPONSE_HEADER.sent = true
    RESPONSE_HEADER.header = {}
    RESPONSE_HEADER.cookie = {}
end

function std.setCookie(...)
    local args = table.pack(...)
    cookie = table.concat(args,";")
    RESPONSE_HEADER.cookie[#RESPONSE_HEADER.cookie + 1] = cookie
end

function std.error(status, msg)
    std.status(status)
    std.header("Content-Type", "text/html")
    std.header_flush()
    echo(string.format("<HTML><HEAD><TITLE>%s</TITLE></HEAD><BODY><h2>%s</h2></BODY></HTML>",msg, msg))
end

function std.unknow(s)
    std.error(404, "Unknown request")
end

function std.f(path)
    fcgio:send_file(path)
end

function std.html()
    std.header("Content-Type", "text/html; charset=utf-8")
    std.header_flush()
end

function std.text()
    std.header("Content-Type", "text/plain; charset=utf-8")
    std.header_flush()
end

function std.json()
    std.header("Content-Type", "application/json; charset=utf-8")
    std.header_flush()
end

function std.jpeg()
    std.header("Content-Type", "image/jpeg")
    std.header_flush()
end

function std.octstream(s)
    std.header("Content-Type", "application/octet-stream")
    std.header("Content-Disposition", 'attachment; filename="' .. s .. '"')
    std.header_flush()
end

function std.is_file(f)
    return ulib.is_dir(f) == false
end

-- TODO provide web socket support
-- use coroutine to read socket message
std.ws = {}
function std.ws.header()
    local h = std.ws_header(HTTP_REQUEST.id)
    if (h) then
        return h -- std.readOnly(h)
    else
        return nil
    end
end

function std.ws.read(h)
    return std.ws_read(HTTP_REQUEST.id, h)
end
function std.ws.swrite(s)
    std.ws_t(HTTP_REQUEST.id, s)
end
function std.ws.fwrite(s)
    std.ws_f(HTTP_REQUEST.id, s)
end
function std.ws.write_bytes(arr)
    std.ws_b(HTTP_REQUEST.id, arr)
end
function std.ws.enable()
    return HTTP_REQUEST ~= nil and HTTP_REQUEST.request["__web_socket__"] == "1"
end
function std.ws.close(code)
    std.ws_close(HTTP_REQUEST.id, code)
end
std.ws.TEXT = 1
std.ws.BIN = 2
std.ws.CLOSE = 8
