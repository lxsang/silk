function std.extra_mime(name)
	local ext = std.ext(name)
	local mpath = __ROOT__.."/".."mimes.json"
	local xmimes = {}
	if utils.file_exists(mpath) then
		local f = io.open(mpath, "r")
		if f then
			xmimes = JSON.decodeString(f:read("*all"))
			f:close()
		end
	end
	if(name:find("Makefile$")) then return "text/makefile",false
	elseif ext == "php" then return "text/php",false
	elseif ext == "c" or ext == "h" then return "text/c",false
	elseif ext == "cpp" or ext == "hpp" then return "text/cpp",false
	elseif ext == "md" then return "text/markdown",false
	elseif ext == "lua" then return "text/lua",false
	elseif ext == "yml" then return "application/x-yaml", false
	elseif xmimes[ext] then return xmimes[ext].mime, xmimes[ext].binary
	--elseif ext == "pgm" then return "image/x-portable-graymap", true
	else 
		return "application/octet-stream",true
	end
end

function std.mimeOf(name)
	local mime = std.mime(name)
	if mime ~= "application/octet-stream" then
		return mime
	else
		return std.extra_mime(name)
	end
end

--[[ function std.isBinary(name)
	local mime = std.mime(name)
	if mime ~= "application/octet-stream" then
		return std.is_bin(name)
	else
		local xmime,bin = std.extra_mime(name)
		return bin
	end
end ]]

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
		std.header("Content-Disposition", "inline; filename=" .. std.basename(m))
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
			--std.header("Content-Length", len)
			std.header("Cache-Control", "no-cache")
			std.header("Last-Modified", finfo.ctime)
			std.header_flush()
			std.f(m)
		end
	end
end
