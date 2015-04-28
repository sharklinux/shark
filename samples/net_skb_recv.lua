#!/usr/bin/env shark

local bpf = require("bpf")

bpf.cdef[[
#include <linux/skbuff.h>
#include <linux/netdevice.h>
#include <uapi/linux/bpf.h>
#include "bpf_helpers.h"

#define _(P) ({typeof(P) val = 0; bpf_probe_read(&val, sizeof(val), &P); val;})

SEC("kprobe/__netif_receive_skb_core")
int bpf_prog1(struct pt_regs *ctx)
{
        /* attaches to kprobe netif_receive_skb,
         * looks for packets on loobpack device and prints them
         */
        char devname[IFNAMSIZ] = {};
        struct net_device *dev;
        struct sk_buff *skb;
        int len;

        /* non-portable! works for the given kernel only */
        skb = (struct sk_buff *) ctx->di;
        dev = _(skb->dev);
        len = _(skb->len);

        bpf_probe_read(devname, sizeof(devname), dev->name);

        if (devname[0] == 'l' && devname[1] == 'o') {
                char fmt[] = "skb %p len %d\n";
                /* using bpf_trace_printk() for DEBUG ONLY */
                bpf_trace_printk(fmt, sizeof(fmt), skb, len);
        }

        return 0;
}
]]

os.execute("taskset 1 ping -c5 localhost >/dev/null &")

for line in io.lines("/sys/kernel/debug/tracing/trace_pipe") do
  print(line)
end

