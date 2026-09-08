local PokemonActors=assert(loadfile("lib/PokemonActors.lua"))({})

local physical={groups={{}},duration=.40}
local damage={groups={{}},duration=.10}
local actor=PokemonActors._test.Actor.new(246,"normal",{
  actions={physicalA=physical,damage=damage},bounds={min={0,0,0},max={1,1,1}},
},{})
actor.sourceMetadata={slots={physicalA={index=2,animationIndex=3,duration=.40,timing={0,.10,.25,.40}}}}

local starts={}
local function onStarted(a,sampled,requested)
  starts[#starts+1]={actor=a,sampled=sampled,requested=requested,action=a.nativeAction}
  return true
end

local accepted,state=actor:attack(44,{type="NORMAL",power=60},{sourceWaza=true,onStarted=onStarted})
assert(accepted==true and state=="started","immediate source attack did not start")
assert(#starts==1 and starts[1].actor==actor and starts[1].sampled==true
  and starts[1].requested=="physicalA" and starts[1].action==physical,
  "MoveFX/Waza handoff did not observe the initialized PKX attack bank")

local queued=PokemonActors._test.Actor.new(246,"normal",{
  actions={physicalA=physical,damage=damage},bounds={min={0,0,0},max={1,1,1}},
},{})
queued.sourceMetadata=actor.sourceMetadata
queued:hit({damage=1,target={hp=9,maxHP=10}})
local delayed={}
local okQueued,queuedState=queued:attack(44,{type="NORMAL",power=60},{sourceWaza=true,onStarted=function(a,sampled,requested)
  delayed[#delayed+1]={actor=a,sampled=sampled,requested=requested,action=a.nativeAction}
  return true
end})
assert(okQueued==true and queuedState=="queued","attack was not queued behind active Damage")
assert(#delayed==0,"Waza/effect handoff fired before the Damage reaction completed")
queued:update(.11)
assert(#delayed==1 and delayed[1].actor==queued and delayed[1].sampled==true
  and delayed[1].requested=="physicalA" and delayed[1].action==physical,
  "queued attack did not bind MoveFX/Waza when its PKX bank actually started")
assert(queued.state=="attack" and queued.nativeAction==physical,
  "queued source attack did not enter the native PKX attack state")

return true
