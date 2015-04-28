# shark

A new event modeled system tracing and monitoring tool


## Highlights

1. Rich system tracing and monitoring API
   Supported perf and bpf modules
   Will support pcap and more

2. Capture any events in real time
   shark can capture any events in real time:
   tcp(udp) packet, syscalls, tracepoints, kprobe, uprobe, function,
   stdin, stdout, http packet, and also high level user specific events.

   shark also can capture many data when event firing:
   field info, timestamp, stack, process info, etc.

3. Powerful analysis
   Powerful and flexible lua script language for event analysis, all lua
   libraries can be use for analysis.
   Easy to build cloud/distributed monitoring

4. Support ebpf scripting
   shark already support ebpf, user can access ebpf map as lua table.

5. Fast
   Jit everything. luajit and epbf both use JIT to boost execution.
   luajit's speed is as fast as C.

6. Safe
   will never crash your system.

7. Easy deployment
   No kernel module needed, all is one binary


## Prerequisites

1. use bpf module

        Linux kernel version >= 4.0
        CONFIG_BPF=y
        CONFIG_BPF_SYSCALL=y
	clang installed in target system
	Linux kernel header file installed

##Samples

1. perf tracepoint

        local perf = require("perf")
        local ffi = require("ffi")

        perf.on("sched:sched_switch", function(e)
          print(ffi.sting(e.name), e.cpu, e.pid)
          print(ffi.string(e.raw.prev_comm), ffi.string(e.raw.next_comm))
        end)

More samples can be found in samples/ directory.


## API:

1. shark

        shark.on_end(callback)
        shark.print_hist

2. timer

        set_interval(timeout, callback)
        set_timeout(timeout, callback)

3. perf

        local perf = require("perf")

        perf.on(events_str, [opts], callback)


4. bpf

        local bpf = require("bpf")

        bpf.cdef
        bpf.var.'mapname'
        bpf.print_hist_map


## Attention:

1. user pairs/ipairs on bpf map

Please don't use lua standard pairs/ipairs(below) for bpf.var.'map' now.

        for k, v in pairs(bpf.var.map) do
          -- v is always nil
          print(k, v)
        end

'v' is always nil in above code, get real 'v' by indexing again.


        for k in pairs(bpf.var.map) do
          print(k, bpf.var.map[k])
        end

## Future/TODO

There have some wish list on shark:

1. Small compiler for ebpf bytecode generate, suit for embedded systems

2. Generic translator for tracing language

3. Support debuginfo without include kernel header files

4. More api for analysis(networking, packet, etc)

## Mailing list

Google groups:
https://groups.google.com/d/forum/sharklinux


## Copyright and License

shark is licensed under GPL v2

Copyright (C) 2015 Shark Authors. All Rights Reserved.

