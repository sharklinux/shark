local perf = require("perf")
local ffi = require("ffi")

perf.on("sched:sched_switch", function(e)
  local prev_comm = ffi.string(e.raw.prev_comm)
  local next_comm = ffi.string(e.raw.next_comm)
  print(prev_comm, "->", next_comm)
end)

perf.on("sched:sched_process_exec", function(e)
  print(ffi.string(e.name), "filename:", ffi.string(e.raw.filename))
end)

