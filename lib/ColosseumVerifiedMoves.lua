







local V=... or {}
local Source=V.ColosseumPokemonMoveData
local M={}
local unpack=table.unpack or unpack
local function pack(...)return{n=select('#',...),...}end


local sourceTypes={
[0]="NORMAL",[1]="FIGHTING",[2]="FLYING",[3]="POISON",[4]="GROUND",
[5]="ROCK",[6]="BUG",[7]="GHOST",[8]="STEEL",[10]="FIRE",
[11]="WATER",[12]="GRASS",[13]="ELECTRIC",[14]="PSYCHIC",
[15]="ICE",[16]="DRAGON",[17]="DARK",
}
local sourceTargets={[0]="selected",[4]="foes",[5]="self",[6]="all-other"}











local plans={

[183]={name="Mach Punch",sourceEffect=103,gen1Effect="NO_ADDITIONAL_EFFECT"},
[202]={name="Giga Drain",sourceEffect=3,gen1Effect="DRAIN_HP_EFFECT"},
[245]={name="ExtremeSpeed",sourceEffect=103,gen1Effect="NO_ADDITIONAL_EFFECT"},




[325]={name="Shadow Punch",sourceEffect=17,gen1Effect="NO_ADDITIONAL_EFFECT",
gen2Effect="EFFECT_ALWAYS_HIT",alwaysHit=true},
[332]={name="Aerial Ace",sourceEffect=17,gen1Effect="NO_ADDITIONAL_EFFECT",
gen2Effect="EFFECT_ALWAYS_HIT",alwaysHit=true},
[345]={name="Magical Leaf",sourceEffect=17,gen1Effect="NO_ADDITIONAL_EFFECT",
gen2Effect="EFFECT_ALWAYS_HIT",alwaysHit=true},
[351]={name="Shock Wave",sourceEffect=17,gen1Effect="NO_ADDITIONAL_EFFECT",
gen2Effect="EFFECT_ALWAYS_HIT",alwaysHit=true},



[303]={name="Slack Off",sourceEffect=32,gen1Effect="HEAL_EFFECT",gen2Effect="EFFECT_HEAL"},
[336]={name="Howl",sourceEffect=10,gen1Effect="ATTACK_UP1_EFFECT",gen2Effect="EFFECT_ATTACK_UP"},
[334]={name="Iron Defense",sourceEffect=51,gen2Effect="EFFECT_DEFENSE_UP_2"},


[337]={name="Dragon Claw",sourceEffect=0,gen1Effect="NO_ADDITIONAL_EFFECT",gen2Effect="EFFECT_NORMAL_HIT"},







[309]={name="Meteor Mash",sourceEffect=139,gen2Effect="EFFECT_ATTACK_UP_HIT",
requiredTarget=0,requiredEffectChance=20,requiredProtect=1},
[318]={name="Silver Wind",sourceEffect=140,gen2Effect="EFFECT_ALL_UP_HIT",
requiredTarget=0,requiredEffectChance=10,requiredProtect=1},
[324]={name="Signal Beam",sourceEffect=76,gen2Effect="EFFECT_CONFUSE_HIT",
requiredTarget=0,requiredEffectChance=10,requiredProtect=1},
[341]={name="Mud Shot",sourceEffect=70,gen2Effect="EFFECT_SPEED_DOWN_HIT",
requiredTarget=0,requiredEffectChance=100,requiredProtect=1},
[352]={name="Water Pulse",sourceEffect=76,gen2Effect="EFFECT_CONFUSE_HIT",
requiredTarget=0,requiredEffectChance=20,requiredProtect=1},







[280]={name="Brick Break",sourceEffect=186,gen2Effect="EFFECT_NORMAL_HIT",
breakScreens=true,requiredTarget=0,requiredEffectChance=0,requiredProtect=1,
gen1Blocker="Brick Break: GC6E01 clears Reflect/Light Screen before damage; no audited Red screen-mutation seam is registered"},





[307]={name="Blast Burn",sourceEffect=80,gen2Effect="EFFECT_HYPER_BEAM"},
[308]={name="Hydro Cannon",sourceEffect=80,gen2Effect="EFFECT_HYPER_BEAM"},
[338]={name="Frenzy Plant",sourceEffect=80,gen2Effect="EFFECT_HYPER_BEAM"},
}

