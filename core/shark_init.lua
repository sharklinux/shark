--[[
/*
 * shark_init.lua
 *
 * Copyright (C) 2015 Shark Authors. All Rights Reserved.
 *
 * shark is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * shark is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */
--]]

---------------------------------------------------------------

local uv = require("uv")
local ffi = require("ffi")

-- microsecond precision
ffi.cdef[[
typedef long time_t;
 
typedef struct timeval {
	time_t tv_sec;
	time_t tv_usec;
} timeval;
 
int gettimeofday(struct timeval *t, void *tzp);
]]

local gettimeofday_struct = ffi.new("timeval")

shark.gettimeofday = function()
  ffi.C.gettimeofday(gettimeofday_struct, nil)
  return tonumber(gettimeofday_struct.tv_sec) * 1000000 +
         tonumber(gettimeofday_struct.tv_usec)
end

set_interval = function(callback, interval)
  local timer = uv.new_timer()
  local function ontimeout()
    callback(timer)
  end
  uv.timer_start(timer, interval, interval, ontimeout)
  return timer
end

set_timeout = function(callback, timeout)
  local timer = uv.new_timer()
  local function ontimeout()
    uv.timer_stop(timer)
    uv.close(timer)
    callback(timer)
  end
  uv.timer_start(timer, timeout, 0, ontimeout)
  return timer
end

local shark_end_notify_list = {}

shark.add_end_notify = function(callback)
  table.insert(shark_end_notify_list, callback)
end

shark.on_end = function(callback)
  local function call_end()
    --notify registered on_end function
    for _, cb in pairs(shark_end_notify_list) do
      cb()
    end

    callback()
    os.exit(0)
  end
  local sigint = uv.new_signal()
  uv.signal_start(sigint, "sigint", function()
    call_end()
  end)

  local sigterm = uv.new_signal()
  uv.signal_start(sigterm, "sigterm", function()
    call_end()
  end)
end

---------------------------------------------------------------

local function fill_line(n, max)
  for i = 1, max do
    if i < n then
      io.write("*")
    else
      io.write(" ")
    end
  end
end

-- standard histogram print function
-- all type keys and number value
local __print_hist = function(t, cmp_func, mode)
  local sorted_tbl = {}
  setmetatable(sorted_tbl, {__index = function() return 0 end })
  local stdSum = 0, 0
  local array = {}

  for k, v in pairs(t) do
    stdSum = stdSum + v
    array[#array + 1] = {k = k, v = v}
  end

  table.sort(array, function(v1, v2)
    if cmp_func ~= nil then
      return cmp_func(v1.v, v2.v)
    else
      if v1.v > v2.v then return true end
    end
  end)

  if mode == "default" then
    io.write("                          value  ---------- Distribution ----------  count\n")
  end

  for k, v in pairs(array) do
    if mode == "default" then
      io.write(string.format("%33s |", tostring(v.k)))
      fill_line(v.v * 34 / stdSum, 34)
      io.write(string.format("| %d\n", v.v))
    else
      io.write(string.format("%s\n%d\n", tostring(v.k), v.v))
    end
  end
end

function print_hist(t, cmp_func)
  __print_hist(t, cmp_func, "default")
end


function print_hist_raw(t, cmp_func)
  __print_hist(t, cmp_func, "raw")
end

shark.print_hist = print_hist
shark.print_hist_raw = print_hist_raw

---------------------------------------------------------------

-- ansiterminal global table

ansiterminal = {}

local colors = {
  -- attributes
  reset = 0,
  clear = 0,
  bright = 1,
  dim = 2,
  underscore = 4,
  blink = 5,
  reverse = 7,
  hidden = 8,

  -- foreground
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37,

  -- background
  onblack = 40,
  onred = 41,
  ongreen = 42,
  onyellow = 43,
  onblue = 44,
  onmagenta = 45,
  oncyan = 46,
  onwhite = 47,
}

local schar = string.char

local function makecolor(name, value)
  ansiterminal[name] = schar(27) .. '[' .. tostring(value) .. 'm'
end

for k, v in pairs(colors) do
  makecolor(k, v)
end

function ansiterminal.clearscreen()
  io.write(schar(27) .. '[' .. "2J")
end

function ansiterminal.moveto(x, y)
  io.write(schar(27) .. '[' .. tostring(x) .. ";" .. tostring(y) .. 'H')
end

function ansiterminal.moveup(n)
  io.write(schar(27) .. '[' .. tostring(n) .. 'F')
end

function ansiterminal.clearline()
  io.write(schar(27) .. '[' .. "2K")
end

function ansiterminal.hidecursor()
  io.write(schar(27) .. '[' .. "?25l")
end

function ansiterminal.showcursor()
  io.write(schar(27) .. '[' .. "?25h")
end

function ansiterminal.setbgcol(color)
  io.write(schar(27) .. '[' .. "48;5;" .. color .. "m")
end

