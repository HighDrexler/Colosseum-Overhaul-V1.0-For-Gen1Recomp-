local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local arena=read("lib/Arena.lua")
local catalog=read("lib/ArenaCatalog.lua")
local cache=read("lib/CacheManager.lua")

-- 1.9.31 supersedes the narrow repeated 120-degree shell. The missing
-- hemisphere is filled from one coherent 180-degree retail source half, while
-- only low source ground/root/rock/understory groups are reused at quarter turns.
assert(arena:find('local relicForestSectorCache=setmetatable',1,true),"source forest sector cache missing")
assert(arena:find('Use one coherent HALF of the retail forest',1,true),"180-degree source-half selection missing")
assert(arena:find('local windowBins=8',1,true),"source-half window width missing")
assert(arena:find('local copyModel=Mat4.mul(Mat4.rotateY(math.pi),baseModel)',1,true),"opposite-hemisphere source replication missing")
assert(arena:find('sector.detailGroups',1,true) and arena:find('for _,delta in ipairs({math.pi*.5,math.pi*1.5}) do',1,true),"source understory density pass missing")
assert(not arena:find('local relicForestMotifCache=setmetatable',1,true),"old isolated motif forest remains")
assert(not arena:find('for _,delta in ipairs({math.pi*2/3,math.pi*4/3}) do',1,true),"old repeated 120-degree shell remains")
assert(arena:find('drawRelicSourceForestShell(s,vp,model,pose)',1,true),"source forest shell not rendered")
assert(arena:find('screen-space backdrop is sky only',1,true),"legacy fake screen-space treeline still authoritative")

-- Relic keeps the real source scene and established clean-camera contract.
assert(catalog:find('cache="cache/M3_shrine_1F_bf_cache.lua"',1,true),"Relic source cache changed")
assert(catalog:find('maxRadius=36',1,true),"Relic clean camera volume regressed")
assert(arena:find('local topSky={.19,.42,.70};local midSky={.42,.61,.72};local horizon={.70,.80,.66}',1,true),"daylight sky fidelity update missing")
assert(cache:find('relic_chamber=GC6E01/M3_shrine_1F_bf.fsys/M3_shrine_1F_bf.dat/source%-hsd%-scene%-v33'),"Relic canonical source identity changed")

print("RelicForest360Fidelity1928Tests PASS")
return true