local blocked={
[181]="Powder Snow: Colosseum uses an exact 10/100 freeze roll; Red's available handler uses 26/256",
[185]="Faint Attack: DARK is absent from the Gen-I host type chart",
[186]="Sweet Kiss: Red converts accuracy to a 0..255 threshold; Colosseum rolls the source percentage in a 1..100 domain",
[200]="Outrage: Gen-III rampage duration/state semantics are not implemented by the active host kernels",
[209]="Spark: Colosseum uses a 30/100 paralysis roll; Red's available handler uses 77/256",
[223]="DynamicPunch: guaranteed post-hit confusion is not represented by the existing Red secondary handler",
[225]="Dragon Breath: Colosseum uses a 30/100 paralysis roll; Red's available handler uses 77/256",
[242]="Crunch: DARK plus the Gen-III Sp.Def secondary path is not exact on Red",
[247]="Shadow Ball: Red lowers unified Special, not Gen-III Special Defense",
[250]="Whirlpool: Gen-III partial-trap residual semantics remain unproven against the host kernel",
[257]="Heat Wave: post-hit probability/Substitute cadence is still under source audit",
[258]="Hail: GC6E01 effect 164 requires Hail weather/residual state absent from the active host executors",
[259]="Torment: GC6E01 effect 165 recurrence restrictions have no audited host executor",
[263]="Facade: GC6E01 effect 169 status-conditioned damage has no audited host executor",
[264]="Focus Punch: GC6E01 effect 170 focus/interruption state has no audited host executor",
[269]="Taunt: GC6E01 effect 175 move-restriction state has no audited host executor",
[285]="Skill Swap: GC6E01 effect 191 ability-swap/veto semantics have no audited challenge-local host seam",
[289]="Snatch: GC6E01 effect 195 interception/priority state has no audited host executor",
[290]="Secret Power: GC6E01 effect 197 environment-dependent secondary behavior has no audited host executor",
[291]="Dive: GC6E01 effect 155 underwater two-turn state is not represented by Gold's Fly/Dig-only vanish seam",
[292]="Arm Thrust: multi-hit per-hit damage/critical/random cadence is still under source audit",
[295]="Luster Purge: Gold's post-hit Sp.Def-drop path does not preserve pre-damage Substitute occupancy; exact GC6E01 secondary cadence remains unproven",
[301]="Ice Ball: Rollout-class lock/damage cadence is still under source audit",
[302]="Needle Arm: Gold checks Substitute only after damage for intrinsic flinch, so a broken Substitute loses the pre-hit guard; exact GC6E01 cadence remains unproven",
[304]="Hyper Voice: Soundproof/direct target-4 spread are source-proven, but Gen-II doubles Mirror Move re-enters the copied move against only its selected defender instead of re-expanding the copied foes target; Red's faithful 100%-accuracy path also retains the native 1/256 miss absent from GC6E01",
[306]="Crush Claw: Gold's post-hit Defense-drop path does not preserve pre-damage Substitute occupancy; exact GC6E01 secondary cadence remains unproven",
[310]="Astonish: Gold checks Substitute only after damage for intrinsic flinch, so a broken Substitute loses the pre-hit guard; exact GC6E01 cadence remains unproven",
[315]="Overheat: GC6E01 effect 204 post-hit Special Attack reduction has no exact audited host cadence",
[317]="Rock Tomb: Gold's post-hit Speed-drop path does not preserve pre-damage Substitute occupancy; exact GC6E01 secondary cadence remains unproven",
[320]="GrassWhistle: Soundproof timing is source-proven, but Gold still applies Gen-II accuracy-stage ratios plus its enemy-only 64/256 status-fail quirk and 1-7-turn sleep, while GC6E01 uses its Gen-III percentage/stage accuracy path and 1-5-turn sleep; Red uses the incompatible 0..255 accuracy domain",
[326]="Extrasensory: Gold checks Substitute only after damage for intrinsic flinch, so a broken Substitute loses the pre-hit guard; exact GC6E01 cadence remains unproven",
[328]="Sand Tomb: Gen-III partial-trap residual semantics remain unproven against the host kernel",
[329]="Sheer Cold: Gen-III level-based OHKO rules differ from the host OHKO implementations",
[330]="Muddy Water: spread + accuracy-drop post-hit cadence is still under source audit",
[331]="Bullet Seed: multi-hit per-hit damage/critical/random cadence is still under source audit",
[333]="Icicle Spear: multi-hit per-hit damage/critical/random cadence is still under source audit",
[339]="Bulk Up: GC6E01 effect 208 is a linked self Attack+Defense change and is Snatchable; no exact composite/Snatch host seam is audited",
[347]="Calm Mind: GC6E01 effect 211 is a linked self Sp.Atk+Sp.Def change and is Snatchable; no exact composite/Snatch host seam is audited",
[348]="Leaf Blade: Gen-III high-critical-hit rules differ from Red/Gold critical ladders",
[350]="Rock Blast: multi-hit per-hit damage/critical/random cadence is still under source audit",
}




