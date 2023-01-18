#include <sqlite3.h>
#include "lua/lualib.h"

typedef sqlite3 *sqldb;

static int l_getdb(lua_State *L)
{
    const char *file = luaL_checkstring(L, 1);
    sqlite3 *db;
    int rc = sqlite3_open(file, &db);
    if (rc != SQLITE_OK)
    {
        lua_pushnil(L);
        lua_pushstring(L,sqlite3_errmsg(db));
        sqlite3_close(db);
        return 2;
    }
    lua_pushlightuserdata(L, db);
    return 1;
}

static int l_db_close(lua_State *L)
{
    sqldb db = (sqldb)lua_touserdata(L, 1);
    if (db)
    {
            sqlite3_close(db);
    }
    db = NULL;
    return 0;
}
static int l_db_exec(lua_State *L)
{
    sqldb db = (sqldb)lua_touserdata(L, 1);
    const char *sql = luaL_checkstring(L, 2);
    int r = 0;
    if(!db)
    {
        lua_pushboolean(L, 0);
        lua_pushstring(L,"Invalid database handle");
        return 2;
    }
    
    char *err_msg = 0;
    sqlite3_mutex_enter(sqlite3_db_mutex(db));
    int rc = sqlite3_exec(db, sql, NULL, 0, &err_msg);
    sqlite3_mutex_leave(sqlite3_db_mutex(db));
    if (rc != SQLITE_OK)
    {
        lua_pushboolean(L, 0);
        lua_pushstring(L,err_msg);
        sqlite3_free(err_msg);
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}
static int l_db_lastid(lua_State *L)
{
    sqldb db = (sqldb)lua_touserdata(L, 1);

    int idx = -1;
    if (db)
        idx = sqlite3_last_insert_rowid(db);
    lua_pushnumber(L, idx);
    return 1;
}
static int l_db_query(lua_State *L)
{
    sqldb db = (sqldb)lua_touserdata(L, 1);
    const char *query = luaL_checkstring(L, 2);
    if (!db)
    {
        lua_pushnil(L);
        return 1;
    }

    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(db, query, -1, &statement, 0) == SQLITE_OK)
    {
        int cols = sqlite3_column_count(statement);
        int result = 0;
        int cnt = 1;
        // new table for data
        lua_newtable(L);
        while ((result = sqlite3_step(statement)) == SQLITE_ROW)
        {
            lua_pushnumber(L, cnt);
            lua_newtable(L);
            for (int col = 0; col < cols; col++)
            {
                const char *value = (const char *)sqlite3_column_text(statement, col);
                const char *name = sqlite3_column_name(statement, col);
                lua_pushstring(L, name);
                lua_pushstring(L, value);
                lua_settable(L, -3);
            }
            lua_settable(L, -3);
            cnt++;
        }
        sqlite3_finalize(statement);
    }
    else
    {
        lua_pushnil(L);
        lua_pushstring(L, sqlite3_errmsg(db));
        return 2;
    }
    return 1;
}
static const struct luaL_Reg sqlite[] = {
    {"db", l_getdb},
    {"dbclose", l_db_close},
    {"query", l_db_query},
    {"last_insert_id", l_db_lastid},
    {"exec", l_db_exec},
    {NULL, NULL}};

int luaopen_sqlitedb(lua_State *L)
{
    luaL_newlib(L, sqlite);
    return 1;
}