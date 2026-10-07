








local RC={}













function RC.streamDVs(stream,maxDv)
maxDv=maxDv or 15
return {
attack=stream:nextInt(0,maxDv),defense=stream:nextInt(0,maxDv),
speed=stream:nextInt(0,maxDv),special=stream:nextInt(0,maxDv),
}
end






RC.ROLE_STAT_WEIGHTS={
sweeper={speed=2.0,attack=1.3,specialAttack=1.3,hp=0.3,defense=0.2,specialDefense=0.2},
setup_sweeper={speed=1.6,attack=1.4,specialAttack=1.4,hp=0.5,defense=0.3,specialDefense=0.3},
wallbreaker={attack=2.0,specialAttack=2.0,speed=0.6,hp=0.6,defense=0.2,specialDefense=0.2},
wall={hp=2.0,defense=1.6,specialDefense=1.6,speed=0.2,attack=0.2,specialAttack=0.2},
bulky_attacker={hp=1.2,defense=1.0,specialDefense=1.0,attack=1.3,specialAttack=1.3,speed=0.6},
support={hp=1.2,defense=1.0,specialDefense=1.0,speed=0.8,attack=0.4,specialAttack=0.4},
pivot={hp=1.0,defense=0.9,specialDefense=0.9,speed=1.0,attack=0.7,specialAttack=0.7},
cleric={hp=1.4,defense=1.0,specialDefense=1.0,speed=0.6,attack=0.2,specialAttack=0.2},
phazer={hp=1.6,defense=1.3,specialDefense=1.3,speed=0.6,attack=0.2,specialAttack=0.2},
revenge_killer={speed=1.8,attack=1.2,specialAttack=1.2,hp=0.5,defense=0.3,specialDefense=0.3},
suicide_lead={speed=1.8,attack=1.0,specialAttack=1.0,hp=0.3,defense=0.2,specialDefense=0.2},
speed_control={speed=2.2,hp=0.6,defense=0.4,specialDefense=0.4,attack=0.5,specialAttack=0.5},
}





local function unifiedStats(baseStats)
if not baseStats then return {hp=0,attack=0,defense=0,speed=0,specialAttack=0,specialDefense=0} end
if baseStats.specialAttack or baseStats.specialDefense then
return {hp=baseStats.hp or 0,attack=baseStats.attack or 0,defense=baseStats.defense or 0,
speed=baseStats.speed or 0,specialAttack=baseStats.specialAttack or 0,
specialDefense=baseStats.specialDefense or 0}
end
local sp=baseStats.special or 0
return {hp=baseStats.hp or 0,attack=baseStats.attack or 0,defense=baseStats.defense or 0,
speed=baseStats.speed or 0,specialAttack=sp,specialDefense=sp}
end
RC.unifiedStats=unifiedStats

function RC.roleScore(role,baseStats)
local weights=RC.ROLE_STAT_WEIGHTS[role] or RC.ROLE_STAT_WEIGHTS.support
local stats=unifiedStats(baseStats)
local score=0
for key,weight in pairs(weights) do score=score+(stats[key] or 0)*weight end
return score
end




function RC.powerIndex(baseStats)
local s=unifiedStats(baseStats)
return (s.hp or 0)+(s.attack or 0)+(s.defense or 0)+(s.speed or 0)
+((s.specialAttack or 0)+(s.specialDefense or 0))*.5
end




function RC.powerWeight(tier,baseStats)
local center=tonumber(tier and tier.powerCenter)
local spread=tonumber(tier and tier.powerSpread)
if not (center and spread and spread>0) then return 1 end
local delta=(RC.powerIndex(baseStats)-center)/spread
return math.max(.18,math.exp(-.5*delta*delta))
end

