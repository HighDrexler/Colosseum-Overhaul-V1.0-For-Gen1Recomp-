

local V=...
local req=V.engineRequire or require
local H={}
local function challenge() return V.Gen3Challenge end
local function data() return V.Gen3Runtime.data() end
local function session() return V.Gen3Runtime.session(V.Gen3Runtime.game or V.mod.game) end
local function save()
local game=V.Gen3Runtime.game or V.mod.game
local ok,result=pcall(game.saveGame,game)
return ok and result~=false
end
function H.active() return H.owner~=nil end
function H.close(reason)
local owner=H.owner;if not owner then return end
local Stack=req('src.ui.game3.stack')
for _,state in ipairs(owner.stack.states) do Stack.pop(state.__gen3HubId) end
V.MtBattleHubStage.endSession(reason or 'hub-closed')
H.owner=nil;H.draft=nil
end
function H.present(draw)
local surface=V.StandaloneHost.renderHubFrame()
return V.Gen3Screens.present('mt-battle-hub',draw,surface)
end
function H.pump(dt)
if H.owner then V.StandaloneHost.update(dt) end
end
local function returnToHub()
V.Gen3UI.close(true)
end
local function show(title,rows,footer)
rows[#rows+1]={label='BACK TO SETUP',run=returnToHub}
return V.Gen3UI.show(title,rows,footer,returnToHub)
end
function H.records()
local d=data();local r=d.challenge;local records=d.records or {}
local rows={
{label='COMPLETED RUNS: '..tostring(records.clears or 0)},
{label='BEST CLEAR: '..tostring(records.best or 0)..' WINS'},
{label='CURRENT RUN: '..(r and (r.status:upper()..' / '..tostring(r.wins)..' WINS') or 'NONE')},
{label='BP BALANCE: '..tostring(d.bp or 0)},
{label='XP BANK: '..tostring(d.xpBank or 0),run=challenge().xp},
{label='BP EXCHANGE',run=challenge().shop},
}
if r and r.status=='ready' then
rows[#rows+1]={label='SCOUT NEXT TRAINER',run=function()
local opponents={};local P=req('src.core.game3.pokemon')
for _,mon in ipairs(challenge().opponents(r)) do opponents[#opponents+1]={label=P.displayMonName(mon)..' / LV. 50'} end
show('NEXT OPPONENT',opponents,'BATTLE '..r.floor..' / '..r.total)
end}
rows[#rows+1]={label='CHALLENGE TEAM / MOVE PREP',run=challenge().team}
end
show('MT. BATTLE RECORDS',rows,'RUN PROGRESS AND REWARDS ARE SAVED WITH YOUR GAME')
end
local function makeOwner()
local real=V.Gen3Runtime.game or V.mod.game
local d=data();local s=session();local P=req('src.core.game3.pokemon')
V.Gen3Runtime.prefs(real)


local prefs=setmetatable({arena='mt_battle_summit',doubleBattlesEnabled=true,arenasEnabled=true},
{__index=d.prefs,__newindex=function(_,key,value) d.prefs[key]=value end})
local owner=setmetatable({save={generation=3,party=s.party,colosseumBattle=prefs},
data={pokemon=setmetatable({},{__index=function(_,id) return {name=P.name(id)} end})}}, {__index=real})
local r=d.challenge
if r and (r.status=='ready' or r.status=='lost') then owner.save.party=r.team end
owner.save.mtBattleChallenge={active=r and (r.status=='ready' or r.status=='lost') or false,
currentFight=r and r.floor or 1,totalFights=r and r.total or 100,continues=r and r.continues or 1}
owner.stack={states={}}
local stack=owner.stack;local Native=req('src.ui.game3.stack')
function stack:top() return self.states[#self.states] end
function stack:pop()
local state=table.remove(self.states)
if state then Native.pop(state.__gen3HubId) end
return state
end
function stack:push(state)
H.serial=(H.serial or 0)+1;state.__gen3HubId='cbe-mtb-'..H.serial
self.states[#self.states+1]=state
local layer={}
function layer.handleInput(input)
owner.input=input
state:update(0)
end
function layer.draw()
H.present(function(w,h)
local _,why=V.MtBattleHubScreens.draw(state,{width=w,height=h})
if why then error(why,0) end
end)
end
Native.push(state.__gen3HubId,layer,{fullscreen=true})
end
H.owner=owner
local ok,why=V.MtBattleHubStage.beginBeat(owner,'wes','MT. BATTLE')
if not ok then H.close('setup-failed');return nil,why or V.StandaloneHost.lastError end
return owner
end
local review
local function selectTeam()
local owner=H.owner;local P=req('src.core.game3.pokemon');local s=session()
local candidates={};local lookup={party={},pc={},rental={}}
local function add(mon,source,index,box,slot)
if not mon or P.isEgg(mon) then return end
local copy=challenge().clone(mon);local dex=P.national(P.speciesOf(mon))
candidates[#candidates+1]={source=source,index=index,box=box,slot=slot,
species=copy.species,dex=dex,generation=dex<=151 and 1 or dex<=251 and 2 or 3,
nickname=P.displayMonName(copy),level=50}
lookup[source][source=='pc' and (box..':'..slot) or index]=copy
end
for i,mon in ipairs(s.party or {}) do add(mon,'party',i) end
for box=1,14 do
local b=s.storage and s.storage.boxes and s.storage.boxes[box]
for slot=1,30 do add(b and b.mons and b.mons[slot],'pc',nil,box,slot) end
end
local rng=V.MtBattleSeedManager.newStream(47231)
for dex=1,386 do add(challenge().makeMon(dex,rng,5),'rental',dex) end
V.MtBattleHubScreens.pushTeamSelect(owner,candidates,function(rows)
H.draft={}
for i,row in ipairs(rows) do
local key=row.source=='pc' and (row.box..':'..row.slot) or row.index
H.draft[i]=challenge().clone(assert(lookup[row.source][key]))
end
end,nil,H.total)
end
function H.customTeams()
local d=data();d.customTeams=d.customTeams or {};local rows={}
rows[#rows+1]={label='SAVE PREPARED TEAM',run=function()
if #H.draft~=6 then V.Gen3UI.menu.footer='CHOOSE EXACTLY SIX POKEMON FIRST';return end
if #d.customTeams>=12 then V.Gen3UI.menu.footer='DELETE A TEAM FIRST / 12 TEAM LIMIT';return end
local team={};for i,m in ipairs(H.draft) do team[i]=challenge().clone(m) end
d.customTeams[#d.customTeams+1]=team
if not save() then table.remove(d.customTeams);V.Gen3UI.menu.footer='SAVE FAILED';return end
H.customTeams()
end}
for i in ipairs(d.customTeams) do local slot=i
rows[#rows+1]={label='TEAM '..slot..' / LOAD OR DELETE',run=function()
show('CUSTOM TEAM '..slot,{
{label='LOAD TEAM',run=function()
H.draft={};for n,m in ipairs(d.customTeams[slot]) do H.draft[n]=challenge().clone(m) end
returnToHub()
end},
{label='DELETE TEAM',run=function()
local team=table.remove(d.customTeams,slot)
if not save() then table.insert(d.customTeams,slot,team);V.Gen3UI.menu.footer='SAVE FAILED';return end
H.customTeams()
end},
},'DETACHED CHALLENGE TEAM / YOUR OWNED POKEMON ARE KEPT')
end}
end
show('CUSTOM TEAMS',rows,'SAVED CHALLENGE TEAMS / UP TO 12')
end
review=function(total)
H.total=total
V.MtBattleHubScreens.pushTeamReview(H.owner,{
generation=3,totalFights=total,onSave=save,onRecords=H.records,
teamProvider=function() return H.draft end,
onRental=selectTeam,onCustomTeams=H.customTeams,onMovePrep=challenge().team,
onStart=function(closeSelf)
if #H.draft~=6 then H.owner.stack:top().saveMessage='CHOOSE EXACTLY SIX POKEMON';return end
local ok,why=challenge().new('prepared',total,H.draft)
if not ok then H.owner.stack:top().saveMessage=why;return end
closeSelf()
H.open()
end,
onCancel=function() V.Gen3UI.home() end,
})
end
function H.open()
if req('src.core.game3.battle').isActive() then return false,'Finish the current battle first' end
V.Gen3UI.close(true);H.close('setup-reopened')
V.Gen3Audio.lobby()
local C=challenge();local r=data().challenge
if r and r.status=='in_battle' then
r.status='ready';req('src.core.game3.party').healAll(r.team)
end
local owner,why=makeOwner()
if not owner then
V.Gen3UI.show('MT. BATTLE PREPARATION',{{label='RETRY',run=H.open},{label='BACK',run=V.Gen3UI.home}},
tostring(why or 'Summit assets unavailable'),V.Gen3UI.home)
return false,why
end
if r and (r.status=='ready' or r.status=='lost') then
H.draft=r.team
V.MtBattleHubScreens.pushActiveRunControl(owner,{
onRecords=H.records,
onResume=function()
if r.status=='lost' then
if (r.continues or 0)<=0 then return false,'NO CONTINUES LEFT / END THIS RUN TO PREPARE ANOTHER' end
local previous=challenge().copy(r.team)
r.continues=r.continues-1;r.status='ready';req('src.core.game3.party').healAll(r.team)
if not save() then
r.continues=r.continues+1;r.status='lost';r.team=previous;H.draft=previous
return false,'SAVE FAILED'
end
end
local ok,why=C.launch()
if not ok then
H.open();H.owner.stack:top().message=tostring(why or 'BATTLE COULD NOT START')
end
return true
end,
onSuspend=function() if not save() then return false,'SAVE FAILED' end;V.Gen3UI.close();return true end,
onEndRun=function()
local previous=r.status;r.status='ended'
if not save() then r.status=previous;return false,'SAVE FAILED' end
H.open();return true
end,
})
else
H.draft={};for _,mon in ipairs(session().party or {}) do
if not req('src.core.game3.pokemon').isEgg(mon) then H.draft[#H.draft+1]=C.clone(mon) end
end
V.MtBattleHubScreens.pushClimbSetup(owner,{
totalFights=r and r.total or 100,onSave=save,onRecords=H.records,
onRewards=C.shop,onTeamSetup=review,
onCancel=V.Gen3UI.home,
})
end
return true
end
H.returnToHub=returnToHub
return H
