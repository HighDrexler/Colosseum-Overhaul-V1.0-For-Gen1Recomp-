





local ALM={}





ALM.LEADER_ARCHETYPE_BY_AREA={
"balanced","bulky_offense","speed_control","setup_sweep","hyper_offense",
"bulky_offense","stall","speed_control","setup_sweep","balanced",
}

function ALM.isAreaLeader(fightIndex)
return fightIndex%10==0
end






function ALM.applyBudget(tier,fightIndex)
local boosted={}
for k,v in pairs(tier) do boosted[k]=v end



boosted.rosterMin=6
boosted.rosterMax=6
boosted.itemChance=math.min(1,tier.itemChance+0.15)



if tonumber(tier.powerCenter) then boosted.powerCenter=tier.powerCenter+20 end
if tonumber(tier.powerSpread) then boosted.powerSpread=math.max(35,tier.powerSpread*.88) end
if tonumber(tier.powerFloor) then boosted.powerFloor=tier.powerFloor+15 end
boosted.optimizationAttempts=(tonumber(tier.optimizationAttempts) or 5)+2
boosted.isAreaLeader=true
local area=math.max(1,math.min(10,math.floor(((tonumber(fightIndex) or 10)-1)/10)+1))
boosted.leaderArea=area
boosted.leaderArchetype=ALM.LEADER_ARCHETYPE_BY_AREA[area]
return boosted
end









function ALM.bossCategory(fightIndex)
if not ALM.isAreaLeader(fightIndex) then return nil end
return "elite-four"
end

return ALM
