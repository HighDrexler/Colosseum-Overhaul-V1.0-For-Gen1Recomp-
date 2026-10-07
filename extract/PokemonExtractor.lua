local V=...
local HSD,FSYS,Dex,PKXMetadata=V.HSD,V.FSYS,V.ColosseumDex,V.PKXMetadata
local Persist,GeneratedAssets=V.PayloadPreserver,V.GeneratedAssets
local P={revision=39}
function P.installGeneratedAssets(assets) GeneratedAssets=assets;return true end






















local MORPH_SLOTS=12
local STRIDE=44
local checkpoint
local MAX_CLIP_PROBE=8













local POSE_COHERENCE_MAX=0.16

local function q(s) return string.format("%q",tostring(s)) end
local function num(x)
if type(x)~="number" or x~=x or x==math.huge or x==-math.huge then return "0" end
return ("%.6g"):format(x)
end
local function safe(v) return (tostring(v or ""):gsub("[%c\r\n]","?")) end
local function signature(tex)
if not tex then return "none" end



return table.concat({tex.w,tex.h,tex.format,tex.rgba},":")
end






local function measure(model,targetHeight)
local mn,mx=model.bounds.min,model.bounds.max
local h=math.max(1e-6,mx[2]-mn[2])
return {s=targetHeight/h,cx=(mn[1]+mx[1])/2,cy=mn[2],cz=(mn[3]+mx[3])/2}
end
local function applyTransform(model,t)
local nmin={1e30,1e30,1e30};local nmax={-1e30,-1e30,-1e30}
for _,g in ipairs(model.groups or {}) do
for vi,v in ipairs(g.vertices or {}) do
if vi%128==0 then checkpoint() end
v[1]=(v[1]-t.cx)*t.s;v[2]=(v[2]-t.cy)*t.s;v[3]=(v[3]-t.cz)*t.s
for k=1,3 do
if v[k]<nmin[k] then nmin[k]=v[k] end
if v[k]>nmax[k] then nmax[k]=v[k] end
end
end
end



for _,j in ipairs(model.jointPositions or {}) do
j[1]=((tonumber(j[1]) or 0)-t.cx)*t.s
j[2]=((tonumber(j[2]) or 0)-t.cy)*t.s
j[3]=((tonumber(j[3]) or 0)-t.cz)*t.s
end
model.bounds={min=nmin,max=nmax,center={(nmin[1]+nmax[1])/2,(nmin[2]+nmax[2])/2,(nmin[3]+nmax[3])/2}}
return model
end






local function retailWazaOwnerBound(base,metadata,transform)
if not (HSD and type(HSD.extractRetailModelBoundFromModel)=="function") then
return nil,"retail-bound extractor unavailable"
end
if type(base)~="table" or base.semanticRootsOnly~=true then
return nil,"retail-bound body lacks semantic-root provenance"
end



if tonumber(base.semanticRootCount)~=1 then
return nil,"retail-bound Pokemon resource root is ambiguous"
end
local idle=metadata and metadata.slots and metadata.slots.idle
local animationIndex=idle and idle.active==true and tonumber(idle.animationIndex) or nil
if animationIndex==nil or animationIndex<0 or animationIndex~=math.floor(animationIndex) then
return nil,"retail-bound base-row zero-motion animation unavailable"
end
local bound,why=HSD.extractRetailModelBoundFromModel(base,animationIndex)
if not (bound and bound.exact==true and bound.frame==0) then return nil,why or "retail-bound frame-0 bake unavailable" end
local t=transform
if not (type(t)=="table" and tonumber(t.s) and tonumber(t.cx) and tonumber(t.cy) and tonumber(t.cz) and t.s>0) then
return nil,"retail-bound source normalization unavailable"
end
local function map(v)
return {(v[1]-t.cx)*t.s,(v[2]-t.cy)*t.s,(v[3]-t.cz)*t.s}
end
local nmin,nmax=map(bound.min),map(bound.max)
local ncenter={(nmin[1]+nmax[1])*.5,(nmin[2]+nmax[2])*.5,(nmin[3]+nmax[3])*.5}
return {
exact=true,format="gc6e01-waza-owner-bound-v1",frame=0,animationIndex=animationIndex,
selector="base-row0-first-zero-motion",selectorExact=true,
source={min={bound.min[1],bound.min[2],bound.min[3]},max={bound.max[1],bound.max[2],bound.max[3]},
center={bound.center[1],bound.center[2],bound.center[3]},extent={bound.extent[1],bound.extent[2],bound.extent[3]}},
normalized={min=nmin,max=nmax,center=ncenter,
extent={nmax[1]-nmin[1],nmax[2]-nmin[2],nmax[3]-nmin[3]}},
sourceToCache={s=t.s,cx=t.cx,cy=t.cy,cz=t.cz,exact=true},
}
end





local function topologyMatches(base,sample)
if not (base and sample) then return false end
local bg,sg=base.groups or {},sample.groups or {}
if #bg~=#sg then return false end
for i=1,#bg do
if #(bg[i].vertices or {})~=#(sg[i].vertices or {}) then return false end
end
return true
end




local function motionRatio(base,sample,height)
if not topologyMatches(base,sample) then return nil end
local H=math.max(.001,height or 1)
local sum,n=0,0
for gi,g in ipairs(base.groups) do
local sgv=sample.groups[gi].vertices
for vi,v in ipairs(g.vertices) do
local o=sgv[vi]
local dx=(o[1] or 0)-(v[1] or 0)
local dy=(o[2] or 0)-(v[2] or 0)
local dz=(o[3] or 0)-(v[3] or 0)
sum=sum+dx*dx+dy*dy+dz*dz;n=n+1
end
end
if n<12 then return nil end
return math.sqrt(sum/n)/H
end

local function finite(v)
return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end

local function modelHeight(model)
local b=model and model.bounds
return b and b.min and b.max and math.max(.001,(tonumber(b.max[2]) or 0)-(tonumber(b.min[2]) or 0)) or 1
end

local function boundsCenterAndSpan(model)
local b=model and model.bounds
if not (b and b.min and b.max) then return nil end
local min,max=b.min,b.max
for i=1,3 do if not (finite(min[i]) and finite(max[i])) then return nil end end
local dx,dy,dz=max[1]-min[1],max[2]-min[2],max[3]-min[3]
if dx<0 or dy<0 or dz<0 then return nil end
return {(min[1]+max[1])*.5,(min[2]+max[2])*.5,(min[3]+max[3])*.5},math.sqrt(dx*dx+dy*dy+dz*dz)
end









local REACTION_SLOT={damage=true,damageHeavy=true,faint=true}
local ACTION_DRIFT_MAX={idle=1.25,extra1=3.5,extra2=3.5,extra3=3.5,extra4=3.5,
specialA=2.25,specialB=2.25,specialC=2.25,
physicalA=3.5,physicalB=3.5,physicalC=3.5,physicalD=3.5,physicalE=3.5,takeFlight=5.0}
local function actionPoseUsable(template,sample,label)
if not topologyMatches(template,sample) then return false,"topology mismatch" end
local tc,ts=boundsCenterAndSpan(template)
local sc,ss=boundsCenterAndSpan(sample)
if not (tc and sc and ts and ss) then return false,"non-finite bounds" end
local H=modelHeight(template)
if ss<math.max(.01,ts*.08) then return false,("collapsed span %.4f vs %.4f"):format(ss,ts) end
if ss>ts*7.0 then return false,("exploded span %.4f vs %.4f"):format(ss,ts) end
local dx,dy,dz=sc[1]-tc[1],sc[2]-tc[2],sc[3]-tc[3]
local centerDistance=math.sqrt(dx*dx+dy*dy+dz*dz)/H
if REACTION_SLOT[label] then




if centerDistance>6.0 then
return false,("reaction center displaced %.3f model heights"):format(centerDistance)
end
return true,nil,centerDistance
end
if centerDistance>3.5 then
return false,("center displaced %.3f model heights"):format(centerDistance)
end
local drift=motionRatio(template,sample,H)
local limit=ACTION_DRIFT_MAX[label] or 2.25
if not drift then return false,"pose displacement unavailable" end
if drift>limit then return false,("pose drift %.3f exceeds %.2f"):format(drift,limit) end
return true,nil,drift
end

local function materialSignature(g)
local function c(v)
if type(v)~="table" then return "-" end
return ("%.5f,%.5f,%.5f"):format(tonumber(v[1]) or 0,tonumber(v[2]) or 0,tonumber(v[3]) or 0)
end
return table.concat({
signature(g.texture),
tostring(g.renderFlags or 0),
("a=%.5f"):format(tonumber(g.alpha) or 1),
"d="..c(g.diffuse),"a2="..c(g.ambient),"s="..c(g.specular),
"x="..tostring(g.xlu==true),"z="..tostring(g.noz==true),
"sh="..tostring(g.shadow==true),"ef="..tostring(g.effect==true),
"ts="..tostring(g.textureSlot or -1),
"sampler="..tostring(g.texture and g.texture.wrapS)..","..tostring(g.texture and g.texture.wrapT),
"texflags="..tostring(g.texture and g.texture.flags),
"blend="..tostring(g.texture and g.texture.blending),
"texgen="..tostring(g.texture and g.texture.texgen),
"srt="..c(g.texture and g.texture.scale).."/"..c(g.texture and g.texture.rotation).."/"..c(g.texture and g.texture.translation),
"repeat="..tostring(g.texture and g.texture.repeatS)..","..tostring(g.texture and g.texture.repeatT),
"motion="..tostring(g.sourceTextureAnimation and g.sourceDobj),
},"|")
end







