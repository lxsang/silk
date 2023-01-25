require("silk.core.hook")
require("silk.core.OOP")
require("silk.core.sqlite")

require("silk.BaseObject")
require("silk.Router")
require("silk.BaseController")
require("silk.BaseModel")
require("silk.Logger")
require("silk.Template")

DIR_SEP = "/"

-- mime type allows
-- this will bypass the default server security
-- the default list is from the server setting
POLICY = {}
POLICY.mimes = {
    ["image/bmp"] = true,
    ["image/jpeg"] = true,
    ["image/png"] = true,
    ["text/css"] = true,
    ["text/markdown"] = true,
    ["text/csv"] = true,
    ["application/pdf"] = true,
    ["image/gif"] = true,
    ["text/html"] = true,
    ["application/json"] = true,
    ["application/javascript"] = true,
    ["image/x-portable-pixmap"] = true,
    ["application/x-rar-compressed"] = true,
    ["image/tiff"] = true,
    ["application/x-tar"] = true,
    ["text/plain"] = true,
    ["application/x-font-ttf"] = true,
    ["application/xhtml+xml"] = true,
    ["application/xml"] = true,
    ["application/zip"] = true,
    ["image/svg+xml"] = true,
    ["application/vnd.ms-fontobject"] = true,
    ["application/x-font-woff"] = true,
    ["application/x-font-otf"] = true,
    ["audio/mpeg"] = true

}

function html()
    if not RESPONSE_HEADER.sent then
        std.html()
    end
end
