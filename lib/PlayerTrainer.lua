local V = ...
local pendingReaction=nil
local animationClock={}
local BattleDirector=V.BattleDirector
local GeneratedAssets=V.GeneratedAssets
local mod, Mat4, TrainerRig = V.mod, V.Mat4, V.TrainerRig
local TrainerPerformance=V.TrainerPerformance
local BattleSides=V.BattleSides
local TrainerRoster=V.TrainerRoster
local TrainerMorph=V.TrainerMorph
local RuntimeMeshCache=V.RuntimeMeshCache
local P = {}

local function platformOS()
if love and love.system and type(love.system.getOS)=="function" then
local ok,v=pcall(love.system.getOS);if ok and v then return tostring(v) end
end
return "Unknown"
end
local WINDOWS_RUNTIME=platformOS()=="Windows"




local FORMAT=TrainerMorph.DENSE_FORMAT
local FORMAT_COMPACT=TrainerMorph.COMPACT_FORMAT
local DENSE_MESH=TrainerMorph.dense()
local VERTEX=TrainerMorph.VERTEX
local PIXEL=[[
uniform vec3 cameraEye; uniform vec4 tintColor; uniform vec4 materialColor; uniform float useTexture; uniform float unlit; uniform float opacity;
uniform float sourceVertexColor; uniform float sourceVertexAlpha;
uniform float alphaComp0; uniform float alphaRef0; uniform float alphaOp; uniform float alphaComp1; uniform float alphaRef1;
varying vec3 worldPos; varying vec3 worldNormal; varying vec4 sourceColor;
bool sourceAlphaCompare(float value,float mode,float refValue) {
  float a=floor(clamp(value,0.0,1.0)*255.0+0.5); float r=floor(clamp(refValue,0.0,255.0)+0.5);
  if (mode<0.5) return false; if (mode<1.5) return a<r; if (mode<2.5) return a==r; if (mode<3.5) return a<=r;
  if (mode<4.5) return a>r; if (mode<5.5) return a!=r; if (mode<6.5) return a>=r; return true;
}
bool sourceAlphaPass(float value) {
  bool a=sourceAlphaCompare(value,alphaComp0,alphaRef0); bool b=sourceAlphaCompare(value,alphaComp1,alphaRef1);
  if (alphaOp<0.5) return a && b; if (alphaOp<1.5) return a || b; if (alphaOp<2.5) return a != b; return a == b;
}
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
  vec4 texel=Texel(texture,uv); float texAlpha=mix(1.0,texel.a,useTexture);
  float sourceAlpha=mix(1.0,sourceColor.a,sourceVertexAlpha);
  float sourceA=texAlpha*materialColor.a*sourceAlpha;
  if (!sourceAlphaPass(sourceA)) discard;
  float a=sourceA*tintColor.a*opacity*color.a;
  /* Preserve the source HSD diffuse multiplier on textured trainer groups. */
  vec3 vertexRGB=mix(vec3(1.0),sourceColor.rgb,sourceVertexColor);
  vec3 sourceBase=mix(materialColor.rgb,texel.rgb*materialColor.rgb,useTexture)*vertexRGB;
  if (unlit>0.5) return vec4(sourceBase*tintColor.rgb,a);
  vec3 n=normalize(worldNormal); vec3 lightDir=normalize(vec3(-0.42,0.82,0.38));
  float ndl=dot(n,lightDir); float key=max(ndl,0.0); float back=max(-ndl,0.0); float hemi=clamp(n.y*0.5+0.5,0.0,1.0);
  vec3 viewDir=normalize(cameraEye-worldPos); float rim=pow(1.0-clamp(abs(dot(n,viewDir)),0.0,1.0),2.4);
  float light=0.73+key*0.25+back*0.055+hemi*0.055; vec3 rgb=sourceBase*light+vec3(0.040,0.047,0.055)*rim;
  rgb=clamp((rgb-vec3(0.5))*1.035+vec3(0.5),vec3(0.0),vec3(1.0));
  return vec4(rgb*tintColor.rgb,a);
}]]

local scene,sceneKey,shader,shadowImage,shadowMesh,errorText
local currentConfig,currentModel,currentReason=nil,"red",nil
local DEFAULT_PLAYER_MODEL=currentModel
local battleKey,age,activeNow=nil,0,false
local actionKind,actionAge,actionStrength=nil,0,0
local performanceState=TrainerPerformance and TrainerPerformance.newState("red") or nil
local currentMotion=nil
local initialThrowQueued=false
local initialOpeningQueued=false
local lastSendingOut=false
local resultSeen=nil
local pendingFrustration=nil
local pendingApproval=nil


local capture=nil
local captureSuccessTemplate=nil
local captureSuccessActive=nil
local ballMeshRed,ballMeshWhite,ballMeshBlack,ballTexture
local ballError=nil
local ballDrawFrames=0



local captureAssetIndex=nil
local captureAssetError=nil
local captureSourceDrawFrames=0



local SOURCE_BALL_DIAMETER=0.365
local FINAL_X,FINAL_Z=13.2,25.8



local SENDOUT_TARGET_X,SENDOUT_TARGET_Z=0,14.5
local CAPTURE_TARGET_X,CAPTURE_TARGET_Z=0,-14.5




local CAPTURE_T={charge=.62,throw=.86,impact=.34,absorb=1.28,fall=.82,settle=.36,shake=.90,outcome=1.08}
local function captureMilestones(shakes)
local a=CAPTURE_T.charge
local b=a+CAPTURE_T.throw
local c=b+CAPTURE_T.impact
local d=c+CAPTURE_T.absorb
local e=d+CAPTURE_T.fall
local f=e+CAPTURE_T.settle
local g=f+math.max(0,tonumber(shakes) or 0)*CAPTURE_T.shake
return a,b,c,d,e,f,g,g+CAPTURE_T.outcome
end
local function presentationNow()
if love and love.timer and type(love.timer.getTime)=="function" then
local ok,v=pcall(love.timer.getTime);if ok and tonumber(v) then return tonumber(v) end
end
return nil
end
local drawFrames=0


local arenaModelScale=0.405
local MODEL_SCALE=0.405
local FINAL_YAW=math.pi

local function clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function smooth(t) t=clamp(t,0,1);return t*t*(3-2*t) end
local function log(ctx,level,msg,...)
local l=ctx and ctx.services and ctx.services.log
if l and type(l[level])=="function" then pcall(l[level],l,"[ColosseumPlayerTrainer] "..msg,...) end
end
local function readLua(path)
local src,readErr=GeneratedAssets.read(path);if not src then return nil,readErr or ("missing "..path) end
local chunk,err=load(src,"@"..tostring(mod.path or mod.id).."/"..path);if not chunk then return nil,err end
local ok,value=pcall(chunk);if not ok then return nil,value end;return value
end


local TRAINER_RUNTIME_MESH_VERSION=1
local playerRuntimeHits,playerRuntimeFallbacks=0,0
local function trainerRuntimeTag(wanted) return tostring(wanted or "trainer"):gsub("[^%w_%-]","_") end
local function trainerRuntimeRoot(wanted) return "cache/runtime_mesh_v1/trainers/"..trainerRuntimeTag(wanted) end
local function trainerRuntimeMetaPath(wanted) return trainerRuntimeRoot(wanted).."/base.lua" end
local function trainerRuntimeBinPath(wanted,i) return trainerRuntimeRoot(wanted)..("/base_%02d.f32"):format(tonumber(i) or 0) end
local function trainerSourceSize(cfg,meta)
local info=GeneratedAssets and GeneratedAssets.info and GeneratedAssets.info(cfg and cfg.cache) or nil
if not info then return nil end



return tonumber(info.size) or tonumber(meta and meta.sourceSize) or 0
end
local function trainerRuntimeUsable(meta,wanted,sourceSize)
if not (DENSE_MESH and RuntimeMeshCache and type(RuntimeMeshCache.readLua)=="function") then return false end
if type(meta)~="table" or tonumber(meta.runtimeMeshVersion)~=TRAINER_RUNTIME_MESH_VERSION or tonumber(meta.formatVersion)~=27 then return false end
if sourceSize==nil or type(meta.groups)~="table" or #meta.groups==0 then return false end
local recorded=tonumber(meta.sourceSize) or 0
if sourceSize>0 and recorded>0 and recorded~=sourceSize then return false end
for i,g in ipairs(meta.groups) do
local path=type(g)=="table" and (g.runtimeBin or trainerRuntimeBinPath(wanted,i)) or nil
local info=path and GeneratedAssets.info and GeneratedAssets.info(path) or nil
if not info then return false end
local size=tonumber(info.size)
if size and (size<192 or size%192~=0) then return false end
end
return true
end
local function releaseLoveObject(obj,seen)
if obj==nil then return end
seen=seen or {};if seen[obj] then return end;seen[obj]=true
pcall(function() if type(obj.release)=="function" then obj:release() end end)
end
local function releaseScene(entry)
if type(entry)~="table" then return end
if TrainerMorph.releaseTracks then TrainerMorph.releaseTracks(entry.groups) end
local seen={}
for _,g in ipairs(entry.groups or {}) do if type(g)=="table" then releaseLoveObject(g.mesh,seen) end end
for _,img in pairs(entry.textures or {}) do releaseLoveObject(img,seen) end
end

