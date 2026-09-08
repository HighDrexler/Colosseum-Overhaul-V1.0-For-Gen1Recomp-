local Mat4=assert(loadfile('lib/Mat4.lua'))({})
local A=assert(loadfile('lib/PokemonActors.lua'))({Mat4=Mat4})
local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function near(a,b,label) check(math.abs(a-b)<1e-7,label) end
local function actor()
 local sc={bounds={min={-1,0,-1},max={1,10,1}},floorMinY=0,morphFrames=0,actions={}}
 for _,name in ipairs({'idle','damage','faint','physicalA'}) do
  sc.actions[name]={groups={},morphFrames=2,duration=name=='damage' and .2 or 1}
 end
 local a=A._test.Actor.new(25,'normal',sc,{})
 a:spawn(1)
 return a
end
-- Harmless host idle notifications must not keep resetting the authored loop.
local a=actor();a:update(.125)
local clock=a.clipClock;local bank=a.nativeAction
check(a:idle()==true,'idle notification was rejected')
near(a.clipClock,clock,'repeated idle notification rewound source playback')
check(a.nativeAction==bank,'repeated idle notification replaced native bank')
-- A queued terminal state starts at frame zero after the complete hurt clip.
-- Its removal/fade clock must agree with its newly reset native-pose clock.
local b=actor();b:hit({damage=20,target={hp=0,maxHP=20}})
b:update(.15);b:update(.10)
check(b.state=='faint','lethal hit did not reach the native faint bank')
near(b.faintAge,b.clipClock,'queued faint aged before its native pose started')
near(b.faintAge,0,'queued faint skipped its opening source frame')
b:update(.25);near(b.faintAge,b.clipClock,'faint pose and fade clocks diverged')
local c=actor();c:hit({damage=1,target={hp=20,maxHP=21}});c:recall('switch')
c:update(.15);c:update(.10)
check(c.state=='recall','queued recall did not follow hurt playback')
near(c.recallAge,0,'queued recall skipped its first visible contraction frame')
check(c.clipClock>=.2,'recall rewound the outgoing hurt pose')
-- Sparse/legacy loops must never reference failed samples at the wrap seam.
local weights=A.frameWeights(.95,3,nil,1,true,false,{true,true,false})
near(weights[4],0,'loop seam weighted a rejected source pose')
near(weights[3],.1,'last valid pose did not span the missing final sample')
near(weights[1],.9,'loop seam did not blend continuously back to the base pose')
local legacy=A.frameWeights(3.5/11,3,nil,nil,true,false)
near(legacy[4],.5,'legacy loop held the final pose until wrap')
near(legacy[1],.5,'legacy loop jumped rather than interpolated to base')
print('PresentationFidelitySweepActorTests: '..checks..' assertions passed')
return true
