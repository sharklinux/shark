local perf = require("perf")

perf.on("cpu-clock", {callchain = 1}, function(e)
  print(e.callchain.nr)
end)

shark.on_end(function()
end)
