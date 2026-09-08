local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end

local catalog=read("lib/ArenaCatalog.lua")
local builder=read("extract/ArenaBuilder.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")
local native=read("lib/NativeLauncherCompat.lua")
local probe=read("extract/FormatProbe.lua")
local cameraProbe=read("extract/CameraProbe.lua")
local arena=read("lib/Arena.lua")
local settings=read("lib/BattleSettings.lua")

local added={
  {id="relic_cave",label="RELIC CAVE",fsys="M3_cave_1F_1_bf.fsys",member="M3_cave_1F_1_bf.dat",cache="cache/M3_cave_1F_1_bf_cache.lua"},
  {id="outskirts",label="OUTSKIRTS",fsys="S1_out_bf.fsys",member="S1_out_bf.dat",cache="cache/S1_out_bf_cache.lua"},
  {id="pyrite_colosseum",label="PYRITE COLOSSEUM",fsys="M2_earth_colo.fsys",member="M2_earth_colo.dat",cache="cache/M2_earth_colo_cache.lua"},
  {id="deep_colosseum",label="DEEP COLOSSEUM",fsys="M4_bottom_colo.fsys",member="M4_bottom_colo.dat",cache="cache/M4_bottom_colo_cache.lua"},
}
for _,v in ipairs(added) do
  assert(catalog:find('id="'..v.id..'",label="'..v.label..'"',1,true),v.label.." missing from catalog")
  assert(catalog:find('{id="'..v.id..'",label="'..v.label..'"}',1,true),v.label.." missing from selector")
  assert(settings:find(v.id..'=true',1,true),v.label.." rejected by BattleSettings")
  assert(builder:find('sourceFsys="'..v.fsys..'"',1,true),v.label.." source FSYS missing")
  assert(builder:find('sourceMember="'..v.member..'"',1,true),v.label.." source DAT missing")
  assert(pipeline:find(v.cache,1,true),v.label.." missing from visual core")
  assert(cache:find(v.cache,1,true),v.label.." missing from cache inspector")
  assert(native:find('"'..v.fsys..'"',1,true),v.label.." missing from raw/CISO validation")
  assert(probe:find('"'..v.fsys..'"',1,true),v.label.." missing from source format probe")
  assert(cameraProbe:find('"'..v.fsys..'"',1,true),v.label.." missing from source camera probe")
end

-- Exact source material/render state is now carried through source cache and the
-- packed runtime sidecar instead of being flattened into CBE's old defaults.
assert(builder:find('return {version=33',1,true),"source arena cache format v33 missing")
for _,field in ipairs({"renderFlags=","effect=","useConstant=","useVertexColor=","useDiffuseLighting=","textureSlot="}) do
  assert(builder:find(field,1,true),"source material field missing: "..field)
end
assert(arena:find('sourceDiffuseLighting',1,true) and arena:find('sourceVertexColor',1,true),"runtime shader does not consume source material flags")
assert(arena:find('runtime_mesh_v7/arenas/',1,true) and builder:find('runtime_mesh_v7/arenas/',1,true),"arena packed sidecar schema v7 missing")
assert(pipeline:find('format=7',1,true),"arena sidecar marker was not advanced to format 7")
assert(pipeline:find('cbe%-arena=10'),"arena migration identity v10 missing")
assert(pipeline:find('source%-hsd%-scene%-v33'),"arena marker is not bound to source HSD v33")
assert(pipeline:find('arenasOnly=function',1,true),"arena-only migration missing")
assert(pipeline:find('local B={cacheVersion=2,extractorRevision=15}',1,true),"arena fidelity sweep unexpectedly invalidates global extraction cache")

-- Source atlases should not receive CBE's synthetic sharpening. Wildlands is
-- explicitly authored and remains the one intended detail-texture exception.
assert(arena:find('cache/stages/wildlands/ground_',1,true) and arena:find('cache/stages/wildlands/bark_',1,true),"runtime source texture sharpening isolation missing")
assert(builder:find('cache/stages/wildlands/ground_',1,true) and builder:find('cache/stages/wildlands/bark_',1,true),"sidecar source texture sharpening isolation missing")

-- New source-backed rooms get a neutral shader profile rather than inheriting
-- Realgam/Wildlands grading; venue-authored colors stay authoritative.
assert(arena:find('neutralSourceProfile = sceneProfile > 4.5',1,true),"neutral source arena shader profile missing")
assert(arena:find('sceneProfile > 3.5 && sceneProfile < 4.5',1,true),"Realgam shader profile is not isolated")

print("ArenaExpansionParityTests PASS")
return true
