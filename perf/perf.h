#ifndef _PERF_H
#define _PERF_H

#include <stdbool.h>
#include <linux/perf_event.h>

typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;

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


#define PERF_REGS_MAX 24  //TODO: only for x86-64

struct regs_dump {
	u64 abi;
	u64 mask;
	u64 *regs;

	/* Cached values/mask filled by first register access. */
	u64 cache_regs[PERF_REGS_MAX];
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

struct ip_callchain {
	u64 nr;
	u64 ips[0];
};

struct branch_flags {
	u64 mispred:1;
	u64 predicted:1;
	u64 in_tx:1;
	u64 abort:1;
	u64 reserved:60;
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

/* must match with perf */
struct perf_sample {
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
		void *raw;
	};
	struct ip_callchain *callchain;
	struct branch_stack *branch_stack;
	struct regs_dump  user_regs;
	struct regs_dump  intr_regs;
	struct stack_dump user_stack;
	struct sample_read read;

	/* below two fields was added by shark */
	const char *name; /* event name added for e.name */
	void *evsel;      /* evsel added for metatable */
};

int target__validate(struct target *target);
int record_opts__config(struct record_opts *opts);
union perf_event *perf_evlist__mmap_read(struct perf_evlist *evlist, int idx);
union perf_event *perf_evlist__mmap_read_top(struct perf_evlist *evlist,
					     int *idx);
int perf_evlist__parse_sample_v2(struct perf_evlist *evlist,
				 union perf_event *event,
				 struct perf_sample *sample,
				 struct perf_evsel **ret_evsel);
const char *perf_evsel__name(struct perf_evsel *evsel);
int perf_evsel__get_ctype_ref(struct perf_evsel *evsel);
#endif
