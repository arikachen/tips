--
-- Created by IntelliJ IDEA.
-- User: arika.chen
-- Date: 2017/11/1
-- Time: 17:18
-- To change this template use File | Settings | File Templates.
--

local log  = ngx.log
local ERR  = ngx.ERR
local opt = require "opt"
local qos = require "qos"
local sec = require "security"

local svc_key = ngx.var.svc_key
local feature = ngx.var.feature
local lb_cache = ngx.shared.lb_opt_cache

if not svc_key then
    log(ERR, "svc key is empty")
    return
end


if #feature > 0 then
    -- local func = function (key)
    --     log(ERR, "1fail to get conf, key: ", key)
    --     local feat = opt:new(key)
    --     local conf, err = feat:parse(key)
    --     if not conf then
    --         log(ERR, "fail to get conf, key: ", key)
    --         return {}
    --     end
    --     log(ERR, "2fail to get conf, key: ", conf.limit.enable)
    --     return conf
    -- end
    -- local cc = cache:new(lb_cache, 5)
    -- local conf, err = cc:get_or_set(svc_key, func)
    local feat = opt:new(svc_key)
    local conf, err = feat:parse(svc_key)
    if not conf then
        log(ERR, "fail to get conf, error: ", err)
        return err
    end
    if conf.security ~= nil then
        local s = sec:new(conf.security)
        if s:check_whitelist() or s:check_blacklist() then
             return ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end 

    if conf.limit ~= nil then
        local qos_cfg = conf.limit
        if qos_cfg.enable then
            if ngx.req.is_internal() then
                return
            end

            local q, err = qos:new(qos_cfg)
            if not q then
                log(ERR, "init limit failed, error: ", err)
                return
            end
            q:incomming()
        end
    end
end
