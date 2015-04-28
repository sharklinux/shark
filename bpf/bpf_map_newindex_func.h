typedef int (*MAP_NEWINDEX_FUNC)(lua_State *ls, int fd, struct bpf_map_def *map);

#define BPF_ANY         0

static int map_newindex_u8_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u8 val;

	key = (u8)lua_tonumber(ls, -2);
	val = (u8)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u8_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u16 val;

	key = (u8)lua_tonumber(ls, -2);
	val = (u16)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u8_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u32 val;

	key = (u8)lua_tonumber(ls, -2);
	val = (u32)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u8_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u64 val;

	key = (u8)lua_tonumber(ls, -2);
	val = (u64)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u8_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	char val[1024] = {0};

	key = (u8)lua_tonumber(ls, -2);
	memcpy(&val, lua_tostring(ls, -1), 1024); // TODO
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u8_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key;
	u8 val[1024] = {0};

	key = (u8)lua_tonumber(ls, -2);
	//todo
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u16_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u8 val;

	key = (u16)lua_tonumber(ls, -2);
	val = (u8)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u16_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u16 val;

	key = (u16)lua_tonumber(ls, -2);
	val = (u16)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u16_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u32 val;

	key = (u16)lua_tonumber(ls, -2);
	val = (u32)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u16_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u64 val;

	key = (u16)lua_tonumber(ls, -2);
	val = (u64)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u16_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	char val[1024] = {0};

	key = (u16)lua_tonumber(ls, -2);
	memcpy(&val, lua_tostring(ls, -1), 1024); // TODO
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u16_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u16 key;
	u8 val[1024] = {0};

	key = (u16)lua_tonumber(ls, -2);
	//todo
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u32_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u8 val;

	key = (u32)lua_tonumber(ls, -2);
	val = (u8)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u32_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u16 val;

	key = (u32)lua_tonumber(ls, -2);
	val = (u16)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u32_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u32 val;

	key = (u32)lua_tonumber(ls, -2);
	val = (u32)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u32_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u64 val;

	key = (u32)lua_tonumber(ls, -2);
	val = (u64)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u32_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	char val[1024] = {0};

	key = (u32)lua_tonumber(ls, -2);
	memcpy(&val, lua_tostring(ls, -1), 1024); // TODO
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u32_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u32 key;
	u8 val[1024] = {0};

	key = (u32)lua_tonumber(ls, -2);
	//todo
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u64_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u8 val;

	key = (u64)lua_tonumber(ls, -2);
	val = (u8)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u64_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u16 val;

	key = (u64)lua_tonumber(ls, -2);
	val = (u16)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u64_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u32 val;

	key = (u64)lua_tonumber(ls, -2);
	val = (u32)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u64_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u64 val;

	key = (u64)lua_tonumber(ls, -2);
	val = (u64)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u64_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	char val[1024] = {0};

	key = (u64)lua_tonumber(ls, -2);
	memcpy(&val, lua_tostring(ls, -1), 1024); // TODO
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_u64_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u64 key;
	u8 val[1024] = {0};

	key = (u64)lua_tonumber(ls, -2);
	//todo
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_string_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u8 val;

	memcpy(&key, lua_tostring(ls, -2), 1024); // TODO
	val = (u8)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_string_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u16 val;

	memcpy(&key, lua_tostring(ls, -2), 1024); // TODO
	val = (u16)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_string_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u32 val;

	memcpy(&key, lua_tostring(ls, -2), 1024); // TODO
	val = (u32)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_string_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u64 val;

	memcpy(&key, lua_tostring(ls, -2), 1024); // TODO
	val = (u64)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_string_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	char val[1024] = {0};

	memcpy(&key, lua_tostring(ls, -2), 1024); // TODO
	memcpy(&val, lua_tostring(ls, -1), 1024); // TODO
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_string_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	char key[1024] = {0};
	u8 val[1024] = {0};

	memcpy(&key, lua_tostring(ls, -2), 1024); // TODO
	//todo
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_userdata_u8_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u8 val;

	//todo
	val = (u8)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_userdata_u16_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u16 val;

	//todo
	val = (u16)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_userdata_u32_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u32 val;

	//todo
	val = (u32)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_userdata_u64_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u64 val;

	//todo
	val = (u64)lua_tonumber(ls, -1);
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_userdata_string_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	char val[1024] = {0};

	//todo
	memcpy(&val, lua_tostring(ls, -1), 1024); // TODO
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static int map_newindex_userdata_userdata_func(lua_State *ls, int fd, struct bpf_map_def *map) {
	u8 key[1024] = {0};
	u8 val[1024] = {0};

	//todo
	//todo
	bpf_update_elem(fd, &key, &val, BPF_ANY);
	return 0;
}

static MAP_NEWINDEX_FUNC map_newindex_func_array[MAP_ELEM_TYPE_max][MAP_ELEM_TYPE_max] = {
	map_newindex_u8_u8_func,
	map_newindex_u8_u16_func,
	map_newindex_u8_u32_func,
	map_newindex_u8_u64_func,
	map_newindex_u8_string_func,
	map_newindex_u8_userdata_func,
	map_newindex_u16_u8_func,
	map_newindex_u16_u16_func,
	map_newindex_u16_u32_func,
	map_newindex_u16_u64_func,
	map_newindex_u16_string_func,
	map_newindex_u16_userdata_func,
	map_newindex_u32_u8_func,
	map_newindex_u32_u16_func,
	map_newindex_u32_u32_func,
	map_newindex_u32_u64_func,
	map_newindex_u32_string_func,
	map_newindex_u32_userdata_func,
	map_newindex_u64_u8_func,
	map_newindex_u64_u16_func,
	map_newindex_u64_u32_func,
	map_newindex_u64_u64_func,
	map_newindex_u64_string_func,
	map_newindex_u64_userdata_func,
	map_newindex_string_u8_func,
	map_newindex_string_u16_func,
	map_newindex_string_u32_func,
	map_newindex_string_u64_func,
	map_newindex_string_string_func,
	map_newindex_string_userdata_func,
	map_newindex_userdata_u8_func,
	map_newindex_userdata_u16_func,
	map_newindex_userdata_u32_func,
	map_newindex_userdata_u64_func,
	map_newindex_userdata_string_func,
	map_newindex_userdata_userdata_func,
};