local gen2PipelineEffects={
EFFECT_NORMAL_HIT=true,EFFECT_ALWAYS_HIT=true,EFFECT_ATTACK_UP=true,
EFFECT_DEFENSE_UP_2=true,EFFECT_HYPER_BEAM=true,
EFFECT_ATTACK_UP_HIT=true,EFFECT_ALL_UP_HIT=true,EFFECT_SPEED_DOWN_HIT=true,
}









local function registryContains(registry,id)
if type(registry)~="table" then return false end
if type(registry.get)=="function" then return registry:get(id)~=nil end
if type(registry.has)=="function" then return registry:has(id)==true end
return false
end

local function hostType(typeId,generation)
local sourceType=sourceTypes[tonumber(typeId)]
if not sourceType then return nil end
if tonumber(generation)==1 and (sourceType=="DARK" or sourceType=="STEEL") then return nil end
return sourceType=="PSYCHIC" and "PSYCHIC_TYPE" or sourceType
end

local function sourceRow(raw)
if type(Source)~="table" or Source.discId~="GC6E01" or type(Source.moves)~="table" then
return nil,"GC6E01 CommonMoveData source cache unavailable"
end
local row=Source.moves[raw]
if type(row)~="table" then return nil,("GC6E01 CommonMoveData row %d unavailable"):format(raw) end
if tonumber(row.rawMoveId)~=raw then return nil,("GC6E01 CommonMoveData identity mismatch for %d"):format(raw) end
return row
end

local function sourceProblem(raw,plan,generation)
local row,why=sourceRow(raw);if not row then return why end
if tonumber(row.effect)~=tonumber(plan.sourceEffect) then
return ("GC6E01 effect mismatch for %d: expected %d, source has %s")
:format(raw,plan.sourceEffect,tostring(row.effect))
end
if plan.requiredTarget~=nil and tonumber(row.target)~=tonumber(plan.requiredTarget) then
return ("GC6E01 target mismatch for %d: expected %d, source has %s")
:format(raw,plan.requiredTarget,tostring(row.target))
end
if plan.requiredEffectChance~=nil
and tonumber(row.effectChance)~=tonumber(plan.requiredEffectChance) then
return ("GC6E01 effect-chance mismatch for %d: expected %d, source has %s")
:format(raw,plan.requiredEffectChance,tostring(row.effectChance))
end
if plan.requiredProtect~=nil
and tonumber(row.blockedByProtect)~=tonumber(plan.requiredProtect) then
return ("GC6E01 Protect-flag mismatch for %d: expected %d, source has %s")
:format(raw,plan.requiredProtect,tostring(row.blockedByProtect))
end
if not sourceTargets[tonumber(row.target)] then
return ("GC6E01 target code %s is not implemented by the host bridge"):format(tostring(row.target))
end
local typ=hostType(row.typeId,generation)
if not typ then return ("GC6E01 type id %s is unavailable in host generation %d")
:format(tostring(row.typeId),generation) end
if tonumber(row.accuracy)==nil or tonumber(row.accuracy)<0 or tonumber(row.accuracy)>100
or tonumber(row.pp)==nil or tonumber(row.power)==nil or tonumber(row.priority)==nil then
return ("GC6E01 move %d has invalid core move fields"):format(raw)
end




local soundBased=tonumber(row.soundBased)
if soundBased~=0 and soundBased~=1 then
return ("GC6E01 move %d has invalid sound flag %s"):format(raw,tostring(row.soundBased))
end





local kingsRock=tonumber(row.kingsRockFlinch)
if generation==2 and tonumber(row.power)>0 and kingsRock~=0 and kingsRock~=1 then
return ("GC6E01 move %d has invalid King's-Rock flag %s"):format(raw,tostring(row.kingsRockFlinch))
end
if plan.alwaysHit and not (tonumber(row.effect)==17 and tonumber(row.accuracy)==0) then
return ("GC6E01 always-hit invariant failed for move %d"):format(raw)
end
return nil
end

