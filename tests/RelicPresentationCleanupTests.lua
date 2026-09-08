local read=function(path) local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local catalog=read("lib/ArenaCatalog.lua")
local arena=read("lib/Arena.lua")
local main=read("main.lua")
assert(catalog:find('presentationOccluderTrim=true',1,true),"Relic view-adaptive guard not enabled")
assert(arena:find('RelicPresentation.shouldCull',1,true),"Arena renderer does not consult projected Relic guard")
assert(main:find('loadModule("RelicPresentation")',1,true),"Relic presentation module not loaded")

local R=assert(loadfile("lib/RelicPresentation.lua"))({})
local pose={eye={0,10,30},focus={0,5,0},fov=math.rad(40)}
-- Large elevated source card crossing the lens/battle window: must disappear
-- only for this camera view.
local canopy={center={0,28,50},extent={180,5,80},mode=3}
assert(R.shouldCull(canopy,pose,.25,0,16/9)==true,"broad camera-side canopy carrier survived")
-- Same type of source card safely behind the battlers: it is authentic room
-- detail and must remain.
local rear={center={0,36,-220},extent={160,8,70},mode=3}
assert(R.shouldCull(rear,pose,.25,0,16/9)==false,"rear shrine foliage was globally removed")
-- Even modest cutout foliage in front of the protected battle view must be removed.
local small={center={0,28,50},extent={12,3,12},mode=3}
assert(R.shouldCull(small,pose,.25,0,16/9)==true,"foreground source leaf/branch detail survived the protected battle view")
-- Large opaque rear wall-like geometry is not a foliage/root carrier.
local wall={center={0,30,45},extent={180,60,12},mode=0}
assert(R.shouldCull(wall,pose,.25,0,16/9)==false,"ordinary source architecture was culled")
print("RelicPresentationCleanupTests PASS")
return true
