--[[
/*
 * perf.lua
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
--]]

local shark = shark
local shark_get_ref = shark.get_ref
local gettimeofday = shark.gettimeofday
local uv = require("uv")
local ffi = require("ffi")
local ffi_cast = ffi.cast
local C = ffi.C
local tonumber = tonumber
local tostring = tostring

---------------------------------------------------------------

ffi.cdef[[
typedef int pid_t;
typedef uint8_t u8;
typedef uint8_t __u8;
typedef int8_t s8;
typedef uint16_t u16;
typedef uint16_t __u16;
typedef int16_t __s16;
typedef uint32_t u32;
typedef uint32_t __u32;
typedef int32_t s32;
typedef uint64_t u64;
typedef uint64_t __u64;
typedef int64_t s64;
typedef int64_t __int64_t;

typedef unsigned int uid_t;

/* struct perf_handle is design for shark */
struct perf_handle {
	struct perf_evlist *evlist;
	struct perf_session *session;
	struct machine *machine;
};

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

struct target {
        const char   *pid;
        const char   *tid;
        const char   *cpu_list;
        const char   *uid_str;
        uid_t        uid;
        bool         system_wide;
        bool         uses_mmap;
        bool         default_per_cpu;
        bool         per_thread;
};

struct record_opts {
        struct target target;
        bool         group;
        bool         inherit_stat;
        bool         no_buffering;
        bool         no_inherit;
        bool         no_inherit_set;
        bool         no_samples;
        bool         raw_samples;
        bool         sample_address;
        bool         sample_weight;
        bool         sample_time;
        bool         period;
        bool         sample_intr_regs;
        unsigned int freq;
        unsigned int mmap_pages;
        unsigned int user_freq;
        u64          branch_stack;
        u64          default_interval;
        u64          user_interval;
        bool         sample_transaction;
        unsigned     initial_delay;
};


enum perf_event_type {
	PERF_RECORD_LOST                        = 2,
	PERF_RECORD_SAMPLE                      = 9,
};

struct perf_event_header {
        __u32   type;
        __u16   misc;
        __u16   size;
};

struct sample_event {
	struct perf_event_header        header;
	u64 array[];
};

struct lost_event {
	struct perf_event_header header;
	u64 id;
	u64 lost;
};

union perf_event {
	struct perf_event_header        header;
	struct sample_event             sample;
	struct lost_event               lost;
};

int perf_module_init();
void perf_callchain_enable(void);
struct perf_evlist *perf_evlist__new(void);
void perf_evlist__enable(void *evlist);
void perf_evlist__disable(void *evlist);
void *perf_evsel__rawptr_v2(struct event_format *tp_format, void *raw_data,
                            const char *name);
void event_format__print(struct event_format *event,
                         int cpu, void *data, int size);

int perf_evlist__create_maps(struct perf_evlist *evlist, struct target *target);
int perf_evlist__mmap(struct perf_evlist *evlist, unsigned int pages,
                      bool overwrite);
void perf_evlist__config(struct perf_evlist *evlist, struct record_opts *opts);
int perf_evlist__open(struct perf_evlist *evlist);
int perf_evlist__set_filter(struct perf_evlist *evlist, const char *filter);
int target__validate(struct target *target);
int target__parse_uid(struct target *target);
int record_opts__config(struct record_opts *opts);
int parse_events(struct perf_evlist *evlist, const char *str);
union perf_event *perf_evlist__mmap_read_top(struct perf_evlist *evlist,
                                             int *idx);
void perf_evlist__mmap_consume(struct perf_evlist *evlist, int idx);
int perf_evlist__parse_sample_v2(struct perf_evlist *evlist,
                                 union perf_event *event,
                                 struct perf_sample *sample,
                                 struct perf_evsel **ret_evsel);
const char *perf_callchain_backtrace(union perf_event *event,
                                     struct perf_sample *sample,
                                     struct machine *machine);
struct perf_session *perf_session__init(struct perf_evlist *evlist,
                                        struct record_opts *opts);
int machine__process_event(struct machine *machine, union perf_event *event,
                           struct perf_sample *sample);
struct machine *perf_session__get_machine(struct perf_session *session);
void perf_evsel__set_callchain(struct perf_evsel *evsel, bool callchain_k,
                               bool callchain_u);
struct thread *machine__findnew_thread(struct machine *machine, pid_t pid,
                                       pid_t tid);
const char *machine__parse_ip(struct machine *machine,
                              struct perf_sample *sample, u64 ip);

struct pollfd {
	int fd;
	short events;
	short revents;
};

struct pollfd *perf_evlist_pollfd(struct perf_evlist *evlist, int *nr);
void perf_evlist_foreach(struct perf_evlist *evlist,
			 void (*func)(struct perf_evlist *evlist,
				      struct perf_evsel *evsel, void *data),
			 void *data);

void perf_evsel__set_sample_id(struct perf_evsel *evsel,
			       bool use_sample_identifier);

enum perf_event_sample_format {
        PERF_SAMPLE_IP                          = 1U << 0,
        PERF_SAMPLE_TID                         = 1U << 1,
        PERF_SAMPLE_TIME                        = 1U << 2,
        PERF_SAMPLE_ADDR                        = 1U << 3,
        PERF_SAMPLE_READ                        = 1U << 4,
        PERF_SAMPLE_CALLCHAIN                   = 1U << 5,
        PERF_SAMPLE_ID                          = 1U << 6,
        PERF_SAMPLE_CPU                         = 1U << 7,
        PERF_SAMPLE_PERIOD                      = 1U << 8,
        PERF_SAMPLE_STREAM_ID                   = 1U << 9,
        PERF_SAMPLE_RAW                         = 1U << 10,
        PERF_SAMPLE_BRANCH_STACK                = 1U << 11,
        PERF_SAMPLE_REGS_USER                   = 1U << 12,
        PERF_SAMPLE_STACK_USER                  = 1U << 13,
        PERF_SAMPLE_WEIGHT                      = 1U << 14,
        PERF_SAMPLE_DATA_SRC                    = 1U << 15,
        PERF_SAMPLE_IDENTIFIER                  = 1U << 16,
        PERF_SAMPLE_TRANSACTION                 = 1U << 17,
        PERF_SAMPLE_REGS_INTR                   = 1U << 18,

        PERF_SAMPLE_MAX = 1U << 19,             /* non-ABI */
};
void __perf_evsel__set_sample_bit(struct perf_evsel *evsel,
				  enum perf_event_sample_format bit);

struct event_format *perf_evsel__tp_fmt(struct perf_evsel *evsel);
const char *perf_evsel__name(struct perf_evsel *evsel);
int perf_evsel__get_ctype_ref(struct perf_evsel *evsel);
void perf_evsel__set_ctype_ref(struct perf_evsel *evsel, int ctype_ref);

struct ip_callchain {
	u64 nr;
	u64 ips[0];
};

struct branch_flags {
	u64 reserved; /* not support u64 bitfield */
};

struct branch_entry {
	u64                     from;
	u64                     to;
	struct branch_flags     flags;
};

struct branch_stack {
	u64                     nr;
	struct branch_entry     entries[0];
};

struct regs_dump {
	u64 abi;
	u64 mask;
	u64 *regs;

	/* Cached values/mask filled by first register access. */
	u64 cache_regs[24]; /* only for x86_64 */
	u64 cache_mask;
};

struct stack_dump {
	u16 offset;
	u64 size;
	char *data;
};

struct sample_read_value {
	u64 value;
	u64 id;
};

struct sample_read {
	u64 time_enabled;
	u64 time_running;
	union {
		struct {
			u64 nr;
			struct sample_read_value *values;
		} group;
		struct sample_read_value one;
	};
};
]]

