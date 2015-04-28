--[[
/*
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

local file = io.open("bpf_map_index_func.h", "w")
io.output(file)


local types = {}
types[0] = "u8"
types[1] = "u16"
types[2] = "u32"
types[3] = "u64"
types[4] = "string"
types[5] = "userdata"
types[6] = "max"

io.write("enum {\n")
for i = 0, 6 do
  io.write("\tMAP_ELEM_TYPE_" .. types[i] .. ",\n")
end
io.write("};\n\n")

io.write("typedef int (*MAP_INDEX_FUNC)(lua_State *ls, int fd, struct bpf_map_def *map);\n\n")


local function get_key(key_type)
  if key_type == "u8" or key_type == "u16" or key_type == "u32" or
     key_type == "u64" then
    return "key = (" .. key_type .. ")lua_tonumber(ls, -1);"
  end

  if key_type == "string" then
    return "const char *str = lua_tostring(ls, -1);\n" ..
	   "\tmemcpy(&key, str, strlen(str));"
  end

  if key_type == "userdata" then
    return "//todo"
  end
end

local function get_val(val_type)
  if val_type == "u8" or val_type == "u16" or val_type == "u32" or
     val_type == "u64" then
    return "lua_pushnumber(ls, val);"
  end

  if val_type == "string" then
    return "lua_pushstring(ls, val);"
  end

  if val_type == "userdata" then
    return "void *ud = lua_newuserdata(ls, map->value_size);\n" ..
           "\tmemcpy(ud, val, map->value_size);"
  end
end

local function get_raw_type(name, itype)
  if itype == "string" then
    return "char " .. name .."[1024] = {0};" -- all string decl as 1024 chars.
  elseif itype == "userdata" then
    return "u8 " .. name .."[1024] = {0};" -- all string decl as 1024 chars.
  else
    return itype .. " " .. name ..";"
  end
end

for i = 0, 5 do
  for j = 0, 5 do
    local str = "static int map_index_" .. types[i] .. "_" .. types[j] .. "_func(lua_State *ls, int fd, struct bpf_map_def *map) {\n"
    io.write(str)
    --io.write("\tprintf(\"invoke map index func: %s\\n\", __FUNCTION__);\n\n")

    local str = "\t" .. get_raw_type("key", types[i]) .. "\n" ..
          "\t" .. get_raw_type("val", types[j]) .. "\n\n" ..
          "\t" .. get_key(types[i]) .. "\n"..
          "\tbpf_lookup_elem(fd, &key, &val);\n" ..
          "\t" .. get_val(types[j]) .. "\n" ..
          "\treturn 1;\n"
          
    io.write(str)
    io.write("}\n\n")
  end
end

io.write("static MAP_INDEX_FUNC map_index_func_array[MAP_ELEM_TYPE_max][MAP_ELEM_TYPE_max] = {\n")

for i = 0, 5 do
  for j = 0, 5 do
    io.write("\tmap_index_" .. types[i] .. "_" .. types[j] .. "_func,\n");
  end
end

io.write("};")

io.close(file)

