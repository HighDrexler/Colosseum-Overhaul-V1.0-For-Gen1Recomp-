local n=0
local function check(v,label)n=n+1;assert(v,label)end
local function near(a,b,label)check(math.abs(a-b)<1e-6,label)end
local Catalog=assert(loadfile('lib/ArenaCatalog.lua'))()
local def=Catalog.definition('orre_colosseum');local cam=def.camera
local Camera=assert(loadfile('lib/Camera.lua'))({})
local arena={id=def.id,camera=cam,figureScale=def.figureScale,visualPlayer=def.pokemon.player,visualEnemy=def.pokemon.enemy,
 player={def.pokemon.player[1]/def.figureScale,def.pokemon.player[2]/def.figureScale},enemy={def.pokemon.enemy[1]/def.figureScale,def.pokemon.enemy[2]/def.figureScale}}
local V={Camera=Camera};V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
local Doubles=assert(loadfile('lib/doubles/CameraDirector.lua'))(V)
local ctx={arena=arena,groundY=0,battle={kind='trainer',game={save={options={speedBattle=1}}}},services={renderSize={width=1280,height=720}}}
local radius=math.sqrt(cam.side^2+cam.back^2)
check(radius<49 and cam.safe.maxRadius<=52,'Orre camera still crosses the source rock perimeter')
check(cam.shotRadiusScale<1,'authored Orre shots did not move inside the bowl')
near(cam.height,18.5,'Orre eye height changed');near(def.figureScale,.335,'battler scale changed')
near(def.pokemon.player[2],16.8,'player source mark changed');near(def.pokemon.enemy[2],-16.8,'enemy source mark changed')
local function safe(p,label)
 local dx,dy,dz=p.eye[1]-p.focus[1],p.eye[2]-p.focus[2],p.eye[3]-p.focus[3]
 check(math.sqrt(dx*dx+dy*dy+dz*dz)<=52.001,label..' escaped Orre lens envelope')
 check(p.eye[2]>=cam.safe.minY and p.eye[2]<=cam.safe.maxY,label..' escaped eye height')
end
local function projected(p,point)
 local dx,dy,dz=p.focus[1]-p.eye[1],p.focus[2]-p.eye[2],p.focus[3]-p.eye[3]
 local len=math.sqrt(dx*dx+dy*dy+dz*dz);dx,dy,dz=dx/len,dy/len,dz/len
 local rlen=math.sqrt(dx*dx+dz*dz);local rx,rz=-dz/rlen,dx/rlen
 local ux,uy,uz=-rz*dy,rz*dx-rx*dz,rx*dy
 local qx,qy,qz=point[1]-p.eye[1],point[2]-p.eye[2],point[3]-p.eye[3]
 local depth=qx*dx+qy*dy+qz*dz;local t=math.tan(p.fov*.5)
 return (qx*rx+qz*rz)/(depth*t*16/9),(qx*ux+qy*uy+qz*uz)/(depth*t),depth
end
local ids={'player-left','player-right','enemy-left','enemy-right'}
local slots={};for _,id in ipairs(ids)do local x,z=V.DoublesPresenter.anchor(ctx,id);slots[#slots+1]={x,3,z}end
for i=0,7 do
 local angle=i*math.pi/4;local base={eye={math.cos(angle)*radius,cam.height,math.sin(angle)*radius},focus={0,cam.lookY,0},fov=math.rad(40)}
 safe(Camera:guardPose(base,arena,'passive'),'default angle '..i)
 local points={{arena.visualPlayer[1],3,arena.visualPlayer[2]},{arena.visualEnemy[1],3,arena.visualEnemy[2]}}
 for _,p in ipairs(slots)do points[#points+1]=p end
 for _,point in ipairs(points)do local x,y,d=projected(base,point);check(d>4 and math.abs(x)<.9 and math.abs(y)<.9,'default orbit lost singles/doubles source mark')end
 -- Doubles' actual director calculates its own range; its final result must
 -- still obey the same Orre venue limit while framing every occupied slot.
 for _,actorHeight in ipairs({16,60})do
  local s={core={slots={},turn=1},actors={},actorOrder={},visualClock=0}
  for k,id in ipairs(ids)do local rec={slot=id,battlerId='p'..k,actor={height=actorHeight,worldScale=1},visible=true};s.core.slots[id]=rec;s.actors[rec.battlerId]=rec;s.actorOrder[k]=rec end
  local p=Doubles.pose(base,s,ctx);safe(p,'doubles command angle '..i)
  for _,slot in ipairs(slots)do for _,height in ipairs({0,actorHeight*def.figureScale})do
   local point={slot[1],height,slot[3]};local x,y,d=projected(p,point)
   check(d>4 and math.abs(x)<.95 and math.abs(y)<.95,'Orre limit cropped doubles feet/head')
  end end
 end
end
local base={eye={56,18.5,17},focus={0,7,0},fov=math.rad(40)}
Camera:begin(ctx)
for _,event in ipairs{{'battle.move_used','attack',{side='player'}},{'battle.damage_dealt','damage',{target='enemy',attacker='player',damage=3,maxHp=20}},{'battle.battler_switched','switch',{side='player'}},{'battle.fainted','faint',{side='enemy'}}}do
 Camera:event(ctx,event[1],event[3]);for i=1,60 do Camera:update(ctx,1/30);safe(Camera:shot(ctx,event[2],0,base,arena),event[2])end
end
local SourceCamera=assert(loadfile('lib/Camera.lua'))({WazaHandlers={cameraPose=function()return {eye={-76,18.5,0},focus={0,7,0},fov=math.rad(40),blend=.2}end}})
SourceCamera:begin(ctx);SourceCamera:event(ctx,'battle.move_used',{side='player'});for i=1,20 do SourceCamera:update(ctx,.05)end
safe(SourceCamera:shot(ctx,'attack',0,base,arena),'native Waza camera')
print('PresentationFidelitySweepOrreCameraTests: '..n..' assertions passed')
return true
