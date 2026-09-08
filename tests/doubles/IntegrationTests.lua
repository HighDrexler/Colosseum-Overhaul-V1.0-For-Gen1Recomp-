-- Additional source-parity and native controller regressions; called by the
-- real Gen1Recomp kernel runner, never substitutes mocked damage arithmetic.
local T=...;local g2,eq,ok=T.g2,T.eq,T.ok
local function prepare(move)
 local c,h,save=g2(3,3,move)
 c.queue={};c.qhead=1;c.currentEvent=nil
 for _,slot in ipairs(c:aliveSlots())do c.adapter.k:volatile(slot.mon)end
 return c,c.slots['player-left'],c.slots['enemy-left'],h,save
end
local function use(c,src,dst,id)
 src.mon.moves={{id=id,pp=20}}
 return c.adapter:perform(src,{dst},{moveId=id,moveIndex=1})
end
local c,src,dst=prepare('SOLARBEAM');local hp=dst.mon.hp
local e=use(c,src,dst,'SOLARBEAM')
eq('Charge chapter selected from native volatile',e.stage,'charge');eq('Charge does not damage target',dst.mon.hp,hp)
eq('Event owns source token',e.sourceBattlerId,src.battlerId);eq('Event owns target token',e.targetBattlers[dst.id],dst.battlerId)
e=c.adapter:perform(src,{dst},{moveId='SOLARBEAM',moveIndex=1})
eq('Release chapter selected',e.stage,'attack');eq('Release flagged',e.release,true)
ok('Release damages target',dst.mon.hp<hp)
-- A source event must not turn self-costs or a status-interrupted move into an
-- unrelated target-side Waza reaction.
do
 local c,src,dst=prepare();local before=c:captureVitals();src.mon.hp=src.mon.hp-2;dst.mon.hp=dst.mon.hp-3
 local source={slot=src.id,battlerId=src.battlerId,move='TACKLE',stage='attack',targetBattlers={[dst.id]=dst.battlerId}}
 c:recordVitals(before,source)
 local recoil,hit
 for _,event in ipairs(c.queue)do if event.kind=='damage' then if event.slot==src.id then recoil=event else hit=event end end end
 eq('Self cost has no target Waza',recoil.move,nil);eq('Real target preserves source Waza',hit.move,'TACKLE')
 eq('Reaction owns source battler',hit.sourceBattlerId,src.battlerId)
end
-- New effects are native kernels with explicit four-position ownership.
local definitions={DISABLE='EFFECT_DISABLE',ENCORE='EFFECT_ENCORE',MEAN_LOOK='EFFECT_MEAN_LOOK',SPIDER_WEB='EFFECT_MEAN_LOOK',LOCK_ON='EFFECT_LOCK_ON',MIND_READER='EFFECT_LOCK_ON',PSYCH_UP='EFFECT_PSYCH_UP'}
for id,effect in pairs(definitions)do
 T.f.data.moves[id]={id=id,name=id,effect=effect,power=0,type='NORMAL',accuracy=100,pp=20}
end
do
 local c,src,dst=prepare();dst.mon.volatile.lastMove='TACKLE'
 eq('Disable available',c.adapter:supports(T.f.data.moves.DISABLE),true)
 use(c,src,dst,'DISABLE');eq('Disable records actual target',dst.mon.volatile.disabled,'TACKLE')
 eq('Partner not disabled',c.slots['enemy-right'].mon.volatile.disabled,nil)
 local pp=dst.mon.moves[1].pp;local hp=src.mon.hp
 c.adapter:perform(dst,{src},{moveId='TACKLE',moveIndex=1})
 eq('Faster Disable blocks queued attack',src.mon.hp,hp);eq('Blocked attack does not spend PP',dst.mon.moves[1].pp,pp)
end
do
 local c,src,dst=prepare();dst.mon.moves={{id='TACKLE',pp=30},{id='EMBER',pp=20}};dst.mon.volatile.lastMove='TACKLE'
 use(c,src,dst,'ENCORE');eq('Encore target locked',dst.mon.volatile.encore,'TACKLE')
 c.actionQueue={{kind='move',slot=dst.id,battlerId=dst.battlerId,moveId='EMBER',moveIndex=2,target=src.id}};c.actionIndex=1
 local tacklePP,emberPP=dst.mon.moves[1].pp,dst.mon.moves[2].pp
 c:performNext();eq('Mid-turn Encore spends forced move PP',dst.mon.moves[1].pp,tacklePP-1)
 eq('Mid-turn Encore does not use selected alternative',dst.mon.moves[2].pp,emberPP)
