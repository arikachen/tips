--
-- Created by IntelliJ IDEA.
-- User: arika.chen
-- Date: 2017/11/1
-- Time: 10:53
-- To change this template use File | Settings | File Templates.
--
local log  = ngx.log
local ERR  = ngx.ERR
local http = require "resty.http"
local json = require "cjson.safe"
local cache = require "cache"

local lb_cache = ngx.shared.lb_opt_cache

local socket_path = "/run/ingress.sock"
local url = "/"
local key_prefix = "key="
local time_out = 500

local _M = {
    _VERSION = '0.01'
}

local mt = { __index = _M }

function _M.new(self, svc_key)
    return setmetatable({ svc_key = svc_key }, mt)
end

local function get(sock, url, arg, time_out)
    local httpc = http.new()

    httpc:set_timeout(time_out)
    local ok, err = httpc:connect("unix:" .. sock)
    if not ok then
        log(ERR, "connect failed: ", err)
        return nil, err
    end

    local res, err = httpc:request({
        path = url,
        query = arg,
        headers = {
            ["Host"] = "localhost",
        }
    })

    if not res then
        log(ERR, "request failed: ", err)
        return nil, err
    end
    local body, err = res:read_body()
    if not body then
        log(ERR, "read body failed: ", err)
        return nil, err
    end

    -- local ok, err = http.close()
    -- if not ok then
    --     ngx.log(ngx.ERR, "close failed: ", err)
    --     return nil, err
    -- end
    return body, nil
end

function _M.parse(self)
    local func = function (key)
        local ctt, err = get(socket_path, url, key_prefix .. key, time_out)
        if ctt == nil then
            log(ERR, "parse config failed: ", err, " key: ", key)
            return nil
        end
        return ctt
    end
    local cc = cache:new(lb_cache, 5)
    local data, err = cc:get_or_set(self.svc_key, func)
    if not data then
        return nil, err
    end
    local data = json.decode(data)
    if data then
        return data, nil
    else
        log(ERR, "json decode failed, key: ", self.svc_key)
        return nil, "decode " .. self.svc_key .. "error"
    end
end


return _M
