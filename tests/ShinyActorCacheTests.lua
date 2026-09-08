local H=assert(loadfile('tests/support/ShinyHarness.lua'))()
local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local h=H.new();h.putModel(25);h.putMetadata(25,h.filter);h.putModel(6);h.putMetadata(6,h.filter)
local normal=assert(h.A.acquire('selected',25,'normal',h.opts({species='TEST'},true)))
local shiny=assert(h.A.acquire('selected',25,'shiny',h.opts({species='TEST',shiny=true},true)))
yes(normal.scene==shiny.scene,'filter variants reuse same body');yes(normal~=shiny,'actor-local palette state')
yes(shiny.shinyFilter and not normal.shinyFilter,'normal remains native')
yes(h.meshes==1,'no duplicate mesh for native filter');yes(#h.extracts==0 and #h.metadataReads==0,'valid cache never reopens source')
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
for _,actor in ipairs{shiny,normal,shiny,normal}do
 yes(actor:draw(matrix),'actor draws');yes(h.shader.uniforms.shinyEnabled[1]==(actor==shiny and 1 or 0),'shader reset per actor')
 if actor==shiny then yes(h.shader.uniforms.shinyRouteR[1][3]==1,'native route uniform')else yes(h.shader.uniforms.shinyRouteR[1][1]==1,'normal identity uniform')end
end
yes(not h.pixelShader:find('hueShift',1,true),'no generic recoloring remains')
local rareN=assert(h.A.acquire('selected',6,'normal',h.opts({species='RARE'},true)))
local rareS=assert(h.A.acquire('selected',6,'shiny',h.opts({species='RARE',shiny=true},true)))
yes(rareN.scene~=rareS.scene,'separate source bodies');yes(rareS.cacheKey=='6:shiny' and rareS.dex==6,'numeric dex plus variant cache key')
yes(rareS.scene.dex=='6:shiny','lazy action paths preserve variant key');yes(not rareS.shinyFilter,'do not filter rare texture twice')
yes(h.files['cache/pokemon/6/shiny/model_cache.lua']~=nil,'rare model persisted separately')
yes(h.files['cache/pokemon/6/model_cache.lua']~=nil,'normal cache not overwritten')
yes(#h.extracts==1 and h.extracts[1].variant=='shiny','runtime requests shiny source')
local count=h.meshes
for i=1,1000 do yes(h.A.peek('selected',6,'shiny').resident,'RAM variant probe')end
yes(h.meshes==count,'peek does not upload')
-- Existing cached normal model without native recipe gets only a small metadata upgrade.
local old=H.new();old.putModel(25);old.putMetadata(25,nil);local initial=old.files['cache/pokemon/25/model_cache.lua']
local m=assert(old.A.acquire('selected',25,'shiny',old.opts({species='TEST',shiny=true},true)))
yes(m.shinyFilter~=nil,'old sidecar upgraded for menu');yes(#old.metadataReads==1 and #old.extracts==0,'metadata-only source read')
yes(old.files['cache/pokemon/25/model_cache.lua']==initial,'old body cache byte-identical')
local resumed=old.newActors();old.source=false
local r=assert(resumed.acquire('selected',25,'shiny',old.opts({species='TEST',shiny=true},true)))
yes(r.shinyFilter~=nil and #old.metadataReads==1,'relaunch uses persisted recipe offline')
-- A missing source cannot turn shiny into normal. A later recovered source retries.
local missing=H.new();missing.putModel(25);missing.putMetadata(25,nil);missing.source=false
local a,why=missing.A.acquire('selected',25,'shiny',missing.opts({species='TEST',shiny=true},true))
yes(a==nil and why:find('not substituted',1,true),'missing recipe fails open, not normal')
missing.source=true;yes(missing.A.acquire('selected',25,'shiny',missing.opts({species='TEST',shiny=true},true)),'metadata retry after source recovery')
local retry=H.new();retry.extractFail='simulated source error'
yes(not retry.A.acquire('selected',6,'shiny',retry.opts({species='RARE',shiny=true},true)),'failed rare extraction')
retry.extractFail=nil;yes(not retry.A.acquire('selected',6,'shiny',retry.opts({species='RARE',shiny=true},true)),'retry throttled')
retry.clock=3;yes(retry.A.acquire('selected',6,'shiny',retry.opts({species='RARE',shiny=true},true)),'failed cache not poisoned for whole session')
-- An acquired variant must remain pinned while another model is warmed/trimmed.
h.A.trimRuntimeMemory({keepParty=0,keepRecent=0});yes(h.A.peek('selected',6,'shiny').resident,'live shiny scene pinned')
print('ShinyActorCacheTests: '..checks..' checks passed; GPU objects are mocks')