local perf = {}

C.perf_module_init()

perf.enable = function(evlist)
  C.perf_evlist__enable(evlist)
end

perf.disable = function()
  C.perf_evlist__disable(evlist)
end

local perf_default_config = ffi.new("struct shark_perf_config")
perf_default_config.no_buffering = 1
perf_default_config.wake_events = 1
--perf default mmap pages is 128 if given UINT_MAX
perf_default_config.mmap_pages = 4294967295ULL --UINT_MAX
perf_default_config.target_pid = nil
perf_default_config.target_tid = nil
perf_default_config.target_cpu_list = nil
perf_default_config.filter = nil
perf_default_config.read_events_rate = 200


perf.default_config = perf_default_config

---------------------------------------------------------------

--Define common type which used in tracepoint event format
ffi.cdef[[
typedef struct { __u8 b[16]; } uuid_le; //ras:extlog_mem_event

struct cper_mem_err_compact {
	__u64 validation_bits;
	__u16 node;
	__u16 card;
	__u16 module;
	__u16 bank;
	__u16 device;
	__u16 row;
	__u16 column;
	__u16 bit_pos;
	__u64 requestor_id;
	__u64 responder_id;
	__u64 target_id;
	__u16 rank;
	__u16 mem_array_handle;
	__u16 mem_dev_handle;
}; //ras:extlog_mem_event

enum thermal_trip_type {THERMAL_TRIP_ACTIVE, THERMAL_TRIP_PASSIVE, 
	THERMAL_TRIP_HOT, THERMAL_TRIP_CRITICAL}; //thermal:thermal_zone_trip

typedef unsigned long long dma_addr_t; //xhci-hcd:xhci_address_ctx

typedef unsigned int dev_t; //random:add_disk_randomness
typedef unsigned long sector_t; //block:block_touch_buffer
typedef unsigned long ino_t; //jbd2:jbd2_submit_inode_data
typedef unsigned int tid_t; //jbd2:jbd2_update_log_tail
typedef unsigned int gid_t; //ext4:ext4_other_inode_update_time
typedef long long loff_t; //ext4:ext4_begin_ordered_truncate
typedef unsigned int ext4_lblk_t; //ext4:ext4_ext_convert_to_initialized_enter
typedef unsigned long long ext4_fsblk_t; //ext4:ext4_ext_convert_to_initialized_enter
typedef void * fl_owner_t; //filelock:break_lease_noblock
enum migrate_mode {MIGRATE_ASYNC, MIGRATE_SYNC_LIGHT, MIGRATE_SYNC}; //migrate:mm_migrate_pages

typedef unsigned int gfp_t; //compaction:mm_compaction_try_to_compact_pages
typedef unsigned int isolate_mode_t; //vmscan:mm_vmscan_lru_isolate

enum pm_qos_req_action {PM_QOS_ADD_REQ, PM_QOS_UPDATE_REQ, 
	PM_QOS_REMOVE_REQ}; //power:pm_qos_update_target

enum dev_pm_qos_req_type {DEV_PM_QOS_RESUME_LATENCY = 1, 
	DEV_PM_QOS_LATENCY_TOLERANCE, DEV_PM_QOS_FLAGS}; //power:dev_pm_qos_add_request

typedef unsigned long long resource_size_t; //ftrace:mmiotrace_rw
typedef int clockid_t; //timer:hrtimer_init
enum hrtimer_mode {HRTIMER_MODE_ABS, HRTIMER_MODE_REL, 
	HRTIMER_MODE_PINNED, HRTIMER_MODE_ABS_PINNED = 2, HRTIMER_MODE_REL_PINNED}; //timer:hrtimer_init

typedef unsigned long long cputime_t; //timer:itimer_state
enum paravirt_lazy_mode {PARAVIRT_LAZY_NONE, PARAVIRT_LAZY_MMU, 
	PARAVIRT_LAZY_CPU}; //xen:xen_mc_batch

typedef void * xen_mc_callback_fn_t; //xen:xen_mc_callback
enum xen_mc_flush_reason {XEN_MC_FL_NONE, XEN_MC_FL_BATCH, 
	XEN_MC_FL_ARGS, XEN_MC_FL_CALLBACK}; //xen:xen_mc_flush_reason

enum xen_mc_extend_args {XEN_MC_XE_OK, XEN_MC_XE_BAD_OP, 
	XEN_MC_XE_NO_SPACE}; //xen:xen_mc_extend_args

typedef unsigned long pteval_t; //xen:xen_mmu_set_pte
typedef struct { pteval_t pte; } pte_t; //xen:xen_mmu_set_pte

typedef unsigned long pmdval_t; //xen:xen_mmu_set_pmd
typedef struct { pmdval_t pmd; } pmd_t; //xen:xen_mmu_set_pmd

typedef unsigned long pudval_t; //xen:xen_mmu_set_pud
typedef struct { pudval_t pud; } pud_t; //xen:xen_mmu_set_pud

typedef unsigned long pgdval_t; //xen:xen_mmu_set_pgd
typedef struct { pgdval_t pgd; } pgd_t; //xen:xen_mmu_set_pgd

typedef struct {
	u16 offset_low;
	u16 segment;
	unsigned int ist : 3;
	unsigned int zero0 : 5;
	unsigned int type : 5;
	unsigned int dpl : 2;
	unsigned int p : 1;
	u16 offset_middle;
	u32 offset_high;
	u32 zero1;
} gate_desc; //xen:xen_cpu_write_idt_entry

typedef unsigned long blkcnt_t; //btrfs:btrfs_inode_new
typedef unsigned long long xfs_ino_t; //xfs
typedef unsigned int xfs_agnumber_t;
typedef int xfs_extnum_t;
typedef unsigned long long xfs_fileoff_t;
typedef unsigned long long xfs_fsblock_t;
typedef unsigned long long xfs_filblks_t;
typedef int xfs_exntst_t; //ENUM
typedef long long xfs_daddr_t;
typedef unsigned int xfs_extlen_t;
typedef long long xfs_lsn_t;

typedef unsigned int uint;
typedef long long xfs_fsize_t;
typedef long long xfs_off_t;
typedef unsigned int xfs_agblock_t;
typedef unsigned int xfs_dahash_t;
typedef unsigned int xlog_tid_t;
]]

