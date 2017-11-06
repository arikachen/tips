--
-- Created by IntelliJ IDEA.
-- User: arika.chen
-- Date: 2017/11/2
-- Time: 9:47
-- To change this template use File | Settings | File Templates.
--

local log  = ngx.log
local ERR  = ngx.ERR
local WARN  = ngx.WARN
local limit_conn = require "resty.limit.conn"
local limit_req = require "resty.limit.req"
local limit_traffic = require "resty.limit.traffic"

local _M = {
    _VERSION = '0.01'
}

local mt = { __index = _M }

function _M.new(self, cfg)
    if cfg then
        local conn, req, err
        local req_rate = cfg.reqRate or 0
        local req_burst = cfg.reqBurst or 0
        if req_rate > 0 and req_burst >= 0 then
            req, err = limit_req.new("lb_req_store", req_rate, req_burst)
            if not req then
                log(ERR, "failed to instantiate req object, error: ", err)
                return nil, ngx.exit(500)
            end
        end

        local conn_rate = cfg.connRate or 0
        local conn_burst = cfg.connBurst or 0
        local conn_delay = cfg.connDelay or 0.5
        if conn_rate > 0 and conn_burst >= 0 and conn_delay > 0 then
            conn, err = limit_conn.new("lb_conn_store", conn_rate, conn_burst, conn_delay)
            if not conn then
                log(ERR, "failed to instantiate conn object, error: ", err)
                return nil, ngx.exit(500)
            end
        end
        return setmetatable({ conn = conn, req = req }, mt), nil
    end
    return setmetatable({}, mt), nil
end

function _M.incomming(self)
    local key = ngx.var.binary_remote_addr
    local limiters, keys
    if self.conn and self.req then
        limiters = { self.req, self.conn }
        keys ={ key, key }
    elseif self.req then
        limiters = { self.req }
        keys ={ key }
    else
        limiters = { self.conn }
        keys ={ key }
    end

    local delay, err = limit_traffic.combine(limiters, keys)
    if not delay then
        if err == "rejected" then
            return ngx.exit(503)
        end
        log(ERR, "failed to limit traffic: ", err)
        return ngx.exit(500)
    end
    if self.conn and self.conn:is_committed() then
        local ctx = ngx.ctx
        ctx.limit_conn = self.conn
        ctx.limit_conn_key = key
    end

    if delay >= 0.001 then
        log(WARN, "delaying traffic, excess ", delay, "s")
        ngx.sleep(delay)
    end
end

function _M.leaving(self)
    local ctx = ngx.ctx
    local lim = ctx.limit_conn
    if lim then
        local key = ctx.limit_conn_key
        local latency = tonumber(ngx.var.request_time)
        if key then
            local conn, err = lim:leaving(key, latency)
            if not conn then
                log(ERR,
                    "failed to record the connection leaving ",
                    "request: ", err)
            end
        end
    end
end

return _M
