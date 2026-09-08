-- Actual supplied Gen I/II kernels, effect records, party and doubles adapter.
-- Explicit ability IDs below are fixture choices, not edits to shipped saves.
local T=...;local V,Core,A=T.V,T.Core,T.A
if not V.Abilities then return end
local checks=0
local function eq(label,a,b)checks=checks+1;T.eq('ABILITY '..label,a,b)end
local function ok(label,a)checks=checks+1;T.ok('ABILITY '..label,a)end
local function clone(t)local n={}for k,v in pairs(t or {})do n[k]=type(v)=='table' and clone(v)or v end;return n end
local function setup(g,enabled)
 local host,save,game
 if g==1 then host,game,save=T.g1(4) else local unused;unused,host,save=T.g2(4,3);game={save=save,data=T.f.data}end
 save.colosseumBattle.abilitiesEnabled=enabled~=false
 for _,party in ipairs({save.party,host.enemyParty})do for _,m in ipairs(party)do m.abilityId='RUN_AWAY';m.abilityName=nil end end
 local c=Core.new{adapter=A.new(host,g),id='ability-'..g..'-'..checks,generation=g,playerParty=save.party,enemyParty=host.enemyParty,playerIndex=1,enemyIndex=1,rng=T.rand}
 return c,c.adapter,c.adapter.k,host,save,game
end
local function addMove(g,id,typ,power,effect,chance)
 local data=g==1 and T.Data or T.f.data
 data.moves[id]={id=id,name=id,type=typ,power=power,accuracy=100,pp=20,effect=effect or (g==1 and 'NO_ADDITIONAL_EFFECT' or 'EFFECT_NORMAL_HIT'),effectChance=chance}
 return data.moves[id]
end
local function attack(c,s,t,id)
 s.mon.moves={{id=id,pp=20}};if c.generation==1 then s.battler.curMoves=s.mon.moves end
 c.adapter:perform(s,type(t[1])=='table' and t or {t},{moveId=id,moveIndex=1})
end
local function clearStatus(g,s)
 s.mon.status=nil;s.mon.statusTurns=nil
 if g==1 then s.battler.statusPenaltyStacks={};s.battler.confusedTurns=nil;s.battler.flinched=nil
 else s.mon.volatile.confused=nil;s.mon.volatile.confuseCount=nil;s.mon.volatile.flinched=nil end