local perf_sample_struct_fmt = [[
struct %s {
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
    struct %s *raw;
  };
  struct ip_callchain *_callchain;
  struct branch_stack *branch_stack;
  struct regs_dump  user_regs;
  struct regs_dump  intr_regs;
  struct stack_dump user_stack;
  struct sample_read read;

  const char *name; /* event name added for e.name */
  struct perf_handle *handle; /* handle of this sample event */
  union perf_event *event; /*original event pointer*/
};]]


--define "struct perf_sample" for events without format, like cpu-clock. 
ffi.cdef(string.format(perf_sample_struct_fmt, "perf_sample", "{}"))
local ctype_perf_sample = ffi.typeof("struct perf_sample *")

perf.parse_ip= function(sample, ip)
  local cast_sample = ffi.cast(ctype_perf_sample, sample)
  local sym = C.machine__parse_ip(sample.handle.machine, cast_sample, ip)
  return ffi.string(sym)
end

local ct_metatable_sample = {
  __index = function(sample, key)
    if key == "callchain" then
      local cast_sample = ffi.cast(ctype_perf_sample, sample)
      -- use thread__resolve_callchain?
      local callchain = C.perf_callchain_backtrace(sample.event, cast_sample,
                                                   sample.handle.machine)
      if callchain == nil then
        return nil
      end
      return ffi.string(callchain)
    else
      print(string.format("error: struct perf_sample don't have field \"%s\"\n",
            name))
      os.exit(-1)
    end
  end
}

