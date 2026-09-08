local HSD=assert(loadfile("extract/HSD.lua"))({})
local matrix=HSD._test.localMatrix
local scale=HSD._test.inheritedScale
local multiply=HSD._test.multiply
local function near(actual,expected)
  assert(math.abs(actual-expected)<1e-6,("expected %.6f, got %.6f"):format(expected,actual))
end
local parent=matrix(0,0,0,1,.35,1,0,0,0)
local child=matrix(-math.pi/2,0,0,1,3,1,0,2,0,{1,.35,1})
local world=multiply(parent,child)
near(math.sqrt(world[2]^2+world[6]^2+world[10]^2),1.05)
near(math.sqrt(world[3]^2+world[7]^2+world[11]^2),1)
near(world[8],.7)
local cumulative=scale({1,.35,1},1,3,1,false)
near(cumulative[2],1.05)
assert(scale(cumulative,2,2,2,true)==cumulative,"classical joint changed accumulated compensation")
assert(scale(nil,2,2,2,true)==nil,"classical root introduced compensation")
local uniform=matrix(.2,.3,.4,1,2,3,4,5,6,{2,2,2})
local plain=matrix(.2,.3,.4,1,2,3,4,5,6)
for index=1,16 do near(uniform[index],plain[index]) end
local Extractor=assert(loadfile("extract/PokemonExtractor.lua"))({})
assert(Extractor.revision>=32,"old stretched-pose cache remains valid")
assert(Extractor._test.denseActionIntervals("specialA",130/30,130)==130,"Bite attack still sampled at 12 poses")
assert(Extractor._test.denseActionIntervals("faint",119/30,119)==119,"faint misses authored source samples")
return true
