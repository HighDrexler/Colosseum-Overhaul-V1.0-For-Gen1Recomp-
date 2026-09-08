-- Uses native EXP, screen, learning and evolution code. Fixture species/learnsets
-- are synthetic; no source models, full UI skin, ROM or device is implied.
local H=...;local T=H.T;local eq,ok=T.eq,T.ok
local D=T.V.DoublesRuntime;local f=T.f;local Data=T.Data
local start,drainVisual,drainProgress,nativeStep,settleTurn,close,action=H.start,H.drainVisual,H.drainProgress,H.nativeStep,H.settleTurn,H.close,H.action
local function clone(t)local n={}for k,v in pairs(t or {})do n[k]=type(v)=='table' and clone(v)or v end;return n end
local function has(m,id)for _,v in ipairs(m.moves)do if v.id==id then return true end end;return false end
local function runProgress(s,mode)
 local prompted,seenChoice,statMon={},setmetatable({},{__mode='k'}),{}
 local choiceCount=0;local c=s.core;local index,turn=c.actionIndex,c.turn
 for tick=1,30000 do
  if not s.progressing then return prompted,statMon end
  local screen=s.screen;local game=screen.game;local top=game.stack:top();local key='a'
  if s.generation==1 then
   for _,view in ipairs(game.stack.states)do if view.newMoveId then prompted[view.mon]=true end end
   if top and top.onChoose then
    if not seenChoice[top]then choiceCount=choiceCount+1;seenChoice[top]=choiceCount end
    if mode=='decline' and seenChoice[top]%2==1 then key='b' end
   elseif top and top.newMoveId then
    prompted[top.mon]=true
   elseif top and getmetatable(top)==require('src.battle.BattleState').StatBox then statMon[top.mon]=true end
  else
   if screen.pendingStatsMon then statMon[screen.pendingStatsMon]=true end
   if screen.pendingLearn then prompted[s.core.playerParty[screen.pendingLearn.index]]=true end
   if mode=='decline' and screen.phase=='ask-forget' then key='b' end
  end
  game.input.wasPressed=function(_,k)return k==key end
  nativeStep(s)
  assert(c.actionIndex==index and c.turn==turn,'Native screen advanced the suspended turn')
  assert(c.phase~='fault',c.messageText)
 end
 error('Native learning did not complete: '..tostring(s.screen.phase))