ffi.metatype("struct perf_sample", ct_metatable_sample)

local ctype_fmt_tbl = {}

local ct_metatable_raw = {
  -- Note that __index metamethod is only used for read dynamic field.
  -- there have some issue when save ctype as table key, so use string as key
  __index = function(raw_cdata, name)
    local ctype = ffi.typeof(raw_cdata)
    local tp_fmt = ctype_fmt_tbl[tostring(ctype)]

    local ptr = C.perf_evsel__rawptr_v2(tp_fmt, raw_cdata, name)
    local intval = ffi.cast('intptr_t', ptr)
    if tonumber(intval) == 0 then
      print(string.format("error: %s don't have field \"%s\"\n",
            tostring(ctype), name))
      os.exit(-1)
    end
    return ptr
  end
}

local function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match);
  end
  return result;
end

--TODO: check correctness of ctype define
local function load_event_ctype(tp_fmt, str)
  local e = split(str, ":")
  local subsys = e[1]
  local event = e[2]
  local sub1 = string.gsub(subsys, "-", "_") --for subsystem: xhci-hcd
  local ev1 = string.gsub(event, "-", "_")
  local event_struct_name = "tracepoint_" .. sub1 .. "_" .. ev1 .. "_struct"
  local event_struct_def = "struct " .. event_struct_name .. " {\n"

  local epath = string.format("/sys/kernel/debug/tracing/events/%s/%s/format",
                              subsys, event)

  local is_syscall = string.match(str, "syscalls:*") ~= nil
  local field_num = 0;

  for line in io.lines(epath) do
    local field_line = string.match(line, "field:([^;]*)")
    if field_line ~= nil then
      field_num = field_num + 1
  
      local arg_name
      for s in (field_line .. " "):gmatch("(.-) ") do
        arg_name = s
      end

      local _, dynamic_field_name =
            string.match(field_line, "__data_loc ([^ ]*) (.*)")
      if dynamic_field_name then
        event_struct_def = event_struct_def .. "  int __dynamic_field_" ..
                           arg_name .. ";\n"
      else
        if is_syscall == true and field_num > 5 then
                event_struct_def = event_struct_def .. "  unsigned long " ..
                                                    arg_name .. ";\n"
        else
          event_struct_def = event_struct_def .. "  " .. field_line .. ";\n"
        end
      end
    end
  end

  event_struct_def = event_struct_def .. "};"

  --print(event_struct_def)
  ffi.cdef(event_struct_def)

  local ctype = ffi.typeof("struct " .. event_struct_name .. "*")
  ctype_fmt_tbl[tostring(ctype)] = tp_fmt

  ffi.metatype("struct " .. event_struct_name, ct_metatable_raw)

  local sample_struct_name = "perf_sample_" .. event_struct_name
  local perf_sample_struct_def = string.format(perf_sample_struct_fmt,
                                               sample_struct_name,
                                               event_struct_name)
  ffi.cdef(perf_sample_struct_def)
  --print(perf_sample_struct_def)

  ffi.metatype("struct " .. sample_struct_name, ct_metatable_sample)

  return ffi.typeof("struct " .. sample_struct_name .. " *")
