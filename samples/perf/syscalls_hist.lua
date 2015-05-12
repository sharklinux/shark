--[[
This script print histogram of called syscalls numbers

Usage:
  shark syscalls_hist.lua
--]]

local perf = require("perf")
local ffi_string = require("ffi").string

local syscalls = {}
setmetatable(syscalls, {__index = function() return 0 end})

perf.on("syscalls:*", function(e)
  local name = ffi_string(e.name)
  syscalls[name] = syscalls[name] + 1
end)

shark.on_end(function()
  print_hist(syscalls)
end)