local function mergeGroups(model)
local map,out={},{}
for _,g in ipairs(model.groups) do
local key=materialSignature(g)
local dst=map[key]
if not dst then
dst={
vertices={},texture=g.texture,
alpha=g.alpha,xlu=g.xlu,noz=g.noz,
diffuse=g.diffuse,ambient=g.ambient,specular=g.specular,shininess=g.shininess,
renderFlags=g.renderFlags,shadow=g.shadow,effect=g.effect,
useConstant=g.useConstant,useVertexColor=g.useVertexColor,
useDiffuseLighting=g.useDiffuseLighting,textureSlot=g.textureSlot,
sourceTextureAnimation=g.sourceTextureAnimation,sourceDobj=g.sourceDobj,
}
map[key]=dst;out[#out+1]=dst
end
for _,v in ipairs(g.vertices) do dst.vertices[#dst.vertices+1]=v end
end
model.groups=out
return model
end









local DECODE={
textures=true,sourceTextureState=true,sourceTextureAnimation=true,maxRoots=64,maxVertices=200000,
maxDisplayOps=600000,maxJobjs=8192,maxDobjs=24576,maxPobjs=49152,
maxSceneRoots=64,




semanticRootsOnly=true,



skipShadowMaterials=true,
}


local MAIN={}
local extractionContexts=setmetatable({}, {__mode="k"})
local function contextKey() return coroutine.running() or MAIN end
local function extractionContext()
return extractionContexts[contextKey()] or {skinFix=true,renderPassFilter=true}
end
checkpoint=function(label)
local c=extractionContext()
if c.checkpoint then c.checkpoint(label) end
end
local function decodeOpts(clip,frame,withTextures)
local o={}
for k,v in pairs(DECODE) do o[k]=v end
o.textures=withTextures and true or false
o.skinFix=extractionContext().skinFix
o.nativeScaleCompensation=true
o.honorRenderPass=extractionContext().renderPassFilter
o.checkpoint=extractionContext().checkpoint
o.decodeSession=extractionContext().decodeSession
o.filterPlaceholders=false
if clip~=nil then o.nativePose={clip=clip,frame=frame or 0} end
return o
end












local function decodeBest(blob,clip,frame,withTextures,trail,label,mode)
mode=mode or "auto"
local opts=decodeOpts(clip,frame,withTextures)

checkpoint("Decoding source pose")



local scene,single,singleErr
local function readScene()
if type(HSD.extractSceneModel)=="function" then
local ok,value=pcall(HSD.extractSceneModel,blob,opts)
if ok then scene=value end
end
end
if mode=="scene" then
readScene()
if not scene then single,singleErr=HSD.extractModel(blob,opts) end
else
single,singleErr=HSD.extractModel(blob,opts)
if not single or (mode~="single" and (tonumber(single.vertexCount) or 0)<=0) then readScene() end
end
checkpoint()
local sv=scene and tonumber(scene.vertexCount) or 0
local nv=single and tonumber(single.vertexCount) or 0




























local DUPLICATION_FACTOR=1.9
local chosen,path
if mode=="scene" and scene then
chosen,path=scene,"scene(forced)"
elseif mode=="single" and single then
chosen,path=single,"single(forced)"
elseif single and nv>0 then
chosen,path=single,"single"
elseif scene and sv>0 then
chosen,path=scene,"scene(single unavailable)"
end

if trail and label then
trail[#trail+1]=("%s scene=%d verts/%s roots  single=%d verts  ratio=%.2f  -> %s")
:format(label,sv,tostring(scene and scene.sceneRoots or "-"),nv,
(nv>0) and (sv/nv) or 0,tostring(path))
if scene and single and nv>0 and sv>=nv*DUPLICATION_FACTOR then
trail[#trail+1]=("  note: scene path would have returned %.2fx the single-root geometry -- "
.."single was used regardless, since scene is no longer preferred by default."):format(sv/nv)
elseif scene and single then
trail[#trail+1]=("  note: scene found %s root(s) totalling %d verts vs single's %d -- "
.."single was used; force scene mode (F10) on this species to compare directly."):format(tostring(scene.sceneRoots or "?"),sv,nv)
end
if not chosen then
trail[#trail+1]=("%s both paths failed: %s"):format(label,safe(singleErr))
end
end
if chosen then return chosen,path,tonumber(chosen.vertexCount) or 0 end
return nil,nil,0,singleErr
end






local function boundsReport(model)
local xs,ys,zs={},{},{}
for _,g in ipairs(model.groups or {}) do
for _,v in ipairs(g.vertices or {}) do
xs[#xs+1]=v[1];ys[#ys+1]=v[2];zs[#zs+1]=v[3]
end
end
if #ys<8 then return nil end
table.sort(xs);table.sort(ys);table.sort(zs)



local function trimmed(t)
local n=#t
local cut=math.max(1,math.floor(n*0.01))
if n-2*cut<4 then return t[n]-t[1] end
return t[n-cut]-t[1+cut]
end
local rawH=ys[#ys]-ys[1]
local trimH=trimmed(ys)
local rawW=xs[#xs]-xs[1]
local trimW=trimmed(xs)
return {
rawH=rawH,trimH=trimH,rawW=rawW,trimW=trimW,
heightRatio=(trimH>1e-9) and (rawH/trimH) or 0,
widthRatio=(trimW>1e-9) and (rawW/trimW) or 0,
count=#ys,
}
end




local function chooseIdleClip(blob,targetHeight,trail,mode)
local base=decodeBest(blob,0,0,false,trail,"bind",mode)
if not base then return nil,nil,"clip probe: bind frame did not decode" end


local probe=HSD.extractModel(blob,decodeOpts(0,0,false))
local clipCount=(probe and probe.stats and tonumber(probe.stats.nativeClipCount)) or 0
trail[#trail+1]=("clips=%d"):format(clipCount)
if clipCount<2 then

return 0,clipCount,"only a bind clip is present"
end







local referenceVerts=tonumber(base.vertexCount) or 0
trail[#trail+1]=("bind-pose reference vertices=%d"):format(referenceVerts)

local bestClip,bestScore,bestRatio=nil,1e30,nil
local limit=math.min(clipCount-1,MAX_CLIP_PROBE)
for clip=1,limit do
local a=decodeBest(blob,clip,0,false,nil,nil,mode)
local b=decodeBest(blob,clip,12,false,nil,nil,mode)
local av=a and tonumber(a.vertexCount) or 0
if referenceVerts>0 and av<referenceVerts*0.995 then
trail[#trail+1]=("clip %d REJECTED: %d verts vs %d at bind (%.1f%% lost)")
:format(clip,av,referenceVerts,(1-av/referenceVerts)*100)
a=nil
end
if a and b then
local t=measure(a,targetHeight)
applyTransform(a,t);applyTransform(b,t)
local r=motionRatio(a,b,targetHeight)



local bindCopy=decodeBest(blob,0,0,false,nil,nil,mode)
local drift=nil
if bindCopy then
applyTransform(bindCopy,t)
drift=motionRatio(bindCopy,a,targetHeight)
end
if drift and drift>POSE_COHERENCE_MAX then
trail[#trail+1]=("clip %d REJECTED: drifts %.3f from bind (max %.2f). "
.."Joint sampling is displacing geometry, not animating it.")
:format(clip,drift,POSE_COHERENCE_MAX)
elseif r then
trail[#trail+1]=("clip %d motion=%.5f drift=%s")
:format(clip,r,drift and ("%.4f"):format(drift) or "?")


if r>=.0015 then
local score=math.abs(r-.030)
if score<bestScore then bestClip,bestScore,bestRatio=clip,score,r end
end
else
trail[#trail+1]=("clip %d topology mismatch"):format(clip)
end
else
trail[#trail+1]=("clip %d did not decode"):format(clip)
end
end
if not bestClip then
return 0,clipCount,"no clip carried usable authored motion"
end
trail[#trail+1]=("selected clip %d motion=%.5f"):format(bestClip,bestRatio or 0)
return bestClip,clipCount,nil
end





local function attachFrames(blob,base,clip,transform,targetHeight,spacing,trail,decodeMode,actionLabel)
local attached=0
local validSlots={}
base.jointFrames=base.jointFrames or {}
for slot=1,MORPH_SLOTS do
local frame=slot*spacing
local sample=decodeBest(blob,clip,frame,false,nil,nil,decodeMode)
if sample then applyTransform(sample,transform) end
local usable,reason
if sample then
if actionLabel then usable,reason=actionPoseUsable(base,sample,actionLabel)
else usable=topologyMatches(base,sample);reason=usable and nil or "topology mismatch" end
else reason="frame did not decode" end
for gi,g in ipairs(base.groups) do
local sv=usable and sample.groups[gi].vertices or nil
for vi,v in ipairs(g.vertices) do
local o=sv and sv[vi] or v



local at=5+slot*3
v[at+1]=o[1];v[at+2]=o[2];v[at+3]=o[3]
end
end



local joints=(usable and sample and sample.jointPositions) or base.jointPositions or {}
local jf={}
for ji,j in ipairs(joints) do jf[ji]={j[1] or 0,j[2] or 0,j[3] or 0} end
base.jointFrames[slot]=jf
validSlots[slot]=usable and true or false
if usable then
attached=attached+1
else
trail[#trail+1]=("%sframe %.3f unusable (%s); slot %d holds base")
:format(actionLabel and ("native "..actionLabel.." ") or "",frame,tostring(reason or "invalid pose"),slot)
end
end
return attached,validSlots
end








local function copyGroupShell(g)
return {
vertices={},texture=g.texture,alpha=g.alpha,xlu=g.xlu,noz=g.noz,
diffuse=g.diffuse,ambient=g.ambient,specular=g.specular,shininess=g.shininess,
renderFlags=g.renderFlags,shadow=g.shadow,effect=g.effect,
useConstant=g.useConstant,useVertexColor=g.useVertexColor,
useDiffuseLighting=g.useDiffuseLighting,textureSlot=g.textureSlot,
sourceTextureAnimation=g.sourceTextureAnimation,sourceDobj=g.sourceDobj,
}
end

local function actionSpacing(duration,endFrame)
duration=tonumber(duration) or 0
endFrame=tonumber(endFrame)






if endFrame and endFrame>0.5 then
return math.max(.25,endFrame/MORPH_SLOTS)
end
if duration>0.02 then
local frameCount=duration*30
return math.max(.25,math.max(1,frameCount-1)/MORPH_SLOTS)
end
return 4
end

local function buildActionModel(blob,template,clip,transform,duration,endFrame,trail,decodeMode,label)
clip=tonumber(clip)
if clip==nil or clip<0 then return nil,"no animation index" end
local first=decodeBest(blob,clip,0,false,nil,nil,decodeMode)
if not first then return nil,"frame 0 did not decode" end
applyTransform(first,transform)
local usable,poseErr=actionPoseUsable(template,first,label)
if not usable then return nil,"frame 0 "..tostring(poseErr or "pose invalid") end

local model={groups={},bounds=first.bounds,vertexCount=template.vertexCount,jointPositions=first.jointPositions}
for gi,tg in ipairs(template.groups or {}) do
local fg=first.groups[gi]
local outg=copyGroupShell(tg)
for vi,tv in ipairs(tg.vertices or {}) do
local fv=fg.vertices[vi]


local v={fv[1],fv[2],fv[3],tv[4] or 0,tv[5] or 0,tv[6] or 0,tv[7] or 1,tv[8] or 0}
outg.vertices[vi]=v
end
model.groups[gi]=outg
end
local spacing=actionSpacing(duration,endFrame)
local attached,validSlots=attachFrames(blob,model,clip,transform,nil,spacing,trail,decodeMode,label)
if attached<1 then return nil,"no authored target frames decoded" end
return model,nil,spacing,attached,validSlots
end









local function denseReactionIntervals(label,duration,endFrame)
if label=="idle" then return MORPH_SLOTS end
local sourceIntervals=math.max(1,math.floor((tonumber(endFrame) or 0)+.5))
if sourceIntervals<=1 then
local seconds=math.max(.05,tonumber(duration) or 0)
sourceIntervals=math.max(1,math.floor(seconds*30+.5)-1)
end




return math.max(MORPH_SLOTS,math.min(144,sourceIntervals))
end

local function buildActionPage(blob,template,clip,transform,spacing,startInterval,slotCount,trail,decodeMode,label)
local baseFrame=startInterval*spacing
local first=decodeBest(blob,clip,baseFrame,false,nil,nil,decodeMode)
if not first then return nil,"page base frame did not decode" end
applyTransform(first,transform)
local usable,poseErr=actionPoseUsable(template,first,label)
if not usable then return nil,"page base "..tostring(poseErr or "pose invalid") end

local model={groups={},bounds=first.bounds,vertexCount=template.vertexCount,
jointPositions=first.jointPositions,jointFrames={}}
for gi,tg in ipairs(template.groups or {}) do
local fg=first.groups[gi]
local outg=copyGroupShell(tg)
for vi,tv in ipairs(tg.vertices or {}) do
local fv=fg.vertices[vi]
outg.vertices[vi]={fv[1],fv[2],fv[3],tv[4] or 0,tv[5] or 0,tv[6] or 0,tv[7] or 1,tv[8] or 0}
end
model.groups[gi]=outg
end

local validSlots={}
local attached=0
for slot=1,MORPH_SLOTS do
local usableSlot=slot<=slotCount
local frame=(startInterval+math.min(slot,slotCount))*spacing
local sample=usableSlot and decodeBest(blob,clip,frame,false,nil,nil,decodeMode) or nil
if sample then applyTransform(sample,transform) end
local ok,reason=false,nil
if sample then ok,reason=actionPoseUsable(template,sample,label)
elseif usableSlot then reason="frame did not decode" end
for gi,g in ipairs(model.groups or {}) do
local sv=ok and sample.groups[gi].vertices or nil
for vi,v in ipairs(g.vertices or {}) do
local o=sv and sv[vi] or v
local at=5+slot*3
v[at+1]=o[1];v[at+2]=o[2];v[at+3]=o[3]
end
end
local joints=(ok and sample and sample.jointPositions) or model.jointPositions or {}
local jf={}
for ji,j in ipairs(joints) do jf[ji]={j[1] or 0,j[2] or 0,j[3] or 0} end
model.jointFrames[slot]=jf
validSlots[slot]=ok and true or false
if ok then attached=attached+1
elseif usableSlot then
trail[#trail+1]=("native %s dense frame %.3f unusable (%s); page slot %d bridges")
:format(label,frame,tostring(reason or "invalid pose"),slot)
end
end
if attached<1 then return nil,"dense page has no authored target frames" end
return {
model=model,morphFrames=slotCount,validSlots=validSlots,
startInterval=startInterval,endInterval=startInterval+slotCount,
attached=attached,
}
end

local function buildActionPages(blob,template,clip,transform,duration,endFrame,trail,decodeMode,label)
local intervals=denseReactionIntervals(label,duration,endFrame)
if intervals<=MORPH_SLOTS then return nil end
local finalFrame=tonumber(endFrame)
if not finalFrame or finalFrame<=0.5 then finalFrame=math.max(1,(tonumber(duration) or .25)*30-1) end
local spacing=math.max(.25,finalFrame/intervals)
local pages={}
local start=0
local validTotal=0
while start<intervals do
local count=math.min(MORPH_SLOTS,intervals-start)
local page,err=buildActionPage(blob,template,clip,transform,spacing,start,count,trail,decodeMode,label)
if not page then return nil,err end
page.startPhase=start/intervals
page.endPhase=(start+count)/intervals
pages[#pages+1]=page
validTotal=validTotal+(page.attached or 0)
start=start+count
end
return pages,nil,spacing,intervals,validTotal
end

local function extractActionBanks(blob,template,transform,metadata,clipCount,trail,decodeMode,wantedActions)
local actions={}
if not (metadata and type(metadata.slots)=="table") then
trail[#trail+1]="PKX action banks: metadata unavailable; retaining legacy single-clip fallback"
return actions
end








local semanticOrder={
{"idle",{"idle"}},
{"specialA",{"specialA"}},
{"physicalA",{"physicalA"}},
{"physicalB",{"physicalB"}},
{"physicalC",{"physicalC"}},
{"physicalD",{"physicalD"}},
{"specialB",{"specialB"}},
{"physicalE",{"physicalE"}},
{"damage",{"damage"}},
{"damageHeavy",{"damageHeavy"}},
{"faint",{"faint"}},
{"extra1",{"extra1"}},
{"specialC",{"specialC"}},
{"extra2",{"extra2"}},
{"extra3",{"extra3"}},
{"extra4",{"extra4"}},
{"takeFlight",{"takeFlight"}},
}

local ownerByClip={}
local failedClip={}

local function slotInfo(key)
local slot=metadata.slots[key]
if slot and slot.active==false then return nil end
local clip=slot and tonumber(slot.animationIndex) or nil
local duration=slot and tonumber(slot.duration) or 0
if not clip or clip<0 or (clipCount and clipCount>0 and clip>=clipCount) then return nil end
return slot,clip,duration
end

local function buildSemantic(requestKey,candidates)
for _,sourceKey in ipairs(candidates) do
local slot,clip,duration=slotInfo(sourceKey)
if slot then
local clipInfo=nil
if HSD and type(HSD.nativeAnimationInfo)=="function" then
local okInfo,value=pcall(HSD.nativeAnimationInfo,template,clip)
if okInfo and type(value)=="table" then clipInfo=value end
end
local endFrame=clipInfo and tonumber(clipInfo.endFrame) or nil
local owner=ownerByClip[clip]
if owner then
actions[requestKey]={alias=owner,clip=clip,duration=duration}
trail[#trail+1]=("native %-11s -> clip %d (source %s, alias %s) duration %.3fs")
:format(requestKey,clip,sourceKey,owner,duration)
return true
end

if not failedClip[clip] then
local pages,pageErr,pageSpacing,pageIntervals,pageValid=
buildActionPages(blob,template,clip,transform,duration,endFrame,trail,decodeMode,requestKey)
if pages then
ownerByClip[clip]=requestKey
actions[requestKey]={pages=pages,clip=clip,duration=duration,frameSpacing=pageSpacing,sourceEndFrame=endFrame,
totalIntervals=pageIntervals,validMorphFrames=pageValid,dense=true}
trail[#trail+1]=("native %-11s -> clip %d (source %s) dense=%d intervals / %d pages valid=%d spacing=%.3f duration=%.3fs")
:format(requestKey,clip,sourceKey,pageIntervals,#pages,pageValid or 0,pageSpacing,duration)
return true
end

local model,err,spacing,attached,validSlots=
buildActionModel(blob,template,clip,transform,duration,endFrame,trail,decodeMode,requestKey)
if model then
ownerByClip[clip]=requestKey
actions[requestKey]={model=model,clip=clip,duration=duration,frameSpacing=spacing,sourceEndFrame=endFrame,
morphFrames=MORPH_SLOTS,validMorphFrames=attached,validSlots=validSlots}
trail[#trail+1]=("native %-11s -> clip %d (source %s) %d/%d valid targets playback=%d spacing=%.3f duration=%.3fs")
:format(requestKey,clip,sourceKey,attached,MORPH_SLOTS,MORPH_SLOTS,spacing,duration)
return true
end
failedClip[clip]=tostring(pageErr or err or "source bank rejected")
end

trail[#trail+1]=("native %-11s source %-11s clip %d rejected: %s; trying fallback")
:format(requestKey,sourceKey,clip,tostring(failedClip[clip]))
end
end
trail[#trail+1]=("native %-11s unavailable after source fallback sweep"):format(requestKey)
return false
end

for _,spec in ipairs(semanticOrder) do
local wanted=wantedActions and wantedActions[spec[1]] or nil
if wantedActions==nil then buildSemantic(spec[1],spec[2])
elseif wanted==true then buildSemantic(spec[1],spec[2])
elseif type(wanted)=="table" then buildSemantic(spec[1],wanted) end
end
return actions
end

local function jointLua(joints)
local out={"{"}
for _,j in ipairs(joints or {}) do
out[#out+1]="{"..num(j[1] or 0)..","..num(j[2] or 0)..","..num(j[3] or 0).."},"
end
out[#out+1]="}"
return table.concat(out)
end
local function jointFramesLua(frames)
local out={"{"}
for slot=1,MORPH_SLOTS do out[#out+1]=jointLua(frames and frames[slot] or {}).."," end
out[#out+1]="}"
return table.concat(out)
end
local function validSlotsLua(slots)
local out={"{"}
for slot=1,MORPH_SLOTS do out[#out+1]=(slots and slots[slot] and "true" or "false").."," end
out[#out+1]="}"
return table.concat(out)
end








local function normalizedVertexRow(v)
local row={v[1],v[2],v[3],v[4] or 0,v[5] or 0,v[6] or 0,v[7] or 1,v[8] or 0}
for slot=1,MORPH_SLOTS do
local at=5+slot*3
row[#row+1]=v[at+1] or v[1]
row[#row+1]=v[at+2] or v[2]
row[#row+1]=v[at+3] or v[3]
end
return row
end




local function packedVerticesLua(vertices)



local chunks,parts={},{}
local n,rows=0,0
for vi,v in ipairs(vertices or {}) do
local row=normalizedVertexRow(v)
if vi>1 then n=n+1;parts[n]="\n" end
for i=1,STRIDE do
if i>1 then n=n+1;parts[n]="," end
n=n+1;parts[n]=num(row[i])
end
rows=rows+1
if rows==64 then
chunks[#chunks+1]=table.concat(parts,"",1,n);n=0;rows=0
if checkpoint then checkpoint("Writing source vertex cache") end
end
end
if n>0 then chunks[#chunks+1]=table.concat(parts,"",1,n) end
if checkpoint then checkpoint() end
return q(table.concat(chunks))
end

local unpackArgs=table.unpack or unpack



local RUNTIME_PACK_BATCH=64
local RUNTIME_PACK_SCALAR_LIMIT=192
local runtimePackFFI
do
local ok,ffi=pcall(require,"ffi")
if ok and ffi.sizeof("float")==4 then runtimePackFFI=ffi end
end
local function runtimeVerticesBytes(vertices)
local lovePack=love and love.data and type(love.data.pack)=="function" and love.data.pack or nil
local luaPack=type(string.pack)=="function" and string.pack or nil
if not lovePack and not luaPack and not runtimePackFFI then return nil end
vertices=vertices or {}
local count=#vertices
if count==0 then return nil end
if runtimePackFFI then



local buffer=runtimePackFFI.new("float[?]",count*STRIDE)
local offset=0
for vi,v in ipairs(vertices) do
for j=1,STRIDE do
local value=v[j]
if j<=8 then
if j>=4 and value==nil then value=j==7 and 1 or 0 end
elseif value==nil then value=v[(j-9)%3+1] end
buffer[offset]=value;offset=offset+1
end
if checkpoint and vi%128==0 then checkpoint("Packing model cache") end
end
return runtimePackFFI.string(buffer,count*STRIDE*4)
end
local rowFmt=string.rep("f",STRIDE)
local rowsPerBatch=math.max(1,math.min(RUNTIME_PACK_BATCH,math.floor(RUNTIME_PACK_SCALAR_LIMIT/STRIDE)))
local batchFmt=string.rep(rowFmt,rowsPerBatch)
local buf={}
local chunks,chunkCount={},0
local i=1
while i<=count do
local take=count-i+1;if take>rowsPerBatch then take=rowsPerBatch end
local k=0
for r=i,i+take-1 do
local row=normalizedVertexRow(vertices[r])
for j=1,STRIDE do k=k+1;buf[k]=row[j] end
end
local fmt=take==rowsPerBatch and batchFmt or string.rep(rowFmt,take)
local ok,bytes
if lovePack then ok,bytes=pcall(lovePack,"string",fmt,unpackArgs(buf,1,k)) end
if (not ok or type(bytes)~="string") and luaPack then ok,bytes=pcall(luaPack,"<"..fmt,unpackArgs(buf,1,k)) end
if not ok or type(bytes)~="string" then return nil end
chunkCount=chunkCount+1;chunks[chunkCount]=bytes
i=i+take
if checkpoint then checkpoint("Packing model cache") end
end
return table.concat(chunks,"",1,chunkCount)
end



local ACTION_ORDER={
"idle","specialA","physicalA","physicalB","physicalC","physicalD","specialB","physicalE",
"damage","damageHeavy","faint","extra1","specialC","extra2","extra3","extra4","takeFlight",
}
local SELECTIVE_ACTION_REF_VERSION=1
local function selectiveActionRefPathFromRoot(cacheRoot,key)
return cacheRoot.."/actions/selective_"..tostring(key or "action"):gsub("[^%w_%-]","_").."_v1.lua"
end
local function mat4Lua(m)
if type(m)~="table" or #m<16 then return "nil" end
local out={"{"};for i=1,16 do out[#out+1]=num(m[i]);out[#out+1]="," end;out[#out+1]="}"
return table.concat(out)
end
local function selectiveActionRefLua(ref,stamp)
local out={"-- Generated additive source-action reference; base cache remains unchanged.\nreturn {version=",
tostring(SELECTIVE_ACTION_REF_VERSION),",stamp=",q(stamp or ""),",clip=",tostring(tonumber(ref and ref.clip) or -1),
",duration=",num(ref and ref.duration or 0)}
if ref and ref.alias then out[#out+1]=",alias="..q(ref.alias)
elseif ref and ref.path then out[#out+1]=",path="..q(ref.path) end
out[#out+1]="}\n"
return table.concat(out)
end



local function metadataCacheLua(metadata)
if type(metadata)~="table" then return nil end
local keys={"origin","mouth","chest","tail","eye_left","eye_right","hand_left","hand_right","additional_1","additional_2","additional_3","additional_4","foot_left","foot_right","center","additional_5"}
local function appendBodyMap(out,map)
out[#out+1]="bodyMap={"
for _,key in ipairs(keys) do out[#out+1]="["..q(key).."]="..tostring(tonumber(map and map[key]) or -1).."," end
out[#out+1]="},"
end
local out={"-- Compact PKX runtime metadata generated from the user's GC6E01 disc.\nreturn {revision=6,"
.."sequenceKind="..tostring(tonumber(metadata.sequenceKind or metadata.scaleSelector) or 0)..","
.."scaleSelector="..tostring(tonumber(metadata.scaleSelector or metadata.sequenceKind) or 0)..","
.."loadMode="..tostring(tonumber(metadata.loadMode) or 0)..","}
if V.ShinySupport then out[#out+1]=V.ShinySupport.filterField(metadata.shinyFilter) end
appendBodyMap(out,metadata.bodyMap)
out[#out+1]="slots={"
local slotKeys={"idle","specialA","physicalA","physicalB","physicalC","physicalD","specialB","physicalE","damage","damageHeavy","faint","extra1","specialC","extra2","extra3","extra4","takeFlight"}
for _,key in ipairs(slotKeys) do
local slot=metadata.slots and metadata.slots[key]
if type(slot)=="table" then
out[#out+1]="["..q(key).."]={index="..tostring(tonumber(slot.index) or -1)
..",animationIndex="..tostring(tonumber(slot.animationIndex) or -1)
..",animType="..tostring(tonumber(slot.animType) or 0)
..",subAnimCount="..tostring(tonumber(slot.subAnimCount) or #(slot.subAnimations or {}))
..",active="..tostring(slot.active==true)
..",duration="..num(slot.duration or 0)
..",cameraTimingCount="..tostring(tonumber(slot.cameraTimingCount) or 0)
..",cameraTimingRate="..tostring(tonumber(slot.cameraTimingRate) or 60)
..",cameraTimingExact="..tostring(slot.cameraTimingExact==true)
..",cameraTimingRaw={"
for i=1,3 do out[#out+1]=tostring(tonumber(slot.cameraTimingRaw and slot.cameraTimingRaw[i]) or 0).."," end
out[#out+1]="},cameraTimingFrames={"
for i=1,3 do out[#out+1]=tostring(tonumber(slot.cameraTimingFrames and slot.cameraTimingFrames[i]) or 0).."," end
out[#out+1]="},wazaTimingExact="..tostring(slot.wazaTimingExact==true)..",wazaTimingFrames={"
for _,frame in ipairs(slot.wazaTimingFrames or {}) do out[#out+1]=tostring(frame).."," end
out[#out+1]="},timing={"
for i=1,4 do out[#out+1]=num(slot.timing and slot.timing[i] or 0).."," end
out[#out+1]="},"
appendBodyMap(out,slot.bodyMap)
out[#out+1]="subAnimations={"
for _,sub in ipairs(slot.subAnimations or {}) do
out[#out+1]="{motionType="..tostring(tonumber(sub.motionType) or 0)
..",animationIndex="..tostring(tonumber(sub.animationIndex) or -1)
..",active="..tostring(sub.active==true).."},"
end
out[#out+1]="}},"
end
end
out[#out+1]="}}\n"
return table.concat(out)
end

local function materialTableLua(value)
if type(value)=="number" then return string.format("%.17g",value) end
if type(value)=="string" then return q(value) end
if type(value)=="boolean" then return tostring(value) end
if type(value)~="table" then return "nil" end
local keys={};for k in pairs(value) do keys[#keys+1]=k end
table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
local out={"{"}
for _,k in ipairs(keys) do out[#out+1]="["..materialTableLua(k).."]="..materialTableLua(value[k]).."," end
out[#out+1]="}";return table.concat(out)
end
local function cacheLua(stem,dex,model,texturePaths,clip,clipCount,frameSpacing,attached,sourceName,decodeMode,actionRefs,runtimeBins,runtimeStamp,actionProfile)
local b=model.bounds
local rb=model.__cbeRetailWazaOwnerBound
local function vec3(v)return "{"..num(v and v[1])..","..num(v and v[2])..","..num(v and v[3]).."}" end
local function retailBoundLua(value)
if type(value)~="table" or value.exact~=true then return "nil" end
local src,norm=value.source,value.normalized
if not (type(src)=="table" and type(norm)=="table" and type(value.sourceToCache)=="table") then return "nil" end
local t=value.sourceToCache
return "{exact=true,format="..q(value.format or "gc6e01-waza-owner-bound-v1")
..",frame=0,animationIndex="..tostring(tonumber(value.animationIndex) or -1)
..",selector="..q(value.selector or "")..",selectorExact="..tostring(value.selectorExact==true)
..",source={min="..vec3(src.min)..",max="..vec3(src.max)..",center="..vec3(src.center)..",extent="..vec3(src.extent).."}"
..",normalized={min="..vec3(norm.min)..",max="..vec3(norm.max)..",center="..vec3(norm.center)..",extent="..vec3(norm.extent).."}"
..",sourceToCache={s="..num(t.s)..",cx="..num(t.cx)..",cy="..num(t.cy)..",cz="..num(t.cz)..",exact=true}}"
end
local function sourceNormalizationLua(t)
if type(t)~="table" or not (tonumber(t.s) and t.s>0) then return "nil" end
return "{s="..num(t.s)..",cx="..num(t.cx)..",cy="..num(t.cy)..",cz="..num(t.cz)
..",rawHeight="..num(t.rawHeight)..",exact=true}"
end
local out={
"-- Generated locally from the user's own Pokemon Colosseum GC6E01 disc.\n",
"return {formatVersion=4,materialTexgenVersion=1,poseFormat=\"source-hsd-authored-pages-v4-split-actions\",\n",
"dex=",tostring(dex),",stem=",q(stem),",source=",q(sourceName),",\n",
"clip=",tostring(clip),",clipCount=",tostring(clipCount),
",idleDuration=",num(model.__cbeIdleDuration or 0),
",frameSpacing=",tostring(frameSpacing),",morphFrames=",tostring(attached),
",morphSlots=",tostring(MORPH_SLOTS),",\n",
"vertexCount=",tostring(model.vertexCount or 0),
",groupCount=",tostring(#(model.groups or {})),
",actionProfile=",q(actionProfile or "full"),
",actionInventoryComplete=",tostring(actionProfile~="storage"),
",requestedDecodeMode=",q(tostring(decodeMode or "auto")),
",decodePath=",q(tostring(model.__cbeDecodePath or "?")),
",heightRatio=",num(model.__cbeHeightRatio or 0),
",widthRatio=",num(model.__cbeWidthRatio or 0),
",envBlends=",tostring(model.__cbeEnvBlends or 0),
",envPobjs=",tostring(model.__cbeEnvPobjs or 0),
",envBlendsMulti=",tostring(model.__cbeEnvBlendsMulti or 0),
",skinFix=",tostring(model.__cbeSkinFix~=false),
",poseDrift=",num(model.__cbeDrift or 0),
",hiddenJobjs=",tostring(model.__cbeHidden or 0),
",quatJobjs=",tostring(model.__cbeQuat or 0),
",jointCount=",tostring(model.__cbeJointCount or 0),
",jointScaleMin=",num(model.__cbeJointScaleMin or 0),
",jointScaleMedian=",num(model.__cbeJointScaleMedian or 0),
",jointScaleMax=",num(model.__cbeJointScaleMax or 0),
",jointScaleOutliers=",tostring(model.__cbeJointScaleOutliers or 0),
",renderPassFilter=",tostring(model.__cbeRenderPassFilter~=false),
",nonRenderJobjs=",tostring(model.__cbeNonRenderJobjs or 0),
",nonRenderDobjs=",tostring(model.__cbeNonRenderDobjs or 0),
",shadowDobjs=",tostring(model.__cbeShadowDobjs or 0),
",semanticRootsOnly=",tostring(model.__cbeSemanticRootsOnly==true),
",semanticRootCount=",tostring(model.__cbeSemanticRootCount or 0),
",envelopeCoordEntries=",tostring(model.__cbeEnvelopeCoordEntries or 0),
",singleEnvelopeCoord=",tostring(model.__cbeSingleEnvelopeCoord or 0),
",singleEnvelopeNoCoord=",tostring(model.__cbeSingleEnvelopeNoCoord or 0),
",inverseBindMissing=",tostring(model.__cbeInverseBindMissing or 0),
",placeholderGroupsRemoved=",tostring(model.__cbePlaceholderGroupsRemoved or 0),
",placeholderVertsRemoved=",tostring(model.__cbePlaceholderVertsRemoved or 0),",\n",
"retailWazaOwnerBound=",retailBoundLua(rb),",\n",
"sourceNormalization=",sourceNormalizationLua(model.__cbeSourceNormalization),",\n",
"bounds={min={",num(b.min[1]),",",num(b.min[2]),",",num(b.min[3]),
"},max={",num(b.max[1]),",",num(b.max[2]),",",num(b.max[3]),
"},center={",num(b.center[1]),",",num(b.center[2]),",",num(b.center[3]),"}},\n",
"jointPositions=",jointLua(model.jointPositions),",jointFrames=",jointFramesLua(model.jointFrames),",\n",
"groups={\n",
}
if runtimeBins then
table.insert(out,3,"runtimeMeshVersion=1,stamp="..q(runtimeStamp or "")..",\n")
end
for gi,g in ipairs(model.groups) do
out[#out+1]="{material="..q("pkx_group_"..gi)
local tp=texturePaths[gi]
if tp then out[#out+1]=",texture={path="..q(tp.path)..",w="..tp.w..",h="..tp.h..",wrapS="..tostring(tp.wrapS or 0)..",wrapT="..tostring(tp.wrapT or 0).."}" end
local d=g.diffuse or {1,1,1}
local a=g.ambient or {1,1,1}
local sp=g.specular or {0,0,0}
out[#out+1]=",diffuse={"..num(d[1] or 1)..","..num(d[2] or 1)..","..num(d[3] or 1).."}"
out[#out+1]=",ambient={"..num(a[1] or 1)..","..num(a[2] or 1)..","..num(a[3] or 1).."}"
out[#out+1]=",specular={"..num(sp[1] or 0)..","..num(sp[2] or 0)..","..num(sp[3] or 0).."}"
out[#out+1]=",alpha="..num(g.alpha or 1)
out[#out+1]=",shininess="..num(g.shininess or 0)
out[#out+1]=",xlu="..tostring(g.xlu==true)..",noz="..tostring(g.noz==true)
out[#out+1]=",renderFlags="..tostring(g.renderFlags or 0)
out[#out+1]=",shadow="..tostring(g.shadow==true)..",effect="..tostring(g.effect==true)
out[#out+1]=",textureSlot="..tostring(g.textureSlot or -1)
local sourceTexture=g.texture
out[#out+1]=",textureColorMap="..tostring(sourceTexture and sourceTexture.colorMap or 5)
out[#out+1]=",textureAlphaMap="..tostring(sourceTexture and sourceTexture.alphaMap or 0)
out[#out+1]=",textureBlend="..num(sourceTexture and sourceTexture.blending or 1)
out[#out+1]=",textureIntensityAlpha="..tostring(sourceTexture and (sourceTexture.format==0 or sourceTexture.format==1) or false)
if g.sourceTextureAnimation then out[#out+1]=",sourceTextureAnimation="..materialTableLua(g.sourceTextureAnimation) end
local coordMode=sourceTexture and tonumber(sourceTexture.coordinateMode) or 0
out[#out+1]=",textureCoordMode="..tostring(coordMode or 0)
out[#out+1]=",textureTexgen="..tostring(sourceTexture and tonumber(sourceTexture.texgen) or 0)
if coordMode==1 and HSD and type(HSD.reflectionTextureMatrix)=="function" then
out[#out+1]=",reflectionTexMtx="..mat4Lua(HSD.reflectionTextureMatrix(sourceTexture))
end
if runtimeBins and runtimeBins[gi] then
out[#out+1]=",vertexStride="..tostring(STRIDE)..",runtimeBin="..q(runtimeBins[gi]).."},\n"
else
out[#out+1]=",vertexStride="..tostring(STRIDE)..",verticesPacked="..packedVerticesLua(g.vertices).."},\n"
end
end
out[#out+1]="},\nactions={\n"
for _,key in ipairs(ACTION_ORDER) do
local a=actionRefs and actionRefs[key]
if a then
out[#out+1]="["..q(key).."]={clip="..tostring(a.clip or -1)..",duration="..num(a.duration or 0)
if a.alias then out[#out+1]=",alias="..q(a.alias)
elseif a.path then out[#out+1]=",path="..q(a.path) end
out[#out+1]="},\n"
end
end
out[#out+1]="}}\n"
return table.concat(out)
end

local function write(mod,path,data,generated)
if Persist and extractionContext().preserveExisting==true then
local _,why=Persist.preserve(mod,"pokemon",path,data)
assert(why==nil,why)
end



local ok,err
if GeneratedAssets and type(GeneratedAssets.write)=="function" then
ok,err=GeneratedAssets.write(path,data)
else ok,err=mod.cache:write(path,data) end
assert(ok,err or ("cache write failed: "..path))
if generated then generated[#generated+1]=path end
end









local ACTION_PACK_VERSION=1
local ACTION_PACK_GUARD_VERSION=3
local function floorSlotsForGroups(groups)
local out={}
for slot=0,MORPH_SLOTS do out[slot+1]=math.huge end
for _,g in ipairs(groups or {}) do
for vi,v in ipairs(g.vertices or {}) do
if checkpoint and vi%128==0 then checkpoint("Measuring animation floor") end
for slot=0,MORPH_SLOTS do
local at=(slot==0) and 1 or (9+(slot-1)*3)
local y=tonumber(v[at+1] or v[2])
if y and y<out[slot+1] then out[slot+1]=y end
end
end
end
for i=1,#out do if out[i]==math.huge then out[i]=0 end end
return out
end
local function numberListLua(values)
local out={"{"}
for i=1,#(values or {}) do out[#out+1]=num(values[i]);out[#out+1]="," end
out[#out+1]="}";return table.concat(out)
end
local function actionPackTag(key)
return tostring(key or "action"):gsub("[^%w_%-]","_")
end
local function compressActionBytes(bytes)
if love and love.data and type(love.data.compress)=="function" then


local ok,value=pcall(love.data.compress,"string","zlib",bytes,3)
if ok and type(value)=="string" and #value<#bytes then return value,"zlib" end
end
return bytes,"raw"
end
local function packedGroupLua(g)
return "{binaryPath="..q(g.binaryPath)..",compression="..q(g.compression)
..",bundleRawBytes="..tostring(g.bundleRawBytes or 0)..",bundleStoredBytes="..tostring(g.bundleStoredBytes or 0)
..",offset="..tostring(g.offset or 0)..",rawBytes="..tostring(g.rawBytes or 0)
..",vertexCount="..tostring(g.vertexCount or 0)..",vertexStride="..tostring(g.vertexStride or STRIDE).."}"
end
local function packedGroupsLua(groups,floorSlots)
local out={"{_packedActionVersion="..ACTION_PACK_VERSION..",_poseGuardVersion="..ACTION_PACK_GUARD_VERSION
..",_floorMinYSlots="..numberListLua(floorSlots)..","}
for _,g in ipairs(groups or {}) do out[#out+1]=packedGroupLua(g).."," end
out[#out+1]="}";return table.concat(out)
end
local function actionPackedPayloadLua(mod,cacheRoot,key,a,generated,written)




local chunks,offset={},0
local function packGroups(sourceGroups)
local packed={}
for _,g in ipairs(sourceGroups or {}) do
local raw=runtimeVerticesBytes(g.vertices)
if type(raw)~="string" then return nil,"float32 action pack unavailable" end
packed[#packed+1]={offset=offset,rawBytes=#raw,vertexCount=#(g.vertices or {}),vertexStride=STRIDE}
chunks[#chunks+1]=raw;offset=offset+#raw
end
return packed
end
local pagePacked=nil
local singlePacked=nil
if a.pages then
pagePacked={}
for pi,page in ipairs(a.pages or {}) do
local packed,why=packGroups(page.model and page.model.groups)
if not packed then return nil,why end
pagePacked[pi]=packed
end
else
singlePacked=select(1,packGroups(a.model and a.model.groups))
if not singlePacked then return nil,"float32 action pack unavailable" end
end
if offset<=0 then return nil,"compact action has no geometry" end
local raw=table.concat(chunks)
local body,compression=compressActionBytes(raw)
local ext=compression=="zlib" and ".f32z" or ".f32"
local path=cacheRoot.."/actions/packed_v1/"..actionPackTag(key)..ext
write(mod,path,body,generated);written[#written+1]=path
local function attach(groups)
for _,g in ipairs(groups or {}) do
g.binaryPath=path;g.compression=compression;g.bundleRawBytes=#raw;g.bundleStoredBytes=#body
end
return groups
end
local out={"-- Compact canonical native Pokemon action bank.\nreturn {packedActionVersion="..ACTION_PACK_VERSION
..",poseGuardVersion="..ACTION_PACK_GUARD_VERSION..",clip="..tostring(a.clip or -1)
..",duration="..num(a.duration or 0)}
if a.pages then
out[#out+1]=",dense=true,frameSpacing="..tostring(a.frameSpacing or 1)
..",totalIntervals="..tostring(a.totalIntervals or 0)..",pages={\n"
for pi,page in ipairs(a.pages or {}) do
local packed=attach(pagePacked[pi])
out[#out+1]="{startPhase="..num(page.startPhase or 0)..",endPhase="..num(page.endPhase or 1)
..",morphFrames="..tostring(page.morphFrames or 0)
..",validSlots="..validSlotsLua(page.validSlots)
..",jointPositions="..jointLua(page.model and page.model.jointPositions)
..",jointFrames="..jointFramesLua(page.model and page.model.jointFrames)
..",groups="..packedGroupsLua(packed,floorSlotsForGroups(page.model and page.model.groups)).."},\n"
end
out[#out+1]="}"
else
local packed=attach(singlePacked)
out[#out+1]=",frameSpacing="..tostring(a.frameSpacing or 1)
..",morphFrames="..tostring(a.morphFrames or 0)
..",validSlots="..validSlotsLua(a.validSlots)
..",jointPositions="..jointLua(a.model and a.model.jointPositions)
..",jointFrames="..jointFramesLua(a.model and a.model.jointFrames)
..",groups="..packedGroupsLua(packed,floorSlotsForGroups(a.model and a.model.groups))
end
out[#out+1]="}\n"
return table.concat(out)
end






local REACTION_RUNTIME_DEFER={damage=true,damageHeavy=true,faint=true}
local function eagerRuntimeActionAllowed(actionProfile,key,a)
if REACTION_RUNTIME_DEFER[key] then return false end
if key=="idle" then return true end



return false
end
local function runtimeActionTag(name) return tostring(name or "action"):gsub("[^%w_%-]","_") end
local function runtimeActionRoot(cacheRoot) return cacheRoot.."/runtime_mesh_v1" end
local function runtimeActionManifestPath(cacheRoot,name)
return runtimeActionRoot(cacheRoot).."/action_"..runtimeActionTag(name)..".lua"
end
local function runtimeActionBinPath(cacheRoot,name,i)
return runtimeActionRoot(cacheRoot).."/action_"..runtimeActionTag(name)..("_%02d.f32"):format(tonumber(i) or 0)
end
local function runtimeActionFloorPath(cacheRoot,name)
return runtimeActionRoot(cacheRoot).."/action_"..runtimeActionTag(name).."_floor.lua"
end
local function scalarArrayLua(values,count)
local out={"{"}
for i=1,count or #(values or {}) do out[#out+1]=num(values and values[i] or 0).."," end
out[#out+1]="}"
return table.concat(out)
end
local function actionFloorSlots(model)
local mins={}
for slot=0,MORPH_SLOTS do mins[slot+1]=math.huge end
for _,g in ipairs((model and model.groups) or {}) do
for _,v in ipairs(g.vertices or {}) do
local row=normalizedVertexRow(v)
for slot=0,MORPH_SLOTS do
local at=(slot==0) and 1 or (9+(slot-1)*3)
local y=tonumber(row[at+1])
if y and y<mins[slot+1] then mins[slot+1]=y end
end
end
end
for i=1,MORPH_SLOTS+1 do if mins[i]==math.huge then mins[i]=0 end end
return mins
end
local function runtimeActionManifestLua(a,stamp)
local out={"return {runtimeMeshVersion=1,stamp="..q(stamp)
..",clip="..tostring(tonumber(a and a.clip) or -1)
..",duration="..num(tonumber(a and a.duration) or 0)}
if a and a.alias then
out[#out+1] = ",alias="..q(a.alias)
elseif a and type(a.pages)=="table" and #a.pages>0 then
out[#out+1] = ",frameSpacing="..num(a.frameSpacing or 1)
..",totalIntervals="..tostring(tonumber(a.totalIntervals) or 0)..",pages={"
for _,page in ipairs(a.pages) do
local model=page and page.model
out[#out+1]="{startPhase="..num(page and page.startPhase or 0)
..",endPhase="..num(page and page.endPhase or 1)
..",morphFrames="..tostring(tonumber(page and page.morphFrames) or 0)
..",jointPositions="..jointLua(model and model.jointPositions)
..",jointFrames="..jointFramesLua(model and model.jointFrames)
..",validSlots="..validSlotsLua(page and page.validSlots)
..",groupCount="..tostring(type(model and model.groups)=="table" and #model.groups or 0).."},"
end
out[#out+1]="}"
else
local model=a and a.model
out[#out+1] = ",frameSpacing="..num(a and a.frameSpacing or 1)
..",morphFrames="..tostring(tonumber(a and a.morphFrames) or 0)
..",jointPositions="..jointLua(model and model.jointPositions)
..",jointFrames="..jointFramesLua(model and model.jointFrames)
..",validSlots="..validSlotsLua(a and a.validSlots)
..",groupCount="..tostring(type(model and model.groups)=="table" and #model.groups or 0)
end
out[#out+1]="}\n"
return table.concat(out)
end
local function emitRuntimeActionSidecar(mod,cacheRoot,key,a,stamp,generated,runtimePaths,trail)
if not (type(a)=="table" and type(stamp)=="string" and stamp~=""
and ((love and love.data and type(love.data.pack)=="function") or type(string.pack)=="function")) then return false,"runtime pack unavailable" end
runtimePaths=runtimePaths or {}
if REACTION_RUNTIME_DEFER[key] and not a.alias then return false,"reaction stabilization deferred" end
local function emit(path,data)
local ok,err=pcall(write,mod,path,data,generated)
if not ok then return false,tostring(err) end
runtimePaths[#runtimePaths+1]=path
return true
end
local function emitModel(tag,model)
if not (type(model)=="table" and type(model.groups)=="table" and #model.groups>0) then return false,"action model unavailable" end
for gi,g in ipairs(model.groups) do
local bytes=runtimeVerticesBytes(g.vertices)
if not bytes then return false,"action runtime pack failed" end
local ok,why=emit(runtimeActionBinPath(cacheRoot,tag,gi),bytes);if not ok then return false,why end
end
local floor=actionFloorSlots(model)
local floorLua="return {runtimeMeshVersion=1,stamp="..q(stamp)
..",groupCount="..tostring(#model.groups)..",floorMinYSlots="..scalarArrayLua(floor,MORPH_SLOTS+1).."}\n"
return emit(runtimeActionFloorPath(cacheRoot,tag),floorLua)
end
if not a.alias then
if type(a.pages)=="table" and #a.pages>0 then
for pi,page in ipairs(a.pages) do
local ok,why=emitModel(key.."/page"..pi,page and page.model);if not ok then return false,why end
end
else
local ok,why=emitModel(key,a.model);if not ok then return false,why end
end
end



local ok,why=emit(runtimeActionManifestPath(cacheRoot,key),runtimeActionManifestLua(a,stamp))
if ok and trail then trail[#trail+1]="runtime action sidecar: "..tostring(key).." READY (direct float32)" end
return ok,why
end

function P.cachePath(dex,variant) return Dex.cacheRoot(dex,variant).."/model_cache.lua" end
function P.compactActionMarkerPath(dex,variant) return Dex.cacheRoot(Dex.modelKey(dex,variant)).."/actions/compact_v1.complete" end
function P.revPath(dex,variant) return Dex.cacheRoot(dex,variant).."/rev.txt" end
function P.materialTexgenPath(dex,variant) return Dex.cacheRoot(dex,variant).."/material_texgen_v1.complete" end









local function stampOptions(opts)
opts=opts or {}
return {
skinFix=opts.skinFix~=false,
renderPassFilter=opts.renderPassFilter~=false,
decodeMode=tostring(opts.decodeMode or "auto"),
}
end

function P.stamp(opts)
local o=stampOptions(opts)
return ("pkx-extractor=%d\nstride=%d\nmorphSlots=%d\nskinFix=%s\nrenderPassFilter=%s\ndecodeMode=%s\n")
:format(P.revision,STRIDE,MORPH_SLOTS,tostring(o.skinFix),tostring(o.renderPassFilter),o.decodeMode)
end




local CACHE_COMPAT_REVISIONS={[39]=true}
local function stampForRevision(revision,opts)
local o=stampOptions(opts)
return ("pkx-extractor=%d\nstride=%d\nmorphSlots=%d\nskinFix=%s\nrenderPassFilter=%s\ndecodeMode=%s\n")
:format(revision,STRIDE,MORPH_SLOTS,tostring(o.skinFix),tostring(o.renderPassFilter),o.decodeMode)
end
function P.isCompatibleStamp(raw,opts)
if type(raw)~="string" then return false end
for revision in pairs(CACHE_COMPAT_REVISIONS) do
if raw==stampForRevision(revision,opts) then return true,revision end
end
return false
end

function P.isCached(mod,dex,opts)
if not (mod.cache and mod.cache.info) then return false end
local identity=Dex.sourceIdentity and Dex.sourceIdentity(dex,opts and opts.variant)
if identity then
local ok,raw=pcall(mod.cache.read,mod.cache,Dex.sourceIdentityPath(dex,opts and opts.variant))
if not ok or raw~=identity then return false end
end
local info=mod.cache:info(P.cachePath(dex,opts and opts.variant))
if not (type(info)=="table" and (info.type==nil or info.type=="file")) then return false end





local ok,raw=pcall(mod.cache.read,mod.cache,P.revPath(dex,opts and opts.variant))
return ok and P.isCompatibleStamp(raw,opts)==true
end

P.MANIFEST="cache/pokemon/manifest.lua"
P.MANIFEST_SHARD_SIZE=32
local MANIFEST_SHARD_COUNT=math.ceil((tonumber(Dex and Dex.speciesCount) or 386)/P.MANIFEST_SHARD_SIZE)
local manifestMemo=setmetatable({}, {__mode="k"})
local manifestStats={reads=0,parses=0,memoHits=0,writes=0,serializedEntries=0}









local function manifestShardIndex(dex)
dex=tonumber(dex)
if not dex or dex<1 then return nil end
return math.floor((dex-1)/P.MANIFEST_SHARD_SIZE)+1
end
function P.manifestShardPath(dexOrIndex,isIndex)
local index=isIndex and tonumber(dexOrIndex) or manifestShardIndex(dexOrIndex)
if not index or index<1 then return nil end
return ("cache/pokemon/manifest_v2/%02d.lua"):format(math.floor(index))
end
local function memoBucket(mod)
local token=mod and mod.cache
if token==nil then return nil end
local bucket=manifestMemo[token]
if not bucket then bucket={};manifestMemo[token]=bucket end
return bucket
end
local function readManifestPath(mod,path,memoKey,force)
local bucket=memoBucket(mod)
if not force and bucket and bucket[memoKey]~=nil then
manifestStats.memoHits=manifestStats.memoHits+1
return bucket[memoKey]
end
manifestStats.reads=manifestStats.reads+1
local ok,raw=pcall(mod.cache.read,mod.cache,path)
if not ok or type(raw)~="string" then
local empty={};if bucket then bucket[memoKey]=empty end;return empty
end
local chunk=load(raw,"@generated/"..path)
if not chunk then
local empty={};if bucket then bucket[memoKey]=empty end;return empty
end
manifestStats.parses=manifestStats.parses+1
local okRun,value=pcall(chunk)
if not okRun or type(value)~="table" then value={} end
if bucket then bucket[memoKey]=value end
return value
end
local function readLegacyManifest(mod,force)
return readManifestPath(mod,P.MANIFEST,"legacy",force)
end
local function readManifestShard(mod,index,force)
return readManifestPath(mod,P.manifestShardPath(index,true),"shard:"..tostring(index),force)
end
local function appendManifestPaths(out,seen,list)
for _,entry in ipairs(list or {}) do
if type(entry)=="table" then
for _,path in ipairs(entry.paths or {}) do
if type(path)=="string" and path~="" and not seen[path] then seen[path]=true;out[#out+1]=path end
end
end
end
end

function P.manifestPaths(mod)


local out,seen={},{}
appendManifestPaths(out,seen,readLegacyManifest(mod,true))
for index=1,MANIFEST_SHARD_COUNT do
appendManifestPaths(out,seen,readManifestShard(mod,index,true))
local shard=P.manifestShardPath(index,true)
if shard and not seen[shard] then seen[shard]=true;out[#out+1]=shard end
end
if not seen[P.MANIFEST] then out[#out+1]=P.MANIFEST end
return out
end

function P.invalidateManifestMemo(mod)
if mod and mod.cache then manifestMemo[mod.cache]=nil
else manifestMemo=setmetatable({}, {__mode="k"}) end
return true
end

local function recordManifest(mod,dex,stem,paths,variant,mergeExisting)
local cacheKey=Dex.modelKey(dex,variant)
local index=manifestShardIndex(dex)
if not index or index>MANIFEST_SHARD_COUNT then return false,"invalid manifest dex" end
local list=readManifestShard(mod,index,false)
local replaced=false
local stalePaths=nil
for i,entry in ipairs(list) do
if type(entry)=="table" and Dex.modelKey(entry.dex,entry.variant)==cacheKey then
if mergeExisting then
local merged,seen={},{}
for _,path in ipairs(entry.paths or {}) do if type(path)=="string" and path~="" and not seen[path] then seen[path]=true;merged[#merged+1]=path end end
for _,path in ipairs(paths or {}) do if type(path)=="string" and path~="" and not seen[path] then seen[path]=true;merged[#merged+1]=path end end
list[i]={dex=dex,variant=variant,stem=stem or entry.stem,paths=merged}
else
stalePaths={};for _,path in ipairs(entry.paths or {}) do stalePaths[#stalePaths+1]=path end
list[i]={dex=dex,variant=variant,stem=stem,paths=paths}
end
replaced=true;break
end
end
if not replaced then list[#list+1]={dex=dex,variant=variant,stem=stem,paths=paths} end
local out={"-- Generated. Sharded lazy Colosseum Pokemon cache manifest.\nreturn {\n"}
for _,entry in ipairs(list) do
out[#out+1]=("{dex=%d,variant=%s,stem=%s,paths={"):format(tonumber(entry.dex) or 0,q(entry.variant or "normal"),q(entry.stem))
for _,path in ipairs(entry.paths or {}) do out[#out+1]=q(path).."," end
out[#out+1]="}},\n"
end
out[#out+1]="}\n"
local body=table.concat(out)
manifestStats.writes=manifestStats.writes+1
manifestStats.serializedEntries=manifestStats.serializedEntries+#list
local ok,written=pcall(mod.cache.write,mod.cache,P.manifestShardPath(index,true),body)
if not ok or written==false then
local bucket=memoBucket(mod);if bucket then bucket["shard:"..tostring(index)]=nil end
return false,tostring(written)
end




if stalePaths and GeneratedAssets and type(GeneratedAssets.delete)=="function" then
local keep={};for _,path in ipairs(paths or {}) do keep[path]=true end
for _,path in ipairs(stalePaths) do
if type(path)=="string" and path~="" and not keep[path] then pcall(GeneratedAssets.delete,path) end
end
end
return true
end







local function commitSelectiveActions(mod,dex,variant,stem,cacheRoot,actions,wantedActions,stamp,generated,trail)
local requested={}
for _,key in ipairs(ACTION_ORDER) do
local wanted=wantedActions and wantedActions[key]
if wanted==true or type(wanted)=="table" then requested[#requested+1]=key end
end
if #requested==0 then return {ready=true,actions={},paths={}} end
for _,key in ipairs(requested) do
if type(actions and actions[key])~="table" then return nil,"source action unavailable: "..tostring(key) end
end

local written,refs,runtimePaths={},{},{}
for _,key in ipairs(requested) do
local a=actions[key]
local ref={clip=a.clip,duration=a.duration}
if a.alias then
ref.alias=a.alias
else
local path=(cacheRoot.."/actions/%s.lua"):format(key)
local payload,packWhy=actionPackedPayloadLua(mod,cacheRoot,key,a,generated,written)
if not payload then return nil,"compact action pack failed: "..tostring(packWhy) end
write(mod,path,payload,generated)
ref.path=path;written[#written+1]=path
end


local descriptor=selectiveActionRefPathFromRoot(cacheRoot,key)
write(mod,descriptor,selectiveActionRefLua(ref,stamp),generated)
written[#written+1]=descriptor;refs[key]=ref
end
for _,path in ipairs(runtimePaths) do written[#written+1]=path end
local ok,why=recordManifest(mod,dex,stem,written,variant,true)
if not ok then return nil,"selective action manifest update failed: "..tostring(why) end
return {ready=true,actions=refs,paths=written,count=#requested}
end




local function extractSpeciesImpl(mod,disc,dex,opts)
opts=opts or {}
local variant=Dex.variant(dex,opts.variant)
dex=Dex.number(dex)
if not dex then return nil,"invalid species" end
local cacheKey=Dex.modelKey(dex,variant)
local cacheRoot=Dex.cacheRoot(cacheKey)
local targetHeight=tonumber(opts.targetHeight) or 16.0
local progress=function(label,current,total)
if opts.progress then opts.progress(label,current,total) end
checkpoint(label)
end
local generated=opts.generated
local currentSkinFix=opts.skinFix~=false
local currentRenderPassFilter=opts.renderPassFilter~=false




local selectiveActions=opts.selectiveActions==true and type(opts.wantedActions)=="table"
local actionProfile=selectiveActions and "selective" or (opts.actionProfile=="storage" and "storage" or "full")
local wantedActions=selectiveActions and opts.wantedActions or (actionProfile=="storage" and {idle=true} or nil)











pcall(function()
mod.cache:write("cache/pokemon/_last_attempt.txt",
("dex=%s skinFix=%s renderPassFilter=%s decodeMode=%s time=%s\n")
:format(tostring(dex),tostring(currentSkinFix),tostring(currentRenderPassFilter),
tostring(opts.decodeMode or "auto"),tostring(os.time and os.time() or "?")))
end)

local archiveName,stem=Dex.archive(dex,variant,opts.unownForm)
if not archiveName then return nil,("dex %s has no Colosseum asset"):format(tostring(dex)) end

local trail={("pkx %s dex=%s archive=%s"):format(safe(stem),tostring(dex),safe(archiveName))}

local file=disc:file(archiveName)
if not file then return nil,("source archive missing: "..archiveName) end
local okArc,arc=pcall(FSYS.open,disc,file)
if not okArc then return nil,("FSYS open failed for %s: %s"):format(archiveName,safe(arc)) end

local members=arc:list()
if #members==0 then return nil,("archive %s has no members"):format(archiveName) end


local entry=members[1]
local typed=arc:modelEntries()
if #typed>0 then entry=typed[1] end
trail[#trail+1]=("member %s type=0x%02X bytes=%d"):format(safe(entry.name),entry.fileType or 0,entry.storedSize or 0)

progress(("POKEMON %s DECOMPRESS"):format(stem:upper()),0,1)
local okBlob,blob=pcall(arc.extract,arc,entry,{
maxOutput=48*1024*1024,
checkpoint=opts.checkpoint or opts.progress,
progress=function(done,total)
local pct=(tonumber(total) or 0)>0 and math.floor((tonumber(done) or 0)*100/total) or 0
progress(("POKEMON %s DECOMPRESS %d%%"):format(stem:upper(),pct),0,1)
end,
})
if not okBlob or type(blob)~="string" then
return nil,("LZSS extract failed for %s: %s"):format(archiveName,safe(blob))
end
trail[#trail+1]=("decompressed bytes=%d"):format(#blob)

progress(("POKEMON %s CLIPS"):format(stem:upper()),0,1)
local decodeMode=tostring(opts.decodeMode or "auto")
trail[#trail+1]="decode mode: "..decodeMode
trail[#trail+1]="skin fix: "..(currentSkinFix and "on (native IBM + owner-coordinate envelope matrices)" or "off (legacy raw-world envelope path)")
trail[#trail+1]="source render-pass filter: "..(currentRenderPassFilter and "on (skip JOBJ geometry the Colosseum renderer never submits)" or "off (diagnostic legacy draw-all)")
local metadata=nil
if PKXMetadata and type(PKXMetadata.parse)=="function" then
local okMeta,value=pcall(PKXMetadata.parse,blob)
if okMeta and type(value)=="table" then metadata=value
else trail[#trail+1]="PKX metadata parse failed: "..safe(value) end
end
local idleSlot=metadata and metadata.slots and metadata.slots.idle
local sourceIdle=idleSlot and idleSlot.active~=false and tonumber(idleSlot.animationIndex)
local clip,clipCount,clipNote,sourceInfo
if sourceIdle and sourceIdle>=0 then
local ref=decodeBest(blob,sourceIdle,0,false,nil,nil,decodeMode)
if ref then
sourceInfo=HSD.nativeAnimationInfo(ref,sourceIdle)
clipCount=ref.stats and tonumber(ref.stats.nativeClipCount) or 0
if sourceInfo and (clipCount==0 or sourceIdle<clipCount) then
clip=sourceIdle
trail[#trail+1]=("PKX authoritative idle: clip %d / %.3fs / %.3f source frames")
:format(clip,tonumber(idleSlot.duration) or 0,tonumber(sourceInfo.endFrame) or 0)
end
end
end
local trustedIdle=clip~=nil
if not trustedIdle then
clip,clipCount,clipNote=chooseIdleClip(blob,targetHeight,trail,decodeMode)
end
if clipNote then trail[#trail+1]="note: "..clipNote end
clip=clip or 0

progress(("POKEMON %s DECODE"):format(stem:upper()),0,1)
local attachedOverride=nil
local base,decodePath,_,decodeErr=decodeBest(blob,clip,0,true,trail,"final",decodeMode)
if not base then
return nil,("HSD decode failed for %s: %s"):format(archiveName,safe(decodeErr))
end







local pre=boundsReport(base)
if pre then
trail[#trail+1]=("pre-normalize height raw=%.4f trimmed=%.4f ratio=%.2f | width raw=%.4f trimmed=%.4f ratio=%.2f | verts=%d")
:format(pre.rawH,pre.trimH,pre.heightRatio,pre.rawW,pre.trimW,pre.widthRatio,pre.count)
if pre.heightRatio>1.6 or pre.widthRatio>1.6 then
trail[#trail+1]="WARNING: outlier vertices detected. A few strays are inflating the bounding box, "
.."which shrinks the visible body when the model is normalized. Likely an envelope/bind transform "
.."issue on skinned POBJs rather than missing geometry."
end
end

local transform=measure(base,targetHeight)
local retailOwnerBound,retailOwnerBoundWhy=retailWazaOwnerBound(base,metadata,transform)
if retailOwnerBound then
trail[#trail+1]=("retail Waza owner bound: exact frame-0 animation %d (%s)")
:format(retailOwnerBound.animationIndex,retailOwnerBound.selector)
else
trail[#trail+1]="retail Waza owner bound blocked: "..safe(retailOwnerBoundWhy)
end
applyTransform(base,transform)






local bindRef=not trustedIdle and decodeBest(blob,0,0,true,nil,nil,decodeMode) or nil
local bindVerts=bindRef and tonumber(bindRef.vertexCount) or 0
local poseVerts=tonumber(base.vertexCount) or 0
local finalDrift=nil
if clip>0 and bindRef then
applyTransform(bindRef,transform)
finalDrift=motionRatio(bindRef,base,targetHeight)
end
local lostGeometry=(clip>0 and bindVerts>0 and poseVerts<bindVerts*0.995)
local incoherent=(finalDrift~=nil and finalDrift>POSE_COHERENCE_MAX)
if clip>0 and (lostGeometry or incoherent) then
trail[#trail+1]=("FALLBACK TO BIND POSE: clip %d %s. Cached static and correctly "
.."assembled instead of animated and scattered.")
:format(clip,lostGeometry
and ("decoded %d verts vs %d at bind"):format(poseVerts,bindVerts)
or ("drifts %.3f from bind, past the %.2f limit"):format(finalDrift,POSE_COHERENCE_MAX))
base=bindRef
decodePath=(decodePath or "?").."/bind-fallback"
clip=0
attachedOverride=0
end
base.__cbeRetailWazaOwnerBound=retailOwnerBound



base.__cbeSourceNormalization={s=transform.s,cx=transform.cx,cy=transform.cy,cz=transform.cz,
rawHeight=pre and pre.rawH or (transform.s>0 and targetHeight/transform.s or nil)}
if V.PokemonMaterial then
for _,g in ipairs(base.groups or {}) do
local baked,why=V.PokemonMaterial.bakeTexture(g.texture)
if baked then trail[#trail+1]="source static texture TEV baked"
elseif why then trail[#trail+1]="source texture TEV: "..why end
end
end
if HSD.textureAnimations then
local animations,why=HSD.textureAnimations(base)
for gi,anim in pairs(animations or {}) do base.groups[gi].sourceTextureAnimation=anim end
if why then trail[#trail+1]="material animation: "..tostring(why) end
end
base.__cbeDrift=finalDrift or 0
trail[#trail+1]=("decoded via %s: vertices=%d groups=%d")
:format(tostring(decodePath),base.vertexCount or 0,#(base.groups or {}))



local actions=extractActionBanks(blob,base,transform,metadata,clipCount or 0,trail,decodeMode,wantedActions)
trail[#trail+1]="action extraction profile: "..actionProfile

local spacing=trustedIdle and actionSpacing(idleSlot.duration,sourceInfo.endFrame)
or math.max(1,math.floor(tonumber(opts.frameSpacing) or 4))
base.__cbeIdleDuration=trustedIdle and tonumber(idleSlot.duration) or 0
if base.__cbeIdleDuration<=0 and trustedIdle then
base.__cbeIdleDuration=(tonumber(sourceInfo.endFrame) or 0)/30
end
local attached=0
if attachedOverride==0 then clip=0 end
if attachedOverride~=0 and (trustedIdle or clip>0) then
progress(("POKEMON %s FRAMES"):format(stem:upper()),0,1)
attached=attachFrames(blob,base,clip,transform,targetHeight,spacing,trail,decodeMode,"idle")
trail[#trail+1]=("authored frames attached=%d/%d spacing=%.3f"):format(attached,MORPH_SLOTS,spacing)
else
trail[#trail+1]="static: no authored clip selected"
end

base.__cbeDecodePath=decodePath



local st=base.stats or {}
base.__cbeEnvBlends=tonumber(st.envelopeBlends) or 0
base.__cbeEnvPobjs=tonumber(st.envelopePobjs) or 0
base.__cbeEnvBlendsMulti=tonumber(st.envelopeBlendsMulti) or 0
base.__cbeSkinFix=currentSkinFix
base.__cbeHidden=tonumber(st.hiddenJobjs) or 0
base.__cbeQuat=tonumber(st.quatJobjs) or 0
trail[#trail+1]=("envelopes: %d matrices (%d multi-bone) across %d enveloped meshes")
:format(base.__cbeEnvBlends,base.__cbeEnvBlendsMulti,base.__cbeEnvPobjs)







base.__cbeJointCount=tonumber(st.jointCount) or 0
base.__cbeJointScaleMin=tonumber(st.jointScaleMin) or 0
base.__cbeJointScaleMedian=tonumber(st.jointScaleMedian) or 0
base.__cbeJointScaleMax=tonumber(st.jointScaleMax) or 0
base.__cbeJointScaleOutliers=tonumber(st.jointScaleOutliers) or 0
trail[#trail+1]=("joint world scale: %d contributing joints, min=%.4f median=%.4f max=%.4f, %d outlier(s) >=10x off median")
:format(base.__cbeJointCount,base.__cbeJointScaleMin,base.__cbeJointScaleMedian,base.__cbeJointScaleMax,base.__cbeJointScaleOutliers)





base.__cbeRenderPassFilter=currentRenderPassFilter
base.__cbeNonRenderJobjs=tonumber(st.nonRenderJobjs) or 0
base.__cbeNonRenderDobjs=tonumber(st.nonRenderDobjs) or 0
base.__cbeShadowDobjs=tonumber(st.shadowDobjs) or 0
base.__cbeSemanticRootsOnly=base.semanticRootsOnly==true
base.__cbeSemanticRootCount=tonumber(base.semanticRootCount) or 0
base.__cbeEnvelopeCoordEntries=tonumber(st.envelopeCoordEntries) or 0
base.__cbeSingleEnvelopeCoord=tonumber(st.singleEnvelopeCoord) or 0
base.__cbeSingleEnvelopeNoCoord=tonumber(st.singleEnvelopeNoCoord) or 0
base.__cbeInverseBindMissing=tonumber(st.inverseBindMissing) or 0
trail[#trail+1]=("source visibility: %d non-render JOBJ(s) + %d DOBJ pass mismatch(es) skipped; %d shadow-pass DOBJ(s) quarantined")
:format(base.__cbeNonRenderJobjs,base.__cbeNonRenderDobjs,base.__cbeShadowDobjs)
trail[#trail+1]=("root selection: %s (%d semantic model-set root%s)")
:format(base.__cbeSemanticRootsOnly and "scene-modelset-only" or "scene-union/legacy",
base.__cbeSemanticRootCount,base.__cbeSemanticRootCount==1 and "" or "s")
trail[#trail+1]=("envelope coord: %d palette entries use owner coord; single-bone coord=%d no-coord=%d; missing IBM fallbacks=%d")
:format(base.__cbeEnvelopeCoordEntries,base.__cbeSingleEnvelopeCoord,base.__cbeSingleEnvelopeNoCoord,base.__cbeInverseBindMissing)
if pre then base.__cbeHeightRatio=pre.heightRatio;base.__cbeWidthRatio=pre.widthRatio end




base.__cbePlaceholderGroupsRemoved=tonumber(st.placeholderGroupsRemoved) or 0
base.__cbePlaceholderVertsRemoved=tonumber(st.placeholderVertsRemoved) or 0

base=mergeGroups(base)








for key,a in pairs(actions or {}) do
local valid=true
if a.model then
a.model=mergeGroups(a.model)
valid=topologyMatches(base,a.model)
elseif type(a.pages)=="table" and #a.pages>0 then
for pi,page in ipairs(a.pages) do
if not (page and page.model) then valid=false;break end
page.model=mergeGroups(page.model)
if not topologyMatches(base,page.model) then
trail[#trail+1]=("native %s page %d rejected after material merge: topology mismatch"):format(key,pi)
valid=false;break
end
end
end
if not valid then
trail[#trail+1]=("native %s rejected after material merge: topology mismatch"):format(key)
actions[key]=nil
end
end

if selectiveActions then
local stamp=P.stamp({skinFix=currentSkinFix,renderPassFilter=currentRenderPassFilter,decodeMode=decodeMode})
local committed,commitWhy=commitSelectiveActions(mod,dex,variant,stem,cacheRoot,actions,wantedActions,stamp,generated,trail)
if not committed then return nil,commitWhy end
pcall(function()
mod.cache:write("cache/pokemon/_last_attempt.txt",
("dex=%s skinFix=%s renderPassFilter=%s decodeMode=%s time=%s SELECTIVE COMPLETED actions=%d\n")
:format(tostring(dex),tostring(currentSkinFix),tostring(currentRenderPassFilter),
tostring(opts.decodeMode or "auto"),tostring(os.time and os.time() or "?"),tonumber(committed.count) or 0))
end)
progress(("POKEMON %s ACTIONS READY"):format(stem:upper()),1,1)
return {dex=dex,stem=stem,archive=archiveName,selective=true,nativeActions=committed.count,
actions=committed.actions,paths=committed.paths,actionProfile="selective",trail=trail}
end

local texturePaths,textureMap={},{}
for gi,g in ipairs(base.groups) do
if g.texture then
local sig=signature(g.texture)
local tp=textureMap[sig]
if not tp then
local path=(cacheRoot.."/tex_%02d.rgba"):format(gi)
write(mod,path,g.texture.rgba,generated)
tp={path=path,w=g.texture.w,h=g.texture.h}
textureMap[sig]=tp
end

texturePaths[gi]={path=tp.path,w=tp.w,h=tp.h,wrapS=g.texture.wrapS or 0,wrapT=g.texture.wrapT or 0}
end
end

for gi,g in ipairs(base.groups or {}) do
local d=g.diffuse or {1,1,1}
trail[#trail+1]=("  group %d: %d verts%s slot=%d diffuse=%.3f,%.3f,%.3f alpha=%.3f flags=0x%08X%s%s")
:format(gi,#(g.vertices or {}),
g.texture and (" tex %dx%d"):format(g.texture.w or 0,g.texture.h or 0) or " (untextured)",
g.textureSlot or -1,d[1] or 1,d[2] or 1,d[3] or 1,g.alpha or 1,g.renderFlags or 0,
g.shadow and " SHADOW" or "",g.effect and " EFFECT" or "")
end

local sourceName=archiveName.." :: "..tostring(entry.name)
local cachePath=P.cachePath(cacheKey)
local diagPath=cacheRoot.."/extract.txt"








local stamp=P.stamp({skinFix=currentSkinFix,renderPassFilter=currentRenderPassFilter,decodeMode=decodeMode})
local actionRefs,actionPaths={},{}
local runtimePaths={}
for _,key in ipairs(ACTION_ORDER) do
local a=actions and actions[key]
if a then
if a.alias then
actionRefs[key]={alias=a.alias,clip=a.clip,duration=a.duration}
else
local path=(cacheRoot.."/actions/%s.lua"):format(key)
local payload,packWhy=actionPackedPayloadLua(mod,cacheRoot,key,a,generated,actionPaths)
if not payload then return nil,"compact action pack failed: "..tostring(packWhy) end
write(mod,path,payload,generated)
actionRefs[key]={path=path,clip=a.clip,duration=a.duration}
actionPaths[#actionPaths+1]=path
end



end
end

if actionProfile=="full" then
local compactMarker=cacheRoot.."/actions/compact_v1.complete"
write(mod,compactMarker,"pokemon-action-pack=1\npose-guard=3\n",generated)
actionPaths[#actionPaths+1]=compactMarker
end

local metadataPath=cacheRoot.."/metadata_v1.lua"
local metadataLua=metadataCacheLua(metadata)
if metadataLua then write(mod,metadataPath,metadataLua,generated) end
write(mod,cachePath,cacheLua(stem,dex,base,texturePaths,clip,clipCount or 0,spacing,attached,sourceName,decodeMode,actionRefs,nil,nil,actionProfile),generated)





local runtimeBins={}
local runtimeOK=(love and love.data and type(love.data.pack)=="function") or type(string.pack)=="function"
if runtimeOK then
for gi,g in ipairs(base.groups or {}) do
local bytes=runtimeVerticesBytes(g.vertices)
local path=(cacheRoot.."/runtime_mesh_v1/base_%02d.f32"):format(gi)
if not bytes then runtimeOK=false;break end
local okWrite=write(mod,path,bytes,generated)
if okWrite==false then runtimeOK=false;break end
runtimeBins[gi]=path;runtimePaths[#runtimePaths+1]=path
end
end
if runtimeOK and #runtimeBins==#(base.groups or {}) and #runtimeBins>0 then
local runtimeMeta=cacheRoot.."/runtime_mesh_v1/base.lua"
write(mod,runtimeMeta,cacheLua(stem,dex,base,texturePaths,clip,clipCount or 0,spacing,attached,sourceName,decodeMode,actionRefs,runtimeBins,stamp,actionProfile),generated)
runtimePaths[#runtimePaths+1]=runtimeMeta
trail[#trail+1]="runtime mesh sidecar: READY (direct float32 upload)"
else
trail[#trail+1]="runtime mesh sidecar: deferred to first runtime materialization"
end
write(mod,diagPath,table.concat(trail,"\n").."\n",generated)






local materialTexgenPath=P.materialTexgenPath(cacheKey)
write(mod,materialTexgenPath,"material-texgen=1\n",generated)

local identity=Dex.sourceIdentity and Dex.sourceIdentity(cacheKey)
local identityPath=identity and Dex.sourceIdentityPath(cacheKey)
if identityPath then write(mod,identityPath,identity,generated) end




local revPath=P.revPath(cacheKey)
write(mod,revPath,stamp,generated)

local written={cachePath,diagPath,revPath,materialTexgenPath}
if identityPath then written[#written+1]=identityPath end
for _,path in ipairs(runtimePaths) do written[#written+1]=path end
if metadataLua then written[#written+1]=metadataPath end
for _,path in ipairs(actionPaths) do written[#written+1]=path end
local seenTex={}
for _,tp in pairs(texturePaths) do
if tp and not seenTex[tp.path] then seenTex[tp.path]=true;written[#written+1]=tp.path end
end
recordManifest(mod,dex,stem,written,variant)






pcall(function()
mod.cache:write("cache/pokemon/_last_attempt.txt",
("dex=%s skinFix=%s renderPassFilter=%s decodeMode=%s time=%s COMPLETED\n")
:format(tostring(dex),tostring(currentSkinFix),tostring(currentRenderPassFilter),
tostring(opts.decodeMode or "auto"),tostring(os.time and os.time() or "?")))
end)

progress(("POKEMON %s READY"):format(stem:upper()),1,1)
return {
dex=dex,stem=stem,cache=cachePath,archive=archiveName,
vertices=base.vertexCount,groups=#base.groups,
clip=clip,clipCount=clipCount or 0,morphFrames=attached,
nativeActions=(function() local n=0;for _ in pairs(actions or {}) do n=n+1 end;return n end)(),
actionProfile=actionProfile,bounds=base.bounds,trail=trail,
}
end





function P.prefetch(mod,disc,list,progress,generated)
progress=progress or function() end
local done,failed={},{}
for i,dex in ipairs(list or {}) do
progress(("PREFETCH %d/%d"):format(i,#list),i-1,#list)
if P.isCached(mod,dex,{skinFix=true,renderPassFilter=true,decodeMode="auto"}) then
done[#done+1]=dex
else
local ok,err=P.extractSpecies(mod,disc,dex,{progress=progress,generated=generated})
if ok then done[#done+1]=dex else failed[#failed+1]={dex=dex,error=tostring(err)} end
end
end
return {cached=done,failed=failed,total=#(list or {})}
end



P._test={normalizedVertexRow=normalizedVertexRow,denseActionIntervals=denseReactionIntervals,metadataCacheLua=metadataCacheLua,
retailWazaOwnerBound=retailWazaOwnerBound,runtimeVerticesBytes=runtimeVerticesBytes,floorSlotsForGroups=floorSlotsForGroups}

function P.extractSpecies(mod,disc,dex,opts)
opts=opts or {}
local key=contextKey();local previous=extractionContexts[key]




local preserveExisting=opts.preserveExisting~=false and Persist and Persist.has(mod,P.cachePath(dex,opts.variant)) or false
extractionContexts[key]={skinFix=opts.skinFix~=false,renderPassFilter=opts.renderPassFilter~=false,
checkpoint=opts.checkpoint or opts.progress,decodeSession={},preserveExisting=preserveExisting}
local ok,result,why=pcall(extractSpeciesImpl,mod,disc,dex,opts)
extractionContexts[key]=previous
if not ok then error(result,0) end
return result,why
end
function P.selectiveActionRefPath(dex,key,variant)
return selectiveActionRefPathFromRoot(Dex.cacheRoot(Dex.modelKey(dex,variant)),key)
end
function P.extractActions(mod,disc,dex,wantedActions,opts)
opts=opts or {}
local requested={}
for key,value in pairs(type(wantedActions)=="table" and wantedActions or {}) do
if value==true then requested[key]=true
elseif type(value)=="table" then
local candidates={};for _,name in ipairs(value) do if type(name)=="string" and name~="" then candidates[#candidates+1]=name end end
if #candidates>0 then requested[key]=candidates end
end
end
if next(requested)==nil then return {ready=true,actions={},paths={},selective=true,nativeActions=0} end
local selective={}
for k,v in pairs(opts) do selective[k]=v end
selective.selectiveActions=true;selective.wantedActions=requested
return P.extractSpecies(mod,disc,dex,selective)
end
P._test=P._test or {}
P._test.recordManifest=recordManifest
P._test.manifestStats=function() local o={};for k,v in pairs(manifestStats)do o[k]=v end;return o end
P._test.resetManifestStats=function() manifestStats={reads=0,parses=0,memoHits=0,writes=0,serializedEntries=0};P.invalidateManifestMemo();return true end
P._test.actionPoseUsable=actionPoseUsable
P._test.decodeBest=decodeBest
P._test.packedVerticesLua=packedVerticesLua
P._test.normalizedVertexRow=normalizedVertexRow
P._test.emitRuntimeActionSidecar=emitRuntimeActionSidecar
P._test.eagerRuntimeActionAllowed=eagerRuntimeActionAllowed
P._test.cacheLua=cacheLua
P._test.write=write
P._test.selectiveActionRefLua=selectiveActionRefLua
P._test.commitSelectiveActions=commitSelectiveActions
P._test.actionPackVersion=ACTION_PACK_VERSION
P._test.actionPackGuardVersion=ACTION_PACK_GUARD_VERSION
P._test.actionPackedPayloadLua=actionPackedPayloadLua
P._test.textureSignature=signature
P._test.mergeGroups=mergeGroups
return P