local function record(raw,plan,generation)
generation=tonumber(generation) or 1
local effect=generation==2 and plan.gen2Effect or plan.gen1Effect
if not effect then
local blocker=generation==2 and plan.gen2Blocker or plan.gen1Blocker
return nil,blocker or "no exact host effect registered for this generation"
end
local problem=sourceProblem(raw,plan,generation);if problem then return nil,problem end
local row=assert(sourceRow(raw))
local out={
id="CMOVE_"..raw,name=plan.name,type=assert(hostType(row.typeId,generation)),
power=tonumber(row.power),accuracy=tonumber(row.accuracy),pp=tonumber(row.pp),
effect=effect,priority=tonumber(row.priority) or 0,highCrit=false,
makesContact=tonumber(row.makesContact)==1,
colosseumMoveId=raw,colosseumSource="GC6E01",colosseumSourceEffect=tonumber(row.effect),
colosseumTargetCode=tonumber(row.target),colosseumEffectChance=tonumber(row.effectChance) or 0,
colosseumBlockedByProtect=tonumber(row.blockedByProtect)==1,
colosseumMagicCoatReflects=tonumber(row.magicCoatReflects)==1,
colosseumSnatchSteals=tonumber(row.snatchSteals)==1,
colosseumMirrorMoveCopies=tonumber(row.mirrorMoveCopies)==1,
colosseumKingsRockFlinch=tonumber(row.kingsRockFlinch)==1,
colosseumSoundBased=tonumber(row.soundBased)==1,
}
if tonumber(row.effectChance) and tonumber(row.effectChance)>0 then out.effectChance=tonumber(row.effectChance) end
local target=sourceTargets[tonumber(row.target)]
if target~="selected" then out.colosseumTarget=target end
if plan.alwaysHit then out.colosseumAlwaysHit=true end
if plan.breakScreens then out.colosseumBreakScreens=true end
return out
end

function M.install(mod,generation)
generation=tonumber(generation) or 1
local content=mod and mod.content
local registry=content and content.moves
if not (registry and type(registry.register)=="function") then
return {generation=generation,installed=0,error="move content registry unavailable"}
end
local effects=content.move_effects
local installedEffects=0
if generation==2 and effects and type(effects.register)=="function" then
for id in pairs(gen2PipelineEffects) do
if not registryContains(effects,id) then
effects:register(id,{kind="full"});installedEffects=installedEffects+1
end
end
end
local installed,failures={},{}
for raw,plan in pairs(plans) do

