local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local arena=read("lib/Arena.lua")
local catalog=read("lib/ArenaCatalog.lua")
local builder=read("extract/ArenaBuilder.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")

-- Relic Chamber: trust the full retail source shell after native HSD render-pass
-- filtering instead of fabricating a forest around a clipped stage.
assert(catalog:find('sourceShellOnly=true,worldShell="source"',1,true),"Relic complete source scene missing")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true,nativeScaleCompensation=true',1,true),"Relic native scale compensation missing")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true',1,true),"Relic retail render-pass filtering missing")
assert(catalog:find('shotRadiusScale=0.60',1,true),"Relic camera radial contract missing")
assert(catalog:find('shotHeightScale=0.42',1,true),"Relic camera height contract missing")
assert(catalog:find('maxRadius=36',1,true) and catalog:find('maxY=13.5',1,true),"Relic source-shell camera volume missing")
assert(catalog:find('minFocusY=4.5,maxFocusY=6.3',1,true),"Relic focus band missing")
assert(not catalog:find('cameraOccluderTrim=true',1,true),"legacy centre-ray Relic trim should stay disabled")
assert(arena:find('if activeDef and activeDef.profile=="relic" and activeDef.sourceShellOnly then return false end',1,true),"complete Relic scene still passes through legacy projected-view culling")
assert(arena:find('local function cameraOccluder',1,true),"shared arena occluder helper unexpectedly removed")

-- Outskirts: retain a much larger slice of the canonical S1_out_bf source in
-- the packed runtime and continue the finite battlefield into a desert skirt.
assert(catalog:find('sceneRadiusRaw=16000,maxGroupSpanRaw=42000,vertexRadiusRaw=15000',1,true),"Outskirts expanded source envelope missing")
assert(builder:find('outskirts={sceneRadiusRaw=16000,maxGroupSpanRaw=42000,vertexRadiusRaw=15000}',1,true),"Outskirts runtime sidecar still clips the far source shell")
assert(arena:find('local function ensureOutskirtsFarField()',1,true),"Outskirts desert continuation mesh missing")
assert(arena:find('local radii={360,1050,2800,6500,12800}',1,true),"Outskirts desert continuation lacks depth bands")
assert(arena:find('profile=="outskirts"',1,true),"Outskirts dedicated backdrop missing")
assert(arena:find('bright cobalt Orre sky',1,true),"Outskirts warm desert sky contract missing")
assert(arena:find('low, continuous desert mesa/plateau',1,true),"Outskirts far plateau silhouette missing")
assert(arena:find('local function drawOutskirtsSandDrift',1,true),"Outskirts light sand drift missing")
assert(arena:find('vec3(.91,.82,.62)',1,true),"Outskirts far-field palette is still too dark/mustard")

-- This visual repair only requires the packed arena cache to be rebuilt from
-- the already-generated canonical Lua. Do not force the disc, trainers, audio
-- or MoveFX through another extraction cycle.
assert(arena:find('runtime_mesh_v7/arenas/',1,true) and builder:find('runtime_mesh_v7/arenas/',1,true),"arena packed runtime schema v7 missing")
assert(pipeline:find('format=7',1,true) and cache:find('format=7',1,true),"arena sidecar v7 migration marker missing")
assert(pipeline:find('cbe%-arena=10'),"canonical arena identity unexpectedly changed")
assert(pipeline:find('local B={cacheVersion=2,extractorRevision=15}',1,true),"global extraction revision unexpectedly changed")
assert(pipeline:find('return sidecarsOnly(mod,progress)',1,true),"sidecar-only upgrade path missing")

-- Pyrite fix from 1.9.21 must remain intact in this combined build.
assert(catalog:find('shotRadiusScale=0.72',1,true) and catalog:find('maxRadius=43',1,true),"Pyrite lower-bowl camera fix regressed")

print("RelicOutskirtsPresentationTests PASS")
return true
