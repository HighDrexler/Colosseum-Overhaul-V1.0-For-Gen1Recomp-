






















local A={}






A.EXCLUDED_MOVES={
BIDE=true,COUNTER=true,MIRROR_COAT=true,MIRROR_MOVE=true,METRONOME=true,
MIMIC=true,SLEEP_TALK=true,FUTURE_SIGHT=true,BATON_PASS=true,
TRANSFORM=true,ATTRACT=true,PURSUIT=true,BEAT_UP=true,DESTINY_BOND=true,
NIGHTMARE=true,SKETCH=true,ROAR=true,WHIRLWIND=true,TELEPORT=true,


BIND=true,WRAP=true,FIRE_SPIN=true,CLAMP=true,
}







function A.isMoveAllowed(moveId,moveDef,adapter)
if not moveId or A.EXCLUDED_MOVES[moveId] then return false end
if adapter and type(adapter.supports)=="function" then
local ok=adapter:supports(moveDef)
if not ok then return false end
end
return true
end








A.STATUS_EFFECTS={
[1]={SLEEP_EFFECT=true,POISON_EFFECT=true,PARALYZE_EFFECT=true,
POISON_SIDE_EFFECT1=true,POISON_SIDE_EFFECT2=true,
PARALYZE_SIDE_EFFECT=true,PARALYZE_SIDE_EFFECT2=true,
BURN_SIDE_EFFECT1=true,BURN_SIDE_EFFECT2=true,
FREEZE_SIDE_EFFECT=true,CONFUSION_EFFECT=true,
CONFUSION_SIDE_EFFECT=true},
[2]={poison=true,paralyze=true,sleep=true,burn=true,freeze=true,confuse=true},
}
A.EVASION_EFFECTS={
[1]={EVASION_UP1_EFFECT=true,EVASION_UP2_EFFECT=true},
[2]={evasion_up=true},
}





A.STALL_EFFECTS={
[1]={HEAL_EFFECT=true,LEECH_SEED_EFFECT=true,TOXIC_EFFECT=true},
[2]={recover=true,leech_seed=true,toxic=true,rest=true,ingrain=true},
}






A.FRUSTRATION_CAPS={
statusMovesPerTeam=3,
evasionMovesPerTeam=1,
stallMovesPerTeam=3,
}

function A.effectCategory(taxonomy,generation,effectId)
local set=taxonomy[generation]
return set and effectId and set[effectId]==true
end






A.ARCHETYPES={
{id="balanced",label="Balanced",
roles={"sweeper","wall","support","revenge_killer","pivot","cleric"}},
{id="hyper_offense",label="Hyper Offense",
roles={"sweeper","sweeper","wallbreaker","suicide_lead","sweeper"}},
{id="bulky_offense",label="Bulky Offense",
roles={"bulky_attacker","wallbreaker","pivot","sweeper","wall"}},
{id="stall",label="Stall",
roles={"wall","wall","cleric","support","phazer"}},
{id="setup_sweep",label="Setup Sweep",
roles={"setup_sweeper","support","wall","pivot","setup_sweeper"}},
{id="speed_control",label="Speed Control",
roles={"speed_control","sweeper","pivot","wall","support"}},
}





function A.pickArchetype(stream)
return stream:pick(A.ARCHETYPES)
end

return A