end
for _,move in ipairs({'MEAN_LOOK','SPIDER_WEB'})do
 local c,src,dst=prepare();use(c,src,dst,move)
 eq(move..' traps target only',c.adapter:switchLocked(dst),true)
 ok(move..' leaves partner free',not c.adapter:switchLocked(c.slots['enemy-right']))
 c.adapter:withdraw(src);ok(move..' frees target when source leaves',not c.adapter:switchLocked(dst))
end
for _,move in ipairs({'LOCK_ON','MIND_READER'})do
 local c,src,dst=prepare();use(c,src,dst,move)
 eq(move..' source identity',dst.lockOnSource,src.battlerId)
 c.adapter.acting=c.slots['player-right'];eq(move..' partner cannot steal aim',c.adapter.k:consumeLockOn(dst.mon),false)
 ok(move..' retains target flag',dst.mon.volatile.lockOn)
 c.adapter.acting=src;eq(move..' owner consumes aim',c.adapter.k:consumeLockOn(dst.mon),true)
 eq(move..' consumed once',c.adapter.k:consumeLockOn(dst.mon),false)
end
do
 local c,src,dst=prepare('SPIKES');use(c,src,dst,'SPIKES')
 eq('Spikes attached to enemy side',c.adapter.spikes.enemy,true);eq('Own side remains clear',c.adapter.spikes.player,false)
 local hp=c.enemyParty[3].hp;c:occupy('enemy-right',3,false)
 eq('Native Flying hazard immunity',c.slots['enemy-right'].mon.hp,hp)
 -- Use a grounded reserve, then exercise a hazard KO and the replacement loop.
 local c,src,dst=prepare('SPIKES');use(c,src,dst,'SPIKES')
 c.enemyParty[3]=T.f.Mon.new(T.f.data,'CYNDAQUIL',20);local reserve=c.enemyParty[3];local hp=reserve.hp
 c:occupy('enemy-right',3,false)
 eq('Grounded reserve takes native eighth',reserve.hp,hp-math.max(1,math.floor(c.adapter:maxHP(reserve)/8)))
 eq('Entry HP visible before its queued damage',c.display[c.slots['enemy-right'].battlerId].hp,hp)
 local c,src,dst=prepare('SPIKES');use(c,src,dst,'SPIKES')
 c.enemyParty[3]=T.f.Mon.new(T.f.data,'CYNDAQUIL',20);c.enemyParty[3].hp=1
 c:occupy('enemy-right',3,false);eq('Hazard KO detected',c.slots['enemy-right'].faintNoted,true)
 eq('Hazard KO records the exact pending vacancy',c.pendingReplacements['enemy-right'],c.slots['enemy-right'].battlerId)
 eq('A voluntary midturn entry KO does not force an early reserve',c.afterEvents,'command')
end
do
 local c,src,dst=prepare('PSYCH_UP')
 dst.stages.attack=3;dst.stages.defense=-2;dst.stages.accuracy=1;dst.stages.speed=2
 use(c,src,dst,'PSYCH_UP')
 eq('Psych Up copies selected target attack',src.stages.attack,3)
 eq('Psych Up copies selected target defense',src.stages.defense,-2)
 eq('Psych Up copies accuracy',src.stages.accuracy,1)
 eq('Psych Up does not mutate partner',c.slots['player-right'].stages.attack,0)
 dst.stages.attack=1;eq('Psych Up stage table detached',src.stages.attack,3)
 eq('Psych Up costs PP once',src.mon.moves[1].pp,19)
 local actual=c.adapter.k:effectiveSpeed(src.mon);ok('Copied speed affects native turn-order calculation',actual>src.mon.stats.speed)
 local c,src,dst=prepare('PSYCH_UP');src.stages.attack=2
 local e=use(c,src,dst,'PSYCH_UP')
 eq('Psych Up neutral target fails',e.targetResults[dst.id].missed,true)
 eq('Psych Up failure keeps own stages',src.stages.attack,2)
 eq('Psych Up failure still spends PP',src.mon.moves[1].pp,19)
 dst.stages.defense=-2;dst.mon.volatile.protect=true;dst.mon.volatile.substitute=12
 dst.mon.volatile.lockOn=true;dst.lockOnSource=src.battlerId
 use(c,src,dst,'PSYCH_UP')
 eq('Psych Up respects no-checkhit source path',src.stages.defense,-2)
 eq('Psych Up overwrites previous boosts',src.stages.attack,0)
 eq('Psych Up does not consume Lock-On',dst.mon.volatile.lockOn,true)
 eq('Psych Up does not replace native host data',c.adapter.host.data,c.adapter.data)
 eq('Psych Up compatibility handler is local',c.adapter.host.data.gen2MoveEffects,nil)