if generation~=2 or raw>251 then
local def,why=record(raw,plan,generation)
if def then
if not registryContains(registry,def.id) then registry:register(def.id,def) end
installed[#installed+1]=raw
elseif (generation==2 and plan.gen2Effect) or (generation~=2 and plan.gen1Effect) then
failures[#failures+1]={rawMoveId=raw,reason=why}
end
end
end
table.sort(installed)
table.sort(failures,function(a,b)return a.rawMoveId<b.rawMoveId end)
return {generation=generation,installed=#installed,ids=installed,installedEffects=installedEffects,
failedClosed=#failures,failures=failures,source=Source and Source.source or nil}
end




local function mirrorBlocked(data,last)
local def=data and data.moves and last and data.moves[last]
return type(def)=="table" and def.colosseumMoveId~=nil
and def.colosseumMirrorMoveCopies==false
end








local function goldKingsRockBlocked(data,moveEvent)
local moveId=type(moveEvent)=="table" and moveEvent.move or nil
local def=data and data.moves and moveId and data.moves[moveId]
return type(def)=="table" and def.colosseumMoveId~=nil
and def.colosseumKingsRockFlinch==false
end








local function breakGoldScreens(self,defender,def)
if type(def)~="table" or def.colosseumBreakScreens~=true then return false end
if type(self)~="table" or type(self.screens)~="table" or type(self.sideOf)~="function" then
return false
end
local side=self.screens[self:sideOf(defender)]
if type(side)~="table" then return false end
local changed=(tonumber(side.reflect) or 0)>0 or (tonumber(side.lightScreen) or 0)>0
side.reflect=nil
side.lightScreen=nil
return changed
end

local function installGen1Runtime()
local req=V.engineRequire or require
local ok,BattleState=pcall(req,"src.battle.BattleState")
if not ok or type(BattleState)~="table" then return nil,"Gen-I BattleState unavailable" end
if BattleState.__cbeColosseumVerifiedMovesV2 then return true end
local originalAccuracy=BattleState.accuracyRoll
local originalPerform=BattleState.performMove
if type(originalAccuracy)~="function" or type(originalPerform)~="function" then
return nil,"Gen-I move runtime seams unavailable"
end
BattleState.accuracyRoll=function(self,move,user,target,...)


if type(move)=="table" and move.colosseumAlwaysHit==true then return true end
return originalAccuracy(self,move,user,target,...)
end
BattleState.performMove=function(self,user,target,moveInst,...)
local mirror=type(moveInst)=="table" and moveInst.id=="MIRROR_MOVE"
local last=mirror and target and target.lastMove or nil
if last and mirrorBlocked(self and self.data,last) then
target.lastMove=nil
local result=pack(pcall(originalPerform,self,user,target,moveInst,...))
target.lastMove=last
if not result[1] then error(result[2],0) end
return unpack(result,2,result.n)
end
return originalPerform(self,user,target,moveInst,...)
end
BattleState.__cbeColosseumVerifiedMovesV2=true
return true
end

local function installGen2Runtime()
local req=V.engineRequire or require
local ok,Battle=pcall(req,"src.battle.gen2.Battle")
if not ok or type(Battle)~="table" then return nil,"Gen-II Battle unavailable" end
local needsUse=not Battle.__cbeColosseumVerifiedMovesV2
local needsBreak=not Battle.__cbeColosseumBrickBreakScreens
local needsKingsRock=not Battle.__cbeColosseumKingsRockEligibility
local originalUse=Battle.useMove
local originalHit=Battle.hitOnce
local originalHeld=Battle.heldEffect
if needsUse and type(originalUse)~="function" then return nil,"Gen-II useMove seam unavailable" end
if needsBreak and type(originalHit)~="function" then return nil,"Gen-II hitOnce seam unavailable" end
if needsKingsRock and type(originalHeld)~="function" then return nil,"Gen-II held-item seam unavailable" end
if needsUse then
Battle.useMove=function(self,attacker,defender,moveId,...)
if moveId=="MIRROR_MOVE" and defender and type(self.volatile)=="function" then
local state=self:volatile(defender)
local last=state and state.lastMove
if last and mirrorBlocked(self and self.data,last) then
state.lastMove=nil
local result=pack(pcall(originalUse,self,attacker,defender,moveId,...))
state.lastMove=last
if not result[1] then error(result[2],0) end
return unpack(result,2,result.n)
end
end
return originalUse(self,attacker,defender,moveId,...)
end
end
if needsBreak then
Battle.hitOnce=function(self,attacker,defender,def,...)
breakGoldScreens(self,defender,def)
return originalHit(self,attacker,defender,def,...)
end
Battle.__cbeColosseumBrickBreakScreens=true
end
if needsKingsRock then
Battle.heldEffect=function(self,mon,trigger,...)
if trigger=="flinch" and goldKingsRockBlocked(self and self.data,self and self.moveEvent) then
return nil,0
end
return originalHeld(self,mon,trigger,...)
end
Battle.__cbeColosseumKingsRockEligibility=true
end
Battle.__cbeColosseumVerifiedMovesV2=true
return true
end

function M.installRuntime(_,generation)
generation=tonumber(generation) or 1
local ok,why=generation==2 and installGen2Runtime() or installGen1Runtime()
return {generation=generation,ready=ok==true,error=why}
end

function M.reason(raw,generation)
raw=tonumber(raw)
if blocked[raw] then return blocked[raw] end
local plan=plans[raw]
if not plan then return "no source-proven executable host mechanic registered" end
if generation~=nil then
local gen=tonumber(generation) or 1
local _,why=record(raw,plan,gen);return why
end


local rowWhy=sourceProblem(raw,plan,2) or sourceProblem(raw,plan,1)
return rowWhy or "source-proven move is not executable in the active host generation"
end
function M.canRegister(raw,generation)
raw=tonumber(raw);generation=tonumber(generation) or 1
local plan=plans[raw];if not plan then return false end
if generation==2 and raw<=251 then return false end
local def=record(raw,plan,generation)
return def~=nil
end
function M.definition(raw,generation)
raw=tonumber(raw);local plan=plans[raw]
return plan and record(raw,plan,tonumber(generation) or 1) or nil
end

M.records=plans
M.blocked=blocked
M._test={record=record,hostType=hostType,sourceTypes=sourceTypes,sourceTargets=sourceTargets,
sourceProblem=sourceProblem,sourceRow=sourceRow,mirrorBlocked=mirrorBlocked,
goldKingsRockBlocked=goldKingsRockBlocked,breakGoldScreens=breakGoldScreens,
gen2PipelineEffects=gen2PipelineEffects,installGen1Runtime=installGen1Runtime,
installGen2Runtime=installGen2Runtime}
return M
