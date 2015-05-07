
local perf = require("perf")
local ffi_string = require("ffi").string

local t = {}
local rec = {}

perf.on("syscalls:sys_enter_write, syscalls:sys_exit_write", function(e)
  local key = tostring(e.cpu) .. tostring(e.pid)

  if ffi_string(e.name) == "syscalls:sys_enter_write" then
    t[key] = e.time
  else
    if t[key] then
      table.insert(rec, tostring(tonumber(e.time/1000)) .. " " ..
                        tostring(tonumber((e.time - t[key])/1000)))
      t[key] = nil
    end
  end
end)

shark.on_end(function()
  shark.post("heatmap", rec)
end)

