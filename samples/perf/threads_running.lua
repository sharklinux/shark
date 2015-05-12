--[[
This script print histogram of threads execution time

Usage:
  shark threads_running.lua
--]]

local perf = require("perf")
local ffi = require("ffi")

local sched_time_tbl = {}
setmetatable(sched_time_tbl, {__index = function() return 0 end})

local last_sched_tbl = {}

perf.on("sched:sched_switch", function(e)
  local prev_comm = ffi.string(e.raw.prev_comm)
  local next_comm = ffi.string(e.raw.next_comm)
  local now = e.time

  if last_sched_tbl[prev_comm] ~= nil then
    local running_time = tonumber(now - last_sched_tbl[prev_comm])
    last_sched_tbl[prev_comm] = nil
    sched_time_tbl[prev_comm] = sched_time_tbl[prev_comm] + running_time/1000
  end

  last_sched_tbl[next_comm] = now
end)

shark.on_end(function()
  print_hist(sched_time_tbl)
end)

