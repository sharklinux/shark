#ifndef __BPF_MAP_DEF_H
#define __BPF_MAP_DEF_H

/* a helper structure used by eBPF C program
 * to describe map attributes to elf_bpf loader
 */
struct bpf_map_def {
        char name[16];
        char key_type[16];
        char val_type[16];
        unsigned int type;
        unsigned int key_size;
        unsigned int value_size;
        unsigned int max_entries;
};

#endif
