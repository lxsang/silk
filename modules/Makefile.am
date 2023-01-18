lib_LTLIBRARIES = ulib.la
ulib_la_LDFLAGS = -module -avoid-version -shared
ulib_la_SOURCES =  3rd/zip/zip.c ulib.c 


lib_LTLIBRARIES += enc.la
enc_la_LDFLAGS = -module -avoid-version -shared
enc_la_SOURCES =  enc.c base64.c sha1.c 

lib_LTLIBRARIES += slice.la
slice_la_LDFLAGS = -module -avoid-version -shared
slice_la_SOURCES =  slice.c 

lib_LTLIBRARIES += stmr.la
stmr_la_LDFLAGS = -module -avoid-version -shared
stmr_la_SOURCES =  stmr.c 

lib_LTLIBRARIES += json.la
json_la_LDFLAGS = -module -avoid-version -shared
json_la_SOURCES =  3rd/jsmn/jsmn.c json.c 


lib_LTLIBRARIES += md.la
md_la_LDFLAGS = -module -avoid-version -shared
md_la_SOURCES =  md.c  3rd/md4c/entity.c 3rd/md4c/md4c.c 3rd/md4c/md4c-html.c


if HAS_DB
lib_LTLIBRARIES += sqlitedb.la
sqlitedb_la_LDFLAGS = -module -avoid-version -shared
sqlitedb_la_SOURCES =   sqlitedb.c 
endif

libdir=$(prefix)/lib/lua/

EXTRA_DIST = base64.h \
    sha1.h \
    3rd/zip/miniz.c \
    3rd/zip/zip.h \
    3rd/jsmn/jsmn.h \
    3rd/md4c/md4c-html.h \
    3rd/md4c/entity.h \
    3rd/md4c/md4c.h \
    lua/lualib.h \
    lua/lua54/luaconf.h \
    lua/lua54/lualib.h \
    lua/lua54/lua.h \
    lua/lua54/lauxlib.h