end
for _,gen in ipairs{1,2}do
 for _,mode in ipairs{'auto','accept','decline'}do
  local prefix='G'..gen..' '..mode..' learning '
  local data=gen==1 and Data or f.data;local species=gen==1 and 'FIXMON_A' or 'CYNDAQUIL'
  local def=data.pokemon[species];local saved=clone(def);local moveId='CBE_TEST_LEARNED'
  local oldMove=data.moves[moveId];local base=gen==1 and 'FIX_TACKLE' or 'TACKLE'
  data.moves[moveId]=clone(data.moves[base]);data.moves[moveId].id=moveId;data.moves[moveId].name='TEST LEARNED'
  local level=gen==1 and 20 or 25
  if gen==1 then def.learnset={{level=level+1,move=moveId}}else def.levelMoves={{level=level+1,move=moveId}}end
  local s,c,h,g,save=start(gen,4)
  -- Non-leading original index 3 is the second actor. The saved party is not reordered.
  c:occupy('player-right',3,false);c.queue={};c.qhead=1;c.currentEvent=nil;c.phase='resolving'
  for _,e in ipairs(c:aliveSlots('enemy'))do c.participants[e.mon]={[1]=true,[3]=true}end
  for _,i in ipairs{1,3}do local m=save.party[i]
   if gen==1 then m.exp=require('src.pokemon.Growth').expForLevel(def.growthRate,level+1,data.growth_rates)-1
   else m.experience=f.Mon.experienceForLevel(f.data.pokemon.growthRates[def.growthRate],level+1)-1 end
   if mode~='auto'then
    local ids=gen==1 and {'FIX_TACKLE','FIX_EMBERISH','FIX_SCRATCH','FIX_CUT'} or {'TACKLE','EMBER','WATER_GUN','THUNDER_WAVE'}
    m.moves={};for _,id in ipairs(ids)do m.moves[#m.moves+1]={id=id,pp=data.moves[id].pp}end
   end
   if gen==1 then c:slotFor(m).battler.curMoves=m.moves end
  end
  local actor=c.slots['player-right'];local oldPP=actor.mon.moves[1].pp
  c.actionQueue={action(c,actor.id,'enemy-right')};c.actionIndex=1
  c.slots['enemy-right'].mon.hp=10000
  c.slots['enemy-left'].mon.hp=0;c:noteFaints();c.phase='present';c.afterEvents='resolving';drainVisual(s)
  if gen==1 then eq(prefix..'stat commit waits for native queue',save.party[1].level,level)end
  local prompts,stats=runProgress(s,mode)
  for _,i in ipairs{1,3}do local m=save.party[i]
   eq(prefix..'correct recipient level '..i,m.level,level+1)
   eq(prefix..'correct learning decision '..i,has(m,moveId),mode~='decline')
   ok(prefix..'native stat presentation '..i,stats[m])
   if mode~='auto'then ok(prefix..'native forget dialog '..i,prompts[m])end
   if gen==1 then ok(prefix..'Gen1 evolution eligibility retained '..i,h.leveledUp[m])
    eq(prefix..'active battler uses updated stats '..i,c:slotFor(m).battler.curStats,m.stats)
   else ok(prefix..'Gen2 evolution eligibility retained '..i,s.screen.evolvable[i])end
   eq(prefix..'no evolution midway through battle '..i,m.species,species)
  end
  eq(prefix..'bench does not silently level',save.party[2].level,level)
  local hp=c.slots['enemy-right'].mon.hp
  local pp=actor.mon.moves[1].pp;c:performNext();drainVisual(s)
  if mode=='accept'then
   eq(prefix..'new slot move cannot inherit committed action',c.slots['enemy-right'].mon.hp,hp)
   eq(prefix..'newly learned move PP unspent',actor.mon.moves[1].pp,pp)
  else
   ok(prefix..'unchanged committed move still executes',c.slots['enemy-right'].mon.hp<hp)
   eq(prefix..'unchanged committed move spends PP once',actor.mon.moves[1].pp,oldPP-1)
  end
  settleTurn(s)
  if mode~='decline'then
   local found=false;for _,m in ipairs(c:legalMoves(actor))do if m.id==moveId and m.enabled then found=true end end
   ok(prefix..'learned move usable on next selection',found)
  end
  close(s);data.pokemon[species]=saved;data.moves[moveId]=oldMove
 end
 -- End-of-turn residual KOs are awarded before any forced reserves enter.
 do
  local s,c=start(gen,4);local enemy=c.slots['enemy-left'];enemy.mon.hp=1
  enemy.mon.status=gen==1 and 'PSN' or 'poison'
  c.actionQueue={};c.actionIndex=1;c.turnEnded=false
  local ticks=0;local old=c.adapter.endTurn;c.adapter.endTurn=function(a)ticks=ticks+1;return old(a)end
  c:performNext();drainVisual(s)
  eq('G'..gen..' residual KO starts reward progression',s.progressing,true)
  eq('G'..gen..' residual KO reserve still absent',enemy.partyIndex,1)
  drainProgress(s);settleTurn(s)
  eq('G'..gen..' residual KO tick exactly once',ticks,1)
  eq('G'..gen..' residual KO awarded exactly once',s.rewardsCompleted,1)
  eq('G'..gen..' residual KO reserve now present',enemy.partyIndex,3)
  close(s)
 end
 -- Revealed second/later species and causal happiness use public party identity.
 do
  local s,c,h,g,save=start(gen,4)
  local e=c.slots['enemy-right'];local late=gen==1 and 'FIXMON_B' or 'GEODUDE'
  c.enemyParty[3].species=late;c:occupy(e.id,3,false)
  eq('G'..gen..' custom send-out marks late species seen',save.pokedex.seen[late],true)
  close(s)
 end
end
-- Entry hazard chains occupy no turn action and never repeat residuals.
do
 local s,c=start(2,5);c.adapter.spikes.enemy=true
 for _,m in ipairs(c.enemyParty)do m.species='GEODUDE'end
 c.slots['enemy-left'].mon.hp=0;c.enemyParty[3].hp=1;c.enemyParty[4].hp=1
 c:noteFaints();c.phase='present';c.afterEvents='resolving';c.actionQueue={};c.actionIndex=1
 local ticks=0;local old=c.adapter.endTurn;c.adapter.endTurn=function(a)ticks=ticks+1;return old(a)end
 drainVisual(s);drainProgress(s);settleTurn(s)
 eq('Entry hazard chain runs residual once',ticks,1)
 eq('Entry hazard chain settles every KO',s.rewardsCompleted,3)
 eq('Entry hazard chain reaches living reserve',c.slots['enemy-left'].partyIndex,5)
 eq('Entry hazard chain enters exactly next turn',c.turn,2)
 close(s)
end
-- Actual native happiness helpers; simultaneous faint does not erase the
-- opposing causal battler before the stronger-foe comparison.
do
 local s,c=start(2,3);local player=c.slots['player-right'];local foe=c.slots['enemy-right']
 player.mon.happiness=225;foe.mon.level=player.mon.level+35;player.mon.hp=0
 player.faintCause={slot=foe.id,battlerId=foe.battlerId};c:noteFaints();c:noteFaints()
 eq('Gen2 correct stronger-foe happiness loss once',player.mon.happiness,215);close(s)
end
do
 local s,c,h,g,save=start(1,3);local player=c.slots['player-right'];local foe=c.slots['enemy-right']
 local Version=require('src.core.GameVersion');local old=Version.isYellow;Version.isYellow=function()return true end
 player.mon.species='PIKACHU';save.pikachuHappiness=225;player.mon.hp=0
 player.faintCause={slot=foe.id,battlerId=foe.battlerId};c:noteFaints();c:noteFaints()
 Version.isYellow=old;eq('Yellow companion faint happiness once',save.pikachuHappiness,224);close(s)
end
print('PROGRESSION BOUNDARIES: native stat/learn accept/decline, non-leading indices, queued-move identity, residual and hazard KOs, seen/happiness PASS')
-- Evolution stays at the final native boundary, in party order; canceling one
-- does not suppress a second eligible mon or repeat prizes/callbacks.
for _,gen in ipairs{1,2}do for _,cancelFirst in ipairs{false,true}do
 local data=gen==1 and Data or f.data;local species=gen==1 and 'FIXMON_A' or 'CYNDAQUIL'
 local def=data.pokemon[species];local old=clone(def);local into=gen==1 and 'FIXMON_B' or 'CBE_TEST_EVOLVED'
 local oldInto=data.pokemon[into]
 if gen==2 then data.pokemon[into]=clone(def);data.pokemon[into].id=into;data.pokemon[into].name='FIXTURE EVOLVED';data.pokemon[into].index=156;data.pokemon[into].levelMoves={};data.pokemon[into].evolutions={}end
 local level=gen==1 and 20 or 25
 if gen==1 then def.learnset={};def.evolutions={{method='LEVEL',level=level+1,species=into}}
 else def.levelMoves={};def.evolutions={{method='EVOLVE_LEVEL',level=level+1,into=into}}end
 local s,c,h,g,save=start(gen,3)
 for _,i in ipairs{1,2}do local m=save.party[i]
  if gen==1 then m.exp=require('src.pokemon.Growth').expForLevel(def.growthRate,level+1,data.growth_rates)-1
  else m.experience=f.Mon.experienceForLevel(data.pokemon.growthRates[def.growthRate],level+1)-1 end
 end
 c.slots['enemy-left'].mon.hp=0;c:noteFaints();c.phase='present';c.afterEvents='resolving';drainVisual(s);drainProgress(s)
 eq('G'..gen..' intermediate gain cannot evolve first mon',save.party[1].species,species)
 eq('G'..gen..' intermediate gain cannot evolve second mon',save.party[2].species,species)
 c.actionQueue={};c.actionIndex=1;settleTurn(s)
 local callback,result=0
 local function done(r) callback=callback+1;result=r end
 if gen==1 then h.onFinish=done else s.screen.onDone=done end
 for _,e in ipairs(c:aliveSlots('enemy'))do e.mon.hp=0 end
 c:noteFaints();c.phase='present';c.afterEvents='finished';drainVisual(s)
 for tick=1,40000 do
  if callback>0 then break end
  local top=g.stack:top();local key='a'
  if cancelFirst and top and top.mon==save.party[1] and top.newSpecies and not top.canceled then
   if (gen==1 and (top.t or 0)>80 and not top.done)or(gen==2 and top.phase=='flash')then key='b'end
  end
  g.input.wasPressed=function(_,k)return k==key end
  nativeStep(s);assert(c.phase~='fault',c.messageText)
 end
 eq('G'..gen..' evolution native completion once '..tostring(cancelFirst),callback,1)
 eq('G'..gen..' evolution native outcome '..tostring(cancelFirst),result,'win')
 eq('G'..gen..' first evolution respects cancel '..tostring(cancelFirst),save.party[1].species,cancelFirst and species or into)
 eq('G'..gen..' second evolution completes '..tostring(cancelFirst),save.party[2].species,into)
 eq('G'..gen..' no repeat KO rewards after evolution',s.rewardsCompleted,3)
 ok('G'..gen..' evolution releases doubles session',s.closed)
 if gen==2 then for _,m in ipairs(save.party)do eq('Gen2 battle volatile cleanup after evolution',m.volatile,nil)end end
 data.pokemon[species]=old;data.pokemon[into]=oldInto
end end
print('NATIVE EVOLUTION: per-KO eligibility survives to post-battle, cancel/continue, exactly-once result and reward PASS')
