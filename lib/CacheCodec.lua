

local C={version=1}
local MAGIC="CBE-CACHE-ZLIB-1\n"
local MAX_BYTES=64*1024*1024
local function eligible(path)
return type(path)=="string" and path:sub(1,6)=="cache/"
and (path:match("%.lua$")or path:match("%.cbb$")
or(path:find("/native_v1/",1,true)and path:match("%.f32$")))
end
local function header(bytes)
if type(bytes)~="string" or bytes:sub(1,#MAGIC)~=MAGIC then return nil end
local stop=bytes:find("\n",#MAGIC+1,true)
local size=stop and tonumber(bytes:sub(#MAGIC+1,stop-1))
if not size or size<1 or size>MAX_BYTES or size~=math.floor(size)then return false,"invalid compressed-cache size"end
return size,stop+1
end
function C.encode(path,bytes)
if not eligible(path)or type(bytes)~="string"or #bytes<4096 then return bytes end
if not(love and love.data and type(love.data.compress)=="function")then return bytes end
local ok,packed=pcall(love.data.compress,"string","zlib",bytes,1)
if not ok or type(packed)~="string"or #packed+#MAGIC+12>=#bytes*.85 then return bytes end
return MAGIC..#bytes.."\n"..packed
end
function C.decode(path,bytes)
local size,at=header(bytes)
if size==nil then return bytes end
if size==false then return nil,tostring(path)..": "..tostring(at)end
if not(love and love.data and type(love.data.decompress)=="function")then return nil,tostring(path)..": zlib decoder unavailable"end
local ok,raw=pcall(love.data.decompress,"string","zlib",bytes:sub(at))
if not ok or type(raw)~="string"or #raw~=size then return nil,tostring(path)..": invalid lossless cache payload"end
return raw
end
function C.install(mod)
local base=assert(mod.cache,"cache unavailable")
if base.__cbeCodec then return base end
local sizes={};local count=0
local function remember(path,logical,physical)
if not sizes[path]then count=count+1 end
if count>2048 then sizes={};count=1 end
sizes[path]={logical=logical,physical=physical}
end
local cache=setmetatable({__cbeCodec=true},{__index=base})
function cache:write(path,bytes)
if type(bytes)~="string"or #bytes>MAX_BYTES then return nil,"cache payload outside 64 MiB limit"end
local stored=C.encode(path,bytes)
local ok,why=base:write(path,stored)
if ok~=false and ok~=nil then remember(path,#bytes,#stored)end
return ok,why
end
function cache:read(path)
local stored,why=base:read(path)
if type(stored)~="string"then sizes[path]=nil;return stored,why end
local raw,err=C.decode(path,stored)
if raw then remember(path,#raw,#stored)else sizes[path]=nil end
return raw,err
end
function cache:info(path)
local info,why=base:info(path)
if type(info)~="table"or not eligible(path)then return info,why end
local logical;local known=sizes[path]
if known and (info.size==nil or tonumber(info.size)==known.physical)then logical=known.logical
else
local bytes,err=base:read(path)
if type(bytes)~="string"then return nil,err end
local size,detail=header(bytes)
if size==false then return nil,tostring(path)..": "..tostring(detail)end
logical=size or #bytes;remember(path,logical,#bytes)
end
local result={};for k,v in pairs(info)do result[k]=v end
result.size=logical;return result
end
function cache:exists(path)return self:info(path)~=nil end
function cache:delete(path)
sizes[path]=nil;return base:delete(path)
end
rawset(mod,"cache",cache);return cache
end
C._test={header=header,eligible=eligible}
return C
