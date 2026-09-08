-- Native single-battle event wiring and safety boundaries, not a replacement
-- damage/EXP implementation. Graphics retain the parent suite's stubs.
local T=...;local V=T.V;local count=0
local function eq(n,a,b)count=count+1;T.eq('ABILITY LIFECYCLE '..n,a,b)end
local function ok(n,v)count=count+1;T.ok('ABILITY LIFECYCLE '..n,v)end
local Runtime=require('src.mods.Runtime');local oldEvents=Runtime.events
local events=require('src.mods.Events').new();Runtime.events=events
V.AbilityLifecycle.install({events=events})
local function single(gen,on)
 local h,save,game
 if gen==1 then h,game,save=T.g1(2)else local unused;unused,h,save=T.g2(2,3)end
 save.colosseumBattle.abilitiesEnabled=on~=false;save.colosseumBattle.doubleBattlesEnabled=false
 for _,p in ipairs({save.party,h.enemyParty})do for _,m in ipairs(p)do m.abilityId='RUN_AWAY' end end
 return h,save,game
end
for _,gen in ipairs{1,2}do
 local p='Gen'..gen..' '
 local h,save=single(gen);local player=gen==1 and h.player.mon or h.player
 player.abilityId='INTIMIDATE';Runtime.emit('battle.started',{battle=h})
 local stages=gen==1 and h.enemy.stages or h.stages.enemy
 eq(p..'native opening emits Intimidate',stages.attack,-1)
 Runtime.emit('battle.started',{battle=h});eq(p..'opening event idempotent',stages.attack,-1)
 -- An explicit foreign ability is not replaced by an invented CBE default.
 local m={abilityId='OTHER_MOD_CUSTOM',dex=58};eq(p..'foreign explicit ability respected',V.Abilities.ensure(m,58),nil)
 -- Switch through the real native switch method, not the CBE doubles helper.
 player.abilityId='NATURAL_CURE';player.status=gen==1 and 'BRN' or 'burn';save.party[2].abilityId='INTIMIDATE'
 if gen==1 then
  h.queue={};h.nextInsert=nil;h:resolveSwitch(save.party[2])
  for i=1,200 do
   if h.player.mon==save.party[2]then break end
   local step=table.remove(h.queue,1);assert(step,'Gen1 native switch queue exhausted')
   if step.fn then step.fn() end
  end
 else assert(h:switch(2)) end
 eq(p..'native leave cures outgoing',player.status,nil)
 eq(p..'native switch activates entrant exactly once',stages.attack,-2)
 local current=gen==1 and h.player.mon or h.player
 eq(p..'native switch retains saved identity',current,save.party[2])
 local currentB=gen==1 and h.player or current
 local beforeAbility=V.Abilities.current(h,current,58)
 V.Abilities.runtime(h,current).trace='PRESSURE';Runtime.emit('battle.ended',{battle=h})
 eq(p..'end listener clears runtime copy',V.Abilities.current(h,current,58),beforeAbility)
 -- Public singleton entry notifications during a live doubles-owned progression
 -- must not activate the same four-slot entry a second time.
 local oldSession=V.DoublesRuntime.session
 V.DoublesRuntime.session=function()return{host=h,screen=h,progressing=true}end
 current.abilityId='INTIMIDATE';local before=stages.attack
 Runtime.emit('battle.started',{battle=h});eq(p..'progression host cannot re-enter native entry',stages.attack,before)
 V.DoublesRuntime.session=oldSession
 -- OFF wrappers and listeners delegate without creating battle ability state.
 local off=single(gen,false);local mon=gen==1 and off.player.mon or off.player;mon.abilityId='INTIMIDATE'
 Runtime.emit('battle.started',{battle=off})
 local st=gen==1 and off.enemy.stages or off.stages.enemy
 eq(p..'OFF native opening unchanged',st.attack or 0,0)
 -- Ability residual hooks are once per actual turn; ordinary native behavior is
 -- not claimed idempotent when a caller deliberately calls endOfTurn twice.
 local turn=single(gen);local mon=gen==1 and turn.player.mon or turn.player;mon.abilityId='SPEED_BOOST'
 if gen==1 then
  turn.turnCount=72;turn:endOfTurn();local st=turn.player.stages
  eq(p..'native residual speed stage',st.speed,1);turn:endOfTurn();eq(p..'ability residual not duplicated',st.speed,1)
 else
  turn.turn=72;turn.turnOpen=true;local batch=turn:closeTurn({})
  eq(p..'native residual speed stage',turn.stages.player.speed,1);ok(p..'ability event reaches native returned batch',#batch>0)
  turn:closeTurn({});eq(p..'ability residual not duplicated',turn.stages.player.speed,1)
 end
end
-- Gen II entry is after spikes and is skipped when the hazard faints an entrant.
do
 local h,save=single(2);local m=save.party[2];m.hp=1;m.abilityId='INTIMIDATE';h.spikes={player=true}
 local before=h.stages.enemy.attack or 0;h:switch(2)
 eq('Gen2 hazard KO occurs',m.hp,0)
 eq('Gen2 no Intimidate from hazard-fainted entrant',h.stages.enemy.attack or 0,before)
end
Runtime.events=oldEvents
print('NATIVE ABILITY LIFECYCLE: '..count..' assertions PASS')
