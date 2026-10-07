local V=...
local mod=V.mod
local G={schema=2}







local INFO_REGISTRY_PATH="build/hard_cache_registry_v1.lua"
local INFO_REGISTRY_REVISION=1
local infoCache={}
local infoRegistry={}
local registryMeta={}
local registryCount=0
local registryPersistedBody=nil
local infoStats={host=0,memory=0,registry=0,trusted=0,writes=0,deletes=0}

local function call(obj,name,...)
if not obj or type(obj[name])~="function" then return nil,"unavailable" end
local ok,a,b=pcall(obj[name],obj,...)
if not ok then return nil,tostring(a) end
return a,b
end

local function loadRegistry()
local raw=select(1,call(mod and mod.cache,"read",INFO_REGISTRY_PATH))
if type(raw)~="string" then return end
local chunk=load(raw,"@generated/"..INFO_REGISTRY_PATH)
if not chunk then return end
local ok,value=pcall(chunk)
if not ok or type(value)~="table" or tonumber(value.revision)~=INFO_REGISTRY_REVISION or type(value.entries)~="table" then return end
registryMeta={}
for k,v in pairs(type(value.meta)=="table" and value.meta or {}) do
if type(k)=="string" and (type(v)=="string" or type(v)=="number" or type(v)=="boolean") then
registryMeta[k]=v
end
end
for path,info in pairs(value.entries) do
if type(path)=="string" and type(info)=="table" then
local row={type=info.type or "file"}
if tonumber(info.size) then row.size=tonumber(info.size) end
if not infoRegistry[path] then registryCount=registryCount+1 end
infoRegistry[path]=row
end
end



registryPersistedBody=raw
end
loadRegistry()

local function remember(path,info)
if type(path)~="string" or path=="" then return end
if type(info)=="table" then
local row={type=info.type or "file"}
if tonumber(info.size) then row.size=tonumber(info.size) end
if not infoRegistry[path] then registryCount=registryCount+1 end
infoCache[path]=row;infoRegistry[path]=row
else



if infoRegistry[path] then registryCount=registryCount-1 end
infoCache[path]=nil;infoRegistry[path]=nil
end
end

local function q(v) return string.format("%q",tostring(v)) end

function G.info(path)
path=tostring(path or "")
local cached=infoCache[path]
if cached~=nil then infoStats.memory=infoStats.memory+1;return cached or nil end
local registered=infoRegistry[path]
if registered then infoCache[path]=registered;infoStats.registry=infoStats.registry+1;return registered end
local v=select(1,call(mod.cache,"info",path));infoStats.host=infoStats.host+1
if type(v)=="table" then remember(path,v);return infoCache[path] end


return nil
end







function G.registered(path)
path=tostring(path or "")
local row=infoCache[path] or infoRegistry[path]
if type(row)=="table" then
infoStats.trusted=infoStats.trusted+1
return row
end
return nil
end

function G.registryMeta()
local out={}
for k,v in pairs(registryMeta) do out[k]=v end
return out
end

function G.revalidateInfo(path)
path=tostring(path or "")
local v=select(1,call(mod.cache,"info",path));infoStats.host=infoStats.host+1
if type(v)=="table" then remember(path,v);return infoCache[path] end
remember(path,nil)
return nil
end

function G.exists(path)
local v=G.info(path)
return v and (v.type==nil or v.type=="file") and true or false
end

function G.read(path)
local data,err=call(mod.cache,"read",path)
if type(data)=="string" then


