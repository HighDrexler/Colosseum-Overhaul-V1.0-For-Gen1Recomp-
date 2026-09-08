local n=0
local function eq(a,b,k)n=n+1;assert(a==b,k..': '..tostring(a)..' ~= '..tostring(b))end
local function yes(v,k)n=n+1;assert(v,k)end
local Core=assert(loadfile('lib/doubles/Core.lua'))()
local calls={items=0,legal=0}
local a={name=function(_,m)return m.species end,maxHP=function()return 100 end,newStages=function()return {}end,
 makeBattler=function(_,s)return {mon=s.mon,stages={}}end,withdraw=function()end,
 moves=function(_,s)calls.legal=calls.legal+1;return s.mon.moves end,
 moveDef=function(_,id)return {id=id,name=id,type='NORMAL',pp=20}end,
 supports=function()return true end,forced=function()end,targetMode=function()return 'foe'end,switchLocked=function()return false end,
 itemList=function()calls.items=calls.items+1;return {{id='POTION',available=3,count=3}}end}
local p,e={},{};for i=1,6 do p[i]={species='P'..i,hp=100,moves={{id='TACKLE',pp=10}}};e[i]={species='E'..i,hp=100,moves={{id='TACKLE',pp=10}}}end
local c=Core.new{id='snapshot-perf',adapter=a,playerParty=p,enemyParty=e}
c.phase='command';c.commandSlot='player-left'
local full=c:snapshot();eq(#full.party,6,'legacy party complete');eq(#full.items,1,'legacy Bag complete');eq(#full.moves,1,'legacy legal moves complete')
local function equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not equal(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
calls.items=0;calls.legal=0
for i=1,120 do c:snapshot{view='render',page='commands'} end
do
 local snap=c:snapshot{view='render',page='commands'}
 yes(equal(full.slots,snap.slots),'same complete four HUD records')
 eq(#snap.party,0,'hidden party not copied');eq(#snap.items,0,'hidden Bag not previewed');eq(#snap.moves,0,'hidden moves not rebuilt')
 snap.slots[1].portrait.species='MUTATED'
 eq(p[1].species,'P1','render snapshot remains detached')
end
eq(calls.items,0,'zero idle Bag constructions');eq(calls.legal,0,'zero idle legal-move scans')
local moves=c:snapshot{view='render',page='targets'};eq(#moves.moves,1,'target page has full moves');yes(moves.targets[1],'target legality retained')
local bag=c:snapshot{view='render',page='bag'};eq(#bag.items,1,'Bag page has inventory')
for _,page in ipairs{'party','item-party','item-moves'}do
 local s=c:snapshot{view='render',page=page};eq(#s.party,6,'party identity on '..page)
end
c.phase='replace'
eq(#c:snapshot{view='render',page='commands'}.party,6,'first forced-replacement draw has party')
c.phase='present';local start=calls.items
local s=c:snapshot{view='render',page='bag'};eq(#s.items,0,'old Bag page cannot do work during move');eq(calls.items,start,'no hidden preview')
-- Actual Runtime.update edge dispatch. No private command/state mutation is
-- skipped: core/presenter still update on every frame, UI gets all input edges.
local old=love;love=nil
local V={mod={},BattleAutoProgress={enabled=function()return true end}}
local D=assert(loadfile('lib/doubles/Runtime.lua'))(V)
local pressed=false;local snapshots,inputs,updates=0,0,0
local core={id='idle',ticket=1,phase='command',snapshot=function()snapshots=snapshots+1;return {}end,
 update=function()updates=updates+1 end}
local session={core=core,inputHeld={},screen={game={input={isDown=function(_,key)return key=='a' and pressed end}}},consumer={input=function()inputs=inputs+1 end}}
for i=1,120 do D.update(session,1/60)end
eq(snapshots,1,'one idle input snapshot not one per frame');eq(inputs,1,'idle UI dispatch bounded');eq(updates,120,'simulation never skipped')
pressed=true;D.update(session,1/60);eq(inputs,2,'new button edge delivered')
D.update(session,1/60);eq(inputs,2,'held key not double-submitted')
pressed=false;D.update(session,1/60);core.ticket=2;D.update(session,1/60);eq(inputs,3,'new command owner resets UI')
core.phase='present';D.update(session,1/60);eq(inputs,4,'phase transition delivered')
love=old
print('DoublesPerformanceTests: '..n..' assertions passed')
