





local V=... or {}
local XPBank=V.MtBattleXPBank
local RunController=V.MtBattleRunController
local XD={}

local State={}
State.__index=State
XD.State=State





function State.new(game,generation,data,eligibleMons)
return setmetatable({game=game,generation=generation,data=data,
eligibleMons=eligibleMons or {},allocated={}},State)
end

function State:bankTotal()
local save=V.MtBattleSaveState.state(self.game)
return save.xpBank or 0
end

function State:allocatedTotal()
local sum=0
for _,amount in pairs(self.allocated) do sum=sum+amount end
return sum
end

function State:remaining()
return math.max(0,self:bankTotal()-self:allocatedTotal())
end




function State:allocate(i,amount)
if self.__cbeMtBattleAppliedReceipt then return false end
amount=tonumber(amount or 0)
if not amount or amount~=amount or amount==math.huge or amount==-math.huge then return false end
amount=math.max(0,math.floor(amount))
local entry=self.eligibleMons[i]
if not entry then return false end
local othersTotal=self:allocatedTotal()-(self.allocated[i] or 0)
local cap=math.max(0,self:bankTotal()-othersTotal)
self.allocated[i]=math.min(amount,cap)
return true
end




function State:preview(i)
local entry=self.eligibleMons[i]
if not entry then return nil end
return XPBank.preview(self.generation,self.data,entry.mon,self.allocated[i] or 0)
end







function State:commit()
local save=V.MtBattleSaveState.state(self.game)
if save.xpDistributed then return nil,"already distributed" end





if #self.eligibleMons>0 and self:remaining()>0 then return nil,"xp remains unallocated" end
local applied={}
for i,entry in ipairs(self.eligibleMons) do
local amount=self.allocated[i] or 0
if amount>0 then
local before=XPBank.preview(self.generation,self.data,entry.mon,amount)
XPBank.commit(self.generation,self.data,entry.mon,amount)
applied[#applied+1]={label=entry.label,fromLevel=before.fromLevel,toLevel=before.toLevel}
end
end
RunController.finish(self.game)
return applied
end

return XD