end

---------------------------------------------------------------

local io_write = io.write
perf.print = function(e)
  local ctype = ffi.typeof(e.raw)
  local tp_fmt = ctype_fmt_tbl[tostring(ctype)]

  io_write(tonumber(e.pid))
  io_write(" ")
  io_write("[" .. tonumber(e.cpu) .. "] ")
  io_write(tonumber(e.time))
  io_write(": ")
  io_write(ffi.string(e.name))
  io_write(": ")
  C.event_format__print(tp_fmt, e.cpu, e.raw, e.raw_size)
  io_write("\n")
end

local stats = {}
stats.samples_num = 0
stats.wakeup_num = 0
stats.lost_num = 0
stats.flush_num = 0
stats.callback_sum_time = 0

local idx_ret = ffi.new("int [1]")
local perf_sample = ffi.new("struct perf_sample")
local evsel_ret = ffi.new("struct perf_evsel *[1]")

local function mmap_read_consume(handle, evlist, callback, max_nr_read)
  local nr_read = 0
  local ret

  perf_sample.handle = handle

  while nr_read < max_nr_read do
    nr_read = nr_read + 1

    -- TODO: speed up this function
    local event = C.perf_evlist__mmap_read_top(evlist, idx_ret)
    if event == nil then
      return
    end

    local idx = idx_ret[0]

    ret = C.perf_evlist__parse_sample_v2(evlist, event, perf_sample, evsel_ret)
    if ret ~= 0 then
      print("perf_evlist__parse_sample failed")
      C.perf_evlist__mmap_consume(evlist, idx)
      return
    end

    local evsel = evsel_ret[0]

    if event.header.type == C.PERF_RECORD_SAMPLE then
      stats.samples_num = stats.samples_num + 1

      perf_sample.name = C.perf_evsel__name(evsel)
      perf_sample.event = event --save it for metatable use

      local tp_fmt = C.perf_evsel__tp_fmt(evsel)
      if tp_fmt ~= nil then
        --TODO: use ref is more faster than lua table?
        local ctype_ref = C.perf_evsel__get_ctype_ref(evsel)
        local ctype = shark_get_ref(ctype_ref)
        local sample_event = ffi_cast(ctype, perf_sample)
        callback(sample_event)
      else
        callback(perf_sample)
      end
    else
      if event.header.type == C.PERF_RECORD_LOST then
        stats.lost_num = stats.lost_num + tonumber(event.lost.lost)
      end
      C.machine__process_event(handle.machine, event, perf_sample)
    end

    C.perf_evlist__mmap_consume(evlist, idx)
  end
