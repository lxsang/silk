require("OOP")
ulib = require("ulib")
require(BASE_FRW.."silk.BaseObject")
require(BASE_FRW.."silk.DBHelper")
require(BASE_FRW.."silk.Router")
require(BASE_FRW.."silk.BaseController")
require(BASE_FRW.."silk.BaseModel")
require(BASE_FRW.."silk.Logger")
require(BASE_FRW.."silk.Template")

-- mime type allows
-- this will bypass the default server security
-- the default list is from the server setting
POLICY = {}
POLICY.mimes = {
    ["application/javascript"]            = true,
    ["image/bmp"]                         = true,
    ["image/jpeg"]                        = true,
    ["image/png"]                        = true,
    ["text/css"]                          = true,
    ["text/markdown"]                     = true,
    ["text/csv"]                          = true,
    ["application/pdf"]                   = true,
    ["image/gif"]                         = true,
    ["text/html"]                         = true,
    ["application/json"]                  = true,
    ["application/javascript"]            = true,
    ["image/x-portable-pixmap"]           = true,
    ["application/x-rar-compressed"]      = true,
    ["image/tiff"]                        = true,
    ["application/x-tar"]                 = true,
    ["text/plain"]                        = true,
    ["application/x-font-ttf"]            = true,
    ["application/xhtml+xml"]             = true,
    ["application/xml"]                   = true,
    ["application/zip"]                   = true,
    ["image/svg+xml"]                     = true,
    ["application/vnd.ms-fontobject"]     = true,
    ["application/x-font-woff"]           = true,
    ["application/x-font-otf"]            = true,
    ["audio/mpeg"]                        = true,

}


HEADER_FLAG = false

function html()
	if not HEADER_FLAG then
		std.chtml(SESSION)
		HEADER_FLAG = true
	end
end

function import(module)
    return require(BASE_FRW.."silk.api."..module)
end