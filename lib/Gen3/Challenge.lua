

local V=...
local req=V.engineRequire or require
local C={version=1}
local function pack(...) return {n=select('#',...),...} end
local unpack=table.unpack or unpack
function C.scoped(fn,...)
C.depth=(C.depth or 0)+1
local result=pack(pcall(fn,...))
C.depth=C.depth-1
if not result[1] then error(result[2],0) end
return unpack(result,2,result.n)
end
function C.release() C.battleSession=nil;C.liveSession=nil end
function C.markBattle(st,number)
if st then
st.cbeMtBattleChallenge=true
st.cbeMtBattleNumber=number
end
end
local function copy(t,seen)
if type(t)~='table' then return t end
seen=seen or {};if seen[t] then return seen[t] end
local out={};seen[t]=out;for k,v in pairs(t) do out[k]=copy(v,seen) end;return out
end
local function data() return V.Gen3Runtime.data(V.Gen3Runtime.game or V.mod.game) end
local function run() local d=data();return d and d.challenge end
local function nativeSession() return V.Gen3Runtime.session(V.Gen3Runtime.game or V.mod.game) end
local function persist()
local game=V.Gen3Runtime.game or V.mod.game
if game and game.saveGame and not req('src.core.game3.battle.init').isActive() then
local ok,written=pcall(game.saveGame,game)
C.saveError=not ok and tostring(written) or (written==false and 'Host save unavailable' or nil)
return ok and written~=false
end
return false
end
function C.clone(mon)
local m=copy(mon);local P=req('src.core.game3.pokemon')
m.species=P.speciesOf(mon);m.speciesId=m.species;m.speciesNumbering='internal'
m.level=50;m.exp=req('src.core.game3.battle.experience').expForLevel(m,50)
m.hp=nil;m.status=nil;P.applyStats(m);m.hp=m.maxHp
req('src.core.game3.party').healAll({m})
return m
end
function C.makeMon(dex,rng,tier)
local P=req('src.core.game3.pokemon');local species=P.speciesFromNational(dex)
if not species then return nil end
local pid=rng:nextRaw();local iv=math.min(31,8+(tier or 1)*2)
local m={species=species,speciesId=species,speciesNumbering='internal',level=50,
personality=pid,otId=47231,otSecretId=121,ivs={hp=iv,atk=iv,def=iv,spa=iv,spd=iv,spe=iv},
evs={hp=0,atk=0,def=0,spa=0,spd=0,spe=0},friendship=255,happiness=255,
ability=P.abilityId(species,pid),gender=P.gender(species,pid),nature=P.natureId(pid)}
m.moves,m.pp,m.maxPp=P.movesAtLevel(species,50)
if not m.moves or #m.moves==0 then return nil end
P.applyStats(m);m.hp=m.maxHp
m.exp=req('src.core.game3.battle.experience').expForLevel(m,50)
if tier and tier>=5 then
local items={200,201,202,203,204,205,206,207,208,209,210,211}
m.item=items[rng:nextInt(1,#items)];m.heldItem=m.item
end
return m
end
function C.opponents(r)
local rng=V.MtBattleSeedManager.newStream(V.MtBattleSeedManager.subSeed(r.seed,r.floor))
local tier=math.ceil(r.floor/10);local pool={};local P=req('src.core.game3.pokemon')
local legends={[144]=true,[145]=true,[146]=true,[150]=true,[151]=true,[243]=true,[244]=true,[245]=true,
[249]=true,[250]=true,[251]=true,[377]=true,[378]=true,[379]=true,[380]=true,[381]=true,[382]=true,[383]=true,[384]=true,[385]=true,[386]=true}
for dex=1,386 do
local species=P.speciesFromNational(dex);local stats=species and P.stats(species)
if stats and (tier>=9 or not legends[dex]) then
local total=(stats.hp or 0)+(stats.attack or stats.atk or 0)+(stats.defense or stats.def or 0)
+(stats.speed or stats.spe or 0)+(stats.spAtk or stats.spa or 0)+(stats.spDef or stats.spd or 0)
if total>=math.min(470,190+tier*26) and total<=math.min(720,370+tier*35) then pool[#pool+1]=dex end
end
end
if #pool<6 then pool={3,6,9,65,68,94,130,149,196,197,248,254,257,260,282,306,330,373,376} end
local mons={};local count=math.min(6,2+math.floor((tier-1)/2))
for i=1,count do
local dex=table.remove(pool,rng:nextInt(1,#pool));local mon=C.makeMon(dex,rng,tier)
if mon then mons[#mons+1]=mon end
end
return mons
end
function C.new(source,total,prepared)
local session=nativeSession();if not session then return false,'No active save' end
if req('src.core.game3.battle.init').isActive() then return false,'Finish the current battle first' end
local team={}
if source=='prepared' then
if type(prepared)~='table' or #prepared~=6 then return false,'Choose exactly six Pokemon' end
for _,mon in ipairs(prepared) do
if req('src.core.game3.pokemon').isEgg(mon) then return false,'Eggs cannot enter Mt. Battle' end
team[#team+1]=C.clone(mon)
end
end
if source=='party' then
for _,m in ipairs(session.party or {}) do
if not req('src.core.game3.pokemon').isEgg(m) then team[#team+1]=C.clone(m) end
end
if #team<2 then return false,'Bring at least two non-Egg Pokemon' end
end
local d=data();d.runNonce=(d.runNonce or 0)+1
local seed=((love.math.random(1,2147483000)+d.runNonce*997)%2147483646)+1
total=V.MtBattleHubScreens and V.MtBattleHubScreens.normalizedClimbLength(total)
or (total==10 and 10 or 100)
local r={version=1,seed=seed,floor=1,total=total,status='ready',team=team,
wins=0,continues=1,source=source,bankedXP=0}
if source=='rental' then
local rng=V.MtBattleSeedManager.newStream(seed)
local pool={3,6,9,26,65,68,94,130,149,154,157,160,181,196,197,212,214,230,248,254,257,260,282,306,330,350,373,376}
for i=1,6 do local dex=table.remove(pool,rng:nextInt(1,#pool));r.team[i]=assert(C.makeMon(dex,rng,5)) end
end
local previous=d.challenge
d.challenge=r
if not persist() then d.challenge=previous;return false,C.saveError or 'Save failed' end
return true
end
function C.launch(opts)
opts=opts or {}
local r=run();if not r or r.status~='ready' then return false,'No ready challenge' end
local B=req('src.core.game3.battle.init');if B.isActive() then return false,'Battle already active' end
local live=nativeSession();local challenge=copy(live)
challenge.party=r.team
challenge.bag=req('src.core.game3.bag').new()
challenge.money=0;challenge.dex=copy(live.dex or {})
challenge.modData={}
local foes=C.opponents(r)
r.opponentPreview={};for i,m in ipairs(foes) do r.opponentPreview[i]=m.species end
V.Gen3UI.close();req('src.ui.game3.start_menu').close(true);r.status='in_battle'
C.liveSession=live;C.battleSession=challenge
local GameVersion=req('src.core.GameVersion')
local emerald=GameVersion.layout and GameVersion.layout(GameVersion.get())=='rse'
local facilityClass,frontierTrainer
if emerald then

frontierTrainer={class=0,className='MT. BATTLE TRAINER',name=r.floor%10==0 and 'AREA LEADER' or 'MT. BATTLE TRAINER',pic=0}
else
local tower=req('src.core.game3.trainer_tower').pack()
for id in pairs(tower and tower.facilityClassTrainerClass or {}) do
if not facilityClass or id<facilityClass then facilityClass=id end
end
if facilityClass==nil then C.release();r.status='ready';return false,'Native trainer tower data unavailable' end
end
local invoked,ok,why=pcall(B.start,{playerParty=r.team,foeParty=foes,foe={party=foes,trainerClass=facilityClass},session=challenge,
headless=opts.headless,autoFight=opts.autoFight,fade=opts.fade,
double=true,wild=false,trainerTower=not emerald,battleTower=true,frontierTrainer=frontierTrainer,
trainerName=r.floor%10==0 and 'AREA LEADER' or 'MT. BATTLE TRAINER',
trainerPicId=0,cbeMtBattleNumber=r.floor,cbeKeepFormat=true,
onStarted=function(st) C.markBattle(st,r.floor) end,
onDone=function(result)
C.release()
V.Gen3Runtime.finish('challenge completed')
if result=='win' then
r.wins=r.wins+1
local bp=r.floor%10==0 and 5+math.ceil(r.floor/10) or 1
local d=data();d.bp=(d.bp or 0)+bp
for _,m in ipairs(foes) do
local earned=req('src.core.game3.battle.experience').gainFor(m.species,50,{trainer=true})
r.bankedXP=r.bankedXP+earned;d.xpBank=(d.xpBank or 0)+earned
end
r.floor=r.floor+1
r.status=r.floor>r.total and 'complete' or 'ready'

for i,m in ipairs(r.team) do r.team[i]=C.clone(m) end
if r.status=='complete' then
d.records=d.records or {};d.records.clears=(d.records.clears or 0)+1
d.records.best=math.max(d.records.best or 0,r.wins)
end
else r.status='lost' end
persist();C.open()
end})
if not invoked or not ok then
local errorText=not invoked and ok or why


B._onDone=nil;B.reset();C.release();r.status='ready';C.open();return false,errorText
end
return true
end
function C.open()
if V.Gen3MtBattleHub then return V.Gen3MtBattleHub.open() end
if V.Gen3Audio then V.Gen3Audio.lobby() end
local d=data();if not d then return end
local r=d.challenge;local rows={}
if r and r.status=='in_battle' and not req('src.core.game3.battle.init').isActive() then

r.status='ready';req('src.core.game3.party').healAll(r.team)
end
if r and r.status=='ready' then
rows[#rows+1]={label='BATTLE '..r.floor..' / '..r.total,run=function()
local ok,why=C.launch();if not ok and V.Gen3UI.menu then V.Gen3UI.menu.footer=why end
end}
rows[#rows+1]={label='SCOUT NEXT TRAINER',run=function()
local foes=C.opponents(r);local list={};local P=req('src.core.game3.pokemon')
for _,m in ipairs(foes) do list[#list+1]={label=P.displayMonName(m),run=function() end} end
V.Gen3UI.show('NEXT OPPONENT / LEVEL 50',list,'A/B BACK',C.open)
end}
rows[#rows+1]={label='TEAM / MOVE PREP',run=C.team}
rows[#rows+1]={label='SUSPEND AND RETURN',run=function() persist();V.Gen3UI.close() end}
elseif r and r.status=='lost' and r.continues>0 then
rows[#rows+1]={label='USE CONTINUE / RETRY FLOOR',run=function()
r.continues=r.continues-1;r.status='ready';req('src.core.game3.party').healAll(r.team);persist();C.open()
end}
end
rows[#rows+1]={label='NEW RUN / OWN TEAM',run=function() C.confirmNew('party') end}
rows[#rows+1]={label='NEW RUN / RENTALS',run=function() C.confirmNew('rental') end}
rows[#rows+1]={label='BP EXCHANGE / '..tostring(d.bp or 0)..' BP',run=C.shop}
rows[#rows+1]={label='DISTRIBUTE XP / '..tostring(d.xpBank or 0),run=C.xp}
rows[#rows+1]={label='BACK',run=V.Gen3UI.home}
V.Gen3UI.show('MT. BATTLE / LEVEL 50 DOUBLES',rows,
r and (r.status:upper()..' / WINS '..r.wins..' / XP BANK '..r.bankedXP) or 'DETACHED TEAMS / OWNED PARTY STAYS IN FIELD',V.Gen3UI.home)
end
function C.back()
local hub=V.Gen3MtBattleHub
if hub and hub.active() then return hub.returnToHub() end
return C.open()
end
function C.grantXP(slot,amount)
local d=data();local s=nativeSession();local mon=s and s.party and s.party[slot]
if d.pendingXP then return false,'Finish the pending move/evolution choices first' end
if not mon or req('src.core.game3.pokemon').isEgg(mon) then return false,'Select a non-Egg party Pokemon' end
amount=math.min(math.max(0,math.floor(tonumber(amount) or 0)),d.xpBank or 0)
local reward=req('src.core.game3.battle.experience').apply(mon,amount)
local P=req('src.core.game3.pokemon')
for _=1,#reward.levels do
P.adjustFriendship(mon,P.FRIENDSHIP_EVENT_GROW_LEVEL,{mapSec=P.currentMapSec(s)})
end
d.xpBank=(d.xpBank or 0)-reward.gained
if reward.gained>0 then
d.pendingXP={slot=slot,personality=mon.personality,otId=mon.otId,index=1,
levels=reward.levels,moves=req('src.core.game3.battle.learn_move').movesForLevels(mon,reward.levels)}
end
persist();return true,reward
end
function C.rewardChoices()
local d=data();local pending=d.pendingXP;if not pending then return C.back() end
local s=nativeSession();local P=req('src.core.game3.pokemon');local mon
for _,candidate in ipairs(s.party or {}) do
if candidate.personality==pending.personality and candidate.otId==pending.otId then mon=candidate;break end
end
if not mon then
V.Gen3UI.show('XP CHOICES PENDING',{{label='BACK',run=C.back}},'RETURN THE REWARDED POKEMON TO YOUR PARTY',C.back);return
end
local row=pending.moves[pending.index]
if row then
local function nextMove() pending.index=pending.index+1;persist();C.rewardChoices() end
if P.knowsMove(mon,row.moveId) then return nextMove() end
if P.moveSlotCount(mon)<4 then P.teachMove(mon,row.moveId);return nextMove() end
local choices={}
for i=1,4 do local slot=i
if not P.isHmMove(mon.moves[slot]) then
choices[#choices+1]={label='REPLACE '..P.moveName(mon.moves[slot]),run=function()
P.replaceMove(mon,slot,row.moveId);nextMove()
end}
end
end
choices[#choices+1]={label='DO NOT LEARN',run=nextMove}
V.Gen3UI.show('LEARN '..P.moveName(row.moveId)..'?',choices,'CHOICES SAVED / B RETURN WITHOUT SKIPPING',C.back)
return
end
local target=#(pending.levels or {})>0 and req('src.core.game3.evolution').levelTarget(mon,s)
if target then
V.Gen3UI.show('EVOLVE '..P.displayMonName(mon)..'?',{
{label='BEGIN EVOLUTION',run=function()
V.Gen3UI.close();req('src.ui.game3.start_menu').close(true)
req('src.ui.game3.evolution_scene').start(mon,target,{session=s,bag=s.bag,canStop=true,isBattle=false,
onDone=function() d.pendingXP=nil;persist();C.open() end})
end},
{label='KEEP CURRENT FORM',run=function() d.pendingXP=nil;persist();C.back() end},
},'NATIVE FRLG EVOLUTION / B RETURN',C.back)
else d.pendingXP=nil;persist();C.back() end
end
function C.xp()
local d=data();if d.pendingXP then return C.rewardChoices() end
local rows={};local P=req('src.core.game3.pokemon')
for i,m in ipairs(nativeSession().party or {}) do local slot,mon=i,m
if not P.isEgg(mon) and (mon.level or 1)<100 then
rows[#rows+1]={label=P.displayMonName(mon)..' L'..mon.level,run=function()
local choices={}
for _,n in ipairs({1000,5000,d.xpBank or 0}) do local amount=n
if amount>0 then choices[#choices+1]={label='GIVE '..math.min(amount,d.xpBank or 0)..' XP',run=function()
local ok,why=C.grantXP(slot,amount)
if ok then C.rewardChoices() else V.Gen3UI.menu.footer=why end
end} end
end
choices[#choices+1]={label='BACK',run=C.xp}
V.Gen3UI.show('XP / '..P.displayMonName(mon),choices,'EXP / STATS / LEARNSET USE NATIVE GEN 3 RULES',C.xp)
end}
end
end
rows[#rows+1]={label='BACK',run=C.back}
V.Gen3UI.show('XP BANK / '..tostring(d.xpBank or 0),rows,'CHOOSE AN OWNED PARTY POKEMON',C.back)
end
function C.confirmNew(source)
V.Gen3UI.show('START NEW '..source:upper()..' RUN?',{
{label='100 BATTLES',run=function() local ok,why=C.new(source,100);C.open();if not ok then V.Gen3UI.menu.footer=why end end},
{label='10 BATTLES',run=function() local ok,why=C.new(source,10);C.open();if not ok then V.Gen3UI.menu.footer=why end end},
{label='CANCEL',run=C.open},
},'REPLACES CURRENT CHALLENGE / KEEPS EARNED BP',C.open)
end
function C.team()
local hub=V.Gen3MtBattleHub
local r=run();local team=hub and hub.active() and hub.draft or r and r.team
if not team then return end
local rows={};local P=req('src.core.game3.pokemon')
for _,m in ipairs(team) do local mon=m
rows[#rows+1]={label=P.displayMonName(mon),run=function() V.Gen3UI.prep(mon,true,C.team) end}
end
local back=hub and hub.active() and hub.returnToHub or C.open
rows[#rows+1]={label='BACK',run=back}
V.Gen3UI.show('CHALLENGE TEAM / MOVE PREP',rows,'LEVEL 50 / CHANGES APPLY TO CHALLENGE CLONES',back)
end
function C.shop()
local rows={};local offers={{name='RARE CANDY',id=68,cost=10},{name='PP UP',id=69,cost=8},{name='LEFTOVERS',id=200,cost=24}}
for _,offer in ipairs(offers) do local o=offer
rows[#rows+1]={label=o.name..' / '..o.cost..' BP',run=function()
local d=data();local s=nativeSession();local Bag=req('src.core.game3.bag')
if (d.bp or 0)<o.cost then V.Gen3UI.menu.footer='NOT ENOUGH BP';return end
if not Bag.canAdd(s.bag,o.id,1) then V.Gen3UI.menu.footer='BAG IS FULL';return end
if Bag.add(s.bag,o.id,1) then d.bp=d.bp-o.cost;persist();C.shop() end
end}
end
rows[#rows+1]={label='BACK',run=C.back}
V.Gen3UI.show('BP EXCHANGE / '..tostring(data().bp or 0)..' BP',rows,'ITEMS GO TO YOUR NATIVE FIELD BAG',C.back)
end
function C.install()


if C.installed then return true end
local Runtime=req('src.core.game3.runtime');local original=Runtime.getSession
Runtime.getSession=function()
if C.battleSession and (C.depth or 0)>0 then return C.battleSession end
return original()
end




local Engine=req('src.core.game3.battle.engine')
local nativeBadge=Engine.hasBadge
Engine.hasBadge=function(st,n,...)
if st and st.cbeMtBattleChallenge==true and C.battleSession then
if n==8 then return true end
if n==3 then return false end
end
return nativeBadge(st,n,...)
end
C.installed=true;return true
end
function C.status()
local r=run();return {active=r~=nil,phase=r and r.status,floor=r and r.floor,saveError=C.saveError}
end
C.copy=copy
return C
