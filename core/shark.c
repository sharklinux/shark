/*
 * shark.c
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
#include <string.h>
#include <stdint.h>
#include <signal.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/utsname.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "shark.h"
#include "luv/luv.h"
#include "libuv/include/uv.h"
#include "luajit/src/lj_obj.h"


static const char *progname = "shark";
lua_State *g_ls;

static int shark_verbose;

uv_loop_t *g_event_loop;
static uv_signal_t g_uv_signal_int;
static uv_signal_t g_uv_signal_term;

static void l_message(const char *pname, const char *msg)
{
	if (pname)
		fprintf(stderr, "%s: ", pname);
	fprintf(stderr, "%s\n", msg);
	fflush(stderr);
}

int lua_report(lua_State *ls, int status)
{
	if (status && !lua_isnil(ls, -1)) {
		const char *msg = lua_tostring(ls, -1);
		if (msg == NULL)
			msg = "(error object is not a string)";
		l_message(progname, msg);
		lua_pop(ls, 1);
	}
	return status;
}

static int shark_api_debuginfo_set(lua_State *ls)
{
	return 0;
}

int lua_traceback(lua_State *ls)
{
	if (!lua_isstring(ls, 1)) {
		if (lua_isnoneornil(ls, 1) ||
		    !luaL_callmeta(ls, 1, "__tostring") ||
		    !lua_isstring(ls, -1))
			return 1;  /* Return non-string error object. */
		/* Replace object by result of __tostring metamethod. */
		lua_remove(ls, 1);
	}
	luaL_traceback(ls, ls, lua_tostring(ls, 1), 1);
	return 1;
}

static int shark_api_lua_ref(lua_State *ls)
{
	int ref;

	lua_pushvalue(ls, -1);
	ref = luaL_ref(ls, LUA_REGISTRYINDEX);
	lua_pushnumber(ls, ref);
	return 1;
}

static int shark_api_get_ref(lua_State *ls)
{
	int ref = lua_tonumber(ls, -1);
	lua_rawgeti(ls, LUA_REGISTRYINDEX, ref);
	return 1;
}

static int shark_api_stats(lua_State *ls)
{
	return 0;
}

static int shark_api_set_binary(lua_State *ls)
{
	return 0;
}

static int shark_api_exec(lua_State *ls)
{
	return 0;
}

#ifndef BPF_DISABLE
#include "bpf_load.h"

#include <net/ethernet.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <arpa/inet.h>

static int shark_api_open_raw_sock(lua_State *ls)
{
	const char *name = lua_tostring(ls, -1);

	struct sockaddr_ll sll;
	int sock;

	sock = socket(PF_PACKET, SOCK_RAW | SOCK_NONBLOCK | SOCK_CLOEXEC,
		      htons(ETH_P_ALL));
	if (sock < 0) {
		printf("cannot create raw socket\n");
		return -1;
	}

	memset(&sll, 0, sizeof(sll));
	sll.sll_family = AF_PACKET;
	sll.sll_ifindex = if_nametoindex(name);
	sll.sll_protocol = htons(ETH_P_ALL);
	if (bind(sock, (struct sockaddr *)&sll, sizeof(sll)) < 0) {
		printf("bind to %s: %s\n", name, strerror(errno));
		close(sock);
		return -1;
	}

	lua_pushnumber(ls, sock);
	return 1;
}

static int shark_api_sock_attach_bpf(lua_State *ls)
{
	int sock = lua_tonumber(ls, -1);

	if(setsockopt(sock, SOL_SOCKET, SO_ATTACH_BPF, prog_fd,
		      sizeof(prog_fd[0]))) {
		printf("cannot setsockopt: %s\n", strerror(errno));
		return -1;
	}

	return 0;
}

static int shark_api_iptos(lua_State *ls)
{
	long ip = lua_tonumber(ls, -1);
	lua_pushstring(ls, inet_ntoa((struct in_addr){htonl(ip)}));
	return 1;
}
#endif

static const struct luaL_reg ll_shark[] = {
        {"debuginfo_set", &shark_api_debuginfo_set},
        {"lua_ref", &shark_api_lua_ref},
        {"get_ref", &shark_api_get_ref},
        {"stats", &shark_api_stats},
        {"set_binary", &shark_api_set_binary},
        {"exec", &shark_api_exec},
//TODO: move to sock library
#ifndef BPF_DISABLE
        {"open_raw_sock", &shark_api_open_raw_sock},
        {"sock_attach_bpf", &shark_api_sock_attach_bpf},
        {"iptos", &shark_api_iptos},
#endif
	{NULL, NULL}
};