end
do
 local c,src,dst=prepare('THRASH');local ids,mode=c:targets(src,{id='THRASH'})
 eq('Rampage random target mode',mode,'random');eq('Rampage exposes opponents only',#ids,2)
 for _,id in ipairs(ids)do ok('Rampage never offers partner',c.slots[id].side~='player')end
end
-- Gen I preview must not mutate either live battler, even for status-stat paths.
do
 local host,game,save=T.g1(3)
 local c=T.Core.new{adapter=T.A.new(host,1),id='preview-ownership',generation=1,playerParty=save.party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=T.rand}
 local I=T.V.DoublesItems;save.inventory={X_ATTACK=2}
 local left,right=c.slots['player-left'],c.slots['player-right'];local enemy=c.slots['enemy-left']
 local attack=right.stages.attack;local stats=enemy.battler.curStats
 eq('Gen I stat preview accepted',I.validate(c.adapter,{item='X_ATTACK',partyIndex=right.partyIndex}),true)
 eq('Preview retains active stage',right.stages.attack,attack);eq('Preview retains inventory',save.inventory.X_ATTACK,2)
 eq('Preview retains opponent stats table',enemy.battler.curStats,stats)
end
print('INTEGRATION: source charge/release, event identities, recoil provenance, Disable/Encore, locks, Spikes, item preview PASS')

-- Target-side status/stat chapters must survive without invented HP damage.
do
 local c,src,dst=prepare();local before=c:captureVitals()
 dst.stages.attack=(dst.stages.attack or 0)-1
 local source={slot=src.id,battlerId=src.battlerId,move='GROWL',stage='attack',targetBattlers={[dst.id]=dst.battlerId}}
 c:recordVitals(before,source)
 local reactions,hits=0,0;local found
 for _,event in ipairs(c.queue) do
  if event.kind=='reaction' then reactions=reactions+1;found=event end
  if event.kind=='damage' then hits=hits+1 end
 end
 eq('Stat-only target reaction emitted once',reactions,1);eq('No invented HP hit',hits,0)
 eq('Stat reaction retains target identity',found.battlerId,dst.battlerId)
 eq('Stat reaction retains source identity',found.sourceBattlerId,src.battlerId)
 eq('Stat reaction retains move',found.move,'GROWL')
 local c,src,dst=prepare();local before=c:captureVitals();dst.mon.status='paralysis'
 c:recordVitals(before,{slot=src.id,battlerId=src.battlerId,move='THUNDER_WAVE',stage='attack',targetBattlers={[dst.id]=dst.battlerId}})
 local reactions=0;for _,event in ipairs(c.queue)do if event.kind=='reaction' then reactions=reactions+1 end end
 eq('Status-only target reaction',reactions,1)
 for _,case in ipairs({'miss','charge','self','replacement'})do
  local c,src,dst=prepare();local before=c:captureVitals()
  if case~='miss' then dst.stages.attack=-1 end
  local source={slot=case=='self' and dst.id or src.id,battlerId=src.battlerId,move='TEST',
   stage=case=='charge' and 'charge' or 'attack',targetBattlers={[dst.id]=case=='replacement' and 'new-id' or dst.battlerId}}
  c:recordVitals(before,source)
  local n=0;for _,event in ipairs(c.queue)do if event.kind=='reaction' then n=n+1 end end
  eq('No false reaction '..case,n,0)
 end
end
