--[[
Usage:
  shark sched_print.lua
--]]

local perf = require("perf")

perf.on("sched:*", function(e)
  perf.print(e)
end)

