--[[
/*
 * sharkcloud module
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

local function shark_read_id()
  local shark_id = nil
  local shark_config_file = io.open("/etc/shark_config", "rb")
  if shark_config_file then
    shark_id = shark_config_file:read("*all")
    shark_config_file:close()
  end
  return shark_id
end

local function shark_write_id(id)
  local shark_id = nil
  local shark_config_file = io.open("/etc/shark_config", "w")
  if shark_config_file then
    shark_config_file:write(id)
    shark_config_file:close()
  end
end

local http = require "socket.http"
local ltn12 = require "ltn12"

http.TIMEOUT = 5

--TODO: luasocket don't support persistent connections
local function sharkly_gist_post(content_type, seq, content)
  local request_body = content
  local response_body = {}

  local url
  local shark_id = shark_read_id()
  if shark_id and shark_id ~= ""  then
    url = "http://www.sharkly.io/gist/" .. shark_id .. "/" .. content_type
  else
    url = "http://www.sharkly.io/gist/null/" .. content_type
  end

  if seq ~= nil then
    url = url .. "/" .. seq
  end

  http.request{
    url = url,
    method = "POST",
    headers = {
      ["Content-Length"] = string.len(request_body)
    },
    source = ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body)
  }

  if response_body[1] then
    local pattern = "(.*)/" .. content_type .. "/()"
    local id = string.match(response_body[1], pattern)
    if shark_id and shark_id ~= "" and shark_id ~= id then
      print(string.format("error: return id(%s) is not equal with shark_id(%s)",
                           id, shark_id))
      os.exit(-1)
    else
      shark_write_id(id)
    end

    return response_body[1]
  end

  return nil
end

function _M.senddata(content_type, data)
  local content = ""

  if content_type == "flamegraph" then
    for k, v in pairs(data) do
      if k ~= "" then
        content = content .. k .. tostring(v) .. "\n"
      end
    end

    local res = sharkly_gist_post("flamegraph", nil, content)
    print("Open " .. content_type .. " at: http://www.sharkly.io/gist/" .. res)
    return
  end

  if content_type == "heatmap" then
    local file = io.open("/tmp/heatmap.txt", "w+")

    for _, v in pairs(data) do
      file:write(v, "\n")
    end
    file:close()

    file = io.open("/tmp/heatmap.txt", "rb")
    content = file:read("*all")
    file:close()

    local res = sharkly_gist_post("heatmap", nil, content)
    print("Open " .. content_type .. " at: http://www.sharkly.io/gist/" .. res)
    return
  end
end

function _M.senddata_start(content_type)
    local res = sharkly_gist_post(content_type, nil, "")
    local seq = string.match(res, "heatmap/(.*).svg")
    print("Open " .. content_type .. " at: http://www.sharkly.io/gist/" .. res)
    return {content_type = content_type, seq = seq}
end

function _M.senddata_append(session, data)
  if session.content_type == "heatmap" then
    local file = io.open("/tmp/heatmap.txt", "w+")

    for _, v in pairs(data) do
      file:write(v, "\n")
    end
    file:close()

    file = io.open("/tmp/heatmap.txt", "rb")
    local content = file:read("*all")
    file:close()

    sharkly_gist_post(session.content_type, session.seq, content)
  end
end

return _M
