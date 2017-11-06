--
-- Created by IntelliJ IDEA.
-- User: arika.chen
-- Date: 2017/11/3
-- Time: 16:11
-- To change this template use File | Settings | File Templates.
--

local log  = ngx.log
local ERR  = ngx.ERR

local iputils = require("resty.iputils")
iputils.enable_lrucache()

local _M = {
    _VERSION = '0.01'
}

local mt = { __index = _M }

function _M.new(self, cfg)
    local whitelist = cfg.whitelist or {}
    local blacklist = cfg.blacklist or {}
    //TODO, mv to init
    iputils.enable_lrucache()
    whitelist = iputils.parse_cidrs(whitelist)
    blacklist = iputils.parse_cidrs(blacklist)
    return setmetatable({ whitelist = whitelist, blacklist = blacklist }, mt), nil
end

local function check_ip(list)
    local ip = ngx.var.remote_addr
    return iputils.ip_in_cidrs(ip, list)
end

function _M.check_whitelist(self)
    if #self.whitelist > 0 and not check_ip(self.whitelist) then
        return true
    end
    return false
end

function _M.check_blacklist(self)
    if #self.blacklist > 0 and check_ip(self.blacklist) then
        return true
    end
    return false
end

return _M
