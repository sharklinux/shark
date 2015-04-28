
CFLAGS=-I. -I core/ -I core/libuv/include -I core/luajit/src/ -I bpf/libbpf/

CORE_LIB=core/luajit/src/libluajit.a core/libuv/.libs/libuv.a

PERF_LIBS= perf/libperf.a perf/libtraceevent.a perf/libapikfs.a
BPF_LIBS=bpf/libbpf/libbpf.a
LIB=$(CORE_LIB) $(PERF_LIBS) $(BPF_LIBS) -lm -ldl -lelf -lc -lpthread

TARGET=shark
OBJS=core/shark.o core/luv/luv.o bpf/bpf.o perf/perf.o

BUILTIN_LUA_HEADER = core/shark_builtin.h bpf/bpf_builtin_lua.h perf/perf_builtin_lua.h

#ffi need to call some functions in library, so add -rdynamic option
$(TARGET) : $(BUILTIN_LUA_HEADER) $(OBJS) force
	clang++ -o $(TARGET) -rdynamic $(OBJS) $(LIB)

DEPS := $(OBJS:.o=.d)
-include $(DEPS)

%.o : %.c
	$(CC) -MD -g -c $(CFLAGS) $< -o $@

core/shark_builtin.h : core/shark.lua
	luajit -b core/shark.lua core/shark_builtin.h

bpf/bpf_builtin_lua.h : bpf/bpf.lua
	luajit -b bpf/bpf.lua bpf/bpf_builtin_lua.h

perf/perf_builtin_lua.h : perf/perf.lua
	luajit -b perf/perf.lua perf/perf_builtin_lua.h

force:
	true

clean:
	@rm -rf $(TARGET) *.d *.o core/*.d core/*.o