/* check that argument has no extra characters at the end */
#define notail(x)		{if ((x)[2] != '\0') return -1;}

#define FLAGS_VERSION		1

static int collectargs(char **argv, int *flags)
{
	int i;

	for (i = 1; argv[i] != NULL; i++) {
		if (argv[i][0] != '-')  /* Not an option? */
			return i;
		switch (argv[i][1]) {  /* Check option. */
		case '-':
			notail(argv[i]);
			return (argv[i+1] != NULL ? i+1 : 0);
		case '\0':
			return i;
		case 'v':
			notail(argv[i]);
			*flags |= FLAGS_VERSION;
			break;
		case 'V':
			shark_verbose = 1;
			return (argv[i+1] != NULL ? i+1 : 0);
		default:
			return -1;  /* invalid option */
		}
	}

	return 0;
}

static int getargs(lua_State *ls, char **argv, int n)
{
	int narg;
	int i;
	int argc = 0;

	while (argv[argc])
		argc++;  /* count total number of arguments */

	narg = argc - (n + 1);  /* number of arguments to the script */
	luaL_checkstack(ls, narg + 3, "too many arguments to script");

	for (i = n + 1; i < argc; i++)
		lua_pushstring(ls, argv[i]);

	lua_createtable(ls, narg, n + 1);

	for (i = 0; i < argc; i++) {
		lua_pushstring(ls, argv[i]);
		lua_rawseti(ls, -2, i - n);
	}

	return narg;
}

static void print_usage(void)
{
	fprintf(stderr,
	"usage: shark [options]... [script [args]...].\n"
	"Available options are:\n"
	"  -v        Show version information.\n");
	fflush(stderr);
}

static void print_version(void)
{
	fputs(SHARK_VERSION " -- " SHARK_COPYRIGHT ". " SHARK_URL "\n", stdout);
	exit(0);
}

LUALIB_API int luaopen_luv (lua_State *ls);

int main(int argc, char **argv)
{
	int ret = EXIT_FAILURE;
	int flags = 0, script;
	int base;

	if (argv[0] && argv[0][0]) progname = argv[0];

	lua_State *ls = lua_open();
	if (!ls) {
		l_message(progname, "cannot create state: not enough memory");
		return ret;
	}

	g_ls = ls;

	script = collectargs(argv, &flags);
	if (script <= 0) {  /* invalid args? */
		print_usage();
		return 0;
	}

	if (flags & FLAGS_VERSION)
		print_version();

	luaL_openlibs(ls);  /* open libraries */

	// Get package.preload so we can store builtins in it.
	lua_getglobal(ls, "package");
	lua_getfield(ls, -1, "preload");
	lua_remove(ls, -2); // Remove package

	// Store uv module definition at preload.uv
	lua_pushcfunction(ls, luaopen_luv);
	lua_setfield(ls, -2, "uv");

	luaL_openlib(ls, "shark", ll_shark, 0);

	lua_getglobal(ls, "shark");
	lua_pushboolean(ls, shark_verbose);
	lua_setfield(ls, -2, "verbose");
	lua_pop(ls, 1);

	int narg = getargs(ls, argv, script);  /* collect arguments */
	lua_setglobal(ls, "arg");

#include "shark_init.h"
	luaL_loadbuffer(ls, luaJIT_BC_shark_init, luaJIT_BC_shark_init_SIZE,
			NULL);
	lua_pcall(ls, 0, 0, 0);

	g_event_loop = luv_loop(ls);

	if(ret = luaL_loadfile(ls, argv[script])) {
		ret = lua_report(ls, ret);
		goto out;
	}

	base = lua_gettop(ls) - 1;
	lua_pushcfunction(ls, lua_traceback);
	lua_insert(ls, base);

	if (lua_pcall(ls, 0, 0, base)) {
		fprintf(stderr, "%s\n", lua_tostring(ls, -1));
		exit(EXIT_FAILURE);
	}

	lua_pop(ls, 1);

	//TODO: move to lua init code
	uv_run(g_event_loop, UV_RUN_DEFAULT);

	ret = 0;
 out:
	lua_close(ls);
	return ret;
}

