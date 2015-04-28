

local kernel = {}

kernel.sysctl = function(str)
  local file = io.popen("sysctl -n " .. str)
  print(io.read(file))
  io.close(file)
end

package.preload["kernel"] = function()
  return kernel
end