local function typeDiversityWeight(types,teamTypes)
if type(teamTypes)~="table" then return 1 end
local unseen=false
local penalty=1
for _,t in ipairs(types or {}) do
local count=tonumber(teamTypes[t]) or 0
if count==0 then unseen=true end
if count>=2 then penalty=penalty*(count>=3 and .48 or .70) end
end
if unseen then penalty=penalty*1.14 end
return math.max(.22,penalty)
end





function RC.pickArchetype(stream,Archetypes,AntiRepeat,save,fightIndex,tier)
local list=Archetypes and Archetypes.ARCHETYPES or {}
if #list==0 then return nil end
return AntiRepeat.weightedPick(stream,list,function(a)
local w=AntiRepeat.archetypeWeight(save,a.id,fightIndex)
local tw=tier and tier.archetypeWeights and tier.archetypeWeights[a.id]
if tonumber(tw) then w=w*tw end



if tier and tier.leaderArchetype then
w=w*(a.id==tier.leaderArchetype and 3.35 or .72)
end
local fp=save and save.fingerprint
if type(fp)=="table" then
local progress=math.max(0,math.min(1,(fightIndex-1)/99))
local nudge=1
local attacks=(tonumber(fp.physical) or 0)+(tonumber(fp.special) or 0)
local status=tonumber(fp.status) or 0
if attacks>status*2 and (a.id=="balanced" or a.id=="bulky_offense") then nudge=nudge+.10*progress end
if (tonumber(fp.hasSetup) or 0)>=2 and a.id=="speed_control" then nudge=nudge+.12*progress end
if ((tonumber(fp.hasRecovery) or 0)+(tonumber(fp.hasStatus) or 0))>=3
and (a.id=="balanced" or a.id=="hyper_offense") then nudge=nudge+.08*progress end
w=w*nudge
end
return w
end)
end






local function coverageFreshnessWeight(AntiRepeat,save,fightIndex,id,baseStats,tier)
if not (AntiRepeat and type(AntiRepeat.useCount)=="function") then return 1 end
if AntiRepeat.useCount(save,id)>0 then return 1 end
local progress=math.max(0,math.min(1,(tonumber(fightIndex) or 1)/100))
local weight=1.22+.18*(1-progress)
local center=tonumber(tier and tier.powerCenter)
if center and fightIndex<=60 then
local deficit=math.max(0,center-RC.powerIndex(baseStats))
weight=weight+math.min(.22,deficit/360)*(1-progress*.65)
end
return weight
end













function RC.behaviorLean(save,fightIndex,speciesTypes,PlayerBehaviorTracker,TypeChart)
if not (PlayerBehaviorTracker and TypeChart and save) then return 1.0 end
local dominant=PlayerBehaviorTracker.dominantMoveType(save)
if not dominant then return 1.0 end
local row=TypeChart.rows(dominant,speciesTypes or {})
local effectiveness=row and row[1]
if effectiveness and effectiveness<10 then
return PlayerBehaviorTracker.typeLean(save,fightIndex,dominant)
end
return 1.0
end









