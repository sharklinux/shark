--[[
/*
 * bpf.lua
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

local ffi = require("ffi")
local C = ffi.C

local bpf = {}

bpf.cargs_extra = ""

---------------------------------------------------------------

bpf.cargs_add = function(s)
  bpf.cargs_extra = s
end

---------------------------------------------------------------

ffi.cdef[[
int load_bpf_file(const char *path);
]]

local function load_bpf_file(path)
  local ret = C.load_bpf_file(path)
  if tonumber(ret) ~= 0 then
    os.exit(-1)
  end
end

local function run_llc_bpf(bc_file, bpfobj_file)
  os.execute("llc-bpf -march=bpf -filetype=obj -o " ..
              bpfobj_file .. " " .. bc_file)
end

---------------------------------------------------------------
local function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match);
  end
  return result;
end

local basic_type_tbl = {
  "char", "u8", "short", "u16", "int", "u32", "long", "long long", "u64"
}

local function get_real_type(typestr)
  for _, v in pairs(basic_type_tbl) do
    if v == typestr then
      return v
    end
  end

  return "cdata"
end

local function process_type(typestr0)
  local typestr, size, size

  typestr, size = string.match(typestr0, "(.*) %[(.*)%]")
  if typestr ~= nil and size ~= nil then
    sizestr = "sizeof("..typestr .. ") * "..size
    typestr = typestr
    if typestr == "char" then
      typestr = "string"
    end
  else
    typestr, size = string.match(typestr0, "(.*)%[(.*)%]")
    if typestr ~= nil and size ~= nil then
      sizestr = "sizeof("..typestr .. ") * "..size
      typestr = typestr
      if typestr == "char" then
        typestr = "string"
      end
    else
      sizestr = "sizeof("..typestr0..")"
      typestr = get_real_type(typestr0)
    end
  end

  return typestr, sizestr
end

local function gen_map_decl(map_type, key_type, val_type, entries, name)
  local key_typestr, key_sizestr = process_type(key_type)
  local val_typestr, val_sizestr = process_type(val_type)

  if not entries then
    entries = 1024;
  end

  local str = string.format("struct bpf_map_def SEC(\"maps\") %s = {\n" ..
                            "\t.name = \"%s\",                 \n" ..
                            "\t.key_type = \"%s\",             \n" ..
                            "\t.val_type = \"%s\",             \n" ..
                            "\t.type = BPF_MAP_TYPE_%s,        \n" ..
                            "\t.key_size = %s,                 \n" ..
                            "\t.value_size = %s,               \n" ..
                            "\t.max_entries = %d,              \n};\n",
        name, name, key_typestr, val_typestr, map_type, key_sizestr,
        val_sizestr, entries)
  io.write(str)
end

local function translate_cdef(s)
  local n = split(s, '\n')
  for _, line in pairs(n) do
    local key_type, val_type, entries, name
    local match = false

    key_type, val_type, name = string.match(line,
             "bpf_map_hash<([^,]*), ([^,]*)> (.*);")
    if key_type and val_type and name then
      gen_map_decl("HASH", key_type, val_type, nil, name)
      match = true
    end

    key_type, val_type, entries, name = string.match(line,
             "bpf_map_hash<([^,]*), ([^,]*), (%d+)> (.*);")
    if key_type and val_type and entries and name then
      gen_map_decl("HASH", key_type, val_type, entries, name)
      match = true
    end

    key_type, val_type, name = string.match(line,
             "bpf_map_array<([^,]*), ([^,]*)> (.*);")
    if key_type and val_type and name then
      gen_map_decl("ARRAY", key_type, val_type, nil, name)
      match = true
    end

    key_type, val_type, entries, name = string.match(line,
             "bpf_map_array<([^,]*), ([^,]*), (%d+)> (.*);")
    if key_type and val_type and entries and name then
      gen_map_decl("ARRAY", key_type, val_type, entries, name)
      match = true
    end

    if not match then
      io.write(line, "\n")
    end
  end

  io.write("\nchar _license[] SEC(\"license\") = \"GPL\";\n")
  io.write("\n#include <linux/version.h>\n")
  io.write("\nu32 _version SEC(\"version\") = LINUX_VERSION_CODE;\n")
end

local function compile(srcfile, objfile)
   local f = io.popen("uname -r", "r")
   local release = f:read()
   local linuxinc = string.format("/lib/modules/%s/build/", release)
   local bpfinc = "bpf/libbpf"

   local clang_cmd = string.format("clang -nostdinc -isystem /usr/lib/gcc/x86_64-linux-gnu/4.8/include -I%s -I%s/arch/x86/include -I%s/arch/x86/include/generated/uapi -I%s/arch/x86/include/generated  -I%s/include -I%s/arch/x86/include/uapi -I%s/arch/x86/include/generated/uapi -I%s/include/uapi -I%s/include/generated/uapi -include %s/include/linux/kconfig.h %s -D__KERNEL__ -Wno-unused-value -Wno-pointer-sign -O2 -emit-llvm -x c -c %s -o %s", bpfinc, linuxinc, linuxinc, linuxinc, linuxinc, linuxinc, linuxinc, linuxinc, linuxinc, linuxinc, bpf.cargs_extra, srcfile, objfile)

  os.execute(clang_cmd)
end

-- builtin cdef function
bpf.cdef = function(s)
  local file

  local srctmp = os.tmpname()
  file = io.open(srctmp, "w")
  io.output(file)
  translate_cdef(s)

  io.close(file)
  io.output(io.stdout)

  -- dump source
  local f = io.open(srctmp, "rb")
  local content = f:read("*all")
  print(content)
  f:close()

  local bctmp = os.tmpname()
  compile(srctmp, bctmp)

  local bpftmp = os.tmpname()
  run_llc_bpf(bctmp, bpftmp)

  -- pass bpf table for bpf object loading, need clear it after load done.
  _G["bpf"] = bpf
  load_bpf_file(bpftmp)

  os.remove(srctmp)
  os.remove(bctmp)
  os.remove(bpftmp)
end

---------------------------------------------------------------

bpf.print_map = function(map)
  local map = map
  for k in pairs(map) do
    print(k, map[k])
  end
end

---------------------------------------------------------------

bpf.copy_map = function(map)
  local new = {}
  local map = map
  for k in pairs(map) do
    new[k] = map[k]
  end
  return new
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

-- print histogram for bpf.var.map
-- Only support number key now.
bpf.print_hist_map = function(t)
  local histo = {}
  local stdSum, max = 0, 0

  for k in pairs(t) do
    if t[k] ~= 0 then
      local k1 = math.pow(2, math.floor(math.log(k, 2)))
      if histo[k1] == nil then histo[k1] = 0 end
      histo[k1] = histo[k1] + t[k]

      stdSum = stdSum + t[k]
      if k1 > max then max = k1 end
    end
  end

  print("        value  ------------- Distribution -------------  count")
  local k = 0
  while k <= max do
    local v = histo[k]
    if v == nil then v = 0 end

    io.write(string.format("%13d |", k))
    fill_line(v * 40 / stdSum, 40)
    io.write(string.format("| %d", v))

    print()

    if k == 0 then k = 1 else k = k * 2 end
  end
end

return bpf

