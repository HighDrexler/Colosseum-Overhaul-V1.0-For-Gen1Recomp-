










local P={version=1,root="cache/preserved/"}

local MOD=4294967291

local function safeNamespace(namespace)
local s=tostring(namespace or "payload"):lower():gsub("[^%w_%-]","_")
if s=="" then s="payload" end
return s
end

local function fingerprint(bytes)
assert(type(bytes)=="string","payload fingerprint requires bytes")
local a,b=2166136261,1315423911
for i=1,#bytes do
local x=bytes:byte(i)
a=(a*65599+x+i)%MOD
b=(b*131071+x*(i%251+1))%MOD
end
return ("%x_%x_%x"):format(#bytes,a,b)
end

local function archivePath(namespace,bytes)
return P.root..safeNamespace(namespace).."/v1/"..fingerprint(bytes)..".bin"
end

local function cacheRead(mod,path)
local cache=mod and mod.cache
if not (cache and type(cache.read)=="function") then return nil,"cache read unavailable" end
local ok,bytes=pcall(cache.read,cache,path)
if not ok then return nil,tostring(bytes) end
if type(bytes)=="string" then return bytes end



if type(cache.info)=="function" then
local infoOK,info=pcall(cache.info,cache,path)
if not infoOK then return nil,"cache info failed: "..tostring(info) end
if info and info.type~="directory" then return nil,"existing payload is unreadable: "..tostring(path) end
end
return nil,nil
end

local function cacheWrite(mod,path,bytes)
local cache=mod and mod.cache
if not (cache and type(cache.write)=="function") then return false,"cache write unavailable" end
local ok,a,b=pcall(cache.write,cache,path,bytes)
if not ok then return false,tostring(a) end
if a==false or a==nil then return false,tostring(b or "cache write failed") end
return true
end

function P.fingerprint(bytes)return fingerprint(bytes)end
function P.archivePath(namespace,bytes)return archivePath(namespace,bytes)end

function P.has(mod,path)
local cache=mod and mod.cache
if not cache then return false end
if type(cache.info)=="function" then
local ok,info=pcall(cache.info,cache,path)
if ok then return type(info)=="table" and (info.type==nil or info.type~="directory") end
end
if type(cache.read)=="function" then
local ok,v=pcall(cache.read,cache,path);return ok and type(v)=="string"
end
return false
end




function P.preserve(mod,namespace,path,incoming,oldBytes)
local old=oldBytes
if old==nil then
local why
old,why=cacheRead(mod,path)
if why then return nil,why end
elseif type(old)~="string" then
return nil,"invalid previous payload bytes"
end
if old==nil or old==incoming then return nil,nil end

local kept=archivePath(namespace,old)
local existing,readWhy=cacheRead(mod,kept)
if readWhy then return nil,readWhy end
if existing~=nil then
if existing~=old then return nil,"content-address collision at "..kept end
return kept,nil
end
local ok,why=cacheWrite(mod,kept,old)
if not ok then return nil,"preserve write failed: "..tostring(why) end
local verify,verifyWhy=cacheRead(mod,kept)
if verifyWhy or verify~=old then
return nil,"preserve verification failed: "..tostring(verifyWhy or kept)
end
return kept,nil
end

function P.write(mod,namespace,path,data,generated,preserveExisting,oldBytes)
assert(type(data)=="string","persistent payload write requires bytes")
local kept
if preserveExisting then
local why
kept,why=P.preserve(mod,namespace,path,data,oldBytes)
assert(why==nil,why)
end
local ok,why=cacheWrite(mod,path,data)
assert(ok,why or ("cache write failed: "..tostring(path)))
if generated then generated[#generated+1]=path end
return true,kept
end

return P
