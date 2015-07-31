# shark

We're building a better performance management system, which include API, consistent commandline tools, cloud monitoring and analysis.

## Quick Start

1. perf tracepoint

        local perf = require("perf")
        local ffi = require("ffi")

        perf.on("sched:sched_switch", function(e)
          print(ffi.string(e.name), e.cpu, e.pid)
          print(ffi.string(e.raw.prev_comm), ffi.string(e.raw.next_comm))
        end)

        perf.on("syscalls:*", function(e)
          print(ffi.string(e.name))
        end)

        perf.on("cpu-clock", {callchain_k = 1}, function(e)
          print(e.callchain)
        end)

2. flamegraph

        local perf = require "perf"
        local sharkcloud = require "sharkcloud"

        local profile = {}
        setmetatable(profile, {__index = function() return 0 end})

        perf.on("cpu-clock", {callchain_k = 1}, function(e)
          profile[e.callchain] = profile[e.callchain] + 1
        end)

        shark.on_end(function()
          --Open flamegraph at http://sharkly.io/
          sharkcloud.senddata("flamegraph", profile)
        end)


More samples can be found in samples/ directory.


## Motivation

Currently System Performance Management is painful(and suck).

Pains:
- No unified system tracing and monitoring scripting API
  (No way to programming perf event; systemtap is in kernel space; etc)
- Too fragmental commandline tools
- limited system visualization
  (flamegraph and heatmap is a good start, but we need more than that)
- No easy use cloud monitoring solution
- All is based on your experence

Shark project is trying to change System Performance Management in
three levels: API, Consistent commandline tools, Cloud monitoring and analysis

*API*

shark project expect to delieve a unified event API, user can programming the
API, we believe that a well designed system tracing and monitoring API is the
fundamental base for Consistent commandline tools and Cloud monitoring.

We already developed lua perf event API, more API will be supportted soon.

*Consistent commandline tools*

Based on powerful API, we can invent many consistent commandline tools which 
cover different subsystems. We think "consistent" is very important for long
term evolution, and it's important for cloud analysis platform.

*Cloud monitoring and analysis*

We believe ultimately all system performance management will goes to
intelligent, most likely through cloud. user don't need spend many days to
investigate why system become slow, the cloud robot will tell you the reason
instantly.

The ultimate goal of shark project is build a cloud robot with special
intelligence on system performane management, in open source way. 

## Highlights

1. Rich system tracing and monitoring API

   Supported perf and bpf modules
   Will support more api soon(pcap)

2. Capture any events in real time(Support in future)

   shark can capture any events in real time:
   tcp(udp) packet, syscalls, tracepoints, kprobe, uprobe, function,
   stdin, stdout, http packet, and also high level user specific events.

   shark also can capture many data when event firing:
   field info, timestamp, stack, process info, etc.

3. Powerful analysis

   Powerful and flexible lua script language for event analysis, all lua
   libraries can be use for analysis.
   Easy to build cloud/distributed monitoring solution

4. Support perf/ebpf scripting

   trace perf event as you want, all is in userspace.
   shark already support ebpf, user can access ebpf map as lua table.

5. Fast

   Jit everything. luajit and epbf both use JIT to boost execution.
   luajit's speed is as fast as C.

6. Safe

   will never crash your system.

7. Easy deployment

   No kernel module needed.
   will support standalone binary deployment soon.


## API:

1. shark

        shark.on_end(callback)
        shark.print_hist

2. sharkcloud

        sharkcloud.senddata("flamegraph", table)
        sharkcloud.senddata("heatmap", table)

2. timer

        set_interval(timeout, callback)
        set_timeout(timeout, callback)

3. perf

        local perf = require "perf"

        perf.on(events_str, [opts], callback)

        perf.print(event)

4. perf config option

        perf can be configured by table:

        struct shark_perf_config {
            int no_buffering;
            int wake_events;
            int mmap_pages;
            const char *target_pid;
            const char *target_tid;
            const char *target_cpu_list;
            const char *filter;
            int read_events_rate;
            int callchain_k;
            int callchain_u;
        };

5. event

        All perf traced events is C data (struct perf_sample), so
        user can access the event directly(and very fast).

        the detail event data structure is:

        struct event_sample {
            u64 ip;
            u32 pid, tid;
            u64 time;
            u64 addr;
            u64 id;
            u64 stream_id;
            u64 period;
            u64 weight;
            u64 transaction;
            u32 cpu;
            u32 raw_size;
            u64 data_src;
            u32 flags;
            u16 insn_len;
            union {
                void *raw_data;
                struct event_fmt_type *raw; /* event specific type */
            };
            struct ip_callchain *_callchain;
            struct branch_stack *branch_stack;
            struct regs_dump  user_regs;
            struct regs_dump  intr_regs;
            struct stack_dump user_stack;
            struct sample_read read;

            const char *name;
        };

        Most frequent used field is(e as event):
        e.time, e.pid, e.tid, e.cpu, e.raw.*, e.name, e.callchain

        The "raw" format type can be found in:
        /sys/kernel/debug/tracing/events/$SUBSYSTEM/$EVENT/format 

        for example, for event "sched:sched_switch", we can access event raw
        fields like below:
        e.raw.prev_comm, e.raw.prev_pid, e.raw.prev_state, ...

        Also, event can be printed by "perf.print(e)"


6. bpf

        local bpf = require "bpf"

        bpf.cdef
        bpf.var.'mapname'
        bpf.print_hist_map

## Prerequisites

1. use bpf module

        Linux kernel version >= 4.0 (use 'make BPF_DISABLE=1' for old kernel)
        CONFIG_BPF=y
        CONFIG_BPF_SYSCALL=y
	clang installed in target system
        llc-bpf binary installed(https://github.com/sharklinux/llc-bpf)
	Linux kernel header file installed

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

Please go to shark wiki:
https://github.com/sharklinux/shark/wiki/todo-list

## Mailing list

Google groups:
https://groups.google.com/d/forum/sharklinux


## Copyright and License

shark is licensed under GPL v2

Copyright (C) 2015 Shark Authors. All Rights Reserved.

