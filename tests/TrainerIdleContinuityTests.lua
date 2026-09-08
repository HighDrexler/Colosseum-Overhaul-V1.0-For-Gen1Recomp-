local A=assert(loadfile('lib/TrainerPerformance.lua'))({})
local function settle(dt,n)
 local state=A.newState('wes');state.current.breath=0;state.current.look=0
 local out
 for i=1,n do out,state=A.step(state,'wes',5,nil,0,1,'player',dt) end
 return out
end
local a,b,c=settle(1/120,120),settle(1/30,30),settle(.1,10)
assert(math.abs(a.breath-b.breath)<1e-9 and math.abs(a.breath-c.breath)<1e-9,'idle filter loses elapsed time at low FPS')
local state=A.newState('wes');state.current.breath=.01;state.current.look=.02
local target=A.idle('wes',5,'command',.2,1,'player')
local out=A.step(state,'wes',5,'command',.2,1,'player',0)
assert(out.breath==.01 and out.look==.02,'action entry snaps idle channels')
assert(out.gesture1==target.gesture1,'authored action timing was filtered')
for _,dt in ipairs({0,.01,.1,.5,3}) do
 local o= A.step(nil,'wes',5,nil,0,1,'player',dt)
 for k,v in pairs(o) do if type(v)=='number' then assert(v==v and math.abs(v)<1e6,'unstable '..k) end end
end
print('Trainer idle continuity tests passed')
