typedef int (*MAP_NEXT_FUNC)(lua_State *ls);

static int map_next_u8_func(lua_State *ls) {
	u8 key;
	u8 nextkey;

	GCtab *t = tabV(ls->top - 2);
	int fd = t->data1;
	struct bpf_map_def *map = t->data2;

	key = (u8)lua_tonumber(ls, -1);
	if (bpf_get_next_key(fd, &key, &nextkey) == 0) {
		lua_pushnumber(ls, nextkey);
		return 1;
	} else
		return 0;
}

static int map_next_u16_func(lua_State *ls) {
	u16 key;
	u16 nextkey;

	GCtab *t = tabV(ls->top - 2);
	int fd = t->data1;
	struct bpf_map_def *map = t->data2;

	key = (u16)lua_tonumber(ls, -1);
	if (bpf_get_next_key(fd, &key, &nextkey) == 0) {
		lua_pushnumber(ls, nextkey);
		return 1;
	} else
		return 0;
}

static int map_next_u32_func(lua_State *ls) {
	u32 key;
	u32 nextkey;

	GCtab *t = tabV(ls->top - 2);
	int fd = t->data1;
	struct bpf_map_def *map = t->data2;

	key = (u32)lua_tonumber(ls, -1);
	if (bpf_get_next_key(fd, &key, &nextkey) == 0) {
		lua_pushnumber(ls, nextkey);
		return 1;
	} else
		return 0;
}

static int map_next_u64_func(lua_State *ls) {
	u64 key;
	u64 nextkey;

	GCtab *t = tabV(ls->top - 2);
	int fd = t->data1;
	struct bpf_map_def *map = t->data2;

	key = (u64)lua_tonumber(ls, -1);
	if (bpf_get_next_key(fd, &key, &nextkey) == 0) {
		lua_pushnumber(ls, nextkey);
		return 1;
	} else
		return 0;
}

static int map_next_string_func(lua_State *ls) {
	char key[1024] = {0};
	char nextkey[1024] = {0};

	GCtab *t = tabV(ls->top - 2);
	int fd = t->data1;
	struct bpf_map_def *map = t->data2;

	if (lua_isnil(ls, -1))
		key[0] = '\0';
	else {
		const char *str = lua_tostring(ls, -1);
		memcpy(&key, str, strlen(str));//TODO
	}

	if (bpf_get_next_key(fd, &key, &nextkey) == 0) {
		lua_pushstring(ls, nextkey);
		return 1;
	} else
		return 0;
}

static int map_next_userdata_func(lua_State *ls) {
	u8 key[1024] = {0};
	u8 nextkey[1024] = {0};

	GCtab *t = tabV(ls->top - 2);
	int fd = t->data1;
	struct bpf_map_def *map = t->data2;

	//todo
	if (bpf_get_next_key(fd, &key, &nextkey) == 0) {
		//todo
		return 1;
	} else
		return 0;
}

static MAP_NEXT_FUNC map_next_func_array[MAP_ELEM_TYPE_max] = {
	map_next_u8_func,
	map_next_u16_func,
	map_next_u32_func,
	map_next_u64_func,
	map_next_string_func,
	map_next_userdata_func,
};