local function loadCaptureAssetIndex()
if captureAssetIndex~=nil then return captureAssetIndex or nil,captureAssetError end
local idx,err=readLua("cache/capture/index.lua")
if type(idx)=="table" and type(idx.balls)=="table" then
captureAssetIndex=idx;captureAssetError=nil;return idx
end
captureAssetIndex=false;captureAssetError=tostring(err or "native Colosseum capture cache unavailable")
return nil,captureAssetError
end
local function captureBallId(value)
local idx=loadCaptureAssetIndex()
local raw=tostring(value or "POKE_BALL"):upper():gsub("[^A-Z0-9]+","_"):gsub("^_+",""):gsub("_+$","")
if idx and idx.aliases and idx.aliases[raw] then return idx.aliases[raw] end
if raw:find("MASTER",1,true) then return "master" end
if raw:find("ULTRA",1,true) or raw:find("HYPER",1,true) then return "ultra" end
if raw:find("GREAT",1,true) or raw:find("SUPER",1,true) then return "great" end
if raw:find("SAFARI",1,true) then return "safari" end
if raw:find("PREMIER",1,true) or raw:find("PREMIRE",1,true) then return "premier" end
if raw:find("LUXURY",1,true) or raw:find("GORGEOUS",1,true) or raw:find("GORGEUS",1,true) then return "luxury" end
if raw:find("REPEAT",1,true) then return "repeatball" end
if raw:find("TIMER",1,true) then return "timer" end
if raw:find("DIVE",1,true) then return "dive" end
if raw:find("NEST",1,true) then return "nest" end
if raw:find("NET",1,true) then return "net" end
return "poke"
end
local function sourceBallAsset(phase,ballOverride)
local idx=loadCaptureAssetIndex();if not idx then return nil end
local id=ballOverride or captureBallId(capture and capture.ball)
local row=idx.balls and idx.balls[id];local phases=row and row.phases



if not (row and row.sourceReady==true and row.fallback~=true and row.staticSource==true and phases) then return nil end
local key=(phase=="shake" and "shake")
or ((phase=="fall" or phase=="settle" or phase=="caught") and "land")
or (phase=="breakout" and "miss") or "throw"
return phases[key] or phases.shake, id, key
end
local function sourceAssetFrame(asset,phase,u,bp)
if asset and asset.staticSource==true then return 0 end
local a=asset and asset.animation or nil
local finish=math.max(0,tonumber(a and a.endFrame) or 0)
if finish<=0 then return 0 end
local q=clamp(tonumber(u) or 0,0,1)






if phase=="shake" or phase=="caught" then return 0 end
return q*finish
end
local function throwFacing(origin,target)
local x=(target[1] or 0)-(origin[1] or 0)
local z=(target[3] or 0)-(origin[3] or 0)
if math.abs(x)+math.abs(z)<1e-8 then return 0 end
if math.atan2 then return math.atan2(x,z) end
if z==0 then return x>0 and math.pi/2 or -math.pi/2 end
local a=math.atan(x/z)
return z<0 and a+(x>=0 and math.pi or -math.pi) or a
end
local function sourceBallModel(asset,bp)
local b=asset and asset.bounds or {};local mn=b.min or {-1,-1,-1};local mx=b.max or {1,1,1};local c=b.center or {0,0,0}
local sx=math.abs((tonumber(mx[1]) or 1)-(tonumber(mn[1]) or -1))
local sy=math.abs((tonumber(mx[2]) or 1)-(tonumber(mn[2]) or -1))
local sz=math.abs((tonumber(mx[3]) or 1)-(tonumber(mn[3]) or -1))
local span=math.max(.0001,sx,sy,sz)
local sc=SOURCE_BALL_DIAMETER/span
local center=Mat4.translate(-(tonumber(c[1]) or 0),-(tonumber(c[2]) or 0),-(tonumber(c[3]) or 0))
local scaled=Mat4.mul(Mat4.scale(sc,sc,sc),center)


if bp and bp.kind=="sendout" then
return Mat4.mul(Mat4.translate(bp[1],bp[2],bp[3]),
Mat4.mul(Mat4.rotateY(tonumber(bp.yaw) or 0),scaled))
end





local airborne=bp and (bp.kind=="throw" or bp.kind=="fall")
if airborne then
return Mat4.mul(Mat4.translate(bp[1],bp[2],bp[3]),
Mat4.mul(Mat4.rotateZ(tonumber(bp.spin) or 0),scaled))
end
local rock=(bp and bp.kind=="shake") and (tonumber(bp.rock) or 0) or 0
if math.abs(rock)>1e-6 then
local radius=SOURCE_BALL_DIAMETER*.50
return Mat4.mul(Mat4.translate(bp[1],bp[2]-radius,bp[3]),
Mat4.mul(Mat4.rotateZ(rock),Mat4.mul(Mat4.translate(0,radius,0),scaled)))
end
return Mat4.mul(Mat4.translate(bp[1],bp[2],bp[3]),scaled)
end
local function imageFromRaw(spec,wrapS,wrapT)
local bytes,readErr=GeneratedAssets.read(spec.path);if not bytes then return nil,readErr or ("missing "..tostring(spec.path)) end
local ok,data=pcall(love.image.newImageData,spec.w,spec.h,"rgba8",bytes);if not ok then return nil,data end
local ok2,img=pcall(love.graphics.newImage,data);if not ok2 then return nil,img end
if img.setFilter then
local minFilt=tonumber(spec.effectiveMinFilt)
if minFilt==nil then local raw=tonumber(spec.minFilt) or 5;minFilt=spec.mipmap and raw or raw%2 end
local minName=(minFilt%2)==0 and "nearest" or "linear";local magName=(tonumber(spec.magFilt) or 1)==0 and "nearest" or "linear"
local gxAniso=math.max(0,math.min(2,math.floor(tonumber(spec.maxAnisotropy) or 0)));local anisotropy=2^gxAniso
local okf=pcall(img.setFilter,img,minName,magName,anisotropy);if not okf then pcall(img.setFilter,img,minName,magName) end
end
if img.setWrap then pcall(img.setWrap,img,wrapS or "clamp",wrapT or "clamp") end
return img
end
local function shadowVertex(x,y,z,u,v)
if not DENSE_MESH then return TrainerMorph.staticCompactVertex(x,y,z,u,v,0,1,0) end
return TrainerMorph.staticDenseVertex(x,y,z,u,v,0,1,0)
end
local function ensureShadow()
if shadowImage and shadowMesh then return true end
local ok,data=pcall(love.image.newImageData,64,64);if not ok then return nil,data end
for y=0,63 do for x=0,63 do
local dx=(x-31.5)/31.5;local dy=(y-31.5)/31.5;local d=math.sqrt(dx*dx+dy*dy);local a=clamp(1-d,0,1);a=a*a*0.40
data:setPixel(x,y,1,1,1,a)
end end
shadowImage=love.graphics.newImage(data);shadowImage:setFilter("linear","linear")
local verts={shadowVertex(-2.2,.035,-1.05,0,0),shadowVertex(2.2,.035,-1.05,1,0),shadowVertex(2.2,.035,1.05,1,1),shadowVertex(-2.2,.035,-1.05,0,0),shadowVertex(2.2,.035,1.05,1,1),shadowVertex(-2.2,.035,1.05,0,1)}
shadowMesh=love.graphics.newMesh(DENSE_MESH and FORMAT or FORMAT_COMPACT,verts,"triangles","static");shadowMesh:setTexture(shadowImage);return true
end

