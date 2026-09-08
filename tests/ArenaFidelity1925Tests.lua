local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local catalog=read("lib/ArenaCatalog.lua")
local arena=read("lib/Arena.lua")
local builder=read("extract/ArenaBuilder.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")
local relic=read("lib/RelicPresentation.lua")

-- Relic Chamber is source-first again. The canonical M3_shrine_1F_bf scene
-- is re-extracted with the native HSD render-pass contract, then retained with
-- a much wider shell. Synthetic tree rows/ground islands are deliberately OFF.
assert(catalog:find('sourceShellOnly=true,worldShell="source"',1,true),"Relic must use its complete compensated source scene")
assert(builder:find('nativeScaleCompensation=spec.nativeScaleCompensation==true',1,true),"Relic native joint scales are not passed to extraction")
assert(not catalog:find('worldShell="forest"',1,true),"legacy procedural Relic forest shell still enabled")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true',1,true),"Relic native render-pass extraction contract missing")
assert(builder:find('relic_chamber={sceneRadiusRaw=7800,maxGroupSpanRaw=20000,vertexRadiusRaw=7400}',1,true),"Relic packed source shell still clipped")
assert(catalog:find('sceneRadiusRaw=7800,maxGroupSpanRaw=20000,vertexRadiusRaw=7400',1,true),"Relic catalog source shell still clipped")
assert(relic:find('local overheadArtifact=',1,true),"Relic overhanging carrier fallback classification missing")
assert(relic:find('if overheadArtifact and visibleArea>.015',1,true),"Relic overhang view rejection fallback missing")

-- Outskirts should resemble the opening Colosseum battle, not a finite stage.
assert(catalog:find('sceneRadiusRaw=16000,maxGroupSpanRaw=42000,vertexRadiusRaw=15000',1,true),"Outskirts source shell still clipped")
assert(builder:find('outskirts={sceneRadiusRaw=16000,maxGroupSpanRaw=42000,vertexRadiusRaw=15000}',1,true),"Outskirts packed shell still clipped")
assert(catalog:find('shotRadiusScale=0.82,shotHeightScale=0.62',1,true),"Outskirts retail-style camera compression missing")
assert(catalog:find('height=13.5',1,true) and catalog:find('maxY=21',1,true),"Outskirts camera remains too high")
assert(arena:find('local radii={360,1050,2800,6500,12800}',1,true),"Outskirts far desert is not deep enough")
assert(arena:find('Broad, soft cloud banks match the first-battle footage',1,true),"Outskirts source-like cloud deck missing")
assert(arena:find('Distant Orre plateau',1,true) or arena:find('low, continuous desert mesa',1,true),"Outskirts distant mesa missing")
assert(arena:find('profile=="outskirts" and 7',1,true),"Outskirts dedicated shader profile missing")

-- Deep Colosseum needs the enormous source shell and low architectural framing.
assert(catalog:find('sceneRadiusRaw=12000,maxGroupSpanRaw=32000,vertexRadiusRaw=11500',1,true),"Deep source shell still clipped")
assert(builder:find('deep_colosseum={sceneRadiusRaw=12000,maxGroupSpanRaw=32000,vertexRadiusRaw=11500}',1,true),"Deep packed shell still clipped")
assert(catalog:find('figureScale=0.300',1,true),"Deep actor scale is not source-proportional")
assert(catalog:find('height=12.2',1,true) and catalog:find('maxRadius=66',1,true),"Deep camera is not constrained to the source floor envelope")
assert(arena:find('(profile=="deep" or profile=="cipher_lab") and 9',1,true),"Deep dedicated shader profile missing")
assert(arena:find('1.9.25 double-darkened it',1,true),"Deep source-neutral lighting treatment missing")
assert(arena:find('outskirtsProfile ? 420.0',1,true) and arena:find('deepProfile ? 620.0',1,true),"venue-specific source depth fog missing")

-- This is intentionally a packed-runtime fidelity migration. The expensive
-- canonical disc/audio/trainer/MoveFX identities stay valid.
assert(arena:find('runtime_mesh_v7/arenas/',1,true) and builder:find('runtime_mesh_v7/arenas/',1,true),"arena sidecar v7 missing")
assert(pipeline:find('format=7',1,true) and cache:find('format=7',1,true),"arena sidecar v7 marker missing")
assert(pipeline:find('cbe%-arena=10'),"canonical arena identity changed unexpectedly")
assert(pipeline:find('local B={cacheVersion=2,extractorRevision=15}',1,true),"global extraction revision changed unexpectedly")

-- Functional overhang regression: a huge opaque elevated slab crossing the
-- upper view must be presentation-trimmed, while an ordinary vertical wall stays.
local R=assert(loadfile("lib/RelicPresentation.lua"))({})
local pose={eye={0,10,30},focus={0,5,0},fov=math.rad(40)}
local overhang={center={0,72,-10},extent={180,18,110},mode=0}
assert(R.shouldCull(overhang,pose,.25,0,16/9)==true,"Relic overhanging slab survived")
local wall={center={0,40,-20},extent={120,140,16},mode=0}
assert(R.shouldCull(wall,pose,.25,0,16/9)==false,"ordinary Relic wall was over-culled")

print("ArenaFidelity1925Tests PASS")
return true
