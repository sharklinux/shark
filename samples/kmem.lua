
local perf = require("perf")

perf.on("kmem:*", function(e)
  perf.print(e)
end)

