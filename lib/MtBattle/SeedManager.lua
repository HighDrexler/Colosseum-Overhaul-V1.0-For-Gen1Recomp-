












local V=... or {}
local SM={}

local M=2147483647
local A=16807




local function lcgStep(seed)
return (seed*A)%M
end



local function normalize(n)
n=math.floor(math.abs(n or 0))%M
if n==0 then n=1 end
return n
end






function SM.subSeed(masterSeed,fightIndex)
local seed=normalize(masterSeed)
local n=math.max(0,math.floor(fightIndex or 0))
for _=1,n do seed=lcgStep(seed) end
return seed
end





local Stream={}
Stream.__index=Stream
function SM.newStream(seed)
return setmetatable({seed=normalize(seed)},Stream)
end

function Stream:nextRaw()
self.seed=lcgStep(self.seed)
return self.seed
end

function Stream:nextFloat()
return (self:nextRaw()-1)/(M-1)
end

function Stream:nextInt(lo,hi)
lo=math.floor(lo);hi=math.floor(hi)
if hi<=lo then return lo end
return lo+math.floor(self:nextFloat()*(hi-lo+1))
end


function Stream:pick(list)
if not list or #list==0 then return nil end
return list[self:nextInt(1,#list)]
end








function SM.roll(game,SaveState)
SaveState=SaveState or V.MtBattleSaveState
local s=SaveState.state(game)
s.runNonce=(s.runNonce or 0)+1
local entropy=0
local ok,r=pcall(function()
if love and love.math and love.math.random then return love.math.random(0,M-1) end
return nil
end)
if ok and type(r)=="number" then entropy=r end
local wall=0
local ok2,t=pcall(os.time)
if ok2 and type(t)=="number" then wall=t end




local mixed=entropy*2654435761 + wall*40503 + s.runNonce*2246822519
s.masterSeed=normalize(mixed)
s.active=true
return s.masterSeed
end

SM.M=M
SM.A=A
SM.normalize=normalize

return SM