local function ballVertex(x,y,z,u,v)
if not DENSE_MESH then return TrainerMorph.staticCompactVertex(x,y,z,u,v,0,1,0) end
return TrainerMorph.staticDenseVertex(x,y,z,u,v,0,1,0)
end
local function sphereBand(y0,y1,r,segments)
local out={}
segments=segments or 12
local function ringY(t) return math.sin(t)*r end
local function ringR(t) return math.cos(t)*r end
for i=0,segments-1 do
local a0=(i/segments)*math.pi*2; local a1=((i+1)/segments)*math.pi*2
local r0,r1=ringR(y0),ringR(y1); local yy0,yy1=ringY(y0),ringY(y1)
local p00={math.cos(a0)*r0,yy0,math.sin(a0)*r0}; local p01={math.cos(a1)*r0,yy0,math.sin(a1)*r0}
local p10={math.cos(a0)*r1,yy1,math.sin(a0)*r1}; local p11={math.cos(a1)*r1,yy1,math.sin(a1)*r1}
local function add(p,u,v) out[#out+1]=ballVertex(p[1],p[2],p[3],u,v) end
add(p00,0,0);add(p10,0,1);add(p11,1,1); add(p00,0,0);add(p11,1,1);add(p01,1,0)
end
return out
end
local function ensureBall()
if ballMeshRed and ballMeshWhite and ballMeshBlack then return true end
if not (love and love.graphics and love.image) then
ballError="LÖVE image/graphics unavailable"
return false
end
local ok,err=pcall(function()
local id=love.image.newImageData(1,1)
id:setPixel(0,0,1,1,1,1)
ballTexture=love.graphics.newImage(id)
local red,white,black={},{},{}



for j=0,4 do
local a=.08+(j/5)*(math.pi/2-.08)
local b=.08+((j+1)/5)*(math.pi/2-.08)
local top=sphereBand(a,b,1,18);for _,v in ipairs(top) do red[#red+1]=v end
local bot=sphereBand(-b,-a,1,18);for _,v in ipairs(bot) do white[#white+1]=v end
end
local eq=sphereBand(-.105,.105,1.025,18);for _,v in ipairs(eq) do black[#black+1]=v end
local function make(vs)
local m=love.graphics.newMesh(DENSE_MESH and FORMAT or FORMAT_COMPACT,vs,"triangles","static")
m:setTexture(ballTexture)
return m
end
ballMeshRed,ballMeshWhite,ballMeshBlack=make(red),make(white),make(black)
end)
if not ok then
ballMeshRed,ballMeshWhite,ballMeshBlack,ballTexture=nil,nil,nil,nil
ballError=tostring(err)
return false
end
ballError=nil
return true
end






local function redStrapRelief(v)
local row={}; for j=1,#v do row[j]=v[j] end
local x,y,z=tonumber(v[1]) or 0,tonumber(v[2]) or 0,tonumber(v[3]) or 0
local u,vv=tonumber(v[4]) or 0,tonumber(v[5]) or 0


local strap=math.abs(x)>.72 and math.abs(x)<1.34 and y>9.72 and y<12.30
and z>.32 and z<1.08 and u>.94 and u<1.12 and vv>.12 and vv<.30
if not strap then return row end
local side=x>=0 and 1 or -1


local t=clamp((y-9.72)/(12.30-9.72),0,1)
local crown=math.sin(t*math.pi)
local shoulder=smooth(clamp((t-.58)/.42,0,1))




local dx=side*(.012+.025*crown+.010*shoulder)
local dz=.060+.120*crown+.025*shoulder


for _,base in ipairs({1,13,16,19,22,25,28,31,34,37,40,43,46}) do
if row[base]~=nil then row[base]=row[base]+dx end
if row[base+2]~=nil then row[base+2]=row[base+2]+dz end
end



local nx,ny,nz=tonumber(row[10]) or 0,tonumber(row[11]) or 0,tonumber(row[12]) or 1
nx=nx+side*.09; nz=nz+.14
local nl=math.sqrt(nx*nx+ny*ny+nz*nz)
if nl>.0001 then row[10],row[11],row[12]=nx/nl,ny/nl,nz/nl end
return row
end

local function preparePlayerVertices(vertices,isRed)
if not isRed then
local rows=vertices or {};for _,row in ipairs(rows) do if type(row)=="table" then row[49]=nil end end
return rows
end
local out={}
for i,v in ipairs(vertices or {}) do
local row=redStrapRelief(v)
row[49]=nil
out[i]=row
end
return out
end

local function playerModelFor(ctx)
if TrainerRoster and type(TrainerRoster.playerModelFor)=="function" then
return TrainerRoster.playerModelFor(ctx)
end
return {id="red",label="RED",cache="cache/trainers/red/model_cache.lua",playerScaleMul=1,pivotY=7.4,playerPivotY=7.4,rig="red"},"legacy-red"
end
local function applyModelScale()

local shared=TrainerRoster and type(TrainerRoster.modelScale)=="function"
and TrainerRoster.modelScale(currentConfig,scene and sceneKey==currentModel and scene.bounds or nil)
if shared then MODEL_SCALE=shared;return end
local mul=currentConfig and tonumber(currentConfig.playerScaleMul) or 1
MODEL_SCALE=arenaModelScale*(mul or 1)
end


local function loadScene(ctx)
local cfg,reason=playerModelFor(ctx)
if not cfg then return nil,reason or "player-model-unavailable" end
local wanted=tostring(cfg.id or cfg.label or cfg.cache or "player")
if scene and shader and sceneKey==wanted then currentReason=reason;return scene end
if sceneKey~=wanted then
releaseScene(scene);scene=nil;errorText=nil;sceneKey=nil
end
currentConfig=cfg;currentModel=wanted;currentReason=reason;applyModelScale()
if errorText then return nil,errorText end
if not (love and love.graphics and love.image and love.graphics.newMesh and love.graphics.newShader) then errorText="LÖVE mesh/shader API unavailable";return nil,errorText end




local cache,err,fromRuntime
local rt
if cfg.directSource~=false and DENSE_MESH and RuntimeMeshCache and type(RuntimeMeshCache.readLua)=="function" then
rt=select(1,RuntimeMeshCache.readLua(trainerRuntimeMetaPath(wanted)))
local sourceSize=trainerSourceSize(cfg,rt)
if trainerRuntimeUsable(rt,wanted,sourceSize) then cache=rt;fromRuntime=true;playerRuntimeHits=playerRuntimeHits+1 end
end
if not cache then cache,err=readLua(cfg.cache) end
if not cache then errorText=tostring(err);return nil,errorText end
if tonumber(cache.formatVersion)~=27 then
errorText=(cfg.label or wanted).." trainer cache format "..tostring(cache.formatVersion or "?").." is stale; rebuild required for dense source animation"
return nil,errorText
end

local textures,groups={},{}
local canonicalFallback=nil
for i,g in ipairs(cache.groups or {}) do
local path=g.texture and g.texture.path
local wrapS,wrapT="clamp","clamp"
if path and TrainerMorph.textureWrap then wrapS,wrapT=TrainerMorph.textureWrap(g.texture,g,wanted) end
local textureKey=path and table.concat({path,wrapS,wrapT,tostring(g.texture.effectiveMinFilt or g.texture.minFilt or 1),
tostring(g.texture.magFilt or 1),tostring(g.texture.maxAnisotropy or 0)},":")
local img=textureKey and textures[textureKey] or nil
if path and not img then img,err=imageFromRaw(g.texture,wrapS,wrapT);if not img then errorText=tostring(err);releaseScene({groups=groups,textures=textures});return nil,errorText end;textures[textureKey]=img end
local mesh,meshErr,denseWeighted
if fromRuntime and RuntimeMeshCache and type(RuntimeMeshCache.meshFromPath)=="function" then
mesh,meshErr=RuntimeMeshCache.meshFromPath(FORMAT,g.runtimeBin or trainerRuntimeBinPath(wanted,i),48,"static")
end
if not mesh then
local sourceGroup=g
if fromRuntime and type(g.vertices)~="table" then
if canonicalFallback==nil then
local canonical,cerr=readLua(cfg.cache)
if type(canonical)=="table" and tonumber(canonical.formatVersion)==27 then canonicalFallback=canonical else canonicalFallback=false;meshErr=tostring(cerr or meshErr or "canonical player trainer fallback unavailable") end
end
if canonicalFallback and canonicalFallback.groups and canonicalFallback.groups[i] then sourceGroup=canonicalFallback.groups[i];playerRuntimeFallbacks=playerRuntimeFallbacks+1 end
end
local vertices=sourceGroup and sourceGroup.vertices or {}
if type(vertices)~="table" or #vertices==0 then
errorText=(cfg.label or wanted).." mesh "..i.." runtime sidecar failed and canonical vertices are unavailable: "..tostring(meshErr or "empty mesh")
releaseScene({groups=groups,textures=textures});return nil,errorText
end
local weighted=preparePlayerVertices(vertices,currentModel==DEFAULT_PLAYER_MODEL and not cfg.directSource)
denseWeighted=weighted
if not DENSE_MESH then
local compact={};for ri,row in ipairs(denseWeighted) do compact[ri]=TrainerMorph.compactVertex(row,nil,nil) end;weighted=compact
end
local ok,built=pcall(love.graphics.newMesh,DENSE_MESH and FORMAT or FORMAT_COMPACT,weighted,"triangles",DENSE_MESH and "static" or "dynamic")
if not ok then errorText=(cfg.label or wanted).." mesh "..i..": "..tostring(built);releaseScene({groups=groups,textures=textures});return nil,errorText end
mesh=built
end
if img then mesh:setTexture(img) end
local d=g.diffuse or {1,1,1};local a=g.ambient or {0,0,0};local sp=g.specular or {0,0,0}
local renderFlags=tonumber(g.renderFlags) or 0
local alphaMode=math.floor(renderFlags/0x2000)%4
groups[#groups+1]={mesh=mesh,material=g.material,image=img,textured=img~=nil,
diffuse={tonumber(d[1]) or 1,tonumber(d[2]) or 1,tonumber(d[3]) or 1},
ambient={tonumber(a[1]) or 0,tonumber(a[2]) or 0,tonumber(a[3]) or 0},
specular={tonumber(sp[1]) or 0,tonumber(sp[2]) or 0,tonumber(sp[3]) or 0},shininess=tonumber(g.shininess) or 0,
alpha=tonumber(g.alpha) or 1,xlu=g.xlu==true,noz=g.noz==true,
pe=g.pe,useConstant=g.useConstant==true,useVertexColor=g.useVertexColor==true,
useVertexAlpha=alphaMode==2 or alphaMode==3,useDiffuseLighting=g.useDiffuseLighting~=false,
renderFlags=renderFlags,shadow=g.shadow==true,effect=g.effect==true,
poseSourceRows=(not DENSE_MESH) and denseWeighted or nil,posePair=nil}
end
if not shader then
local ok,sh=pcall(love.graphics.newShader,VERTEX,PIXEL);if not ok or not sh then errorText=(cfg.label or wanted).." shader: "..tostring(sh or "unavailable");releaseScene({groups=groups,textures=textures});return nil,errorText end
shader=sh
end
local sok,serr=ensureShadow();if not sok then errorText=(cfg.label or wanted).." shadow: "..tostring(serr);releaseScene({groups=groups,textures=textures});return nil,errorText end
scene={groups=groups,bounds=cache.bounds,source=cache.source,textures=textures,
jointPositions=cache.jointPositions,jointParents=cache.jointParents,poseJointPositions=cache.poseJointPositions,
releaseJoint=tonumber(cache.releaseJoint),releaseSide=tonumber(cache.releaseSide),
releaseJointScore=tonumber(cache.releaseJointScore),runtimeSidecar=fromRuntime==true};sceneKey=wanted
scene.nativeTrack=TrainerMorph.loadTracks(wanted,groups)
scene.drawGroups=TrainerMorph.materialOrder and TrainerMorph.materialOrder(groups) or groups


applyModelScale()
log(ctx,"info","loaded player trainer %s: %d material groups%s",cfg.label or wanted,#groups,fromRuntime and " (runtime sidecar)" or "")
return scene
end
local function battleOf(ctx) if type(ctx)~="table" then return nil end;return ctx.battle or (ctx.kind and ctx) or nil end
local function enabled(ctx)
local cfg=playerModelFor(ctx)
if not cfg then return false end
local b=battleOf(ctx)
if battleKey==b and errorText and not scene then return false end
return true
end
function P:prewarm(ctx)
local s,err=loadScene(ctx)
if s then
local source=loadCaptureAssetIndex()
if not source then pcall(ensureBall) end
end
return s~=nil,err
end
function P:shouldRender(ctx) return enabled(ctx) end
local normalReleasePoint
local captureTargetY
local sendoutTarget
local sendoutForward
local arenaForward={0,-1}
local trigger,performanceId,actionDuration
function P:begin(ctx)
battleKey=battleOf(ctx);age=0;actionKind=nil;actionAge=0;actionStrength=0;initialThrowQueued=false;initialOpeningQueued=false;lastSendingOut=false;resultSeen=nil;pendingFrustration=nil;pendingApproval=nil;pendingReaction=nil;capture=nil;drawFrames=0;currentMotion=nil
performanceState=TrainerPerformance and TrainerPerformance.resetState(performanceState,"red") or nil
activeNow=self:shouldRender(ctx)
if activeNow then
local loaded,err=loadScene(ctx)
if not loaded then
activeNow=false
log(ctx,"error","Player Colosseum actor failed to load: %s",tostring(err or errorText))
return false,err or errorText
end
end
return true
end
local function stopCaptureSuccessAudio()
if captureSuccessActive and type(captureSuccessActive.stop)=="function" then pcall(captureSuccessActive.stop,captureSuccessActive) end
captureSuccessActive=nil
end
local function ensureCaptureSuccessAudio(ctx)
if not (love and love.audio and love.audio.newSource and GeneratedAssets and GeneratedAssets.fileData) then return false end
if captureSuccessTemplate==nil then
local fd,err=GeneratedAssets.fileData("assets/audio/capture/me_snatch.wav","me_snatch.wav")
if not fd then captureSuccessTemplate=false;log(ctx,"warn","Colosseum capture-success jingle unavailable: %s",tostring(err));return false end
local ok,src=pcall(love.audio.newSource,fd,"static")
captureSuccessTemplate=(ok and src) or false
if captureSuccessTemplate and type(captureSuccessTemplate.setLooping)=="function" then pcall(captureSuccessTemplate.setLooping,captureSuccessTemplate,false) end
if not captureSuccessTemplate then log(ctx,"warn","Colosseum capture-success jingle failed to load") end
end
return captureSuccessTemplate and true or false
end
local function playCaptureSuccessAudio(ctx)
if not ensureCaptureSuccessAudio(ctx) then return false end
local src=captureSuccessTemplate
if type(src.clone)=="function" then local ok,v=pcall(src.clone,src);if ok and v then src=v end end
stopCaptureSuccessAudio();captureSuccessActive=src
if type(src.play)=="function" then local ok=pcall(src.play,src);return ok end
return false
end

function P:update(ctx,dt)
local b=battleOf(ctx);if b~=battleKey then stopCaptureSuccessAudio();battleKey=b;age=0;actionKind=nil;actionAge=0;actionStrength=0;initialThrowQueued=false;initialOpeningQueued=false;lastSendingOut=false;resultSeen=nil;pendingFrustration=nil;pendingApproval=nil;pendingReaction=nil;capture=nil;currentMotion=nil;performanceState=TrainerPerformance and TrainerPerformance.resetState(performanceState,"red") or nil end
activeNow=self:shouldRender(ctx);dt=TrainerPerformance and TrainerPerformance.realDt(ctx,dt,animationClock) or (tonumber(dt) or 0)
if activeNow then
local cfg=playerModelFor(ctx)
if cfg and sceneKey~=tostring(cfg.id or cfg.label or cfg.cache or "player") then loadScene(ctx) end
age=age+dt





if not initialOpeningQueued and age>=.72 then initialOpeningQueued=true;trigger("opening",.88) end
local sending=(b and b.sendingOut==true) or false



local poof=(sending and b and b.animPlaying and b.animName=="POOF_ANIM") and true or false
local growing=(b and b.growIn and b.growIn.battler==b.player) and true or false



if (poof or growing) and not initialThrowQueued then
initialThrowQueued=true
trigger("throw",1.0)
end
if not sending and not poof and not growing then initialThrowQueued=false end
lastSendingOut=sending
local result=b and b.result
if result and result~=resultSeen then
resultSeen=result
if result=="win" or result=="victory" then trigger("victory",1.0)
elseif result=="lose" or result=="loss" or result=="defeat" then trigger("defeat",1.0) end
end
end
if actionKind then actionAge=actionAge+dt end
if capture then



local wall=presentationNow();local step=dt
if wall and capture.lastClock then step=math.max(0,math.min(.12,wall-capture.lastClock)) end
if wall then capture.lastClock=wall end
capture.age=(capture.age or 0)+math.max(0,tonumber(step) or 0)
if capture.caught and not capture.successSfxPlayed and capture.age>=(capture.outcomeAt or 0) then
capture.successSfxPlayed=true
capture.successSfxOwned=playCaptureSuccessAudio(ctx)==true
end
if capture.age>(capture.duration or 12.0) then capture.done=true end
end
if activeNow and pendingFrustration then
pendingFrustration=pendingFrustration-dt
if pendingFrustration<=0 then pendingFrustration=nil;pendingApproval=nil;pendingReaction=nil;trigger("frustration",1.0) end
elseif activeNow and pendingApproval then
pendingApproval=pendingApproval-dt
if pendingApproval<=0 then pendingApproval=nil;trigger("approval",.88) end
end
if activeNow and TrainerPerformance then
local id=performanceId();local duration=actionKind and actionDuration(actionKind) or nil
if actionKind and actionAge>(duration or 1.2) then
if TrainerPerformance.terminal(actionKind) then actionAge=duration
else actionKind=nil;actionStrength=0 end
end
if not actionKind and pendingReaction then
local queued=pendingReaction;pendingReaction=nil;trigger(queued.kind,queued.strength)
end
currentMotion,performanceState=TrainerPerformance.step(performanceState,id,age,actionKind,actionAge,actionStrength,"player",dt)
end
end
function P:finish() stopCaptureSuccessAudio();battleKey=nil;age=0;activeNow=false;actionKind=nil;actionAge=0;actionStrength=0;initialThrowQueued=false;initialOpeningQueued=false;lastSendingOut=false;resultSeen=nil;pendingFrustration=nil;pendingApproval=nil;pendingReaction=nil;capture=nil;currentMotion=nil;performanceState=TrainerPerformance and TrainerPerformance.resetState(performanceState,"red") or nil end
local function entryPose()
if battleKey and battleKey.__mtbHub==true then




return {x=0,y=0,z=0,yaw=FINAL_YAW,progress=1}
end
local p=smooth((age-0.06)/1.05)



local sx=FINAL_X+2.8
local sz=FINAL_Z+5.0
return {x=sx+(FINAL_X-sx)*p,y=-.12+.12*p,z=sz+(FINAL_Z-sz)*p,yaw=FINAL_YAW-.10*(1-p),progress=p}
end
local function payloadSide(ctx,payload,fields)
return BattleSides.payload(ctx,payload,fields)
end
local other=BattleSides.other

performanceId=function()
return tostring((currentConfig and currentConfig.id) or currentModel or "red"):lower()
end
actionDuration=function(kind)
if not kind then return nil end
local source=scene and scene.nativeTrack and TrainerMorph and TrainerMorph.sourceDuration
and TrainerMorph.sourceDuration(scene.nativeTrack,kind) or nil
if tonumber(source) and source>0 then return source end
return TrainerPerformance and TrainerPerformance.duration(performanceId(),kind) or nil
end
trigger=function(kind,strength,force)
if TrainerPerformance and TrainerPerformance.terminal(actionKind) then return false end
if not force and TrainerPerformance and not TrainerPerformance.shouldTrigger({battle=battleKey},actionKind,actionAge,kind,actionDuration(actionKind)) then
if kind~=actionKind and not (actionKind=="concern" and kind=="brace") then
pendingReaction=TrainerPerformance.queueReaction(pendingReaction,kind,strength)
end
return false
end
if TrainerPerformance and TrainerPerformance.terminal(kind) then pendingReaction=nil;pendingFrustration=nil;pendingApproval=nil end
normalReleasePoint=nil;sendoutTarget=nil;sendoutForward=nil
actionKind=kind;actionAge=0;actionStrength=strength or 1
return true
end

function P:event(ctx,name,payload)
payload=type(payload)=="table" and payload or {}
local b0=battleOf(ctx)
local gen2=b0 and b0.__cbeGeneration==2
local gen3Owned=b0 and b0.__cbeGeneration==3 and V.Gen3Presentation
and V.Gen3Presentation.session and V.Gen3Presentation.session.screen==b0
local queueSync=b0 and b0.__cbePresentationQueueSync==true
if queueSync and ((gen2 or gen3Owned) and
(name=="battle.move_used" or name=="battle.damage_dealt" or name=="battle.fainted")) then return end
if queueSync and name=="battle.fainted" then return end
local semantic=name
if name=="battle.presentation_damage" then semantic="battle.damage_dealt"
elseif name=="battle.presentation_faint" then semantic="battle.fainted" end
if semantic=="battle.move_used" or name=="battle.presentation_move" then
local actorSide=payloadSide(ctx,payload,{"user","attacker","source","battler","side"})
if actorSide=="player" then
local b=battleOf(ctx)
local stillReleasing=b and (b.sendingOut==true or (b.growIn and b.growIn.battler==b.player))




trigger("command",1.0,actionKind=="throw" and not stillReleasing)
end
elseif semantic=="battle.damage_dealt" then
local targetSide=payloadSide(ctx,payload,{"target","defender","targetSide","defenderSide"})
if not targetSide then local actorSide=payloadSide(ctx,payload,{"user","attacker","source","side"});targetSide=other(actorSide) end
if targetSide=="player" then
local b=battleOf(ctx);local dmg=tonumber(payload.damage) or 0
local maxhp=b and b.player and b.player.mon and b.player.mon.stats and tonumber(b.player.mon.stats.hp) or 1
local kind,strength=TrainerPerformance.damageReaction(dmg,maxhp)
if kind then trigger(kind,strength) end
end
elseif name=="battle.status_inflicted" then
local targetSide=payloadSide(ctx,payload,{"target","battler","side","targetSide"})
if targetSide=="player" then trigger("concern",.72) end
elseif name=="battle.battler_switched" then






local switched=payloadSide(ctx,payload,{"side","battler","target","switchedSide"})
if switched=="player" then
initialThrowQueued=false
end
elseif semantic=="battle.fainted" then
local fainted=payloadSide(ctx,payload,{"battler","target","side","faintedSide","targetSide"})




if fainted=="player" then
local fd=BattleDirector and type(BattleDirector.faintDuration)=="function"
and BattleDirector:faintDuration(ctx,"player") or nil
pendingApproval=nil
pendingFrustration=math.max(.52,math.min(1.35,(tonumber(fd) or 1.0)*.80))
elseif fainted=="enemy" and not pendingFrustration then
local fd=BattleDirector and type(BattleDirector.faintDuration)=="function"
and BattleDirector:faintDuration(ctx,"enemy") or nil
pendingApproval=math.max(tonumber(pendingApproval) or 0,math.max(.42,math.min(1.05,(tonumber(fd) or 1.0)*.68)))
end
elseif name=="battle.ball_thrown" then



local rawShakes=payload.shakes or payload.shakeCount or payload.shake_count or payload.wobbles or payload.rocks
local rawCaught=payload.caught
local caught=rawCaught==true or rawCaught==1 or (type(rawCaught)=="string" and rawCaught:lower()=="true")





local shakes=caught and 3
or math.max(0,math.min(3,math.floor(tonumber(rawShakes) or 0)))
local ball=tostring(payload.ball or payload.item or "POKE_BALL")
local _,_,_,_,_,_,outcomeAt,duration=captureMilestones(shakes)
capture={age=0,caught=caught,shakes=shakes,ball=ball,duration=duration,done=false,
lastClock=presentationNow(),outcomeAt=outcomeAt,successSfxPlayed=false,successSfxOwned=false,
successSfxAvailable=caught and ensureCaptureSuccessAudio(ctx)==true or false,rawShakes=rawShakes,
sourceBallId=captureBallId(ball)}



trigger("throw",1.0,true)
elseif name=="battle.ended" then
pendingFrustration=nil;pendingApproval=nil
local b=battleOf(ctx);local result=payload.result or payload.outcome or (b and b.result)
if result=="win" or result=="victory" then trigger("victory",1.0)
elseif result=="lose" or result=="loss" or result=="defeat" then trigger("defeat",1.0)
else actionKind=nil;actionAge=0;actionStrength=0 end
end
end

local function idleMotion()
local id=performanceId()
if TrainerPerformance then




if capture and not capture.done then
local t=math.max(0,tonumber(capture.age) or 0)
local a,b,c1=captureMilestones(capture.shakes)
local d=math.max(.001,actionDuration("throw") or 1.48)
local phase
local rel=(scene and scene.nativeTrack and TrainerMorph.releaseFraction and
TrainerMorph.releaseFraction(scene.nativeTrack,"throw",scene.runtimeReleaseJoint or scene.releaseJoint)) or .31
if t<a then
phase=.05+(rel-.05)*clamp(t/math.max(.001,a),0,1)
elseif t<b then
phase=rel+(.79-rel)*clamp((t-a)/math.max(.001,b-a),0,1)
elseif t<c1 then
phase=.79+.21*clamp((t-b)/math.max(.001,c1-b),0,1)
end
if phase then
return TrainerPerformance.idle(id,age,"throw",phase*d,1,"player")
end
end
return currentMotion or TrainerPerformance.idle(id,age,actionKind,actionAge,actionStrength,"player")
end
return {breath=.12,look=0,arm=0,shift=0,settle=0,lean=0,turn=0,bob=0,sway=0,command=0,brace=0,forward=0}
end
local function animatedModel(p,motion)




local sourceRoot=scene and scene.nativeTrack and TrainerMorph.nativeTrackOwnsRoot
and TrainerMorph.nativeTrackOwnsRoot(scene.nativeTrack,motion)
local root=sourceRoot and {pitch=0,roll=0,yaw=0,compression=0}
or (TrainerPerformance and TrainerPerformance.root(performanceId(),motion)
or {pitch=0,roll=0,yaw=(motion.turn or 0)*.8,compression=(motion.brace or 0)*.032})
local pivotY=(currentConfig and (tonumber(currentConfig.playerPivotY) or tonumber(currentConfig.pivotY))) or 7.4
local localAnim=Mat4.mul(Mat4.translate(0,pivotY,0),
Mat4.mul(Mat4.rotateZ(root.roll or 0),
Mat4.mul(Mat4.rotateX(root.pitch or 0),
Mat4.mul(Mat4.rotateY(root.yaw or 0),Mat4.translate(0,-pivotY,0)))))
local compression=root.compression or 0
local sway=sourceRoot and 0 or (motion.sway or 0)
local bob=sourceRoot and 0 or (motion.bob or 0)
local forward=sourceRoot and 0 or (motion.forward or 0)
return Mat4.mul(Mat4.translate(p.x+sway,p.y+bob-compression,p.z+forward),
Mat4.mul(Mat4.rotateY(p.yaw),Mat4.mul(Mat4.scale(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE),localAnim)))
end
local function setShader(vp,model,pose,unlit,tint,opacity,motion)
motion=motion or {}
if not shader then local loaded=loadScene(nil); if not (loaded and shader) then return false end end
love.graphics.setShader(shader);shader:send("vp","row",vp);shader:send("model","row",model);shader:send("cameraEye",pose and pose.eye or {54,24,13});shader:send("unlit",unlit or 0);shader:send("tintColor",tint or {1,1,1,1});shader:send("opacity",opacity or 1)



shader:send("materialColor",{1,1,1,1});shader:send("useTexture",1)
shader:send("sourceVertexColor",0);shader:send("sourceVertexAlpha",0)
shader:send("alphaComp0",7);shader:send("alphaRef0",0);shader:send("alphaOp",0);shader:send("alphaComp1",7);shader:send("alphaRef1",0)
TrainerMorph.sendMixes(shader,motion)
end
function P:drawShadow(ctx,vp,pose)
if not activeNow then return end;local s=loadScene(ctx);if not s then return end;local p=entryPose();if p.progress<.05 then return end
local motion=idleMotion();local sourceRoot=s.nativeTrack and TrainerMorph.nativeTrackOwnsRoot and TrainerMorph.nativeTrackOwnsRoot(s.nativeTrack,motion)
local model=Mat4.translate(p.x+(sourceRoot and 0 or (motion.sway or 0)),0,p.z);love.graphics.setDepthMode("lequal",false);love.graphics.setBlendMode("alpha","alphamultiply");if love.graphics.setMeshCullMode then love.graphics.setMeshCullMode("none") end;love.graphics.setColor(1,1,1,1)
setShader(vp,model,pose,1,{0,0,0,.58},smooth(p.progress/.50));love.graphics.draw(shadowMesh);love.graphics.setShader()
end
function P:draw(ctx,vp,pose)
if not activeNow then return end;drawFrames=drawFrames+1;local s=loadScene(ctx);if not s then return end;local p=entryPose();if p.progress<.03 then return end
local motion=idleMotion();local model=animatedModel(p,motion)
TrainerMorph.bindPair(s.groups,motion)
love.graphics.setDepthMode("lequal",true);love.graphics.setBlendMode("alpha","alphamultiply");if love.graphics.setMeshCullMode then love.graphics.setMeshCullMode("none") end;love.graphics.setColor(1,1,1,1)
setShader(vp,model,pose,0,{1,1,1,1},smooth(p.progress/.38),motion)
for _,grp in ipairs(s.drawGroups or s.groups) do
local animated=TrainerMorph.materialSample and TrainerMorph.materialSample(grp,motion) or nil
local channels=TrainerMorph.materialChannels(grp,animated)
shader:send("materialColor",channels.color)
shader:send("useTexture",grp.textured and 1 or 0)
shader:send("sourceVertexColor",channels.vertexColor)
shader:send("sourceVertexAlpha",channels.vertexAlpha)
shader:send("unlit",grp.useDiffuseLighting==false and 1 or 0)
local pe=TrainerMorph.materialState and TrainerMorph.applyMaterialState(grp,animated) or nil
if pe then
shader:send("alphaComp0",pe.alphaComp0);shader:send("alphaRef0",pe.alphaRef0);shader:send("alphaOp",pe.alphaOp)
shader:send("alphaComp1",pe.alphaComp1);shader:send("alphaRef1",pe.alphaRef1)
elseif love.graphics.setDepthMode then love.graphics.setDepthMode("lequal",not grp.noz) end
love.graphics.draw(grp.mesh)
end
if love.graphics.setDepthMode then love.graphics.setDepthMode("lequal",true) end
love.graphics.setBlendMode("alpha","alphamultiply")
love.graphics.setShader()
end


local function transformPoint(m,p)
local x,y,z=tonumber(p and p[1]) or 0,tonumber(p and p[2]) or 0,tonumber(p and p[3]) or 0
return {m[1]*x+m[2]*y+m[3]*z+m[4],m[5]*x+m[6]*y+m[7]*z+m[8],m[9]*x+m[10]*y+m[11]*z+m[12]}
end
local mixJointPoint=TrainerRig.mixJointPoint
local function runtimeReleaseJoint()
if not (scene and type(scene.jointPositions)=="table" and #scene.jointPositions>0) then return nil end
if scene.runtimeReleaseJoint~=nil then return scene.runtimeReleaseJoint or nil end

local base=scene.jointPositions
local poses=scene.poseJointPositions or {}
local action=poses.gesture3 or poses.gesture4 or poses.gesture2 or poses.arm or poses.command or base
local parents=scene.jointParents or {}
local b=scene.bounds or {};local mn=b.min or {0,0,0};local mx=b.max or {0,16,0};local center=b.center or {0,8,0}
local h=math.max(.001,(tonumber(mx[2]) or 16)-(tonumber(mn[2]) or 0))
local cx=tonumber(center[1]) or 0
local side=tonumber(scene.releaseSide) or -1
local childCount={}
for i,parent in ipairs(parents) do
parent=tonumber(parent) or 0
if parent>0 then childCount[parent]=(childCount[parent] or 0)+1 end
end
local best,bestScore=nil,-1e30

local function scoreCandidate(i)
local rest=base[i];local p=action[i] or rest
if type(rest)~="table" or type(p)~="table" then return nil end
local bx,by=tonumber(rest[1]) or 0,tonumber(rest[2]) or 0
local sideX=side*(bx-cx)/h
local baseY=(by-(tonumber(mn[2]) or 0))/h
local topologyKnown=#parents==#base
local leaf=topologyKnown and ((childCount[i] or 0)==0) or nil
if sideX<=.10 or baseY<=.56 or baseY>=.90 or leaf==false then return nil end
local dx=(tonumber(p[1]) or bx)-bx
local dy=(tonumber(p[2]) or by)-by
local dz=(tonumber(p[3]) or (tonumber(rest[3]) or 0))-(tonumber(rest[3]) or 0)
local move=math.sqrt(dx*dx+dy*dy+dz*dz)/h
local handBand=1-math.min(1,math.abs(baseY-.74)/.18)
return sideX*7.0+move*1.25+handBand*.9+(leaf==true and 2.4 or 0)
end


local hinted=tonumber(scene.releaseJoint)
if hinted and hinted>0 and hinted<=#base then
local score=scoreCandidate(hinted)
if score then best,bestScore=hinted,score+.35 end
end
for i=1,#base do
local score=scoreCandidate(i)
if score and score>bestScore then best,bestScore=i,score end
end

scene.runtimeReleaseJoint=best or false
scene.runtimeReleaseJointScore=bestScore>-1e20 and bestScore or nil
return best
end

local function releaseAnchor(sampleMotion)



if scene and scene.nativeTrack and TrainerMorph.throwHandPoint then
local motion=sampleMotion or idleMotion()
local p=TrainerMorph.throwHandPoint(scene.nativeTrack,motion)
if p then
local out=transformPoint(animatedModel(entryPose(),motion),p)
if out[2]>=1.2 then return out,"source-throw-part" end
end
end




local idx=runtimeReleaseJoint()
if idx and idx>0 and scene.jointPositions and scene.jointPositions[idx] then
local motion=sampleMotion or idleMotion()
local localPoint=scene.nativeTrack and TrainerMorph.trackJoint(scene.nativeTrack,idx,motion)
localPoint=localPoint or mixJointPoint(scene.jointPositions,scene.poseJointPositions,idx,motion)
if localPoint then
local b=scene.bounds or {};local mn=b.min or {0,0,0};local mx=b.max or {0,16,0}
local h=math.max(.001,(tonumber(mx[2]) or 16)-(tonumber(mn[2]) or 0))
local yn=((tonumber(localPoint[2]) or 0)-(tonumber(mn[2]) or 0))/h



if yn>=.30 and yn<=.98 then
local ep=entryPose();local world=animatedModel(ep,motion)
local out=transformPoint(world,localPoint)







if out[2]>=2.20 then return out,"source-hand-end-effector" end
end
end
end


local id=performanceId()
local pf=TrainerPerformance and TrainerPerformance.profile(id) or {lead=1}
local lead=tonumber(pf.lead) or 1
local rigName=(currentConfig and currentConfig.rig) or id
local rp=TrainerRig and scene and TrainerRig.profile(rigName,scene.bounds) or nil
local shoulderLocal=rp and ((rp.minY or 0)+(rp.shoulder or .72)*(rp.height or 1)) or (4.35/MODEL_SCALE)
local lateralLocal=rp and ((rp.halfWidth or 1)*math.max(.52,tonumber(rp.shoulderRadius) or .22)) or (0.70/MODEL_SCALE)
local releaseY=clamp(shoulderLocal*MODEL_SCALE-.08,3.55,5.25)
local releaseX=clamp(lateralLocal*MODEL_SCALE*.92,.48,1.02)
return {FINAL_X-releaseX*lead,releaseY,FINAL_Z-0.46},"heuristic"
end

local function sendoutYaw()
local f=sendoutForward or arenaForward
return throwFacing({0,0,0},{f[1],0,f[2]})
end


local function throwReleaseFraction()
local track=scene and scene.nativeTrack
local f=track and TrainerMorph.releaseFraction and TrainerMorph.releaseFraction(track,"throw",runtimeReleaseJoint())
return f or .31
end
local ballOpened=false
local function normalThrowBallPose()
if actionKind~="throw" or ballOpened then return nil end
local id=performanceId();local d=actionDuration("throw") or 1.48
local releaseT=throwReleaseFraction()*d
if actionAge<releaseT then
local hand=releaseAnchor()
return {hand[1],hand[2],hand[3],0,kind="sendout",handAttached=true,
yaw=sendoutYaw()}
end


if not normalReleasePoint then
local motion=TrainerPerformance and TrainerPerformance.idle(id,age,"throw",releaseT,actionStrength,"player")
normalReleasePoint=releaseAnchor(motion)
end
local target=sendoutTarget or {SENDOUT_TARGET_X,3.85,SENDOUT_TARGET_Z}
local p,q=TrainerMorph.ballFlight(normalReleasePoint,target,actionAge-releaseT)
if q>=1 then return nil end
return {p[1],p[2],p[3],q,kind="sendout",yaw=sendoutYaw(),spin=q*math.pi*5}
end
local function normalThrowLanded()
if actionKind~="throw" or not normalReleasePoint then return false end
local d=actionDuration("throw") or 1.48
local releaseT=throwReleaseFraction()*d
local target=sendoutTarget or {SENDOUT_TARGET_X,3.85,SENDOUT_TARGET_Z}
local T=TrainerMorph.ballFlightTime(normalReleasePoint,target)
return actionAge>=releaseT+T
end

local function capturePhase(c)
if not c then return nil,0 end
local t=math.max(0,tonumber(c.age) or 0)
local a,b,c1,d,e,f,g=captureMilestones(c.shakes)
if t<a then return "charge",t/math.max(.001,CAPTURE_T.charge) end
if t<b then return "throw",(t-a)/CAPTURE_T.throw end
if t<c1 then return "impact",(t-b)/CAPTURE_T.impact end
if t<d then return "absorb",(t-c1)/CAPTURE_T.absorb end
if t<e then return "fall",(t-d)/CAPTURE_T.fall end
if t<f then return "settle",(t-e)/CAPTURE_T.settle end
if t<g then
local elapsed=math.max(0,t-f)
return "shake",(elapsed/CAPTURE_T.shake)%1
end
return c.caught and "caught" or "breakout",math.max(0,(t-g)/CAPTURE_T.outcome)
end

captureTargetY=function()
if capture and capture.targetY then return capture.targetY end
local y=3.75
local actor
local CSM=V.CurrentSpriteModels
local rec=CSM and CSM.stadiumActors and CSM.stadiumActors.enemy
actor=rec and rec.actor
if not actor and V.Gen3Presentation and type(V.Gen3Presentation.records)=="table" then
for id,r in pairs(V.Gen3Presentation.records) do
if type(r)=="table" and r.actor and (tonumber(id) or 0)%2==1 then actor=r.actor;break end
end
end
if actor then
local h=(tonumber(actor.height) or 16)*(tonumber(actor.worldScale) or 1)
y=clamp((tonumber(actor.hoverLift) or 0)+h*.55,1.6,14)
end
if capture then capture.targetY=y end
return y
end
local function captureBallPose()
local c=capture
if not c or c.done then return nil end
local phase,u=capturePhase(c)
local liveStart,anchorKind=releaseAnchor()







local releaseU=math.min(.08,(2/60)/math.max(.001,CAPTURE_T.throw))
local handAttached=(phase=="charge") or (phase=="throw" and (tonumber(u) or 0)<releaseU)
if handAttached then c.releasePoint=nil;c.releaseAnchorKind=anchorKind
elseif not c.releasePoint then c.releasePoint={liveStart[1],liveStart[2],liveStart[3]};c.releaseAnchorKind=anchorKind end
local start=handAttached and liveStart or (c.releasePoint or liveStart)

local target={CAPTURE_TARGET_X,captureTargetY(),CAPTURE_TARGET_Z}
local ground={CAPTURE_TARGET_X,0.31,CAPTURE_TARGET_Z}
if phase=="charge" then

local pulse=.018*math.sin(clamp(u,0,1)*math.pi*4)


return {start[1],start[2]+pulse,start[3],0,kind=phase,phaseU=u,spin=0,opacity=1}
elseif phase=="throw" then
if handAttached then
return {start[1],start[2],start[3],0,kind=phase,phaseU=u,spin=0,trail=0,opacity=1,handAttached=true}
end




local q=clamp((u-releaseU)/math.max(.001,1-releaseU),0,1)
local dx,dz=target[1]-start[1],target[3]-start[3]
local arc=4.0*q*(1-q)*math.max(1.4,math.min(3.6,.9+math.sqrt(dx*dx+dz*dz)*.065))
return {start[1]+(target[1]-start[1])*q,
start[2]+(target[2]-start[2])*q+arc,
start[3]+(target[3]-start[3])*q,0,kind=phase,phaseU=u,
spin=q*math.pi*6.0,trail=math.sin(q*math.pi)*.72,opacity=1}
elseif phase=="impact" then
local q=clamp(u,0,1)



local recoil=math.sin(q*math.pi)*.10*(1-q*.35)
return {target[1],target[2]+recoil,target[3],0,kind=phase,phaseU=u,spin=math.pi*6.0,flare=1-q*.62,opacity=1}
elseif phase=="absorb" then
local q=clamp(u,0,1)
local recoil=math.sin(q*math.pi)*.12*(1-q)
return {target[1],target[2]+recoil,target[3],0,kind=phase,phaseU=u,spin=0,flare=(1-q)*.34+.05,opacity=1}
elseif phase=="fall" then


local q=clamp(u,0,1)
local fall=q*q
return {target[1],target[2]+(ground[2]-target[2])*fall,target[3],0,kind=phase,phaseU=u,
spin=(1-q)*math.pi*.74,trail=(1-q)*.16,opacity=1}
elseif phase=="settle" then
local q=clamp(u,0,1)

local bounce=math.sin(q*math.pi)*math.max(0,1-q)*.13
local rock=math.sin(q*math.pi)*math.max(0,1-q)*.045
return {ground[1],ground[2]+bounce,ground[3],2.58,kind=phase,phaseU=u,rock=rock,flare=math.max(0,1-q*2.5)*.14,opacity=1}
elseif phase=="shake" then
local _,_,_,_,_,f=captureMilestones(c.shakes)
local elapsed=math.max(0,(c.age or 0)-f)
local idx=math.floor(elapsed/CAPTURE_T.shake)
local q=(elapsed/CAPTURE_T.shake)-idx
local dir=(idx%2==0) and -1 or 1
local maxRock=math.rad(27)
local rock=0









if q<.10 then
rock=0
elseif q<.28 then
rock=dir*maxRock*smooth((q-.10)/.18)
elseif q<.48 then
rock=dir*maxRock*(1-smooth((q-.28)/.20))
elseif q<.62 then
rock=-dir*maxRock*.34*smooth((q-.48)/.14)
elseif q<.75 then
rock=-dir*maxRock*.34*(1-smooth((q-.62)/.13))
end
return {ground[1],ground[2],ground[3],0,kind=phase,phaseU=u,shakeQ=q,rock=rock,shakeIndex=idx+1,opacity=1}
elseif phase=="caught" then
return {ground[1],ground[2],ground[3],3.02,kind=phase,phaseU=u,flare=math.max(0,1-clamp(u,0,1))*.12,opacity=1}
elseif phase=="breakout" then
local q=clamp(u,0,1)


local open=smooth(clamp((q-.10)/.68,0,1))
local hop=math.sin(open*math.pi)*.25
return {ground[1],ground[2]+hop,ground[3],3.08+open*.18,kind=phase,phaseU=u,rock=math.sin(open*math.pi)*.08,flare=math.max(0,1-open)*.34,opacity=1}
end
end

local function ballPose()
return captureBallPose() or normalThrowBallPose()
end

function P:captureStatus(ctx)
if not capture then return {active=false} end
local phase,u=capturePhase(capture)
return {active=not capture.done,phase=phase,progress=u,caught=capture.caught,shakes=capture.shakes,ball=capture.ball,age=capture.age,duration=capture.duration,
successSfxPlayed=capture.successSfxPlayed==true,successSfxOwned=capture.successSfxOwned==true,successSfxAvailable=capture.successSfxAvailable==true,
releaseAnchorKind=capture.releaseAnchorKind}
end






function P:suppressesNativeCaughtAudio(ctx)
return capture~=nil and capture.caught==true and (capture.successSfxAvailable==true or capture.successSfxOwned==true)
end
function P:captureBallPosition(ctx)
local bp=captureBallPose();if not bp then return nil end
return {bp[1],bp[2],bp[3],phase=bp.kind,progress=bp.phaseU or 0,shakeIndex=bp.shakeIndex}
end

function P:captureEnemyScale(ctx)
if not capture then return 1 end




if capture.caught and capture.done then return 0 end
if capture.done then return 1 end
local phase,u=capturePhase(capture)
if phase=="charge" or phase=="throw" or phase=="impact" then return 1 end
if phase=="absorb" then return math.max(0,1-smooth(clamp((u-.10)/.72,0,1))) end
if phase=="breakout" then return smooth(clamp((u-.27)/.54,0,1)) end
return 0
end

function P:captureHidesEnemy(ctx)
return self:captureEnemyScale(ctx)<=.015
end

local function drawBallPart(mesh,vp,pose,model,tint)
setShader(vp,model,pose,1,tint,1,{})
love.graphics.draw(mesh)
end
local function captureBallTints()

local id=capture and tostring(capture.ball or "POKE_BALL"):upper() or "POKE_BALL"
if id:find("GREAT",1,true) then return {.96,.96,.94,1},{.08,.22,.68,1},{.78,.08,.06,1} end
if id:find("ULTRA",1,true) then return {.96,.96,.94,1},{.045,.045,.055,1},{.90,.72,.08,1} end
if id:find("MASTER",1,true) then return {.96,.96,.94,1},{.38,.12,.58,1},{.90,.25,.50,1} end
if id:find("SAFARI",1,true) then return {.94,.94,.86,1},{.30,.48,.18,1},{.16,.22,.10,1} end
return {.96,.96,.94,1},{.84,.08,.07,1},{.035,.035,.04,1}
end
function P:sendoutStatus()
if not activeNow or actionKind~="throw" or (capture and not capture.done) then return nil end
local duration=actionDuration("throw") or 1.48
local phase=clamp(actionAge/math.max(.001,duration),0,1)
local ball=normalThrowBallPose()
return {active=phase<1,phase=phase,ball=ball,duration=duration,age=actionAge,
ballLanded=normalThrowLanded(),releasePhase=throwReleaseFraction()}
end

function P:markBallOpened() ballOpened=true end
function P:beginSendout(target,forward)
if not activeNow or (capture and not capture.done) then return nil end
if not trigger("throw",1,true) then return nil end
ballOpened=false
sendoutTarget=target and {target[1],target[2],target[3]} or nil
sendoutForward=forward and {forward[1],forward[2]} or nil
initialOpeningQueued=true;pendingReaction=nil;pendingFrustration=nil;pendingApproval=nil
return actionDuration("throw") or 1.48
end
function P:clearSendoutTarget() sendoutTarget=nil;sendoutForward=nil end



function P:drawSendoutBall(ctx,vp,pose,bp)
local asset=sourceBallAsset("throw","poke")
local handlers=V.WazaHandlers
if not (bp and asset and handlers and type(handlers.drawAsset)=="function") then return false end
local ok,drew=pcall(handlers.drawAsset,ctx,asset,vp,sourceBallModel(asset,bp),0,
{opacity=bp.opacity or 1,depthAlways=false,forceOpaque=true,cullMode="none"})
if ok and drew==true then captureSourceDrawFrames=captureSourceDrawFrames+1;ballDrawFrames=ballDrawFrames+1;return true end
if not ok then captureAssetError=tostring(drew) end
return false
end

function P:drawBall(ctx,vp,pose)
local bp=ballPose()
if not bp then return false end
local captureActive=capture and not capture.done
if not captureActive and bp.kind=="sendout" and self:drawSendoutBall(ctx,vp,pose,bp) then return true end
local sourcePropActive=captureActive





if sourcePropActive then
local asset=sourceBallAsset(bp.kind)
local handlers=V.WazaHandlers
if asset and handlers and type(handlers.drawAsset)=="function" then
local model=sourceBallModel(asset,bp)
local frame=sourceAssetFrame(asset,bp.kind,bp.phaseU,bp)



local ok,drew=pcall(handlers.drawAsset,ctx,asset,vp,model,frame,{
opacity=bp.opacity or 1,depthAlways=false,forceOpaque=true,cullMode="none",hsdFrame=true})
if ok and drew==true then
captureSourceDrawFrames=captureSourceDrawFrames+1;ballDrawFrames=ballDrawFrames+1
return true
end
if not ok then captureAssetError=tostring(drew) end
end
end



if not ensureBall() then
log(ctx,"warn","3D capture ball unavailable: %s",tostring(ballError or "unknown"))
return false
end
local grounded=(bp.kind=="caught" or bp.kind=="shake" or bp.kind=="settle" or bp.kind=="breakout")
local scale=grounded and .180 or .188
local roll=bp.rock or (grounded and 0 or (tonumber(bp.spin) or 0))
local model=Mat4.mul(Mat4.translate(bp[1],bp[2],bp[3]),
Mat4.mul(bp.kind=="sendout" and Mat4.rotateY(bp.yaw or 0) or Mat4.rotateZ(roll),Mat4.scale(scale,scale,scale)))



love.graphics.setDepthMode("lequal",true)
love.graphics.setBlendMode("alpha","alphamultiply")
if love.graphics.setMeshCullMode then love.graphics.setMeshCullMode("none") end
love.graphics.setColor(1,1,1,1)
local white,top,band=captureBallTints()
drawBallPart(ballMeshWhite,vp,pose,model,white)
drawBallPart(ballMeshRed,vp,pose,model,top)
drawBallPart(ballMeshBlack,vp,pose,model,band)




local flare=math.max(0,tonumber(bp.flare) or 0)
if captureActive and flare>.04 and bp.kind~="charge" and bp.kind~="throw" then
love.graphics.setShader();pcall(love.graphics.setBlendMode,"add","alphamultiply")
local tint=(bp.kind=="impact" or bp.kind=="settle") and {1.0,.62,.22,.36*flare}
or (bp.kind=="absorb" and {.98,.20,.56,.30*flare})
or (bp.kind=="breakout" and {.58,.22,1.0,.38*flare}) or {.76,.46,1.0,.24*flare}
local ss=scale*1.42
local shell=Mat4.mul(Mat4.translate(bp[1],bp[2],bp[3]),Mat4.scale(ss,ss,ss))
drawBallPart(ballMeshWhite,vp,pose,shell,tint)
love.graphics.setShader();love.graphics.setBlendMode("alpha","alphamultiply")
end
love.graphics.setShader();love.graphics.setDepthMode("lequal",true)
ballDrawFrames=ballDrawFrames+1
return true
end

function P:setArenaProfile(def)
local t=def and def.trainers and def.trainers.player
local playerMon=def and def.pokemon and def.pokemon.player
local enemyMon=def and def.pokemon and def.pokemon.enemy
if t then FINAL_X=tonumber(t[1]) or FINAL_X;FINAL_Z=tonumber(t[2]) or FINAL_Z end
if playerMon then SENDOUT_TARGET_X=tonumber(playerMon[1]) or SENDOUT_TARGET_X;SENDOUT_TARGET_Z=tonumber(playerMon[2]) or SENDOUT_TARGET_Z end
if enemyMon then CAPTURE_TARGET_X=tonumber(enemyMon[1]) or CAPTURE_TARGET_X;CAPTURE_TARGET_Z=tonumber(enemyMon[2]) or CAPTURE_TARGET_Z end
if playerMon and enemyMon then
local dx,dz=(enemyMon[1] or 0)-(playerMon[1] or 0),(enemyMon[2] or 0)-(playerMon[2] or 0)
if math.abs(dx)+math.abs(dz)>1e-8 then arenaForward={dx,dz} else arenaForward={0,-1} end
end
local sc=def and def.trainerScale and tonumber(def.trainerScale.player)
if sc then arenaModelScale=sc;applyModelScale() end
end

function P:anchor(y) return {FINAL_X,y or 7.0,FINAL_Z} end
function P:resetRuntime()
stopCaptureSuccessAudio()
releaseScene(scene);scene=nil;sceneKey=nil
releaseLoveObject(shader);shader=nil
releaseLoveObject(shadowMesh);releaseLoveObject(shadowImage);shadowImage=nil;shadowMesh=nil;errorText=nil
releaseLoveObject(ballMeshWhite);releaseLoveObject(ballMeshRed);releaseLoveObject(ballMeshBlack);releaseLoveObject(ballTexture)
currentConfig=nil;currentModel="red";currentReason=nil;MODEL_SCALE=arenaModelScale
activeNow=false;age=0;drawFrames=0;actionKind=nil;actionAge=0;actionStrength=0;lastSendingOut=false
ballMeshWhite=nil;ballMeshRed=nil;ballMeshBlack=nil;ballTexture=nil;ballError=nil;ballDrawFrames=0
captureAssetIndex=nil;captureAssetError=nil;captureSourceDrawFrames=0
return true
end
function P:status() return {active=activeNow,ready=scene~=nil,error=errorText,model=(currentConfig and currentConfig.label) or tostring(currentModel):upper(),modelSource=currentConfig and currentConfig.source or nil,modelReason=currentReason,battleHeight=TrainerRoster and TrainerRoster.battleHeight and TrainerRoster.battleHeight(currentConfig) or 6.9,pose="NativeHSD-source-hand-anchored-throw-player",action=actionKind,modelScale=MODEL_SCALE,final={FINAL_X,0,FINAL_Z},ballTarget={SENDOUT_TARGET_X,0,SENDOUT_TARGET_Z},captureTarget={CAPTURE_TARGET_X,0,CAPTURE_TARGET_Z},drawFrames=drawFrames,ballReady=(captureAssetIndex and true) or ballMeshRed~=nil,ballError=ballError,captureAssetError=captureAssetError,captureSourceDrawFrames=captureSourceDrawFrames,ballDrawFrames=ballDrawFrames,releaseJoint=scene and scene.releaseJoint or nil,releaseJointScore=scene and scene.releaseJointScore or nil,capture=P:captureStatus(),runtimeMeshHit=scene and scene.runtimeSidecar==true or false,runtimeMeshHits=playerRuntimeHits,runtimeMeshFallbacks=playerRuntimeFallbacks,morph=TrainerMorph.status(),windowsCompat=WINDOWS_RUNTIME} end
P._test={throwFacing=throwFacing,sourceBallModel=sourceBallModel}
return P
