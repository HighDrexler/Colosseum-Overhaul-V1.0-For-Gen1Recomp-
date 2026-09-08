local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local catalogSrc=read("lib/ArenaCatalog.lua")
local cameraSrc=read("lib/Camera.lua")
assert(catalogSrc:find("shotRadiusScale=0.60",1,true),"Relic radial compression missing")
assert(catalogSrc:find("shotHeightScale=0.42",1,true),"Relic height compression missing")
assert(catalogSrc:find("maxRadius=36",1,true),"Relic canopy-safe max radius missing")
assert(catalogSrc:find("maxY=13.5",1,true),"Relic canopy-safe max eye height missing")
assert(catalogSrc:find("minFocusY=4.5,maxFocusY=6.3",1,true),"Relic clean focus band missing")
assert(cameraSrc:find("spec.minFocusY",1,true) and cameraSrc:find("spec.maxFocusY",1,true),"Camera does not consume venue focus band")

local Camera=assert(loadfile("lib/Camera.lua"))({})
local arena={
  id="relic_chamber",
  visualPlayer={-4.0,16.2},visualEnemy={4.0,-16.2},
  camera={side=34,back=8,height=10.8,lookX=0,lookY=5.15,frameH=29.5,shotRadiusScale=0.60,shotHeightScale=0.42,
    safe={minRadius=23,maxRadius=36,minY=6.6,maxY=13.5,maxPitch=11.5,minPitch=-5.5,minFov=34,maxFov=48,minFocusY=4.5,maxFocusY=6.3}},
}
local ctx={battle={kind="trainer",game={save={options={speedBattle=1}}}}}
-- Deliberately unsafe host/base pose: high, wide and pitched down through the
-- exact outer-canopy volume seen in the user's screenshots.
local base={eye={66,29,26},focus={0,9.8,0},fov=math.rad(40)}
local function assertSafe(pose,label)
  assert(pose and pose.eye and pose.focus,label.." missing pose")
  local dx=pose.eye[1]-pose.focus[1];local dy=pose.eye[2]-pose.focus[2];local dz=pose.eye[3]-pose.focus[3]
  local r=math.sqrt(dx*dx+dy*dy+dz*dz)
  local h=math.max(.001,math.sqrt(dx*dx+dz*dz))
  local pitch=math.deg((math.atan2 and math.atan2(dy,h) or math.atan(dy/h)))
  assert(r<=36.05,label.." escaped inner bowl radius: "..tostring(r))
  assert(pose.eye[2]<=13.55,label.." rose into canopy eye band: "..tostring(pose.eye[2]))
  assert(pose.eye[2]>=6.55,label.." fell below camera floor: "..tostring(pose.eye[2]))
  assert(pose.focus[2]>=4.45 and pose.focus[2]<=6.35,label.." focus tilted toward canopy: "..tostring(pose.focus[2]))
  assert(pitch<=11.6,label.." pitch sees too much overhead foliage: "..tostring(pitch))
end

Camera:begin(ctx)
assertSafe(Camera:shot(ctx,"intro",0,base,arena),"intro-frame-zero")
for i=1,2 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"intro",0,base,arena),"intro-early-blend")
for i=1,90 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"command",0,base,arena),"passive")
Camera:event(ctx,"battle.move_used",{side="player"})
for i=1,12 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"attack",0,base,arena),"attack")
Camera:event(ctx,"battle.damage_dealt",{target="enemy",attacker="player",damage=3,maxHp=20})
for i=1,18 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"damage",0,base,arena),"damage")
Camera:event(ctx,"battle.battler_switched",{side="player"})
for i=1,14 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"switch",0,base,arena),"switch")
Camera:event(ctx,"battle.fainted",{side="enemy"})
for i=1,18 do Camera:update(ctx,.05) end
assertSafe(Camera:shot(ctx,"faint",0,base,arena),"faint")


-- Source-Waza poses bypass arenaFrame(), so prove the venue safe volume still
-- owns the final source camera target. Feed an intentionally canopy-high source
-- eye/focus and ensure it is corrected before presentation.
local WazaCamera=assert(loadfile("lib/Camera.lua"))({WazaHandlers={cameraPose=function()
  return {eye={72,34,-24},focus={0,12,0},fov=math.rad(38),blend=.20}
end}})
WazaCamera:begin(ctx)
WazaCamera:event(ctx,"battle.move_used",{side="player"})
for i=1,12 do WazaCamera:update(ctx,.05) end
assertSafe(WazaCamera:shot(ctx,"attack",0,base,arena),"source-waza-attack")

print("RelicCameraSafetyTests PASS")
return true
