/*
 * perf.c
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
#include <poll.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "luajit/src/lj_obj.h"
#include "libuv/include/uv.h"

#include "perf.h"

extern unsigned int page_size;
extern lua_State *g_ls;

int use_browser = -1;
const char perf_version_string[] = "0.1";

/* this function is for luajit ffi can get symbols */
void dummy()
{
	target__validate(NULL);
	record_opts__config(NULL);
}

int lua_report(lua_State *ls, int status);
int lua_traceback(lua_State *ls);

int shark_perf_module_init(lua_State *ls)
{
	int base, ret;

	page_size = sysconf(_SC_PAGE_SIZE);
	//verbose = 2;

#include "perf_builtin_lua.h"
	ret = luaL_loadbuffer(ls, luaJIT_BC_perf, luaJIT_BC_perf_SIZE, NULL);
	if(ret) {
		ret = lua_report(ls, ret);
		return -1;
	}

	base = lua_gettop(ls) - 1;
	lua_pushcfunction(ls, lua_traceback);
	lua_insert(ls, base);

	if (lua_pcall(ls, 0, 0, base)) {
		fprintf(stderr, "%s\n", lua_tostring(ls, -1));
		exit(EXIT_FAILURE);
	}

	lua_pop(ls, 1);

	return 0;
}

