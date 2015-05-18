local perf = require "perf"
local sharkcloud = require "sharkcloud"

local profile = {}
setmetatable(profile, {__index = function() return 0 end})

perf.on("cpu-clock", {callchain_k = 1}, function(e)
  profile[e.callchain] = profile[e.callchain] + 1
end)

shark.on_end(function()
  sharkcloud.senddata("flamegraph", profile)
end)
