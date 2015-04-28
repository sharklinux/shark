
CFLAGS=-I. -I core/ -I core/libuv/include -I core/luajit/src/ -I bpf/libbpf/

CORE_LIB=core/luajit/src/libluajit.a core/libuv/.libs/libuv.a

PERF_LIBS= perf/libperf.a perf/libtraceevent.a perf/libapikfs.a
BPF_LIBS=bpf/libbpf/libbpf.a
LIB=$(CORE_LIB) $(PERF_LIBS) $(BPF_LIBS) -lm -ldl -lelf -lc -lpthread

TARGET=shark
OBJS=core/shark.o core/luv/luv.o bpf/bpf.o perf/perf.o

BUILTIN_LUA_OBJS = perf/perf_builtin_lua.o bpf/bpf_builtin_lua.o

OBJS += $(BUILTIN_LUA_OBJS)

#ffi need to call some functions in library, so add -rdynamic option
$(TARGET) : core/luajit/src/libluajit.a core/libuv/.libs/libuv.a core/shark_init.h $(OBJS) force
	$(CC) -o $(TARGET) -rdynamic $(OBJS) $(LIB)

core/luajit/src/libluajit.a:
	@cd core/luajit; make

core/libuv/.libs/libuv.a:
	@cd core/libuv; make


DEPS := $(OBJS:.o=.d)
-include $(DEPS)

%.o : %.c
	$(CC) -MD -g -c $(CFLAGS) $< -o $@

LUAJIT_BIN=core/luajit/src/luajit

core/shark_init.h : core/shark_init.lua
	cd core/luajit/src; ./luajit -b ../../shark_init.lua ../../shark_init.h

bpf/bpf_builtin_lua.o : bpf/bpf.lua
	cd core/luajit/src; ./luajit -b ../../../bpf/bpf.lua ../../../bpf/bpf_builtin_lua.o

perf/perf_builtin_lua.o : perf/perf.lua
	cd core/luajit/src; ./luajit -b ../../../perf/perf.lua ../../../perf/perf_builtin_lua.o

force:
	true

clean:
	@rm -rf $(TARGET) *.d *.o core/*.d core/*.o bpf/*.d bpf/*.o perf/*.d perf/*.o core/shark_builtin.h bpf/bpf_builtin_lua.h perf/perf_builtin_lua.h

