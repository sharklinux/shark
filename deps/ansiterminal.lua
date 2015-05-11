--[[
/*
 * ansiterminal module
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

local _M = {}

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

function _M.clearscreen()
  io.write(schar(27) .. '[' .. "2J")
end

function _M.moveto(x, y)
  io.write(schar(27) .. '[' .. tostring(x) .. ";" .. tostring(y) .. 'H')
end

function _M.moveup(n)
  io.write(schar(27) .. '[' .. tostring(n) .. 'F')
end

function _M.clearline()
  io.write(schar(27) .. '[' .. "2K")
end

function _M.hidecursor()
  io.write(schar(27) .. '[' .. "?25l")
end

function _M.showcursor()
  io.write(schar(27) .. '[' .. "?25h")
end

function _M.setbgcol(color)
  io.write(schar(27) .. '[' .. "48;5;" .. color .. "m")
end

return _M
