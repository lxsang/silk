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
    size_t magic;
	size_t len;
    uint8_t* data;
} slice_t;


#ifndef LUA_SLICE_MAGIC
/**
 * @brief Send data to the server via fastCGI protocol
 * This function is defined by the luad fcgi server
 * 
 * @param fd the socket fd
 * @param id the request id
 * @param ptr data pointer
 * @param size data size
 * @return int 
 */
int fcgi_send_slice(int fd, uint16_t id, uint8_t* ptr, size_t size);

/**
 * @brief Get the magic number of the slice
 * This value is defined by the luad fastCGI server
 * 
 * @return size_t 
 */
size_t lua_slice_magic();
#else
#define lua_slice_magic() (LUA_SLICE_MAGIC)
#define fcgi_send_slice(fd,id,ptr,size) (-1)
#endif

void lua_new_slice(lua_State*L, int n)
{
    size_t nbytes = sizeof(slice_t) + n * 1U;
    slice_t *a = (slice_t *)lua_newuserdata(L, nbytes);
    a->data = &((char *)a)[sizeof(slice_t)];
    a->magic = lua_slice_magic();
    luaL_getmetatable(L, SLICE);
    lua_setmetatable(L, -2);
    (void)memset(a->data,0,n);
    a->len = n;
}
slice_t * lua_check_slice(lua_State *L, int idx)
{
    void *ud = luaL_checkudata(L, idx, SLICE);
    luaL_argcheck(L, ud != NULL, idx, "`slice' expected");
    return (slice_t *)ud;
}

#endif