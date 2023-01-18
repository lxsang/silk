#ifndef LUALIB_H
#define LUALIB_H
#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <strings.h>
#include <string.h>
#include <stdlib.h>

#include "lua54/lua.h"
#include "lua54/lauxlib.h"
#include "lua54/lualib.h"

#define SLICE "slice"

typedef struct {
	size_t len;
    uint8_t* data;
} slice_t;

void lua_new_slice(lua_State*L, int n)
{
    size_t nbytes = sizeof(slice_t) + n * 1U;
    slice_t *a = (slice_t *)lua_newuserdata(L, nbytes);
    a->data = &((char *)a)[sizeof(slice_t)];
    luaL_getmetatable(L, SLICE);
    lua_setmetatable(L, -2);

    a->len = n;
}
slice_t * lua_check_slice(lua_State *L, int idx)
{
    void *ud = luaL_checkudata(L, idx, SLICE);
    luaL_argcheck(L, ud != NULL, idx, "`slice' expected");
    return (slice_t *)ud;
}

#endif