local H=assert(loadfile('tests/support/ShinyHarness.lua'))()
local checks=0
local function yes(x,k) checks=checks+1;assert(x,k) end
local h=H.new({disk=true})
local initial=h.A.sessionCacheIdentity()
for dex=1,251 do
  for _,variant in ipairs{'normal','shiny'} do
    local ok,err=h.A.prepareSessionModel(dex,variant)
    yes(ok,'preparation '..dex..' '..variant..': '..tostring(err))
    yes(h.A.peek('selected',dex,variant).resident,'exact variant resident')
    local actor,why=h.A.acquireCached('selected',dex,variant,{context={services={informationSurface=true}}})
    yes(actor and actor.variant==variant,'actor identity '..tostring(why))
    if variant=='shiny' and not h.Dex.rare[dex] then yes(actor.shinyFilter~=nil,'source shiny colour parameters') end
    actor:release()
  end
end
local extracts=#h.extracts
local writes=0;for _,count in pairs(h.writes) do writes=writes+count end
yes(extracts==270,'502 appearances use exactly 270 source units')
yes(h.A.sessionResidentCount()==270,'all desktop base scenes shared/pinned')
h.source=false
for dex=1,251 do
  yes(h.A.prepareSessionModel(dex,'normal'),'normal warm reuse without source')
  yes(h.A.prepareSessionModel(dex,'shiny'),'shiny warm reuse without source')
end
local after=0;for _,count in pairs(h.writes) do after=after+count end
yes(after==writes and #h.extracts==extracts,'warm resident pass performs no writes/extraction')
h.A.trimRuntimeMemory({keepParty=0,keepRecent=0,softLimit=3})
yes(h.A.sessionResidentCount()==270,'ordinary battle/menu trim cannot purge session bases')
local retained=assert(h.A.acquireCached('selected',25,'normal',{}));local scene=retained.scene;retained:release()
local tex={released=false,release=function(self)self.released=true end}
local mesh={released=false,release=function(self)self.released=true end}
scene.textures=scene.textures or {};scene.textures['action-shared-fixture']=tex
scene.actions={idle={groups={{mesh=mesh,image=tex}}}}
h.A.trimRuntimeMemory({keepParty=0,keepRecent=0,softLimit=3})
yes(mesh.released and not tex.released,'trim releases action mesh but not still-indexed shared scene texture')
yes(next(scene.actions)==nil,'unpinned animation banks dropped without dropping base')
h.A.resetRuntime();yes(h.A.sessionResidentCount()==0,'explicit reset unpins scenes')
yes(h.A.sessionCacheIdentity()~=initial,'reset invalidates completion identity')
-- Persistent cache survives restart; both shared-filter and separate shiny use it.
local h2=H.new({disk=true,files=h.files});h2.source=false
for _,dex in ipairs{25,58,100,156,246,6,157} do
 for _,variant in ipairs{'normal','shiny'}do yes(h2.A.prepareSessionModel(dex,variant),'disk-only restart reuse '..dex..'/'..variant)end
end
yes(#h2.extracts==0 and #h2.metadataReads==0,'restart does not reopen source for prepared units')
-- A corrupt or missing colour recipe must be repaired, never accepted as normal.
local fail=H.new({disk=true});fail.putModel(25);fail.putMetadata(25,nil)
fail.failWrite='cache/pokemon/25/metadata_v1.lua'
local ok,why=fail.A.prepareSessionModel(25,'normal');yes(not ok and why,'normal prep also refuses an unpersisted shiny recipe')
fail.failWrite=nil;yes(fail.A.prepareSessionModel(25,'normal'),'retry repairs metadata')
yes(fail.A.prepareSessionModel(25,'shiny'),'repaired shiny appearance ready')
-- Transient scene failure is recoverable in the same process.
local retry=H.new({disk=true});retry.putModel(25);retry.putMetadata(25,retry.filter)
local old=love.graphics.newMesh;love.graphics.newMesh=function()error('transient GPU fixture fault')end
local fine=pcall(retry.A.prepareSessionModel,25,'normal');love.graphics.newMesh=old
local a,b=retry.A.prepareSessionModel(25,'normal');yes(a,'retry scene after transient GPU error: '..tostring(b))
local mobile=H.new({disk=true,os='Android'})
for dex=1,30 do yes(mobile.A.prepareSessionModel(dex,'shiny'),'mobile shiny preparation') end
yes(mobile.A.sessionResidentCount()<=12,'mobile base residency bounded')
yes(mobile.A.prepareSessionModel(1,'shiny'),'evicted model reloads exact colour from cache')
print('SessionModelCacheTests: '..checks..' checks PASS; real cache/actor code, synthetic source and graphics')
