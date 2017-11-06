--
-- Created by IntelliJ IDEA.
-- User: arika.chen
-- Date: 2017/11/3
-- Time: 9:36
-- To change this template use File | Settings | File Templates.
--

local log  = ngx.log
local ERR  = ngx.ERR
local resty_lock = require "resty.lock"

local _M = {
    _VERSION = '0.01'
}

local mt = { __index = _M }

function _M.new(self, pool, expire)
    return setmetatable({ cache = pool, expire = expire }, mt)
end

-- https://github.com/openresty/lua-resty-lock#for-cache-locks
function _M.get_or_set(self, key, func)
    -- step 1:
    local val, err = self.cache:get(key)
    if val then
        return val, nil
    end

    if err then
        log(ERR, "failed to get key from shm: ", err)
        return nil, err
    end

    -- cache miss!
    -- step 2:
    local lock, err = resty_lock:new("cache_locks")
    if not lock then
        log(ERR, "failed to create lock: ", err)
        return nil, err
    end

    local elapsed, err = lock:lock(key)
    if not elapsed then
        log(ERR, "failed to acquire the lock: ", err)
        return nil, err
    end

    -- lock successfully acquired!

    -- step 3:
    -- someone might have already put the value into the cache
    -- so we check it here again:
    val, err = self.cache:get(key)
    if val then
        local ok, err = lock:unlock()
        if not ok then
            log(ERR, "failed to unlock: ", err)
            return nil, err
        end

        return val
    end

    --- step 4:
    local val = func(key)
    if not val then
        local ok, err = lock:unlock()
        if not ok then
            log(ERR, "failed to unlock: ", err)
            return nil, err
        end

        -- FIXME: we should handle the backend miss more carefully
        -- here, like inserting a stub value into the cache.
        return nil, "no value"
    end

    -- update the shm cache with the newly fetched value
    local ok, err = self.cache:set(key, val, self.expire)
    if not ok then
        local ok, err = lock:unlock()
        if not ok then
            log(ERR, "failed to unlock: ", err)
            return nil, err
        end
        log(ERR, "failed to update shm cache: ", err)
        return nil, err
    end

    local ok, err = lock:unlock()
    if not ok then
        log(ERR, "failed to unlock: ", err)
        return nil, err
    end
    return val, nil
end

return _M
