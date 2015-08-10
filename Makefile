
#Define BPF_ENABLE if Linux kernel is 4.0+
#BPF_DISABLE=1

CFLAGS=-I. -I core/ -I core/libuv/include -I core/luajit/src/ -I bpf/libbpf/

CORE_LIB=core/luajit/src/libluajit.a core/libuv/.libs/libuv.a

PERF_LIBS= perf/libperf.a perf/libtraceevent.a perf/libapikfs.a
LIB=$(CORE_LIB) $(PERF_LIBS) -lm -ldl -lelf -lc -lpthread

OBJS=core/shark.o core/luv/luv.o perf/perf.o

BUILTIN_LUA_OBJS = perf/perf_builtin_lua.o
OBJS += $(BUILTIN_LUA_OBJS)

ifndef BPF_DISABLE
OBJS += bpf/bpf.o bpf/libbpf/bpf_load.o bpf/libbpf/libbpf.o
BUILTIN_LUA_OBJS += bpf/bpf_builtin_lua.o
else
CFLAGS += -DBPF_DISABLE
endif

TARGET=shark

#ffi need to call some functions in library, so add -rdynamic option
$(TARGET) : core/luajit/src/libluajit.a core/libuv/.libs/libuv.a core/shark_init.h $(OBJS) force
	$(CC) -o $(TARGET) -rdynamic $(OBJS) $(LIB)

core/luajit/src/libluajit.a:
	@cd core/luajit; make

core/libuv/.libs/libuv.a:
	@cd core/libuv; ./autogen.sh; ./configure; make


DEPS := $(OBJS:.o=.d)
-include $(DEPS)

%.o : %.c
	$(CC) -MD -g -c $(CFLAGS) $< -o $@

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

