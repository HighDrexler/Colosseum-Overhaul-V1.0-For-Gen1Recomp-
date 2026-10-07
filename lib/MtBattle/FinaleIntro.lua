













local FI={}

FI.FINALE_FIGHT=100






function FI.forceBossIntro(game)
local prefs=game and game.save and game.save.colosseumBattle
if type(prefs)~="table" then return function() end end
local original=prefs.bossIntroEnabled
prefs.bossIntroEnabled=true
return function() prefs.bossIntroEnabled=original end
end





function FI.gen2TrainerMeta(baseMeta)
local meta={}
for k,v in pairs(baseMeta or {}) do meta[k]=v end
meta.cbeBossIntro=true
meta.cbeBossCategory="champion"
return meta
end

function FI.isFinale(fightIndex)
return fightIndex==FI.FINALE_FIGHT
end

return FI
