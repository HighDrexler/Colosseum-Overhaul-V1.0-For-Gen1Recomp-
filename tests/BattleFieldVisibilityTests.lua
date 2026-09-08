-- ROM-free structural absence and live/native-string attachment regression.
local n=0;local function eq(a,b,m)n=n+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
local function yes(a,m)n=n+1;assert(a,m)end
local V={}
local A=assert(loadfile('lib/doubles/NativeAdapter.lua'))(V)
local Core=assert(loadfile('lib/doubles/Core.lua'))()
for _,gen in ipairs{1,2}do
 local mon={hp=100,volatile={}};local b={mon=mon};local slot={battlerId='first',mon=mon,battler=b,stages={}}
 local adapter=setmetatable({generation=gen},{__index=A})
 local c=setmetatable({adapter=adapter,slots={['player-left']=slot},queue={},display={},turn=1},{__index=Core})
 -- Only use the populated positions; real Core always owns all four.
 for _,id in ipairs{'player-right','enemy-left','enemy-right'}do c.slots[id]={}end
 local emitted={};c.enqueue=function(_,e)emitted[#emitted+1]=e end
 b.picHidden=true;b.spriteHidden=true
 eq(adapter:structuralHidden(slot),false,'ordinary picture hiding is not absence '..gen)
 local before=c:captureVitals()
 if gen==1 then b.invulnerable=true else mon.volatile.vanished=true end
 local move={kind='move',battlerId='first',slot='player-left',stage='charge',targetBattlers={}}
 c:recordVitals(before,move)
 eq(move.structuralHiddenBefore,false,'immutable precharge state '..gen)
 eq(move.structuralHiddenAfter,true,'postcharge state '..gen)
 eq(emitted[1].kind,'visibility','semantic transition queued '..gen);eq(emitted[1].hidden,true,'hide after departure '..gen)
 before=c:captureVitals();b.invulnerable=nil;mon.volatile.vanished=nil
 c:recordVitals(before) -- No move event: cancelled/interrupted charge.
 eq(emitted[2].hidden,false,'interruption without attack restores presence '..gen)
 eq(move.structuralHiddenAfter,true,'mutable native state never changes old event '..gen)
 before=c:captureVitals();slot.battlerId='replacement';b.invulnerable=true;mon.volatile.vanished=true
 c:recordVitals(before)
 eq(#emitted,2,'old occupant cannot alter replacement '..gen)
end
V.WazaHandlers={actorVisible=function()return true end,controllers={}}
V.WazaSequenceRuntime={update=function()end}
V.CurrentSpriteModels={clearDoublesWaza=function()end,updateReleaseFx=function()end,withDoublesPair=function(_,ctx,r,fn)return fn(ctx)end}
V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
V.DoublesMovePresentation=assert(loadfile('lib/doubles/MovePresentation.lua'))(V)
local M,P=V.DoublesMovePresentation,V.DoublesPresenter
for _,id in ipairs{'player-left','player-right','enemy-left','enemy-right'}do
 local r={slot=id,battlerId=id..':1',visible=true};local replacement={slot=id,battlerId=id..':2',visible=true}
 local s={actors={[r.battlerId]=r,[replacement.battlerId]=replacement},core={slots={[id]=replacement}},context={}}
 local e={kind='move',slot=id,battlerId=r.battlerId,move='DIG',stage='charge',targets={id},targetBattlers={[id]=r.battlerId},structuralHiddenBefore=false,structuralHiddenAfter=true}
 M.begin(s,e);eq(M.visible(s,r),true,'departure visible '..id)
 M.finish(s,true);eq(M.visible(s,r),false,'hidden with no active source chapter '..id)
 eq(M.visible(s,replacement),true,'same slot new token never hidden '..id)
 s.movePresentation={sourceBattlerId='partner',targetBattlerId='opponent'}
 eq(M.visible(s,r),false,'hidden through other actions '..id);s.movePresentation=nil
 e.stage='attack';e.release=true;e.structuralHiddenBefore=true;e.structuralHiddenAfter=false
 M.begin(s,e);eq(M.visible(s,r),true,'release visible before attack even on miss '..id);M.finish(s,true)
 P.event(s,{kind='visibility',battlerId=r.battlerId,hidden=true});eq(M.visible(s,r),false,'hide event applied '..id)
 P.event(s,{kind='visibility',battlerId=r.battlerId,hidden=false});eq(M.visible(s,r),true,'cancel event applied '..id)
 r.structuralHidden=true;P.event(s,{kind='faint',battlerId=r.battlerId});eq(M.visible(s,r),true,'terminal lifecycle restores actor '..id)
end
-- Hidden sprite fallback follows the same structural gate as source actors.
local oldLove=love;local draws=0
love={graphics={push=function()end,pop=function()end,setShader=function()end,setDepthMode=function()end,setColor=function()end,draw=function()draws=draws+1 end}}
V.PokemonActors={service={worldUnits=false}};V.CurrentSpriteModels.drawn={};V.CurrentSpriteModels.presented={}
local image={getDimensions=function()return 32,32 end}
local a={slot='player-left',battlerId='a',visible=true,spriteMode=true,structuralHidden=true,battler={sprite=image}}
local b={slot='enemy-right',battlerId='b',visible=true,spriteMode=true,battler={sprite=image}}
local s={actorOrder={a,b},actors={a=a,b=b},core={slots={}},generation=1}
local ctx={arena={player={0,20},enemy={0,-20}},services={vp={},project=function()return 100,100 end,renderSize={height=720}}}
P.draw(s,ctx);eq(draws,1,'Models OFF hides underground/airborne sprite only')
a.structuralHidden=false;P.draw(s,ctx);eq(draws,3,'Models OFF release restores sprite')
love=oldLove
-- A zero-duration invisible event never asks for a manual dialogue advance.
local c=setmetatable({clock=0,phase='present',eventTime=0,autoProgress=false,currentEvent={kind='visibility',automatic=true,duration=0}}, {__index=Core})
local advanced=false;c.presentNext=function()advanced=true end;c:update(.016,false);eq(advanced,true,'visibility transition requires no extra A press')
-- Actual singles visibility helper, both generation records; ordinary hit
-- picture flags retain the persistent source actor contract.
local C=assert(loadfile('lib/CurrentSpriteModels.lua'))({})
local b1={mon={hp=100},picHidden=true};local actor={lastMove='DIG'}
local context={battle={player=b1},sides={player={battler=b1}}}
eq(C._test.actorVisible(context,'player',actor),true,'single hit blink remains visible')
b1.invulnerable=true;eq(C._test.actorVisible(context,'player',actor),false,'Gen I Dig native absence without facade')
actor.cbeStructuralDeparture=true;actor.action='attack';eq(C._test.actorVisible(context,'player',actor),true,'departure bank not skipped')
actor.action=nil;eq(C._test.actorVisible(context,'player',actor),false,'departure completion hides actor')
b1.invulnerable=nil;eq(C._test.actorVisible(context,'player',actor),true,'Gen I interruption restores presence')
b1.mon.volatile={vanished=true};actor.lastMove='FLY';eq(C._test.actorVisible(context,'player',actor),false,'Gen II volatile absence')
b1.mon.volatile.vanished=nil;eq(C._test.actorVisible(context,'player',actor),true,'Gen II release visible')
print('BattleFieldVisibilityTests: '..n..' assertions passed')
