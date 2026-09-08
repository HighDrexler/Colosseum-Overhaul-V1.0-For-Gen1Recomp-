local H=assert(loadfile('tests/support/ShinyHarness.lua'))()
local h=H.new({disk=true,os='Android'})
local checks=0
local function yes(v,s)checks=checks+1;assert(v,s)end
local function total(t)local n=0;for _,v in pairs(t)do n=n+v end;return n end
yes(not h.A.sessionModelReady(25,'normal'),'unprepared identity not ready')
yes(h.A.prepareSessionModel(25,'normal'),'normal ready')
yes(h.A.sessionModelReady(25,'normal'),'session completion exposed')
yes(h.A.sessionModelReady(25,'shiny'),'source colour metadata certifies shared shiny body')
yes(not h.A.sessionModelReady(6,'shiny'),'distinct rare shiny source not inferred')
local reads,writes,extracts=total(h.reads),total(h.writes),#h.extracts
for _=1,1000 do yes(h.A.sessionModelReady(25,'normal'),'warm frame ready');yes(h.A.sessionModelReady(25,'shiny'),'warm shiny ready')end
yes(total(h.reads)==reads and total(h.writes)==writes and #h.extracts==extracts,'2000 readiness probes cause zero cache reads/writes/extractions')
h.A.trimRuntimeMemory({keepParty=0,keepRecent=0,softLimit=0})
-- The runtime may enforce a minimum retention limit. An explicit reset always
-- changes the epoch and must revoke all previous completion/residency claims.
h.A.resetRuntime();yes(not h.A.sessionModelReady(25,'normal'),'reset revokes readiness')
h.source=false;yes(h.A.prepareSessionModel(25,'shiny'),'disk-only reload after reset')
yes(#h.extracts==extracts,'reload does not re-extract')
-- A real texture-bearing fixture still validates exact payload size, but only
-- the GPU loader reads the payload. Validation must not allocate a second copy.
local t=H.new({disk=true})
local path='cache/pokemon/test-texture.rgba'
t.template.groups[1].texture={path=path,w=2,h=2}
t.files[path]=string.rep('x',16)
yes(t.A.prepareSessionModel(25,'normal'),'texture-bearing model prepares')
yes(t.reads[path]==1,'cold texture payload read once, solely for GPU load')
local damaged=H.new({disk=true})
damaged.template.groups[1].texture={path=path,w=2,h=2};damaged.files[path]=string.rep('x',15)
local ok,why=damaged.A.prepareSessionModel(25,'normal')
yes(not ok and tostring(why):find('texture',1,true),'truncated texture remains rejected')
yes(not damaged.A.sessionModelReady(25,'normal'),'damaged texture cannot certify runtime readiness')
print('SessionReadinessFastPathTests: '..checks..' checks PASS; memory-only readiness, exact variants, epoch reset and disk reuse')
