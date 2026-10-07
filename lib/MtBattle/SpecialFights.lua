










local SF={}












SF.LEGENDARIES={
ARTICUNO=true,ZAPDOS=true,MOLTRES=true,MEWTWO=true,MEW=true,
RAIKOU=true,ENTEI=true,SUICUNE=true,LUGIA=true,HO_OH=true,CELEBI=true,






REGIROCK=true,REGICE=true,REGISTEEL=true,LATIAS=true,LATIOS=true,
KYOGRE=true,GROUDON=true,RAYQUAZA=true,JIRACHI=true,DEOXYS=true,
}

function SF.isLegendary(speciesId)
return SF.LEGENDARIES[speciesId]==true
end


SF.LEGENDARY_GATE_FIGHT=40








SF.EEVEELUTIONS={"VAPOREON","JOLTEON","FLAREON","ESPEON","UMBREON"}
SF.EEVEE="EEVEE"

function SF.isEeveelution(speciesId)
for _,id in ipairs(SF.EEVEELUTIONS) do
if id==speciesId then return true end
end
return false
end


SF.EEVEELUTION_FIGHT=49

function SF.isEeveelutionFight(fightIndex)
return fightIndex==SF.EEVEELUTION_FIGHT
end



















function SF.gateEligible(eligibleSpeciesIds,fightIndex)
local out={}
for _,id in ipairs(eligibleSpeciesIds or {}) do
local blockedLegendary=fightIndex<SF.LEGENDARY_GATE_FIGHT and SF.isLegendary(id)



local blockedEeveelution=fightIndex<SF.EEVEELUTION_FIGHT and (SF.isEeveelution(id) or id==SF.EEVEE)
if not (blockedLegendary or blockedEeveelution) then out[#out+1]=id end
end
return out
end









function SF.eeveelutionSpeciesList(data,teamSize,stream,eligibleSpeciesIds)
local allowed=nil
if type(eligibleSpeciesIds)=="table" then
allowed={};for _,id in ipairs(eligibleSpeciesIds) do allowed[id]=true end
end
local available={}
for _,id in ipairs(SF.EEVEELUTIONS) do
local def=data.pokemon and data.pokemon[id]
if def and def.baseStats and def.types and (not allowed or allowed[id]) then available[#available+1]=id end
end




for i=#available,2,-1 do
local j=stream:nextInt(1,i)
available[i],available[j]=available[j],available[i]
end
local out={}
for i=1,math.min(teamSize,#available) do out[#out+1]=available[i] end
local eeveeDef=data.pokemon and data.pokemon[SF.EEVEE]
local eeveeOk=eeveeDef and eeveeDef.baseStats and eeveeDef.types and (not allowed or allowed[SF.EEVEE])
while #out<teamSize and eeveeOk do out[#out+1]=SF.EEVEE end





local i=1
while #out<teamSize and #available>0 do
out[#out+1]=available[((i-1)%#available)+1];i=i+1
end
return out
end






SF.DOUBLE_ACE_FIGHT=100

function SF.aceCountFor(fightIndex)
if fightIndex==SF.DOUBLE_ACE_FIGHT then return 2 end
return 1
end

return SF
