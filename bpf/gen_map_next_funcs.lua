--[[
/*
 * This file is part of shark
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

local file = io.open("bpf_map_next_func.h", "w")
io.output(file)


local types = {}
types[0] = "u8"
types[1] = "u16"
types[2] = "u32"
types[3] = "u64"
types[4] = "string"
types[5] = "userdata"
types[6] = "max"

io.write("typedef int (*MAP_NEXT_FUNC)(lua_State *ls);\n\n")

local function get_key(key_type)
  if key_type == "u8" or key_type == "u16" or key_type == "u32" or
     key_type == "u64" then
    return "key = (" .. key_type .. ")lua_tonumber(ls, -1);"
  end

  if key_type == "string" then
    return "if (lua_isnil(ls, -1))\n" ..
                "\t\tkey[0] = '\\0';\n" ..
        "\telse {\n" ..
		"\t\tconst char *str = lua_tostring(ls, -1);\n" ..
		"\t\tmemcpy(&key, str, strlen(str));//TODO\n\t}\n"
  end

  if key_type == "userdata" then
    return "//todo"
  end
end

local function push_nextkey(key_type)
  if key_type == "u8" or key_type == "u16" or key_type == "u32" or
     key_type == "u64" then
    return "lua_pushnumber(ls, nextkey);"
  end

  if key_type == "string" then
    return "lua_pushstring(ls, nextkey);"
  end

  if key_type == "userdata" then
    return "//todo"
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
  local str = "static int map_next_" .. types[i] .. "_func(lua_State *ls) {\n"
  io.write(str)
  --io.write("\tprintf(\"invoke map next func: %s\\n\", __FUNCTION__);\n\n")

  local str = "\t" .. get_raw_type("key", types[i]) .. "\n" ..
        "\t" .. get_raw_type("nextkey", types[i]) .. "\n\n" ..
        "\tGCtab *t = tabV(ls->top - 2);\n" ..
        "\tint fd = t->data1;\n" ..
        "\tstruct bpf_map_def *map = t->data2;\n\n" ..
        "\t" .. get_key(types[i]) .. "\n"..
        "\tif (bpf_get_next_key(fd, &key, &nextkey) == 0) {\n" ..
        "\t\t" .. push_nextkey(types[i]) .. "\n" ..
        "\t\treturn 1;\n" ..
        "\t} else\n" ..
        "\t\treturn 0;\n"

    io.write(str)
    io.write("}\n\n")
end

io.write("static MAP_NEXT_FUNC map_next_func_array[MAP_ELEM_TYPE_max] = {\n")

for i = 0, 5 do
    io.write("\tmap_next_" .. types[i] .. "_func,\n");
end

io.write("};")

io.close(file)

