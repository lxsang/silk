FFI = require("ffi")
FFI.type  = {}
FFI.type.VOID       = 0
FFI.type.UINT8      = 1
FFI.type.SINT8      = 2
FFI.type.UINT16     = 3
FFI.type.SINT16     = 4
FFI.type.UINT32     = 5
FFI.type.SINT32     = 6
FFI.type.UINT64     = 7
FFI.type.SINT64     = 8
FFI.type.FLOAT      = 9
FFI.type.DOUBLE     = 10
FFI.type.UCHAR      = 11
FFI.type.SCHAR      = 12
FFI.type.USHORT     = 13
FFI.type.SSHORT     = 14
FFI.type.UINT       = 15
FFI.type.SINT       = 16
FFI.type.ULONG      = 17
FFI.type.SLONG      = 18
FFI.type.LONGDOUBLE = 19
FFI.type.POINTER    = 20
FFI.cache = {}

FFI.load = function(path)
    if FFI.cache[path] then
        return FFI.cache[path]
    else
        print("Loading: "..path)
        local lib = FFI.dlopen(path)
        if lib then
            FFI.cache[path] = {ref = lib, fn= {}}
        end
        return FFI.cache[path]
    end
end

FFI.unload = function(path)
    local lib = FFI.cache[path]
    if lib then
        FFI.dlclose(lib.ref)
        FFI.cache[path] = false
    end
end

FFI.unloadAll = function()
    for k,v in pairs(FFI.cache) do
        FFI.dlclose(v.ref)
    end
    FFI.cache = {}
end

FFI.lookup = function(lib, name)
    local fn = lib.fn[name]
    if fn then return fn end
    fn = FFI.dlsym(lib.ref, name)
    if fn then
        lib.fn[name] = fn
        return fn
    end
    return nil
end