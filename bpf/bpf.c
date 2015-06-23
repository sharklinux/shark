/*
 * bpf.c
 *
 * Copyright (C) 2015 Shark Authors. All Rights Reserved.
 *
 * shark is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * shark is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>
#include <unistd.h>
#include <errno.h>
#include <linux/bpf.h>
#include <poll.h>

#include "libbpf.h"
#include "bpf_load.h"
#include "bpf_map_def.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "luajit/src/lj_obj.h"
#include "libuv/include/uv.h"

#include "luajit/src/lj_obj.h"

typedef char u8;
typedef short u16;
typedef unsigned int u32;
typedef uint64_t u64;

#include "bpf_map_index_func.h"
#include "bpf_map_newindex_func.h"
#include "bpf_map_next_func.h"

extern lua_State *g_ls;

static int get_type(const char *type_name)
{
	if (!strcmp(type_name, "char") || !strcmp(type_name, "u8")) {
		return  MAP_ELEM_TYPE_u8;
	} else if (!strcmp(type_name, "short") || !strcmp(type_name, "u16")) {
		return MAP_ELEM_TYPE_u16;
	} else if (!strcmp(type_name, "int") || !strcmp(type_name, "u32")) {
		return MAP_ELEM_TYPE_u32;
	} else if (!strcmp(type_name, "long")) {
		if (sizeof(long) == 4)
			return MAP_ELEM_TYPE_u32;
		else if (sizeof(long) == 8)
			return MAP_ELEM_TYPE_u64;
	} else if (!strcmp(type_name, "long long") ||
		   !strcmp(type_name, "u64")) {
		return MAP_ELEM_TYPE_u64;
	} else if (!strcmp(type_name, "string")) {
		return MAP_ELEM_TYPE_string;
	} else
		return MAP_ELEM_TYPE_userdata;
}

static int mt_index(lua_State *ls)
{
	MAP_INDEX_FUNC func;
	struct bpf_map_def *map;
	int fd;
	GCtab *t;

	t = tabV(ls->top - 2);
	fd = t->data1;
	map = t->data2;
	func = t->data3;
	func(ls, fd, map);
	return 1;
}

static int mt_newindex(lua_State *ls)
{
	MAP_NEWINDEX_FUNC func;
	struct bpf_map_def *map;
	int fd;
	GCtab *t;

	t = tabV(ls->top - 3);
	fd = t->data1;
	map = t->data2;
	func = t->data4;
	func(ls, fd, map);
	return 0;
}

static int mt_pairs(lua_State *ls)
{
	MAP_NEXT_FUNC func;
	struct bpf_map_def *map;
	int fd;
	GCtab *t;

	t = tabV(ls->top - 1);
	fd = t->data1;
	map = t->data2;
	func = t->data5;
	lua_pushcfunction(ls, func); //push next function
	lua_pushvalue(ls, -2); //push table
	lua_pushnil(ls); //push nil
	return 3;
}

static void init_metatable(lua_State *ls, struct bpf_map_def *map, int fd)
{
	MAP_INDEX_FUNC index_func;
	MAP_NEWINDEX_FUNC newindex_func;
	MAP_NEXT_FUNC next_func;
	GCtab *t;

	index_func = map_index_func_array[get_type(map->key_type)]
					 [get_type(map->val_type)];

	newindex_func = map_newindex_func_array[get_type(map->key_type)]
					       [get_type(map->val_type)];

	next_func = map_next_func_array[get_type(map->key_type)];

	//hack luajit table structure
	t = tabV(ls->top - 1);
	t->data1 = fd;
	t->data2 = map;
	t->data3 = index_func;
	t->data4 = newindex_func;
	t->data5 = next_func;

	lua_createtable(ls, 0, 4); //create metatable

	lua_pushcfunction(ls, mt_index);
	lua_setfield(ls, -2, "__index");

	lua_pushcfunction(ls, mt_newindex);
	lua_setfield(ls, -2, "__newindex");

	lua_pushcfunction(ls, mt_pairs);
	lua_setfield(ls, -2, "__pairs");

	lua_pushcfunction(ls, mt_pairs);
	lua_setfield(ls, -2, "__ipairs");

	lua_setmetatable(ls, -2);
}

int shark_create_bpf_map(struct bpf_map_def *maps, int len)
{
	lua_State *ls = g_ls;
	int size = len / sizeof(struct bpf_map_def);
	int i;

	/* get the temp bpf global varible */
	lua_getglobal(ls, "bpf");
	lua_createtable(ls, 0, size); //create var table

	for (i = 0; i < size; i++) {
		map_fd[i] = bpf_create_map(maps[i].type,
					   maps[i].key_size,
					   maps[i].value_size,
					   maps[i].max_entries);
		if (map_fd[i] < 0) {
			printf("create map %s failed\n", maps[i].name);
			return 1;
		}

		lua_createtable(ls, 2, 2);
		init_metatable(ls, &maps[i], map_fd[i]);
		lua_setfield(ls, -2, maps[i].name);
	}

	lua_setfield(ls, -2, "var");
	lua_pop(ls, 1);

	/* clear the temp bpf global variable */
	lua_pushnil(ls);
	lua_setglobal(ls, "bpf");
	return 0;
}

int shark_bpf_module_init(lua_State *ls)
{
	return 0;
}

