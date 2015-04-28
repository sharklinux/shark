--[[
Usage:
  shark sched_print.lua
--]]

local perf = require("perf")
local ffi = require("ffi")

perf.on("sched:*", function(e)
  perf.print(e)
end)

