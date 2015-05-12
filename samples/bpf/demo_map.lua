#!/usr/bin/env shark

local bpf = require("bpf")
local ffi = require("ffi")

bpf.cdef[[
#include <linux/skbuff.h>
#include <linux/netdevice.h>
#include <uapi/linux/bpf.h>
#include "bpf_helpers.h"

struct pair {
	u64 val;
	u64 ip;
};

bpf_map_hash<int, int, 10> map1;
bpf_map_hash<char[100], int, 1024> map2;
bpf_map_hash<char[100], char[100], 1024> map3;
bpf_map_hash<int, char[100]> map4;
bpf_map_hash<int, struct pair> map5;

bpf_map_hash<char[100], int, 1> map_sched_num;

SEC("kprobe/schedule")
int bpf_prog1(struct pt_regs *ctx)
{
	char strk[100] = "this is string key.";
	char strv[100] = "this is string value.";
	int val1 = 1;
	int val2 = 2;

	bpf_map_update_elem(&map1, &val1, &val2, BPF_ANY);

	bpf_map_update_elem(&map2, &strk, &val1, BPF_ANY);
	bpf_map_update_elem(&map2, &strk, &val2, BPF_ANY);

	bpf_map_update_elem(&map3, &strk, &strv, BPF_ANY);

	bpf_map_update_elem(&map4, &val1, &strv, BPF_ANY);

        struct pair v = {
                .val = bpf_ktime_get_ns(),
                .ip = 0x9,
        };
        bpf_map_update_elem(&map5, &val1, &v, BPF_ANY);

	char strx[100] = "schedule numbers:";
	int *num;
	int init_val = 1;
	num = bpf_map_lookup_elem(&map_sched_num, &strx);
	if (num)
		__sync_fetch_and_add(num, 1);
	else
		bpf_map_update_elem(&map_sched_num, &strx, &init_val, BPF_ANY);

	return 0;
}
]]

ffi.cdef[[
  struct pair {
    uint64_t val;
    uint64_t ip;
  };
]]

set_interval(function()
  print("\n[map_sched_num]:")
  bpf.print_map(bpf.var.map_sched_num)

  print("\n[map5]:")
  local pair = ffi.cast("struct pair *", bpf.var.map5[1])
  print(pair.val, pair.ip)
end, 1000)

shark.on_end(function()
  print("\n[map1]:")
  bpf.print_map(bpf.var.map1)

  print("\n[map2]:")
  bpf.print_map(bpf.var.map2)

  print("\n[map3]:")
  bpf.print_map(bpf.var.map3)

  print("\n[map4]:")
  bpf.print_map(bpf.var.map4)

  print("\n[map_sched_num]:")
  bpf.print_map(bpf.var.map_sched_num)
end)

