local default_mimes = {
    ["bmp"] = "image/bmp",
    ["jpg"] = "image/jpeg",
    ["jpeg"] = "image/jpeg",
    ["css"] = "text/css",
    ["md"] = "text/markdown",
    ["csv"] = "text/csv",
    ["pdf"] = "application/pdf",
    ["gif"] = "image/gif",
    ["html"] = "text/html",
    ["htm"] = "text/html",
    ["chtml"] = "text/html",
    ["json"] = "application/json",
    ["js"] = "application/javascript",
    ["png"] = "image/png",
    ["ppm"] = "image/x-portable-pixmap",
    ["rar"] = "application/x-rar-compressed",
    ["tiff"] = "image/tiff",
    ["tar"] = "application/x-tar",
    ["txt"] = "text/plain",
    ["ttf"] = "application/x-font-ttf",
    ["xhtml"] = "application/xhtml+xml",
    ["xml"] = "application/xml",
    ["zip"] = "application/zip",
    ["svg"] = "image/svg+xml",
    ["eot"] = "application/vnd.ms-fontobject",
    ["woff"] = "application/x-font-woff",
    ["woff2"] = "application/x-font-woff",
    ["otf"] = "application/x-font-otf",
    ["mp3"] = "audio/mpeg",
    ["mpeg"] = "audio/mpeg"
}

setmetatable(default_mimes, {
	__index = function(this, key)
		return "application/octet-stream"
	end
})
function std.mime(ext)
	return default_mimes[ext]
end
function std.extra_mime(name)
    local ext = utils.ext(name)
    local mpath = __ROOT__ .. "/" .. "mimes.json"
    if WWW_ROOT and not ulib.exists(mpath) then
        LOG_DEBUG("No extra mimes found in %s", mpath)
        mpath = WWW_ROOT .. "/" .. "mimes.json"
        LOG_DEBUG("Trying to looking for extra mimes in: %s", mpath)
    end
    local xmimes = {}
    if ulib.exists(mpath) then
        xmimes = JSON.decodeFile(mpath)
    else
        LOG_DEBUG("No extra mimes")
    end
    if (name:find("Makefile$")) then
        return "text/makefile", false
    elseif ext == "php" then
        return "text/php", false
    elseif ext == "c" or ext == "h" then
        return "text/c", false
    elseif ext == "cpp" or ext == "hpp" then
        return "text/cpp", false
    elseif ext == "md" then
        return "text/markdown", false
    elseif ext == "lua" then
        return "text/lua", false
    elseif ext == "yml" then
        return "application/x-yaml", false
    elseif xmimes[ext] then
        return xmimes[ext].mime, xmimes[ext].binary
        -- elseif ext == "pgm" then return "image/x-portable-graymap", true
    else
        return "application/octet-stream", true
    end
end

function std.mimeOf(name)
    local mime = std.mime(utils.ext(name))
    if mime ~= "application/octet-stream" then
        return mime
    else
        return std.extra_mime(name)
    end
end


function std.sendFile(m)
    local mime = std.mimeOf(m)
    local finfo = ulib.file_stat(m)
    local len = tostring(math.floor(finfo.size))
    local len1 = tostring(math.floor(finfo.size - 1))
    if mime == "audio/mpeg" then
        std.status(200)
        std.header("Pragma", "public")
        std.header("Expires", "0")
        std.header("Content-Type", mime)
        std.header("Content-Length", len)
        std.header("Content-Disposition", "inline; filename=" .. utils.basename(m))
        std.header("Content-Range:", "bytes 0-" .. len1 .. "/" .. len)
        std.header("Accept-Ranges", "bytes")
        std.header("X-Pad", "avoid browser bug")
        std.header("Content-Transfer-Encoding", "binary")
        std.header("Cache-Control", "no-cache, no-store")
        std.header("Connection", "Keep-Alive")
        std.header_flush()
        std.f(m)
    else
        if HEADER['If-Modified-Since'] and HEADER['If-Modified-Since'] == finfo.ctime then
            std.status(304)
            std.header_flush()
        else
            std.status(200)
            std.header("Content-Type", mime)
            -- std.header("Content-Length", len)
            std.header("Cache-Control", "no-cache")
            std.header("Last-Modified", finfo.ctime)
            std.header_flush()
            std.f(m)
        end
    end
end
