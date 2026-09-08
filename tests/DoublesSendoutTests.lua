local Core=assert(loadfile('lib/doubles/Core.lua'))({})
local calls,clears=0,0
local phase=0
local trainer={beginSendout=function(_,p)calls=calls+1;assert(p[1]==-12 and p[3]==20,'ball did not target right lane');return 1.48 end,
 sendoutStatus=function()return {active=phase<1,phase=phase,age=phase*1.48} end,
 clearSendoutTarget=function()clears=clears+1 end}
local cameraCalls,guards=0,0
local V={PlayerTrainer=trainer,Trainer=trainer,CurrentSpriteModels={stadiumActors={},drawn={},presented={}},
 Camera={sendoutShot=function(_,ctx,arena,side)cameraCalls=cameraCalls+1;assert(side=='player');return {eye={10,10,10},focus={0,6,0},fov=.7} end,
 guardPose=function(_,pose)guards=guards+1;return pose end}}
local P=assert(loadfile('lib/doubles/Presenter.lua'))(V)
local ctx={groundY=0,arena={player={0,20},enemy={0,-20},mid={0,0}}}
-- spread is 11.2 at distance 40; use the exact computed lane in the assertion.
trainer.beginSendout=function(_,p)calls=calls+1;local x,z=P.anchor(ctx,'player-right');assert(p[1]==x and p[3]==z);return 1.48 end
local actor={spawn=function(self,p)self.scale=p end,update=function()end}
local s={context=ctx,core={slots={}},actors={b={actor=actor,visible=true,slot='player-right',battlerId='b'}},actorOrder={},visualClock=0}
s.actorOrder={s.actors.b}
local e={kind='send',slot='player-right',battlerId='b'};s.core.currentEvent=e
P.event(s,e);P.update(s,.05)
assert(calls==1 and actor.scale==0 and e.presentationPending,'sendout did not wait for ball arrival')
local base={eye={50,20,15},focus={0,5,0},fov=.8}
P.camera(base,s,ctx);assert(cameraCalls==1,'second throw bypassed shared camera')
phase=.5;P.update(s,.05);assert(actor.scale==0,'Pokemon appeared while ball was airborne')
-- Real Core advancement honours the presentation hold even with advance pressed.
local core=setmetatable({clock=0,phase='present',currentEvent=e,eventTime=5},{__index=Core})
core.presentNext=function(self)self.advanced=true end
core:update(.05,true);assert(not core.advanced and core.currentEvent==e,'held button skipped trainer throw')
phase=.80;P.update(s,.05);assert(actor.scale==0,'owner appeared before source ball-open timing')
for i=1,17 do P.update(s,.05)end;assert(actor.scale>0 and actor.scale<1,'source reveal did not begin')
P.camera(base,s,ctx);assert(guards==1,'arrival camera bypassed arena guard')
phase=1;for i=1,60 do P.update(s,.05)end
assert(actor.scale==1 and not e.presentationPending and clears==1,'sendout failed to release presentation queue')
core:update(.05,true);assert(core.advanced,'completed sendout blocked battle')
-- Transferred initial leads already had a native sendout and must not throw twice.
s.actors.b.transferred=true;P.event(s,e);assert(e.alreadyPresented and not s.actors.b.sendout)
local previous=calls;P.update(s,.05);P.camera(base,s,ctx);assert(calls==previous)
-- Enemy/right and player/right arrival views keep the base viewing side.
for _,id in ipairs({'player-left','player-right','enemy-left','enemy-right'})do
 s.core.currentEvent={kind='send',slot=id,battlerId='other'}
 local p=P.camera(base,s,ctx)
 assert((p.eye[1]-p.focus[1])*(base.eye[1]-base.focus[1])+(p.eye[3]-p.focus[3])*(base.eye[3]-base.focus[3])>0,'camera flipped behind arena')
end
print('DoublesSendoutTests: OK')

-- Initial pair: exactly one trainer performance, two protected releases.
local function paired(side)
 s.openingThrown={};local before=calls
 trainer.beginSendout=function()calls=calls+1;return 1.48 end
 for _,lane in ipairs({'left','right'})do
  local id=side..'-'..lane;local a={spawn=actor.spawn,update=actor.update}
  s.actors[id]={actor=a,visible=true,slot=id,battlerId=id};s.actorOrder={s.actors[id]}
  local event={kind='send',opening=true,slot=id,battlerId=id};s.core.currentEvent=event
  P.event(s,event);phase=0;P.update(s,.05)
  assert(s.actors[id].sendout.releaseOnly==(lane=='right'),'partner repeated trainer throw')
  phase=1;for i=1,60 do P.update(s,.05)end
  assert(not event.presentationPending and a.scale==1,'pair release never settled')
 end
 assert(calls==before+1,'pair must have exactly one throw')
end
paired('enemy');paired('player')
print('Grouped opening throw counts: OK')
