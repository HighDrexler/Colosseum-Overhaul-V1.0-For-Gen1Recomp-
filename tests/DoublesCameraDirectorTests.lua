local n=0;local function yes(v,k)n=n+1;assert(v,k)end
local function near(a,b,k)n=n+1;assert(math.abs(a-b)<1e-7,k..': '..a..' '..b)end
local V={};V.Mat4=assert(loadfile('lib/Mat4.lua'))();V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
local guarded=0;V.Camera={guardPose=function(_,p,arena,mode)assert(mode=='passive');guarded=guarded+1;return p end,
 sendoutShot=function()return {eye={12,19,61},focus={1,6,34},fov=.7,curve=0}end}
V.DoublesCamera=assert(loadfile('lib/doubles/CameraDirector.lua'))(V)
local C=V.DoublesCamera;local ids={'player-left','player-right','enemy-left','enemy-right'}
local base={eye={-39,32,60},focus={0,6,0},fov=.8}
for _,size in ipairs{{1280,720},{360,640}}do
 local ctx={groundY=0,arena={figureScale=.38,player={0,60},enemy={0,-60}},services={figureScale=.38,renderSize={width=size[1],height=size[2]}}}
 local s={core={slots={},turn=1},actors={},actorOrder={},visualClock=0}
 for i,id in ipairs(ids)do local token='token'..i;local r={slot=id,battlerId=token,actor={height=16,worldScale=1},visible=true}
  s.core.slots[id]=r;s.actors[token]=r;s.actorOrder[i]=r end
 local a=C.pose(base,s,ctx);local saved=a.eye[1];a.eye[1]=10000
 near(C.pose(base,s,ctx).eye[1],saved,'returned pose detached')
 for _,kind in ipairs{'move','damage','recall','faint','send'}do
  local r=s.actorOrder[1];local e={kind=kind,eventId=3,slot=r.slot,battlerId=r.battlerId,targets={'enemy-left'},targetBattlers={['enemy-left']='token3'}}
  if kind=='send'then r.sendout={phase=.3}else r.sendout=nil end
  s.core.currentEvent=e;s.core.eventTime=0;s.movePresentation={chapterAge=0,impactTime=.7}
  s.doublesCamera=nil;local p=C.pose(base,s,ctx)
  yes(C.status(s).shot~='command','event-specific '..kind)
  local before=p.eye[1]
  local finite=true
  for f=1,60 do s.visualClock=s.visualClock+1/60;s.core.eventTime=f/60;s.movePresentation.chapterAge=f/60
   if kind=='move' and f>=40 then s.movePresentation.impactStarted=true;s.movePresentation.impactAge=(f-40)/60 end
   p=C.pose(base,s,ctx)
   for _,xyz in ipairs{p.eye,p.focus}do for _,v in ipairs(xyz)do finite=finite and v==v and math.abs(v)<1e5 end end
  end
  yes(finite,'60 finite frames for '..kind)
  if kind=='move'then
   yes(C.status(s).shot=='impact','camera reaches impact');yes(math.abs(p.eye[1]-before)>.5,'not same static pose')
   local finalX=p.eye[1];s.movePresentation=nil;s.visualClock=s.visualClock+.1
   near(C.pose(base,s,ctx).eye[1],finalX,'finished channel does not recut same event')
  end
  local once=C.pose(base,s,ctx);for i=1,8 do local repeatPose=C.pose(base,s,ctx);near(repeatPose.eye[1],once.eye[1],'no draw-count camera acceleration')end
 end
 -- Spread launch includes both targets, not only the selected first slot.
 local e={kind='move',eventId=7,slot='player-right',battlerId='token2',targets={'enemy-left','enemy-right'},targetBattlers={['enemy-left']='token3',['enemy-right']='token4'}}
 s.core.currentEvent=e;s.movePresentation={chapterAge=0,impactTime=.7};s.doublesCamera=nil
 local p=C.pose(base,s,ctx);yes(C.status(s).shot=='transit','spread starts wide')
 local before=p.eye[1];e.presentationConsumed=true;s.visualClock=s.visualClock+.1
 near(C.pose(base,s,ctx).eye[1],before,'bookkeeping does not recut')
 C.adopt(s,{eye={7,8,9},focus={1,2,3},fov=.8});near(C.pose(base,s,ctx).eye[1],7,'manual return continuity')
end
-- Native Gen II facade and the real screen differ; doubles must resolve the
-- latter and retain ownership while a move runs, but not consume menu input.
local old=love;local mx,my=500,300;local button,home=2,false
love={graphics={getDimensions=function()return 1000,700 end},keyboard={isDown=function(k)return k=='home'and home end},mouse={getPosition=function()return mx,my end,isDown=function(k)return button==k end}}
local game={save={colosseumBattle={freeLookEnabled=true}}};local screen={game=game};local facade={game=game};local top=screen;game.stack={top=function()return top end}
local d={screen=screen,core={id='battle',phase='command'},consumer={states={battle={page='commands'}}}}
V.DoublesRuntime={presentation=function(b)if b==facade then return d end end};local F=assert(loadfile('lib/FreeLookCamera.lua'))(V)
local ctx={battle=facade,game=game,arena={}};yes(F.allowed(ctx),'real Gen II screen allowed');yes(not F.pose(ctx,base),'drag initialization')
mx=540;local p=F.pose(ctx,base);yes(p,'RMB orbit');local manual=p.eye[1];button=false;d.core.phase='present'
near(F.pose(ctx,base).eye[1],manual,'automatic attack cannot steal manual pose')
top={};yes(not F.allowed(ctx),'covered UI input blocked');near(F.pose(ctx,base).eye[1],manual,'covered UI retains pose without polling');top=screen
d.core.phase='command';d.consumer.states.battle.page='bag';yes(not F.allowed(ctx),'Bag blocks drag');d.consumer.states.battle.page='commands'
home=true;yes(not F.pose(ctx,base) and not F.state.focus,'Home returns director');home=false
mx=500;button=2;F.pose(ctx,base);mx=550;yes(F.pose(ctx,base),'second drag');game.save.colosseumBattle.freeLookEnabled=false
 yes(not F.pose(ctx,base) and not F.state.focus,'toggle off releases camera');love=old
-- Verified source prop's +Z basis must point at the destination for all quadrant/lane
-- combinations. Capture animation retains its original matrix branch.
V.TrainerRig=assert(loadfile('lib/TrainerRig.lua'))();V.BattleSides={other=function()end};V.TrainerMorph={dense=function()return false end};local P=assert(loadfile('lib/PlayerTrainer.lua'))(V)
local asset={bounds={min={-1,-1,-1},max={1,1,1},center={0,0,0}}}
for _,target in ipairs{{0,4,-20},{14,4,-25},{-14,4,25},{0,4,60}}do
 local start={2,4,35};local yaw=P._test.throwFacing(start,target)
 local m=P._test.sourceBallModel(asset,{2,4,35,kind='sendout',yaw=yaw})
 local dx,dz=target[1]-start[1],target[3]-start[3];local len=math.sqrt(dx*dx+dz*dz);local sc=math.sqrt(m[3]^2+m[11]^2)
 near(m[3]/sc,dx/len,'ball front X');near(m[11]/sc,dz/len,'ball front Z')
end
near(P._test.throwFacing({0,0,0},{0,0,0}),0,'zero displacement safe')
yes(guarded>10,'director/manual use arena safety guard')
print('DoublesCameraDirectorTests: '..n..' checks passed (finite-frame workload included)')
