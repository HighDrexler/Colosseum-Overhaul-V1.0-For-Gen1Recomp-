-- Native progression + shared doubles scheduler acceptance. ROM-free fixtures;
-- no mock EXP/damage implementation. Synthetic learnsets isolate UI routing.
local T=...;local eq,ok=T.eq,T.ok
local D,V,Core,A,Data,f=T.V.DoublesRuntime,T.V,T.Core,T.A,T.Data,T.f
local req=require
local oldGeneration=V.GenerationCompat.current
-- Exercise the installed native update interception in both generations.
D.installed=false;V.GenerationCompat.current=function()return 2 end;D.install()
V.GenerationCompat.current=oldGeneration
local function exp(m) return m.exp or m.experience or 0 end
local function clear(c)
 c.queue={};c.qhead=1;c.currentEvent=nil;c.afterEvents=nil;c.phase='resolving';c.messageText=''
end
local function action(c,id,target,move,index)
 local s=c.slots[id]
 return {kind='move',slot=id,battlerId=s.battlerId,target=target,moveId=move or s.mon.moves[1].id,moveIndex=index or 1}
end
local function start(gen,n,configure)
 local screen,host,game,save
 if gen==1 then host,game,save=T.g1(n or 4);screen=host
 else
  local unused;unused,host,save=T.g2(n or 4,3)
  game={data=f.data,save=save,stack={states={}},input={}}
  function game.stack:top() return self.states[#self.states] end
  function game.stack:pop() return table.remove(self.states) end
  function game.stack:push(s) self.states[#self.states+1]=s;if s.enter then s:enter() end end
  local View=req('src.ui.gen2.BattleState');screen=View.new(game,{battle=host})
  game.stack.states={screen};screen.phase='menu';screen.slideFrame=100;screen.queue={}
 end
 game.input.wasPressed=function(_,key)return key=='a'end
 game.input.isDown=function()return false end
 if configure then configure(host,game,save) end
 local s=assert(D.tryBegin(screen,gen),'begin Gen '..gen)
 clear(s.core);s.core.actionQueue={};s.core.actionIndex=1
 return s,s.core,host,game,save
end
local function nativeStep(s)
 local game=s.screen.game;local top=game.stack:top()
 if top and top~=s.screen then if top.update then top:update(.1) end
 else s.screen:update(.1) end
end
local function drainProgress(s,limit)
 for i=1,limit or 16000 do
  if not s.progressing then return i end
  nativeStep(s)
  assert(s.core.phase~='fault',s.core.messageText)
 end
 error('Native progression did not settle: '..tostring(s.screen.phase))
end
local function drainVisual(s)
 local c=s.core
 for i=1,3000 do
  if c.phase~='present' and c.phase~='intro' then return end
  c:update(.1,true)
 end
 error('Visual boundary did not settle')
end
local function runOne(s)
 s.core:performNext();drainVisual(s)
end
local function finish(s)
 if not s.handoff then D.startHandoff(s) end
 for i=1,25000 do
  nativeStep(s)
  assert(s.core.phase~='fault',s.core.messageText)
  if s.closed then return end
 end
 error('Final handoff did not settle')
end
local function close(s) D.close(s) end
local function settleTurn(s)
 for i=1,10000 do
  local c=s.core
  if s.progressing then drainProgress(s)
  elseif c.phase=='command' or c.phase=='replace' or c.phase=='finished' then return
  else c:update(.1,true) end
 end
 error('Turn failed to settle')
end
for _,gen in ipairs({1,2}) do
 local prefix='Gen '..gen..' '
 -- Per-KO award is completed BEFORE the committed partner command; neither a
 -- prompt nor an enemy replacement may appear while any actions remain.
 do
  local s,c,h,g,save=start(gen,4);local left=c.slots['player-left'];local right=c.slots['player-right']
  local foe=c.slots['enemy-left'];foe.mon.hp=1
  local oldToken=foe.battlerId;local benchHP=c.enemyParty[3].hp
  c.slots['enemy-right'].mon.hp=1000
  local before=exp(left.mon);local reserve=exp(save.party[3]);local pp=right.mon.moves[1].pp
  c.actionQueue={action(c,left.id,foe.id),action(c,right.id,foe.id)};c.actionIndex=1
  runOne(s)
  eq(prefix..'KO enters explicit native progression',c.phase,'progression')
  eq(prefix..'pending partner action cursor is frozen',c.actionIndex,2)
  eq(prefix..'forced reserve not logically present midturn',foe.partyIndex,1)
  eq(prefix..'faint token retained until retirement',foe.battlerId,oldToken)
  eq(prefix..'UI command service yields during native progression',D.service.snapshot(h),nil)
  eq(prefix..'four-actor world remains owned during progression',D.presentation(h),s)
  ok(prefix..'KO EXP begins immediately',exp(left.mon)>before)
  eq(prefix..'unshared nonparticipant remains unpaid',exp(save.party[3]),reserve)
  eq(prefix..'progression cannot spend partner PP',right.mon.moves[1].pp,pp)
  local e=exp(left.mon);drainProgress(s)
  eq(prefix..'resume exact committed continuation',c.phase,'resolving')
  eq(prefix..'award record completed',c.defeated[1].rewardState,'complete')
  eq(prefix..'award cursor advanced once',s.awardIndex,2)
  eq(prefix..'same turn after progression',c.turn,1)
  local remainingHP=c.slots['enemy-right'].mon.hp;runOne(s)
  ok(prefix..'remaining target takes retargeted native damage',c.slots['enemy-right'].mon.hp<remainingHP)
  eq(prefix..'reserve is not target of queued move',c.enemyParty[3].hp,benchHP)
  eq(prefix..'earlier EXP not replayed with surviving action',exp(left.mon),e)
  local ticks=0;local endTurn=c.adapter.endTurn
  c.adapter.endTurn=function(ad) ticks=ticks+1;return endTurn(ad) end
  settleTurn(s)
  eq(prefix..'one residual tick for completed queue',ticks,1)
  eq(prefix..'forced enemy reserve finally enters',c.slots['enemy-left'].partyIndex,3)
  eq(prefix..'next commands occur on next turn',c.turn,2)
  eq(prefix..'native command UI restored to doubles',s.screen.phase,'cbe_doubles')
  close(s)
 end
 -- Both opposing active positions faint, but reserves must not absorb the
 -- already submitted follow-up attack. Failure charges PP once, no fake hit.
 do
  local s,c=start(gen,4);local one=c.slots['enemy-left'];local two=c.slots['enemy-right']
  one.mon.hp=0;two.mon.hp=0;c:noteFaints();c.phase='present';c.afterEvents='resolving'
  local actor=c.slots['player-right'];local pp=actor.mon.moves[1].pp
  c.actionQueue={action(c,actor.id,'enemy-left')};c.actionIndex=1
  drainVisual(s);eq(prefix..'spread KO batch pauses once',s.progressing,true)
  drainProgress(s);eq(prefix..'both KO records settled',s.rewardsCompleted,2)
  eq(prefix..'both vacancies remain unfilled before follow-up',#c:aliveSlots('enemy'),0)
  runOne(s)
  eq(prefix..'no-target action still spends its PP',actor.mon.moves[1].pp,pp-1)
  eq(prefix..'no-target action does not claim a move FX hit',c.log[#c.log].kind,'message')
  settleTurn(s)
  eq(prefix..'both enemy reserves enter after turn',#c:aliveSlots('enemy'),2)
  eq(prefix..'turn advances exactly once after double vacancy',c.turn,2)
  eq(prefix..'double KO rewards never replay at replacements',s.rewardsCompleted,2)
  close(s)
 end
 -- Ally KO: surviving enemy still acts against survivor, not the forced bench.
 do
  local s,c=start(gen,4);local fallen=c.slots['player-left'];local survivor=c.slots['player-right'];fallen.mon.hp=0
  c:noteFaints();c.phase='present';c.afterEvents='resolving'
  local pp=c.slots['enemy-right'].mon.moves[1].pp;local hp=survivor.mon.hp
  c.actionQueue={action(c,'enemy-right',fallen.id),action(c,fallen.id,'enemy-left')};c.actionIndex=1
  drainVisual(s)
  eq(prefix..'ally faint does not open forced choice midturn',c.phase,'resolving')
  runOne(s);ok(prefix..'surviving enemy executes native action',survivor.mon.hp<hp)
  eq(prefix..'surviving enemy spends its own PP',c.slots['enemy-right'].mon.moves[1].pp,pp-1)
  eq(prefix..'player reserve still on bench',c.slots['player-left'].partyIndex,1)
  local ticks=0;local old=c.adapter.endTurn;c.adapter.endTurn=function(a)ticks=ticks+1;return old(a)end
  settleTurn(s)
  eq(prefix..'forced player choice follows residual',c.phase,'replace');eq(prefix..'residual exactly once before choice',ticks,1)
  local r=T.req(c,'switch');r.partyIndex=3;assert(c:submit(r));settleTurn(s)
  eq(prefix..'player reserve enters chosen slot',c.slots['player-left'].partyIndex,3)
  eq(prefix..'replacement did not repeat residual',ticks,1)
  close(s)
 end
 -- Prior gains survive a later party wipe; native loss callback cannot erase
 -- already committed progression or replay enemy rewards.
 do
  local s,c,h,g,save=start(gen,3);local mon=save.party[1];local before=exp(mon)
  c.slots['enemy-left'].mon.hp=0;c:noteFaints();c.phase='present';c.afterEvents='resolving'
  drainVisual(s);drainProgress(s);local earned=exp(mon)
  ok(prefix..'earned reward exists before later loss',earned>before)
  for _,m in ipairs(save.party)do m.hp=0 end
  c:noteFaints();c.phase='present';c.afterEvents='finished';drainVisual(s)
  finish(s);eq(prefix..'earlier reward survives later loss',exp(mon),earned)
  eq(prefix..'loss does not repeat award',s.rewardsCompleted,1)
  eq(prefix..'native loss result',gen==2 and h.outcome or h.result,'lose')
 end
 -- Calling award hooks and their own applyShare stays native. Retain default
 -- EXP.ALL / EXP.SHARE passes and native announcements instead of deduping by KO.
 for _,mode in ipairs({'native-sharing','mod-hook'}) do
  local s,c,h,g,save=start(gen,3)
  if gen==1 then save.inventory.EXP_ALL=1 else save.party[3].item='EXP_SHARE' end
  local initial=exp(save.party[3]);local Runtime=req('src.mods.Runtime')
  local oldW,oldH,oldC,oldE=Runtime.wants,Runtime.wantsHook,Runtime.call,Runtime.emit
  local awards,gains,events,shares=0,0,0,0
  Runtime.wants=function(name)return name=='battle.exp_gained' or oldW(name)end
  Runtime.wantsHook=function(name)return (mode=='mod-hook' and (name=='battle.exp_award' or name=='exp.gain')) or oldH(name)end
  Runtime.call=function(name,fn,ctx,...)
   if mode=='mod-hook' and name=='battle.exp_award' and ctx.battle==h then
    awards=awards+1;eq(prefix..'native mod hook participant count',ctx.participants,2)
    eq(prefix..'native mod hook receives actual party identity',ctx.alive[1],save.party[1])
    local apply=ctx.applyShare;ctx.applyShare=function(...) shares=shares+1;return apply(...)end
    -- Exercise a real mod's native helper, not reimplemented arithmetic.
    for _,m in ipairs(save.party)do ctx.applyShare(m,3,false)end;return
   elseif mode=='mod-hook' and name=='exp.gain' then gains=gains+1;return fn(ctx) end
   return oldC(name,fn,ctx,...)
  end
  Runtime.emit=function(name,payload,...)
   if name=='battle.exp_gained' and payload.battle==h then events=events+1 end
   return oldE(name,payload,...)
  end
  c.slots['enemy-left'].mon.hp=0;c:noteFaints();c.phase='present';c.afterEvents='resolving'
  drainVisual(s);drainProgress(s)
  Runtime.wants,Runtime.wantsHook,Runtime.call,Runtime.emit=oldW,oldH,oldC,oldE
  ok(prefix..mode..' pays eligible bench through native code',exp(save.party[3])>initial)
  eq(prefix..mode..' native exp_gained notification count',events,mode=='mod-hook' and 3 or (gen==1 and 5 or 3))
  if mode=='mod-hook' then eq(prefix..'one native award-hook per KO',awards,1);eq(prefix..'three legitimate applyShare calls retained',shares,3);eq(prefix..'native exp.gain still invoked',gains,3)end
  close(s)
 end
 -- No-target interruption does not waste PP; an already charging Dig/Fly
 -- releases once without a second PP charge and cannot stay invisible.
 do
  local s,c=start(gen,3);for _,id in ipairs({'enemy-left','enemy-right'})do c.slots[id].mon.hp=0 end
  local actor=c.slots['player-left'];local pp=actor.mon.moves[1].pp
  actor.mon.status=gen==1 and 'SLP' or 'sleep';actor.mon.statusTurns=3;actor.battler.sleepTurns=3
  c.actionQueue={action(c,actor.id,'enemy-left')};c.actionIndex=1
  c:performNext();eq(prefix..'no-target sleeping action keeps PP',actor.mon.moves[1].pp,pp)
  close(s)
 end
 -- Every real reveal/faint carries the host, side and original party token;
 -- a final native win must not emit a fourth duplicate faint for three KOs.
 do
  local s,c,h,g,save=start(gen,3);local Runtime=req('src.mods.Runtime');local old=Runtime.emit;local events={}
  Runtime.emit=function(name,payload,...)
   if name=='battle.fainted' and payload.battle==h then events[#events+1]=payload end
   return old(name,payload,...)
  end
  c.slots['enemy-left'].mon.hp=0;c.slots['enemy-right'].mon.hp=0;c:noteFaints();c:noteFaints()
  c.phase='present';c.afterEvents='resolving';drainVisual(s);drainProgress(s);settleTurn(s)
  local last=c:aliveSlots('enemy')[1];last.mon.hp=0;c:noteFaints();c:noteFaints();c.phase='present';c.afterEvents='finished'
  drainVisual(s);drainProgress(s);finish(s);Runtime.emit=old
  eq(prefix..'one authoritative notification per faint',#events,3)
  for i,e in ipairs(events)do eq(prefix..'faint host identity '..i,e.battle,h);eq(prefix..'faint opposing side '..i,e.side.index,2);ok(prefix..'faint has stable battler token '..i,e.battlerId);ok(prefix..'faint original party index '..i,e.partyIndex>=1)end
  eq(prefix..'final handoff settles exactly three rewards',s.rewardsCompleted,3)
  eq(prefix..'native final win',gen==2 and h.outcome or h.result,'win')
 end
end
-- Gen II final KO while the surviving ally is genuinely charging, through the
-- native move handler, must never invoke a native singles turn on queue exit.
do
 local s,c,h=start(2,3);local left=c.slots['player-left'];left.mon.moves={{id='SOLARBEAM',pp=10}}
 local calls=0;local original=h.takeTurn;h.takeTurn=function(...)calls=calls+1;return original(...)end
 c.adapter:perform(left,{c.slots['enemy-left']},{moveId='SOLARBEAM',moveIndex=1})
 eq('Gen2 genuine native charge established',left.mon.volatile.chargeMove,'SOLARBEAM')
 for _,m in ipairs(c.enemyParty)do m.hp=0 end
 -- Third opponent must be represented in reward records too, as in an earlier
 -- resolved KO. Normally Core has already recorded it; this isolates final UI.
 c.defeated[#c.defeated+1]={mon=c.enemyParty[3],battler={},participants={[1]=true,[2]=true},partyIndex=3,rewardState='pending'}
 c:noteFaints();c.phase='present';c.afterEvents='finished';drainVisual(s)
 drainProgress(s);finish(s)
 eq('Gen2 charge never resumes singles combat during rewards',calls,0)
 eq('Gen2 charge final batch settles every KO',s.rewardsCompleted,3)
 ok('Gen2 charge final handoff closes session',s.closed)
 eq('Gen2 charge final handoff native win',h.outcome,'win')
end
print('TURN FLOW: per-KO native progression, frozen turn continuation, after-residual replacements, sharing/hooks, later loss, public faints, charge-finalization PASS')

assert(loadfile((os.getenv('CBE_DOUBLES_MOD_DIR') or '../cbe')..'/tests/doubles/ProgressionBoundaryTests.lua')){T=T,start=start,drainVisual=drainVisual,drainProgress=drainProgress,nativeStep=nativeStep,settleTurn=settleTurn,close=close,action=action}
if V.Abilities then assert(loadfile((os.getenv('CBE_DOUBLES_MOD_DIR') or '../cbe')..'/tests/doubles/AbilityTurnFlowTests.lua')){T=T,start=start,drainVisual=drainVisual,drainProgress=drainProgress,nativeStep=nativeStep,settleTurn=settleTurn,close=close,action=action,finish=finish} end
