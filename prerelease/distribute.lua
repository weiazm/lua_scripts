function split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
--获取version顺序 1.get参数 2.post参数 3.cookie
--获取org_number顺序 1.header 2.cookie

local version = "default"
local org_number = "default"
--get请求uri参数
local uri_args = ngx.req.get_uri_args()
for k, v in pairs(uri_args) do
    if k == "version" then
        version=v
    end
end

--post请求参数
if ngx.var.version == "default" then
	ngx.req.read_body()
	local post_args = ngx.req.get_post_args()
	for k, v in pairs(post_args) do
    	if type(v) ~= "table" then
        	if k == "version" then
        		version=v
        	end
    	end
	end
end

--header获取org_number
local headers = ngx.req.get_headers()
local header_org_number = headers.userNumber
local header_tx_version = headers.version
if header_org_number ~= nil then
	org_number = header_org_number
end
if header_tx_version ~= nil then
	version = header_tx_version
end

local ck = require "resty.cookie"
local cookie,err = ck:new()
if not cookie then
    ngx.log(ngx.ERR, err)
else
	--cookie取version
    if version == "default" then
    	local cookie_version, err = cookie:get("version")
		if not cookie_version then
    		ngx.log(ngx.ERR, err)
		else
			version=cookie_version
		end
    end
    --cookie取orgnumber
    if org_number == "default" then
		local cookie_org_number, err = cookie:get("userNumber")
		if not cookie_org_number then
    		ngx.log(ngx.ERR, err)
		else
			org_number=cookie_org_number
		end	
	end
end





local redis_cache = ngx.shared.redis_cache
local redis_versions = redis_cache:get("tx_versions")
local redis_org_numbers = redis_cache:get("tx_orgnumbers")

if redis_org_numbers ~= nil then
	local org_number_table = split(redis_org_numbers,",")
	if org_number_table ~= nil then
		for k,v in pairs(org_number_table) do
			if v == org_number then
				ngx.exec("@pre_release")
				break
			end
		end
	end
end

if redis_versions ~= nil then
	local version_table = split(redis_versions,",")	
	if version_table ~= nil then
		for k,v in pairs(version_table) do	
		ngx.log(ngx.ERR," version in redis : ",v)		
			if v == version then
				ngx.exec("@pre_release")
				break
			end
		end
	end
end


