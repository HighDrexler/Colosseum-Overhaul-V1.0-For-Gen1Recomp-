-- Regression boundaries that diagnostic-only move renders previously missed:
-- live string move IDs, selective lane reach, and stale packed Waza sidecars.
local root=(arg and arg[0] or ''):gsub('tests[/\\]ArenaMoveFXIntegrationTests.lua$','')
if root=='' then root='./' end
local n=0
local function eq(a,b,msg)n=n+1;assert(a==b,(msg or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,msg)n=n+1;assert(math.abs(a-b)<1e-7,msg)end
local function copy(t)local c={};for k,v in pairs(t)do c[k]=type(v)=='table' and copy(v)or v end;return c end
local C=assert(loadfile(root..'lib/CurrentSpriteModels.lua'))({})
for _,p in ipairs{{53,23,70},{55,24,60},{61,22,65},{190,45,60}}do
 for _,phase in ipairs{'attack','sp1'}do
  eq(C._test.particleTransitSpan(p[1],'attack',{phase=phase,selector=p[2]}),p[3],'identified transit core')
 end
 eq(C._test.particleTransitSpan(p[1],'attack',{phase='attack',selector=p[2]+1}),100,'muzzle/other selector unchanged')
 eq(C._test.particleTransitSpan(p[1],'damage',{phase='attack',selector=p[2]}),100,'receiving role unchanged')
 eq(C._test.particleTransitSpan(p[1],'attack',{phase='damage',selector=p[2]}),100,'receiving bank unchanged')
 eq(C._test.particleTransitSpan(p[1],'attack',{phase='attack',selector=p[2],flags=1}),100,'linked source model owns its scale')
 eq(C._test.particleTransitSpan(p[1],'attack',nil),100,'not a particle entry')
end
eq(C._test.particleTransitSpan(57,'attack',{selector=23}),100,'Surf never stretched as fire')
eq(C._test.particleTransitSpan(58,'attack',{selector=23}),100,'beam model scale unchanged')
local sizes={};local V={CurrentSpriteModels=C,MoveFXExtractor={revision=33},GeneratedAssets={info=function(p)return sizes[p] and {size=sizes[p]}end}}
local H=assert(loadfile(root..'lib/WazaHandlers.lua'))(V)
local path='cache/movefx/057/wave.lua';local dir=H._test.runtimeRoot(path)
eq(dir,'cache/movefx/057/wave_runtime_v2_r33','schema+extractor isolation')
local meta={runtimeMeshVersion=2,sourcePath=path,sourceSize=1000,extractorRevision=33,morphFrames=12,
 groups={{vertexCount=3,runtimeBin=dir..'/base_01.f32'}}}
sizes[meta.groups[1].runtimeBin]=3*44*4
eq(H._test.runtimeUsable(meta,path,1000),true,'valid morph sidecar')
for _,mutation in ipairs{
 function(m)m.runtimeMeshVersion=1 end,function(m)m.sourcePath='other.lua'end,
 function(m)m.extractorRevision=30 end,function(m)m.sourceSize=999 end,
 function(m)m.sourceSize=nil end,function(m)m.groups[1].vertexCount=4 end,
 function(m)m.groups[1].vertexCount=2 end,function(m)m.groups[1].vertexCount=3.5 end,
 function(m)m.groups[1].vertexCount=nil end,function(m)m.groups={}end,
 function(m)m.groups[1].runtimeBin='cache/movefx/057/wave_runtime/base_01.f32'end,
 function(m)m.morphFrames=0 end
}do local m=copy(meta);mutation(m);eq(H._test.runtimeUsable(m,path,1000),false,'reject stale/invalid metadata')end
sizes[meta.groups[1].runtimeBin]=3*44*4-4;eq(H._test.runtimeUsable(meta,path,1000),false,'truncated stream')
sizes[meta.groups[1].runtimeBin]=nil;eq(H._test.runtimeUsable(meta,path,1000),false,'missing binary')
sizes[meta.groups[1].runtimeBin]=3*44*4
local static=copy(meta);static.morphFrames=0;sizes[static.groups[1].runtimeBin]=3*8*4
eq(H._test.runtimeUsable(static,path,1000),true,'valid static sidecar')
V.MoveFXExtractor.revision=34
eq(H._test.runtimeUsable(meta,path,1000),false,'extractor refresh never reuses previous schema')
eq(H._test.runtimeRoot(path),'cache/movefx/057/wave_runtime_v2_r34','new namespace after extraction')
-- Real live string move, selected numeric source record. Both must reach the
-- same field placement path as the primary source model (not Pokemon height).
local ctx={groundY=3,arena={player={0,-50},enemy={0,50}}}
C.stadiumActors={}
for _,side in ipairs{'player','enemy'}do local p=ctx.arena[side]
 local actor={height=2,worldScale=1};function actor:attachment()return {position={p[1],1,p[2]}}end
 C.stadiumActors[side]={actor=actor}
end
local partData='return {revision=1,endFrame=1,tracks={[2]={{1,0,0,0,0,1,0,0,0,0,1,0},{1,0,0,0,0,1,0,0,0,0,1,10}}}}'
V.GeneratedAssets.read=function(p)if p=='parts.lua'then return partData end end
local e={kind='particle',phase='attack',flags=1,linkedEntryKey=7,partIndex=2}
local model={kind='model',phase='attack',identifier=7,attachment=1,modelAsset={parts={path='parts.lua'}}}
local inst={role='attack',moveId='SURF',spec={moveId=57},side='player',target='enemy',frame=.5,entries={{started=true,startFrame=0,entry=model}}}
local live=assert(H.linkedParticleFrame(ctx,inst,e));inst.moveId=57
local diagnostic=assert(H.linkedParticleFrame(ctx,inst,e))
for _,axis in ipairs{'x','y','z'}do near(live.basis.sourceUnits[axis],diagnostic.basis.sourceUnits[axis],'string/numeric same source units')end
eq(live.basis.fieldWave,true,'source-record numeric ID selects field wave')
near(live.basis.origin[2],3,'foam shares arena floor not mouth')
print('ArenaMoveFXIntegrationTests: '..n..' assertions passed')
