local PokemonActors=assert(loadfile("lib/PokemonActors.lua"))({})
local function newActor()
  local damage={groups={{}},duration=.10}
  local damageHeavy={groups={{}},duration=.12}
  local faint={groups={{}},duration=.30}
  return PokemonActors._test.Actor.new(246,"normal",{
    actions={damage=damage,damageHeavy=damageHeavy,faint=faint},bounds={min={0,0,0},max={1,1,1}},
  },{})
end

local actor=newActor()
actor:hit({damage=10,target={hp=20,maxHP=30}})
actor:hit({damage=20,target={hp=0,maxHP=30}})
assert(#actor.pendingHits==1,"second impact did not queue")
actor:update(.11)
assert(actor.hitAge~=nil and actor.state=="hit","queued impact was discarded by duplicate suppression")
actor:update(.11)
assert(actor.state=="faint","lethal queued impact did not advance to faint")

local duplicateActor=newActor()
local firstHit={damage=10,target={hp=20,maxHP=30}}
local secondHit={damage=10,target={hp=10,maxHP=30}}
duplicateActor:hit(firstHit)
duplicateActor:hit(firstHit)
assert(duplicateActor.pendingHits==nil,"duplicate first impact queued another reaction")
duplicateActor:hit(secondHit)
duplicateActor:hit(secondHit)
assert(#duplicateActor.pendingHits==1,"duplicate queued impact was admitted twice")
duplicateActor:update(.11)
assert(duplicateActor.hitAge~=nil,"nonlethal queued reaction was lost")
duplicateActor:update(.11)
assert(duplicateActor.hitAge==nil and duplicateActor.state=="idle","nonlethal reaction did not return to idle")


local sourceDamageActor=newActor()
sourceDamageActor:hit({damage=12,target={hp=18,maxHP=30}},{nativeSlot="damageHeavy",sourceSequenceKind=9})
assert(sourceDamageActor.requestedNativeSlot=="damageHeavy" and sourceDamageActor.nativeActionName=="damageHeavy"
  and sourceDamageActor.sourceDamageSequenceKind==9,
  "source damage WZX kind did not select the matching PKX reaction row")

local terminalActor=newActor()
terminalActor:faint()
assert(terminalActor:hit(firstHit)==false and terminalActor.state=="faint",
  "late damage resurrected a fainting actor")

return true
