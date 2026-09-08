local H=assert(loadfile('tests/support/ShinyHarness.lua'))();local h=H.new({disk=true})
local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
h.putModel(25);h.putMetadata(25,nil);h.putModel(6);h.putMetadata(6,h.filter)
h.game.save.boxes={{{species='TEST'},{species='TEST',shiny=true},{species='RARE'},{species='RARE',shiny=true},
 {species='RARE',shiny=true}}}
yes(h.A.queueHardCache(h.game)==3,'share nonrare body, separate rare body, deduplicate duplicates')
local source25=h.files['cache/pokemon/25/model_cache.lua'];local source6=h.files['cache/pokemon/6/model_cache.lua']
for i=1,100 do local out=h.A.pumpHardCache(h.game,10);if not out.running then break end end
local status=h.A.hardCacheStatus()
yes(status.done==3 and status.failed==0 and not status.running,'all variants hard-cached')
yes(h.meshes==0 and h.images==0,'hard cache creates no Pokemon GPU meshes/textures')
yes(h.files['cache/pokemon/25/model_cache.lua']==source25,'nonrare normal cache unchanged')
yes(h.files['cache/pokemon/6/model_cache.lua']==source6,'rare normal cache unchanged')
local bytes=h.files['cache/pokemon/6/shiny/runtime_mesh_v1/base_01.f32']
yes(type(bytes)=='string' and #bytes==3*44*4,'rare binary cache complete')
yes(h.files['cache/pokemon/25/runtime_mesh_v1/base_01.f32']==bytes,'fixture geometry bytes same, paths distinct')
local meta=assert(load(h.files['cache/pokemon/25/metadata_v1.lua']))()
yes(h.Shiny.validFilter(meta.shinyFilter),'boxed shiny recipe persisted')
yes(#h.extracts==1 and h.extracts[1].variant=='shiny','only missing rare geometry extracted')
local writesBefore=h.writes['cache/pokemon/6/shiny/runtime_mesh_v1/base_01.f32']
yes(h.A.queueHardCache(h.game)==3,'repeat hard-cache queue valid')
for i=1,100 do if not h.A.pumpHardCache(h.game,10).running then break end end
yes(h.A.hardCacheStatus().failed==0,'repeat hard cache complete')
yes(#h.extracts==1,'no re-extraction on repeated hard-cache pass')
yes(h.writes['cache/pokemon/6/shiny/runtime_mesh_v1/base_01.f32']==writesBefore,'valid sidecar not rewritten')
-- Bad writes cannot mark a shiny ready.
local fail=H.new({disk=true});fail.putModel(25);fail.putMetadata(25,nil);fail.failWrite='cache/pokemon/25/metadata_v1.lua'
fail.game.save.boxes={{{species='TEST',shiny=true}}};fail.A.queueHardCache(fail.game)
for i=1,100 do if not fail.A.pumpHardCache(fail.game,10).running then break end end
yes(fail.A.hardCacheStatus().failed==1,'missing shiny sidecar write reports failure')
fail.failWrite=nil;fail.A.queueHardCache(fail.game)
for i=1,100 do if not fail.A.pumpHardCache(fail.game,10).running then break end end
yes(fail.A.hardCacheStatus().done==1 and fail.A.hardCacheStatus().failed==0,'retry repairs only missing metadata')
local paths={['build/hard_cache_v4.complete']='legacy-ready'}
local C=assert(loadfile('lib/CacheManager.lua'))({mod={},GeneratedAssets={exists=function(path)return paths[path]~=nil end}})
yes(C.hardCacheStatus().ready==false and C.hardCacheStatus().needsShinyRefresh,'legacy completion is not shiny-ready')
paths['build/hard_cache_v5.complete']='new-ready';yes(C.hardCacheStatus().ready==true,'new shiny completion is ready')
print('ShinyHardCacheTests: '..checks..' checks passed; synthetic geometry, real binary pack/cache pipeline')
