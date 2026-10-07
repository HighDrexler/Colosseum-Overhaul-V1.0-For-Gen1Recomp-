local V=...
local Waza=V and V.WazaSequenceRuntime
local Assets=V and V.GeneratedAssets
local CSM=V and V.CurrentSpriteModels
local Audio=V and V.WazaAudioRuntime
local RuntimeMeshCache=V and V.RuntimeMeshCache
local function checkpoint(label)
if V.WorkBudget then V.WorkBudget.checkpoint(label) end
end
local CameraFov=V and V.WazaCameraFov
local CameraParams=V and V.WazaCameraParams
local H={installed=false,models={},effects={},controllers={player={},enemy={}},opaque={},lastModel=nil,modelCache={},partsCache={},modelErrors={},textureCache={},drawError=nil,
postCanvas=nil,postHistory=nil,postW=0,postH=0,distortShader=nil,postErrors=0}




local function sourceModelFrame(ticks) return math.max(0,tonumber(ticks) or 0)*.5 end





local function platformOS()
if love and love.system and type(love.system.getOS)=="function" then
local ok,value=pcall(love.system.getOS)
if ok and value then return tostring(value) end
end
return "Unknown"
end
local PLATFORM_OS=platformOS()
local MOBILE_RUNTIME=PLATFORM_OS=="Android" or PLATFORM_OS=="iOS"

local FORMAT_STATIC={
{"VertexPosition","float",3},{"VertexTexCoord","float",2},{"VertexNormal","float",3},
}



local FORMAT_MORPH={
{"VertexPosition","float",3},{"VertexTexCoord","float",2},{"VertexNormal","float",3},
{"FramePack1","float",4},{"FramePack2","float",4},{"FramePack3","float",4},
{"FramePack4","float",4},{"FramePack5","float",4},{"FramePack6","float",4},
{"FramePack7","float",4},{"FramePack8","float",4},{"FramePack9","float",4},
}
local VERTEX_STATIC=[[
uniform mat4 vp;
uniform mat4 model;
attribute vec3 VertexNormal;
varying vec3 wNormal;
vec4 position(mat4 transform_projection, vec4 vertex_position) {
  vec4 world=model*vec4(vertex_position.xyz,1.0);
  wNormal=normalize((model*vec4(VertexNormal,0.0)).xyz);
  return vp*world;
}
]]
local VERTEX_MORPH=[[
uniform mat4 vp;
uniform mat4 model;
uniform float w0; uniform float w1; uniform float w2; uniform float w3;
uniform float w4; uniform float w5; uniform float w6; uniform float w7;
uniform float w8; uniform float w9; uniform float w10; uniform float w11; uniform float w12;
attribute vec3 VertexNormal;
attribute vec4 FramePack1; attribute vec4 FramePack2; attribute vec4 FramePack3;
attribute vec4 FramePack4; attribute vec4 FramePack5; attribute vec4 FramePack6;
attribute vec4 FramePack7; attribute vec4 FramePack8; attribute vec4 FramePack9;
varying vec3 wNormal;
vec4 position(mat4 transform_projection, vec4 vertex_position) {
  vec3 f1=FramePack1.xyz;
  vec3 f2=vec3(FramePack1.w,FramePack2.x,FramePack2.y);
  vec3 f3=vec3(FramePack2.z,FramePack2.w,FramePack3.x);
  vec3 f4=FramePack3.yzw;
  vec3 f5=FramePack4.xyz;
  vec3 f6=vec3(FramePack4.w,FramePack5.x,FramePack5.y);
  vec3 f7=vec3(FramePack5.z,FramePack5.w,FramePack6.x);
  vec3 f8=FramePack6.yzw;
  vec3 f9=FramePack7.xyz;
  vec3 f10=vec3(FramePack7.w,FramePack8.x,FramePack8.y);
  vec3 f11=vec3(FramePack8.z,FramePack8.w,FramePack9.x);
  vec3 f12=FramePack9.yzw;
  vec3 p=vertex_position.xyz*w0+f1*w1+f2*w2+f3*w3+f4*w4+f5*w5+f6*w6+f7*w7+f8*w8+f9*w9+f10*w10+f11*w11+f12*w12;
  vec4 world=model*vec4(p,1.0);
  wNormal=normalize((model*vec4(VertexNormal,0.0)).xyz);
  return vp*world;
}
]]
local PIXEL=[[
uniform vec4 materialColor;
uniform float useTexture;
uniform float opacity;
uniform float unlit;
uniform float forceOpaque;
uniform float envMode;
uniform vec3 effectTint;
uniform vec3 uvRow0;
uniform vec3 uvRow1;
varying vec3 wNormal;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
  vec3 nn=normalize(wNormal);
  vec2 envUV=vec2(nn.x*0.5+0.5,0.5-nn.y*0.5);
  vec3 uvh=vec3(uv,1.0);
  vec2 sourceUV=vec2(dot(uvRow0,uvh),dot(uvRow1,uvh));
  vec4 t=Texel(texture,mix(sourceUV,envUV,envMode));
  float texA=mix(1.0,t.a,useTexture);
  float a=mix(texA,1.0,forceOpaque)*materialColor.a*opacity*color.a;
  if (a<0.025) discard;
  // Keep the source effect's keyed colour on textured groups too. Its RGB was
  // previously folded into materialColor, then discarded by this texture mix.
  vec3 base=mix(materialColor.rgb,t.rgb,useTexture)*effectTint;
  if (unlit > 0.5) return vec4(base,a);
  vec3 n=normalize(wNormal);
  vec3 l=normalize(vec3(-0.38,0.84,0.39));
  float key=0.70+0.30*abs(dot(n,l));
  return vec4(base*key,a);
}
]]
local shaderStatic,shaderMorph
local modelUseSerial=0
local runtimeMeshHits,runtimeMeshWrites,runtimeMeshFallbacks=0,0,0
local hardCacheQueue,hardCacheSeen={},{}
local hardCacheState={running=false,total=0,done=0,failed=0,last=nil}
local hardCacheRetries={}
local HARD_CACHE_ROW_RETRIES=1

local function key(inst,entry)
local entryKey=entry and (entry.runtimeIdentifier or
(tostring(entry.phase or "?")..":"..tostring(entry.identifier or entry.index or "?"))) or "?"
return tostring(inst and inst.serial or "?")..":"..tostring(entryKey)
end
local function remove(t,k) t[k]=nil end

local function readLua(path)
if not (Assets and type(Assets.read)=="function") then return nil,"generated asset service unavailable" end
local src,err=Assets.read(path);if type(src)~="string" then return nil,err or ("missing "..tostring(path)) end
local f,e=load(src,"@generated/"..tostring(path));if not f then return nil,e end
local ok,v=pcall(f);if not ok then return nil,v end
return v
end
local function imageFromRaw(spec)
if not (spec and spec.path and love and love.image and love.graphics) then return nil end
if H.textureCache[spec.path] then return H.textureCache[spec.path] end
local bytes=Assets and Assets.read and Assets.read(spec.path)
if type(bytes)~="string" then return nil,"missing "..tostring(spec.path) end
local ok,d=pcall(love.image.newImageData,spec.w,spec.h,"rgba8",bytes);if not ok then return nil,d end
local ok2,img=pcall(love.graphics.newImage,d);if not ok2 then return nil,img end
if img.setFilter then pcall(img.setFilter,img,"linear","linear",8) end
if img.setWrap then
local function wn(v) v=tonumber(v) or 0;if v==1 then return "repeat" elseif v==2 then return "mirroredrepeat" end;return "clamp" end
pcall(img.setWrap,img,wn(spec.wrapS),wn(spec.wrapT))
end
H.textureCache[spec.path]=img
return img
end
local function ensureShader(morph)



local current
if morph then current=shaderMorph else current=shaderStatic end
if current then return current end
if not (love and love.graphics and love.graphics.newShader) then return nil,"LÖVE shader unavailable" end
local ok,sh=pcall(love.graphics.newShader,morph and VERTEX_MORPH or VERTEX_STATIC,PIXEL)
if not ok then return nil,sh end
if morph then shaderMorph=sh else shaderStatic=sh end
return sh
end

