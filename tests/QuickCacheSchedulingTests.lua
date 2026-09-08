-- Pure scheduling/scope probes; deterministic time, not device benchmarks.
local checks=0
local function yes(x,l)checks=checks+1;assert(x,l)end
local function eq(a,b,l)checks=checks+1;assert(a==b,l..': '..tostring(a)..' ~= '..tostring(b))end
local function loadM(p,v)return assert(loadfile(p))(v)end
local now,platform,gen,version=0,'Windows',2,'gold'
love={timer={getTime=function()return now end},system={getOS=function()return platform end}}
local Shiny=loadM('lib/ShinySupport.lua');local V={ShinySupport=Shiny,GenerationCompat={current=function()return gen end}}
V.ModelIdentity=loadM('lib/ModelIdentity.lua',V);V.WorkBudget=loadM('lib/WorkBudget.lua')
local saved=nil
V.engineRequire=function(name)
 if name=='src.core.GameVersion' then return {get=function()return version end}end
 if name=='src.core.SaveData' or name=='src.core.gen2.Save' then return {load=function()return saved end}end
 error('unexpected engine read '..name)
end
local resident={};local calls={};local mode='warm';local steps=0;local failures={};local cleanup=0
V.PokemonActors={sessionCacheIdentity=function()return 'fixture' end,peek=function(_,d,v)return {resident=resident[d..':'..v]==true}end,
 prepareSessionModel=function(d,v,checkpoint)
  local k=d..':'..v;calls[#calls+1]=k
  if mode=='cold' then
   V.WorkBudget.onCancel(function()cleanup=cleanup+1 end)
   for i=1,40 do now=now+.001;steps=steps+1;checkpoint(k)end
  end
  if failures[k] then return false,'fixture read failed' end
  resident[k]=true;return true,'resident'
 end}
local savedWrites=0;V.mod={cache={write=function()savedWrites=savedWrites+1;return true end}}
local stack={};function stack:push(s)self[#self+1]=s end;function stack:top()return self[#self]end;function stack:pop()return table.remove(self)end
local pressed={};local game={data={pokemon={GROWLITHE={dex=58},VOLTORB={dex=100}}},stack=stack,input={wasPressed=function(_,k)return pressed[k]end}}
local C=loadM('lib/BattleCache.lua',V)
local save={party={{species='GROWLITHE'},{species='GROWLITHE',shiny=true},{species='VOLTORB'},
 {species='VOLTORB'},{dex=6,shiny=true},{species='EGG',isEgg=true}},boxes={{dex=251}}}
saved=save
local rows=C.quickPlan(game,save);eq(#rows,4,'unique team appearances only, no egg or PC bake')
eq(rows[1].dex,58,'definition mapping');eq(rows[2].variant,'shiny','shared-body shiny distinct');eq(rows[4].dex,6,'rare shiny identity')
eq(save.party[1].species,'GROWLITHE','input unchanged');eq(#save.party,6,'party unchanged')
local full=C.fullPlan(game,save);eq(#full,502,'full catalog still present');eq(full[1].dex,58,'full builds useful team first')
local seen={};for _,r in ipairs(full)do local k=r.dex..':'..r.variant;yes(not seen[k],'no duplicate '..k);seen[k]=true end
for i=1,251 do yes(seen[i..':normal'] and seen[i..':shiny'],'full coverage '..i)end
local bad=C.quickPlan(game,{party={{species='UNKNOWN'}}});yes(bad[1].error,'unmapped team member never silently skipped')
local starter=C.quickPlan(game,save,true);eq(#starter,3,'new Gold starter scope');eq(starter[1].dex,152,'not the old save party')
gen=1;version='yellow';starter=C.quickPlan(game,save,true);eq(#starter,1,'Yellow only needs Pikachu');eq(starter[1].dex,25,'Yellow model')
version='red';eq(#C.quickPlan(game,nil),3,'no-save Red starter scope');gen=2;version='gold'
platform='Windows';eq(C.frameBudgetMs(),12,'foreground desktop budget');platform='Android';eq(C.frameBudgetMs(),8,'Android budget')
platform='iOS';eq(C.frameBudgetMs(),8,'iOS budget');platform='Windows'
-- Batch 32 inexpensive ready rows in one update rather than one per frame.
assert(C.open(game,nil));local s=stack:top();s:update();eq(#calls,32,'32 warm entries batched')
local first=#calls;for i=1,8 do s:update()end;eq(#calls,first,'game-speed updates cannot multiply budget')
local frames=1
while C.busy() do now=now+1/60+1e-7;stack:top():update();frames=frames+1;yes(frames<100,'bounded warm run')end
eq(#calls,502,'all appearances really visited');eq(frames,16,'502 ready entries finish in 16 slices not 503')
yes(C.ready(),'full readiness only after all pass')
local old=#calls;assert(C.openStartup(game,save));yes(not C.busy(),'validated exact team returns immediately');eq(#calls,old,'no work on warm Continue')
-- A GPU eviction cannot be concealed by earlier validation.
resident['58:shiny']=nil;yes(not C.quickReady(rows),'eviction detected');assert(C.openStartup(game,save));now=now+.02;stack:top():update()
yes(not C.busy() and C.quickReady(rows),'evicted exact shiny restored')
-- Cold work respects one total time budget; multiple rows do not each receive
-- another 12 ms allowance within the same update.
C._test.reset();calls={};mode='cold';steps=0;resident={};now=0
assert(C.open(game,{{dex=100,variant='normal'},{dex=156,variant='normal'}},nil,false,'quick'))
s=stack:top();s:update();yes(steps>=11 and steps<=13,'one desktop cold slice')
first=steps;for i=1,8 do s:update()end;eq(steps,first,'no speed-multiplied cold extraction')
pressed.b=true;s:update();pressed={};eq(cleanup,1,'cold task cancellation cleanup once');yes(not C.busy(),'cancel returns')
C._test.reset();mode='warm';calls={};failures['156:normal']=true
assert(C.open(game,{{dex=100,variant='normal'},{dex=156,variant='normal'}},nil,false,'quick'))
s=stack:top();s:update();yes(C.status().error~=nil,'batched failure stops immediately');eq(C.status().done,1,'no false progress')
yes(not C.ready(),'failure not marked catalog ready');eq(savedWrites,1,'error persisted')
failures={};pressed.a=true;s:update();pressed={};now=now+.02;s:update();yes(not C.busy(),'retry reuses completed entries')
print('QuickCacheSchedulingTests: '..checks..' checks PASS; scopes, colour identity, warm batching, deadlines, retry/cancel')
print('Deterministic ready-entry schedule: legacy 503 updates; current '..frames..' updates. Not a device timing claim.')
