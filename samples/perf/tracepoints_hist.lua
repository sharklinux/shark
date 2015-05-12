--[[
This script print histogram of called tracepoints numbers

Some events don't be set because perf don't support it:
ftrace:*, irq_vectors:irq_work_exit

Usage:
  shark tracepoints_hist.lua
--]]

local perf = require("perf")
local ffi = require("ffi")

local tp_tbl = {}
setmetatable(tp_tbl, {__index = function() return 0 end})

perf.on("block:*, compaction:*, context_tracking:*, exceptions:*, ext4:*, fence:*, filelock:*, filemap:*, gpio:*, i2c:*, iommu:*, irq:*, jbd2:*, kmem:*, mce:*, migrate:*, module:*, napi:*, net:*, nmi:*, oom:*, pagemap:*, power:*, printk:*, random:*, ras:*, raw_syscalls:*, rcu:*, regmap:*, regulator:*, rpm:*, sched:*, scsi:*, signal:*, skb:*, sock:*, spi:*, swiotlb:*, syscalls:*, task:*, thermal:*, timer:*, tlb:*, udp:*, vmscan:*, vsyscall:*, workqueue:*, writeback:*, xen:*, xhci-hcd:*", function(e)
  local name = ffi.string(e.name)
  tp_tbl[name] = tp_tbl[name] + 1
end)

set_interval(function()
  print("------------------------------")
end, 1000)

shark.on_end(function()
  print_hist(tp_tbl)
end)

