local H=assert(loadfile('tests/support/ShinyHarness.lua'))()
local checks=0;local function yes(v,l)checks=checks+1;assert(v,l)end
for _,osname in ipairs({'Windows','Android'})do
 for _,variant in ipairs({'normal','shiny'})do
  local h=H.new({disk=true,os=osname});local W=assert(loadfile('lib/WorkBudget.lua'))()
  local A=assert(loadfile('lib/PokemonActors.lua'))({mod=h.mod,Mat4=assert(loadfile('lib/Mat4.lua'))(),ColosseumDex=h.Dex,
   ShinySupport=h.Shiny,GeneratedAssets=h.Assets,RuntimeMeshCache=h.R,WorkBudget=W})
  A.install(h.extractor,function()return {}end,nil,{inspectSpecies=function()return {shinyFilter=h.filter,slots={},bodyMap={}}end})
  local mon={species='RARE',shiny=variant=='shiny'};local battler={mon=mon}
  local resident=A.informationWarmStatus(h.game,battler);yes(not resident.resident and not resident.cached,osname..' starts cold '..variant)
  local ok,why,pending=A.pumpInformation(h.game,battler,'body')
  yes(not ok and pending,'cold extraction yields rather than blocking entire source job')
  yes(A.sourceBusy(),'source writer lock retained across slices')
  local other={mon={species='TEST'}}
  local ok2,reason,pending2=A.pumpInformation(h.game,other,'body')
  yes(not ok2 and pending2 and reason=='another model is preparing','competing model cannot steal writer')
  for i=1,100 do ok,why,pending=A.pumpInformation(h.game,battler,'body');if not pending then break end end
  yes(ok and not pending,'selected model eventually ready '..tostring(why))
  yes(A.informationWarmStatus(h.game,battler).resident,'model ready while viewer remains open')
  yes(not A.sourceBusy(),'writer unlocks after completed model')
  yes(h.extracts[1].variant==variant,'correct dedicated source variant')
  yes(#h.extracts==1,'no repeated extraction while resuming')
  local meshBefore=h.meshes
  ok,why,pending=A.pumpInformation(h.game,battler,'body')
  yes(ok and not pending and h.meshes==meshBefore,'resident lookup no repeated GPU construction')
  local second={mon={species='SECOND'}};A.pumpInformation(h.game,second,'body');yes(A.sourceBusy(),'second source task started')
  A.cancelInformation();yes(not A.sourceBusy(),'cancel releases writer')
  for i=1,100 do ok,why,pending=A.pumpInformation(h.game,second,'body');if not pending then break end end
  yes(ok,'cancelled source can retry safely')
 end
end
print('PerformanceInformationLoadingTests: '..checks..' checks passed')
