#include "lua/lualib.h"
#include "3rd/jsmn/jsmn.h"

#define MAXTOKEN 8192

// define unescape sequence

static int token_to_object(lua_State *L, jsmntok_t* t, const char* s, int cid);
static int l_json_parser(lua_State *L, const char* s);

//void header(int,const char*);
static int l_json_decode_s (lua_State *L) {
	const char* s = luaL_checkstring(L,1);
	return l_json_parser(L,s);
}

static int l_json_decode_f (lua_State *L) {
	// read the entire file
	char * buffer = 0;
	long length;
	const char* ph = luaL_checkstring(L,1);
	FILE * f = fopen (ph, "rb");

	if (f)
	{
	  fseek (f, 0, SEEK_END);
	  length = ftell (f);
	  fseek (f, 0, SEEK_SET);
	  buffer = malloc (length+1);
	  if (buffer)
	  {
	    int ret = fread(buffer, 1, length, f);
	  }
	  fclose (f);
	}

	if (buffer)
	{
		buffer[length] = '\0';
	   l_json_parser(L,buffer);
	   free(buffer);
	   return 1;
	}
	else
	{
		lua_pushnil(L);
		return 1;
	}
	
}
static int  process_token_object(lua_State* L, jsmntok_t* t, const char* s, int cid)
{
	lua_newtable(L);
	int id = cid+1;
	//printf("%d\n", t[cid].size);
	for(int i = 0; i < t[cid].size; i++)
	{
		char*str = strndup(s+t[id].start, t[id].end-t[id].start);
		lua_pushstring(L,str);
		free(str);
		id = token_to_object(L,t,s,id+1);
		lua_settable(L, -3);
	}
	return id;
}
static int process_token_array(lua_State* L, jsmntok_t* t, const char* s, int cid)
{
	lua_newtable(L);
	int id = cid+1;
	for(int i = 1; i <= t[cid].size; i++)
	{
		lua_pushnumber(L,i);
		id = token_to_object(L,t,s,id);
		lua_settable(L, -3);
	}
	return id;
}

/*
static void stackDump (lua_State *L) {
      int i;
      int top = lua_gettop(L);
      for (i = 1; i <= top; i++) {  
        int t = lua_type(L, i);
        switch (t) {
    
          case LUA_TSTRING:  
            printf("`%s' \n", lua_tostring(L, i));
            break;
    
          case LUA_TBOOLEAN: 
            printf(lua_toboolean(L, i) ? "true\n" : "false\n");
            break;
    
          case LUA_TNUMBER:  
            printf("%g\n", lua_tonumber(L, i));
            break;
    
          default:  
            printf("%s\n", lua_typename(L, t));
            break;
    
        }
        printf("  ");  
      }
      printf("\n");  
    }
*/
static int process_token_string(lua_State* L, jsmntok_t* t, const char* s, int cid)
{
	// un escape the string
	char * str = (char*) malloc(t[cid].end-t[cid].start + 1);
	int index = 0;
	char c;
	uint8_t escape = 0;

	for (int i = t[cid].start; i < t[cid].end; i++)
	{
		c = *(s+i);
		if(c == '\\')
		{
			if(escape)
			{
				str[index] = c;
				escape = 0;
				index++;
			}
			else 
			{
				escape = 1;
			}
		}
		else
		{
			if(escape)
			{
				switch (c)
				{
				case 'b':
					str[index] = '\b';
					break;
				case 'f':
					str[index] = '\f';
					break;
				case 'n':
					str[index] = '\n';
					break;
				case 'r':
					str[index] = '\r';
					break;
				case 't':
					str[index] = '\t';
					break;
				default:
					str[index] = c;
				}
			}
			else
			{
				str[index] = c;
			}
			index++;
			escape = 0;
		}
	}
	str[index] = '\0';
	//strndup(s+t[cid].start, t[cid].end-t[cid].start);
	// un escape the string
	/*lua_getglobal(L, "utils");
	lua_getfield(L, -1, "unescape");
	lua_pushstring(L,str);
	if (lua_pcall(L, 1, 1, 0) != 0)
	        printf("Error running function `unescape': %s\n",lua_tostring(L, -1));
	if(str) free(str);
	str = (char*)luaL_checkstring(L,-1);
	lua_settop(L, -3);*/
	lua_pushstring(L,str);
	//stackDump(L);
	//lua_pushstring(L, str);
	//printf("%s\n",strndup(s+t[cid].start, t[cid].end-t[cid].start) );
	if(str) free(str);
	return cid+1;
}
static int process_token_primitive(lua_State* L, jsmntok_t* t, const char* s, int cid)
{
	//printf("%s\n",strndup(s+t[cid].start, t[cid].end-t[cid].start) );
	char c = s[t[cid].start];
	char *str;
	switch(c)
	{
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		case '+':
		case '-':
			str = strndup(s+t[cid].start, t[cid].end-t[cid].start);
			lua_pushnumber(L,atof(str));
			free(str);
			break;
		
		case 't': lua_pushboolean(L,1); break;
		case 'f': lua_pushboolean(L,0); break;
		default: lua_pushnil(L);break;
		
	}
	return cid+1;
}
static int token_to_object(lua_State *L, jsmntok_t* t, const char* s, int cid)
{
	switch(t[cid].type)
	{
		case JSMN_OBJECT:
			return process_token_object(L,t,s,cid);
			break;
		case JSMN_ARRAY:
			return process_token_array(L,t,s,cid);
			break;
		case JSMN_STRING:
			return process_token_string(L,t,s,cid);
			break;
		
		case JSMN_PRIMITIVE:
			return process_token_primitive(L,t,s,cid);
			break;
		
		default:
			lua_pushnil(L);
			return cid + t[cid].size; break;
		
	}
}

static int l_json_parser(lua_State *L, const char* s)
{
	jsmn_parser p;
	jsmntok_t t[MAXTOKEN]; 

	jsmn_init(&p);
	int r = jsmn_parse(&p, s, strlen(s), t, sizeof(t)/sizeof(t[0]));
	if (r < 0) {
		lua_pushnil(L);
		return 0;
	}
	token_to_object(L,t,s,0);
	return 1;
}
static const struct luaL_Reg _json [] = {
	{"decodeString", l_json_decode_s},
	{"decodeFile", l_json_decode_f},
	{NULL,NULL}
};

int luaopen_json(lua_State *L)
{
	luaL_newlib(L, _json);
	return 1;
}