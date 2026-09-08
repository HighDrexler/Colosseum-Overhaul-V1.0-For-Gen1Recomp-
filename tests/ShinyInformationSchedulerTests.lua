local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local now=0;love={timer={getTime=function()return now end},system={getOS=function()return 'Android'end}}
local events={};local fail=false;local sourceBusy=false
local A={informationWarmStatus=function(_,b)return {dex=b.dex,key=b.key or b.dex,variant=b.shiny and 'shiny' or 'normal',
 supported=true,cached=b.cached==true,resident=b.ready==true,idlePrepared=true}end,
 prewarmInformation=function(_,b,allow,checkpoint)
  events[#events+1]=tostring(b.dex)..(b.shiny and ':shiny' or ':normal')..':start'
  sourceBusy=true
  for i=1,3 do now=now+.005;checkpoint()end
  sourceBusy=false
  if fail then return false,'fixture failure'end
  b.ready=true;events[#events+1]=tostring(b.dex)..(b.shiny and ':shiny' or ':normal')..':done';return true
 end,
 sourceBusy=function()return sourceBusy end,cancelSourceWork=function()sourceBusy=false end,
 cancelHardCache=function()end,cancelPartyPrewarm=function()end,hardCacheStatus=function()return {}end}
local S=assert(loadfile('lib/ResidentPrewarm.lua'))({PokemonActors=A})
local game={};local ordinary={dex=25,cached=true};local shiny={dex=25,cached=true,shiny=true}
S.queueInformation(game,ordinary,'summary');S.queueInformation(game,shiny,'summary');S.touchViewer(1,'fixture')
for i=1,10 do now=now+.02;S.pump(game)end
yes(shiny.ready and not ordinary.ready,'same species normal/shiny queue keys distinct')
yes(#events==2 and events[1]=='25:shiny:start','superseded queued normal pruned')
-- An already-started source job completes safely, then the new exact variant.
S.cancel();events={};now=1;ordinary={dex=6,key=6};shiny={dex=6,key='6:shiny',shiny=true}
S.queueInformation(game,ordinary,'pc');S.touchViewer(1,'source');now=1.1;S.pump(game)
yes(sourceBusy and #events==1,'source extraction yields after one slice')
S.queueInformation(game,shiny,'pc')
for i=1,20 do now=now+.02;S.pump(game)end
yes(ordinary.ready and shiny.ready,'started source job not discarded mid-write')
yes(events[2]=='6:normal:done' and events[3]=='6:shiny:start','no simultaneous source decoder jobs')
-- Failed work retries, without a flood of jobs every draw or pretending ready.
S.cancel();events={};now=3;fail=true;local broken={dex=2,shiny=true}
S.queueInformation(game,broken,'dex');S.touchViewer(1,'retry')
for i=1,8 do now=now+.02;S.pump(game)end
yes(not broken.ready and S.status().failed>=1,'failed variant not ready')
local ok,why=S.queueInformation(game,broken,'dex');yes(not ok and why=='retry-cooldown','failure throttle')
fail=false;now=6;yes(S.queueInformation(game,broken,'dex'),'retry after timeout');S.touchViewer(1,'retry')
for i=1,8 do now=now+.02;S.pump(game)end
yes(broken.ready,'retry completes variant')
-- Cancellation explicitly releases decoder ownership for future jobs.
S.cancel();now=8;local cold={dex=3,shiny=true};S.queueInformation(game,cold,'dex');S.touchViewer(1,'cancel');now=8.1;S.pump(game)
yes(sourceBusy,'cancellable source running');S.cancel();yes(not sourceBusy and S.status().pending==0,'cancel releases source lock')
print('ShinyInformationSchedulerTests: '..checks..' checks passed; simulated Android slices')
