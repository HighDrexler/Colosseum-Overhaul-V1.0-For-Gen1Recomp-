


















local SRM={}

SRM.SHINY_ODDS=1/2048





function SRM.rollNormal(stream)
return stream:nextFloat()<SRM.SHINY_ODDS
end














function SRM.chooseAceSlots(rosterSize,archetype,roleOfSlot,n)
n=math.max(0,math.min(math.floor(n or 1),rosterSize))
local chosen,taken={},{}
for k=1,n do
local wantRole=archetype.roles[k] or archetype.roles[1]
local slot=nil
for i=1,rosterSize do
if not taken[i] and roleOfSlot(i)==wantRole then slot=i;break end
end
if not slot then





for i=1,rosterSize do
if not taken[i] then slot=i;break end
end
end
if slot then chosen[#chosen+1]=slot;taken[slot]=true end
end
return chosen
end



function SRM.chooseAceSlot(rosterSize,archetype,roleOfSlot)
return SRM.chooseAceSlots(rosterSize,archetype,roleOfSlot,1)[1]
end












function SRM.assign(stream,rosterSize,aceCount,archetype,roleOfSlot)
local shiny={}
local aceSlots={}
if aceCount and aceCount>0 then
aceSlots=SRM.chooseAceSlots(rosterSize,archetype,roleOfSlot,aceCount)
end
local aceSet={}
for _,slot in ipairs(aceSlots) do aceSet[slot]=true end
for i=1,rosterSize do
if aceSet[i] then shiny[i]=true
else shiny[i]=SRM.rollNormal(stream) end
end
return shiny,aceSlots[1],aceSlots
end

return SRM
