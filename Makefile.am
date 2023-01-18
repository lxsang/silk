AUTOMAKE_OPTIONS = foreign



# check for system
if LINUX
    AM_CPPFLAGS = -Wl,E,--no-as-needed
    FL_LUA=linux
else
    AM_CPPFLAGS = -Wl,-undefined,dynamic_lookup
    FL_LUA=macosx
endif


AM_CPPFLAGS += -W  -Wall -g -std=c99 -fPIC

silkdir = $(libdir)/lua/silk
silk_DATA = silkmvc/router.lua.tpl \
    silkmvc/BaseController.lua \
    silkmvc/Router.lua \
    silkmvc/BaseModel.lua \
    silkmvc/Template.lua \
    silkmvc/Logger.lua \
    silkmvc/BaseObject.lua \
    silkmvc/DBHelper.lua \
    silkmvc/api.lua

coredir = $(libdir)/lua/silk/core
core_DATA = silkmvc/core/OOP.lua \
    silkmvc/core/std.lua \
    silkmvc/core/extra_mime.lua \
    silkmvc/core/utils.lua \
    silkmvc/core/api.lua \
    silkmvc/core/cif.lua \
    silkmvc/core/sqlite.lua

# lua libraris &  modules
SUBDIRS = . modules

EXTRA_DIST = README.md silkmvc