function RC.pickSpecies(stream,AntiRepeat,save,fightIndex,data,role,eligibleSpeciesIds,behaviorCtx,tier,teamTypes)
local candidates={}
local scores={}
for _,id in ipairs(eligibleSpeciesIds or {}) do
local def=data.pokemon and data.pokemon[id]
if def and def.baseStats and def.types then
candidates[#candidates+1]=id
local lean=behaviorCtx and RC.behaviorLean(save,fightIndex,def.types,
behaviorCtx.PlayerBehaviorTracker,behaviorCtx.TypeChart) or 1.0
scores[id]=math.max(1,RC.roleScore(role,def.baseStats)*lean
*RC.powerWeight(tier,def.baseStats)*typeDiversityWeight(def.types,teamTypes)
*coverageFreshnessWeight(AntiRepeat,save,fightIndex,id,def.baseStats,tier))
end
end
if #candidates==0 then return nil end
return AntiRepeat.weightedPick(stream,candidates,function(id)
return scores[id]*AntiRepeat.speciesWeight(save,id,fightIndex)
end)
end




















function RC.pickRosterSpecies(stream,AntiRepeat,Difficulty,save,fightIndex,data,archetype,rosterSize,eligibleSpeciesIds,behaviorCtx,tier)
local capFiltered={}
for _,id in ipairs(eligibleSpeciesIds or {}) do
if AntiRepeat.canUse(save,id) then capFiltered[#capFiltered+1]=id end
end
local forcedCount=AntiRepeat.forcedCoverageCount(save,fightIndex,rosterSize,capFiltered,Difficulty)
local usedThisFight={}
local teamTypes={}
local species={}
for i=1,rosterSize do
local role=archetype.roles[((i-1)%#archetype.roles)+1]
local pool=nil
if i<=forcedCount then
pool={}
for _,id in ipairs(capFiltered) do
if AntiRepeat.useCount(save,id)==0 and not usedThisFight[id] then pool[#pool+1]=id end
end
if #pool==0 then pool=nil end
end
if not pool then
pool={}
for _,id in ipairs(capFiltered) do
if not usedThisFight[id] then pool[#pool+1]=id end
end
end
local pick=RC.pickSpecies(stream,AntiRepeat,save,fightIndex,data,role,pool,behaviorCtx,tier,teamTypes)
if pick then
species[i]=pick
usedThisFight[pick]=1
local def=data.pokemon and data.pokemon[pick]
for _,t in ipairs((def and def.types) or {}) do teamTypes[t]=(teamTypes[t] or 0)+1 end
end
end






for i=1,rosterSize do
if not species[i] then
local role=archetype.roles[((i-1)%#archetype.roles)+1]
local pool={}
for _,id in ipairs(eligibleSpeciesIds or {}) do
local localUses=usedThisFight[id] or 0
if AntiRepeat.useCount(save,id)+localUses<AntiRepeat.MAX_USES then pool[#pool+1]=id end
end
local pick=RC.pickSpecies(stream,AntiRepeat,save,fightIndex,data,role,pool,behaviorCtx,tier,teamTypes)



if not pick then pick=RC.pickSpecies(stream,AntiRepeat,save,fightIndex,data,role,eligibleSpeciesIds,behaviorCtx,tier,teamTypes) end
if pick then
species[i]=pick
usedThisFight[pick]=(usedThisFight[pick] or 0)+1
local def=data.pokemon and data.pokemon[pick]
for _,t in ipairs((def and def.types) or {}) do teamTypes[t]=(teamTypes[t] or 0)+1 end
end
end
end
return species
end







function RC.scoreMove(mdef,role,memberTypes,alreadyCovered,Archetypes,generation,personality,teamCoveredTypes,tier)
local score=0
local stab=mdef.type and memberTypes[mdef.type]
if stab then score=score+3 end
if (mdef.power or 0)>0 then
score=score+2




score=score+math.min(2.0,(tonumber(mdef.power) or 0)/60)
local accuracy=tonumber(mdef.accuracy)
if accuracy and accuracy>0 and accuracy<85 then
score=score-math.min(1.5,(85-accuracy)/20)
end
if mdef.type and not alreadyCovered[mdef.type] then score=score+2 end
if mdef.type and alreadyCovered[mdef.type] then score=score-(stab and .15 or .55) end




local target=tonumber(tier and tier.movePowerTarget)
if target then
local power=tonumber(mdef.power) or 0
score=score-math.min(2.25,math.abs(power-target)/32)
end
end
local eff=tostring(mdef.effect or "")
local isStatus=Archetypes.effectCategory(Archetypes.STATUS_EFFECTS,generation,mdef.effect)
local isStall=Archetypes.effectCategory(Archetypes.STALL_EFFECTS,generation,mdef.effect)
local isEvasion=Archetypes.effectCategory(Archetypes.EVASION_EFFECTS,generation,mdef.effect)
if role=="wall" or role=="cleric" or role=="phazer" or role=="stall" then
if isStall then score=score+3 end
if isStatus then score=score+2 end
end
if role=="setup_sweeper" then
if eff:find("UP1") or eff:find("UP2") or eff:find("_up") then score=score+3 end
end
if role=="support" or role=="pivot" then
if isStatus then score=score+1 end
end



if isEvasion then score=score-2 end
if mdef.priority and mdef.priority>0 and (role=="revenge_killer" or role=="speed_control") then
score=score+2
end
if (mdef.power or 0)>0 and mdef.type and teamCoveredTypes and not teamCoveredTypes[mdef.type] then
score=score+.65
end
local p=type(personality)=="table" and personality.id or personality
if p=="aggressive" then
if (mdef.power or 0)>0 then score=score+1 end
if mdef.priority and mdef.priority>0 then score=score+.4 end
elseif p=="technical" then
if isStatus then score=score+.5 end
if (mdef.power or 0)>0 and mdef.type and not alreadyCovered[mdef.type] then score=score+.55 end
elseif p=="defensive" then
if isStall then score=score+.8 elseif isStatus then score=score+.35 end
elseif p=="disruptive" then
if isStatus then score=score+1 end
elseif p=="setup" then
if eff:find("UP1") or eff:find("UP2") or eff:find("_up") then score=score+1.2 end
end
return score
end

local function frustrationFlags(Archetypes,generation,mdef)
if not (Archetypes and mdef and type(Archetypes.effectCategory)=="function") then
return {status=false,evasion=false,stall=false}
end
return {
status=Archetypes.effectCategory(Archetypes.STATUS_EFFECTS,generation,mdef.effect)==true,
evasion=Archetypes.effectCategory(Archetypes.EVASION_EFFECTS,generation,mdef.effect)==true,
stall=Archetypes.effectCategory(Archetypes.STALL_EFFECTS,generation,mdef.effect)==true,
}
end

local function frustrationCountsForMoves(data,ids,Archetypes,generation)
local out={status=0,evasion=0,stall=0}
for _,id in ipairs(ids or {}) do
local mdef=data and data.moves and data.moves[id]
local flags=frustrationFlags(Archetypes,generation,mdef)
if flags.status then out.status=out.status+1 end
if flags.evasion then out.evasion=out.evasion+1 end
if flags.stall then out.stall=out.stall+1 end
end
return out
end
RC.frustrationCountsForMoves=frustrationCountsForMoves

local function frustrationBudgetAllows(data,chosen,candidate,Archetypes,generation,budget)
if type(budget)~="table" then return true end
local caps=budget.caps or (Archetypes and Archetypes.FRUSTRATION_CAPS) or {}
local prior=budget.counts or {}
local localCounts=frustrationCountsForMoves(data,chosen,Archetypes,generation)
local flags=frustrationFlags(Archetypes,generation,candidate)
local function within(key,capKey,adds)
local cap=tonumber(caps[capKey]);if not cap then return true end
return (tonumber(prior[key]) or 0)+(tonumber(localCounts[key]) or 0)+(adds and 1 or 0)<=cap
end
return within("status","statusMovesPerTeam",flags.status)
and within("evasion","evasionMovesPerTeam",flags.evasion)
and within("stall","stallMovesPerTeam",flags.stall)
end







function RC.pickMoveset(stream,data,candidateIds,role,memberTypes,Archetypes,generation,personality,teamCoveredTypes,teamMoveBudget,tier)
local pool={}
for _,id in ipairs(candidateIds or {}) do
local mdef=data.moves and data.moves[id]
if mdef then pool[#pool+1]={id=id,def=mdef} end
end
local chosen={}
local covered={}
for _=1,4 do
if #pool==0 then break end
local best,bestScore,bestIdx=nil,-math.huge,nil
for i,entry in ipairs(pool) do
local p=type(personality)=="table" and personality.id or personality
local tierJitter=tonumber(tier and tier.moveSearchJitter) or .01
local jitter=(p=="unpredictable") and math.max(.65,tierJitter) or tierJitter
local s=RC.scoreMove(entry.def,role,memberTypes,covered,Archetypes,generation,personality,teamCoveredTypes,tier)
+stream:nextFloat()*jitter
if frustrationBudgetAllows(data,chosen,entry.def,Archetypes,generation,teamMoveBudget)
and s>bestScore then best,bestScore,bestIdx=entry,s,i end
end
if not best then break end
chosen[#chosen+1]=best.id
if best.def.type and (best.def.power or 0)>0 then covered[best.def.type]=true end
table.remove(pool,bestIdx)
end
if #chosen==0 then chosen={"TACKLE"} end



local hasDamage=false
for _,id in ipairs(chosen) do
local d=data.moves and data.moves[id]
if d and (d.power or 0)>0 then hasDamage=true;break end
end
if not hasDamage then
local best,bestScore=nil,-math.huge
local selected={};for _,id in ipairs(chosen) do selected[id]=true end
local replaceIndex=math.max(1,#chosen)
local retained={}
for i,id in ipairs(chosen) do if i~=replaceIndex then retained[#retained+1]=id end end
for _,id in ipairs(candidateIds or {}) do
local d=data.moves and data.moves[id]
if d and (d.power or 0)>0 and not selected[id]
and frustrationBudgetAllows(data,retained,d,Archetypes,generation,teamMoveBudget) then
local s=RC.scoreMove(d,role,memberTypes,{},Archetypes,generation,personality,teamCoveredTypes,tier)
if s>bestScore then best,bestScore=id,s end
end
end
if best then chosen[replaceIndex]=best end
end
if type(teamMoveBudget)=="table" then
teamMoveBudget.counts=teamMoveBudget.counts or {status=0,evasion=0,stall=0}
local added=frustrationCountsForMoves(data,chosen,Archetypes,generation)
for _,key in ipairs({"status","evasion","stall"}) do
teamMoveBudget.counts[key]=(tonumber(teamMoveBudget.counts[key]) or 0)+(tonumber(added[key]) or 0)
end
end
if type(teamCoveredTypes)=="table" then
for _,id in ipairs(chosen) do
local d=data.moves and data.moves[id]
if d and (d.power or 0)>0 and d.type then teamCoveredTypes[d.type]=true end
end
end
return chosen
end






local function setupEffect(effect)
local s=tostring(effect or "")
local upper=s:upper()
if upper:find("_UP1_EFFECT",1,true) or upper:find("_UP2_EFFECT",1,true)
or upper:find("SWORDS_DANCE",1,true) or upper:find("GROWTH",1,true)
or upper:find("AMNESIA",1,true) or upper:find("AGILITY",1,true) then return true end
local lower=s:lower()
return lower:find("attack_up",1,true)~=nil or lower:find("defense_up",1,true)~=nil
or lower:find("speed_up",1,true)~=nil or lower:find("sp_attack_up",1,true)~=nil
or lower:find("sp_defense_up",1,true)~=nil or lower:find("special_attack_up",1,true)~=nil
or lower:find("special_defense_up",1,true)~=nil
end

local function speedControlEffect(effect)
local s=tostring(effect or ""):lower()
return s:find("paraly",1,true)~=nil or s:find("speed_down",1,true)~=nil
end





local function typeMultiplier(data,attackType,defenderTypes)
local chart=data and data.type_chart
if type(chart)~="table" or type(chart.matchups)~="table" then return nil end
local mult=10
for _,row in ipairs(chart.matchups) do
if row.attacker==attackType then
for _,defType in ipairs(defenderTypes or {}) do
if row.defender==defType then
mult=math.floor(mult*(tonumber(row.multiplier) or 10)/10)
break
end
end
end
end
return mult
end

local function moveProfile(data,row,def,Archetypes,generation)
local p={damage=0,strong=0,stab=0,support=0,status=0,stall=0,setup=0,speedControl=0,priority=0}
local ownTypes={};for _,t in ipairs((def and def.types) or {}) do ownTypes[t]=true end
for _,mv in ipairs(row.moves or {}) do
local id=type(mv)=="table" and mv.id or mv
local m=data and data.moves and data.moves[id]
if m then
local power=tonumber(m.power) or 0
if power>0 then
p.damage=p.damage+1
if power>=70 then p.strong=p.strong+1 end
if m.type and ownTypes[m.type] then p.stab=p.stab+1 end
else p.support=p.support+1 end
if setupEffect(m.effect) then p.setup=p.setup+1 end
if speedControlEffect(m.effect) or (tonumber(m.priority) or 0)>0 then p.speedControl=p.speedControl+1 end
if (tonumber(m.priority) or 0)>0 then p.priority=p.priority+1 end
if Archetypes and type(Archetypes.effectCategory)=="function" then
if Archetypes.effectCategory(Archetypes.STATUS_EFFECTS,generation,m.effect) then p.status=p.status+1 end
if Archetypes.effectCategory(Archetypes.STALL_EFFECTS,generation,m.effect) then p.stall=p.stall+1 end
end
end
end
return p
end

local function roleRealizationScore(role,p)
if role=="sweeper" then return (p.damage>=2 and 1.3 or -.7)+(p.stab>0 and .6 or -.2)+(p.strong>0 and .4 or 0) end
if role=="setup_sweeper" then return (p.setup>0 and 1.6 or -1.2)+(p.damage>0 and .8 or -1.0) end
if role=="wallbreaker" then return (p.damage>=2 and 1.0 or -.7)+(p.strong>0 and 1.1 or -.6) end
if role=="bulky_attacker" then return (p.damage>=2 and 1.1 or -.6)+(p.stab>0 and .5 or 0) end
if role=="revenge_killer" then return (p.damage>=2 and .8 or -.6)+(p.priority>0 and 1.0 or 0) end
if role=="speed_control" then return (p.speedControl>0 and 1.7 or -1.1)+(p.damage>0 and .5 or -.5) end
if role=="suicide_lead" then return (p.damage>0 and .6 or -.8)+(p.support>0 and .7 or 0) end
if role=="wall" or role=="cleric" or role=="support" or role=="phazer" or role=="pivot" then
return (p.damage>0 and .45 or -.8)+(p.support>0 and .85 or -.45)
end
return p.damage>0 and .4 or -.5
end

local function defensiveSynergy(data,members)
local attackTypes={}
local chart=data and data.type_chart
for _,row in ipairs(type(chart)=="table" and chart.matchups or {}) do attackTypes[row.attacker]=true end
local exposed,covered,maxWeak=0,0,0
for attackType in pairs(attackTypes) do
local weak,resist=0,0
for _,member in ipairs(members or {}) do
local def=data and data.pokemon and data.pokemon[member.species]
local mult=def and typeMultiplier(data,attackType,def.types)
if mult and mult>10 then weak=weak+1 elseif mult and mult<10 then resist=resist+1 end
end
if weak>maxWeak then maxWeak=weak end
if weak>=3 then
if resist>0 then covered=covered+1 else exposed=exposed+1 end
end
end
return {exposed=exposed,covered=covered,maxWeak=maxWeak}
end

function RC.teamQuality(data,members,roles,tier,opts)
opts=opts or {}
local Archetypes=opts.Archetypes
local generation=tonumber(opts.generation) or 1
local archetype=opts.archetype
local score=0
local typeCounts,attackTypes={},{}
local teamProfile={damage=0,strong=0,stab=0,support=0,status=0,stall=0,setup=0,speedControl=0,priority=0}
local itemCounts={}
for i,row in ipairs(members or {}) do
local def=data and data.pokemon and data.pokemon[row.species]
if def then
score=score+RC.powerWeight(tier,def.baseStats)*4
score=score+RC.roleScore((roles and roles[i]) or "support",def.baseStats)/120
local floor=tonumber(tier and tier.powerFloor)
if floor then
local deficit=math.max(0,floor-RC.powerIndex(def.baseStats))
score=score-math.min(3.2,deficit/42)
end
for _,t in ipairs(def.types or {}) do typeCounts[t]=(typeCounts[t] or 0)+1 end
end
local damaging=0
for _,mv in ipairs(row.moves or {}) do
local id=type(mv)=="table" and mv.id or mv
local m=data and data.moves and data.moves[id]
if m and (m.power or 0)>0 then
damaging=damaging+1
if m.type then attackTypes[m.type]=true end
score=score+math.min(1.2,(tonumber(m.power) or 0)/100)
end
end
score=score+(damaging>0 and 1.8 or -5)
local profile=moveProfile(data,row,def,Archetypes,generation)
for key in pairs(teamProfile) do teamProfile[key]=teamProfile[key]+(profile[key] or 0) end
score=score+roleRealizationScore((roles and roles[i]) or "support",profile)
if row.item then itemCounts[row.item]=(itemCounts[row.item] or 0)+1 end
if generation==2 then
local role=(roles and roles[i]) or "support"
if row.item=="LEFTOVERS" and (role=="wall" or role=="cleric") then score=score+.75 end
if row.item=="MIRACLE_BERRY" and (role=="support" or role=="cleric" or role=="speed_control") then score=score+.4 end
if row.item=="BERRY" and (role=="sweeper" or role=="wallbreaker" or role=="revenge_killer") then score=score+.3 end
end
end
local distinctTypes=0
for _,count in pairs(typeCounts) do
distinctTypes=distinctTypes+1
if count>3 then score=score-(count-3)*1.4 end
end
local distinctAttacks=0;for _ in pairs(attackTypes) do distinctAttacks=distinctAttacks+1 end
score=score+distinctTypes*1.0+distinctAttacks*1.15



score=score+math.min(6,distinctAttacks)*.25
score=score+math.min(6,teamProfile.stab)*.35+math.min(6,teamProfile.strong)*.22

local defense=defensiveSynergy(data,members)
score=score-defense.exposed*1.8-math.max(0,defense.maxWeak-3)*.9+defense.covered*.35




if archetype=="balanced" then
score=score+(teamProfile.support>=2 and 1.0 or -.8)+(teamProfile.damage>=8 and .7 or -.4)
elseif archetype=="hyper_offense" then
score=score+(teamProfile.strong>=4 and 1.4 or -.7)+(teamProfile.damage>=10 and .9 or -.5)
elseif archetype=="bulky_offense" then
score=score+(teamProfile.damage>=8 and .8 or -.4)+(teamProfile.support>=1 and .5 or 0)
elseif archetype=="stall" then
score=score+(teamProfile.support>=3 and 1.2 or -.8)+(teamProfile.damage>=4 and .5 or -.5)
elseif archetype=="setup_sweep" then
score=score+(teamProfile.setup>=1 and 1.8 or -1.2)+(teamProfile.damage>=7 and .5 or -.4)
elseif archetype=="speed_control" then
score=score+(teamProfile.speedControl>=1 and 1.8 or -1.2)+(teamProfile.damage>=7 and .5 or -.4)
end
for _,count in pairs(itemCounts) do if count>2 then score=score-(count-2)*.35 end end
return score
end

RC._test={typeDiversityWeight=typeDiversityWeight,coverageFreshnessWeight=coverageFreshnessWeight,
setupEffect=setupEffect,speedControlEffect=speedControlEffect,typeMultiplier=typeMultiplier,
moveProfile=moveProfile,roleRealizationScore=roleRealizationScore,defensiveSynergy=defensiveSynergy}

return RC
