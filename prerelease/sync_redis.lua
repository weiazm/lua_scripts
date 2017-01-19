local check = function()
    local redis = require "resty.redis"
    while (true) do
        local red = redis:new()
        local redis_cache = ngx.shared.redis_cache
        red:set_timeout(10000) -- 10 sec

        local ok, err = red:connect("b0d5cb45f85b4884.m.cnbja.kvstore.aliyuncs.com", 6379)
        if not ok then
            ngx.log(ngx.ERR, err)
            return
        end
        local ok, err = red:auth("b0d5cb45f85b4884:b0d5cb45f85b4884MhxzKhl8887")
        if not ok then
            ngx.log(ngx.ERR, err)
            return
        end
        -- 分流到新server版本集合
        local res, err = red:get("tx_versions")
        if not res then
            ngx.log(ngx.ERR, err)
        else
            if res == ngx.null then
                ngx.log(ngx.ERR, "tx_version not found.")
            else
                redis_cache:delete("tx_versions")
                redis_cache:set("tx_versions",res)
--                ngx.log(ngx.ERR,"found versions:",res)
            end
        end
        -- 分流到新server用户集合
        local res, err = red:get("tx_orgnumbers")
        if not res then
            ngx.log(ngx.ERR, err)
        else
            if res == ngx.null then
                ngx.log(ngx.ERR, "tx_orgnumbers not found.")
            else
                redis_cache:delete("tx_orgnumbers")
                redis_cache:set("tx_orgnumbers",res)
--                ngx.log(ngx.ERR,"found tx_orgnumbers:",res)
            end
        end
--        local ok, err = red:set_keepalive(10000, 10)
--        if not ok then
--            ngx.log(ngx.ERR, err)
--        end
        local ok, err = red:close()
                if not ok then
                    ngx.say("failed to close: ", err)
                    return
                end
        ngx.sleep(60)
    end
end

local new_timer = ngx.timer.at
local ok, err = new_timer(0, check)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
end


