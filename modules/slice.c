#include "lua/lualib.h"
static int l_slice_send_to(lua_State* L);

void lua_new_light_slice(lua_State *L, int n, char *ptr)
{
    size_t nbytes = sizeof(slice_t);
    slice_t *a = (slice_t *)lua_newuserdata(L, nbytes);
    a->len = n;
    a->data = ptr;
    a->magic = lua_slice_magic();
    luaL_getmetatable(L, SLICE);
    lua_setmetatable(L, -2);
}

static int l_new_slice(lua_State *L)
{
    int n = luaL_checknumber(L, 1);
    lua_new_slice(L, n);
    return 1; /* new userdatum is already on the stack */
}


static int l_new_lightslice(lua_State *L)
{
    uint8_t* ptr = NULL;
    if(lua_isnumber(L,1))
    {
        size_t addr = luaL_checknumber(L, 1);
        ptr = (uint8_t*) addr; 
    }
    else
    {
        ptr = lua_touserdata(L, 1);
    }
    int n = luaL_checknumber(L, 2);
    lua_new_light_slice(L, n, ptr);
    return 1; /* new userdatum is already on the stack */
}

static unsigned char *get_sel(lua_State *L)
{
    slice_t *a = lua_check_slice(L, 1);
    int index = luaL_checknumber(L, 2);
    luaL_argcheck(L, 1 <= index && index <= a->len, 2,
                  "index out of range");

    /* return element address */
    return &a->data[index - 1];
}

static int l_set_slice(lua_State *L)
{
    unsigned char value = luaL_checknumber(L, 3);
    *get_sel(L) = value;
    return 0;
}

static int l_get_slice_size(lua_State *L)
{
    slice_t *a = lua_check_slice(L, 1);
    lua_pushnumber(L, a->len);
    return 1;
}

static int l_slice_write(lua_State *L)
{
    slice_t *a = lua_check_slice(L, 1);
    const char *f = luaL_checkstring(L, 2);
    FILE *fp;
    fp = fopen(f, "wb");

    if (!fp)
        lua_pushboolean(L, 0);
    else
    {
        fwrite(a->data, 1, a->len, fp);
        lua_pushboolean(L, 1);
        fclose(fp);
    }
    return 1;
}

static int l_slice_ptr(lua_State *L)
{
    slice_t *a = lua_check_slice(L, 1);
    lua_pushnumber(L, (size_t)a);
    return 1;
}


static int l_slice_index(lua_State *L)
{
    if(lua_isnumber(L,2))
    {
        lua_pushnumber(L, *get_sel(L));
    }
    else if(lua_isstring(L,2))
    {
        const char* string = luaL_checkstring(L,2);
        if(strcmp(string,"size") == 0)
        {
            lua_pushcfunction(L, l_get_slice_size);
        }
        else if(strcmp(string, "fileout") == 0)
        {
            lua_pushcfunction(L, l_slice_write);
        }
        else if(strcmp(string,"out") == 0)
        {
            lua_pushcfunction(L, l_slice_send_to);
        }
        else if(strcmp(string,"ptr") == 0)
        {
            lua_pushcfunction(L, l_slice_ptr);
        }
        else
        {
            lua_pushnil(L);
        }
        return 1;
    }
    else 
    {
        lua_pushnil(L);
    }
    return 1;
}

static int l_slice_to_string(lua_State *L)
{
    slice_t *a = lua_check_slice(L, 1);
    char *d = (char *)malloc(a->len + 1);
    memcpy(d, a->data, a->len);
    d[a->len] = '\0';
    lua_pushstring(L, d);
    if (d)
        free(d);
    return 1;
}

static int l_slice_send_to(lua_State* L)
{
    slice_t *a = lua_check_slice(L, 1);
    int fd = (int) luaL_checknumber(L, 2);
    uint16_t id = (uint16_t) luaL_checknumber(L, 3);

    lua_pushboolean(L, fcgi_send_slice(fd, id, a->data, a->len) == 0);
    return 1;
}

static const struct luaL_Reg slicemetalib[] = {
    {"unew", l_new_lightslice},
    {"new", l_new_slice},
    {NULL, NULL}};

static const struct luaL_Reg slicelib[] = {
    {"__index", l_slice_index},
    {"__newindex", l_set_slice},
    {"__tostring", l_slice_to_string},
    {NULL, NULL}};

int luaopen_slice(lua_State *L)
{
    luaL_newmetatable(L, SLICE);
    luaL_setfuncs(L, slicelib, 0);
    luaL_newlib(L, slicemetalib);

    return 1;
}