end
for _,g in ipairs{1,2}do
 local p='Gen'..g..' '
 -- Toggle OFF, even with an external field, must not trap or stamp party data.
 do
  local c,ad,k,h,save=setup(g,false);local src=c.slots['player-left'];local foe=c.slots['enemy-left']
  foe.mon.abilityId='SHADOW_TAG';eq(p..'OFF is not trapped',ad:abilityTraps(src),false)
  src.mon.abilityId=nil;eq(p..'OFF current ability absent',ad:abilityInfo(src.mon),nil)
  c:snapshot();eq(p..'snapshot does not stamp ability',src.mon.abilityId,nil)
  save.colosseumBattle.abilitiesEnabled=true;eq(p..'ON trap applies',ad:abilityTraps(src),true)
  foe.mon.hp=0;eq(p..'fainted holder does not trap',ad:abilityTraps(src),false)
 end
 -- Opening both sides after all four slots exist, same species distinct mons.
 do
  local c,ad,k=setup(g);local left=c.slots['player-left'];left.mon.abilityId='INTIMIDATE'
  ad:onOpeningAbilities()
  eq(p..'Intimidate reaches enemy left',c.slots['enemy-left'].stages.attack,-1)
  eq(p..'Intimidate reaches enemy right',c.slots['enemy-right'].stages.attack,-1)
  eq(p..'Intimidate does not lower partner',(c.slots['player-right'].stages.attack or 0),0)
  local enemy=c.slots['enemy-right'];enemy.mon.abilityId='CLEAR_BODY'
  ad:onEnterAbilities(left);eq(p..'Clear Body blocks actual entry stage change',enemy.stages.attack,-1)
 end
 -- Entry copied abilities never become permanent saved assignments.
 do
  local c,ad,k=setup(g);local src=c.slots['player-right'];src.mon.abilityId='TRACE'
  for _,s in ipairs(c:aliveSlots('enemy'))do s.mon.abilityId='INTIMIDATE'end
  ad:onEnterAbilities(src);eq(p..'Trace runtime identity',ad:abilityInfo(src.mon),'INTIMIDATE')
  eq(p..'Trace keeps saved original',src.mon.abilityId,'TRACE')
  eq(p..'Trace activates copied entry',c.slots['enemy-left'].stages.attack,-1)
  ad:withdraw(src);eq(p..'Trace resets on leave',ad:abilityInfo(src.mon),'TRACE')
 end
 -- Main damage path: native opts shape, no accidental secondary after immunity.
 do
  local c,ad,k=setup(g);local s=c.slots['player-left'];local t=c.slots['enemy-left'];t.mon.hp=1000;t.mon.maxHp=1200
  addMove(g,'CBE_AB_WATER','WATER',40)
  attack(c,s,t,'CBE_AB_WATER');ok(p..'neutral native water damages',t.mon.hp<1000)
  t.mon.hp=700;t.mon.abilityId='WATER_ABSORB';attack(c,s,t,'CBE_AB_WATER')
  eq(p..'Water Absorb heals exact quarter',t.mon.hp,1000);eq(p..'absorb costs normal PP',s.mon.moves[1].pp,19)
  addMove(g,'CBE_AB_GROUND','GROUND',40);t.mon.abilityId='LEVITATE';local hp=t.mon.hp
  attack(c,s,t,'CBE_AB_GROUND');eq(p..'Levitate blocks native damage',t.mon.hp,hp)
  t.mon.abilityId='RUN_AWAY';addMove(g,'CBE_AB_FIRE','FIRE',40);t.mon.hp=1000
  attack(c,s,t,'CBE_AB_FIRE');local ordinary=1000-t.mon.hp
  t.mon.hp=1000;t.mon.abilityId='THICK_FAT';attack(c,s,t,'CBE_AB_FIRE')
  eq(p..'Thick Fat handles actual move metadata',1000-t.mon.hp,math.max(1,math.floor(ordinary/2)))
  t.mon.hp=1000;t.mon.abilityId='FLASH_FIRE';attack(c,s,t,'CBE_AB_FIRE');eq(p..'Flash Fire immune',t.mon.hp,1000)
  ok(p..'Flash Fire battle flag stored',V.Abilities.runtime(k,t.mon).flashFire)
  eq(p..'Flash Fire does not save activation',t.mon.__cbeFlashFireBoost,nil)
 end
 -- Production record dispatch vetoes; no boolean passed where native expects messages.
 do
  local c,ad,k=setup(g);local s=c.slots['player-left'];local t=c.slots['enemy-left'];t.mon.hp=1000
  addMove(g,'CBE_AB_BURN','FIRE',10,g==1 and 'BURN_SIDE_EFFECT1' or 'EFFECT_BURN_HIT',100)
  t.mon.abilityId='WATER_VEIL';attack(c,s,t,'CBE_AB_BURN');eq(p..'Water Veil real native status veto',t.mon.status,nil)
  t.mon.abilityId='RUN_AWAY';attack(c,s,t,'CBE_AB_BURN');eq(p..'native burn still applies unprotected',t.mon.status,g==1 and 'BRN' or 'burn')
  clearStatus(g,t);t.mon.abilityId='SHIELD_DUST';attack(c,s,t,'CBE_AB_BURN');eq(p..'Shield Dust prevents native secondary',t.mon.status,nil)
  t.mon.abilityId='CLEAR_BODY'
  addMove(g,'CBE_AB_GROWL','NORMAL',0,g==1 and 'ATTACK_DOWN1_EFFECT' or 'EFFECT_ATTACK_DOWN')
  attack(c,s,t,'CBE_AB_GROWL');eq(p..'Clear Body vetoes cached primary record',(t.stages.attack or 0),0)
  t.mon.abilityId='RUN_AWAY';attack(c,s,t,'CBE_AB_GROWL');eq(p..'native Growl works otherwise',t.stages.attack,-1)
 end
 -- OHKO record, recoil and drain are real effect handlers, not simulated damage.
 do
  local c,ad,k=setup(g);local s=c.slots['player-left'];local t=c.slots['enemy-left'];t.mon.hp=1000
  addMove(g,'CBE_AB_OHKO','NORMAL',1,g==1 and 'OHKO_EFFECT' or 'EFFECT_OHKO')
  t.mon.abilityId='STURDY';attack(c,s,t,'CBE_AB_OHKO');eq(p..'Sturdy native effect gate',t.mon.hp,1000)
  t.mon.abilityId='RUN_AWAY';addMove(g,'CBE_AB_RECOIL','NORMAL',40,g==1 and 'RECOIL_EFFECT' or 'EFFECT_RECOIL_HIT')
  local hp=s.mon.hp;attack(c,s,t,'CBE_AB_RECOIL');ok(p..'ordinary native recoil exists',s.mon.hp<hp)
  s.mon.hp=hp;s.mon.abilityId='ROCK_HEAD';attack(c,s,t,'CBE_AB_RECOIL');eq(p..'Rock Head prevents native recoil',s.mon.hp,hp)
  s.mon.abilityId='RUN_AWAY';s.mon.hp=math.floor(ad:maxHP(s.mon)/2)
  addMove(g,'CBE_AB_DRAIN','GRASS',20,g==1 and 'DRAIN_HP_EFFECT' or 'EFFECT_LEECH_HIT');local hp2=s.mon.hp
  attack(c,s,t,'CBE_AB_DRAIN');ok(p..'ordinary drain heals',s.mon.hp>hp2)
  s.mon.hp=hp2;t.mon.abilityId='LIQUID_OOZE';attack(c,s,t,'CBE_AB_DRAIN');ok(p..'Liquid Ooze hurts instead of restoring',s.mon.hp<hp2)
 end
 -- Pressure once per selected holder, not once per paired native dispatch.
 do
  local c,ad,k=setup(g);local s=c.slots['player-left'];local targets=c:aliveSlots('enemy')
  for _,t in ipairs(targets)do t.mon.hp=10000;t.mon.abilityId='PRESSURE'end
  addMove(g,'CBE_AB_SPREAD','NORMAL',10);attack(c,s,targets,'CBE_AB_SPREAD')
  eq(p..'two Pressure holders charge three PP total',s.mon.moves[1].pp,17)
  s.mon.status=g==1 and 'SLP' or 'sleep';s.mon.statusTurns=3;s.battler.sleepTurns=3
  attack(c,s,targets,'CBE_AB_SPREAD');eq(p..'sleep does not spend Pressure PP',s.mon.moves[1].pp,20)
 end
 -- Cure/stages run on the right actor and never change a defeated actor.
 do
  local c,ad,k=setup(g);local s=c.slots['player-right'];s.mon.abilityId='NATURAL_CURE';s.mon.status=g==1 and 'BRN' or 'burn'
  ad:withdraw(s);eq(p..'Natural Cure on actual adapter withdrawal',s.mon.status,nil)
  s.mon.abilityId='SPEED_BOOST';local other=c.slots['player-left'];other.mon.abilityId='SPEED_BOOST';other.mon.hp=0
  ad:endTurn();eq(p..'living right Speed Boost',s.stages.speed,1);eq(p..'fainted left Speed Boost skipped',(other.stages.speed or 0),0)
 end
 -- Weather suppression uses all FOUR actives, not whichever pair was last bound.
 do
  local c,ad,k=setup(g);local left=c.slots['player-left'];local right=c.slots['player-right'];local foe=c.slots['enemy-left']
  right.mon.abilityId='CLOUD_NINE';left.mon.abilityId='SWIFT_SWIM';ad:bind(left,foe)
  V.AbilityWeather.set(k,g,'rain',{turns=5});local base=ad:speed(left)
  right.mon.abilityId='RUN_AWAY';eq(p..'weather Speed double with no Cloud Nine',ad:speed(left),base*2)
  right.mon.abilityId='CLOUD_NINE';V.AbilityWeather.set(k,g,'sandstorm',{abilityLocked=true})
  local hp=left.mon.hp;ad:endTurn();eq(p..'off-pair Cloud Nine stops chip',left.mon.hp,hp)
  eq(p..'underlying ability weather retained',V.AbilityWeather.get(k,g).kind,'sandstorm')
  right.mon.abilityId='RUN_AWAY';left.mon.abilityId='SAND_VEIL';ad:endTurn();eq(p..'Sand Veil chip immunity',left.mon.hp,hp)
 end
 -- Snapshot labels carry actual individual identity without writing a save.
 do
  local c,ad,k=setup(g);local s=c.slots['player-right'];s.mon.abilityId=nil;s.mon.dex=58;s.mon.otId=137
  local id=V.Abilities.resolve(s.mon,58);local snap=c:snapshot();local p;for _,row in ipairs(snap.slots)do if row.id==s.id then p=row.portrait end end
  eq('Gen'..g..' snapshot contains resolved ability',p.abilityId,id)
  eq('Gen'..g..' snapshot preserves OT seed',p.otId,137)
  p.abilityId='BAD';eq('Gen'..g..' snapshot detached from saved record',s.mon.abilityId,nil)
 end
