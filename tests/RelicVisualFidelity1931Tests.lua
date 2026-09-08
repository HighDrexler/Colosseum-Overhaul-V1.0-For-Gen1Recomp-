local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local arena=read("lib/Arena.lua")
local catalog=read("lib/ArenaCatalog.lua")
local builder=read("extract/ArenaBuilder.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")
local main=read("main.lua")

local currentVersion=assert(read('manifest.json'):match('"version"%s*:%s*"([^"]+)"'))
assert(main:find(currentVersion,1,true),"1.9.31 build id missing")
assert(builder:find('local A={arenaRevision=16}',1,true),"Relic visual refresh revision missing")
assert(builder:find('relic_chamber={sceneRadiusRaw=7800,maxGroupSpanRaw=20000,vertexRadiusRaw=7400}',1,true),"Relic packed source envelope not widened")
assert(catalog:find('sceneRadiusRaw=7800,maxGroupSpanRaw=20000,vertexRadiusRaw=7400',1,true),"Relic runtime envelope not widened")
assert(builder:find('if arena.sourceFsys then',1,true),"complete-install migration must include every source arena")
assert(builder:find('complete and "all-source-colors" or "full"',1,true),"all-source arena repair report missing")
assert(pipeline:find('Refreshing source arena fidelity: native texture transforms, material colors and scene instances',1,true),"source arena migration message missing")

assert(catalog:find('sourceShellOnly=true,worldShell="source"',1,true),"Relic scene still uses rotated source sectors or procedural ground")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true,nativeScaleCompensation=true',1,true),"Relic native joint compensation missing")
assert(not builder:find('rejectBattleOverhang',1,true),"Relic extraction still removes authored geometry")
assert(arena:find('Native HSD unlit color selection is exclusive',1,true),"source unlit material colors still receive synthetic venue grading")
assert(arena:find('relicProfile ? 300.0',1,true) and arena:find('relicProfile ? 760.0',1,true),"Relic clarity fog range missing")
assert(arena:find('relicProfile ? .070',1,true),"Relic fog strength not reduced")
assert(not arena:find('for _,delta in ipairs({math.pi*2/3,math.pi*4/3}) do',1,true),"narrow repeated shell still present")

assert(pipeline:find('relic-chamber=retail-source-complete+native-scale-compensation+source-material-color+cave-scale-compensation-v5',1,true),"pipeline Relic marker not advanced")
assert(cache:find('relic-chamber=retail-source-complete+native-scale-compensation+source-material-color+cave-scale-compensation-v5',1,true),"cache Relic marker not advanced")
assert(read("extract/PokemonExtractor.lua"):find('local P={revision=37}',1,true),"battle animation rollback regressed")

-- Exercise the actual extraction boundary: Relic must request parent-scale
-- compensation and retain every source group, including broad forest groups
-- that the obsolete overhang heuristic used to delete wholesale.
local function up(fn,name,value,set)
  for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
    if n==name then if set then debug.setupvalue(fn,i,value) end;return v end
  end
  error('missing upvalue '..name)
end
local files={}
local V={FSYS={open=function()return {
  member=function()return {modelKind=true,name='M3_shrine_1F_bf.dat'}end,
  extract=function()return 'source fixture'end,
}end}}
V.HSD={extractSceneModel=function(blob,options)
  assert(blob=='source fixture' and options.nativeScaleCompensation==true,'source transforms were not compensated')
  assert(options.groupFilter==nil,'Relic source still uses a bounds-based deletion filter')
  assert(options.honorRenderPass and options.skipShadowMaterials,'native render-pass semantics lost')
  local groups={}
  for i=1,3 do groups[i]={vertices={{-200,i,100,0,0},{200,i,100,1,0},{0,i,-200,0,1}}}end
  return {groups=groups,vertexCount=9,sceneRoots=1,bounds={min={-200,0,-200},max={200,3,100},center={0,1.5,-50}}}
end}
local B=assert(loadfile('extract/ArenaBuilder.lua'))(V)
local spec
for _,s in ipairs(B._test.arenas)do if s.id=='relic_chamber'then spec={};for k,v in pairs(s)do spec[k]=v end end end
assert(spec and spec.nativeScaleCompensation==true)
spec.minVertices=1;spec.minGroups=1
local mod={cache={write=function(_,path,bytes)files[path]=bytes;return true end}}
local r=B._test.buildSourceArena(mod,{file=function()return {path=spec.sourceFsys}end},function()end,{},spec)
local stored=assert(load(files[spec.cache]))()
assert(r.groups==3 and #stored.groups==3,'source groups disappeared during cache serialization')

-- Run the shipped draw helpers for four azimuths. Complete source scenes must
-- submit each group once, with no rotated duplicates/procedural ground and no
-- legacy group-AABB trimming. The legacy guard's standalone tests remain.
local savedLove=love;local drawn={};local uniforms={}
love={graphics={draw=function(mesh)drawn[mesh]=(drawn[mesh] or 0)+1 end}}
local R=assert(loadfile('lib/Arena.lua'))({RelicPresentation={shouldCull=function()error('legacy culler called for compensated source')end}})
local drawGroups=up(R.render,'drawGroups')
local cameraOccluder=up(drawGroups,'cameraOccluder')
up(cameraOccluder,'activeDef',{profile='relic',sourceShellOnly=true,presentationOccluderTrim=true},true)
local drawGroup=up(drawGroups,'drawGroup')
up(drawGroup,'sendShader',function(name,value)uniforms[name]=value end,true)
local farField=up(R.render,'drawRelicFarField')
local cloneShell=up(R.render,'drawRelicSourceForestShell')
local groups={
  {mesh={},center={0,72,-10},extent={180,18,110},mode=0,useDiffuseLighting=false},
  {mesh={},center={0,25,44},extent={14,3,14},mode=3,useDiffuseLighting=false},
  {mesh={},center={0,30,-180},extent={90,6,55},mode=3,useDiffuseLighting=false},
}
for _,eye in ipairs({{0,10,30},{30,10,0},{0,10,-30},{-30,10,0}})do
  local pose={eye=eye,focus={0,5,0},fov=math.rad(40)}
  farField();cloneShell({opaque=groups,cutout={}},nil,nil,pose)
  drawGroups(groups,pose)
end
for _,g in ipairs(groups)do assert(drawn[g.mesh]==4,'source geometry was culled or duplicated across battle views')end
assert(uniforms.sourceDiffuseLighting==0,'native unlit source material became procedurally lit')
love=savedLove

print("RelicVisualFidelity1931Tests PASS")
return true
