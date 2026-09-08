local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local catalog=read("lib/ArenaCatalog.lua")
local arena=read("lib/Arena.lua")
local builder=read("extract/ArenaBuilder.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")
local relic=read("lib/RelicPresentation.lua")

-- RELIC CHAMBER LOCK: complete compensated source geometry. The apparent
-- overhangs were sheared source transforms, so corrected groups stay intact.
assert(catalog:find('sceneRadiusRaw=7800,maxGroupSpanRaw=20000,vertexRadiusRaw=7400',1,true),"Relic source envelope not locked")
assert(catalog:find('sourceShellOnly=true,worldShell="source"',1,true),"Relic complete source scene missing")
assert(catalog:find('shotRadiusScale=0.60,shotHeightScale=0.42',1,true),"Relic camera compression missing")
assert(catalog:find('maxRadius=36',1,true) and catalog:find('maxY=13.5',1,true),"Relic camera can still enter canopy volume")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true,nativeScaleCompensation=true',1,true),"Relic retail passes/native scale contract missing")
assert(not builder:find('rejectBattleOverhang',1,true),"Relic source groups are still deleted by the obsolete overhang heuristic")
assert(arena:find('Relic Chamber must read as an outdoor Agate forest from every azimuth',1,true),"Relic 360 sky/forest closure missing")
assert(arena:find('local topSky={.19,.42,.70};local midSky={.42,.61,.72};local horizon={.70,.80,.66}',1,true),"Relic sky is not an actual blue daylight sky")
assert(arena:find('if not (activeDef and activeDef.profile=="relic" and s) or activeDef.sourceShellOnly then return end',1,true),"complete Relic scene is still duplicated into rotated forest sectors")
assert(arena:find('if activeDef and activeDef.profile=="relic" and activeDef.sourceShellOnly then return false end',1,true),"corrected source scene still loses groups to AABB culling")
assert(relic:find('Hard rule: no leaf/branch card in front of the fight',1,true),"Relic foreground foliage hard rule missing")

-- Preserve the functional legacy guard for older/fallback presentations:
-- foreground cutout disappears from the battle
-- window, the same foliage behind the battlers remains, and architecture stays.
local R=assert(loadfile("lib/RelicPresentation.lua"))({})
local pose={eye={0,10,30},focus={0,5,0},fov=math.rad(40)}
local foregroundLeaf={center={0,25,44},extent={14,3,14},mode=3}
assert(R.shouldCull(foregroundLeaf,pose,.25,0,16/9)==true,"foreground Relic leaf survived")
local rearLeaf={center={0,30,-180},extent={90,6,55},mode=3}
assert(R.shouldCull(rearLeaf,pose,.25,0,16/9)==false,"rear Relic foliage was globally removed")
local wall={center={0,30,42},extent={130,100,12},mode=0}
assert(R.shouldCull(wall,pose,.25,0,16/9)==false,"Relic architecture was mistaken for foliage")

-- OUTSKIRTS LOCK: retain much more of S1_out_bf, reconcile the source pad and
-- continuation sand in the shader, keep the low source-like camera and sky, and
-- provide a subtle but actually visible blowing-sand layer.
assert(catalog:find('sceneRadiusRaw=16000,maxGroupSpanRaw=42000,vertexRadiusRaw=15000',1,true),"Outskirts source shell not deep enough")
assert(builder:find('outskirts={sceneRadiusRaw=16000,maxGroupSpanRaw=42000,vertexRadiusRaw=15000}',1,true),"Outskirts packed source shell not deep enough")
assert(builder:find('sourceFsys="S1_out_bf.fsys",sourceMember="S1_out_bf.dat"',1,true),"Outskirts not source-bound")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true',1,true),"Outskirts retail render-pass filtering missing")
assert(catalog:find('shotRadiusScale=0.82,shotHeightScale=0.62',1,true) and catalog:find('height=13.5',1,true),"Outskirts opening-battle camera framing regressed")
assert(arena:find('S1_out_bf uses a pale tiled battle pad inside the same sun-baked desert',1,true),"Outskirts floor reconciliation missing")
assert(arena:find('vec3 unifiedSand=vec3(.870,.805,.635)',1,true) and arena:find('floorMask*.78',1,true),"Outskirts source tile/far-desert palette lock missing")
assert(arena:find('local radii={360,1050,2800,6500,12800}',1,true),"Outskirts world continuation depth missing")
assert(arena:find('Opening-story Outskirts: bright cobalt Orre sky',1,true),"Outskirts source-like sky contract missing")
assert(arena:find('Broad, soft cloud banks match the first-battle footage',1,true),"Outskirts cloud bank missing")
assert(arena:find('low, continuous desert mesa/plateau',1,true),"Outskirts distant mesas missing")
assert(arena:find('for i=1,30 do',1,true) and arena:find('A handful of tiny grains make the drift read as sand rather than haze',1,true),"Outskirts sand drift too weak/missing")
assert(arena:find('love.graphics.setColor(.97,.89,.70,.018)',1,true),"Outskirts light dust veil missing")

-- The 1.9.27 Relic/Outskirts contracts remain intact. 1.9.30 has a newer
-- Deep-only arena migration; expensive unrelated caches must still stay valid.
assert(arena:find('runtime_mesh_v7/arenas/',1,true) and builder:find('runtime_mesh_v7/arenas/',1,true),"arena runtime sidecar v7 missing")
assert(pipeline:find('format=7',1,true) and cache:find('format=7',1,true),"arena runtime sidecar format 7 marker missing")
assert(builder:find('complete and "all-source-colors" or "full"',1,true),"current targeted arena migration missing")
assert(builder:find('if arena.sourceFsys then',1,true),"arena refresh must be isolated to source arenas")
assert(pipeline:find('cbe%-arena=10'),"canonical arena family unexpectedly changed")
assert(pipeline:find('local B={cacheVersion=2,extractorRevision=15}',1,true),"global extraction revision changed")
-- Pyrite safety remains intact while these two venues are rebuilt.
assert(catalog:find('shotRadiusScale=0.72',1,true) and catalog:find('maxRadius=43',1,true),"Pyrite camera regression")

print("RelicOutskirtsLock1927Tests PASS")
return true
