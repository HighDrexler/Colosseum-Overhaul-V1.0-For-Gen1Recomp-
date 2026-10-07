





local TIG={}





TIG.PREFIXES={
"ACE","IRON","STONE","SWIFT","CRAG","EMBER","FROST","THUNDER","SHADOW",
"GALE","RIDGE","VOLT","QUARTZ","OBSIDIAN","CINDER","MIST","BRISK","GRIT",
"AMBER","ONYX","TEMPEST","HOLLOW","SILT","BRAMBLE","HALCYON","UMBRA",
"SPARK","GRANITE","MARSH","ZEPHYR",
}
TIG.SUFFIXES={
"KADE","REN","MORA","VESS","TARN","OKI","LYRA","BRAND","HOLT","VANE",
"WICK","ROSS","DAHL","FINN","QUILL","SORA","THORNE","WREN","GALEN","ASH",
"CASS","DRISK","EIRA","FALK","GARR","HESS","IONA","JODEL","KORA","LUNE",
}

TIG.TITLE_BY_PERSONALITY={
aggressive="BRAWLER",technical="TACTICIAN",defensive="SENTINEL",
disruptive="TRICKSTER",setup="STRATEGIST",unpredictable="WILDCARD",
}

TIG.AREA_LEADER_TITLE="AREA LEADER"
TIG.FINALE_NAME="THE MT. BATTLE MASTER"
TIG.FINALE_TITLE="MT. BATTLE MASTER"



function TIG.rollName(stream)
local prefix=stream:pick(TIG.PREFIXES)
local suffix=stream:pick(TIG.SUFFIXES)
return prefix..suffix
end






function TIG.generate(stream,fightIndex,isAreaLeader,personality)
if fightIndex==100 then
return {name=TIG.FINALE_NAME,personality=personality.id,title=TIG.FINALE_TITLE,fixed=true}
end
local name=TIG.rollName(stream)
local personalityTitle=TIG.TITLE_BY_PERSONALITY[personality.id] or "TRAINER"
local title=isAreaLeader and (TIG.AREA_LEADER_TITLE.." "..personalityTitle) or personalityTitle
return {name=name,personality=personality.id,title=title,fixed=false}
end

return TIG