end
-- Fault-safety sweep, not a correctness/parity score: every catalogue entry
-- is attached to actual native actor records in each generation and traverses
-- entry, incoming/outgoing physical/special/status moves and one residual tick.
local swept=0
for _,g in ipairs{1,2}do
 addMove(g,'CBE_AB_SWEEP_PHYSICAL','NORMAL',10)
 addMove(g,'CBE_AB_SWEEP_SPECIAL','WATER',10)
 addMove(g,'CBE_AB_SWEEP_STATUS','NORMAL',0,g==1 and 'ATTACK_DOWN1_EFFECT' or 'EFFECT_ATTACK_DOWN')
 for id in pairs(V.AbilityData.byId)do
  local c,ad,k=setup(g);local s=c.slots['player-left'];local t=c.slots['enemy-left']
  s.mon.abilityId=id;s.mon.hp=2000;s.mon.maxHp=3000;t.mon.hp=2000;t.mon.maxHp=3000
  ad:onEnterAbilities(s)
  attack(c,s,t,'CBE_AB_SWEEP_PHYSICAL');clearStatus(g,s);clearStatus(g,t)
  attack(c,t,s,'CBE_AB_SWEEP_PHYSICAL');clearStatus(g,s);clearStatus(g,t)
  attack(c,s,t,'CBE_AB_SWEEP_SPECIAL');clearStatus(g,s);clearStatus(g,t)
  attack(c,t,s,'CBE_AB_SWEEP_SPECIAL');clearStatus(g,s);clearStatus(g,t)
  attack(c,t,s,'CBE_AB_SWEEP_STATUS');ad:endTurn();ad:withdraw(s)
  eq('catalogue '..g..'/'..id..' keeps explicit save identity',s.mon.abilityId,id)
  eq('catalogue '..g..'/'..id..' no saved boost flag',s.mon.__cbeFlashFireBoost,nil)
  ok('catalogue '..g..'/'..id..' finite HP',s.mon.hp==s.mon.hp and s.mon.hp>=0 and s.mon.hp<=3000)
  swept=swept+1
 end
end
print('NATIVE ABILITY CATALOGUE SWEEP: '..swept..' fault-safety cases; not an effect-correctness certificate')
print('NATIVE ABILITIES: '..checks..' assertions; real kernel ON/OFF, entry, effects, weather, Pressure, no save stamping PASS')