remember(tostring(path),{type="file",size=#data})
return data
end
remember(tostring(path),nil)
return nil,err or ("generated asset missing: "..tostring(path))
end

function G.write(path,data)
local a,b=call(mod.cache,"write",path,data)
if a~=nil and a~=false then
remember(tostring(path),{type="file",size=type(data)=="string" and #data or nil});infoStats.writes=infoStats.writes+1
else
remember(tostring(path),nil)
end
return a,b
end

function G.delete(path)
local a,b=call(mod.cache,"delete",path)
infoStats.deletes=infoStats.deletes+1
if a~=nil and a~=false then remember(tostring(path),nil);return a,b end



local info,infoErr=call(mod.cache,"info",path)
if info==nil and infoErr==nil then
remember(tostring(path),nil)
return true,"already absent"
end
if type(info)=="table" then remember(tostring(path),info) end
return false,b or infoErr or "cache deletion failed"
end

function G.readLua(path)
local src,err=G.read(path)
if not src then return nil,err end
local chunk,loadErr=load(src,"@generated/"..tostring(path))
if not chunk then return nil,loadErr end
local ok,value=pcall(chunk)
if not ok then return nil,value end
return value
end




function G.fileData(path,name)
local bytes,err=G.read(path)
if not bytes then return nil,err end
if not (love and love.filesystem and love.filesystem.newFileData) then
return nil,"love.filesystem.newFileData unavailable"
end
local ok,fd=pcall(love.filesystem.newFileData,bytes,name or tostring(path):match("[^/]+$") or "generated.bin")
if not ok then return nil,tostring(fd) end
return fd
end

function G.packageRead(path)
if not (mod and type(mod.read)=="function") then return nil,"mod.read unavailable" end
local ok,data=pcall(mod.read,mod,path)
if not ok then return nil,tostring(data) end
return data
end

function G.packageLua(path,arg)
local src,err=G.packageRead(path)
if not src then return nil,err end
local chunk,loadErr=load(src,"@"..tostring(mod.path or mod.id).."/"..tostring(path))
if not chunk then return nil,loadErr end
local ok,value=pcall(chunk,arg)
if not ok then return nil,value end
return value
end

function G.invalidateInfo(path)
if path==nil then infoCache={} else infoCache[tostring(path)]=nil end
return true
end

function G.saveInfoRegistry(extra)
if type(extra)=="table" then
for k,v in pairs(extra) do
if type(k)=="string" and (type(v)=="string" or type(v)=="number" or type(v)=="boolean") then
registryMeta[k]=v
end
end
end
local keys={}
for path,info in pairs(infoRegistry) do
if path~=INFO_REGISTRY_PATH and type(info)=="table" then keys[#keys+1]=path end
end
table.sort(keys)
local out={"return {revision=",tostring(INFO_REGISTRY_REVISION),",entries={"}
for _,path in ipairs(keys) do
local info=infoRegistry[path]
out[#out+1]="["..q(path).."]={type="..q(info.type or "file")
if tonumber(info.size) then out[#out+1]=",size="..tostring(math.floor(tonumber(info.size))) end
out[#out+1]="},"
end
out[#out+1]="},meta={"
local metaKeys={};for k in pairs(registryMeta) do metaKeys[#metaKeys+1]=k end;table.sort(metaKeys)
for _,k in ipairs(metaKeys) do local v=registryMeta[k]
out[#out+1]="["..q(k).."]="..(type(v)=="string" and q(v) or tostring(v))..","
end
out[#out+1]="}}\n"
local body=table.concat(out)
if body==registryPersistedBody then return true,"unchanged",#keys end
local a,b=call(mod.cache,"write",INFO_REGISTRY_PATH,body)
if a~=nil and a~=false then
remember(INFO_REGISTRY_PATH,{type="file",size=#body});registryPersistedBody=body
return true,b,#keys
end
return false,b or "registry write failed",#keys
end

function G.clearInfoRegistry(deletePersisted)
infoCache={};infoRegistry={};registryMeta={};registryCount=0;registryPersistedBody=nil
if deletePersisted~=false then call(mod.cache,"delete",INFO_REGISTRY_PATH) end
return true
end

function G.registryStatus()
local meta={}
for k,v in pairs(registryMeta) do meta[k]=v end
return {path=INFO_REGISTRY_PATH,revision=INFO_REGISTRY_REVISION,entries=registryCount,
hostProbes=infoStats.host,memoryHits=infoStats.memory,registryHits=infoStats.registry,
trustedHits=infoStats.trusted,writes=infoStats.writes,deletes=infoStats.deletes,meta=meta}
end

return G
