local T=...;local g1,g2,Core,A,V,Data,f,rand,eq,ok,pump,req=T.g1,T.g2,T.Core,T.A,T.V,T.Data,T.f,T.rand,T.eq,T.ok,T.pump,T.req
local function fresh(gen)
 if gen==2 then return g2(4,4)end
 local h,g,save=g1(4)
 return Core.new{adapter=A.new(h,1),id='stability',generation=1,playerParty=save.party,enemyParty=h.enemyParty,playerIndex=1,enemyIndex=1,rng=rand},h,save
end
local failures={};local cases=0
local function check(label,fn)
 cases=cases+1;local pass,why=pcall(fn);if not pass then failures[#failures+1]=label..': '..tostring(why)end
end
-- Available Gen II fixture moves cover damaging, primary/secondary status,
-- multi-turn, recoil, weather, held-item and field-effect native kernels.
local ids={};for id in pairs(f.data.moves)do ids[#ids+1]=id end;table.sort(ids)
for _,id in ipairs(ids)do for _,side in ipairs({'player','enemy'})do
 check('Gen2 '..id..' '..side,function()
  local c=fresh(2);local a=c.adapter;local def=a:moveDef(id)
  if not a:supports(def) then return end
  local s=c.slots[side..'-right'];s.mon.moves={{id=id,pp=20}}
  for _,p in pairs(c.slots)do p.mon.hp=a:maxHP(p.mon);end
  local targets=c:targets(s,def);local ts={}
  for _,slot in ipairs(targets)do if c.slots[slot].side~=side or #targets==1 then ts[#ts+1]=c.slots[slot]end end
  if #ts==0 then return end
  if a:targetMode(def)=='selected' then ts={ts[1]}end
  a:perform(s,ts,{moveId=id,moveIndex=1});a:endTurn();c:noteFaints()
  for _,p in pairs(c.slots)do ok('finite HP '..id,type(p.mon.hp)=='number' and p.mon.hp==p.mon.hp and p.mon.hp>=0)end
 end)
end end
-- Gen I primary and secondary effect families, through the real effect registry.
local E=require('src.battle.MoveEffects')
for _,family in ipairs({'primary','secondary'})do
 local names={};for name in pairs(E[family] or {})do names[#names+1]=name end;table.sort(names)
 for _,effect in ipairs(names)do for _,side in ipairs({'player','enemy'})do
  check('Gen1 '..effect..' '..side,function()
   local c=fresh(1);local a=c.adapter;local id='SWEEP_'..effect
   local def={id=id,name=id,type='NORMAL',accuracy=100,power=family=='primary' and 0 or 10,pp=20,effect=effect}
   Data.moves[id]=def;if not a:supports(def)then return end
   local s=c.slots[side..'-right'];local t=c.slots[(side=='player' and 'enemy' or 'player')..'-left']
   s.mon.moves={{id=id,pp=20}};s.battler.curMoves=s.mon.moves;t.battler.curTypes={'GRASS'};t.mon.hp=500
   a:perform(s,{t},{moveId=id,moveIndex=1});a:endTurn();c:noteFaints()
  end)
 end end
end
for gen=1,2 do
 for _,id in ipairs({'POTION','SUPER_POTION','HYPER_POTION','MAX_POTION','FULL_RESTORE','ANTIDOTE','BURN_HEAL','ICE_HEAL','AWAKENING','PARLYZ_HEAL','FULL_HEAL','REVIVE','MAX_REVIVE','ETHER','MAX_ETHER','ELIXER','MAX_ELIXER','X_ATTACK','X_DEFEND','X_SPEED','X_SPECIAL','X_ACCURACY','DIRE_HIT','GUARD_SPEC','BERRY','GOLD_BERRY','MIRACLEBERRY','MYSTERYBERRY','HEAL_POWDER','ENERGY_ROOT','REVIVAL_HERB'})do
  for _,index in ipairs({1,2,3})do check('item '..gen..id..index,function()
   local c,h,save=fresh(gen);local a=c.adapter;local I=V.DoublesItems
   a.data.items=a.data.items or {};a.data.items[id]={id=id,name=id};save.inventory={[id]=2}
   if not I.classify(a,id)then return end
   local mon=c.playerParty[index];mon.hp=1;mon.status=gen==1 and 'PSN' or 'poison'
   mon.moves[1].pp=0;mon.moves[1].maxPp=35
   if id:find('REVIV') then mon.hp=0 end
   local before=mon.hp;local status=mon.status
   I.validate(a,{item=id,partyIndex=index,moveIndex=1})
   eq('Item preview HP isolated',mon.hp,before);eq('Item preview status isolated',mon.status,status)
   local used=I.perform(a,{item=id,partyIndex=index,moveIndex=1,targetMon=mon})
   eq('Item consumption matches outcome',save.inventory[id],used and 1 or 2)
  end)end
 end
 check('switch/replacements '..gen,function()
  local c=fresh(gen);pump(c,function(x)return x.phase=='command'end)
  local s=c.slots['player-right'];local ally=c.slots['player-left'];local old=s.mon
  s.stages.attack=4;ally.stages.attack=2
  if gen==2 then old.volatile={confuseCount=3,substitute=10} else s.battler.confused=3;s.battler.substituteHP=10 end
  old.status=gen==1 and 'PSN' or 'poison'
  c:occupy(s.id,3,false)
  eq('Switch clears incoming stages',s.stages.attack or 0,0);eq('Partner stages survive switch',ally.stages.attack,2)
  eq('Old major status survives switch',old.status,gen==1 and 'PSN' or 'poison')
  eq('Old identity unbound',c:slotFor(old),nil)
  if gen==2 then eq('Old volatile cleared',old.volatile,nil)end
  local def=c.adapter:moveDef(gen==1 and 'FIX_TACKLE' or 'TACKLE')
  local target=c:resolvedTargets(c.slots['enemy-left'],{target=s.id},def)
  eq('Queued opposing move follows incoming slot',target[1].mon,s.mon)
  -- Both player slots faint, only one surviving reserve in Gen I.
  ally.mon.hp=0;s.mon.hp=0;c:noteFaints();c.queue={};c.qhead=1;c.currentEvent=nil
  c:replaceFainted();eq('Forced replacement requested',c.phase,'replace')
  local bad=req(c,'switch');bad.partyIndex=1;eq('Fainted replacement rejected',c:submit(bad),false)
  local good=req(c,'switch');good.partyIndex=c:bench('player')[1]
  eq('Healthy forced replacement accepted',c:submit(good),true)
  eq('Stale replacement rejected',c:submit(good),false)
  for i=1,500 do if c.phase=='replace' or c.phase=='resolving' then break end;c:update(.1,true)end
  ok('Replacement presentation settles',c.phase=='replace' or c.phase=='resolving')
 end)
 check('missing inventory '..gen,function()
  local c,h,save=fresh(gen);save.inventory=nil;c.adapter.data.items.POTION={id='POTION',name='POTION'}
  eq('Missing stock rejected at execution',V.DoublesItems.perform(c.adapter,{item='POTION',partyIndex=1}),false)
 end)
end
-- Trap ownership must end when its source leaves, without clearing another trap.
check('Gen2 trap source switch',function()
 local c=fresh(2);local a=c.adapter;local s=c.slots['player-left'];local t=c.slots['enemy-right'];local other=c.slots['enemy-left']
 local id='WRAP';a.data.moves[id]={id=id,name=id,power=15,type='NORMAL',accuracy=100,pp=20,effect='EFFECT_TRAP_TARGET'}
 s.mon.moves={{id=id,pp=20}};t.mon.hp=500
 a:perform(s,{t},{moveId=id,moveIndex=1})
 ok('Wrap applied',t.mon.volatile and t.mon.volatile.wrapCount)
 other.mon.volatile={wrapCount=4,wrapMove='Other trap'};other.boundBy=c.slots['player-right'].battlerId
 c:occupy(s.id,3,false)
 eq('Source switch ends its trap',t.mon.volatile.wrapCount,nil)
 eq('Other source trap retained',other.mon.volatile.wrapCount,4)
end)
for gen=1,2 do
 for _,condition in ipairs({'sleep','freeze','paralysis','poison','burn','confusion'})do
  for _,side in ipairs({'player','enemy'})do check('status gates '..gen..condition..side,function()
   local c=fresh(gen);local a=c.adapter;local src=c.slots[side..'-right'];local dst=c.slots[(side=='player' and 'enemy' or 'player')..'-left']
   local statuses=gen==1 and {sleep='SLP',freeze='FRZ',paralysis='PAR',poison='PSN',burn='BRN'} or {sleep='sleep',freeze='freeze',paralysis='paralysis',poison='poison',burn='burn'}
   src.mon.status=statuses[condition]
   if condition=='sleep' then src.mon.statusTurns=3;src.battler.sleepTurns=3 end
   if condition=='confusion' then if gen==2 then src.mon.volatile={confuseCount=3} else src.battler.confused=3 end end
   local id=gen==1 and 'FIX_TACKLE' or 'TACKLE';src.mon.moves={{id=id,pp=20}};if gen==1 then src.battler.curMoves=src.mon.moves end
   for i=1,3 do if src.mon.hp>0 and dst.mon.hp>0 then a:beginTurn();a:perform(src,{dst},{moveId=id,moveIndex=1});a:endTurn()end end
   ok('Status resolution finite',src.mon.hp>=0 and dst.mon.hp>=0)
  end)end
 end
 check('execution revalidation '..gen,function()
  local c,h,save=fresh(gen);local a=c.adapter;local I=V.DoublesItems
  a.data.items.POTION={id='POTION',name='POTION'};save.inventory={POTION=1}
  local mon=c.playerParty[2];mon.hp=1
  local action={item='POTION',partyIndex=2,targetMon=mon}
  eq('Target initially valid',I.validate(a,action),true)
  save.inventory.POTION=nil;eq('Item disappeared safely refused',I.perform(a,action),false);eq('No stock no heal',mon.hp,1)
  save.inventory.POTION=1;mon.hp=a:maxHP(mon)
  eq('Already healed target retains item',I.perform(a,action),false);eq('Retained stock',save.inventory.POTION,1)
  mon.hp=1;action.targetMon=c.playerParty[3]
  eq('Changed target identity refused',I.perform(a,action),false)
 end)
end
check('Gen2 repeated item and preview isolation',function()
 local c,h,save=fresh(2);local a=c.adapter;local I=V.DoublesItems;local mon=c.playerParty[2]
 for _,id in ipairs({'DIRE_HIT','GUARD_SPEC','FULL_HEAL'})do a.data.items[id]={id=id,name=id}end
 save.inventory={DIRE_HIT=2,GUARD_SPEC=2,FULL_HEAL=2}
 mon.volatile=nil;I.validate(a,{item='FULL_HEAL',partyIndex=2})
 eq('Preview does not create volatile state',mon.volatile,nil)
 for _,id in ipairs({'DIRE_HIT','GUARD_SPEC'})do
  eq('First battle effect succeeds',I.perform(a,{item=id,partyIndex=2}),true)
  eq('Active battle effect refused at selection',I.validate(a,{item=id,partyIndex=2}),false)
  eq('Duplicate effect retains remaining copy',save.inventory[id],1)
 end
 mon.status=nil;mon.volatile.confuseCount=3
 eq('Full Heal clears confusion-only target',I.perform(a,{item='FULL_HEAL',partyIndex=2}),true)
 eq('Confusion removed',mon.volatile.confuseCount,nil)
end)
check('Replacement request identity',function()
 local c=fresh(2);c.slots['player-left'].mon.hp=0;c:replaceFainted()
 local r=req(c,'switch');r.partyIndex=3;r.slot='enemy-left'
 eq('Wrong replacement slot refused',c:submit(r),false)
 eq('Refusal keeps replacement prompt',c.phase,'replace')
end)
for _,why in ipairs(failures)do print('STABILITY FAILURE',why)end
assert(#failures==0,#failures..' stability failures')
print('Stability native effect sweep: '..cases..' cases PASS')
