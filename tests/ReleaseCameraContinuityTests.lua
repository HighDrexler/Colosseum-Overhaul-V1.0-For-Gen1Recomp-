local checks=0
local function yes(v,label)checks=checks+1;assert(v,label)end
local function near(a,b,label)yes(math.abs(a-b)<1e-7,label)end
local now=0
love={timer={getTime=function()return now end},system={getOS=function()return 'Windows'end},
  graphics={getDimensions=function()return 1280,720 end},keyboard={isDown=function()return false end}}
local base={eye={58,20,0},focus={0,6,0},fov=.8}
local arena={figureScale=.38,player={0,50},enemy={0,-50},camera={side=58}}
local game={save={options={speedBattle=1}}};local ctx={game=game,battle={game=game,kind='wild'},arena=arena}
local function run(trainers,speed)
  now=0;game.save.options.speedBattle=speed
  local actor={shouldRender=function()return trainers end}
  local C=assert(loadfile('lib/Camera.lua'))({Trainer=actor,PlayerTrainer=actor})
  C:begin(ctx);C:event(ctx,'battle.turn_started',{})
  local poses={};local minRadius=10000;local maxZ,minZ=-10000,10000;local cuts=0;local prev
  for i=1,2400 do
    now=now+1/60
    for j=1,speed do C:update(ctx,1/60)end
    local p=C:shot(ctx,'command',0,base,arena)
    for _,v in ipairs{p.eye[1],p.eye[2],p.eye[3],p.focus[1],p.focus[2],p.focus[3],p.fov}do yes(v==v and math.abs(v)<1000,'finite bounded pose')end
    if i>180 then
      local radius=math.sqrt((p.eye[1]-p.focus[1])^2+(p.eye[3]-p.focus[3])^2)
      minRadius=math.min(minRadius,radius);minZ=math.min(minZ,p.eye[3]);maxZ=math.max(maxZ,p.eye[3])
      if prev and math.abs(prev.eye[1]-p.eye[1])>30 then cuts=cuts+1 end
    end
    local again=C:shot(ctx,'command',0,base,arena);near(again.eye[1],p.eye[1],'repeat draw cannot move camera')
    poses[i]=p;prev=p
  end
  if trainers then
    yes(maxZ-minZ>9,'trainer command framing varies');yes(minRadius>55,'trainer framing remains broad')
  else
    yes(cuts>=2,'opposing idle viewpoints cut');yes(minRadius>35,'idle transitions never traverse arena centre')
  end
  return poses
end
for _,trainers in ipairs{false,true}do
  local a,b=run(trainers,1),run(trainers,4)
  for i=1,#a do for k=1,3 do near(a[i].eye[k],b[i].eye[k],'1x/4x presentation-equivalent eye')end end
end
-- A fresh render context at the SAME visual clock must not reset doubles
-- interpolation, even when the current event changes before the next update.
local V={DoublesPresenter={anchor=function(_,id)return id=='player-left' and 10 or -10,id=='player-left' and 20 or -20 end},
  Camera={guardPose=function(_,p)return p end}}
local D=assert(loadfile('lib/doubles/CameraDirector.lua'))(V)
local s={core={slots={}},actors={},actorOrder={},visualClock=0}
for _,id in ipairs{'player-left','enemy-left'}do local r={slot=id,battlerId=id,actor={height=16},visible=true};s.core.slots[id]=r;s.actors[id]=r;s.actorOrder[#s.actorOrder+1]=r end
local function context()return {arena=arena,services={renderSize={width=1280,height=720}}}end
local a=D.pose(base,s,context());s.core.currentEvent={kind='damage',slot='enemy-left',battlerId='enemy-left',eventId=1}
local b=D.pose(base,s,context())
for i=1,3 do near(a.eye[i],b.eye[i],'new context same clock retains doubles eye');near(a.focus[i],b.focus[i],'new context same clock retains doubles focus')end
s.visualClock=.016;local c=D.pose(base,s,context());yes(math.abs(c.focus[3]-b.focus[3])>0,'doubles advances on next presentation update')
local d=D.pose(base,s,context());near(c.focus[3],d.focus[3],'repeat fresh context does not accelerate doubles camera')
print('ReleaseCameraContinuityTests: '..checks..' checks PASS; 40-second 1x/4x tracks, idle cuts, trainer framing, doubles context lifetime')