end

local function open_perf_event(str, config, callback)
  local evlist, err
  local opts = ffi.new("struct record_opts")
  opts.sample_time = true
  opts.mmap_pages = config.mmap_pages
  opts.user_freq = -1
  opts.user_interval = -1
  opts.freq = 4000
  opts.no_buffering = config.no_buffering
  opts.raw_samples = true
  opts.target.system_wide = true
  opts.target.uses_mmap = true
  opts.target.default_per_cpu = true
  opts.target.pid = config.target_pid
  opts.target.tid = config.target_tid
  opts.target.cpu_list = config.target_cpu_list

  if config.callchain_k or config.callchain_u then
    C.perf_callchain_enable()
  end

  evlist = C.perf_evlist__new()

  err = C.parse_events(evlist, str)
  if err ~= 0 then
    print(string.format("parse events [%s] failed!", str))
    return nil
  end

  err = C.target__validate(opts.target)
  if err ~= 0 then
    print("target validate failed!")
    return nil
  end

  err = C.target__parse_uid(opts.target)
  if err ~= 0 then
    print("target parse uid failed!")
    return nil
  end

  C.perf_evlist__create_maps(evlist, opts.target)
  if err < 0 then
    print("perf_evlist__create_maps failed!")
    return nil
  end

  C.record_opts__config(opts)

  C.perf_evlist__config(evlist, opts)

  C.perf_evlist_foreach(evlist, function(evlist, evsel, _)
    C.perf_evsel__set_sample_id(evsel, true);
    C.__perf_evsel__set_sample_bit(evsel, C.PERF_SAMPLE_TIME);
    C.__perf_evsel__set_sample_bit(evsel, C.PERF_SAMPLE_CPU);
    C.__perf_evsel__set_sample_bit(evsel, C.PERF_SAMPLE_RAW);
    C.__perf_evsel__set_sample_bit(evsel, C.PERF_SAMPLE_STREAM_ID);
    C.__perf_evsel__set_sample_bit(evsel, C.PERF_SAMPLE_IDENTIFIER);
 
    C.perf_evsel__set_callchain(evsel, config.callchain_k, config.callchain_u)

    local tp_fmt = C.perf_evsel__tp_fmt(evsel)
    if tp_fmt == nil then
      --it's not tracepoint
      return
    end
    local event_name = C.perf_evsel__name(evsel)
    local ctype = load_event_ctype(tp_fmt, ffi.string(event_name))
    local ref = shark.lua_ref(ctype)
    C.perf_evsel__set_ctype_ref(evsel, ref)
  end, nil)

  err = C.perf_evlist__open(evlist)
  if err < 0 then
    print("perf_evlist__open failed!")
    return nil
  end

  if config.filter ~= nil then
    err = C.perf_evlist__set_filter(evlist, config.filter)
    if err ~= 0 then
      print("perf_evlist__set_filter failed!")
      return nil
    end
  end

  err = C.perf_evlist__mmap(evlist, opts.mmap_pages, false)
  if err < 0 then
    print("perf_evlist__mmap failed!")
    return nil
  end

  local session = C.perf_session__init(evlist, opts)
  if session == nil then
     print("perf_session__new failed")
     return nil
  end

  handle = ffi.new("struct perf_handle")
  handle.evlist = evlist
  handle.session = session
  handle.machine = C.perf_session__get_machine(session)
 
  local nret = ffi.new("int [1]")
  local pollfd = C.perf_evlist_pollfd(evlist, nret)
  local nr = nret[0]

  local function poll_callback()
    stats.wakeup_num = stats.wakeup_num + 1

    local begin = gettimeofday()
    mmap_read_consume(handle, evlist, callback,
                      perf_default_config.read_events_rate)
    stats.callback_sum_time = stats.callback_sum_time + gettimeofday() - begin
  end

  for i = 0, nr-1 do
    --lua based callback
    uv.poll_start(uv.new_poll(pollfd[i].fd), "r", poll_callback)
  end

  --Do not enable events in here, we should enable events after all
  --events be added in libuv, we use a timer callback to enable events.

  return handle
