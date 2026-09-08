local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end

local catalogSrc=read("lib/ArenaCatalog.lua")
local cameraSrc=read("lib/Camera.lua")
assert(catalogSrc:find("shotRadiusScale=0.72",1,true),"Pyrite lower-bowl radial compression missing")
assert(catalogSrc:find("shotHeightScale=0.72",1,true),"Pyrite lower-bowl elevation compression missing")
assert(catalogSrc:find("maxRadius=43",1,true),"Pyrite gallery-safe max radius missing")
assert(catalogSrc:find("maxY=22.5",1,true),"Pyrite gallery-safe max height missing")
assert(cameraSrc:find("shotRadiusScale",1,true) and cameraSrc:find("shotHeightScale",1,true),"Camera does not consume venue shot compression")

local Camera=assert(loadfile("lib/Camera.lua"))({})
local arena={
  id="pyrite_colosseum",
  visualPlayer={-5.0,18.0},visualEnemy={5.0,-18.0},
  camera={side=59,back=18,height=20.8,lookX=0,lookY=6.0,frameH=51,shotRadiusScale=0.72,shotHeightScale=0.72,
    safe={minRadius=24,maxRadius=43,minY=6.5,maxY=22.5,maxPitch=19.5,minPitch=-9,minFov=31,maxFov=50}},
}
local ctx={battle={kind="trainer",game={save={options={speedBattle=1}}}}}
local base={eye={58,21,2},focus={0,6,0},fov=math.rad(40)}
local function assertSafe(pose,label)
  assert(pose and pose.eye and pose.focus,label.." missing pose")
  local dx=pose.eye[1]-pose.focus[1];local dy=pose.eye[2]-pose.focus[2];local dz=pose.eye[3]-pose.focus[3]
  local r=math.sqrt(dx*dx+dy*dy+dz*dz)
  assert(r<=43.05,label.." escaped lower bowl radius: "..tostring(r))
  assert(pose.eye[2]<=22.55,label.." escaped lower bowl height: "..tostring(pose.eye[2]))
  assert(pose.eye[2]>=6.45,label.." fell below arena camera floor: "..tostring(pose.eye[2]))
end

Camera:begin(ctx)
-- The host base camera is deliberately outside Pyrite's lower bowl. The final
-- blend must still be clamped on frame zero / early intro, not only once the
-- authored target has finished blending in.
assertSafe(Camera:shot(ctx,"intro",0,base,arena),"intro-frame-zero")
for i=1,2 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"intro",0,base,arena),"intro-early-blend")
for i=1,18 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"intro",0,base,arena),"intro")
for i=1,90 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"command",0,base,arena),"passive")
Camera:event(ctx,"battle.move_used",{side="player"})
for i=1,12 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"attack",0,base,arena),"attack")
Camera:event(ctx,"battle.damage_dealt",{target="enemy",attacker="player",damage=3,maxHp=20})
for i=1,18 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"damage",0,base,arena),"damage")

print("PyriteCameraSafetyTests PASS")
return true
