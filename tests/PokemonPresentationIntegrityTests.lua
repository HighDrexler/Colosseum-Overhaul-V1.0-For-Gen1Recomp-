local Extractor=assert(loadfile("extract/PokemonExtractor.lua"))({})
assert(Extractor.revision>=36,"Pokemon cache revision did not invalidate globally repaired idle banks")
assert(not (Extractor._test and Extractor._test.repairIdleIsolatedGroups),
  "global idle isolated-part pose rewriting is still present")

-- Diglett/Dugtrio are source-authored with body geometry below the battle plane.
-- Keep the targeted floor-placement exception: unlike the removed idle-pose
-- rewrite this is species-specific and does not touch source animation frames.
local Mat4=assert(loadfile("lib/Mat4.lua"))({})
local Actors=assert(loadfile("lib/PokemonActors.lua"))({Mat4=Mat4})
local function floorLift(dex)
  local actor=Actors._test.Actor.new(dex,"normal",{bounds={min={-2,-5,-2},max={2,5,2}},floorMinY=-5},{})
  actor.spawnScale=1;actor.worldScale=1;actor.state="idle"
  actor:matrix(0,0,0,0,1)
  return actor.floorLift,actor.burrowDepth
end
local ordinary=select(1,floorLift(49))
local diglett,buried=floorLift(50)
local dugtrio,dugBuried=floorLift(51)
assert(ordinary>4.99,"ordinary species floor clamp fixture is invalid")
assert(diglett<ordinary*.20 and buried>4.5,"Diglett whole-body lift was not replaced by burrow-aware placement")
assert(dugtrio<ordinary*.30 and dugBuried>3.7,"Dugtrio whole-body lift was not replaced by burrow-aware placement")

print("PokemonPresentationIntegrityTests PASS")
return true
