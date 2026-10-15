

local Codec=...
local A={}
local LIMIT=64*1024*1024
local CHUNK=8*1024*1024
local MAGIC="CBE-MODEL-CHUNK-1\n"
local function identity(path)
if type(path)~="string"then return nil end
local stem,relative=path:match("^cache/movefx/([^/]+)/(.+)$")
if not stem then return nil end
if relative:match("^packed_[^/]+/")then return nil end
local name=relative:match("^models/(.+)$")
if not name then return "cache/movefx/"..stem,"cache/movefx/"..stem.."/packed_bank_v1"end
name=name:gsub("_runtime_v%d+_r%d+/.*$",""):gsub("%.lua$",""):gsub("%.rgba$","")
name=name:gsub("_anim_%d+$",""):gsub("_tex_%d+$",""):gsub("_parts$","")
if not name:match("^[%w_%-]+$")then return nil end
return "cache/movefx/"..stem.."/models/"..name,"cache/movefx/"..stem.."/packed_models_v1/"..name
end
local function number(v)return type(v)=="number"and v==math.floor(v)and v>=0 end
local function indexBody(index)
local keys={};for k in pairs(index.entries)do keys[#keys+1]=k end;table.sort(keys)
local rows={"return {version=1,chunks={"}
for _,n in ipairs(index.chunks)do rows[#rows+1]=tostring(n)..","end
rows[#rows+1]="},entries={"
for _,k in ipairs(keys)do local e=index.entries[k]
rows[#rows+1]=("[%q]={%d,%d,%d,%d},"):format(k,e[1],e[2],e[3],e[4])
end
rows[#rows+1]="}}\n";return table.concat(rows)
end
function A.install(mod)
local base=assert(mod.cache);if base.__cbeModelArchive then return base end
local indexes={};local indexCount=0;local lastPath,lastBytes;local active
local cache=setmetatable({__cbeModelArchive=true},{__index=base})
local function remember(root,value)
if indexes[root]==nil then indexCount=indexCount+1 end
if indexCount>16 then indexes={};indexCount=1 end
indexes[root]=value
end
local function loadIndex(root)
if indexes[root]~=nil then return indexes[root]or nil end
local bytes=base:read(root.."/index.lua")
if type(bytes)~="string"then remember(root,false);return nil end
if #bytes>4*1024*1024 then return nil,"model archive index too large"end
local chunk,why=load(bytes,"@"..root.."/index.lua","t",{})
if not chunk then return nil,why end
local ok,index=pcall(chunk)
if not ok or type(index)~="table"or index.version~=1 or type(index.entries)~="table"or type(index.chunks)~="table"then return nil,"invalid model archive index"end
for _,size in ipairs(index.chunks)do if not number(size)or size<1 or size>LIMIT then return nil,"invalid model archive chunk size"end end
local count=0
for path,e in pairs(index.entries)do
local _,owner=identity(path);count=count+1
if owner~=root or count>50000 or type(e)~="table"or not number(e[1])or e[1]<1 or not index.chunks[e[1]]
or not number(e[2])or e[2]<#MAGIC or not number(e[3])or e[3]<1 or e[2]+e[3]>index.chunks[e[1]]
or not number(e[4])or e[4]<1 or e[4]>LIMIT then return nil,"invalid model archive member"end
end
remember(root,index);return index
end
local function member(path)
local _,root=identity(path);if not root then return nil end
local index,why=loadIndex(root);if not index then return nil,why end
return index.entries[path],nil,root,index
end
local function archivedRead(path,e,root,index)
local file=("%s/chunk_%04d.cba"):format(root,e[1])
local bytes=lastPath==file and lastBytes or base:read(file)
if type(bytes)~="string"or #bytes~=index.chunks[e[1]]or bytes:sub(1,#MAGIC)~=MAGIC then return nil,path..": missing/truncated model archive chunk"end

if #bytes<=CHUNK then lastPath,lastBytes=file,bytes end
local raw,why=Codec.decode(path,bytes:sub(e[2]+1,e[2]+e[3]))
if type(raw)~="string"or #raw~=e[4]then return nil,why or(path..": invalid model archive member length")end
return raw
end
function cache:read(path)
if active and active.entries[path]then return archivedRead(path,active.entries[path],active.root,active)end
if not identity(path)then return base:read(path)end
local info,why=base:info(path);if why~=nil then return nil,why end
if info then return base:read(path)end
local e,err,root,index=member(path);if not e then return nil,err end
return archivedRead(path,e,root,index)
end
function cache:info(path)
if active and active.entries[path]then return {type="file",size=active.entries[path][4]}end
local info,why=base:info(path);if info~=nil or why~=nil then return info,why end
local e,err,root,index=member(path);if not e then return nil,err end
local file=("%s/chunk_%04d.cba"):format(root,e[1])
local chunk=base:info(file)
if not chunk or tonumber(chunk.size)~=index.chunks[e[1]]then return nil,path..": missing/truncated model archive chunk"end
return {type="file",size=e[4]}
end
function cache:exists(path)return self:info(path)~=nil end
local function enroll(tx,path)
if tx.generated and not tx.seen[path]then tx.seen[path]=true;tx.generated[#tx.generated+1]=path end
end
local function flush(tx)
if tx.size==0 then return true end
local file=("%s/chunk_%04d.cba"):format(tx.root,#tx.chunks+1)

enroll(tx,file)
local bytes=MAGIC..table.concat(tx.pending);local ok,why=base:write(file,bytes)
if not ok then tx.failed=why or "archive chunk write failed";return nil,tx.failed end
tx.chunks[#tx.chunks+1]=#bytes;tx.pending={};tx.size=0
lastPath,lastBytes=nil,nil;return true
end
function cache:isModelBundlePath(path)
local prefix=identity(path);return active and prefix==active.prefix or false
end
function cache:write(path,bytes)
if not self:isModelBundlePath(path)then return base:write(path,bytes)end
local tx=active
if type(bytes)~="string"or #bytes<1 or #bytes>LIMIT then tx.failed="model member outside cache size limit";return nil,tx.failed end
if tx.entries[path]then tx.failed="duplicate model archive member";return nil,tx.failed end


if base:info(path)then enroll(tx,path);return base:write(path,bytes)end


local encoded=Codec.encode("cache/archive_member.cbb",bytes)
if #encoded+#MAGIC>LIMIT then tx.failed="encoded model member outside cache size limit";return nil,tx.failed end
if tx.size>0 and tx.size+#encoded+#MAGIC>CHUNK then local ok,why=flush(tx);if not ok then return nil,why end end
tx.entries[path]={#tx.chunks+1,tx.size+#MAGIC,#encoded,#bytes}
tx.pending[#tx.pending+1]=encoded;tx.size=tx.size+#encoded


return true
end
local ordinaryRead=cache.read
function cache:read(path)
if active and active.entries[path]and active.entries[path][1]>#active.chunks then
local ok,why=flush(active);if not ok then return nil,why end
end
return ordinaryRead(self,path)
end
function cache:delete(path)
if active then return nil,"cannot delete during model archive transaction"end
local concrete=base:info(path)
local e,why,root,index=member(path);if why then return nil,why end
if e then
local entries={};for k,v in pairs(index.entries)do if k~=path then entries[k]=v end end
local replacement={version=1,chunks=index.chunks,entries=entries}
local ok,err=base:write(root.."/index.lua",indexBody(replacement));if not ok then return nil,err end
remember(root,replacement);lastPath,lastBytes=nil,nil
end
if e and not concrete then return true end
local ok,err=base:delete(path)
if path:find("/packed_models_v1/",1,true)then indexes={};indexCount=0;lastPath,lastBytes=nil,nil end
return ok,err
end
function cache:bundleModel(path,build,generated)
local prefix,root=identity(path)
if (active and active.prefix==prefix)or not prefix then return build()end


local info=base:info(path)
local old,why=loadIndex(root)
if info or old or why then return build()end
local tx={prefix=prefix,root=root,version=1,entries={},chunks={},pending={},size=0,generated=generated,seen={}}
local parent=active;active=tx
local ok,result,detail=pcall(build)
if ok and result and not tx.failed then
local committed,err=flush(tx)
if committed then
local file=root.."/index.lua";enroll(tx,file)
committed,err=base:write(file,indexBody(tx))
end
if committed then remember(root,{version=1,chunks=tx.chunks,entries=tx.entries})else tx.failed=err or "archive index write failed"end
end
active=parent;lastPath,lastBytes=nil,nil
if not ok then error(result,0)end
if tx.failed then return nil,"model archive commit failed: "..tostring(tx.failed)end
return result,detail
end
rawset(mod,"cache",cache);return cache
end
A._test={identity=identity,chunkBytes=CHUNK,indexBody=indexBody}
return A
