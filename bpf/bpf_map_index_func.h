enum {
	MAP_ELEM_TYPE_u8,
	MAP_ELEM_TYPE_u16,
	MAP_ELEM_TYPE_u32,
	MAP_ELEM_TYPE_u64,
	MAP_ELEM_TYPE_string,
	MAP_ELEM_TYPE_userdata,
	MAP_ELEM_TYPE_max,
};

typedef int (*MAP_INDEX_FUNC)(lua_State *ls, int fd, struct bpf_map_def *map);

static int map_index_u8_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u8 val;

	key = (u8)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u8_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u16 val;

	key = (u8)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u8_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u32 val;

	key = (u8)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u8_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u64 val;

	key = (u8)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u8_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	char val[1024] = {0};

	key = (u8)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushstring(ls, val);
	return 1;
}

static int map_index_u8_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u8 val[1024] = {0};

	key = (u8)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	void *ud = lua_newuserdata(ls, map->value_size);
	memcpy(ud, val, map->value_size);
	return 1;
}

static int map_index_u16_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u8 val;

	key = (u16)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u16_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u16 val;

	key = (u16)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u16_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u32 val;

	key = (u16)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u16_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u64 val;

	key = (u16)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u16_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	char val[1024] = {0};

	key = (u16)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushstring(ls, val);
	return 1;
}

static int map_index_u16_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u8 val[1024] = {0};

	key = (u16)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	void *ud = lua_newuserdata(ls, map->value_size);
	memcpy(ud, val, map->value_size);
	return 1;
}

static int map_index_u32_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u8 val;

	key = (u32)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u32_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u16 val;

	key = (u32)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u32_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u32 val;

	key = (u32)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u32_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u64 val;

	key = (u32)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u32_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	char val[1024] = {0};

	key = (u32)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushstring(ls, val);
	return 1;
}

static int map_index_u32_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u8 val[1024] = {0};

	key = (u32)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	void *ud = lua_newuserdata(ls, map->value_size);
	memcpy(ud, val, map->value_size);
	return 1;
}

static int map_index_u64_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u8 val;

	key = (u64)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u64_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u16 val;

	key = (u64)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u64_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u32 val;

	key = (u64)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u64_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u64 val;

	key = (u64)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_u64_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	char val[1024] = {0};

	key = (u64)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	lua_pushstring(ls, val);
	return 1;
}

static int map_index_u64_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u8 val[1024] = {0};

	key = (u64)lua_tonumber(ls, -1);
	bpf_lookup_elem(fd, &key, &val);
	void *ud = lua_newuserdata(ls, map->value_size);
	memcpy(ud, val, map->value_size);
	return 1;
}

static int map_index_string_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u8 val;

	const char *str = lua_tostring(ls, -1);
	memcpy(&key, str, strlen(str));
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_string_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u16 val;

	const char *str = lua_tostring(ls, -1);
	memcpy(&key, str, strlen(str));
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_string_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u32 val;

	const char *str = lua_tostring(ls, -1);
	memcpy(&key, str, strlen(str));
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_string_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u64 val;

	const char *str = lua_tostring(ls, -1);
	memcpy(&key, str, strlen(str));
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_string_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	char val[1024] = {0};

	const char *str = lua_tostring(ls, -1);
	memcpy(&key, str, strlen(str));
	bpf_lookup_elem(fd, &key, &val);
	lua_pushstring(ls, val);
	return 1;
}

static int map_index_string_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u8 val[1024] = {0};

	const char *str = lua_tostring(ls, -1);
	memcpy(&key, str, strlen(str));
	bpf_lookup_elem(fd, &key, &val);
	void *ud = lua_newuserdata(ls, map->value_size);
	memcpy(ud, val, map->value_size);
	return 1;
}

static int map_index_userdata_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u8 val;

	//todo
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_userdata_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u16 val;

	//todo
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_userdata_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u32 val;

	//todo
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_userdata_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u64 val;

	//todo
	bpf_lookup_elem(fd, &key, &val);
	lua_pushnumber(ls, val);
	return 1;
}

static int map_index_userdata_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	char val[1024] = {0};

	//todo
	bpf_lookup_elem(fd, &key, &val);
	lua_pushstring(ls, val);
	return 1;
}

static int map_index_userdata_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u8 val[1024] = {0};

	//todo
	bpf_lookup_elem(fd, &key, &val);
	void *ud = lua_newuserdata(ls, map->value_size);
	memcpy(ud, val, map->value_size);
	return 1;
}

static MAP_INDEX_FUNC map_index_func_array[MAP_ELEM_TYPE_max][MAP_ELEM_TYPE_max] = {
	map_index_u8_u8_func,
	map_index_u8_u16_func,
	map_index_u8_u32_func,
	map_index_u8_u64_func,
	map_index_u8_string_func,
	map_index_u8_userdata_func,
	map_index_u16_u8_func,
	map_index_u16_u16_func,
	map_index_u16_u32_func,
	map_index_u16_u64_func,
	map_index_u16_string_func,
	map_index_u16_userdata_func,
	map_index_u32_u8_func,
	map_index_u32_u16_func,
	map_index_u32_u32_func,
	map_index_u32_u64_func,
	map_index_u32_string_func,
	map_index_u32_userdata_func,
	map_index_u64_u8_func,
	map_index_u64_u16_func,
	map_index_u64_u32_func,
	map_index_u64_u64_func,
	map_index_u64_string_func,
	map_index_u64_userdata_func,
	map_index_string_u8_func,
	map_index_string_u16_func,
	map_index_string_u32_func,
	map_index_string_u64_func,
	map_index_string_string_func,
	map_index_string_userdata_func,
	map_index_userdata_u8_func,
	map_index_userdata_u16_func,
	map_index_userdata_u32_func,
	map_index_userdata_u64_func,
	map_index_userdata_string_func,
	map_index_userdata_userdata_func,
};