#!/usr/bin/env shark

local bpf = require("bpf")

bpf.cdef[[
#include <linux/skbuff.h>
#include <linux/netdevice.h>
#include <uapi/linux/bpf.h>
#include "bpf_helpers.h"

static unsigned int log2(unsigned int v)
{
        unsigned int r;
        unsigned int shift;

        r = (v > 0xFFFF) << 4; v >>= r;
        shift = (v > 0xFF) << 3; v >>= shift; r |= shift;
        shift = (v > 0xF) << 2; v >>= shift; r |= shift;
        shift = (v > 0x3) << 1; v >>= shift; r |= shift;
        r |= (v >> 1);
        return r;
}

static unsigned int log2l(unsigned long v)
{
        unsigned int hi = v >> 32;
        if (hi)
                return log2(hi) + 32;
        else
                return log2(v);
}

bpf_map_array<u32, long, 64> my_hist_map;

SEC("kprobe/sys_write")
int bpf_prog3(struct pt_regs *ctx)
{
        long write_size = ctx->dx; /* arg3 */
        long init_val = 1;
        long *value;
        u32 index = log2l(write_size);

        value = bpf_map_lookup_elem(&my_hist_map, &index);
        if (value)
                __sync_fetch_and_add(value, 1);
        return 0;
}
]]

os.execute("dd if=/dev/zero of=/dev/null count=5000000 >/dev/null &")

set_timeout(function()
  local newmap = {}
  local my_hist_map = bpf.var.my_hist_map

  for k in pairs(my_hist_map) do
    newmap[math.pow(2, k)] = my_hist_map[k]
  end

  bpf.print_hist_map(newmap)
end, 5000)

