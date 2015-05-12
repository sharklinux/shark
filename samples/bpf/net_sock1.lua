#!/usr/bin/env shark

local bpf = require("bpf")

bpf.cdef[[
#include <uapi/linux/bpf.h>
#include <uapi/linux/if_ether.h>
#include <uapi/linux/ip.h>
#include "bpf_helpers.h"

bpf_map_array<int, long, 256> my_map;

SEC("socket1")
int bpf_prog1(struct sk_buff *skb)
{
        int index = load_byte(skb, ETH_HLEN + offsetof(struct iphdr, protocol));
        long *value;

        value = bpf_map_lookup_elem(&my_map, &index);
        if (value)
                __sync_fetch_and_add(value, 1);

        return 0;
}
]]

local sock = shark.open_raw_sock("lo")
shark.sock_attach_bpf(sock)

os.execute("ping -c5 localhost >/dev/null &")

local IPPROTO_TCP, IPPROTO_UDP, IPPROTO_ICMP = 6, 17, 1

local my_map = bpf.var.my_map
set_interval(function()
  print("TCP:", my_map[IPPROTO_TCP],
        "UDP", my_map[IPPROTO_UDP],
        "ICMP", my_map[IPPROTO_ICMP])
end, 1000)

