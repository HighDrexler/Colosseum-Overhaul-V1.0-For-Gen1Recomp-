local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local px=read("extract/PokemonExtractor.lua")
local actors=read("lib/PokemonActors.lua")
local cache=read("lib/CacheManager.lua")
local prewarm=read("lib/ResidentPrewarm.lua")
assert(px:find('local P={revision=37}',1,true),"Pokemon extractor revision 37 missing")
assert(not px:find('repairIdleIsolatedGroups',1,true),"global idle pose repair regression still present")
assert(px:find('local P={revision=37}',1,true) and px:find('denseActionIntervals=denseReactionIntervals',1,true),"source action extractor contract missing")
assert(actors:find('Continuous source-pose playback',1,true),"continuous source-pose runtime missing")
assert(actors:find('BURROWED_GROUND_DEPTH',1,true),"targeted Diglett/Dugtrio placement fix lost")
assert(cache:find('build/hard_cache_v4.complete',1,true),"Hard Cache v4 migration marker missing")
assert(prewarm:find('pokemon-extractor=37',1,true),"Hard Cache v4 does not bind Pokemon extractor 37")
print("BattleAnimationRegression1929Tests PASS")
return true