end

local perf_handle_tbl = {}

perf.on = function(str, ...) --(str, [opts], callback)
  local nargs = select('#', ...)
  local args = {...}
  local config
  local cb

  if nargs == 1 then
    config = perf.default_config
    cb = args[1]
  elseif nargs == 2 then
    local newconfig = ffi.new("struct shark_perf_config")
    ffi.copy(newconfig, perf.default_config, ffi.sizeof(newconfig))

    local user_config = args[1]
    for k, v in pairs(user_config) do
      newconfig[k] = v
    end
    config = newconfig
    cb = args[2]
  else
    print("wrong arugments for perf.on")
    os.exit(-1)
  end

  local handle = open_perf_event(str, config, cb)
  if handle == nil then
    os.exit(-1)
  end

  perf_handle_tbl[handle] = cb

  -- force enable perf events after epoll_ctrl fd added
  -- this can prevent mmap buffer flush full before start polling
  set_timeout(function()
      set_timeout(function()
        perf.enable(handle.evlist)
      end, 1)
  end, 0)

  return evlist
end

shark.add_end_notify(function()
  -- disable all evlists
  for handle, callback in pairs(perf_handle_tbl) do
    C.perf_evlist__disable(handle.evlist)

    local prev_samples_num = stats.samples_num
    mmap_read_consume(handle, handle.evlist, callback, 4294967295ULL)
    stats.flush_num = stats.flush_num + stats.samples_num - prev_samples_num
  end

  if shark.verbose then
    print(string.format("shark: Woken up %d times, flushed %d events, losted %d events, total %d sample events, avg event process time is %d usec",
                        stats.wakeup_num, stats.flush_num,
                        stats.lost_num, stats.samples_num,
                        stats.callback_sum_time / stats.samples_num))
  end
end)

return perf
