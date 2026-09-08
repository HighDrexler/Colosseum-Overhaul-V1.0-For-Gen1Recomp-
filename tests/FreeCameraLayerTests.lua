local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local function near(a,b,k)yes(math.abs(a-b)<1e-7,k..' '..tostring(a)..'/'..tostring(b))end
local mx,my,button=500,300,nil;local home,shift=false,false;local touches={};local points={}
love={graphics={getDimensions=function()return 1000,700 end},keyboard={isDown=function(k)return k=='home' and home or (k=='lshift' and shift)end},
 mouse={getPosition=function()return mx,my end,isDown=function(b)return b==button end},
 touch={getTouches=function()return touches end,getPosition=function(id)return points[id][1],points[id][2]end}}
local screen={};local game={save={colosseumBattle={freeLookEnabled=true}}};screen.game=game
local battle={game=game};local top=screen;game.stack={top=function()return top end}
local d={screen=screen,core={id='demo',phase='command'},consumer={states={demo={page='commands'}}}}
local V={DoublesRuntime={presentation=function(b)if b==battle then return d end end}}
local F=assert(loadfile('lib/FreeLookCamera.lua'))(V)
local ctx={battle=battle,game=game,arena={}}
local base={eye={15,20,60},focus={0,6,0},fov=.8,curve=.2}
local nextBase={eye={-27,15,-38},focus={4,7,-20},fov=.62,curve=.4}
yes(not F.pose(ctx,base),'enabled without input preserves exact automatic shot')
button=2;F.pose(ctx,base);mx=580;my=240;local first=assert(F.pose(ctx,base));button=nil
local yaw,pitch=F.state.yawOffset,F.state.pitchOffset
yes(math.abs(yaw)>.1 and pitch>.1,'vertical and horizontal orbit available')
for _,phase in ipairs{'command','present','resolving','replace'}do
 d.core.phase=phase
 local a=F.pose(ctx,base);local b=F.pose(ctx,nextBase)
 yes(math.abs(a.eye[1]-b.eye[1])>5,'auto shot moves below layer: '..phase)
 near(b.fov,nextBase.fov,'auto lens preserved')
 near(F.state.yawOffset,yaw,'auto shot does not rewrite manual yaw')
 near(F.state.pitchOffset,pitch,'auto shot does not rewrite manual pitch')
 near(nextBase.eye[1],-27,'source pose immutable');near(base.eye[3],60,'base immutable')
end
-- Covered menus block input, but a new scripted pose still flows through.
top={};yes(not F.allowed(ctx),'modal UI blocks gesture');button=2;mx=630;my=180
local held=F.pose(ctx,nextBase);near(F.state.yawOffset,yaw,'no input stolen from modal')
yes(math.abs(held.eye[1]-first.eye[1])>5,'covered UI does not freeze director')
top=screen;button=nil;d.core.phase='command'
F.pose(ctx,base)
yes(F.wheel(game,0,3),'wheel zoom owned in arena')
local nearPose=F.pose(ctx,base)
local function radius(p)return math.sqrt((p.eye[1]-p.focus[1])^2+(p.eye[2]-p.focus[2])^2+(p.eye[3]-p.focus[3])^2)end
yes(radius(nearPose)<radius(base),'wheel moves closer')
for i=1,30 do F.wheel(game,0,8)end;near(math.exp(F.state.zoomLog),.60,'close limit')
for i=1,30 do F.wheel(game,0,-8)end;near(math.exp(F.state.zoomLog),1.65,'far limit')
mx=50;yes(not F.wheel(game,0,1),'wheel outside arena forwarded');mx=500
-- Engine hooks chain both generations, without replacing map/menu wheel behavior.
local calls1,calls2=0,0;local G1={wheelmoved=function()calls1=calls1+1;return 'map1'end};local G2={wheelmoved=function()calls2=calls2+1;return 'map2'end}
package.loaded['src.core.Game']=G1;package.loaded['src.core.Game2']=G2
yes(F.install()==2 and F.install()==0,'wheel hooks idempotent')
yes(G1.wheelmoved(game,0,1)==true and calls1==0,'Gen I owns battle wheel')
yes(G2.wheelmoved(game,0,1)==true and calls2==0,'Gen II owns battle wheel')
top={};yes(G1.wheelmoved(game,0,1)=='map1' and calls1==1,'Gen I forwards modal wheel')
yes(G2.wheelmoved(game,0,1)=='map2' and calls2==1,'Gen II forwards modal wheel');top=screen
-- Two touches pinch and vertical pan within the same arena-only input gate.
F.reset();touches={11,22};points[11]={400,300};points[22]={600,300};F.pose(ctx,base)
points[11]={350,260};points[22]={650,260};yes(F.pose(ctx,base),'pinch accepted')
yes(F.state.zoomLog<0 and F.state.panY>0,'pinch zoom and independent height pan')
touches={};home=true;yes(not F.pose(ctx,base) and not F.state.active,'Home resets relative layer');home=false
button=2;F.pose(ctx,base);mx=530;F.pose(ctx,base);game.save.colosseumBattle.freeLookEnabled=false
yes(not F.pose(ctx,base) and not F.state.active,'toggle OFF discards offsets');button=nil
-- Explicitly emulate LuaJIT's one-argument math.atan (without math.atan2).
local oldAtan,oldAtan2=math.atan,math.atan2;math.atan=function(x)return oldAtan(x)end;math.atan2=nil
local F51=assert(loadfile('lib/FreeLookCamera.lua'))({})
for _,eye in ipairs{{-10,8,-20},{10,8,-20},{-10,-8,20},{10,-8,20}}do
 local p=F51.compose({eye=eye,focus={0,0,0},fov=.8},{})
 -- Negative camera pitch here is ~-19.7, so test bounded expectations separately.
 if eye[2]>0 then for i=1,3 do near(p.eye[i],eye[i],'atan quadrant reconstruction')end end
 yes(p.eye[1]*eye[1]>0 and p.eye[3]*eye[3]>0,'all four quadrants retained')
end
local C=assert(loadfile('lib/Camera.lua'))({})
local requested={eye={0,25,18},focus={0,14,0},fov=.8}
local auto=C:guardPose(requested,{},'passive');local free=C:guardFreePose(requested,{})
yes(free.focus[2]>auto.focus[2]+4,'manual focus not narrow automatic height band')
yes(free.eye[2]>free.focus[2]+2,'LuaJIT-compatible pitch is not clamped from atan misuse')
yes(free.eye[2]<=32,'venue ceiling remains bounded')
math.atan,math.atan2=oldAtan,oldAtan2
local f=assert(io.open('lib/StandaloneHost.lua','rb'));local source=f:read('*a');f:close()
yes(not source:find('DoublesCamera.adopt',1,true),'host never feeds manual pose into director')
print('FreeCameraLayerTests: '..checks..' checks passed; mouse/touch/engine inputs simulated')
