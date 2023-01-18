#include "lua/lualib.h"
#include "3rd/md4c/md4c-html.h"

static void md_process_output(const MD_CHAR *buf, MD_SIZE len, void *udata)
{
    lua_State *L = (lua_State *)udata;
    lua_pushlstring(L, buf, len);
    lua_call(L, 1, 0);
    lua_pushvalue(L, -1);
}

static int l_md_to_html(lua_State *L)
{
    const char *input = luaL_checkstring(L, 1);
    if (input == NULL)
    {
        //lua_pushstring(L,"NULL markdown input string");
        return 0;
    }
    if (!lua_isfunction(L, -1))
    {
        //lua_pushstring(L,"Invalid callback function");
        return 0;
    }
    // duplicate top of the stack
    lua_pushvalue(L, -1);
    reset_hd_cnt();
    if (md_html(input,
                strlen(input),
                md_process_output,
                L,
                MD_DIALECT_GITHUB |
                    MD_HTML_FLAG_VERBATIM_ENTITIES |
                    MD_FLAG_PERMISSIVEATXHEADERS |
                    MD_FLAG_NOINDENTEDCODEBLOCKS |
                    MD_FLAG_NOHTMLBLOCKS |
                    MD_FLAG_NOHTMLSPANS |
                    MD_FLAG_NOHTML |
                    MD_FLAG_COLLAPSEWHITESPACE |
                    MD_FLAG_PERMISSIVEURLAUTOLINKS |
                    MD_FLAG_PERMISSIVEWWWAUTOLINKS |
                    MD_FLAG_PERMISSIVEEMAILAUTOLINKS |
                    MD_FLAG_PERMISSIVEAUTOLINKS |
                    MD_FLAG_UNDERLINE,
                MD_HTML_FLAG_XHTML) == -1)
    {
        //lua_pushstring(L,"Unable to parse markdown: md_parse() fails");
        lua_pop(L,1);
        return 0;
    }
    lua_pop(L,1);
    return 1;
}

static const struct luaL_Reg _lib[] = {
    {"to_html", l_md_to_html},
    {NULL, NULL}};

int luaopen_md(lua_State *L)
{
    luaL_newlib(L, _lib);
    return 1;
}