local function decodedVertices(group,expectedStride,checkpoint)
if type(group)~="table" then return nil,"Waza vertex group missing" end
if type(group.vertices)=="table" then return group.vertices end
local packed=group.verticesPacked
if type(packed)~="string" then return nil,"Waza packed vertex payload missing" end
local stride=tonumber(group.vertexStride) or tonumber(expectedStride) or 8
if stride~=expectedStride then
return nil,("Waza vertex stride %s does not match expected %s"):format(tostring(stride),tostring(expectedStride))
end
local rows={}
for line in packed:gmatch("[^\r\n]+") do
local row={}
for token in line:gmatch("[^,]+") do
local n=tonumber(token);if n==nil then return nil,"Waza packed vertex contains non-number" end
row[#row+1]=n
end
if #row~=stride then return nil,("Waza packed vertex row has %d scalars; expected %d"):format(#row,stride) end
rows[#rows+1]=row
if checkpoint and #rows%128==0 then checkpoint() end
end
if #rows==0 then return nil,"Waza packed vertex payload empty" end
group.vertices=rows;group.verticesPacked=nil
return rows
end




local RUNTIME_MESH_VERSION=2
local function extractorRevision()
local x=V and V.MoveFXExtractor
return tonumber(x and (x.runtimeRevision or x.revision)) or 0
end
local function runtimeRoot(path)
return tostring(path or "cache/waza/model_cache.lua"):gsub("%.lua$","").."_runtime_v2_r"..extractorRevision()
end
local function runtimeMetaPath(path) return runtimeRoot(path).."/base.lua" end
local function runtimeBinPath(path,i) return runtimeRoot(path)..("/base_%02d.f32"):format(tonumber(i) or 0) end
local function sourceSize(path) local info=Assets and Assets.info and Assets.info(path) or nil;return info and tonumber(info.size) or nil end
local function runtimeUsable(meta,path,size)
if type(meta)~="table" or tonumber(meta.runtimeMeshVersion)~=RUNTIME_MESH_VERSION
or meta.sourcePath~=path or tonumber(meta.extractorRevision)~=extractorRevision()
or type(meta.groups)~="table" or #meta.groups==0 then return false end
local recorded=tonumber(meta.sourceSize)
if size and recorded~=size then return false end
local stride=(tonumber(meta.morphFrames) or 0)>0 and 44 or 8;local bpv=stride*4
for i,g in ipairs(meta.groups) do
local expected=runtimeBinPath(path,i)
if type(g)~="table" or (g.runtimeBin~=nil and g.runtimeBin~=expected) then return false end
local bin=g.runtimeBin or expected
local info=Assets and Assets.info and Assets.info(bin) or nil
if not info then return false end
local n=tonumber(info.size)
local count=tonumber(type(g)=="table" and g.vertexCount)
if not count or count<3 or count%3~=0 or count~=math.floor(count) then return false end
if n and n~=count*bpv then return false end
end
return true
end
local function compactGroup(g,path,i)
local o={};for k,v in pairs(g or {}) do if k~="vertices" and k~="verticesPacked" then o[k]=v end end
o.runtimeBin=runtimeBinPath(path,i)
o.vertexCount=type(g.vertices)=="table" and #g.vertices or tonumber(g.vertexCount)
return o
end
local function writeRuntimeMeta(path,cache,size,preserveExisting)
if not (RuntimeMeshCache and RuntimeMeshCache.writeLua) then return false end
local o={}
for k,v in pairs(cache or {}) do if k~="groups" then o[k]=v end end
o.runtimeMeshVersion=RUNTIME_MESH_VERSION;o.sourcePath=path;o.extractorRevision=extractorRevision()
o.sourceSize=size
o.groups={};for i,g in ipairs(cache.groups or {}) do o.groups[i]=compactGroup(g,path,i) end
local ok=RuntimeMeshCache.writeLua(runtimeMetaPath(path),o,preserveExisting);if ok then runtimeMeshWrites=runtimeMeshWrites+1 end;return ok
end

local function loadCache(path)
if not path then return nil,"Waza model cache missing" end
if H.modelCache[path]~=nil then
local hit=H.modelCache[path]
if type(hit)=="table" then modelUseSerial=modelUseSerial+1;hit.__cbeUse=modelUseSerial end
return hit or nil,H.modelErrors[path]
end
if not (love and love.graphics and love.graphics.newMesh) then return nil,"LÖVE mesh API unavailable" end
local size=sourceSize(path)
local cache,err,fromRuntime
local preserveWazaRuntime=false
if RuntimeMeshCache and type(RuntimeMeshCache.readLua)=="function" then
local rtPath=runtimeMetaPath(path)
local rt=select(1,RuntimeMeshCache.readLua(rtPath))
preserveWazaRuntime=rt~=nil or (type(RuntimeMeshCache.exists)=="function" and RuntimeMeshCache.exists(rtPath)) or false
if runtimeUsable(rt,path,size) then cache=rt;fromRuntime=true;runtimeMeshHits=runtimeMeshHits+1 end
end
if not cache then cache,err=readLua(path) end
if not cache then H.modelCache[path]=false;H.modelErrors[path]=tostring(err);return nil,err end
local morph=(tonumber(cache.morphFrames) or 0)>0
local fmt=morph and FORMAT_MORPH or FORMAT_STATIC
local textures,groups={},{}
local commit=V.WorkBudget and V.WorkBudget.onCancel(function()
for _,g in ipairs(groups) do if g.mesh and g.mesh.release then pcall(g.mesh.release,g.mesh) end end
for _,img in pairs(textures) do if img.release then pcall(img.release,img) end end
end) or function() end
local canonicalFallback=nil
for i,g in ipairs(cache.groups or {}) do
checkpoint("Uploading move effect material "..i)
local img
if g.texture then
local tp=g.texture.path;img=textures[tp]
if not img then
local why;img,why=imageFromRaw(g.texture)
if not img then H.modelCache[path]=false;H.modelErrors[path]=tostring(why);return nil,why end
textures[tp]=img
end
end
local stride=morph and 44 or 8
local mesh,vErr,vertices
if fromRuntime and RuntimeMeshCache and type(RuntimeMeshCache.meshFromPath)=="function" then
mesh,vErr=RuntimeMeshCache.meshFromPath(fmt,g.runtimeBin or runtimeBinPath(path,i),stride,"static")
end
if not mesh then
local sourceGroup=g





if fromRuntime and type(g.vertices)~="table" and type(g.verticesPacked)~="string" then
if canonicalFallback==nil then canonicalFallback=select(1,readLua(path)) or false end
if canonicalFallback and canonicalFallback.groups and canonicalFallback.groups[i] then
sourceGroup=canonicalFallback.groups[i];runtimeMeshFallbacks=runtimeMeshFallbacks+1
end
end
vertices,vErr=decodedVertices(sourceGroup,stride,checkpoint)
if not vertices then H.modelCache[path]=false;H.modelErrors[path]=tostring(vErr);return nil,vErr end
local ok,built=pcall(love.graphics.newMesh,fmt,vertices,"triangles","static")
if not ok then H.modelCache[path]=false;H.modelErrors[path]=tostring(built);return nil,built end
mesh=built
if RuntimeMeshCache and RuntimeMeshCache.supported and RuntimeMeshCache.supported() then RuntimeMeshCache.writeRows(runtimeBinPath(path,i),vertices,stride,checkpoint,preserveWazaRuntime) end
end
if img then mesh:setTexture(img) end
local effectLike=g.effect==true or (g.useConstant==true and g.useDiffuseLighting==false)
groups[#groups+1]={mesh=mesh,image=img,diffuse=g.diffuse or {1,1,1},alpha=tonumber(g.alpha) or 1,
xlu=g.xlu==true,noz=g.noz==true,renderFlags=tonumber(g.renderFlags) or 0,textureTexgen=g.textureTexgen,
shadow=g.shadow==true,effect=g.effect==true,useConstant=g.useConstant==true,
useVertexColor=g.useVertexColor==true,useDiffuseLighting=g.useDiffuseLighting~=false,



luminous=effectLike}
end
if #groups==0 then H.modelCache[path]=false;H.modelErrors[path]="Waza model cache empty";return nil,H.modelErrors[path] end
if not fromRuntime and RuntimeMeshCache and RuntimeMeshCache.packSupported and RuntimeMeshCache.packSupported() then
local all=true;local bpv=(morph and 44 or 8)*4
for i=1,#(cache.groups or {}) do local info=Assets.info and Assets.info(runtimeBinPath(path,i)) or nil;local n=info and tonumber(info.size);if not info or (n and (n<bpv or n%bpv~=0)) then all=false;break end end
if all then writeRuntimeMeta(path,cache,size,preserveWazaRuntime) end
end
local out={groups=groups,bounds=cache.bounds,source=cache.source,textures=textures,morph=morph,
morphFrames=tonumber(cache.morphFrames) or 0,startFrame=tonumber(cache.startFrame) or 0,endFrame=tonumber(cache.endFrame) or 0,
animation=cache.animation,textureAnimation=cache.textureAnimation,materialAnimation=cache.materialAnimation}
modelUseSerial=modelUseSerial+1;out.__cbeUse=modelUseSerial
commit();H.modelCache[path]=out;H.modelErrors[path]=nil;return out
end





local function bakeRuntimeCache(path,checkpoint)
local size=sourceSize(path)
local preserveRuntime=false
if RuntimeMeshCache and type(RuntimeMeshCache.readLua)=="function" then
local metaPath=runtimeMetaPath(path)
local meta=select(1,RuntimeMeshCache.readLua(metaPath))
if runtimeUsable(meta,path,size) then return true,"ready" end
preserveRuntime=meta~=nil or (type(RuntimeMeshCache.exists)=="function" and RuntimeMeshCache.exists(metaPath)) or false
end
if not (RuntimeMeshCache and RuntimeMeshCache.packSupported and RuntimeMeshCache.packSupported()) then return false,"float32 pack API unavailable" end
local cache,err=readLua(path);if type(cache)~="table" then return false,err end
local stride=(tonumber(cache.morphFrames) or 0)>0 and 44 or 8
for i,g in ipairs(cache.groups or {}) do
local rows,why=decodedVertices(g,stride,checkpoint);if not rows then return false,why end
local ok,werr=RuntimeMeshCache.writeRows(runtimeBinPath(path,i),rows,stride,checkpoint,preserveRuntime);if not ok then return false,werr end
end
if #(cache.groups or {})==0 then return false,"Waza model cache empty" end
local ok=writeRuntimeMeta(path,cache,size,preserveRuntime)
if RuntimeMeshCache.invalidateLua then RuntimeMeshCache.invalidateLua(runtimeMetaPath(path)) end
return ok==true,ok and "baked" or "metadata write failed"
end

local function collectHardCachePaths(value,depth,seenTables)
depth=(depth or 0)+1;if depth>14 or type(value)~="table" then return end
seenTables=seenTables or {};if seenTables[value] then return end;seenTables[value]=true
for k,v in pairs(value) do
if k=="cache" and type(v)=="string" and v:match("^cache/movefx/") and v:match("%.lua$") then
if not hardCacheSeen[v] then hardCacheSeen[v]=true;hardCacheQueue[#hardCacheQueue+1]=v end
elseif type(v)=="table" then collectHardCachePaths(v,depth,seenTables) end
end
end



local function loadPartsCache(path,retry)
local data=H.partsCache[path]
if data==false and retry then H.partsCache[path]=nil;H.modelErrors[path]=nil;data=nil end
if data==nil then
local why;data,why=readLua(path)
if not (type(data)=="table" and data.revision==1 and type(data.tracks)=="table") then
H.modelErrors[path]=tostring(why or "invalid effect-model parts cache");H.partsCache[path]=false
return nil,H.modelErrors[path]
end
H.partsCache[path]=data;H.modelErrors[path]=nil
end
if data==false then return nil,H.modelErrors[path] end
return data
end
function H.specPrepared(spec)
if not H.preparedSpecs or not H.preparedSpecs[spec] then return false end
for _,path in ipairs(H.preparedSpecs[spec]) do
if not H.modelCache[path] then return false end
end
for _,path in ipairs(H.preparedSpecs[spec].parts or {}) do
if not H.partsCache[path] then return false end
end
return true
end
function H.prewarmSpec(spec)
local paths,partPaths,seen={},{},{}
local function visit(value,depth)
if type(value)~="table" or depth>14 or seen[value] then return end
seen[value]=true
for key,row in pairs(value) do
if key=="cache" and value.transformOnly~=true and type(row)=="string" and row:match("^cache/movefx/") and row:match("%.lua$") then
if not seen[row] then
seen[row]=true;checkpoint("Preparing move model "..row)
local model,why=loadCache(row)
if not model then error(tostring(why),0) end
paths[#paths+1]=row
end
elseif type(row)=="table" then
if key=="parts" and type(row.path)=="string" and row.path:match("^cache/movefx/") and row.path:match("%.lua$") and not seen[row.path] then
seen[row.path]=true;checkpoint("Preparing move model parts "..row.path)
local parts,why=loadPartsCache(row.path,true)
if not parts then error(tostring(why),0) end
partPaths[#partPaths+1]=row.path
end
visit(row,depth+1)
end
end
end
visit(spec,0)
H.preparedSpecs=H.preparedSpecs or setmetatable({},{__mode='k'})
paths.parts=partPaths
H.preparedSpecs[spec]=paths
return true
end

local hardTask=nil
local hardDeadline=0
local hardCacheHead=1
local function hardPending()
return math.max(0,#hardCacheQueue-hardCacheHead+1)
end
local function hardClock()
if love and love.timer and love.timer.getTime then return love.timer.getTime() end
return os.clock()
end
local function hardCheckpoint()
if hardClock()>=hardDeadline then coroutine.yield("cpu-slice") end
end
local function hardSlice()
return MOBILE_RUNTIME and 0.003 or 0.006
end
function H.queueHardCacheSpecs(specs)
hardTask=nil
hardCacheQueue={};hardCacheHead=1;hardCacheSeen={};hardCacheRetries={};hardCacheState={running=false,total=0,done=0,failed=0,last=nil}
for _,spec in ipairs(type(specs)=="table" and specs or {}) do collectHardCachePaths(spec,0,{}) end
hardCacheState.total=#hardCacheQueue;hardCacheState.running=#hardCacheQueue>0
return #hardCacheQueue
end
function H.pumpHardCache(maxItems)
maxItems=math.max(1,math.floor(tonumber(maxItems) or 1));local n=0
hardDeadline=hardClock()+hardSlice()





while n<maxItems and hardCacheHead<=#hardCacheQueue do
local path=hardCacheQueue[hardCacheHead]
if not hardTask then hardTask=coroutine.create(function() return bakeRuntimeCache(path,hardCheckpoint) end) end
local resumed,ok,why=coroutine.resume(hardTask)
if resumed and coroutine.status(hardTask)~="dead" then break end
hardTask=nil;hardCacheHead=hardCacheHead+1;n=n+1
hardCacheState.last=path
if resumed and ok then hardCacheState.done=hardCacheState.done+1
else
local reason=tostring(resumed and why or ok)
local retries=(hardCacheRetries[path] or 0)+1;hardCacheRetries[path]=retries
if retries<=HARD_CACHE_ROW_RETRIES then



hardCacheState.retried=(hardCacheState.retried or 0)+1
hardCacheState.lastRetry=path;hardCacheState.lastRetryError=reason
hardCacheQueue[#hardCacheQueue+1]=path
else
hardCacheState.failed=hardCacheState.failed+1
hardCacheState.lastFailed=path;hardCacheState.lastError=reason
H.modelErrors[path]=reason
end
end
if hardClock()>=hardDeadline then break end
end
local pending=hardPending()
hardCacheState.running=pending>0
if pending==0 then hardCacheQueue={};hardCacheHead=1;hardCacheRetries={} end
return {processed=n,pending=pending,running=hardCacheState.running,done=hardCacheState.done,failed=hardCacheState.failed}
end
function H.cancelHardCache() hardTask=nil;hardCacheQueue={};hardCacheHead=1;hardCacheSeen={};hardCacheRetries={};hardCacheState.running=false end

function H.hardCacheStatus()
return {running=hardCacheState.running,pending=hardPending(),total=hardCacheState.total,done=hardCacheState.done,failed=hardCacheState.failed,last=hardCacheState.last,
lastFailed=hardCacheState.lastFailed,lastError=hardCacheState.lastError,retried=hardCacheState.retried or 0,
lastRetry=hardCacheState.lastRetry,lastRetryError=hardCacheState.lastRetryError}
end

local function pageForAsset(asset,localFrame)
local anim=type(asset)=="table" and asset.animation
if not (type(anim)=="table" and anim.animated==true and type(anim.pages)=="table" and #anim.pages>0) then
return asset and asset.cache,nil
end
local f=math.max(0,tonumber(localFrame) or 0)
local selected=anim.pages[#anim.pages]
for _,page in ipairs(anim.pages) do
if f>= (tonumber(page.startFrame) or 0) and f<= (tonumber(page.endFrame) or math.huge) then selected=page;break end
end
return selected and selected.cache,selected
end

local function loadModel(asset,localFrame)
local path,page=pageForAsset(asset,localFrame)
local model,err=loadCache(path)
if not model and page and asset and asset.cache then model,err=loadCache(asset.cache);page=nil end
if model then model.asset=asset end
return model,err,page
end

local function morphWeights(page,localFrame)
local w={0,0,0,0,0,0,0,0,0,0,0,0,0}
if not page then w[1]=1;return w end
local start=tonumber(page.startFrame) or 0
local n=math.max(0,math.min(12,tonumber(page.morphFrames) or ((tonumber(page.endFrame) or start)-start)))
if n<=0 then w[1]=1;return w end
local x=math.max(0,math.min(n,(tonumber(localFrame) or 0)-start))
local i=math.floor(x);local t=x-i
if i>=n then w[n+1]=1
else w[i+1]=1-t;w[i+2]=t end
return w
end
local UV_IDENTITY={1,0,0,0,1,0}
local function textureAnimationSample(model,groupIndex,localFrame)
local anim=type(model)=="table" and model.textureAnimation or nil
if not anim and type(model)=="table" and type(model.asset)=="table" then anim=model.asset.textureAnimation end
local frames=type(anim)=="table" and type(anim.groups)=="table" and anim.groups[groupIndex] or nil
if type(frames)~="table" or #frames==0 then return UV_IDENTITY end
local last=math.max(0,math.min(#frames-1,math.floor(tonumber(anim.endFrame) or (#frames-1))))
local x=math.max(0,math.min(last,tonumber(localFrame) or 0))
local i=math.floor(x);local t=x-i
local a=frames[i+1] or frames[1] or UV_IDENTITY
local b=frames[math.min(last,i+1)+1] or a
if t<=0 then return a end
local out={};for k=1,6 do out[k]=(tonumber(a[k]) or UV_IDENTITY[k])+((tonumber(b[k]) or UV_IDENTITY[k])-(tonumber(a[k]) or UV_IDENTITY[k]))*t end
return out
end
local function materialAnimationSample(model,groupIndex,localFrame)
local anim=type(model)=="table" and model.materialAnimation or nil
if not anim and type(model)=="table" and type(model.asset)=="table" then anim=model.asset.materialAnimation end
local frames=type(anim)=="table" and type(anim.groups)=="table" and anim.groups[groupIndex] or nil
if type(frames)~="table" or #frames==0 then return nil end
local last=math.max(0,math.min(#frames-1,math.floor(tonumber(anim.endFrame) or (#frames-1))))
local x=math.max(0,math.min(last,tonumber(localFrame) or 0))
local i=math.floor(x);local t=x-i
local a=frames[i+1] or frames[1];local b=frames[math.min(last,i+1)+1] or a
if t<=0 then return a end
local function lerp(u,v) return (tonumber(u) or 0)+((tonumber(v) or tonumber(u) or 0)-(tonumber(u) or 0))*t end
local out={alpha=lerp(a.alpha,b.alpha)}
for _,key in ipairs({"diffuse","ambient","specular"}) do
if type(a[key])=="table" then
out[key]={};for n=1,3 do out[key][n]=lerp(a[key][n],b[key] and b[key][n]) end
end
end
return out
end
local function modelSpan(model,basis)
local b=model and (model.normalizationBounds or model.bounds)
local mn,mx=b and b.min,b and b.max
if not (mn and mx) then return 16 end
local sx=math.abs((tonumber(mx[1]) or 0)-(tonumber(mn[1]) or 0))
local sy=math.abs((tonumber(mx[2]) or 0)-(tonumber(mn[2]) or 0))
local sz=math.abs((tonumber(mx[3]) or 0)-(tonumber(mn[3]) or 0))
if basis and basis.groundField then return math.max(.001,sx,sz) end
return math.max(.001,sx,sy,sz)
end







local function partTransformSelector(positionType)
local pt=tonumber(positionType)
if not pt then return 0 end
pt=math.floor(pt)
return (pt>=0 and pt<=6) and (pt+1) or 0
end
local function filteredPartTransform(part,positionType)
if type(part)~="table" then return nil,0 end
local selector=partTransformSelector(positionType)
if selector==0 then return nil,selector end



local inheritPosition=(selector==1 or selector==4 or selector==6 or selector==7)
local inheritRotation=(selector==2 or selector==4 or selector==5 or selector==7)
local inheritScale=(selector==3 or selector==5 or selector==6 or selector==7)
local out={};for i=1,12 do out[i]=tonumber(part[i]) or 0 end
local scales={}
for c=1,3 do
local x,y,z=out[c],out[c+4],out[c+8];local n=math.sqrt(x*x+y*y+z*z)
scales[c]=n>1e-9 and n or 1
end
if inheritRotation then
if not inheritScale then
for c=1,3 do local n=scales[c];out[c]=out[c]/n;out[c+4]=out[c+4]/n;out[c+8]=out[c+8]/n end
end
else
for r=1,3 do for c=1,3 do out[(r-1)*4+c]=(r==c) and (inheritScale and scales[c] or 1) or 0 end end
end
if not inheritPosition then out[4],out[8],out[12]=0,0,0 end
return out,selector
end
local function linkedParticleBirthTransform(part,positionType,flags)
local selector=partTransformSelector(positionType)








local state=math.floor((tonumber(flags) or 0)/2)%2
if state==0 then return nil,selector,state end
local transform=filteredPartTransform(part,positionType)
return transform,selector,state
end
local function modelMatrix(basis,model,asset)
local o,r,u,f=basis.origin,basis.right,basis.up,basis.forward






if basis.sourceStrict or basis.aimed or basis.fieldWave or (asset and asset.transformOnly) then
local v=basis.sourceUnits
return {r[1]*v.x,u[1]*v.y,f[1]*v.z,o[1],r[2]*v.x,u[2]*v.y,f[2]*v.z,o[2],r[3]*v.x,u[3]*v.y,f[3]*v.z,o[3],0,0,0,1}
end
local desired=math.max(.10,tonumber(basis.modelTargetSpan) or tonumber(basis.referenceVisualHeight) or 16)
local span=modelSpan(asset or (model and model.asset) or model,basis)
local s=math.max(.01,math.min(24,desired/span))
return {
r[1]*s,u[1]*s,f[1]*s,o[1],
r[2]*s,u[2]*s,f[2]*s,o[2],
r[3]*s,u[3]*s,f[3]*s,o[3],
0,0,0,1,
}
end




function H.linkedParticleFrame(ctx,inst,entry)
if not (inst and entry and (tonumber(entry.flags) or 0)%2==1) then return nil end
local wanted=tonumber(entry.linkedEntryKey)
if not wanted or wanted<=0 then return nil,"invalid linked effect-model identity" end
local linked
for _,state in ipairs(inst.entries or {}) do
local e=state.entry
if e and e.phase==entry.phase and tonumber(e.identifier)==wanted and e.kind=="model" then linked=state;break end
end
if not linked or not linked.started then return nil,"linked effect-model has not started" end
local e=linked.entry;local asset=e.modelAsset;local desc=asset and asset.parts
if not (desc and desc.path) then return nil,"linked effect-model parts cache unavailable" end
local data,why=loadPartsCache(desc.path)
if not data then return nil,why end
local track=data.tracks[tonumber(entry.partIndex)]
if not (track and track[1]) then return nil,"requested effect-model part is absent" end
local frame=math.max(0,math.min(tonumber(data.endFrame) or 0,
sourceModelFrame((tonumber(inst.frame) or 0)-(tonumber(linked.startFrame) or 0))))
local first=math.floor(frame)+1;local a=track[first] or track[#track];local b=track[first+1] or a;local t=frame-math.floor(frame)
local part={};for k=1,12 do part[k]=a[k]+(b[k]-a[k])*t end
local originSide=inst.role=="damage" and inst.target or inst.side
local otherSide=originSide==inst.side and inst.target or inst.side
local basis=CSM:wazaBasis(ctx,originSide,otherSide,e.attachment,{moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),
style=inst.spec and inst.spec.style,role=inst.role,sourceStrict=true,positionType=e.positionType,flags=e.flags,modelEntry=e})
if not basis then return nil,"linked effect-model world basis unavailable" end
local m=modelMatrix(basis,nil,asset)
local function column(i)
local x,y,z=m[i],m[i+4],m[i+8];local n=math.sqrt(x*x+y*y+z*z)
if n<1e-9 then return nil end
return {x/n,y/n,z/n},n
end
local right,x=column(1);local up,y=column(2);local forward,z=column(3)
if not (right and up and forward) then return nil,"singular linked effect-model transform" end
basis.origin={m[4],m[8],m[12]};basis.right=right;basis.up=up;basis.forward=forward
local particleTransform,selector,linkState=linkedParticleBirthTransform(part,entry.positionType,entry.flags)



local pt=tonumber(entry.positionType)
local inheritsScale=pt==2 or pt==4 or pt==5 or pt==6
if basis.sourceUnitsFromOwner and (linkState==0 or not inheritsScale)
and type(CSM.sourceOwnerUnit)=='function' then
local unit=CSM:sourceOwnerUnit(basis.actor,{moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),
role=inst.role,flags=entry.flags,resourceGroup=inst.spec and inst.spec.sourceResourceGroup})
if unit then x,y,z=unit,unit,unit end
end
basis.sourceUnits={x=x,y=y,z=z};basis.modelLinked=true
return {basis=basis,part=part,particleTransform=particleTransform,transformSelector=selector,
particleLinkState=linkState,modelIdentifier=wanted,partIndex=entry.partIndex,frame=frame}
end




local function modelStart(ctx,inst,entry,eventName,state)
local asset=entry and entry.modelAsset
if not (type(asset)=="table" and asset.cache) then
H.modelErrors[key(inst,entry)]=tostring(entry and entry.modelError or "type-2 model asset unavailable")
return false
end


if H.modelCache[asset.cache]==false then H.modelCache[asset.cache]=nil;H.modelErrors[asset.cache]=nil end
local partsPath=asset.parts and asset.parts.path
if partsPath and H.partsCache[partsPath]==false then H.partsCache[partsPath]=nil;H.modelErrors[partsPath]=nil end
local k=key(inst,entry)
H.models[k]={context=ctx,instance=inst,entry=entry,state=state,asset=asset,startedFrame=inst.frame,rawPath=entry.rawPath,
dataOffset=entry.dataOffset,dataSize=entry.dataSize or entry.embeddedSize,dataMagic=entry.dataMagic}
H.lastModel=H.models[k]
return true
end
local function modelUpdate(ctx,inst,entry,frame,state)
local asset=entry and entry.modelAsset
local anim=asset and asset.animation
local localFrame=sourceModelFrame((tonumber(frame) or tonumber(inst.frame) or 0)-(tonumber(state and state.startFrame) or 0))
if type(anim)=="table" and (anim.animated==true or anim.partsAnimated==true or anim.materialAnimated==true or anim.textureAnimated==true) then
return localFrame < (tonumber(anim.endFrame) or 0) and true or "done"
end


return (tonumber(frame) or 0)<(tonumber(inst.sourceEndFrame) or 1) and true or "done"
end
local function modelFinish(ctx,inst,entry) remove(H.models,key(inst,entry));return true end
local function modelCancel(ctx,inst,entry) remove(H.models,key(inst,entry));return true end
local function opaqueFinish() return true end

local function controllerSide(inst)
if not inst then return "player" end

return (inst.role=="damage" and inst.target) or inst.side or "player"
end
local function controllerState(inst)
local side=controllerSide(inst);H.controllers[side]=H.controllers[side] or {};return H.controllers[side],side
end






local function type1Start(ctx,inst,entry,event,state)
local mode=tonumber(entry.subtype) or 0;if mode<0 or mode>3 then return false end





state.controllerImmediate=(mode==1 or mode==2)
local delay=(mode==0) and math.max(0,math.floor(tonumber(entry.controllerParam) or 0)) or 0
state.controllerDelay=delay;state.controllerMode=mode
return true
end
local function type1Update(ctx,inst,entry,frame,state)
if state.controllerImmediate then return "done" end
local elapsed=(tonumber(frame) or 0)-(tonumber(state.startFrame) or 0)
if elapsed < (tonumber(state.controllerDelay) or 0) then return true end
if Waza and type(Waza.requestStop)=="function" then Waza:requestStop(inst,"type1-sequence-boundary") end
return "done"
end







local function type6Start(ctx,inst,entry)
local st,side=controllerState(inst);local op=tonumber(entry.subtype)
if op==0 then st.ownerAuxEffect=true
elseif op==1 then st.ownerAuxEffect=false
elseif op==2 then st.hidden=true
elseif op==3 then st.hidden=false
elseif op==4 then st.rootNull=false
elseif op==5 then st.rootNull=true;st.ownerAnimationRefresh=(tonumber(st.ownerAnimationRefresh) or 0)+1
elseif op==6 then st.rootNull=false;st.ownerAnimationRefresh=(tonumber(st.ownerAnimationRefresh) or 0)+1
elseif op==7 then st.motionFrozen=true;st.fieldAuxEffect=true
elseif op==8 then st.motionFrozen=false;st.fieldAuxEffect=false;st.ownerAnimationRefresh=(tonumber(st.ownerAnimationRefresh) or 0)+1
elseif op==9 then
if Waza and type(Waza.requestStop)=="function" then Waza:requestStop(inst,"type6-sequence-cleanup") end
else return false end
st.lastOp=op;st.lastOpAlias=entry.controllerOp;st.serial=inst.serial;st.frame=inst.frame;st.side=side
return true
end

function H.actorVisible(_,side)
local st=H.controllers[tostring(side or "")]
if st and st.hidden==true then return false end
return nil
end
function H.actorControllerState(_,side) return H.controllers[tostring(side or "")] end

local function effectStart(ctx,inst,entry,event,state)
local family=tonumber(entry.effectType);if not family or family<0 or family>12 then return false end
local k=key(inst,entry);local duration=math.max(1,math.floor(tonumber(entry.effectFrames) or tonumber(entry.effect and entry.effect.frames) or 1))
local rec={context=ctx,instance=inst,entry=entry,state=state,family=family,effect=entry.effect or {},startedFrame=inst.frame,duration=duration,assets=entry.effectAssets or {},history={}}
rec.textureSpec=entry.effectTextureAsset
if not rec.textureSpec then for _,a in ipairs(rec.assets) do if type(a)=="table" and type(a.texture)=="table" then rec.textureSpec=a.texture;break end end end
H.effects[k]=rec;state.effectEndFrame=(tonumber(state.startFrame) or inst.frame)+duration
if type(entry.effectModelAsset)=="table" and entry.effectModelAsset.cache then
local path=entry.effectModelAsset.cache
if H.modelCache[path]==false then H.modelCache[path]=nil;H.modelErrors[path]=nil end
H.models[k]={context=ctx,instance=inst,entry=entry,state=state,asset=entry.effectModelAsset,startedFrame=inst.frame,rawPath=entry.rawPath,effectRec=rec}
end
return true
end
local function effectUpdate(ctx,inst,entry,frame,state)
return ((tonumber(frame) or 0)<(tonumber(state.effectEndFrame) or ((tonumber(state.startFrame) or 0)+1))) and true or "done"
end
local function releaseDynamicMeshes(rec)
for _,mesh in pairs(rec and rec.dynamicMeshes or {}) do if mesh and mesh.release then pcall(mesh.release,mesh) end end
if rec then rec.dynamicMeshes=nil end
end



local function surfaceHolds(rec)
if not (rec and tonumber(rec.family)==0) then return false end
local e=rec.effect or {};local mode=tonumber(e.mode)
if mode~=1 and mode~=2 then return false end
local keys=e.keys;local last=type(keys)=="table" and keys[#keys] or nil
return type(last)=="table" and (tonumber(last.duration) or 0)>=100000
end
H._surfaceHolds=surfaceHolds
local function effectFinish(ctx,inst,entry,reason)
local k=key(inst,entry);local rec=H.effects[k]
releaseDynamicMeshes(rec)
H.models[k]=nil
if rec and surfaceHolds(rec) and inst and not inst.done and reason=="entry-update-complete" then
rec.surfaceHeld=true;return true
end
H.effects[k]=nil;return true
end

function H.install()
if H.installed or not (Waza and type(Waza.registerHandler)=="function") then return false end
Waza:registerHandler("model","cbe-waza-model",{start=modelStart,update=modelUpdate,finish=modelFinish,cancel=modelCancel})



if Audio then
Waza:registerHandler("sound","cbe-waza-audio",{
start=function(...) return Audio:start(...) end,
update=function(...) return Audio:update(...) end,
finish=function(...) return Audio:finish(...) end,
cancel=function(...) return Audio:cancel(...) end})
end
Waza:registerHandler("type1","cbe-waza-controller",{start=type1Start,update=type1Update,finish=opaqueFinish,cancel=opaqueFinish})
Waza:registerHandler("type4","cbe-waza-tracefx",{start=effectStart,update=effectUpdate,finish=effectFinish,cancel=effectFinish})
Waza:registerHandler("type6","cbe-waza-owner-controller",{start=type6Start,finish=opaqueFinish,cancel=opaqueFinish})
H.installed=true
return true
end


local function graphicsScope(g,fn)
local okPush,pushErr=pcall(g.push,"all")
if not okPush then return false,nil,pushErr end
local ok,value=pcall(fn)
pcall(g.setShader)
pcall(g.setDepthMode)
pcall(g.pop)
if not ok then return false,nil,value end
return true,value,nil
end

local function relinquishFailedVisual(rec,reason)
local inst=rec and rec.instance
local ownership=V and V.MoveFXOwnership
if not (inst and tonumber(inst.moveId) and ownership and type(ownership.relinquish)=="function") then return false end
local ok,released=pcall(ownership.relinquish,ownership,rec.context or inst.ctx,inst.moveId,reason)
return ok and released==true
end

local function modelRenderFault(rec,grp,err)
local inst=rec and rec.instance
H.drawError=("Type-2 render fault move=%s entry=%s: %s")
:format(tostring(inst and inst.moveId or "?"),tostring(rec and rec.entry and rec.entry.index or "?"),tostring(err))
H.renderFaults=(tonumber(H.renderFaults) or 0)+1
if type(rec)=="table" then
rec._cbeRenderFaults=(tonumber(rec._cbeRenderFaults) or 0)+1
if rec._cbeRenderFaults==3 then relinquishFailedVisual(rec,H.drawError) end
end
if type(grp)=="table" then
grp._cbeRenderFaults=(tonumber(grp._cbeRenderFaults) or 0)+1
if grp._cbeRenderFaults>=3 then grp._cbeRenderDisabled=true end
end
end

local function effectRGBA(c,alpha)
c=type(c)=="table" and c or {255,255,255,255};local a=(tonumber(c[4]) or 255)/255
return (tonumber(c[1]) or 255)/255,(tonumber(c[2]) or 255)/255,(tonumber(c[3]) or 255)/255,math.max(0,math.min(1,a*(alpha or 1)))
end
local function lerp(a,b,t)return (tonumber(a) or 0)+((tonumber(b) or 0)-(tonumber(a) or 0))*t end
local function effectSides(rec)
local inst=rec and rec.instance;if not inst then return "player","enemy" end
local origin=(inst.role=="damage") and inst.target or inst.side
local other=origin==inst.side and inst.target or inst.side
return origin or "player",other or "enemy"
end
local function sourceBasis(ctx,rec,attachment)
if not (CSM and type(CSM.wazaBasis)=="function") then return nil end
local inst=rec.instance;local originSide,other=effectSides(rec)
local ok,b=pcall(CSM.wazaBasis,CSM,ctx,originSide,other,attachment~=nil and attachment or (rec.entry and rec.entry.attachment),
{moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),style=inst.spec and inst.spec.style,role=inst.role,sourceStrict=true,positionType=rec.entry and rec.entry.positionType,flags=rec.entry and rec.entry.flags})
return ok and b or nil
end
local function sourceLocalPoint(ctx,rec,pos,attachment)
if not (type(pos)=="table" and CSM and type(CSM.wazaLocalPoint)=="function") then return nil end
local inst=rec.instance;local originSide,other=effectSides(rec)
local ok,p=pcall(CSM.wazaLocalPoint,CSM,ctx,originSide,other,attachment~=nil and attachment or (rec.entry and rec.entry.attachment),pos,
{moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),style=inst.spec and inst.spec.style,role=inst.role,sourceStrict=true,positionType=rec.entry and rec.entry.positionType,flags=rec.entry and rec.entry.flags})
return ok and p or nil
end
local function projectSource(ctx,p)
if not (CSM and type(CSM.projectWazaWorld)=="function") then return nil end
local ok,x,y=pcall(CSM.projectWazaWorld,CSM,ctx,p);if ok then return x,y end
end
local function effectProgress(rec)
local inst=rec and rec.instance
local frame=(tonumber(inst and inst.frame) or 0)+(tonumber(inst and inst.accumulator) or 0)*60-(tonumber(rec and rec.startedFrame) or 0)
return math.max(0,math.min(1,frame/math.max(1,tonumber(rec and rec.duration) or 1))),frame
end
local function effectImage(rec)
if rec.image==false then return nil end
if rec.image then return rec.image end
if type(rec.textureSpec)~="table" then rec.image=false;return nil end
local img,err=imageFromRaw(rec.textureSpec)
if not img then H.drawError=("Type-4 source texture load failed family=%s move=%s: %s")
:format(tostring(rec.family),tostring(rec.instance and rec.instance.moveId),tostring(err))
relinquishFailedVisual(rec,H.drawError);rec.image=false;return nil end
rec.image=img;return img
end
local function keyedColor(keys,p,default)


if type(default)~="table" then default={255,255,255,255} end
if type(keys)=="table" and type(keys[1])=="table"
and type(keys[1].from)~="table" and type(keys[1].to)~="table" then return default end
if type(keys)~="table" or #keys==0 then return default end
local total=0
for _,k in ipairs(keys) do local d=tonumber(k.duration) or 0;if d>0 and d<100000 then total=total+d end end
if total<=0 then return keys[#keys].to or keys[1].from or default end
local at=p*total;local elapsed=0
for _,k in ipairs(keys) do
local d=tonumber(k.duration) or 0
if d>0 and d<100000 then
if at<=elapsed+d then
local t=math.max(0,math.min(1,(at-elapsed)/d));local a=type(k.from)=="table" and k.from or default;local b=type(k.to)=="table" and k.to or a
return {lerp(a[1],b[1],t),lerp(a[2],b[2],t),lerp(a[3],b[3],t),lerp(a[4],b[4],t)}
end
elapsed=elapsed+d
end
end


local last=keys[#keys];local ld=tonumber(last and last.duration) or 0
if ld>=100000 and type(last.from)=="table" then return last.from end
return last.to or default
end
local function sourceSurfaceColor(e,p)




e=type(e)=="table" and e or {}
local c=keyedColor(e.keys,p,{128,128,128,255})
local mode=tonumber(e.mode) or 0
local layout=tonumber(e.layoutMode) or 0
local flags=tonumber(e.flags) or 0
local useRgb,useAlpha=true,false
if layout~=1 and layout~=2 then
if math.floor(flags/4)%2==1 then useRgb=false end
if flags%2==1 then useAlpha=true end
end
if mode==0 then useRgb,useAlpha=true,true end
return {
useRgb and (tonumber(c[1]) or 128) or 127,
useRgb and (tonumber(c[2]) or 128) or 127,
useRgb and (tonumber(c[3]) or 128) or 127,
useAlpha and (tonumber(c[4]) or 255) or 255,
}
end








H.sideWorlds=H.sideWorlds or setmetatable({},{__mode="k"})
local function latestSurface(effects,mode,best)
for k,rec in pairs(effects or {}) do
local e=rec.effect or {}
if rec.surfaceHeld and (not rec.instance or rec.instance.done) then effects[k]=nil;e={} end
if tonumber(rec.family)==0 and tonumber(e.mode)==mode then
if not best or (tonumber(rec.startedFrame) or 0)>(tonumber(best.startedFrame) or 0) then best=rec end
end
end
return best
end


function H.ownerModulation(effects)
local best=latestSurface(effects or H.effects,2)
if not best then return nil end
local c=sourceSurfaceColor(best.effect,effectProgress(best))
return {math.max(0,math.min(2,c[1]/128)),math.max(0,math.min(2,c[2]/128)),math.max(0,math.min(2,c[3]/128))},best
end
function H.arenaModulation()
local best=latestSurface(H.effects,1)
for world in pairs(H.sideWorlds) do best=latestSurface(world.effects,1,best) end
if not best then return nil end
local p=effectProgress(best)
local c=sourceSurfaceColor(best.effect,p)
return {c[1]/255,c[2]/255,c[3]/255,c[4]/255},best
end
local function keyedScalar(e,p,default)
local keys=e and e.keys
if type(keys)~="table" or #keys==0 then return tonumber(e and e.value) or default end
local total=0;for _,k in ipairs(keys) do local d=tonumber(k.duration) or 0;if d>0 and d<100000 then total=total+d end end
if total<=0 then return tonumber(keys[#keys].to) or tonumber(keys[1].from) or default end
local at=p*total;local elapsed=0
for _,k in ipairs(keys) do local d=tonumber(k.duration) or 0;if d>0 and d<100000 then
if at<=elapsed+d then return lerp(k.from,k.to,math.max(0,math.min(1,(at-elapsed)/d))) end;elapsed=elapsed+d end end
return tonumber(keys[#keys].to) or default
end
local function angle2(y,x)
if type(math.atan2)=="function" then return math.atan2(y,x) end


local ok,v=pcall(math.atan,y,x);if ok and type(v)=="number" then return v end
if x>0 then return math.atan(y/x) end
if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
return y>0 and math.pi*.5 or (y<0 and -math.pi*.5 or 0)
end
local function drawTexturedSegment(g,img,x1,y1,x2,y2,width)
if not (img and x1 and y1 and x2 and y2) then return false end
local dx,dy=x2-x1,y2-y1;local len=math.sqrt(dx*dx+dy*dy);if len<.25 then return false end
local iw,ih=math.max(1,img:getWidth()),math.max(1,img:getHeight())
g.draw(img,(x1+x2)*.5,(y1+y2)*.5,angle2(dy,dx),len/iw,math.max(.5,tonumber(width) or ih)/ih,iw*.5,ih*.5)
return true
end
local function drawTraceRibbon(g,img,rec,e,p)
local bA=sourceBasis(rec.context or {},rec,e.partA or (rec.entry and rec.entry.attachment))
local bB=sourceBasis(rec.context or {},rec,e.partB or (rec.entry and rec.entry.attachment))
if not (bA and bB and bA.origin and bB.origin) then return false end
local ax,ay=projectSource(rec.context or {},bA.origin);local bx,by=projectSource(rec.context or {},bB.origin)
if not (ax and bx) then return false end
local frame=math.floor((tonumber(rec.instance and rec.instance.frame) or 0)+.5)
if rec.historyFrame~=frame then
rec.historyFrame=frame;rec.history[#rec.history+1]={ax=ax,ay=ay,bx=bx,by=by}
local maxn=math.max(2,math.min(128,tonumber(e.maxSegments) or 24));while #rec.history>maxn do table.remove(rec.history,1) end
end
if #rec.history<2 then return false end
local live=math.max(2,math.min(#rec.history,tonumber(e.liveSegments) or #rec.history))
local first=#rec.history-live+1;local verts={}
for i=first,#rec.history do
local h=rec.history[i];local v=(i-first)/math.max(1,live-1);local fade=.18+.82*v
verts[#verts+1]={h.ax,h.ay,0,v,1,1,1,fade}
verts[#verts+1]={h.bx,h.by,1,v,1,1,1,fade}
end
local fmt={{"VertexPosition","float",2},{"VertexTexCoord","float",2},{"VertexColor","float",4}}
rec.dynamicMeshes=rec.dynamicMeshes or {}
local mesh=rec.dynamicMeshes.trace;local capacity=rec.traceCapacity or 0
if not mesh or #verts>capacity then
if mesh and mesh.release then pcall(mesh.release,mesh) end
capacity=math.min(256,math.max(8,capacity*2,#verts))
local ok,built=pcall(g.newMesh,fmt,capacity,"strip","stream")
if not ok or not built then rec.dynamicMeshes.trace=nil;rec.traceCapacity=nil;return false end
mesh=built;rec.dynamicMeshes.trace=mesh;rec.traceCapacity=capacity
end
local ok=pcall(mesh.setVertices,mesh,verts)
if not ok then return false end
if mesh.setDrawRange then mesh:setDrawRange(1,#verts) end
if img then pcall(mesh.setTexture,mesh,img) end
return pcall(g.draw,mesh)
end

local COLOR_MESH_FORMAT={{"VertexPosition","float",2},{"VertexColor","float",4}}
local function drawDynamicColorMesh(g,rec,slot,verts)
rec.dynamicMeshes=rec.dynamicMeshes or {};local mesh=rec.dynamicMeshes[slot]
if mesh and mesh.setVertices then
local ok=pcall(mesh.setVertices,mesh,verts)
if not ok then if mesh.release then pcall(mesh.release,mesh) end;mesh=nil;rec.dynamicMeshes[slot]=nil end
end
if not mesh then
local ok,built=pcall(g.newMesh,COLOR_MESH_FORMAT,verts,"triangles","stream");if not ok or not built then return false end
mesh=built;rec.dynamicMeshes[slot]=mesh
end
return pcall(g.draw,mesh)
end
local function drawAuraField(g,rec,cx,cy,rx,ry,alpha)
local verts={};local segments=56
for i=0,segments-1 do
local a0=i/segments*math.pi*2;local a1=(i+1)/segments*math.pi*2
verts[#verts+1]={cx,cy,1,1,1,alpha}
verts[#verts+1]={cx+math.cos(a0)*rx,cy+math.sin(a0)*ry,1,1,1,0}
verts[#verts+1]={cx+math.cos(a1)*rx,cy+math.sin(a1)*ry,1,1,1,0}
end
return drawDynamicColorMesh(g,rec,"aura",verts)
end





local function drawProceduralEffects(ctx)
if not (love and love.graphics) then return false end
local g=love.graphics;local drew=false
for _,rec in pairs(H.effects) do
local fam=tonumber(rec.family) or -1;local e=rec.effect or {};local inst=rec.instance;rec.context=ctx
if fam~=2 and fam~=8 and fam~=10 and not (rec.entry and rec.entry.effectModelAsset) then
local b=sourceBasis(ctx,rec);local p=effectProgress(rec)
if b and b.origin and b.target then
local x1,y1=projectSource(ctx,b.origin);local x2,y2=projectSource(ctx,b.target)
if x1 and x2 then
local c=keyedColor(e.keys,p,e.color or e.colorA or {255,255,255,255})
local r,gc,bb,a=effectRGBA(c,1-p*.12)
g.push("all");g.setColor(r,gc,bb,a)
if fam==0 then



elseif fam==1 then



local img=effectImage(rec)
local ws=sourceLocalPoint(ctx,rec,e.start);local we=sourceLocalPoint(ctx,rec,e.endv)
local sx,sy,ex,ey;if ws then sx,sy=projectSource(ctx,ws) end;if we then ex,ey=projectSource(ctx,we) end
sx,sy=sx or x1,sy or y1;ex,ey=ex or x2,ey or y2
local count=math.max(1,math.min(16,tonumber(e.partA) or 3));local depth=math.max(1,math.min(5,tonumber(e.partB) or 2))
if img then
pcall(g.setBlendMode,"add","alphamultiply")
for branch=1,count do
local dx,dy=ex-sx,ey-sy;local len=math.max(1,math.sqrt(dx*dx+dy*dy));local nx,ny=-dy/len,dx/len
local pieces=math.max(3,depth*3)
for j=1,pieces do
local t0=(j-1)/pieces;local t1=j/pieces
local amp=len*(.018+.009*depth)*(1-p*.25)
local j0=(j==1) and 0 or math.sin((branch*37+j*19+(inst.serial or 0)*11)*1.731)*amp
local j1=(j==pieces) and 0 or math.sin((branch*37+(j+1)*19+(inst.serial or 0)*11)*1.731)*amp
local ax=sx+dx*t0+nx*j0;local ay=sy+dy*t0+ny*j0;local bx=sx+dx*t1+nx*j1;local by=sy+dy*t1+ny*j1
drew=drawTexturedSegment(g,img,ax,ay,bx,by,math.max(2,math.abs(tonumber(e.width) or 3))) or drew
end
end
end
elseif fam==3 then


local img=effectImage(rec);local ws=sourceLocalPoint(ctx,rec,e.start);local we=sourceLocalPoint(ctx,rec,e.endv)
local sx,sy,ex,ey;if ws then sx,sy=projectSource(ctx,ws) end;if we then ex,ey=projectSource(ctx,we) end;sx,sy=sx or x1,sy or y1;ex,ey=ex or x2,ey or y2
if img then
pcall(g.setBlendMode,"add","alphamultiply");local dx,dy=ex-sx,ey-sy;local len=math.max(1,math.sqrt(dx*dx+dy*dy));local nx,ny=-dy/len,dx/len
local pieces=math.max(5,math.min(24,tonumber(e.mode) or 10));local lastx,lasty=sx,sy
for j=1,pieces do local t=j/pieces;local amp=len*.035*(1-.35*p);local jitter=(j==pieces) and 0 or math.sin((j*29+(inst.serial or 0)*13)*2.07)*amp
local nxp=sx+dx*t+nx*jitter;local nyp=sy+dy*t+ny*jitter;drew=drawTexturedSegment(g,img,lastx,lasty,nxp,nyp,math.max(3,math.abs(tonumber(e.values and e.values[1]) or 4))) or drew;lastx,lasty=nxp,nyp end
end
elseif fam==4 then
local img=effectImage(rec);if img then pcall(g.setBlendMode,"alpha","alphamultiply");drew=drawTraceRibbon(g,img,rec,e,p) or drew end
elseif fam==9 then


pcall(g.setBlendMode,"add","alphamultiply");local v=math.abs(keyedScalar(e,p,1));local rad=math.max(10,math.min(180,22+v*18))*(.72+.28*math.sin(math.pi*p))
g.setColor(r,gc,bb,1);drew=drawAuraField(g,rec,x1,y1,rad,rad*1.28,a*.34) or drew
elseif fam==12 then


local img=effectImage(rec);if img then
pcall(g.setBlendMode,"alpha","alphamultiply")
local scale=math.max(.08,math.min(8,math.abs(tonumber(e.a) or 1)*(0.7+0.3*math.sin(math.pi*p))))
g.draw(img,x2,y2,(tonumber(e.b) or 0)*p,scale,scale,img:getWidth()*.5,img:getHeight()*.5);drew=true
end
end
g.pop()
end
end
end
end
return drew
end

local DISTORT_SHADER=[[
extern number amount;
extern number frequency;
extern number phase;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
  vec2 q=uv;
  q.x += sin((uv.y+phase)*frequency)*amount;
  q.y += sin((uv.x+phase*0.73)*frequency*0.81)*amount*0.55;
  return Texel(texture,q)*color;
}
]]
local function releasePost()
for _,c in ipairs({H.postCanvas,H.postHistory}) do if c and c.release then pcall(c.release,c) end end
H.postCanvas=nil;H.postHistory=nil;H.postW=0;H.postH=0;H.postHistoryValid=false
end
local function ensurePost(w,h)
if H.postCanvas and H.postHistory and H.postW==w and H.postH==h then return true end
releasePost()
if not (love and love.graphics and love.graphics.newCanvas) then return false end
local ok,a=pcall(love.graphics.newCanvas,w,h,{dpiscale=1,msaa=0});if not ok then ok,a=pcall(love.graphics.newCanvas,w,h) end
if not ok or not a then return false end
local ok2,b=pcall(love.graphics.newCanvas,w,h,{dpiscale=1,msaa=0});if not ok2 then ok2,b=pcall(love.graphics.newCanvas,w,h) end
if not ok2 or not b then if a.release then pcall(a.release,a) end;return false end
H.postCanvas,H.postHistory,H.postW,H.postH=a,b,w,h;H.postHistoryValid=false
return true
end
local function ensureDistortShader()
if H.distortShader then return H.distortShader end
if not (love and love.graphics and love.graphics.newShader) then return nil end
local ok,sh=pcall(love.graphics.newShader,DISTORT_SHADER);if ok then H.distortShader=sh;return sh end
H.drawError=tostring(sh);return nil
end
local function activePostFamilies()
local filter,blur,distort
for _,rec in pairs(H.effects) do
local fam=tonumber(rec.family)
if fam==2 then filter=rec elseif fam==8 then blur=rec elseif fam==10 then distort=rec end
end
return filter,blur,distort
end

local function readablePostAlpha(ctx,r,g,b,alpha)
local generation=ctx and ctx.battle and ctx.battle.__cbeGeneration
if generation==nil and V and V.GenerationCompat and type(V.GenerationCompat.current)=="function" then
local ok,value=pcall(V.GenerationCompat.current)
if ok then generation=value end
end
if tonumber(generation)==2 then
local brightness=math.max(0,math.min(1,((tonumber(r) or 0)+(tonumber(g) or 0)+(tonumber(b) or 0))/3))
if brightness<.35 then alpha=math.min(alpha,.36+brightness*.25) end
end
return alpha
end





function H.drawPost(ctx,sourceCanvas,w,h)
local filter,blur,distort=activePostFamilies()
if not (filter or blur or distort) then H.postHistoryValid=false;return false end
local g=love and love.graphics;if not (g and sourceCanvas and w and h and ensurePost(w,h)) then return false end
local ok,err=pcall(function()
g.push("all");if g.origin then g.origin() end;if g.setScissor then g.setScissor() end;g.setShader();g.setDepthMode();g.setBlendMode("alpha","alphamultiply")



if distort then
g.setCanvas(H.postCanvas);g.clear(0,0,0,0);g.setColor(1,1,1,1);g.draw(sourceCanvas,0,0)
g.setCanvas(sourceCanvas);g.clear(0,0,0,0)
local sh=ensureDistortShader();local p,frame=effectProgress(distort);local vals=distort.effect and distort.effect.values or {}
if sh then
g.setShader(sh)
local amount=math.max(0.001,math.min(.045,math.abs(tonumber(vals[1]) or .9)*.006*(.45+.55*math.sin(math.pi*p))))
local freq=math.max(8,math.min(90,math.abs(tonumber(vals[2]) or 3)*8+18))
sh:send("amount",amount);sh:send("frequency",freq);sh:send("phase",(tonumber(frame) or 0)*.012+(tonumber(vals[3]) or 0)*.01)
end
g.setColor(1,1,1,1);g.draw(H.postCanvas,0,0);g.setShader()
end




if blur then
local p=effectProgress(blur);local strength=math.abs(keyedScalar(blur.effect or {},p,.5));strength=math.max(.04,math.min(.72,strength*.28))
if H.postHistoryValid then
g.setCanvas(sourceCanvas);g.setBlendMode("alpha","alphamultiply");g.setColor(1,1,1,strength)
local drift=math.max(0,math.min(4,strength*4));g.draw(H.postHistory,-drift,0);g.draw(H.postHistory,drift,0)
end
g.setCanvas(H.postHistory);g.clear(0,0,0,0);g.setBlendMode("alpha","alphamultiply");g.setColor(1,1,1,1);g.draw(sourceCanvas,0,0);H.postHistoryValid=true
g.setCanvas(sourceCanvas)
else H.postHistoryValid=false end

if filter then
g.setCanvas(sourceCanvas);g.setShader();g.setBlendMode("alpha","alphamultiply")
local p=effectProgress(filter);local e=filter.effect or {};local c=e.color or {255,255,255,255};local r,gg,b,a=effectRGBA(c,1)
local energy=math.sin(math.pi*p);local scale=math.abs(tonumber(e.a) or tonumber(e.c) or 1);local alpha=math.max(0,math.min(.92,a*energy*math.max(.12,math.min(1,scale))))
alpha=readablePostAlpha(ctx,r,gg,b,alpha)
g.setColor(r,gg,b,alpha);g.rectangle("fill",0,0,w,h)
end
g.setColor(1,1,1,1);g.setShader();g.setCanvas(sourceCanvas);g.pop()
end)
if not ok then H.postErrors=(tonumber(H.postErrors) or 0)+1;H.drawError="Type-4 postprocess: "..tostring(err);pcall(g.setCanvas,sourceCanvas);pcall(g.setShader);return false end
return true
end

local function shiftedBasis(base,x,y,z,scale,yaw)
local b={};for k,v in pairs(base or {}) do b[k]=v end
local u=type(base.sourceUnits)=="table" and base.sourceUnits or {x=1,y=1,z=1}
local ux=tonumber(u.x) or tonumber(u[1]) or 1;local uy=tonumber(u.y) or tonumber(u[2]) or 1;local uz=tonumber(u.z) or tonumber(u[3]) or 1
local r,up,f=base.right or {1,0,0},base.up or {0,1,0},base.forward or {0,0,1};local o=base.origin or {0,0,0}
local angle=tonumber(yaw) or 0
if angle~=0 then
local ca,sa=math.cos(angle),math.sin(angle)
local oldR,oldF=r,f
r={oldR[1]*ca+oldF[1]*sa,oldR[2]*ca+oldF[2]*sa,oldR[3]*ca+oldF[3]*sa}
f={oldF[1]*ca-oldR[1]*sa,oldF[2]*ca-oldR[2]*sa,oldF[3]*ca-oldR[3]*sa}
b.right=r;b.forward=f
end
local ox=(tonumber(x) or 0)*ux;local oy=(tonumber(y) or 0)*uy;local oz=(tonumber(z) or 0)*uz
b.origin={o[1]+r[1]*ox+up[1]*oy+f[1]*oz,o[2]+r[2]*ox+up[2]*oy+f[2]*oz,o[3]+r[3]*ox+up[3]*oy+f[3]*oz}
local t=base.target or o;b.target={t[1]+r[1]*ox+up[1]*oy+f[1]*oz,t[2]+r[2]*ox+up[2]*oy+f[2]*oz,t[3]+r[3]*ox+up[3]*oy+f[3]*oz}
local sm=math.max(.04,math.min(8,tonumber(scale) or 1));b.modelTargetSpan=(tonumber(base.modelTargetSpan) or tonumber(base.referenceVisualHeight) or 16)*sm



b.sourceUnits={x=ux*sm,y=uy*sm,z=uz*sm}
return b
end
local function stable01(serial,index,salt)
local n=((tonumber(serial) or 1)*73856093+(tonumber(index) or 1)*19349663+(tonumber(salt) or 0)*83492791)%2147483647
return n/2147483647
end

function H.drawWorld(ctx)
if not (love and love.graphics and CSM and type(CSM.wazaBasis)=="function") then return false end
local vp=ctx and ctx.services and (ctx.services.vp or ctx.services.stageVP)
if type(vp)~="table" then return false end
local g=love.graphics;local jobs={}
for _,rec in pairs(H.models) do
local inst,entry=rec.instance,rec.entry
local originSide=(inst and inst.role=="damage") and inst.target or (inst and inst.side)
local otherSide=originSide==(inst and inst.side) and (inst and inst.target) or (inst and inst.side)
local er=rec.effectRec;local ee=er and er.effect or nil;local family=tonumber(er and er.family)
local attachment=entry and entry.attachment
if ee and (family==5 or family==7 or family==11) then attachment=ee.partA or attachment end
local okBasis,basis=pcall(CSM.wazaBasis,CSM,ctx,originSide,otherSide,attachment,{
moveId=inst and (tonumber(inst.moveId) or (inst.spec and inst.spec.moveId)),style=inst and inst.spec and inst.spec.style,role=inst and inst.role,
sourceStrict=true,positionType=entry and entry.positionType,flags=entry and entry.flags,modelEntry=entry})




local frac=math.max(0,math.min(.999999,(tonumber(inst and inst.accumulator) or 0)*60))
local localFrame=(tonumber(inst and inst.frame) or 0)+frac-(tonumber(rec.state and rec.state.startFrame) or tonumber(rec.startedFrame) or 0)
if entry and entry.kind=='model' then localFrame=sourceModelFrame(localFrame) end
local model,err,page
if not rec.asset.transformOnly then model,err,page=loadModel(rec.asset,localFrame) end
if okBasis and basis and model then
if er and tonumber(er.family)==5 then




local e=er.effect or {};local vals=e.values or {};local p=effectProgress(er)
local count=math.max(1,math.min(32,math.floor(tonumber(e.partA) or 1)))
for li=1,count do
local r1=stable01(inst and inst.serial,li,1);local r2=stable01(inst and inst.serial,li,2);local r3=stable01(inst and inst.serial,li,3)
local scale=math.abs((tonumber(vals[1]) or 1)+(tonumber(vals[2]) or 0)*(r1*2-1));if scale<.05 then scale=1 end
local h0=(tonumber(vals[3]) or 0)+(tonumber(vals[4]) or 0)*(r2*2-1)
local radius=math.abs((tonumber(vals[5]) or .5)+(tonumber(vals[6]) or 0)*(r3*2-1))
local speed=math.abs(tonumber(vals[7]) or .7)+.15
local angle=r1*math.pi*2+(tonumber(inst and inst.frame) or 0)*.015*(.6+r2)
local x=math.cos(angle)*radius+math.sin((p+r3)*math.pi*2)*radius*.28
local z=math.sin(angle)*radius+math.cos((p+r2)*math.pi*2)*radius*.28
local y=h0+(1-p)*radius*.45-p*speed
jobs[#jobs+1]={rec=rec,basis=shiftedBasis(basis,x,y,z,scale,angle),model=model,page=page,
localFrame=localFrame+(li-1)*.35,tint=keyedColor(e.keys,p,e.color)}
end
elseif er and tonumber(er.family)==6 then



local e=er.effect or {};local vals=e.values or {};local p=effectProgress(er)
local start=e.start or {0,0,0};local velocity=e.velocity or {0,0,0}
local count=math.max(1,math.min(32,math.floor(tonumber(e.countA) or 1)))
local spread=math.abs(tonumber(vals[2]) or 0);local baseScale=math.abs(tonumber(vals[1]) or 1)
if baseScale<.02 or baseScale>16 then baseScale=1 end
for mi=1,count do
local lane=mi-(count+1)*.5;local phase=(mi-1)/math.max(1,count)
local x=(tonumber(start[1]) or 0)+(tonumber(velocity[1]) or 0)*p+lane*spread
local y=(tonumber(start[2]) or 0)+(tonumber(velocity[2]) or 0)*p
local z=(tonumber(start[3]) or 0)+(tonumber(velocity[3]) or 0)*p
jobs[#jobs+1]={rec=rec,basis=shiftedBasis(basis,x,y,z,baseScale,(p+phase)*math.pi*2),model=model,page=page,
localFrame=localFrame+phase,tint=keyedColor(e.keys,p,e.color),environment=true}
end
elseif er and tonumber(er.family)==7 then


local e=er.effect or {};local p=effectProgress(er);local start=e.start or {0,0,0};local velocity=e.velocity or {0,0,0}
local scale=math.abs(tonumber(e.a) or 1);if scale<.02 or scale>16 then scale=1 end
local wave=math.sin(p*math.pi*2)*math.max(-8,math.min(8,tonumber(e.b) or 0))
local x=(tonumber(start[1]) or 0)+(tonumber(velocity[1]) or 0)*p
local y=(tonumber(start[2]) or 0)+(tonumber(velocity[2]) or 0)*p+wave
local z=(tonumber(start[3]) or 0)+(tonumber(velocity[3]) or 0)*p
jobs[#jobs+1]={rec=rec,basis=shiftedBasis(basis,x,y,z,scale),model=model,page=page,localFrame=localFrame,
tint=keyedColor(e.keys,p,e.color)}
elseif er and tonumber(er.family)==11 then



local e=er.effect or {};local p=effectProgress(er)
local turns=(tonumber(e.mode) or 0)~=0 and p*(tonumber(e.partB) or 1) or 0
jobs[#jobs+1]={rec=rec,basis=shiftedBasis(basis,0,0,0,1,turns*math.pi*2),model=model,page=page,
localFrame=localFrame,tint=keyedColor(e.keys,p,e.color)}
else jobs[#jobs+1]={rec=rec,basis=basis,model=model,page=page,localFrame=localFrame,
tint=er and keyedColor((er.effect or {}).keys,effectProgress(er),(er.effect or {}).color) or nil} end
elseif err then H.drawError=tostring(err);relinquishFailedVisual(rec,H.drawError) end
end
local proceduralDrew=drawProceduralEffects(ctx)
if #jobs==0 then return proceduralDrew end
local drew=proceduralDrew
local ok,value,scopeErr=graphicsScope(g,function()
local function pass(kind)
if kind=="add" then pcall(g.setBlendMode,"add","alphamultiply")
else pcall(g.setBlendMode,"alpha","alphamultiply") end
for _,job in ipairs(jobs) do
local sh,serr=ensureShader(job.model.morph)
if sh then
local okJob,jobErr=pcall(function()
g.setShader(sh);sh:send("vp","row",vp);sh:send("model","row",modelMatrix(job.basis,job.model,job.rec and job.rec.asset))
if job.model.morph then
local weights=morphWeights(job.page,job.localFrame)
for wi=0,12 do sh:send("w"..wi,weights[wi+1] or 0) end
end
for gi,grp in ipairs(job.model.groups) do
if not grp._cbeRenderDisabled then
local class=grp.luminous and "add" or (grp.xlu and "alpha" or "solid")
if class==kind then
local okGrp,grpErr=pcall(function()
local material=materialAnimationSample(job.model,gi,job.localFrame)
local d=material and material.diffuse or grp.diffuse or {1,1,1};local tr,tg,tb,ta=effectRGBA(job.tint,1)
if not job.tint then tr,tg,tb,ta=1,1,1,1 end
sh:send("materialColor",{tonumber(d[1]) or 1,tonumber(d[2]) or 1,tonumber(d[3]) or 1,(tonumber(material and material.alpha or grp.alpha) or 1)*ta})
sh:send("effectTint",{tr,tg,tb})
sh:send("useTexture",grp.image and 1 or 0);sh:send("opacity",1);sh:send("forceOpaque",0)
local uv=textureAnimationSample(job.model,gi,job.localFrame)
sh:send("uvRow0",{uv[1],uv[2],uv[3]});sh:send("uvRow1",{uv[4],uv[5],uv[6]})
sh:send("envMode",job.environment and 1 or 0)
sh:send("unlit",(grp.luminous or grp.effect or grp.useConstant or not grp.useDiffuseLighting) and 1 or 0)
g.setDepthMode("lequal",class=="solid" and not grp.noz)
g.setColor(1,1,1,1);g.draw(grp.mesh);drew=true
end)
if not okGrp then modelRenderFault(job.rec,grp,grpErr);pcall(g.setShader,sh) end
end
end
end
end)
if not okJob then modelRenderFault(job.rec,nil,jobErr);pcall(g.setShader) end
else H.drawError=tostring(serr) end
end
end
pass("solid");pass("alpha");pass("add")
return drew
end)
if not ok then modelRenderFault(jobs[1] and jobs[1].rec,nil,scopeErr);return false end
if value and not H.drawError then H.drawError=nil end
return value==true
end




function H.drawAsset(ctx,asset,vp,worldModel,localFrame,opts)
opts=type(opts)=="table" and opts or {}


if opts.hsdFrame~=true then localFrame=sourceModelFrame(localFrame) end
if not (type(asset)=="table" and asset.cache and type(vp)=="table" and type(worldModel)=="table") then return false,"invalid source asset draw" end
local model,err,page=loadModel(asset,localFrame)
if not model then return false,err end
local g=love and love.graphics;if not g then return false,"LÖVE graphics unavailable" end
local opacity=math.max(0,math.min(1,tonumber(opts.opacity) or 1))
local drew=false
local ok,value,scopeErr=graphicsScope(g,function()
local sh,serr=ensureShader(model.morph);if not sh then error(serr or "source model shader unavailable") end
if opts.cullMode and g.setMeshCullMode then pcall(g.setMeshCullMode,opts.cullMode) end
g.setShader(sh);sh:send("vp","row",vp);sh:send("model","row",worldModel)
sh:send("effectTint",{1,1,1})
if model.morph then
local weights=morphWeights(page,localFrame)
for wi=0,12 do sh:send("w"..wi,weights[wi+1] or 0) end
end
local function pass(kind)
if kind=="add" then pcall(g.setBlendMode,"add","alphamultiply") else pcall(g.setBlendMode,"alpha","alphamultiply") end
for gi,grp in ipairs(model.groups or {}) do
if not grp._cbeRenderDisabled then
local class=opts.forceOpaque and "solid" or (grp.luminous and "add" or (grp.xlu and "alpha" or "solid"))
if class==kind then
local material=materialAnimationSample(model,gi,localFrame)
local d=material and material.diffuse or grp.diffuse or {1,1,1}
local materialAlpha=opts.forceOpaque and 1 or (tonumber(material and material.alpha or grp.alpha) or 1)
sh:send("materialColor",{tonumber(d[1]) or 1,tonumber(d[2]) or 1,tonumber(d[3]) or 1,materialAlpha})
sh:send("useTexture",grp.image and 1 or 0);sh:send("opacity",opts.forceOpaque and 1 or opacity);sh:send("forceOpaque",opts.forceOpaque and 1 or 0)
local uv=textureAnimationSample(model,gi,localFrame)
sh:send("uvRow0",{uv[1],uv[2],uv[3]});sh:send("uvRow1",{uv[4],uv[5],uv[6]})
sh:send("envMode",0)
local forcedUnlit=opts.unlit
sh:send("unlit",forcedUnlit~=nil and (forcedUnlit and 1 or 0) or ((grp.luminous or grp.effect or grp.useConstant or not grp.useDiffuseLighting) and 1 or 0))
if opts.depthAlways then
g.setDepthMode("always",false)
else


local writeDepth=(opts.forceOpaque==true) or (class=="solid" and not grp.noz)
g.setDepthMode("lequal",writeDepth)
end
g.setColor(1,1,1,1);g.draw(grp.mesh);drew=true
end
end
end
end
pass("solid");pass("alpha");pass("add")
return drew
end)
if not ok then return false,scopeErr end
return value==true,nil,model.bounds
end

function H.prewarm()



local okStatic,staticErr=ensureShader(false)
local okMorph,morphErr=ensureShader(true)
if not okStatic and staticErr then H.drawError=tostring(staticErr) end
if not okMorph and morphErr then H.drawError=tostring(morphErr) end
return okStatic~=nil or okMorph~=nil
end








local SOURCE_CAMERA_FOV=math.rad(39.09)
local function cadd(a,b,s)return {(a[1] or 0)+(b[1] or 0)*(s or 1),(a[2] or 0)+(b[2] or 0)*(s or 1),(a[3] or 0)+(b[3] or 0)*(s or 1)} end
local function clerp(a,b,t)return {(a[1] or 0)+((b[1] or 0)-(a[1] or 0))*t,(a[2] or 0)+((b[2] or 0)-(a[2] or 0))*t,(a[3] or 0)+((b[3] or 0)-(a[3] or 0))*t} end
local function cdist(a,b)local x=(b[1] or 0)-(a[1] or 0);local y=(b[2] or 0)-(a[2] or 0);local z=(b[3] or 0)-(a[3] or 0);return math.sqrt(x*x+y*y+z*z) end
local cameraContinuity={session=nil,currentSerial=nil,transitionFrom=nil,transitionStartFrame=0,lastPose=nil,actionKey=nil,axisSign=nil,
motionKey=nil,motionMode=nil,lastMotionMode=nil}
local function latestCameraInstance()
local best
for _,inst in ipairs(Waza and Waza.active or {}) do
if type(inst)=="table" and not inst.done and type(inst.spec)=="table" then
local owns=true
if type(Waza.canOwn)=="function" then local ok,v=pcall(Waza.canOwn,Waza,inst.spec,inst.role);owns=ok and v==true end
if owns and (not best or (tonumber(inst.serial) or 0)>(tonumber(best.serial) or 0)) then best=inst end
end
end
return best
end
local function cameraAttachment(inst)
local fallback
for _,st in ipairs(inst and inst.entries or {}) do
local e=st.entry
if type(e)=="table" and (e.kind=="model" or e.kind=="particle") then
fallback=fallback or e.attachment
if st.started and not st.closed then return e.attachment end
end
end
return fallback
end
local function hasCameraFlag(flags,mask)
flags=math.max(0,math.floor(tonumber(flags) or 0));mask=math.max(1,math.floor(tonumber(mask) or 1))
return math.floor(flags/mask)%2==1
end
local function cameraPhaseRole(phase)
local name=tostring(phase and (phase.name or phase.phase) or "all"):lower()
return (name=="status" or name:match("^damage")) and "damage" or "attack"
end
local function sourceCameraPhase(inst,role)
local fallback
for _,phase in ipairs(type(inst and inst.spec)=="table" and (inst.spec.wazaPhases or {}) or {}) do
if cameraPhaseRole(phase)==role and (phase.sequenceFlags~=nil or phase.sequenceKind~=nil or phase.cameraActive~=nil) then
if #(phase.entries or {})>0 then return phase end
fallback=fallback or phase
end
end
return fallback
end
local function sourceMotionOptions(flags,modelId)




if CameraParams and type(CameraParams.motionOptions)=="function" then
return CameraParams.motionOptions(flags,modelId)
end
if hasCameraFlag(flags,0x1) then return {5},true end
local out={}
if hasCameraFlag(flags,0x08) then out[#out+1]=3 end
if hasCameraFlag(flags,0x10) then out[#out+1]=0 end
if hasCameraFlag(flags,0x20) then out[#out+1]=1 end
if hasCameraFlag(flags,0x40) then out[#out+1]=2 end
if #out==0 then out={3,0,1,2} end
return out,#out==1
end
local function chooseSourceMotion(inst,phase,role,ownerDex)
local flags=math.max(0,math.floor(tonumber(phase and phase.sequenceFlags) or 0))
local key=table.concat({tostring(inst.presentationSerial or inst.serial or 0),role,tostring(flags),
tostring(phase and phase.sequenceKind or ""),tostring(ownerDex or "")},":")
if cameraContinuity.motionKey==key and cameraContinuity.motionMode~=nil then return cameraContinuity.motionMode end
local options,forced
if CameraParams and type(CameraParams.motionOptionsForPokemonDex)=="function" and ownerDex~=nil then
options,forced=CameraParams.motionOptionsForPokemonDex(flags,ownerDex)
else
options,forced=sourceMotionOptions(flags,phase and phase.modelSequenceId)
end
local pool={}
for _,mode in ipairs(options) do
if forced or #options==1 or mode~=cameraContinuity.lastMotionMode then pool[#pool+1]=mode end
end
if #pool==0 then pool=options end



local salt=(flags%65536)+(tonumber(phase and phase.sequenceKind) or 0)*31+(role=="damage" and 97 or 17)
local r=stable01(inst.presentationSerial or inst.serial or 1,inst.serial or 1,salt)
local idx=math.min(#pool,math.floor(r*#pool)+1);local mode=pool[idx]
cameraContinuity.motionKey=key;cameraContinuity.motionMode=mode;cameraContinuity.lastMotionMode=mode
return mode
end
local function sourceParamsFlags(flags,ownerPosition)





local out=0
if hasCameraFlag(flags,0x00200000) then out=2
elseif hasCameraFlag(flags,0x00000200) then out=4
elseif hasCameraFlag(flags,0x00400000) then out=((ownerPosition and (ownerPosition[3] or 0)<0) and 4 or 8) end
if hasCameraFlag(flags,0x00000400) then out=out+0x20
elseif hasCameraFlag(flags,0x00000800) then out=out+0x40
elseif hasCameraFlag(flags,0x00001000) then out=out+0x80 end
return out
end
local function sourceDistanceBand(paramsFlags)





if hasCameraFlag(paramsFlags,0x20) then return 25,40 end
if hasCameraFlag(paramsFlags,0x40) then return 35,50 end
if hasCameraFlag(paramsFlags,0x80) then return 48,60 end
return 20,60
end
local function sourceRotationBand(paramsFlags)
local low=paramsFlags%0x20
if hasCameraFlag(low,0x01) then return 0,math.rad(30) end
if hasCameraFlag(low,0x02) then return math.rad(18),math.rad(36) end



if hasCameraFlag(low,0x04) then return math.rad(18),math.rad(54) end
if hasCameraFlag(low,0x08) then return math.rad(36),math.rad(72) end
if hasCameraFlag(low,0x10) then return math.rad(72),math.rad(90) end
return math.rad(18),math.rad(63)
end
local function sourceCameraTargetSlot(phase)





local root=type(phase)=="table" and phase.root or nil
if type(root)~="table" then return nil,false end
local mode=tonumber(root.mode)
if mode==nil then return nil,false end
local slot=mode==5 and tonumber(root.variant) or 2
if slot==nil or slot<0 or slot>=16 or slot~=math.floor(slot) then return nil,false end
return slot,true
end
local function sourceCameraDecision(inst,role,src,ownerRootBasis,ownerSide)
local phase=sourceCameraPhase(inst,role);if not phase then return nil end
if phase.cameraActive==false then return {active=false,phase=phase} end
local flags=math.max(0,math.floor(tonumber(phase.sequenceFlags) or 0))
local embeddedSize=math.max(0,math.floor(tonumber(phase.root and phase.root.embeddedSize) or 0))






if embeddedSize>0 then
local camera=type(phase.sourceCamera)=="table" and phase.sourceCamera or nil
local curveDecoded=camera and camera.complete==true and type(camera.samples)=="table" and #camera.samples>0







local battleSpace=hasCameraFlag(flags,0x4)
local boundCentre=(not battleSpace) and hasCameraFlag(flags,0x00004000)










local rootNullSpecial=false
if not battleSpace and role=="damage" then
local ownerState=H.controllers[tostring(controllerSide(inst) or "")]
rootNullSpecial=ownerState and ownerState.rootNull==true or false
end
local gridNormalised=battleSpace and hasCameraFlag(flags,0x00800000)
local gridYIdentity=gridNormalised and hasCameraFlag(flags,0x01000000)
local gridFacingFlip=battleSpace and hasCameraFlag(flags,0x02000000)







local transformSupported=not rootNullSpecial
local transformUnsupported=rootNullSpecial and "owner-root-null-y-unavailable" or nil
return {active=true,phase=phase,flags=flags,sequenceKind=tonumber(phase.sequenceKind),embedded=true,embeddedSize=embeddedSize,
camera=camera,embeddedCurveDecoded=curveDecoded,embeddedDecoded=curveDecoded and transformSupported,
battleSpace=battleSpace,gridNormalised=gridNormalised,gridYIdentity=gridYIdentity,gridFacingFlip=gridFacingFlip,
boundCentre=boundCentre,rootNullSpecial=rootNullSpecial,embeddedTransformUnsupported=transformUnsupported}
end
local ownerPosition=type(ownerRootBasis)=="table" and ownerRootBasis.origin or src
local paramsFlags=sourceParamsFlags(flags,ownerPosition)
local retailParams
if CameraParams and type(CameraParams.calculate)=="function" and type(ownerRootBasis)=="table" then
retailParams=CameraParams.calculate(paramsFlags,ownerRootBasis.sourceScaleSelector,
ownerRootBasis.ownerRetailWazaBound,ownerRootBasis.ownerModelYaw)
end
local near,far
if retailParams and retailParams.exact then near,far=retailParams.distanceMin,retailParams.distanceMax
else near,far=sourceDistanceBand(paramsFlags) end
local motion=chooseSourceMotion(inst,phase,role,ownerRootBasis and ownerRootBasis.ownerDex)
local serial=tonumber(inst.presentationSerial or inst.serial) or 1
local targetSlot,targetSlotExact=sourceCameraTargetSlot(phase)





local motionSample
if retailParams and retailParams.exact and CameraParams and type(CameraParams.sampleMotion)=="function" then
local salts={
["dolly-alternate"]=131,["dolly-distance-a"]=149,["dolly-distance-b"]=167,
["mode1-lateral"]=181,["distance"]=193,["height"]=197,
["rotation-a"]=211,["rotation-b"]=229,
}
local ownerFacing=ownerSide=="player" and -1 or (ownerSide=="enemy" and 1 or nil)
local ownerReverse=ownerFacing and ownerFacing<0 and not hasCameraFlag(flags,0x80) or false
motionSample=CameraParams.sampleMotion(motion,retailParams,function(key)
return stable01(serial,inst.serial or 1,(salts[key] or 251)+(flags%997))
end,{rotationBase=ownerRootBasis.ownerModelYaw,reverse=ownerFacing~=nil and ownerReverse or nil})
end
local r0=stable01(serial,inst.serial or 1,flags%10007+11)
local r1=stable01(serial,inst.serial or 1,flags%10009+37)
local distance0=motionSample and motionSample.distance0 or (near+(far-near)*r0)
local distance1=motionSample and motionSample.distance1 or (near+(far-near)*r1)
if not motionSample then
if motion==1 then
distance0=20+30*r0;distance1=distance0
elseif motion==4 and CameraParams and type(CameraParams.mode4)=="function" then
local m4=CameraParams.mode4();distance0=m4.distance;distance1=m4.distance
elseif motion==5 then
local selector=retailParams and retailParams.selector
local exactDistance=CameraParams and type(CameraParams.mode5Distance)=="function" and selector~=nil
and CameraParams.mode5Distance(selector) or nil
distance0=exactDistance or 50;distance1=distance0
end
end
local rot0,rot1
if motionSample then
rot0=motionSample.rotation0;rot1=motionSample.rotation1
else
local rotLo,rotHi
if retailParams and retailParams.exact then rotLo,rotHi=retailParams.rotationMin,retailParams.rotationMax
else rotLo,rotHi=sourceRotationBand(paramsFlags) end
rot0=rotLo+(rotHi-rotLo)*stable01(serial,inst.serial or 1,53)
rot1=rotLo+(rotHi-rotLo)*stable01(serial,inst.serial or 1,71)
if rot1<rot0 then rot0,rot1=rot1,rot0 end
end
local ownerFacing=ownerSide=="player" and -1 or (ownerSide=="enemy" and 1 or nil)
local ownerReverse=ownerFacing and ownerFacing<0 and not hasCameraFlag(flags,0x80) or false
return {active=true,phase=phase,flags=flags,sequenceKind=tonumber(phase.sequenceKind),motion=motion,paramsFlags=paramsFlags,
retailParams=retailParams,paramsExact=retailParams and retailParams.exact==true or false,
motionSample=motionSample,motionScalarExact=motionSample and motionSample.scalarFormulaExact==true or false,
motionRngExact=motionSample and motionSample.rngExact==true or false,
motionWorldRotationExact=motionSample and motionSample.worldRotationFormulaExact==true or false,
targetSlot=targetSlot,targetSlotExact=targetSlotExact,ownerSide=ownerSide,ownerFacing=ownerFacing,ownerReverse=ownerReverse,
distance0=distance0,distance1=distance1,rotation0=rot0,rotation1=rot1}
end
local function sourceFovEnvelope(decision,visualHeight,distance,rangeIndex)




local params=decision and decision.retailParams
rangeIndex=tonumber(rangeIndex) or 1
local exactGeometry=params and params.exact==true
local span
if exactGeometry then
local scaleMin,scaleMax=tonumber(params.scaleMin),tonumber(params.scaleMax)




if rangeIndex>=3 then scaleMin,scaleMax=scaleMax,tonumber(params.rotationMin) end
if scaleMin==nil or scaleMax==nil then exactGeometry=false
else span=math.max(.75*scaleMin,scaleMax) end
end
if not exactGeometry then span=math.max(1,tonumber(visualHeight) or 6) end
local range=math.max(1,tonumber(distance) or 40)
local low=math.deg(2*math.atan(.5*span/range));local high=math.deg(2*math.atan(2*span/range))
low=math.max(15,math.min(85,low));high=math.max(15,math.min(85,high));if high<low then low,high=high,low end
return low,high,exactGeometry
end
local function sourceCameraFov(decision,visualHeight,ranges,serial,frame,timing)




local function rangeAt(index)
if type(ranges)=="table" then
if index==1 then return tonumber(ranges.near or ranges[1]) end
if index==2 then return tonumber(ranges.mid or ranges.middle or ranges[2]) end
return tonumber(ranges.far or ranges[3])
end
return tonumber(ranges)
end
local function envelope(index)
return sourceFovEnvelope(decision,visualHeight,rangeAt(index),index)
end
local low,high,boundGeometryExact=envelope(1)
local draw=0
local function rand01()
draw=draw+1
return stable01(serial,draw,149+draw*37+(tonumber(decision.sequenceKind) or 0)*11)
end
local function randIndex(n)return math.floor(rand01()*math.max(1,n)) end
local function choose(flags,rangeIndex)
local eLow,eHigh,eExact=envelope(rangeIndex or 1)
if eExact~=boundGeometryExact then boundGeometryExact=boundGeometryExact and eExact end
local a,b
if CameraFov and type(CameraFov.mixBand)=="function" then a,b=CameraFov.mixBand(flags)
else
if hasCameraFlag(flags,1) then a,b=0,.20
elseif hasCameraFlag(flags,4) then a,b=.75,1
else a,b=.35,.60 end
end
local mix=a+(b-a)*rand01()
return eLow+(eHigh-eLow)*mix
end

local usesPattern=CameraFov and CameraFov.usesPattern and CameraFov.usesPattern(decision.motion)
if not CameraFov then
local flags=hasCameraFlag(decision.paramsFlags,0x20) and 1
or (hasCameraFlag(decision.paramsFlags,0x80) and 4 or 2)
local value=choose(flags,1)
return math.rad(value),{patternExact=false,timingExact=false,boundsExact=false,boundsProxy=true,reason="pattern-module-unavailable"}
end




if not usesPattern then
local flags=CameraFov.staticChoice(decision.paramsFlags)
local value=choose(flags,1)
return math.rad(value),{patternExact=true,patternUsed=false,timingExact=true,
boundsExact=false,boundsProxy=not boundGeometryExact,boundGeometryExact=boundGeometryExact,
rangeFormulaExact=decision and decision.motionSample and decision.motionSample.fovRangeFormulaExact==true or false,
rangeSampleExact=false,tableName="none",rowIndex=nil,frameShift=timing and timing.frameShift or nil}
end

local timingExact=type(timing)=="table" and timing.exact==true
and tonumber(timing.rate)==60 and tonumber(timing.count) and type(timing.frames)=="table"
if not timingExact then



local value=low+(high-low)*(.35+.40*rand01())
return math.rad(value),{patternExact=false,patternUsed=true,timingExact=false,
boundsExact=false,boundsProxy=true,reason="owner-camera-timing-unavailable"}
end

local plan=CameraFov.plan(decision.sequenceKind,decision.paramsFlags,decision.motion,timing,rand01,randIndex)
local current=choose(plan.initialFlags,1)
local keys={}
for i,segment in ipairs(plan.segments or {}) do
local ending=current
if not segment.hold then ending=choose(segment.descriptor and segment.descriptor.flags or 0,i+1) end
keys[i]={start=current,finish=ending,startFrame=segment.startFrame,endFrame=segment.endFrame}
current=ending
end
local cameraClock=(tonumber(plan.frame0) or 0)+math.max(0,tonumber(frame) or 0)
local value
if #keys==0 then value=current
else
value=keys[#keys].finish
for _,key in ipairs(keys) do
if cameraClock<=key.startFrame then value=key.start;break end
if cameraClock<=key.endFrame then
local span=key.endFrame-key.startFrame
local t=span>0 and (cameraClock-key.startFrame)/span or 1
value=key.start+(key.finish-key.start)*math.max(0,math.min(1,t));break
end
value=key.finish
end
end
return math.rad(value),{patternExact=true,patternUsed=true,timingExact=true,boundsExact=false,boundsProxy=not boundGeometryExact,
boundGeometryExact=boundGeometryExact,
rangeFormulaExact=decision and decision.motionSample and decision.motionSample.fovRangeFormulaExact==true or false,
rangeSampleExact=false,
tableName=plan.tableName,rowIndex=plan.rowIndex,selection=plan.selection,frameShift=plan.frameShift,
cameraClock=cameraClock,frame0=plan.frame0,keyCount=#keys}
end
local function offsetEye(focus,forward,right,back,side,height)
local eye=cadd(focus,forward,-back)
eye=cadd(eye,right,side)
eye[2]=(eye[2] or 0)+height
return eye
end



local RETAIL_CAMERA_OWNER_SCALES={0.5,0.75,1.0,1.333299994468689,2.0,3.25}
local RETAIL_CAMERA_SCALE_BY_SELECTOR={[-2]=0.5,[-1]=0.75,[0]=1.0,[1]=1.333299994468689,[2]=2.0,[3]=3.25}







local RETAIL_GRID_NORMALISED_BY_SELECTOR={
[-2]=1.4967105388641357,[-1]=1.4967105388641357,[0]=1.7105263471603394,
[1]=2.3947367668151855,[2]=3.0789473056793213,[3]=4.7039475440979,
}
local RETAIL_GRID_NORMALISED_DEFAULT=1.7105263471603394
local function embeddedCameraSample(camera,frame)
local samples=type(camera)=="table" and camera.samples or nil
if type(samples)~="table" or #samples==0 then return nil end
local f=math.max(0,math.min(#samples-1,tonumber(frame) or 0))
local i0=math.floor(f)+1;local i1=math.min(#samples,i0+1);local t=f-math.floor(f)
local a,b=samples[i0],samples[i1]
if not (a and a.eye and a.focus and b and b.eye and b.focus) then return nil end
local function v3(x,y)return {lerp(x[1],y[1],t),lerp(x[2],y[2],t),lerp(x[3],y[3],t)}end
return {eye=v3(a.eye,b.eye),focus=v3(a.focus,b.focus),fov=lerp(tonumber(a.fov) or 40,tonumber(b.fov) or tonumber(a.fov) or 40,t)}
end
local function embeddedOwnerScale(basis,figureScale)





local selector=basis and tonumber(basis.sourceScaleSelector)
if selector~=nil then
local exact=RETAIL_CAMERA_SCALE_BY_SELECTOR[selector]

return exact or 1.0,nil,selector,true
end
local stageHeight=math.max(.01,(tonumber(basis and basis.sourceVisualHeight) or 17.25)*math.max(.01,figureScale or .4))
local relative=stageHeight/6.90
local best,bestErr=1,math.huge
for _,v in ipairs(RETAIL_CAMERA_OWNER_SCALES) do local e=math.abs(relative-v);if e<bestErr then best,bestErr=v,e end end
return best,relative,nil,false
end
local function embeddedOwnerPoint(basis,p,figureScale,stageScale,ownerScale,reverse)
local origin=basis.origin
local yaw=tonumber(basis and basis.ownerModelYaw)
if yaw==nil or basis.ownerModelRotationExact~=true then return nil end
local ox,oy,oz=origin[1]*figureScale,origin[2]*figureScale,origin[3]*figureScale
local q=(stageScale or .25)*(ownerScale or 1)
local x,y,z=(p[1] or 0)*q,(p[2] or 0)*q,(p[3] or 0)*q









if reverse then x=-x end
local cs,sn=math.cos(yaw),math.sin(yaw)
local dx,dz=cs*x+sn*z,-sn*x+cs*z
return {ox+dx,oy+y,oz+dz}
end
local function retailGridScale(ctx)
local selectors=ctx and ctx.cbeRetailScaleSelectors
local complete=ctx and ctx.cbeRetailScaleSelectorsComplete
if selectors==nil and CSM and type(CSM.retailScaleSelectors)=="function" then
local ok,a,b=pcall(CSM.retailScaleSelectors,CSM)
if ok then selectors,complete=a,b end
end
if complete~=true or type(selectors)~="table" or #selectors==0 then return nil,nil,false end
local maxSelector=nil
for _,value in ipairs(selectors)do
local selector=tonumber(value)
if selector==nil then return nil,nil,false end
if maxSelector==nil or selector>maxSelector then maxSelector=selector end
end
local scale=RETAIL_GRID_NORMALISED_BY_SELECTOR[maxSelector] or RETAIL_GRID_NORMALISED_DEFAULT
return scale,maxSelector,true
end
local function retailWazaOwnerFacing(side)






if side=="player" then return -1 end
if side=="enemy" then return 1 end
return nil
end
local function retailEmbeddedReverse(side,flags)





if hasCameraFlag(flags,0x80) then return false,retailWazaOwnerFacing(side) end
local facing=retailWazaOwnerFacing(side)
if facing==nil then return nil,nil end
return facing<0,facing
end
local function embeddedBattlePoint(ctx,p,stageScale,sx,sy,sz)
local x=(tonumber(p and p[1]) or 0)*(sx or 1)*(stageScale or .25)
local y=(tonumber(p and p[2]) or 0)*(sy or 1)*(stageScale or .25)
local z=(tonumber(p and p[3]) or 0)*(sz or 1)*(stageScale or .25)
local yaw=tonumber(ctx and ctx.arena and ctx.arena.stageYaw) or 0
if yaw~=0 then
local cs,sn=math.cos(yaw),math.sin(yaw)
x,z=cs*x+sn*z,-sn*x+cs*z
end
return {x,y,z}
end
function H.cameraPose(ctx)
if not (Waza and CSM and type(CSM.wazaBasis)=="function") then return nil end
local inst=latestCameraInstance();if not inst then return nil end
local role=tostring(inst.role or "attack")





local originSide=inst.side
local otherSide=inst.target or (originSide=="player" and "enemy" or "player")






local sourceOwnerSide=(role=="damage") and otherSide or originSide
local sourceOtherSide=(sourceOwnerSide==originSide) and otherSide or originSide
local attachment=cameraAttachment(inst)
local ok,basis=pcall(CSM.wazaBasis,CSM,ctx,originSide,otherSide,attachment,{
moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),style=inst.spec and inst.spec.style,role=role,sourceStrict=true})
if not ok or type(basis)~="table" or type(basis.origin)~="table" or type(basis.target)~="table" then return nil end

local src,dst=basis.origin,basis.target
local forward=type(basis.forward)=="table" and basis.forward or {0,0,-1}
local right=type(basis.right)=="table" and basis.right or {1,0,0}
local frame=(tonumber(inst.frame) or 0)+(tonumber(inst.accumulator) or 0)*60
local total=math.max(1,tonumber(inst.sourceEndFrame) or 1)
local p=math.max(0,math.min(1,frame/total))
local fallbackStyle=V.WazaPhasePolicy and V.WazaPhasePolicy.cameraStyle(inst.spec) or tostring(inst.spec and inst.spec.style or "impact"):lower()
local fight=math.max(10,tonumber(basis.fightDistance) or cdist(src,dst))
local sh=math.max(2.8,tonumber(basis.sourceVisualHeight) or 5.5)
local th=math.max(2.8,tonumber(basis.targetVisualHeight) or sh)
local avgH=(sh+th)*.5
local focus,eye,fov=clerp(src,dst,.5),nil,SOURCE_CAMERA_FOV
local fovSourceStatus
local ownerRootBasis
local okOwnerRoot,ownerRoot=pcall(CSM.wazaBasis,CSM,ctx,sourceOwnerSide,sourceOtherSide,nil,{
moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),style=inst.spec and inst.spec.style,role=role,sourceStrict=true,ownerRoot=true})
if okOwnerRoot and type(ownerRoot)=="table" and type(ownerRoot.origin)=="table" then ownerRootBasis=ownerRoot end
local sourceDecision=sourceCameraDecision(inst,role,src,ownerRootBasis,sourceOwnerSide)
if sourceDecision and sourceDecision.active==false then return nil end
local sourceCameraTarget
if sourceDecision and not sourceDecision.embedded and sourceDecision.targetSlotExact then
local okTarget,targetBasis=pcall(CSM.wazaBasis,CSM,ctx,sourceOwnerSide,sourceOtherSide,sourceDecision.targetSlot,{
moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),style=inst.spec and inst.spec.style,
role=role,sourceStrict=true})
if okTarget and type(targetBasis)=="table" and type(targetBasis.origin)=="table" then
sourceCameraTarget=targetBasis.origin;sourceDecision.targetResolved=true
end
end




local compositionStyle=fallbackStyle
local style=sourceDecision and sourceDecision.embedded
and (sourceDecision.embeddedDecoded and "source-embedded-hsd" or ("source-embedded-fallback-"..fallbackStyle))
or (sourceDecision and ("source-motion-"..tostring(sourceDecision.motion)) or fallbackStyle)





local actionKey=tostring(inst.presentationSerial or inst.parentAttackSerial or inst.serial or "waza")
if cameraContinuity.actionKey~=actionKey then
cameraContinuity.actionKey=actionKey
cameraContinuity.axisSign=originSide=="enemy" and -1 or 1
end
local axisSign=cameraContinuity.axisSign or 1

local embeddedStageSpace=false
if sourceDecision and sourceDecision.embeddedDecoded then




local okRoot,rootBasis=ownerRootBasis~=nil,ownerRootBasis
local sample=embeddedCameraSample(sourceDecision.camera,frame)
if okRoot and type(rootBasis)=="table" and type(rootBasis.origin)=="table" and sample then
local figureScale=tonumber(ctx and ctx.arena and ctx.arena.figureScale) or tonumber(ctx and ctx.services and ctx.services.figureScale) or 1
local stageScale=tonumber(ctx and ctx.arena and ctx.arena.stageScale) or .25
local ownerScale,ownerRelative,ownerSelector,ownerSelectorExact=embeddedOwnerScale(rootBasis,figureScale)
local ownerReverse,ownerFacing=retailEmbeddedReverse(sourceOwnerSide,sourceDecision.flags)
sourceDecision.ownerSide=sourceOwnerSide;sourceDecision.ownerFacing=ownerFacing;sourceDecision.ownerReverse=ownerReverse==true
if ownerReverse==nil then
sourceDecision.embeddedDecoded=false
sourceDecision.embeddedTransformUnsupported="owner-facing-unavailable"
style="source-embedded-fallback-"..fallbackStyle
end
if sourceDecision.battleSpace then
local gridScale,gridSelector,gridScaleExact=1,nil,true
if sourceDecision.gridNormalised then
gridScale,gridSelector,gridScaleExact=retailGridScale(ctx)
if not gridScale then
sourceDecision.embeddedDecoded=false
sourceDecision.embeddedTransformUnsupported="battle-grid-selector-unavailable"
style="source-embedded-fallback-"..fallbackStyle
end
end
local gridOwnerSide=sourceOwnerSide
local gridOwnerFacing=ownerFacing
local gridFacingSign=1
if sourceDecision.gridFacingFlip then
if gridOwnerFacing==nil then
sourceDecision.embeddedDecoded=false
sourceDecision.embeddedTransformUnsupported="battle-grid-owner-facing-unavailable"
style="source-embedded-fallback-"..fallbackStyle
elseif gridOwnerFacing<0 then


gridFacingSign=-1
end
end
if sourceDecision.embeddedDecoded then
local yScale=sourceDecision.gridYIdentity and 1 or gridScale



local reverseZ=ownerReverse and -1 or 1
eye=embeddedBattlePoint(ctx,sample.eye,stageScale,gridScale*gridFacingSign,yScale,gridScale*gridFacingSign*reverseZ)
focus=embeddedBattlePoint(ctx,sample.focus,stageScale,gridScale*gridFacingSign,yScale,gridScale*gridFacingSign*reverseZ)
sourceDecision.gridScale=gridScale;sourceDecision.gridSelector=gridSelector
sourceDecision.gridScaleExact=gridScaleExact==true
sourceDecision.gridOwnerSide=gridOwnerSide;sourceDecision.gridOwnerFacing=gridOwnerFacing
sourceDecision.gridFacingApplied=sourceDecision.gridFacingFlip and gridFacingSign<0 or false
sourceDecision.reverseMirrorApplied=ownerReverse==true
embeddedStageSpace=true
end
else
if rootBasis.ownerModelRotationExact~=true or tonumber(rootBasis.ownerModelYaw)==nil then
sourceDecision.embeddedDecoded=false
sourceDecision.embeddedTransformUnsupported="owner-model-rotation-unavailable"
style="source-embedded-fallback-"..fallbackStyle
elseif sourceDecision.embeddedDecoded then
local pointBasis=rootBasis
if sourceDecision.boundCentre then
local retailBound=rootBasis.ownerRetailWazaBound
if not (type(retailBound)=="table" and retailBound.exact==true and retailBound.selectorExact==true
and type(retailBound.centerWorld)=="table") then
sourceDecision.embeddedDecoded=false
sourceDecision.embeddedTransformUnsupported="owner-bound-centre-unavailable"
style="source-embedded-fallback-"..fallbackStyle
else
pointBasis={origin=retailBound.centerWorld,ownerModelYaw=rootBasis.ownerModelYaw,ownerModelRotationExact=true}
sourceDecision.ownerBoundCentreExact=true
sourceDecision.ownerBoundAnimationIndex=retailBound.animationIndex
end
end
if sourceDecision.embeddedDecoded then
eye=embeddedOwnerPoint(pointBasis,sample.eye,figureScale,stageScale,ownerScale,ownerReverse)
focus=embeddedOwnerPoint(pointBasis,sample.focus,figureScale,stageScale,ownerScale,ownerReverse)
if eye and focus then
sourceDecision.ownerModelYaw=rootBasis.ownerModelYaw
sourceDecision.reverseMirrorApplied=ownerReverse==true
embeddedStageSpace=true
else
sourceDecision.embeddedDecoded=false
sourceDecision.embeddedTransformUnsupported="owner-model-rotation-unavailable"
style="source-embedded-fallback-"..fallbackStyle
end
end
end
end
fov=math.rad(math.max(1,math.min(179,tonumber(sample.fov) or 40)))
sourceDecision.ownerScale=ownerScale;sourceDecision.ownerRelative=ownerRelative;sourceDecision.ownerSelector=ownerSelector
sourceDecision.ownerSelectorExact=ownerSelectorExact;sourceDecision.stageScale=stageScale
else


sourceDecision.embeddedDecoded=false
style="source-embedded-fallback-"..fallbackStyle
end
end
if embeddedStageSpace then

elseif sourceDecision and not sourceDecision.embedded then





local motion=sourceDecision.motion
local motionSample=sourceDecision.motionSample
local ownerH=role=="damage" and th or sh
local distance=sourceDecision.distance0
local angle=sourceDecision.rotation0
local worldAngle
local sourceLateral
if motion==0 then



distance=lerp(sourceDecision.distance0,sourceDecision.distance1,p)
focus=role=="damage" and {dst[1],dst[2]+th*.04,dst[3]} or clerp(src,dst,.08)
elseif motion==1 then




if motionSample and motionSample.lateral0 and motionSample.lateral1 then
sourceLateral=lerp(motionSample.lateral0,motionSample.lateral1,p)
angle=math.atan(sourceLateral/math.max(1,distance))
else
local lateral=25+10*stable01(inst.presentationSerial or inst.serial or 1,inst.serial or 1,181)
angle=math.atan((lateral*p)/math.max(1,distance))
end
focus=role=="damage" and {dst[1],dst[2]+th*.04,dst[3]} or clerp(src,dst,.16)
elseif motion==2 then


angle=lerp(sourceDecision.rotation0,sourceDecision.rotation1,p)
focus=role=="damage" and {dst[1],dst[2]+th*.04,dst[3]} or clerp(src,dst,.27)
elseif motion==3 then
focus=role=="damage" and {dst[1],dst[2]+th*.04,dst[3]} or clerp(src,dst,.24)
elseif motion==4 then



if motionSample then angle=motionSample.rotation0
elseif CameraParams and type(CameraParams.mode4)=="function" then angle=CameraParams.mode4().rotation end
focus=role=="damage" and {dst[1],dst[2]+th*.04,dst[3]} or {src[1],src[2]+sh*.05,src[3]}
elseif motion==5 then
angle=motionSample and motionSample.rotation0 or math.rad(45)
focus=role=="damage" and {dst[1],dst[2]+th*.04,dst[3]} or {src[1],src[2]+sh*.05,src[3]}
end
if sourceCameraTarget then




focus={sourceCameraTarget[1],sourceCameraTarget[2],sourceCameraTarget[3]}
end
local height
if motionSample and tonumber(motionSample.height) then height=motionSample.height
elseif motion==1 then height=1+9*stable01(inst.presentationSerial or inst.serial or 1,inst.serial or 1,197)
elseif motion==4 and CameraParams and type(CameraParams.mode4)=="function" then height=CameraParams.mode4().height
elseif sourceDecision.retailParams and sourceDecision.retailParams.exact then
local rp=sourceDecision.retailParams
height=rp.heightMin+(rp.heightMax-rp.heightMin)*stable01(inst.presentationSerial or inst.serial or 1,inst.serial or 1,197)
else height=math.max(6,math.min(20,ownerH*.80)) end
local fovRange=distance
if motion==0 then fovRange=math.sqrt(sourceDecision.distance0*sourceDecision.distance0+height*height)
elseif motion==1 then
if motionSample and motionSample.fovRange then fovRange=motionSample.fovRange.near
else
local lateral=25+10*stable01(inst.presentationSerial or inst.serial or 1,inst.serial or 1,181)
fovRange=math.sqrt(lateral*lateral+height*height)
end
elseif motion==2 then fovRange=math.sqrt(distance*distance+height*height)
elseif motion==3 then fovRange=math.sqrt(distance*distance+height*height+angle*angle)
elseif motion==4 and CameraParams and type(CameraParams.mode4)=="function" then fovRange=CameraParams.mode4().range
elseif motion==5 then fovRange=math.sqrt(distance*distance+height*height+math.rad(45)*math.rad(45)) end
if motion~=1 and motionSample and motionSample.worldRotationFormulaExact
and tonumber(motionSample.worldRotation0) and tonumber(motionSample.worldRotation1) then




worldAngle=lerp(motionSample.worldRotation0,motionSample.worldRotation1,p)
eye={focus[1]+math.sin(worldAngle)*distance,focus[2]+height,focus[3]+math.cos(worldAngle)*distance}
sourceDecision.worldRotationApplied=true;sourceDecision.worldRotation=worldAngle
elseif sourceLateral then


eye=offsetEye(focus,forward,right,distance,sourceLateral*axisSign,height)
else
local back=distance*math.cos(angle);local side=distance*math.sin(angle)*axisSign
eye=offsetEye(focus,forward,right,back,side,height)
end
local ownerTiming
local okTiming,timingBasis=pcall(CSM.wazaBasis,CSM,ctx,sourceOwnerSide,sourceOtherSide,nil,{
moveId=tonumber(inst.moveId) or (inst.spec and inst.spec.moveId),style=inst.spec and inst.spec.style,
role=role,sourceStrict=true,ownerRoot=true})
if okTiming and type(timingBasis)=="table" then ownerTiming=timingBasis.ownerCameraTiming end
local fovRanges=motionSample and motionSample.fovRange or fovRange
fov,fovSourceStatus=sourceCameraFov(sourceDecision,ownerH,fovRanges,
inst.presentationSerial or inst.serial or 1,frame,ownerTiming)
elseif role=="damage" then


focus={dst[1],dst[2]+th*.05,dst[3]}
eye=offsetEye(focus,forward,right,fight*.29,fight*.22*axisSign,th*.52)
fov=math.rad(35.5)
elseif compositionStyle=="projectile" then



focus=clerp(src,dst,.08);focus[2]=focus[2]+sh*.03
eye=offsetEye(focus,forward,right,fight*.20,fight*.30*axisSign,sh*.48)
fov=math.rad(36.5)
elseif compositionStyle=="wave" then
focus=clerp(src,dst,.5);focus[2]=focus[2]+avgH*.02
eye=offsetEye(focus,forward,right,fight*.17,fight*.52*axisSign,avgH*.68)
fov=math.rad(40.0)
elseif compositionStyle=="contact" then
focus=clerp(src,dst,.28);focus[2]=focus[2]+avgH*.04
eye=offsetEye(focus,forward,right,fight*.23,fight*.36*axisSign,avgH*.50)
fov=math.rad(36.0)
elseif compositionStyle=="aura" or compositionStyle=="self" then
focus={src[1],src[2]+sh*.08,src[3]}
eye=offsetEye(focus,forward,right,fight*.30,fight*.26*axisSign,sh*.62)
fov=math.rad(34.5)
elseif compositionStyle=="target" then
focus={dst[1],dst[2]+th*.05,dst[3]}
eye=offsetEye(focus,forward,right,fight*.28,fight*.25*axisSign,th*.57)
fov=math.rad(35.5)
else
focus=clerp(src,dst,.25);focus[2]=focus[2]+avgH*.04
eye=offsetEye(focus,forward,right,fight*.25,fight*.34*axisSign,avgH*.56)
fov=math.rad(36.0)
end



local k=tonumber(ctx and ctx.arena and ctx.arena.figureScale) or tonumber(ctx and ctx.services and ctx.services.figureScale) or 1
if not embeddedStageSpace then
eye={eye[1]*k,eye[2]*k,eye[3]*k};focus={focus[1]*k,focus[2]*k,focus[3]*k}
end
local shotId=tostring(inst.presentationSerial or inst.serial or "waza")..":"..role..":"..style
local cut=cameraContinuity.currentSerial~=shotId
cameraContinuity.currentSerial=shotId
local pose={eye=eye,focus=focus,fov=fov,sourceSerial=inst.serial,sourceShotId=shotId,sourceFrame=frame,sourceProgress=p,
sourceStyle=style,sourceRole=role,presentationSerial=inst.presentationSerial,blend=.10,cut=cut,
sourceCameraMotion=sourceDecision and sourceDecision.motion or nil,sourceCameraFlags=sourceDecision and sourceDecision.flags or nil,
sourceCameraParamsFlags=sourceDecision and sourceDecision.paramsFlags or nil,sourceSequenceKind=sourceDecision and sourceDecision.sequenceKind or nil,
sourceCameraMotionScalarExact=sourceDecision and sourceDecision.motionScalarExact==true or false,
sourceCameraMotionRngExact=sourceDecision and sourceDecision.motionRngExact==true or false,
sourceCameraWorldRotationExact=sourceDecision and sourceDecision.motionWorldRotationExact==true or false,
sourceCameraWorldRotationApplied=sourceDecision and sourceDecision.worldRotationApplied==true or false,
sourceCameraWorldRotation=sourceDecision and sourceDecision.worldRotation or nil,
sourceCameraTargetSlot=sourceDecision and sourceDecision.targetSlot or nil,
sourceCameraTargetSlotExact=sourceDecision and sourceDecision.targetSlotExact==true or false,
sourceCameraTargetResolved=sourceDecision and sourceDecision.targetResolved==true or false,
sourceCameraMode1LateralStart=sourceDecision and sourceDecision.motionSample and sourceDecision.motionSample.lateral0 or nil,
sourceCameraMode1LateralEnd=sourceDecision and sourceDecision.motionSample and sourceDecision.motionSample.lateral1 or nil,
sourceCameraEmbedded=sourceDecision and sourceDecision.embedded==true or false,
sourceCameraEmbeddedSize=sourceDecision and sourceDecision.embeddedSize or nil,
sourceCameraEmbeddedCurveDecoded=sourceDecision and sourceDecision.embeddedCurveDecoded==true or false,
sourceCameraEmbeddedDecoded=sourceDecision and sourceDecision.embeddedDecoded==true or false,
sourceCameraEmbeddedTransformUnsupported=sourceDecision and sourceDecision.embeddedTransformUnsupported or nil,
sourceCameraRootNullSpecial=sourceDecision and sourceDecision.rootNullSpecial==true or false,
sourceCameraOwnerBoundCentreExact=sourceDecision and sourceDecision.ownerBoundCentreExact==true or false,
sourceCameraOwnerBoundAnimationIndex=sourceDecision and sourceDecision.ownerBoundAnimationIndex or nil,
sourceCameraOwnerScale=sourceDecision and sourceDecision.ownerScale or nil,
sourceCameraOwnerRelative=sourceDecision and sourceDecision.ownerRelative or nil,
sourceCameraOwnerSelector=sourceDecision and sourceDecision.ownerSelector or nil,
sourceCameraOwnerSelectorExact=sourceDecision and sourceDecision.ownerSelectorExact==true or false,
sourceCameraOwnerSide=sourceDecision and sourceDecision.ownerSide or nil,
sourceCameraOwnerFacing=sourceDecision and sourceDecision.ownerFacing or nil,
sourceCameraOwnerReverse=sourceDecision and sourceDecision.ownerReverse==true or false,
sourceCameraOwnerModelYaw=sourceDecision and sourceDecision.ownerModelYaw or nil,
sourceCameraReverseMirrorApplied=sourceDecision and sourceDecision.reverseMirrorApplied==true or false,
sourceCameraStageScale=sourceDecision and sourceDecision.stageScale or nil,
sourceCameraGridScale=sourceDecision and sourceDecision.gridScale or nil,
sourceCameraGridScaleExact=sourceDecision and sourceDecision.gridScaleExact==true or false,
sourceCameraGridSelector=sourceDecision and sourceDecision.gridSelector or nil,
sourceCameraGridOwnerSide=sourceDecision and sourceDecision.gridOwnerSide or nil,
sourceCameraGridOwnerFacing=sourceDecision and sourceDecision.gridOwnerFacing or nil,
sourceCameraGridFacingApplied=sourceDecision and sourceDecision.gridFacingApplied==true or false,
sourceCameraFovPatternExact=fovSourceStatus and fovSourceStatus.patternExact==true or false,
sourceCameraFovPatternUsed=fovSourceStatus and fovSourceStatus.patternUsed==true or false,
sourceCameraFovTimingExact=fovSourceStatus and fovSourceStatus.timingExact==true or false,
sourceCameraFovBoundsExact=fovSourceStatus and fovSourceStatus.boundsExact==true or false,
sourceCameraFovBoundsProxy=fovSourceStatus and fovSourceStatus.boundsProxy==true or false,
sourceCameraFovBoundGeometryExact=fovSourceStatus and fovSourceStatus.boundGeometryExact==true or false,
sourceCameraFovRangeFormulaExact=fovSourceStatus and fovSourceStatus.rangeFormulaExact==true or false,
sourceCameraFovRangeSampleExact=fovSourceStatus and fovSourceStatus.rangeSampleExact==true or false,
sourceCameraFovTable=fovSourceStatus and fovSourceStatus.tableName or nil,
sourceCameraFovRow=fovSourceStatus and fovSourceStatus.rowIndex or nil,
sourceCameraFovSelection=fovSourceStatus and fovSourceStatus.selection or nil,
sourceCameraFovFrameShift=fovSourceStatus and fovSourceStatus.frameShift or nil,
sourceCameraFovClock=fovSourceStatus and fovSourceStatus.cameraClock or nil,
sourceCameraFovUnsupported=fovSourceStatus and fovSourceStatus.reason or nil,
sourceCameraRetailFrameExact=sourceDecision and sourceDecision.camera and sourceDecision.camera.retailFrameExact==true or false}
cameraContinuity.lastPose={eye={eye[1],eye[2],eye[3]},focus={focus[1],focus[2],focus[3]},fov=fov}
return pose
end
function H.activeModels() local out={};for _,row in pairs(H.models) do out[#out+1]=row end;return out end
function H.finish() releasePost();if H.distortShader and H.distortShader.release then pcall(H.distortShader.release,H.distortShader) end;H.distortShader=nil;for _,rec in pairs(H.effects) do releaseDynamicMeshes(rec) end;H.models={};H.effects={};H.controllers={player={},enemy={}};cameraContinuity={session=nil,currentSerial=nil,transitionFrom=nil,transitionStartFrame=0,lastPose=nil,actionKey=nil,axisSign=nil,motionKey=nil,motionMode=nil,lastMotionMode=nil};return true end

local function releaseLoveObject(obj,seen)
if obj==nil then return end
seen=seen or {}
if seen[obj] then return end
seen[obj]=true
pcall(function()
local release=obj.release
if type(release)=="function" then release(obj) end
end)
end





function H.trimRuntimeMemory()




local ranked={}
for path,asset in pairs(H.modelCache) do
if type(asset)=="table" then ranked[#ranked+1]={path=path,asset=asset,use=tonumber(asset.__cbeUse) or 0} end
end
table.sort(ranked,function(a,b)return a.use>b.use end)
local keep={};for i=1,math.min(4,#ranked) do keep[ranked[i].path]=true end
local keptImages={}
for path in pairs(keep) do
local asset=H.modelCache[path]
if type(asset)=="table" then
for _,g in ipairs(asset.groups or {}) do if type(g)=="table" and g.image then keptImages[g.image]=true end end
for _,img in pairs(asset.textures or {}) do if img then keptImages[img]=true end end
end
end
local seen={}
for path,asset in pairs(H.modelCache) do
if not keep[path] and type(asset)=="table" then
for _,g in ipairs(asset.groups or {}) do
if type(g)=="table" then
releaseLoveObject(g.mesh,seen)
if g.image and not keptImages[g.image] then releaseLoveObject(g.image,seen) end
end
end
for _,img in pairs(asset.textures or {}) do if not keptImages[img] then releaseLoveObject(img,seen) end end
H.modelCache[path]=nil;H.modelErrors[path]=nil
elseif asset==false then


end
end
for key,img in pairs(H.textureCache or {}) do
if not keptImages[img] then releaseLoveObject(img,seen);H.textureCache[key]=nil end
end
H.partsCache={};releasePost();for _,rec in pairs(H.effects) do releaseDynamicMeshes(rec) end;H.models={};H.effects={};H.controllers={player={},enemy={}};H.opaque={};H.lastModel=nil
cameraContinuity={session=nil,currentSerial=nil,transitionFrom=nil,transitionStartFrame=0,lastPose=nil}



return true
end

H._test={runtimeUsable=runtimeUsable,runtimeRoot=runtimeRoot,runtimeMetaPath=runtimeMetaPath,bakeRuntimeCache=bakeRuntimeCache,modelMatrix=modelMatrix,shiftedBasis=shiftedBasis,morphWeights=morphWeights,ensureShader=ensureShader,keyedColor=keyedColor,sourceSurfaceColor=sourceSurfaceColor,readablePostAlpha=readablePostAlpha,drawTraceRibbon=drawTraceRibbon,releaseDynamicMeshes=releaseDynamicMeshes,
sourceModelFrame=sourceModelFrame,modelUpdate=modelUpdate,
relinquishFailedVisual=relinquishFailedVisual,
type6Start=type6Start,filteredPartTransform=filteredPartTransform,partTransformSelector=partTransformSelector,linkedParticleBirthTransform=linkedParticleBirthTransform,
textureAnimationSample=textureAnimationSample,materialAnimationSample=materialAnimationSample,
sourceCameraFov=sourceCameraFov,sourceFovEnvelope=sourceFovEnvelope,sourceParamsFlags=sourceParamsFlags,retailGridScale=retailGridScale}

function H.status()
local m=0;for _ in pairs(H.models) do m=m+1 end
local cached=0;for _,v in pairs(H.modelCache) do if v then cached=cached+1 end end
return {installed=H.installed,activeModels=m,cachedModels=cached,opaqueEntries=#H.opaque,drawError=H.drawError,renderFaults=H.renderFaults or 0,runtimeMeshHits=runtimeMeshHits,runtimeMeshWrites=runtimeMeshWrites,runtimeMeshFallbacks=runtimeMeshFallbacks,hardCache=H.hardCacheStatus(),
provenSourceTypes={controller=1,model=2,particle=3,effect=4,sound=5,ownerController=6},opaqueSourceTypes={},
cameraDecoder="embedded HSD_CObj retail-frame curves plus procedural FOV pattern/timing tables; exact GSmodel-bound geometry and DoPosition range formulas are used when available, retail RNG identity remains unresolved; bound-centre/root-null-Y/unsupported path transforms fail closed",
modelDecoder="native-HSD-60Hz-morph-pages-v4-safe-tev-pass"}
end
return H
