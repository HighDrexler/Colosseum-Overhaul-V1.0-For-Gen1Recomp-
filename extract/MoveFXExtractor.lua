local V=...
local FSYS,GX,HSD=V.FSYS,V.GXTexture,V.HSD
local Waza=V.WazaSequenceExtractor
local Persist=V.PayloadPreserver
local SpeciesIndex=V.ColosseumSpeciesIndex
local RETAIL_MODEL_IDENTITY_REVISION=3
local M={revision=38,runtimeRevision=35,releaseRevision=35,mod=nil,openDisc=nil,memory={},negative={},pending={},pendingKeys={},prefetchFailures={},prefetchStats={queued=0,completed=0,failed=0},
sourceMoveRows=nil,retailModelOverrides=nil,retailModelOverridesMeta=nil,indexMemory=nil,preserveExistingWrites=false}
local function checkpoint(label)
local W=M.runtime and M.runtime.WorkBudget
if W then W.checkpoint(label) end
end

local MOVE={
[33]={stem="taiatari",phases={"attack","damage"},style="impact",tint={1.00,0.96,0.82}},
[40]={stem="dokubari",phases={"attack","damage"},style="projectile",tint={0.72,0.42,0.92}},
[45]={stem="nakigoe",phases={"attack","sp1"},style="aura",tint={0.92,0.96,1.00}},
[52]={stem="hinoko",phases={"attack","damage","sp1"},style="projectile",tint={1.00,0.48,0.12}},
[53]={stem="kaenhousya",phases={"attack","damage","sp1"},style="projectile",tint={1.00,0.42,0.12}},
[57]={stem="naminori",phases={"attack","damage","sp1"},style="wave",tint={0.36,0.72,1.00}},
[59]={stem="fubuki",phases={"attack","damage","sp1"},style="wave",tint={0.72,0.92,1.00}},
[63]={stem="hakai",phases={"attack","damage"},style="projectile",tint={1.00,0.86,0.34}},
[64]={stem="tsutsuku",phases={"attack","damage"},style="impact",tint={1.00,0.95,0.82}},
[81]={stem="itowohaku",phases={"attack","damage"},style="projectile",tint={0.80,0.95,0.64}},
[85]={stem="10manvolt",phases={"attack","damage"},style="target",tint={1.00,0.90,0.12}},
[106]={stem="katakunaru",phases={"special"},style="self",tint={0.86,0.88,0.92}},
[172]={stem="kaenguruma",phases={"attack","damage","sp1"},style="contact",tint={1.00,0.38,0.08}},
[193]={stem="miyaburu",phases={"attack","damage"},style="target",tint={0.80,0.70,1.00}},
}
local NAME={
tackle=33,poisonsting=40,growl=45,ember=52,flamethrower=53,surf=57,blizzard=59,hyperbeam=63,
peck=64,stringshot=81,thunderbolt=85,harden=106,flamewheel=172,foresight=193,
}





local DIRECT={}
for _,name in ipairs({
"karatechop","cometpunch","sonicboom","counter","megadrain","solarbeam",
"teleport","barrier","smog","flash","sketch","triplekick","aeroblast",
"machpunch","lockon","gigadrain","endure","spark","present","megahorn",
"encore","irontail","metalclaw","crosschop","mirrorcoat","shadowball",
}) do DIRECT[name]=name end







local SOURCE_STEM_ALIASES={
[1]={"hataku"},
[2]={"karatechop","karatechoppu"},
[3]={"oufukubinta","oufuku"},
[4]={"renzokupunch","renzokupanchi","renzoku"},
[5]={"megatonpunch","megatonpanchi"},
[6]={"nekonikoban"},
[7]={"honoonopunch","honoonopanchi","honoonopanti"},
[8]={"reitoupunch","reitoupanchi"},
[9]={"kaminaripunch","kaminaripanchi"},
[10]={"hikkaku"},
[11]={"hasamu"},
[12]={"hasamiguillotine","hasamigirochin","hasami"},
[13]={"kamaitachi"},
[14]={"tsuruginomai","turuginomai"},
[15]={"iaigiri"},
[16]={"kazeokoshi"},
[17]={"tsubasadeutsu","tsubasa"},
[18]={"fukitobashi"},
[19]={"sorawotobu"},
[20]={"shimetsukeru"},
[21]={"tatakitsukeru","tataki"},
[22]={"tsurunomuchi","tsuru"},
[23]={"fumitsuke"},
[24]={"nidogeri"},
[25]={"megatonkick","megatonkikku"},
[26]={"tobigeri"},
[27]={"mawashigeri","mawashi"},
[28]={"sunakake"},
[29]={"zutsuki"},
[30]={"tsunodetsuku","tsuno"},
[31]={"midarezuki","midareduki"},
[32]={"tsunodrill","tsunodoriru"},
[33]={"taiatari"},
[34]={"noshikakari"},
[35]={"makitsuku"},
[36]={"tosshin"},
[37]={"abareru"},
[38]={"sutemitackle","sutemi"},
[39]={"shippowofuru"},
[40]={"dokubari"},
[41]={"doubleneedle","daburuniidoru"},
[42]={"missilebari","misairubari"},
[43]={"niramitsukeru","niramitukeru"},
[44]={"kamitsuku","kamituku"},
[45]={"nakigoe"},
[46]={"hoeru"},
[47]={"utau"},
[48]={"chouonpa","tyouonpa"},
[49]={"sonicboom","sonikkubuumu"},
[50]={"kanashibari"},
[51]={"youkaieki"},
[52]={"hinoko"},
[53]={"kaenhousya","kaenhousha"},
[54]={"shiroikiri"},
[55]={"mizudeppou"},
[56]={"hydropump","haidoroponpu"},
[57]={"naminori"},
[58]={"reitoubeam","reitoubiimu"},
[59]={"fubuki"},
[60]={"saikekousen","psybeam","psyche"},
[61]={"bubblekousen","baburukousen","barburukousen"},
[62]={"aurorabeam","oororabiimu","ourorabeam"},
[63]={"hakaikousen","hakai"},
[64]={"tsutsuku"},
[65]={"drillkuchibashi","dorirukuchibashi","drill"},
[66]={"jigokuguruma","jigoku"},
[67]={"ketaguri"},
[68]={"counter","kauntaa"},
[69]={"chikyuunage","chikyunage"},
[70]={"kairiki"},
[71]={"suitoru"},
[72]={"megadrain","megadorein"},
[73]={"yadoriginotane","yadorigi"},
[74]={"seichou","seityou"},
[75]={"happacutter","happakattaa","happa"},
[76]={"solarbeam","sooraabiimu"},
[77]={"dokunokona"},
[78]={"shibiregona","shibire"},
[79]={"nemurigona","nemuri"},
[80]={"hanabiranomai","hanabira"},
[81]={"itowohaku"},
[82]={"ryuunoikari","ryunoikari"},
[83]={"honoonouzu"},
[84]={"denkishoock","denkisyokku","denkiskock","denkishock"},
[85]={"10manvolt","10manboruto"},
[86]={"denjiha"},
[87]={"kaminari"},
[88]={"iwaotoshi"},
[89]={"jishin","jisin"},
[90]={"jiware","ziware"},
[91]={"anawohoru"},
[92]={"dokudoku"},
[93]={"nenriki"},
[94]={"psychokinesis","saikokineshisu","psycho"},
[95]={"saiminjutsu","saimin"},
[96]={"yoganopose","yoga"},
[97]={"kousokuidou","kousoku"},
[98]={"denkousekka","denkou"},
[99]={"ikari"},
[100]={"teleport","tereport"},
[101]={"nighthead","naitoheddo"},
[102]={"monomane"},
[103]={"iyanaoto"},
[104]={"kagebunshin"},
[105]={"jikosaisei"},
[106]={"katakunaru"},
[107]={"chiisakunaru","tiisakunaru"},
[108]={"enmaku"},
[109]={"ayashiihikari","ayashii"},
[110]={"karanikomoru"},
[111]={"marukunaru"},
[112]={"barrier","bariaa"},
[113]={"hikarinokabe","hikari"},
[114]={"kuroikiri"},
[115]={"reflect","rifurekutaa","reflector"},
[116]={"kiaidame"},
[117]={"gaman"},
[118]={"yubiwofuru"},
[119]={"oumugaeshi","oumugaesi"},
[120]={"jibaku"},
[121]={"tamagobakudan","tamagobomb"},
[122]={"shitadenameru","shita"},
[123]={"smog","sumoggu"},
[124]={"hedorokougeki"},
[125]={"honekonbou"},
[126]={"daimonji"},
[127]={"takinobori","taki"},
[128]={"karadehasamu"},
[129]={"speedstar","supiidosutaa"},
[130]={"rocketzutsuki","rokettouzuki","rocket"},
[131]={"togecannon","togekyanon"},
[132]={"karamitsuku","karami"},
[133]={"dowasure"},
[134]={"spoonmage","supuunmage"},
[135]={"tamagoumi"},
[136]={"tobihizageri","tobihiza"},
[137]={"hebinirami"},
[138]={"yumekui"},
[139]={"dokugas","dokugasu"},
[140]={"tamanage"},
[141]={"kyuuketsu"},
[142]={"akumanokiss","akumanokissu"},
[143]={"godbird","goddobaado"},
[144]={"henshin"},
[145]={"awa"},
[146]={"piyopiyopunch","piyopiyopanchi","piyopiyo"},
[147]={"kinokonohoushi","kinoko"},
[148]={"flash","furasshu"},
[149]={"psychowave","saikowave"},
[150]={"haneru"},
[151]={"tokeru"},
[152]={"crabhammer","kurabuhanmaa","kurabuhanmer"},
[153]={"daibakuhatsu"},
[154]={"midarehikkaki"},
[155]={"honeboomerang","honebuumeran","honeboomeran"},
[156]={"nemuru"},
[157]={"iwanadare"},
[158]={"hissatsumaeba","hissatsu"},
[159]={"kakubaru"},
[160]={"texture","tekusuchaa"},
[161]={"triattack","toraiatakku","tryattack"},
[162]={"ikarinomaeba"},
[163]={"kirisaku"},
[164]={"migawari"},
[165]={"waruagaki"},
[166]={"sketch","sukecchi"},
[167]={"triplekick","toripurukikku"},
[168]={"dorobou"},
[169]={"kumonosu"},
[170]={"kokoronome"},
[171]={"akumu"},
[172]={"kaenguruma"},
[173]={"ibiki"},
[174]={"noroi"},
[175]={"jitabata"},
[176]={"texture2","tekusuchaa2"},
[177]={"aeroblast","earoburasuto"},
[178]={"watahoushi","wata"},
[179]={"kishikaisei","kisikaisei"},
[180]={"urami"},
[181]={"konayuki"},
[182]={"mamoru"},
[183]={"machpunch","mahapanchi"},
[184]={"kowaikao"},
[185]={"damashiuchi","damasiuti"},
[186]={"tenshinokiss","tenshinokissu"},
[187]={"haradaiko"},
[188]={"hedorobakudan"},
[189]={"dorokake"},
[190]={"octanhou","okutanhou"},
[191]={"makibishi","makibisi"},
[192]={"denjihou"},
[193]={"miyaburu"},
[194]={"michizure","michidure"},
[195]={"horobinouta"},
[196]={"kogoerukaze"},
[197]={"mikiri"},
[198]={"bonerush","boonrasshu","boonrush"},
[199]={"lockon","rokkuon"},
[200]={"gekirin"},
[201]={"sunaarashi"},
[202]={"gigadrain","gigadorein"},
[203]={"koraeru","endure"},
[204]={"amaeru"},
[205]={"korogaru"},
[206]={"mineuchi"},
[207]={"ibaru"},
[208]={"milkonomi","mirukunomi","milknomi"},
[209]={"spark","supaaku"},
[210]={"renzokugiri"},
[211]={"haganenotsubasa","hagane"},
[212]={"kuroimanazashi"},
[213]={"meromero"},
[214]={"negoto"},
[215]={"iyashinosuzu"},
[216]={"ongaeshi"},
[217]={"present","purezento"},
[218]={"yatsuatari"},
[219]={"shinpinomamori","sinpi"},
[220]={"itamiwake"},
[221]={"seinaruhonoo","seinaru"},
[222]={"magnitude","magunichuudo","magunityuudo"},
[223]={"bakuretsupunch","bakuretsupanchi","bakuretsu"},
[224]={"megahorn","megahoon"},
[225]={"ryuunoibuki","ryunoibuki"},
[226]={"batontouch","batontacchi"},
[227]={"encore","ankooru"},
[228]={"oiuchi","oiuti"},
[229]={"kousokuspin","kousokusupin"},
[230]={"amaikaori"},
[231]={"irontail","aiantairu"},
[232]={"metalclaw","metarukuroo"},
[233]={"ateminage"},
[234]={"asanohizashi","asanohizasi"},
[235]={"kougousei"},
[236]={"tsukinohikari","tukinohikari"},
[237]={"mezamerupower","mezamerupawaa"},
[238]={"crosschop","kurosuchoppu"},
[239]={"tatsumaki"},
[240]={"amagoi"},
[241]={"nihonbare"},
[242]={"kamikudaku"},
[243]={"mirrorcoat","miraakooto"},
[244]={"jikoanji"},
[245]={"shinsoku"},
[246]={"genshinochikara","genshi"},
[247]={"shadowball","shadoobooru"},
[248]={"miraiyochi"},
[249]={"iwakudaki"},
[250]={"uzushio","uzusio"},
[251]={"fukurodataki","hukuro"},










[257]={"neppuu"},
[292]={"tsuppari"},
[295]={"lusterpurge"},
[304]={"hypervoice"},
[320]={"kusabue"},
[324]={"signalbeam"},
[325]={"shadowpunch"},
[332]={"tsubame"},
[337]={"dragonclaw"},
[345]={"magicalleaf"},
[348]={"lfblade"},
[350]={"rockblast"},
[352]={"mizunohadou"},







[302]={"needlearm"},
[310]={"odorokasu"},
[326]={"jintsuriki"},
[328]={"sunajigoku"},
[329]={"zettaireido"},
[336]={"tooboe"},
}




local SOURCE_STEM_ALIASES_COUNT=0
for _ in pairs(SOURCE_STEM_ALIASES) do SOURCE_STEM_ALIASES_COUNT=SOURCE_STEM_ALIASES_COUNT+1 end

local function addUnique(out,seen,value)
value=tostring(value or ""):lower():gsub("[^%w]","")
if value~="" and not seen[value] then seen[value]=true;out[#out+1]=value end
end
local function stemVariants(value,out,seen)
value=tostring(value or ""):lower():gsub("[^%w]","")
addUnique(out,seen,value)



local swaps={
{"sha","sya"},{"shu","syu"},{"sho","syo"},{"shi","si"},
{"cha","tya"},{"chu","tyu"},{"cho","tyo"},{"chi","ti"},
{"ja","zya"},{"ju","zyu"},{"jo","zyo"},{"ji","zi"},
}
for _,pair in ipairs(swaps) do
if value:find(pair[1],1,true) then addUnique(out,seen,(value:gsub(pair[1],pair[2]))) end
if value:find(pair[2],1,true) then addUnique(out,seen,(value:gsub(pair[2],pair[1]))) end
end
end
local function sourceStemCandidates(p,id,move)
local out,seen={},{}




local sourceRow=M.sourceMoveRows and M.sourceMoveRows[tonumber(id)] or nil
if sourceRow and sourceRow.primaryStem then stemVariants(sourceRow.primaryStem,out,seen) end
for _,animationId in ipairs(sourceRow and {sourceRow.primaryAnimationId,sourceRow.secondaryAnimationId} or {}) do
for _,v in ipairs(SOURCE_STEM_ALIASES[tonumber(animationId)] or {}) do stemVariants(v,out,seen) end
end
stemVariants(p and p.stem,out,seen)
for _,v in ipairs((p and p.stems) or {}) do stemVariants(v,out,seen) end
for _,v in ipairs(SOURCE_STEM_ALIASES[tonumber(id)] or {}) do stemVariants(v,out,seen) end
if type(move)=="table" then stemVariants(move.name or move.id or move.move,out,seen) end
return out
end




local SOURCE_STYLE_OVERRIDES={
[17]="contact",
[60]="projectile",
[94]="target",
}

local TYPE_TINT={
FIRE={1.00,.42,.12},WATER={.34,.70,1.00},ICE={.70,.92,1.00},
ELECTRIC={1.00,.90,.12},GRASS={.48,.86,.34},POISON={.72,.42,.92},
PSYCHIC={.92,.50,1.00},DARK={.48,.38,.72},GHOST={.64,.48,.88},
ROCK={.74,.64,.46},GROUND={.72,.56,.36},STEEL={.72,.78,.86},
}

local function inferredProfile(stem,move)
local category=type(move)=="table" and tostring(move.category or move.damageClass or move.class or ""):lower() or ""
local power=type(move)=="table" and tonumber(move.power) or nil
local typ=type(move)=="table" and tostring(move.type or ""):upper():gsub("[^A-Z]","") or ""
local style=(category:find("status",1,true) or (power and power<=0)) and "target" or "impact"
if style~="target" and (typ=="FIRE" or typ=="WATER" or typ=="ICE" or typ=="ELECTRIC"
or typ=="GRASS" or typ=="POISON" or typ=="PSYCHIC" or typ=="GHOST") then style="projectile" end
return {stem=stem,phases={},style=style,tint=TYPE_TINT[typ] or {1,1,1},direct=true}
end

local function norm(s)
return tostring(s or ""):lower():gsub("[^%w]","")
end
local function profile(moveId,move)



local id=tonumber(moveId) or (type(move)=="table" and (tonumber(move.index) or tonumber(move.colosseumMoveId)))
local p=id and MOVE[id] or nil
local sourceRow=M.sourceMoveRows and M.sourceMoveRows[id]
if not p and sourceRow and sourceRow.primaryStem then
p=inferredProfile(sourceRow.primaryStem,move);p.candidate=true
end


if not p and id and id>=252 and id<=354 then
p=inferredProfile('move'..id,move);p.candidate=true
end
if not p and id and SOURCE_STEM_ALIASES[id] then
p=inferredProfile(SOURCE_STEM_ALIASES[id][1],move);p.stems=SOURCE_STEM_ALIASES[id];p.candidate=true
end
if not p and type(move)=="table" then
local key=norm(move.name or move.id or move.move)
local mapped=NAME[key]
p=mapped and MOVE[mapped] or nil; id=id or mapped
if not p and id and SOURCE_STEM_ALIASES[id] then
p=inferredProfile(SOURCE_STEM_ALIASES[id][1],move);p.stems=SOURCE_STEM_ALIASES[id];p.candidate=true
end
if not p and DIRECT[key] then p=inferredProfile(DIRECT[key],move) end





if not p and key~="" then
p=inferredProfile(key,move);p.candidate=true
end
end
if p and id and SOURCE_STYLE_OVERRIDES[id] then
local copy={};for k,v in pairs(p) do copy[k]=v end
copy.style=SOURCE_STYLE_OVERRIDES[id]
p=copy
end
return p,id
end

local function describe(moveId,move)
local p,id=profile(moveId,move)
if not p then return nil end
local stems=sourceStemCandidates(p,id,move)
return {moveId=id,stem=stems[1] or p.stem,stems=stems,style=p.style,tint=p.tint,phases=p.phases}
end
function M.describe(moveId,move) return describe(moveId,move) end
function M.mapped(moveId,move) return describe(moveId,move)~=nil end

local function be16(s,p)
local a,b=s:byte(p+1,p+2); if not b then return nil end
return a*256+b
end
local function be32(s,p)
local a,b,c,d=s:byte(p+1,p+4); if not d then return nil end
return ((a*256+b)*256+c)*256+d
end



local write,serialize,cacheReadLua,extractSourceMoveRows






local function dolReadVirtual(disc,address,size)
if not (disc and type(disc.read)=="function") then return nil,"disc raw reader unavailable" end
address=tonumber(address);size=tonumber(size)
if not (address and size and size>=0) then return nil,"invalid DOL virtual range" end
local header=disc.header
if type(header)~="string" or #header<0x424 then
local ok,value=pcall(disc.read,disc,0,0x440);if not ok then return nil,tostring(value) end
header=value
end
local dolOffset=type(header)=="string" and be32(header,0x420) or nil
if not dolOffset or dolOffset<=0 then return nil,"main.dol offset unavailable" end
local okDol,dolHeader=pcall(disc.read,disc,dolOffset,0x100)
if not okDol or type(dolHeader)~="string" or #dolHeader<0xD8 then return nil,"main.dol header unavailable" end
local function seekSections(fileBase,addressBase,sizeBase,count)
for i=0,count-1 do
local fileOff=be32(dolHeader,fileBase+i*4)
local virtual=be32(dolHeader,addressBase+i*4)
local bytes=be32(dolHeader,sizeBase+i*4)
if fileOff and virtual and bytes and bytes>0 and address>=virtual and address+size<=virtual+bytes then
local ok,data=pcall(disc.read,disc,dolOffset+fileOff+(address-virtual),size)
if ok and type(data)=="string" and #data==size then return data end
return nil,tostring(data or "short DOL read")
end
end
end
local data,why=seekSections(0x00,0x48,0x90,7);if data then return data end
data,why=seekSections(0x1C,0x64,0xAC,11);if data then return data end
return nil,why or ("DOL VA not mapped: 0x%08X"):format(address)
end








local function extractRetailModelOverrides(disc)
local blob,why=dolReadVirtual(disc,0x80373750,0x16F0)
if not blob then return nil,why end
local byGroup,rows={},{}
for index=1,0x11B do
local at=index*0x10
local variant=blob:byte(at+1) or 0
local modelId=be16(blob,at+2)
local animationGroup=be16(blob,at+4)
local resourceGroup=be32(blob,at+8)
local resourceId=be32(blob,at+0x0C)
if modelId and animationGroup and resourceGroup and animationGroup>0 and resourceGroup>0 then
local row={index=index,variant=variant,modelId=modelId,animationGroup=animationGroup,
resourceGroup=resourceGroup,resourceId=resourceId}
rows[#rows+1]=row
byGroup[animationGroup]=byGroup[animationGroup] or {};byGroup[animationGroup][#byGroup[animationGroup]+1]=row
end
end
return byGroup,{source="GC6E01 main.dol lbl_80373750 / fn_801DDEE4 type-1 model override",address=0x80373750,
first=1,lastExclusive=0x11C,stride=0x10,rows=#rows}
end

local function fsysResourceGroup(disc,file)
if not (disc and file and type(disc.readFile)=="function") then return nil end
local ok,header=pcall(disc.readFile,disc,file,0,12)
if not ok or type(header)~="string" or header:sub(1,4)~="FSYS" then return nil end
return be32(header,8)
end

local function retailModelPhaseMap(sourceRows,overrides,moveId,banks)
local sourceRow=sourceRows and sourceRows[tonumber(moveId)] or nil
local animationGroup=sourceRow and tonumber(sourceRow.primaryAnimationId) or nil
if not animationGroup then return {},{},nil end
local phasesByResource={}
for _,bank in ipairs(banks or {}) do
if tonumber(bank.resourceGroup) then phasesByResource[tonumber(bank.resourceGroup)]=bank.phase end
end
local mapped,blocked,details,forms={}, {}, {}, {}
for _,row in ipairs((overrides and overrides[animationGroup]) or {}) do



if tonumber(row.variant)==0 then
local modelId=tonumber(row.modelId);local phase=phasesByResource[tonumber(row.resourceGroup)]
if modelId and modelId>=1 then
local dex=modelId<=251 and modelId or (SpeciesIndex and SpeciesIndex.dexForModelInternal and SpeciesIndex.dexForModelInternal(modelId))
local rec={modelId=modelId,dex=dex,phase=phase,resourceGroup=row.resourceGroup,resourceId=row.resourceId,index=row.index}
details[#details+1]=rec
if not dex then
blocked[modelId]="retail model id has no proven National Dex mapping"
elseif SpeciesIndex and SpeciesIndex.FORM_INTERNAL_TO_DEX and SpeciesIndex.FORM_INTERNAL_TO_DEX[modelId] then
if phase then forms[modelId]=phase
else blocked[dex]=("retail form model override FSYS 0x%X was not decoded"):format(tonumber(row.resourceGroup) or 0) end
elseif phase then
if mapped[dex] and mapped[dex]~=phase then
mapped[dex]=nil;blocked[dex]="retail model override resolves to multiple attack chapters"
elseif not blocked[dex] then mapped[dex]=phase end
else
blocked[dex]=("retail model override FSYS 0x%X was not decoded for this Waza stem"):format(tonumber(row.resourceGroup) or 0)
end
end
end
end
return mapped,blocked,{animationGroup=animationGroup,rows=details,source="GC6E01 main.dol model-specific attack resolver"},forms
end

local SOURCE_SELECTOR_CACHE="cache/movefx/source_selectors_v2.lua"
local function saveRetailSelectorCache(preserveExisting)
if not (M.sourceMoveRows and M.retailModelOverrides and write and serialize) then return false end
return write(SOURCE_SELECTOR_CACHE,"return "..serialize({revision=2,discId="GC6E01",
moveRows=M.sourceMoveRows,modelOverrides=M.retailModelOverrides,modelOverridesMeta=M.retailModelOverridesMeta}).."\n",preserveExisting)
end
local function ensureRetailSelectorSources(disc)
if M.sourceMoveRows and M.retailModelOverrides then return true end
if cacheReadLua then
local cached=cacheReadLua(SOURCE_SELECTOR_CACHE)
if type(cached)=="table" and cached.revision==2 and cached.discId=="GC6E01"
and type(cached.moveRows)=="table" and cached.moveRows[354] and type(cached.modelOverrides)=="table" then
M.sourceMoveRows=cached.moveRows;M.retailModelOverrides=cached.modelOverrides;M.retailModelOverridesMeta=cached.modelOverridesMeta
return true
end
end
if not disc then return false,"retail selector cache unavailable" end
local rows,rowsMeta=extractSourceMoveRows(disc)
if not rows then return false,"Colosseum move animation table unavailable: "..tostring(rowsMeta) end
local overrides,overrideMeta=extractRetailModelOverrides(disc)
if not overrides then return false,"Colosseum model-specific attack table unavailable: "..tostring(overrideMeta) end
M.sourceMoveRows=rows;M.retailModelOverrides=overrides;M.retailModelOverridesMeta=overrideMeta
saveRetailSelectorCache(true)
return true
end





local function ensureSpecRetailModelMove(spec,moveId)
moveId=tonumber(moveId)
if not (type(spec)=="table" and moveId and M.sourceMoveRows and M.retailModelOverrides) then return false end
spec.retailModelSelectionDone=type(spec.retailModelSelectionDone)=="table" and spec.retailModelSelectionDone or {}
spec.retailModelIdentityRevisionByMove=type(spec.retailModelIdentityRevisionByMove)=="table" and spec.retailModelIdentityRevisionByMove or {}
if spec.retailModelSelectionDone[moveId] and spec.retailModelIdentityRevisionByMove[moveId]==RETAIL_MODEL_IDENTITY_REVISION
and (moveId<=251 or (spec.retailResourceSelectionDone or {})[moveId]) then return false end
local banks={}
for _,phase in ipairs(spec.wazaPhases or {}) do
local resourceGroup=tonumber(phase.resourceGroup)
if resourceGroup then banks[#banks+1]={phase=phase.name or phase.phase,resourceGroup=resourceGroup} end
end
local mapped,blocked,source,forms=retailModelPhaseMap(M.sourceMoveRows,M.retailModelOverrides,moveId,banks)
spec.retailModelPhasesByMove=type(spec.retailModelPhasesByMove)=="table" and spec.retailModelPhasesByMove or {}
spec.retailFormPhasesByMove=type(spec.retailFormPhasesByMove)=="table" and spec.retailFormPhasesByMove or {}
spec.retailModelOverrideBlockersByMove=type(spec.retailModelOverrideBlockersByMove)=="table" and spec.retailModelOverrideBlockersByMove or {}
spec.retailModelOverrideSourceByMove=type(spec.retailModelOverrideSourceByMove)=="table" and spec.retailModelOverrideSourceByMove or {}
spec.retailModelPhasesByMove[moveId]=mapped
spec.retailFormPhasesByMove[moveId]=forms
spec.retailModelOverrideBlockersByMove[moveId]=blocked
spec.retailModelOverrideSourceByMove[moveId]=source
spec.retailModelSelectionDone[moveId]=true
spec.retailModelIdentityRevisionByMove[moveId]=RETAIL_MODEL_IDENTITY_REVISION
spec.retailResourceSelectionDone=spec.retailResourceSelectionDone or {}
spec.retailResourceSelectionDone[moveId]=true


if tonumber(spec.moveId)==moveId then
spec.retailModelPhases=mapped;spec.retailModelOverrideBlockers=blocked;spec.retailModelOverrideSource=source
end
if type(spec.coverage)=="table" and type(spec.coverage.unsupported)=="table" then
for i=#spec.coverage.unsupported,1,-1 do
local row=spec.coverage.unsupported[i]
if row and row.phase=="attack-override" and tonumber(row.moveId)==moveId then table.remove(spec.coverage.unsupported,i) end
end
for modelId,why in pairs(blocked or {}) do
spec.coverage.unsupported[#spec.coverage.unsupported+1]={phase="attack-override",index=modelId,moveId=moveId,
kind="retail-model-selector",reason=why}
end
end
local mappedCount,blockedCount=0,0
for _,rows in pairs(spec.retailModelPhasesByMove) do for _ in pairs(rows or {}) do mappedCount=mappedCount+1 end end
for _,rows in pairs(spec.retailModelOverrideBlockersByMove) do for _ in pairs(rows or {}) do blockedCount=blockedCount+1 end end
spec.retailModelOverrideCount=mappedCount;spec.retailModelOverrideBlockedCount=blockedCount
spec.retailModelOverridesReady=blockedCount==0
return true
end
local function specRetailSelectionReady(spec,moveId)
moveId=tonumber(moveId)
if not moveId then return true end
local done=type(spec)=="table" and spec.retailModelSelectionDone or nil
return type(done)=="table" and done[moveId]==true
and type(spec.retailModelIdentityRevisionByMove)=="table"
and spec.retailModelIdentityRevisionByMove[moveId]==RETAIL_MODEL_IDENTITY_REVISION
and (moveId<=251 or (spec.retailResourceSelectionDone or {})[moveId]==true)
end

local function beFloat(s,p)
local bits=be32(s,p);if not bits then return nil end
local sign=1
if bits>=2147483648 then sign=-1;bits=bits-2147483648 end
local exp=math.floor(bits/8388608)
local mant=bits-exp*8388608
if exp==255 then return mant==0 and sign*1e30 or 0 end
if exp==0 then return sign*(mant/8388608)*(2^-126) end
return sign*(1+mant/8388608)*(2^(exp-127))
end









local RUNTIME_MESH_VERSION=2
local function runtimeRoot(path) return tostring(path or "cache/movefx/model.lua"):gsub("%.lua$","").."_runtime_v2_r"..tostring(M.runtimeRevision or M.revision) end
local function runtimeBinPath(path,i) return runtimeRoot(path)..("/base_%02d.f32"):format(tonumber(i) or 0) end
local function runtimeMetaPath(path) return runtimeRoot(path).."/base.lua" end
local function cacheSize(path)
local mod=M.mod;if not (mod and mod.cache and type(mod.cache.info)=="function") then return nil end
local ok,info=pcall(mod.cache.info,mod.cache,path);return ok and type(info)=="table" and tonumber(info.size) or nil
end
local PACK_ROWS_BATCH=64
local function packPackedRows(group,stride)
local lovePack=love and love.data and type(love.data.pack)=="function" and love.data.pack or nil
local luaPack=type(string.pack)=="function" and string.pack or nil
if not lovePack and not luaPack then return nil,"float32 pack unavailable" end
local packed=type(group)=="table" and group.verticesPacked or nil
if type(packed)~="string" then return nil,"packed vertices unavailable" end
local unpackArgs=table.unpack or unpack
local rowFmt=string.rep("f",stride);local fullFmt=string.rep(rowFmt,PACK_ROWS_BATCH)
local chunks={};local n=0;local values={};local rows=0;local valueCount=0;local totalRows=0
local function flush()
if rows==0 then return true end
local fmt=rows==PACK_ROWS_BATCH and fullFmt or string.rep(rowFmt,rows)
local ok,bytes
if lovePack then ok,bytes=pcall(lovePack,"string",fmt,unpackArgs(values,1,valueCount)) end
if (not ok or type(bytes)~="string") and luaPack then


ok,bytes=pcall(luaPack,"<"..fmt,unpackArgs(values,1,valueCount))
end
if not ok or type(bytes)~="string" then return false,tostring(bytes or "float32 pack failed") end
n=n+1;chunks[n]=bytes;rows=0;valueCount=0
return true
end
for line in packed:gmatch("[^\r\n]+") do
local count=0
for token in line:gmatch("[^,]+") do count=count+1;valueCount=valueCount+1;values[valueCount]=tonumber(token) or 0 end
if count~=stride then return nil,("packed stride mismatch %d/%d"):format(count,stride) end
rows=rows+1;totalRows=totalRows+1
if rows==PACK_ROWS_BATCH then local ok,why=flush();if not ok then return nil,why end end
end
local ok,why=flush();if not ok then return nil,why end
if n==0 then return nil,"no packed vertex rows" end
return table.concat(chunks),totalRows
end
local function prebuildRuntimeMesh(path,cache,stride,knownSourceSize)
local size=tonumber(knownSourceSize) or cacheSize(path)
if not ((love and love.data and type(love.data.pack)=="function") or type(string.pack)=="function") then return false end



local compact={runtimeMeshVersion=RUNTIME_MESH_VERSION,sourcePath=path,extractorRevision=M.runtimeRevision or M.revision}
if size and size>0 then compact.sourceSize=size end
for k,v in pairs(cache or {}) do if k~="groups" then compact[k]=v end end
compact.groups={}
for i,g in ipairs(cache.groups or {}) do
local bytes,count=packPackedRows(g,stride);if type(bytes)~="string" or not count then return false end
local bin=runtimeBinPath(path,i);local ok=write(bin,bytes);if not ok then return false end
local row={};for k,v in pairs(g) do if k~="vertices" and k~="verticesPacked" then row[k]=v end end
row.runtimeBin=bin;row.vertexCount=count;compact.groups[i]=row
end
return write(runtimeMetaPath(path),"return "..serialize(compact).."\n")
end

local function hex(bytes)
local out={}
for i=1,#bytes do out[#out+1]=string.format("%02X",bytes:byte(i)) end
return table.concat(out)
end
local function saneRange(off,size,n)
return type(off)=="number" and type(size)=="number" and off>=0 and size>=0 and off+size<=n
end
cacheReadLua=function(path)
local mod=M.mod;if not (mod and mod.cache and type(mod.cache.read)=="function") then return nil end
local ok,src=pcall(mod.cache.read,mod.cache,path); if not ok or type(src)~="string" then return nil end
local f=load(src,"@generated/"..path);if not f then return nil end
local ok2,v=pcall(f);return ok2 and v or nil
end
local function includeIndexedStem(candidates,id)
if M.sourceMoveRows then return candidates end
if M.indexMemory==nil then M.indexMemory=cacheReadLua("cache/movefx/index.lua") or false end
local row=type(M.indexMemory)=="table" and type(M.indexMemory.moves)=="table" and M.indexMemory.moves[tonumber(id)] or nil
local stem=type(row)=="table" and tostring(row.stem or ""):lower():gsub("[^%w]","") or ""
if stem=="" then return candidates end
local out={stem};for _,v in ipairs(candidates or {}) do if v~=stem then out[#out+1]=v end end;return out
end
write=function(path,data,preserveExisting)
local mod=M.mod; if not (mod and mod.cache and type(mod.cache.write)=="function") then return false,"cache unavailable" end
local preserve=(preserveExisting==true or M.preserveExistingWrites==true)
and (tostring(path):find("cache/movefx/",1,true)==1 or tostring(path):find("cache/capture/",1,true)==1)
if preserve and Persist then
local manifestTarget=nil
if type(M.buildGenerated)=="table" then
local seen=M.buildGeneratedSeen or {};M.buildGeneratedSeen=seen
if not seen[path] then manifestTarget=M.buildGenerated end
end
local ok,a,b=pcall(Persist.write,mod,"movefx",path,data,manifestTarget,true)
if not ok then return false,("cache preserve/write failed [%s]: %s"):format(tostring(path),tostring(a)) end
if a==false or a==nil then return false,("cache preserve/write failed [%s]: %s"):format(tostring(path),tostring(b or "cache write failed")) end
if manifestTarget then M.buildGeneratedSeen[path]=true end
return true
end
local ok,a,b=pcall(mod.cache.write,mod.cache,path,data)
if not ok then return false,("cache write failed [%s]: %s"):format(tostring(path),tostring(a)) end
if a==false or a==nil then return false,("cache write failed [%s]: %s"):format(tostring(path),tostring(b or "cache write failed")) end
if type(M.buildGenerated)=="table" then
local seen=M.buildGeneratedSeen or {};M.buildGeneratedSeen=seen
if not seen[path] then seen[path]=true;M.buildGenerated[#M.buildGenerated+1]=path end
end
return true
end
serialize=function(v)
local t=type(v)
if t=="nil" then return "nil" elseif t=="number" then return ("%.9g"):format(v)
elseif t=="boolean" then return v and "true" or "false" elseif t=="string" then return string.format("%q",v)
elseif t=="table" then
local out={"{"};local n=#v
for i=1,n do out[#out+1]=serialize(v[i]);out[#out+1]="," end
for k,x in pairs(v) do
if not (type(k)=="number" and k>=1 and k<=n and k%1==0) then
out[#out+1]="["..serialize(k).."]="..serialize(x).."," end
end
out[#out+1]="}";return table.concat(out)
end
return "nil"
end






local function refreshEmbeddedCameraCache(meta,stem)
local target=tonumber(HSD and HSD.cameraRevision) or 0
if target<=0 or type(meta)~="table" or type(meta.wazaPhases)~="table"
or not (HSD and type(HSD.extractCameraAnimation)=="function") then return meta,false end
local changed=false
local cache=M.mod and M.mod.cache
for _,phase in ipairs(meta.wazaPhases) do
local size=math.max(0,math.floor(tonumber(phase and (phase.hsdSize or (phase.root and phase.root.embeddedSize))) or 0))
local camera=phase and phase.sourceCamera
if size>0 and not (type(camera)=="table" and tonumber(camera.revision)==target) then
local rawPath=phase.rawPath
local raw=nil
if type(rawPath)=="string" and cache and type(cache.read)=="function" then
local ok,v=pcall(cache.read,cache,rawPath);if ok and type(v)=="string" then raw=v end
end
if type(raw)=="string" and 0xA0+size<=#raw then
local ok,newCamera,why=pcall(HSD.extractCameraAnimation,raw:sub(0xA0+1,0xA0+size),
{phase=phase.name,wazaOffsetWorldUp=true})
if ok and type(newCamera)=="table" then
phase.sourceCamera=newCamera;phase.sourceCameraError=nil
else
phase.sourceCamera=nil
phase.sourceCameraError="embedded camera cache refresh failed: "..tostring(ok and why or newCamera)
end
else



if type(camera)=="table" then
camera.complete=false;camera.cacheStale=true
camera.cacheRefreshError="embedded camera cache revision requires retained raw WZX"
end
phase.sourceCameraError="embedded camera cache revision requires retained raw WZX"
end
changed=true
end
end
if changed and stem then write(M.cachePath(stem),"return "..serialize(meta).."\n",true) end
return meta,changed
end







local GS_TO_GX={
[0x00]=8,[0x01]=9,[0x30]=10,[0x40]=0,[0x41]=2,[0x42]=1,
[0x43]=3,[0x45]=6,[0x90]=5,[0xA0]=1,[0xB0]=14,
}
local function be16at(s,off)
local a,b=s:byte(off+1,off+2);if not b then return nil end;return a*256+b
end
local function be32at(s,off)
local a,b,c,d=s:byte(off+1,off+4);if not d then return nil end;return ((a*256+b)*256+c)*256+d
end
local function decodeGSTexture(bytes)
if type(bytes)~="string" or #bytes<0x80 then return nil,"serialized GStexture shorter than 0x80" end
local w,h=be16at(bytes,0),be16at(bytes,2)
local levels=bytes:byte(0x05+1) or 0
local format=be32at(bytes,0x08);local tlutFormat=be32at(bytes,0x0C) or 0
local wrapS=be32at(bytes,0x10) or 0;local wrapT=be32at(bytes,0x14) or 0
local dataOff=be32at(bytes,0x28);local palOff=be32at(bytes,0x48)
if not w or not h or w<1 or h<1 or w>2048 or h>2048 then return nil,"serialized GStexture dimensions invalid" end
local gx=GS_TO_GX[format]
if gx==nil then return nil,("unsupported serialized GStexture format 0x%X"):format(tonumber(format) or -1) end
if not dataOff or dataOff<0x20 or dataOff>=#bytes then return nil,"serialized GStexture mip pointer invalid" end
local need=GX and GX.dataSize and GX.dataSize(w,h,gx) or nil
if not need or dataOff+need>#bytes then return nil,"serialized GStexture image range truncated" end
local image=bytes:sub(dataOff+1,dataOff+need)
local palette,palFmt
if gx==8 or gx==9 or gx==10 then
if not palOff or palOff<=0 or palOff>=#bytes then return nil,"paletted GStexture has no TLUT" end
local entries=(format==0x00 and 16) or (format==0x01 and 256) or 1024
local plen=entries*2
if palOff+plen>#bytes then return nil,"serialized GStexture TLUT truncated" end
palette=bytes:sub(palOff+1,palOff+plen)
palFmt=(tlutFormat==1 and 0) or (tlutFormat==2 and 1) or 2
end
local ok,rgba=pcall(GX.decode,image,w,h,gx,palette,palFmt)
if not ok or type(rgba)~="string" then return nil,tostring(rgba or "GX texture decode failed") end
return {rgba=rgba,w=w,h=h,gxFormat=gx,gsFormat=format,tlutFormat=tlutFormat,
wrapS=wrapS,wrapT=wrapT,mipLevels=levels,sourceDataOffset=dataOff,sourcePaletteOffset=palOff}
end

local function cacheGSTextureArtifact(bytes,stem,phase,ident,artifactIndex)
local tex,err=decodeGSTexture(bytes);if not tex then return nil,err end
local path=("cache/movefx/%s/effects/%s_%03d_%02d_texture.rgba"):format(stem,phase,tonumber(ident) or 0,tonumber(artifactIndex) or 0)
local ok,why=write(path,tex.rgba);if not ok then return nil,why end
tex.path=path;tex.rgba=nil
return tex
end

local function textureTraits(rgba,w,h)
local minx,miny,maxx,maxy=w,h,-1,-1
local live=0;local alphaSum=0
for i=0,w*h-1 do
local a=rgba:byte(i*4+4) or 0
alphaSum=alphaSum+a
if a>10 then
live=live+1
local x=i%w;local y=math.floor(i/w)
if x<minx then minx=x end;if x>maxx then maxx=x end
if y<miny then miny=y end;if y>maxy then maxy=y end
end
end
local cw,ch=w,h
if live>0 then cw=maxx-minx+1;ch=maxy-miny+1 end
local coverage=live/math.max(1,w*h)
local contentScale=math.max(w,h)/math.max(1,math.max(cw,ch))
return {coverage=coverage,meanAlpha=alphaSum/math.max(1,w*h*255),
contentW=cw,contentH=ch,contentScale=math.max(1,math.min(4,contentScale))}
end
local function intensityAlpha(rgba)
local out={};local n=#rgba
for p=1,n,4 do
local r=rgba:byte(p) or 0
local g=rgba:byte(p+1) or r
local b=rgba:byte(p+2) or r
local i=math.max(r,g,b)
out[#out+1]=string.char(r,g,b,i)
end
return table.concat(out)
end






local function scanSequenceGPT1(blob)
local map={}
if not (Waza and type(Waza.parse)=="function") then return map end
local ok,timeline=pcall(Waza.parse,blob,{phase="gpt1-index"})
if not ok or type(timeline)~="table" then return map end
for _,entry in ipairs(timeline.entries or {}) do
if type(entry)=="table" and entry.kind=="particle" then
if entry.gptOffset~=nil then
map[tonumber(entry.gptOffset) or entry.gptOffset]=entry
end




local first=tonumber(entry.dataOffset);local size=tonumber(entry.dataSize) or 0
if first and size>0 and first>=0 and first+size<=#blob then
local pos=first+1;local stop=first+size
while pos<=stop do
local hit=blob:find("GPT1",pos,true)
if not hit or (hit-1)>=stop then break end
map[hit-1]=entry
pos=hit+4
end
end
end
end
return map
end

local function parseGPT1(blob,gptOff,bank,out,sequence)
local n=#blob






local rootSelector=type(sequence)=="table" and tonumber(sequence.selector) or nil
local descRel,objRel,bankRel=be32(blob,gptOff+4),be32(blob,gptOff+8),be32(blob,gptOff+0x10)
if not (descRel and objRel and bankRel) then return end
local desc=gptOff+descRel;local objects=gptOff+objRel;local bankData=gptOff+bankRel
if not (saneRange(desc,12,n) and saneRange(objects,4,n) and saneRange(bankData,4,n)) then return end

local version=be16(blob,desc) or -1
local firstId,count,total=0,0,0
local ptrBase
if version==0 then
count=be32(blob,desc+4) or 0;total=count;ptrBase=desc+8
elseif version>=0x40 and version<0x44 then
firstId=be32(blob,desc+4) or 0
count=be32(blob,desc+8) or 0
total=firstId+count;ptrBase=desc+0x0C
else
out.gptErrors=out.gptErrors or {};out.gptErrors[#out.gptErrors+1]={bank=bank,offset=gptOff,error=("unsupported GPT1 script table version 0x%X"):format(math.max(0,version))}
return
end
if count<1 or count>4096 or total>8192 then return end

local scripts={}
local offsets={}
for j=0,count-1 do
local scriptId=firstId+j
local rel=be32(blob,ptrBase+j*4)
local ga=rel and rel>0 and (desc+rel) or nil
if ga and saneRange(ga,0x3C,n) then
scripts[#scripts+1]={scriptId=scriptId,offset=ga,rel=rel}
offsets[#offsets+1]=ga
end
end
table.sort(offsets)
local function nextOffset(after)
for _,v in ipairs(offsets) do if v>after then return v end end
return objects
end

out.lookupTables=out.lookupTables or {}
out.lookupTables[bank]=out.lookupTables[bank] or {}



local resourceEnd=n
if type(sequence)=="table" then
local ro,rs=tonumber(sequence.dataOffset),tonumber(sequence.dataSize)
if ro and rs and rs>0 and gptOff>=ro and gptOff<ro+rs then resourceEnd=math.min(n,ro+rs) end
end
local lookupCap=math.min(1024,math.max(0,math.floor((resourceEnd-bankData)/4)))
for i=0,lookupCap-1 do
local id=be32(blob,bankData+i*4)
if id~=nil and id>=0 and id<total then out.lookupTables[bank][i]=id end
end

for ordinal,script in ipairs(scripts) do
local ga=script.offset
local cmdStart=ga+0x3C
local cmdEnd=math.min(nextOffset(ga),objects,n)
if cmdEnd<=cmdStart then cmdEnd=math.min(objects,n) end
local commands=(cmdEnd>cmdStart and saneRange(cmdStart,cmdEnd-cmdStart,n)) and blob:sub(cmdStart+1,cmdEnd) or ""
local maxLife=be16(blob,ga+4) or 0
local repeatCount=be16(blob,ga+6) or 0
if maxLife>out.maxLifetime then out.maxLifetime=maxLife end
local params={}
for j=0,11 do params[j+1]=beFloat(blob,ga+0x0C+j*4) or 0 end
local scriptId=script.scriptId
out.programs[#out.programs+1]={
bank=bank,bankIndex=scriptId,scriptId=scriptId,ordinal=ordinal-1,
angleFlags=be16(blob,ga) or 0,


animIndex=be16(blob,ga+2) or 0,texGroup=be16(blob,ga+2) or 0,
maxLife=maxLife,repeatCount=repeatCount,particleLife=repeatCount,
flags=be32(blob,ga+8) or 0,
gravity=params[1],friction=params[2],velocityX=params[3],velocityY=params[4],velocityZ=params[5],
radius=params[6],angle=params[7],




random=params[8],emissionRate=params[8],particleSize=params[9],
shapeX=params[10],shapeY=params[11],shapeZ=params[12],
params=params,commandHex=hex(commands),selector=rootSelector,rootRef=rootSelector,gptOffset=gptOff,
root=(rootSelector~=nil and tonumber(scriptId)==tonumber(rootSelector)) or false,
sequence=sequence,gptVersion=version,scriptTableFirst=firstId,scriptTableCount=total,
sourceContract="GC6E01 FieldParticleFile/PSGeneratorState",
}
end
out.generators=out.generators+#scripts




local txg=objects
local groupCount=be32(blob,txg) or 0
if groupCount<1 or not saneRange(txg+4,groupCount*4,n) then return end
for ci=0,groupCount-1 do
local rel=be32(blob,txg+4+ci*4)
local ca=rel and (txg+rel) or nil
if ca and saneRange(ca,0x18,n) then
local nb=be32(blob,ca) or 0
local fmt=be32(blob,ca+4)
local w,h=be32(blob,ca+0x0C),be32(blob,ca+0x10)
if fmt and w and h and nb>0 and saneRange(ca+0x18,nb*4,n)
and w>=1 and h>=1 and w<=1024 and h<=1024 then
local okSize,size=pcall(GX.dataSize,w,h,fmt)
if okSize and type(size)=="number" and size>0 and size<=8*1024*1024 then
for ti=0,nb-1 do
local texRel=be32(blob,ca+0x18+ti*4)
local start=texRel and (txg+texRel) or nil
if start and saneRange(start,size,n) then
local src=blob:sub(start+1,start+size)
local okDec,rgba=pcall(GX.decode,src,w,h,fmt)
if okDec and type(rgba)=="string" and #rgba==w*h*4 then
local gray=(fmt==0 or fmt==1)
out.raw[#out.raw+1]={bytes=rgba,w=w,h=h,fmt=fmt,gray=gray,bank=bank,container=ci,texture=ti}
out.textures[#out.textures+1]={w=w,h=h,fmt=fmt,gray=gray,bank=bank,container=ci,texture=ti}
end
end
end
end
end
end
end
end

local function scanGPT1(blob,out)
local sequenceMap=scanSequenceGPT1(blob)
out.gptBanks=out.gptBanks or {}
local pos=1;local bank=0
while true do
local s=blob:find("GPT1",pos,true);if not s then break end
bank=bank+1
local gptOff=s-1
out.gptBanks[gptOff]=bank



parseGPT1(blob,gptOff,bank,out,sequenceMap[gptOff])
pos=s+4
end
end





local function scanSoundEntries(blob,out)




return
end




local WAZA_MODEL_PAGE_SLOTS=12

local function wazaModelTopologyMatches(a,b)
if not (a and b and #(a.groups or {})==#(b.groups or {})) then return false end
for gi,g in ipairs(a.groups or {}) do
local h=b.groups[gi]
if not h or #(g.vertices or {})~=#(h.vertices or {}) then return false end
end
return true
end

local function wazaModelMotion(a,b)
if not wazaModelTopologyMatches(a,b) then return math.huge end
local maxd=0
for gi,g in ipairs(a.groups or {}) do
local h=b.groups[gi]
for vi,v in ipairs(g.vertices or {}) do
local q=h.vertices[vi]
local dx=(tonumber(v[1]) or 0)-(tonumber(q[1]) or 0)
local dy=(tonumber(v[2]) or 0)-(tonumber(q[2]) or 0)
local dz=(tonumber(v[3]) or 0)-(tonumber(q[3]) or 0)
local d=math.sqrt(dx*dx+dy*dy+dz*dz)
if d>maxd then maxd=d end
end
end
return maxd
end

local function wazaModelGroupShell(g,texSpec)
return {vertices={},texture=texSpec,diffuse=g.diffuse,ambient=g.ambient,specular=g.specular,
alpha=g.alpha,shininess=g.shininess,xlu=g.xlu==true,noz=g.noz==true,renderFlags=g.renderFlags,
textureSlot=g.textureSlot,textureTexgen=texSpec and texSpec.texgen or nil,shadow=g.shadow==true,effect=g.effect==true,
useConstant=g.useConstant==true,useVertexColor=g.useVertexColor==true,
useDiffuseLighting=g.useDiffuseLighting~=false}
end






local function packedWazaVertices(vertices,stride)
local rows={}
stride=tonumber(stride) or 8
for _,v in ipairs(vertices or {}) do
local parts={}
for i=1,stride do parts[i]=("%.9g"):format(tonumber(v[i]) or 0) end
rows[#rows+1]=table.concat(parts,",")
end
return table.concat(rows,"\n")
end
local function packWazaGroups(groups,stride)
local out={}
for gi,g in ipairs(groups or {}) do
local copy={}
for k,v in pairs(g) do if k~="vertices" then copy[k]=v end end
copy.vertexStride=stride
copy.verticesPacked=packedWazaVertices(g.vertices,stride)
out[gi]=copy
end
return out
end

local function wazaModelPage(base,poses,startFrame,endFrame,textureSpecs)
local slotCount=math.max(0,math.min(WAZA_MODEL_PAGE_SLOTS,endFrame-startFrame))
local groups={}
for gi,g in ipairs(base.groups or {}) do
local out=wazaModelGroupShell(g,textureSpecs[gi])
for vi,v in ipairs(g.vertices or {}) do
local row={v[1] or 0,v[2] or 0,v[3] or 0,v[4] or 0,v[5] or 0,v[6] or 0,v[7] or 1,v[8] or 0}
for slot=1,WAZA_MODEL_PAGE_SLOTS do
local frame=startFrame+math.min(slot,slotCount)
local pose=poses[frame]
local q=pose and pose.groups and pose.groups[gi] and pose.groups[gi].vertices and pose.groups[gi].vertices[vi] or v
row[#row+1]=q[1] or v[1] or 0;row[#row+1]=q[2] or v[2] or 0;row[#row+1]=q[3] or v[3] or 0
end
out.vertices[vi]=row
end
groups[gi]=out
end
return {revision=3,source="GC6E01 WazaSequence type-2 HSD animated page",startFrame=startFrame,endFrame=endFrame,
morphFrames=slotCount,groups=packWazaGroups(groups,44),bounds=base.bounds,vertexCount=base.vertexCount}
end






local function compileWazaModel(blob,entry,stem,phase,opts)
if not (HSD and type(HSD.extractModel)=="function" and type(blob)=="string"
and type(entry)=="table" and tonumber(entry.dataOffset) and tonumber(entry.dataSize)) then
return nil,"Waza model extractor unavailable"
end
local off,size=tonumber(entry.dataOffset),tonumber(entry.dataSize)
if off<0 or size<=0 or off+size>#blob then return nil,"Waza model source range invalid" end
local source=blob:sub(off+1,off+size)



local keepParts=opts and opts.partIndices and #opts.partIndices>0









local decodeOpts={checkpoint=checkpoint,textures=true,sourceTextureAnimation=true,allowTransformOnly=true,preserveJointMatrices=keepParts,semanticRootsOnly=true,minVertices=3,maxRoots=48,maxVertices=90000,maxDisplayOps=300000,maxJobjs=4096,maxDobjs=12000,maxPobjs=20000}
local model,err=HSD.extractModel(source,decodeOpts)
if not model then return nil,err or "Waza HSD model decode failed" end
local bindModel=model
local animInfo=type(HSD.nativeAnimationInfo)=="function" and select(1,HSD.nativeAnimationInfo(bindModel,0)) or nil
local materialInfo=type(HSD.nativeMaterialAnimationInfo)=="function" and select(1,HSD.nativeMaterialAnimationInfo(bindModel,0)) or nil
local frameZeroApplied=false
if animInfo and (tonumber(animInfo.endFrame) or 0)>0 and not (opts and opts.staticOnly) then


local zero,why=HSD.extractNativePose(bindModel,0,0,decodeOpts)
if not zero or not wazaModelTopologyMatches(bindModel,zero) then
return nil,"Waza authored frame zero unavailable: "..tostring(why or "topology mismatch")
end
model=zero;frameZeroApplied=true
end

local ident=tonumber(entry.identifier) or tonumber(entry.index) or 0
local textureSpecs={};local textureCount=0
for gi,g in ipairs(model.groups or {}) do
local texSpec=nil;local t=g.texture
if t and type(t.rgba)=="string" and tonumber(t.w) and tonumber(t.h) then
local path=("cache/movefx/%s/models/%s_%03d_tex_%03d.rgba"):format(stem,phase,ident,gi)
local okWrite,why=write(path,t.rgba)
if not okWrite then return nil,why end
texSpec={path=path,w=t.w,h=t.h,wrapS=t.wrapS,wrapT=t.wrapT,format=t.format,dataOffset=t.dataOffset,
texgen=t.texgen,flags=t.flags,slot=t.slot}
textureCount=textureCount+1
end
textureSpecs[gi]=texSpec
end

local endFrame=math.max(tonumber(animInfo and animInfo.endFrame) or 0,tonumber(materialInfo and materialInfo.endFrame) or 0)
endFrame=math.max(0,math.floor(endFrame))
if opts and opts.staticOnly then endFrame=0 end
if endFrame>600 then return nil,("Waza model source animation exceeds safety bound: %d frames"):format(endFrame) end
local textureAnimation,textureAnimationBlocker=nil,nil
if endFrame>0 and type(HSD.nativeTexturePose)=="function" then
local probe,why=HSD.nativeTexturePose(bindModel,0,0)
if probe and probe.animated==true then
local groups={};local complete=true
for fr=0,endFrame do
local pose,pwhy=HSD.nativeTexturePose(bindModel,0,fr)
if not pose then complete=false;textureAnimationBlocker=("frame %d: %s"):format(fr,tostring(pwhy));break end
for gi,state in ipairs(pose.groups or {}) do
if state and type(state.affine)=="table" then
groups[gi]=groups[gi] or {}
groups[gi][fr+1]=state.affine
end
end
end
if complete then
textureAnimation={revision=1,source="GC6E01 HSD_TexAnim + MakeTextureMtx",clip=0,endFrame=endFrame,frameCount=endFrame+1,groups=groups}
end
elseif not probe and why then


textureAnimationBlocker=tostring(why)
end
end




local materialAnimation,materialAnimationBlocker=nil,nil
if type(HSD.nativeMaterialPose)=="function" then
local probe,why=HSD.nativeMaterialPose(bindModel,0,0,{separateTextureAnimation=true})
if probe then
local groups={};local complete=true
for fr=0,endFrame do
local pose,pwhy=fr==0 and probe or HSD.nativeMaterialPose(bindModel,0,fr,{separateTextureAnimation=true})
if not pose then complete=false;materialAnimationBlocker=("frame %d: %s"):format(fr,tostring(pwhy));break end
for gi,state in ipairs(pose.groups or {}) do
groups[gi]=groups[gi] or {}
groups[gi][fr+1]={diffuse=state.diffuse,ambient=state.ambient,specular=state.specular,alpha=state.alpha}
end
end
if complete then materialAnimation={revision=1,source="GC6E01 HSD_MatAnimJoint",clip=0,endFrame=endFrame,groups=groups} end
elseif why then materialAnimationBlocker=tostring(why) end
end
local animated=false;local poses={[0]=model};local maxMotion=0;local partsMotion=0
if endFrame>0 and type(HSD.extractNativePose)=="function" then


local probeFrames={math.max(1,math.floor(endFrame*.25)),math.max(1,math.floor(endFrame*.5)),
math.max(1,math.floor(endFrame*.75)),endFrame}
for _,fr in ipairs(probeFrames) do
if not poses[fr] then
local pose=select(1,HSD.extractNativePose(bindModel,0,fr,decodeOpts))
if pose and wazaModelTopologyMatches(model,pose) then
poses[fr]=pose;maxMotion=math.max(maxMotion,wazaModelMotion(model,pose))
for _,part in ipairs((opts and opts.partIndices) or {}) do
local a=model.jointMatrices and model.jointMatrices[part+1]
local b=pose.jointMatrices and pose.jointMatrices[part+1]
if a and b then for k=1,12 do partsMotion=math.max(partsMotion,math.abs(a[k]-b[k])) end end
end
end
end
end
animated=maxMotion>1e-5
end

local pages={}
if animated or partsMotion>1e-5 then


for fr=1,endFrame do
if not poses[fr] then
local pose,why=HSD.extractNativePose(bindModel,0,fr,decodeOpts)
if not pose then return nil,("Waza model animation frame %d decode failed: %s"):format(fr,tostring(why)) end
if not wazaModelTopologyMatches(model,pose) then return nil,("Waza model animation topology changed at frame %d"):format(fr) end
poses[fr]=pose
end
end
end
if animated then
local start=0
while start<endFrame do
local stop=math.min(endFrame,start+WAZA_MODEL_PAGE_SLOTS)
local page=wazaModelPage(poses[start] or model,poses,start,stop,textureSpecs)
local path=("cache/movefx/%s/models/%s_%03d_anim_%03d.lua"):format(stem,phase,ident,#pages+1)
local body="return "..serialize(page).."\n"
local okWrite,why=write(path,body)
if not okWrite then return nil,why end


pcall(prebuildRuntimeMesh,path,page,44,#body)
pages[#pages+1]={cache=path,startFrame=start,endFrame=stop,morphFrames=stop-start}
start=stop
end
end




local normalizationBounds={min={math.huge,math.huge,math.huge},max={-math.huge,-math.huge,-math.huge}}
for _,pose in pairs(poses) do
local b=pose.bounds
if b and b.min and b.max then
for k=1,3 do
normalizationBounds.min[k]=math.min(normalizationBounds.min[k],b.min[k])
normalizationBounds.max[k]=math.max(normalizationBounds.max[k],b.max[k])
end
end
end
if normalizationBounds.min[1]==math.huge then normalizationBounds=model.bounds end




local parts=nil
if decodeOpts.preserveJointMatrices then
local tracks={};local frames=partsMotion>1e-5 and endFrame or 0
for _,index in ipairs(opts.partIndices) do
local track={}
for fr=0,frames do
local pose=poses[fr] or model
local mat=pose.jointMatrices and pose.jointMatrices[index+1]
if not mat then return nil,"Waza linked part missing: "..tostring(index) end
track[fr+1]=mat
end
tracks[index]=track
end
local path=("cache/movefx/%s/models/%s_%03d_parts.lua"):format(stem,phase,ident)
local okParts,why=write(path,"return "..serialize({revision=1,endFrame=frames,tracks=tracks}).."\n")
if not okParts then return nil,why end
parts={path=path,endFrame=frames,count=#opts.partIndices}
end



local groups={}
for gi,g in ipairs(model.groups or {}) do
groups[#groups+1]=wazaModelGroupShell(g,textureSpecs[gi]);groups[#groups].vertices=g.vertices
end
if #groups==0 and not model.transformOnly then return nil,"Waza effect model has no drawable groups" end
local cachePath=("cache/movefx/%s/models/%s_%03d.lua"):format(stem,phase,ident)
local cache={revision=4,source="GC6E01 WazaSequence type-2 HSD",phase=phase,identifier=entry.identifier,
transformOnly=model.transformOnly==true,parts=parts,frameZeroApplied=frameZeroApplied,normalizationBounds=normalizationBounds,bounds=model.bounds,vertexCount=model.vertexCount,groups=packWazaGroups(groups,8),
textureAnimation=textureAnimation,textureAnimationBlocker=textureAnimationBlocker,
materialAnimation=materialAnimation,materialAnimationBlocker=materialAnimationBlocker,
animation={clip=0,endFrame=endFrame,frameCount=endFrame+1,animated=animated,textureAnimated=textureAnimation~=nil,
materialAnimated=materialAnimation~=nil,partsAnimated=partsMotion>1e-5,maxMotion=maxMotion,pages=pages}}
local cacheBody="return "..serialize(cache).."\n"
local okWrite,why=write(cachePath,cacheBody)
if not okWrite then return nil,why end
if not model.transformOnly then pcall(prebuildRuntimeMesh,cachePath,cache,8,#cacheBody) end
return {cache=cachePath,groups=#groups,vertices=tonumber(model.vertexCount) or 0,textures=textureCount,bounds=model.bounds,
transformOnly=model.transformOnly==true,parts=parts,frameZeroApplied=frameZeroApplied,normalizationBounds=normalizationBounds,
textureAnimation=textureAnimation,textureAnimationBlocker=textureAnimationBlocker,
materialAnimation=materialAnimation,materialAnimationBlocker=materialAnimationBlocker,
animation={clip=0,endFrame=endFrame,frameCount=endFrame+1,animated=animated,textureAnimated=textureAnimation~=nil,
materialAnimated=materialAnimation~=nil,partsAnimated=partsMotion>1e-5,maxMotion=maxMotion,pages=pages}}
end




local function compileDecodedCaptureModel(model,stem,phase,tag)
if type(model)~="table" then return nil,"decoded capture model unavailable" end
local safe=tostring(tag or "root"):gsub("[^%w_%-]","_")
local textureSpecs={};local textureCount=0
for gi,g in ipairs(model.groups or {}) do
local texSpec=nil;local t=g.texture
if t and type(t.rgba)=="string" and tonumber(t.w) and tonumber(t.h) then
local path=("cache/movefx/%s/models/%s_member_%s_tex_%03d.rgba"):format(stem,phase,safe,gi)
local okWrite,why=write(path,t.rgba);if not okWrite then return nil,why end
texSpec={path=path,w=t.w,h=t.h,wrapS=t.wrapS,wrapT=t.wrapT,format=t.format,dataOffset=t.dataOffset}
textureCount=textureCount+1
end
textureSpecs[gi]=texSpec
end
local groups={}
for gi,g in ipairs(model.groups or {}) do
groups[#groups+1]=wazaModelGroupShell(g,textureSpecs[gi]);groups[#groups].vertices=g.vertices
end
if #groups==0 then return nil,"capture member HSD root has no drawable groups" end
local cachePath=("cache/movefx/%s/models/%s_member_%s.lua"):format(stem,phase,safe)
local cache={revision=4,source="GC6E01 snatch member HSD static root",phase=phase,identifier=safe,
bounds=model.bounds,vertexCount=model.vertexCount,groups=packWazaGroups(groups,8),
animation={clip=0,endFrame=0,frameCount=1,animated=false,maxMotion=0,pages={}}}
local cacheBody="return "..serialize(cache).."\n"
local okWrite,why=write(cachePath,cacheBody);if not okWrite then return nil,why end
pcall(prebuildRuntimeMesh,cachePath,cache,8,#cacheBody)
return {cache=cachePath,groups=#groups,vertices=tonumber(model.vertexCount) or 0,textures=textureCount,bounds=model.bounds,
animation={clip=0,endFrame=0,frameCount=1,animated=false,maxMotion=0,pages={}},staticSource=true,memberRoot=true}
end

local function sourcePhaseArchivePath(stem,phase,disc)
local ordinary="wzx_"..stem.."_"..phase..".fsys"
local number,suffix=tostring(phase or ""):match("^(%d+)_(.+)$")
if number and not (disc and disc:file(ordinary)) then return "wzx_"..stem..number.."_"..suffix..".fsys" end
return ordinary
end

local function extractWZX(disc,stem,phase)
local file=disc and disc:file(sourcePhaseArchivePath(stem,phase,disc))
if not file then return nil,"source FSYS missing" end
local resourceGroup=fsysResourceGroup(disc,file)
local okArc,arc=pcall(FSYS.open,disc,file); if not okArc or not arc then return nil,tostring(arc) end
local list=arc:list() or {};local entry
for _,e in ipairs(list) do if tostring(e.name or ""):lower():find("%.wzx$",1,false) then entry=e;break end end
entry=entry or list[1];if not entry then return nil,"empty FSYS" end
local blob,err=arc:extract(entry,{maxOutput=64*1024*1024})
if not blob then return nil,err end
local out={textures={},raw={},sounds={},programs={},lookupTables={},maxLifetime=0,generators=0,phase=phase,member=entry.name,blob=blob,
resourceGroup=resourceGroup}
if Waza and type(Waza.parse)=="function" then
local okTimeline,timeline,why=pcall(Waza.parse,blob,{phase=phase,member=entry.name})
if okTimeline and type(timeline)=="table" then out.waza=timeline
else out.wazaError=tostring(okTimeline and why or timeline) end
end
scanGPT1(blob,out)
scanSoundEntries(blob,out)
return out
end





extractSourceMoveRows=function(disc)
local commonFile=disc and disc:file("common.fsys");if not commonFile then return nil,"common.fsys unavailable" end
local okArc,arc=pcall(FSYS.open,disc,commonFile);if not okArc or not arc then return nil,tostring(arc) end
local member
for _,e in ipairs(arc:list() or {}) do
local name=tostring(e.name or ""):lower()
if name=="common_rel.fdat" or name=="common_rel.dat" or name=="common_rel" then member=e;break end
end
if not member then
for _,e in ipairs(arc:list() or {}) do if tostring(e.name or ""):lower():find("common_rel",1,true) then member=e;break end end
end
if not member then return nil,"common_rel.fdat unavailable" end
local okBlob,blob=pcall(arc.extract,arc,member,{maxOutput=64*1024*1024})
if not okBlob or type(blob)~="string" then return nil,tostring(blob) end
local base,stride=0x11E010,0x38
if #blob<base+(354+1)*stride then return nil,"common_rel move table truncated" end




local tableBytes,tableWhy=dolReadVirtual(disc,0x8036E150,355*28)
if not tableBytes then return nil,tableWhy end
if be32(tableBytes,28)~=2001 or be32(tableBytes,28+4)~=908 or be32(tableBytes,354*28)~=2354 then
return nil,'GC6E01 Waza resource table signature mismatch'
end
local resources={}
for _,file in ipairs(disc.files or {}) do
local stem,phase=file.path:match('wzx_(.-)_([^_/]+)%.fsys$')
if stem then
local group=fsysResourceGroup(disc,file)
if group then resources[group]={stem=stem,phase=phase,path=file.path} end
end
end
local rows={}
for id=1,354 do
local at=base+id*stride;local primary=be16(blob,at+0x32);local secondary=be16(blob,at+0x1E)
if not primary or primary==0xFFFF or primary>4095 then return nil,("move %d primary Waza animation id invalid"):format(id) end
if secondary==0xFFFF or (secondary and secondary>4095) then secondary=nil end
local tableAt=primary*28
local sourceId=be32(tableBytes,tableAt)
if not sourceId or sourceId==0 then return nil,('Waza resource row missing: %d'):format(primary) end
local group=be32(tableBytes,tableAt+4)
local resource=resources[group]

if not resource then group=be32(tableBytes,tableAt+20);resource=resources[group] end
if not resource then return nil,('Waza resource archive missing for move %d / animation %d'):format(id,primary) end
rows[id]={moveId=id,primaryAnimationId=primary,secondaryAnimationId=secondary,sourceOffset=at,
primaryStem=resource.stem,primaryResourceGroup=group,primaryResourcePath=resource.path,
resourceTableAddress=0x8036E150+tableAt,resourceTableId=sourceId}
end
return rows,{archive="common.fsys",member=member.name,base=base,stride=stride,count=354}
end






local function migrateCachedSpec34(spec,stem,disc)
if type(spec)~="table" or tonumber(spec.revision)~=34 then return nil,"not a revision-34 effect cache" end
if tonumber(spec.wazaRevision)~=(Waza and Waza.revision or 12) then return nil,"Waza cache revision changed" end
stem=tostring(stem or spec.stem or "")
if stem=="" or tostring(spec.stem or "")~=stem then return nil,"effect stem mismatch" end
local phaseGroups={}
for _,phase in ipairs(spec.wazaPhases or {}) do
local name=tostring(phase.name or phase.phase or "")
local group=tonumber(phase.resourceGroup)
if not group then
local file=disc and type(disc.file)=="function" and disc:file("wzx_"..stem.."_"..name..".fsys") or nil
group=fsysResourceGroup(disc,file)
if not group then return nil,("retail FSYS id unavailable for %s/%s"):format(stem,name) end
phase.resourceGroup=group
end
phaseGroups[name]=group
end


for _,phase in ipairs(spec.phases or {}) do
local name=tostring(phase.name or phase.phase or "")
if phase.resourceGroup==nil and phaseGroups[name] then phase.resourceGroup=phaseGroups[name] end
end
spec.revision=M.revision
spec.retailModelPhasesByMove=type(spec.retailModelPhasesByMove)=="table" and spec.retailModelPhasesByMove or {}
spec.retailModelOverrideBlockersByMove=type(spec.retailModelOverrideBlockersByMove)=="table" and spec.retailModelOverrideBlockersByMove or {}
spec.retailModelOverrideSourceByMove=type(spec.retailModelOverrideSourceByMove)=="table" and spec.retailModelOverrideSourceByMove or {}
spec.retailModelSelectionDone=type(spec.retailModelSelectionDone)=="table" and spec.retailModelSelectionDone or {}
spec.source="GC6E01 WazaSequence timeline + typed native handlers + main.dol model-specific attack selection"
return spec
end

function M.migrateRevision34(mod,disc,progress,generated)


if M.revision>=36 then return nil,"numbered Waza banks require source extraction" end
if not (mod and mod.cache and disc) then return nil,"MoveFX metadata migration source unavailable" end
local oldMod,oldOpen,oldGenerated,oldSeen=M.mod,M.openDisc,M.buildGenerated,M.buildGeneratedSeen
local oldRows,oldOverrides,oldOverrideMeta,oldIndex=M.sourceMoveRows,M.retailModelOverrides,M.retailModelOverridesMeta,M.indexMemory
M.mod=mod
local index=cacheReadLua("cache/movefx/index.lua")
if type(index)~="table" or tonumber(index.revision)~=34
or tonumber(index.wazaRevision)~=(Waza and Waza.revision or 12)
or tonumber(index.total)~=251 or tonumber(index.ready)~=251 or tonumber(index.missing)~=0
or type(index.moves)~="table" then M.mod=oldMod;return nil,"revision-34 full MoveFX index unavailable" end

local sourceRows,sourceMeta=extractSourceMoveRows(disc)
if not sourceRows then M.mod=oldMod;return nil,"move selector migration: "..tostring(sourceMeta) end
local overrides,overrideMeta=extractRetailModelOverrides(disc)
if not overrides then M.mod=oldMod;return nil,"model selector migration: "..tostring(overrideMeta) end

M.openDisc=function()return disc end;M.buildGenerated=generated
local seen={};for _,path in ipairs(type(generated)=="table" and generated or {}) do seen[path]=true end;M.buildGeneratedSeen=seen
M.sourceMoveRows=sourceRows;M.retailModelOverrides=overrides;M.retailModelOverridesMeta=overrideMeta;M.indexMemory=index
saveRetailSelectorCache()
local specs,dirty={},{}
local ok,result=pcall(function()
for id=1,251 do
local row=index.moves[id]
assert(type(row)=="table" and row.missing~=true and row.stem,"revision-34 MoveFX index row missing: "..id)
local stem=tostring(row.stem)
local spec=specs[stem]
if not spec then
spec=assert(cacheReadLua(M.cachePath(stem)),"revision-34 effect cache missing: "..stem)
local migrated,why=migrateCachedSpec34(spec,stem,disc);assert(migrated,why)
spec=migrated;specs[stem]=spec;dirty[stem]=true
end
spec.sourceAnimation=spec.sourceAnimation or sourceRows[tonumber(spec.moveId)]
ensureSpecRetailModelMove(spec,id)
row.sourceAnimation=sourceRows[id]
row.retailModelOverrides=spec.retailModelOverrideSourceByMove and spec.retailModelOverrideSourceByMove[id] or nil
if progress and (id==1 or id%16==0 or id==251) then
pcall(progress,("MOVEFX METADATA MIGRATION %03d/251"):format(id),id,251)
end
end
local migratedStems=0
for stem in pairs(dirty) do
assert(write(M.cachePath(stem),"return "..serialize(specs[stem]).."\n",true));migratedStems=migratedStems+1
end
index.revision=M.revision;index.moveTable=sourceMeta;index.modelOverrideTable=overrideMeta
index.source="GC6E01 common_rel move animation selection + retail WZX + main.dol model-specific attack selection"
assert(write("cache/movefx/index.lua","return "..serialize(index).."\n",true))
return {ready=true,total=251,sourceReady=251,missing=0,fullVisualCount=tonumber(index.fullVisualReady) or 0,
fullVisualReady=tonumber(index.fullVisualReady)==251,soundIds=index.soundIds or {},migratedStems=migratedStems,index=index}
end)
M.mod=oldMod;M.openDisc=oldOpen;M.buildGenerated=oldGenerated;M.buildGeneratedSeen=oldSeen
M.sourceMoveRows=oldRows;M.retailModelOverrides=oldOverrides;M.retailModelOverridesMeta=oldOverrideMeta;M.indexMemory=oldIndex
M.memory={};M.negative={}
if not ok then return nil,tostring(result) end
return result
end


local function directEmbeddedType3(entry)




return false
end

local function entryParticleReady(spec,entry)
local programs=spec.generatorPrograms or {}
local wanted=tonumber(entry.selector~=nil and entry.selector or entry.rootRef)
for _,g in ipairs(programs) do
if tonumber(g.bank)==tonumber(entry.bank) and type(g.commandHex)=="string" and #g.commandHex>=2
and (wanted==nil or tonumber(g.scriptId)==wanted or tonumber(g.bankIndex)==wanted) then return true end
end
return false
end
local function cachedEntryReady(spec,entry)
if type(entry)~="table" then return false,"missing entry" end
if entry.parseWarning then return false,"entry parse warning: "..tostring(entry.parseWarning) end
if entry.kind=="particle" then
return entryParticleReady(spec,entry),"particle bank/generator unavailable"
end
if entry.kind=="model" then return type(entry.modelAsset)=="table" and entry.modelAsset.cache~=nil,"type-2 model unavailable" end
if entry.kind=="sound" then return true end
if entry.kind=="type1" then return tonumber(entry.subtype)~=nil and tonumber(entry.subtype)>=0 and tonumber(entry.subtype)<=3,"type-1 controller unsupported" end
if entry.kind=="type6" then return entry.controllerSupported==true,"type-6 owner controller unsupported" end
if entry.kind=="type4" then
if entry.effectSupported~=true then return false,"type-4 family unsupported" end
if entry.effectRequiredArtifact=="texture" and not (type(entry.effectTextureAsset)=="table" and entry.effectTextureAsset.path) then
return false,"type-4 required source texture unavailable"
end
if entry.effectRequiresModel and not (type(entry.effectModelAsset)=="table" and entry.effectModelAsset.cache) then return false,"type-4 embedded model unavailable" end
for _,artifact in ipairs(entry.effectAssets or entry.effectArtifacts or {}) do
if artifact.error or artifact.textureError or artifact.modelError then
return false,"type-4 source artifact incomplete: "..tostring(artifact.error or artifact.textureError or artifact.modelError)
end
end
return entry.effectRuntimeReady~=false,"type-4 effect runtime unavailable"
end
return false,"unknown Waza entry kind"
end
local function cachedRoleReady(spec,role)
if type(spec)~="table" then return false end
local seen=false
for _,phase in ipairs(spec.wazaPhases or {}) do
local pn=tostring(phase.name or "all"):lower();local pRole=(pn=="damage" or pn=="status") and "damage" or "attack"
if pRole==role then
if phase.complete~=true or phase.parseError then return false end
for _,entry in ipairs(phase.entries or {}) do
seen=true;local ok=cachedEntryReady(spec,entry);if not ok then return false end
end
end
end
return seen
end

local ATTACK_PHASES={"attack","special","sp1","all"}
local DAMAGE_PHASES={"damage","status"}
local CANONICAL={attack=true,special=true,sp1=true,all=true,damage=true,status=true}
local function phasesFor(disc,stem,preferred,layerPreferred)
local found,variants={},{}
local function exists(phase)
phase=tostring(phase or ""):lower()
if phase=="" then return false end
if found[phase]~=nil then return found[phase] end
found[phase]=disc:file(sourcePhaseArchivePath(stem,phase,disc)) and true or false
return found[phase]
end
for _,phase in ipairs(preferred or {}) do exists(phase) end
if type(disc.find)=="function" then
local prefix="wzx_"..stem.."_"
for _,file in ipairs(disc:find(prefix)) do
local base=tostring(file.path or ""):lower():match("([^/]+)$") or ""
local phase=base:match("^"..prefix:gsub("([^%w])","%%%1").."(.+)%.fsys$")
if phase then found[phase]=true;if not CANONICAL[phase] then variants[#variants+1]=phase end end
end



local numbered="wzx_"..stem
for _,file in ipairs(disc:find(numbered)) do
local base=tostring(file.path or ""):lower():match("([^/]+)$") or ""
local number,suffix=base:match("^"..numbered:gsub("([^%w])","%%%1").."(%d+)_(.+)%.fsys$")
if number and suffix then
local phase=number.."_"..suffix
found[phase]=true;variants[#variants+1]=phase
end
end
end




local out,seen={},{}
local function add(phase)
phase=tostring(phase or ""):lower()
if phase~="" and exists(phase) and not seen[phase] then seen[phase]=true;out[#out+1]=phase end
end
for _,phase in ipairs(preferred or {}) do add(phase) end
for _,phase in ipairs(ATTACK_PHASES) do add(phase) end
for _,phase in ipairs(DAMAGE_PHASES) do add(phase) end
local rest={};for phase,ok in pairs(found) do if ok and not seen[phase] then rest[#rest+1]=phase end end
table.sort(rest);for _,phase in ipairs(rest) do add(phase) end
table.sort(variants)
return out,variants
end

M._internal={scanSequenceGPT1=scanSequenceGPT1,scanGPT1=scanGPT1,compileWazaModel=compileWazaModel,phasesFor=phasesFor,decodeGSTexture=decodeGSTexture}








local CAPTURE_BALLS={
poke={suffix="monster",aliases={"POKE_BALL","POKEBALL","MONSTER_BALL","BALL"}},
great={suffix="super",aliases={"GREAT_BALL","GREATBALL","SUPER_BALL"}},
ultra={suffix="hyper",aliases={"ULTRA_BALL","ULTRABALL","HYPER_BALL"}},
master={suffix="master",aliases={"MASTER_BALL","MASTERBALL"}},
safari={suffix="safari",aliases={"SAFARI_BALL","SAFARIBALL"}},
net={suffix="net",aliases={"NET_BALL","NETBALL"}},
nest={suffix="nest",aliases={"NEST_BALL","NESTBALL"}},
repeatball={suffix="repeat",aliases={"REPEAT_BALL","REPEATBALL"}},
timer={suffix="timer",aliases={"TIMER_BALL","TIMERBALL"}},
dive={suffix="dive",aliases={"DIVE_BALL","DIVEBALL"}},
premier={suffix="premire",aliases={"PREMIER_BALL","PREMIERBALL","PREMIRE_BALL"}},
luxury={suffix="gorgeus",aliases={"LUXURY_BALL","LUXURYBALL","GORGEOUS_BALL","GORGEOUS"}},
}
local CAPTURE_PHASES={
throw="snatch_attack",
land="snatch_ball_land",
shake="snatch_shake",
miss="snatch_miss",
}
local function captureArchiveName(base,suffix)
return "wzx_"..base..((suffix and suffix~="") and ("_"..suffix) or "")..".fsys"
end
local function captureSource(disc,archiveName)
local file=disc and disc:file(archiveName);if not file then return nil,"source archive missing: "..archiveName end
local okArc,arc=pcall(FSYS.open,disc,file);if not okArc or not arc then return nil,("FSYS open failed [%s]: %s"):format(tostring(archiveName),tostring(arc)) end
local list=arc:list() or {};local entry




for _,candidate in ipairs(list) do
if tostring(candidate.name or ""):lower():find("%.fdat$",1,false) then entry=candidate;break end
end
if not entry then
for _,candidate in ipairs(list) do
if tostring(candidate.name or ""):lower():find("%.wzx$",1,false) then entry=candidate;break end
end
end
entry=entry or list[1];if not entry then return nil,"empty source archive: "..archiveName end
local okBlob,blob=pcall(arc.extract,arc,entry,{maxOutput=64*1024*1024})
if not okBlob or type(blob)~="string" then return nil,("capture WZX extraction failed [%s/%s]: %s"):format(tostring(archiveName),tostring(entry.name),tostring(blob or "unknown error")) end
local okTimeline,timeline,why=pcall(Waza.parse,blob,{phase="capture",member=entry.name})
if not okTimeline or type(timeline)~="table" then return nil,("capture WZX parse failed [%s/%s]: %s"):format(tostring(archiveName),tostring(entry.name),tostring(okTimeline and why or timeline)) end
return {blob=blob,timeline=timeline,member=entry.name,archive=archiveName}
end
local CAPTURE_BALL_EXPECTED_BYTES=7168
local CAPTURE_PHASE_ORDER={"shake","throw","land","miss"}



local function captureHash(bytes)
if type(bytes)~="string" then return "0:00000000" end
local h=5381
for i=1,#bytes do h=(h*33+bytes:byte(i))%2147483647 end
return ("%d:%08X"):format(#bytes,h)
end
local function captureQuant(v)
v=tonumber(v) or 0
return math.floor(v*10000+(v>=0 and .5 or -.5))
end
local function captureVisualFingerprint(model)
if type(model)~="table" then return nil end
local b=model.bounds or {};local mn=b.min or {};local mx=b.max or {}
local parts={tostring(tonumber(model.vertexCount) or 0)}
for k=1,3 do parts[#parts+1]=tostring(captureQuant((tonumber(mx[k]) or 0)-(tonumber(mn[k]) or 0))) end
for _,g in ipairs(model.groups or {}) do
local t=g.texture
if t and type(t.rgba)=="string" then
parts[#parts+1]=table.concat({"T",tostring(t.w or 0),tostring(t.h or 0),tostring(t.format or 0),captureHash(t.rgba)},":")
else
parts[#parts+1]="U:"..tostring(#(g.vertices or {}))
end
end
return table.concat(parts,"|")
end
local function captureEmbeddedFingerprint(blob,entry)
local off=tonumber(entry and entry.dataOffset);local size=tonumber(entry and (entry.dataSize or entry.embeddedSize))
if not off or not size or off<0 or size<=0 or type(blob)~="string" or off+size>#blob then return nil end
return captureHash(blob:sub(off+1,off+size))
end

local CAPTURE_DECODE_OPTS={textures=true,maxRoots=96,maxVertices=90000,maxDisplayOps=300000,maxJobjs=4096,maxDobjs=12000,maxPobjs=20000}

local function capturePreviewFromModel(model,size,embeddedFingerprint,sizeHint)
if type(model)~="table" then return nil,"decoded HSD model unavailable" end
local b=model.bounds or {};local mn=b.min or {};local mx=b.max or {}
local sx=math.abs((tonumber(mx[1]) or 0)-(tonumber(mn[1]) or 0))
local sy=math.abs((tonumber(mx[2]) or 0)-(tonumber(mn[2]) or 0))
local sz=math.abs((tonumber(mx[3]) or 0)-(tonumber(mn[3]) or 0))
local largest=math.max(sx,sy,sz);local smallest=math.min(sx,sy,sz)
local aspect=(smallest>1e-6) and (largest/smallest) or math.huge
local textures=0
for _,g in ipairs(model.groups or {}) do
local t=g.texture;if t and type(t.rgba)=="string" and tonumber(t.w) and tonumber(t.h) then textures=textures+1 end
end
local vertices=tonumber(model.vertexCount) or 0
local score=0
if aspect<=1.35 then score=score+90
elseif aspect<=1.70 then score=score+65
elseif aspect<=2.20 then score=score+35
elseif aspect<=3.00 then score=score+10
else score=score-math.min(50,(aspect-3)*8) end
if vertices>=24 and vertices<=12000 then score=score+20 elseif vertices>50000 then score=score-30 end
score=score+math.min(4,textures)*8



if sizeHint and tonumber(size) and tonumber(size)>0 then
local ratio=math.max(size,1)/CAPTURE_BALL_EXPECTED_BYTES
score=score+12/(1+math.abs(math.log(ratio)))
end
return {model=model,size=tonumber(size) or 0,vertices=vertices,textures=textures,spans={sx,sy,sz},aspect=aspect,
score=score,visualFingerprint=captureVisualFingerprint(model),embeddedFingerprint=embeddedFingerprint}
end

local function captureModelPreview(blob,entry)
if not (HSD and type(HSD.extractModel)=="function" and type(blob)=="string" and type(entry)=="table") then
return nil,"HSD preview unavailable"
end
local off=tonumber(entry.dataOffset);local size=tonumber(entry.dataSize or entry.embeddedSize)
if not off or not size or off<0 or size<=0 or off+size>#blob then return nil,"model source range invalid" end
local source=blob:sub(off+1,off+size)
local model,err=HSD.extractModel(source,CAPTURE_DECODE_OPTS)
if not model then return nil,err or "HSD decode failed" end
return capturePreviewFromModel(model,size,captureEmbeddedFingerprint(blob,entry),true)
end





local function captureMemberCandidates(src)
local out={}
if not (src and type(src.blob)=="string" and HSD) then return out end
local models,why
if type(HSD.extractModels)=="function" then
models,why=HSD.extractModels(src.blob,CAPTURE_DECODE_OPTS)
elseif type(HSD.extractModel)=="function" then
local one,err=HSD.extractModel(src.blob,CAPTURE_DECODE_OPTS);why=err
if one then models={one} end
end
if type(models)~="table" then return out,why end
for ri,model in ipairs(models) do
local preview=capturePreviewFromModel(model,#src.blob,nil,false)
if preview then
out[#out+1]={memberRoot=true,rootIndex=ri,size=#src.blob,preview=preview,score=preview.score,
entry={identifier=9000+ri,entryType="member-hsd",kind="member-model"}}
end
end
table.sort(out,function(a,b)
if a.score~=b.score then return a.score>b.score end
return (a.preview.vertices or math.huge)<(b.preview.vertices or math.huge)
end)
return out,why
end

local function captureBallCandidates(src)
local out={}
for _,entry in ipairs((src and src.timeline and src.timeline.entries) or {}) do
if tonumber(entry.entryType)==2 or entry.kind=="model" then
local size=tonumber(entry.dataSize or entry.embeddedSize) or 0
if size>0 then
local preview,why=captureModelPreview(src.blob,entry)
out[#out+1]={entry=entry,size=size,preview=preview,error=why,score=preview and preview.score or -math.huge}
end
end
end
table.sort(out,function(a,b)
if (a.preview~=nil)~=(b.preview~=nil) then return a.preview~=nil end
if a.score~=b.score then return a.score>b.score end
return a.size<b.size
end)
return out
end

local function captureTimelineDump(src,id,phase)
local t=src and src.timeline or {}
local out={
("[%s/%s] archive=%s member=%s parsed=%s complete=%s parse_error=%s"):format(
tostring(id),tostring(phase),tostring(src and src.archive),tostring(src and src.member),
tostring(t and t.parsedCount),tostring(t and t.complete),tostring(t and t.parseError))
}
for i,e in ipairs((t and t.entries) or {}) do
out[#out+1]=("  #%d id=%s type=%s kind=%s dataSize=%s embeddedSize=%s dataOffset=%s magic=%s state=%s attachment=%s part=%s position=%s"):format(
i,tostring(e.identifier),tostring(e.entryType),tostring(e.kind),tostring(e.dataSize),
tostring(e.embeddedSize),tostring(e.dataOffset),tostring(e.dataMagic and hex(e.dataMagic) or nil),tostring(e.state),
tostring(e.attachment),tostring(e.partIndex),tostring(e.positionType))
end
return table.concat(out,"\n")
end

local function shallowCopy(t)
local o={};for k,v in pairs(t or {}) do o[k]=v end;return o
end

function M.extractCaptureAssets(mod,disc,progress,generated,options)
if not (mod and disc and Waza and type(Waza.parse)=="function") then return nil,"capture source extractor unavailable" end
local previousMod,previousGenerated=M.mod,M.buildGenerated
local previousSeen,previousPreserve=M.buildGeneratedSeen,M.preserveExistingWrites
M.mod=mod;M.buildGenerated=generated;M.buildGeneratedSeen={};M.preserveExistingWrites=options and options.preserveExisting==true or false
local index={revision=6,source="GC6E01 native snatch FSYS member HSD roots + Waza type-2 fallback / static runtime",balls={},aliases={},sourceReady=0,fallbackBalls=0,sourceComplete=false}
local ids={"poke","great","ultra","master","safari","net","nest","repeatball","timer","dive","premier","luxury"}
local failures={};local timelineDiagnostics={};local candidateDiagnostics={}
local function recordFailure(id,phase,why)
local msg=tostring(id).."/"..tostring(phase)..": "..tostring(why);failures[#failures+1]=msg;return msg
end
local function flushCaptureDiagnostics()
local timelineText=table.concat(timelineDiagnostics,"\n\n");if timelineText~="" then timelineText=timelineText.."\n" end
local okT,whyT=write("build/capture_timeline_entries.txt",timelineText);if not okT then error(tostring(whyT),0) end
local candidateText=table.concat(candidateDiagnostics,"\n");if candidateText~="" then candidateText=candidateText.."\n" end
return candidateText
end

local okRun,runErr=pcall(function()
for bi,id in ipairs(ids) do
if type(progress)=="function" then pcall(progress,"CAPTURE BALLS / "..id:upper(),bi-1,#ids) end
local def=CAPTURE_BALLS[id];local row={id=id,suffix=def.suffix,phases={},sourceReady=false,fallback=false}
local sources={};local all={};local identifierPhases={};local visualPhases={};local embeddedPhases={}




for _,phase in ipairs(CAPTURE_PHASE_ORDER) do
local base=CAPTURE_PHASES[phase];local archive=captureArchiveName(base,def.suffix)
local src,why=captureSource(disc,archive)
if src then
sources[phase]=src;timelineDiagnostics[#timelineDiagnostics+1]=captureTimelineDump(src,id,phase)




local memberCandidates,memberWhy=captureMemberCandidates(src)
src.memberCandidates=memberCandidates
for ci,c in ipairs(memberCandidates or {}) do
local pv=c.preview
candidateDiagnostics[#candidateDiagnostics+1]=("%s/%s MEMBER_HSD root=%s vertices=%s textures=%s score=%.3f aspect=%s spans=%s"):format(
tostring(id),tostring(phase),tostring(c.rootIndex),tostring(pv and pv.vertices),tostring(pv and pv.textures),
tonumber(c.score) or -9999,tostring(pv and pv.aspect or nil),
pv and table.concat({("%.4g"):format(pv.spans[1]),("%.4g"):format(pv.spans[2]),("%.4g"):format(pv.spans[3])},",") or "nil")
if pv then
local ident="member:"..tostring(c.rootIndex)
identifierPhases[ident]=identifierPhases[ident] or {};identifierPhases[ident][phase]=true
if pv.visualFingerprint then visualPhases[pv.visualFingerprint]=visualPhases[pv.visualFingerprint] or {};visualPhases[pv.visualFingerprint][phase]=true end
all[#all+1]={phase=phase,src=src,candidate=c,memberRoot=true}
end
end
if #(memberCandidates or {})==0 then
candidateDiagnostics[#candidateDiagnostics+1]=(tostring(id).."/"..tostring(phase).." MEMBER_HSD none: "..tostring(memberWhy or "no roots"))
end



local candidates=captureBallCandidates(src);src.captureCandidates=candidates
for ci,c in ipairs(candidates) do
local pv=c.preview
candidateDiagnostics[#candidateDiagnostics+1]=("%s/%s preview=%d id=%s type=%s size=%s decode=%s score=%.3f aspect=%s spans=%s vertices=%s textures=%s err=%s"):format(
tostring(id),tostring(phase),ci,tostring(c.entry.identifier),tostring(c.entry.entryType),tostring(c.size),
tostring(pv~=nil),tonumber(c.score) or -9999,tostring(pv and pv.aspect or nil),
pv and table.concat({("%.4g"):format(pv.spans[1]),("%.4g"):format(pv.spans[2]),("%.4g"):format(pv.spans[3])},",") or "nil",
tostring(pv and pv.vertices or nil),tostring(pv and pv.textures or nil),tostring(c.error))
if pv then
local ident=tostring(c.entry.identifier or "nil")
identifierPhases[ident]=identifierPhases[ident] or {};identifierPhases[ident][phase]=true
if pv.visualFingerprint then visualPhases[pv.visualFingerprint]=visualPhases[pv.visualFingerprint] or {};visualPhases[pv.visualFingerprint][phase]=true end
if pv.embeddedFingerprint then embeddedPhases[pv.embeddedFingerprint]=embeddedPhases[pv.embeddedFingerprint] or {};embeddedPhases[pv.embeddedFingerprint][phase]=true end
all[#all+1]={phase=phase,src=src,candidate=c,memberRoot=false}
end
end
else
recordFailure(id,phase,why)
end
end










local function phaseCount(set)local n=0;for _ in pairs(set or {}) do n=n+1 end;return n end
local phaseBonus={shake=260,land=120,throw=90,miss=35}
local ranked={}
for _,x in ipairs(all) do
local pv=x.candidate.preview or {}
local ident=tostring(x.candidate.entry.identifier or "nil")
local exactN=phaseCount(embeddedPhases[pv.embeddedFingerprint])
local visualN=phaseCount(visualPhases[pv.visualFingerprint])
local identN=phaseCount(identifierPhases[ident])
local textures=tonumber(pv.textures) or 0
local vertices=tonumber(pv.vertices) or 0
local aspect=tonumber(pv.aspect) or math.huge
local textureEvidence=(textures>0) and (120+math.min(textures,4)*12) or -80
local shapeEvidence=(aspect<=1.8 and 90) or (aspect<=2.4 and 45) or (aspect<=3.0 and 5) or -120
local vertexEvidence=(vertices>=24 and vertices<=20000) and 30 or ((vertices>0 and vertices<=50000) and 5 or -60)
local recurrenceEvidence=exactN*80+visualN*120+identN*18


local memberEvidence=x.memberRoot and 420 or 0
local score=(tonumber(x.candidate.score) or 0)+(phaseBonus[x.phase] or 0)+textureEvidence+shapeEvidence+vertexEvidence+recurrenceEvidence+memberEvidence
x.exactPhaseCount=exactN;x.visualPhaseCount=visualN;x.identifierPhaseCount=identN;x.lockScore=score



x.strongBallCandidate=(textures>0 and vertices>=24 and vertices<=50000 and aspect<=3.0)
ranked[#ranked+1]=x
end
table.sort(ranked,function(a,b)
if a.strongBallCandidate~=b.strongBallCandidate then return a.strongBallCandidate==true end
if a.lockScore~=b.lockScore then return a.lockScore>b.lockScore end
if a.phase~=b.phase then return (phaseBonus[a.phase] or 0)>(phaseBonus[b.phase] or 0) end
return (a.candidate.size or math.huge)<(b.candidate.size or math.huge)
end)






local compiledAny,canonical,chosenAsset,lastErr=nil,nil,nil,nil
for ai,x in ipairs(ranked) do
local stem="capture/"..id
local trial,why
if x.memberRoot then
trial,why=compileDecodedCaptureModel(x.candidate.preview and x.candidate.preview.model,stem,x.phase,"root"..tostring(x.candidate.rootIndex or ai))
else
trial,why=compileWazaModel(x.src.blob,x.candidate.entry,stem,x.phase,{staticOnly=true})
end
local pv=x.candidate.preview or {}
candidateDiagnostics[#candidateDiagnostics+1]=("%s/source-lock compile=%d sourcePhase=%s id=%s size=%s score=%.3f strong=%s exact=%s visual=%s ident=%s textures=%s aspect=%s result=%s"):format(
tostring(id),ai,tostring(x.phase),tostring(x.candidate.entry.identifier),tostring(x.candidate.size),
tonumber(x.lockScore) or 0,tostring(x.strongBallCandidate==true),tostring(x.exactPhaseCount or 0),
tostring(x.visualPhaseCount or 0),tostring(x.identifierPhaseCount or 0),tostring(pv.textures),tostring(pv.aspect),
trial and (x.memberRoot and "PASS_MEMBER_HSD_STATIC" or "PASS_TYPE2_STATIC") or ("FAIL "..tostring(why)))
if trial then canonical=x;chosenAsset=trial;break else lastErr=why end
end

if canonical and chosenAsset then
local pv=canonical.candidate.preview or {}
row.canonicalIdentifier=canonical.candidate.entry.identifier
row.canonicalSourcePhase=canonical.phase
row.canonicalScore=canonical.lockScore
row.canonicalExactPhases=canonical.exactPhaseCount
row.canonicalVisualPhases=canonical.visualPhaseCount
row.canonicalIdentifierPhases=canonical.identifierPhaseCount
row.selection=canonical.memberRoot and "snatch-member-hsd-root-v1" or "waza-type2-decoded-hsd-v3"
row.staticSource=true
chosenAsset.sourceArchive=canonical.src.archive
chosenAsset.sourceMember=canonical.src.member
chosenAsset.sourceEntry=canonical.memberRoot and ("member-root:"..tostring(canonical.candidate.rootIndex)) or canonical.candidate.entry.identifier
chosenAsset.sourceBytes=canonical.memberRoot and #canonical.src.blob or canonical.candidate.size
chosenAsset.sourceLocked=true
chosenAsset.staticSource=true
chosenAsset.sourceSelection=row.selection
local rawPath=("cache/capture/source/%s_%s.wzx"):format(id,canonical.phase)
local wrote,werr=write(rawPath,canonical.src.blob);if not wrote then error(tostring(werr),0) end
chosenAsset.rawPath=rawPath





for _,phase in ipairs(CAPTURE_PHASE_ORDER) do
local asset=shallowCopy(chosenAsset)
asset.capturePhase=phase
asset.sourcePhase=canonical.phase
asset.sharedRetailProp=true
row.phases[phase]=asset
end
compiledAny=chosenAsset
row.sourceReady=true;index.sourceReady=index.sourceReady+1
else
recordFailure(id,"all","no drawable retail HSD ball root found in snatch member or type-2 payload: "..tostring(lastErr or "no candidate"))
row.fallback=true
row.fallbackReason="native source model unavailable; runtime procedural capture prop enabled"
index.fallbackBalls=index.fallbackBalls+1
end
index.balls[id]=row
for _,alias in ipairs(def.aliases or {}) do index.aliases[tostring(alias):upper()]=id end
local candidateText=flushCaptureDiagnostics()
local failText=table.concat(failures,"\n");if failText~="" then failText=failText.."\n" end
local okD,whyD=write("build/capture_source.txt",failText..candidateText);if not okD then error(tostring(whyD),0) end
end

index.sourceComplete=(index.sourceReady==#ids and index.fallbackBalls==0)



index.ready=true
local okIndex,indexErr=write("cache/capture/index.lua","return "..serialize(index).."\n");if not okIndex then error(tostring(indexErr),0) end
local candidateText=flushCaptureDiagnostics();local failText=table.concat(failures,"\n");if failText~="" then failText=failText.."\n" end
local okDiag,diagErr=write("build/capture_source.txt",failText..candidateText);if not okDiag then error(tostring(diagErr),0) end
if type(progress)=="function" then pcall(progress,("CAPTURE BALLS READY / %d SOURCE / %d FALLBACK"):format(index.sourceReady,index.fallbackBalls),#ids,#ids) end
end)

if not okRun then
pcall(function()
local detail=table.concat(failures,"\n");if detail~="" then detail=detail.."\n" end
local candidateText=table.concat(candidateDiagnostics,"\n");if candidateText~="" then candidateText=candidateText.."\n" end
write("build/capture_source.txt",detail..candidateText.."fatal="..tostring(runErr).."\n")
end)
end
M.mod=previousMod;M.buildGenerated=previousGenerated;M.buildGeneratedSeen=previousSeen;M.preserveExistingWrites=previousPreserve
if not okRun then return nil,tostring(runErr) end
return {ready=index.ready==true,sourceComplete=index.sourceComplete==true,count=#ids,sourceReady=index.sourceReady,
fallbackBalls=index.fallbackBalls,failures=failures,index="cache/capture/index.lua",
message=index.sourceComplete and nil or ("capture bank ready with "..tostring(index.sourceReady).."/"..tostring(#ids).." retail HSD balls; unresolved rows use explicit procedural fallback")}
end







function M.extractAllMoves(mod,disc,progress,generated,options)
assert(mod and mod.cache,"MoveFX full build: cache unavailable")
assert(disc,"MoveFX full build: disc unavailable")
local previousMod,previousOpen,previousGenerated=M.mod,M.openDisc,M.buildGenerated
local previousSeen,previousSourceRows,previousOverrides,previousOverridesMeta,previousIndex,previousPreserve=
M.buildGeneratedSeen,M.sourceMoveRows,M.retailModelOverrides,M.retailModelOverridesMeta,M.indexMemory,M.preserveExistingWrites
M.mod=mod;M.openDisc=function() return disc end;M.buildGenerated=generated;M.buildGeneratedSeen={};M.preserveExistingWrites=options and options.preserveExisting==true or false
local sourceRows,sourceRowsMeta=extractSourceMoveRows(disc)
if not sourceRows then
M.mod=previousMod;M.openDisc=previousOpen;M.buildGenerated=previousGenerated;M.buildGeneratedSeen=previousSeen
M.sourceMoveRows=previousSourceRows;M.retailModelOverrides=previousOverrides;M.retailModelOverridesMeta=previousOverridesMeta;M.indexMemory=previousIndex;M.preserveExistingWrites=previousPreserve
return nil,"Colosseum move animation table unavailable: "..tostring(sourceRowsMeta)
end
local retailOverrides,retailOverridesMeta=extractRetailModelOverrides(disc)
if not retailOverrides then
M.mod=previousMod;M.openDisc=previousOpen;M.buildGenerated=previousGenerated;M.buildGeneratedSeen=previousSeen
M.sourceMoveRows=previousSourceRows;M.retailModelOverrides=previousOverrides;M.retailModelOverridesMeta=previousOverridesMeta;M.indexMemory=previousIndex;M.preserveExistingWrites=previousPreserve
return nil,"Colosseum model-specific attack table unavailable: "..tostring(retailOverridesMeta)
end
M.sourceMoveRows=sourceRows;M.retailModelOverrides=retailOverrides;M.retailModelOverridesMeta=retailOverridesMeta;M.indexMemory=nil
saveRetailSelectorCache()
M.memory={};M.negative={};M.pending={};M.pendingKeys={};M.prefetchStats={queued=0,completed=0,failed=0}
local index={revision=M.revision,wazaRevision=Waza and Waza.revision or nil,source="GC6E01 common_rel move animation selection + retail WZX",
moveTable=sourceRowsMeta,modelOverrideTable=retailOverridesMeta,moves={},soundIds={}}
local soundSeen={};local ready,missing,fullReady=0,0,0;local report={}
local okRun,runErr=pcall(function()
for id=1,354 do
if type(progress)=="function" then pcall(progress,("MOVEFX %03d/354"):format(id),id-1,354) end
local spec,err=M.acquire(id,nil)
if type(spec)=="table" then
ready=ready+1



local rowUnsupported={}
for _,u in ipairs((spec.coverage and spec.coverage.unsupported) or {}) do
if u.moveId==nil or tonumber(u.moveId)==id then rowUnsupported[#rowUnsupported+1]=u end
end
local row={id=id,stem=spec.stem,style=spec.style,wazaReady=spec.wazaReady==true,
sourceAnimation=sourceRows[id],
retailModelOverrides=spec.retailModelOverrideSourceByMove and spec.retailModelOverrideSourceByMove[id] or nil,
attackReady=spec.attackReady==true,damageReady=spec.damageReady==true,fullVisualReady=spec.fullVisualReady==true,
phases=(spec.coverage and spec.coverage.phases) or #(spec.wazaPhases or {}),entries=(spec.coverage and spec.coverage.entries) or 0,
unsupported=rowUnsupported,soundIds={}}
if row.fullVisualReady then fullReady=fullReady+1 end
local localSeen={}
for _,se in ipairs(spec.sounds or {}) do
local sid=(type(se)=="table" and tonumber(se.sourceType)==5) and tonumber(se.soundId) or nil
if sid and sid>=0 and sid<65536 and not localSeen[sid] then
sid=math.floor(sid);localSeen[sid]=true;row.soundIds[#row.soundIds+1]=sid
if not soundSeen[sid] then soundSeen[sid]=true;index.soundIds[#index.soundIds+1]=sid end
end
end
table.sort(row.soundIds);index.moves[id]=row
report[#report+1]=("%03d READY anim=%s/%s stem=%s waza=%s attack=%s damage=%s full=%s phases=%d entries=%d unsupported=%d sounds=%d"):format(
id,tostring(row.sourceAnimation and row.sourceAnimation.primaryAnimationId or "?"),tostring(row.sourceAnimation and row.sourceAnimation.secondaryAnimationId or "?"),
tostring(spec.stem),tostring(row.wazaReady),tostring(row.attackReady),tostring(row.damageReady),tostring(row.fullVisualReady),
tonumber(row.phases) or 0,tonumber(row.entries) or 0,#(row.unsupported or {}),#row.soundIds)
for _,u in ipairs(row.unsupported or {}) do report[#report+1]=("    UNSUPPORTED phase=%s entry=%s kind=%s reason=%s"):format(tostring(u.phase),tostring(u.index),tostring(u.kind),tostring(u.reason)) end
else
missing=missing+1
index.moves[id]={id=id,missing=true,error=tostring(err or "source WZX unavailable")}
report[#report+1]=("%03d MISSING %s"):format(id,tostring(err or "source WZX unavailable"))
end
if id%8==0 and type(collectgarbage)=="function" then pcall(collectgarbage,"step",220) end
end
table.sort(index.soundIds)
index.ready=ready;index.fullVisualReady=fullReady;index.missing=missing;index.total=354;index.uniqueSounds=#index.soundIds
write("cache/movefx/index.lua","return "..serialize(index).."\n")
write("build/movefx_coverage.txt",table.concat(report,"\n").."\n")
if type(progress)=="function" then pcall(progress,("MOVEFX SOURCE %d/354 / FULL VISUAL %d/354 / %d source SFX ids"):format(ready,fullReady,#index.soundIds),354,354) end
end)
M.mod=previousMod;M.openDisc=previousOpen;M.buildGenerated=previousGenerated;M.buildGeneratedSeen=previousSeen
M.sourceMoveRows=previousSourceRows;M.retailModelOverrides=previousOverrides;M.retailModelOverridesMeta=previousOverridesMeta;M.indexMemory=previousIndex;M.preserveExistingWrites=previousPreserve
if not okRun then return nil,tostring(runErr) end
return {ready=(ready==354 and missing==0),fullVisualReady=(fullReady==354),fullVisualCount=fullReady,total=354,sourceReady=ready,missing=missing,soundIds=index.soundIds,index=index}
end

function M.install(mod,openDisc)
M.mod=mod;M.openDisc=openDisc;ensureRetailSelectorSources(nil);return true
end
function M.cachePath(stem) return "cache/movefx/"..stem.."/effect.lua" end






local function type4RangeStale(spec)
local want=Waza and tonumber(Waza.type4RangeRevision) or nil
if type(spec)~="table" or not want or tonumber(spec.type4RangeRevision)==want then return false end
for _,phase in ipairs(spec.wazaPhases or {}) do
for _,e in ipairs(phase.entries or {}) do
if e.kind=="type4" and (e.effectSupported~=true
or ((e.effectRequiredArtifact=="model" or e.effectRequiredArtifact=="texture") and e.effectRuntimeReady==false)) then
return true
end
end
end
return false
end
M._type4RangeStale=type4RangeStale

function M.acquire(moveId,move,requestedPhases,options)
checkpoint("Reading move effect bank")
options=type(options)=="table" and options or nil
local isolated=options and options.isolated==true
local function metadataPath(candidate)
return (options and options.metadataPath) or M.cachePath(candidate)
end
local p,id=profile(moveId,move);if not p then return nil,"unmapped move" end
if id and not M.sourceMoveRows then
local ready=ensureRetailSelectorSources(nil)
if not ready and M.openDisc then
local disc=M.openDisc();if disc then
local ok,why=ensureRetailSelectorSources(disc);if not ok then return nil,why end
end
end
end
local candidates=includeIndexedStem(sourceStemCandidates(p,id,move),id)
if #candidates==0 then return nil,"no source stem candidates" end
local selectorDisc
local function prepareCachedSelector(cached,candidate)
if specRetailSelectionReady(cached,id) then return true end
local ready,why=ensureRetailSelectorSources(nil)
if not ready then
if type(M.openDisc)~="function" then return false,why end
if not selectorDisc then
local ok,value=pcall(M.openDisc);if not ok or not value then return false,"source disc unavailable: "..tostring(value) end
selectorDisc=value
end
ready,why=ensureRetailSelectorSources(selectorDisc)
end
if not ready then return false,why end
if ensureSpecRetailModelMove(cached,id) then
local okWrite,writeWhy=write(metadataPath(candidate),"return "..serialize(cached).."\n",true)
if not okWrite then return false,writeWhy end
end
if not specRetailSelectionReady(cached,id) then return false,"retail model-specific attack selection was not resolved" end
return true
end

for _,candidate in ipairs(candidates) do
if not isolated and M.memory[candidate]~=nil then
if M.memory[candidate] then
local cached=M.memory[candidate]
local ready=prepareCachedSelector(cached,candidate)
if ready then refreshEmbeddedCameraCache(cached,candidate);return cached end
end
else
local cached=cacheReadLua(metadataPath(candidate))
if type(cached)=="table" and cached.revision==M.revision and cached.wazaRevision==(Waza and Waza.revision or nil) and cached.stem==candidate
and not type4RangeStale(cached) then
local ready=prepareCachedSelector(cached,candidate)
if ready then refreshEmbeddedCameraCache(cached,candidate);if not isolated then M.memory[candidate]=cached end;return cached end
end
end
end
local negKey=tostring(id or norm(type(move)=="table" and (move.name or move.id or move.move) or moveId))
if not isolated and M.negative[negKey] then return nil,M.negative[negKey] end
if type(M.openDisc)~="function" then return nil,"source disc opener unavailable" end
local disc=selectorDisc
if not disc then
local okDisc,value=pcall(M.openDisc);if not okDisc or not value then return nil,"source disc unavailable: "..tostring(value) end
disc=value
end





if id then
local selectorsReady,selectorWhy=ensureRetailSelectorSources(disc)
if not selectorsReady then return nil,selectorWhy end
end



do
local seen={};for _,v in ipairs(candidates) do seen[v]=true end
for _,v in ipairs(includeIndexedStem(sourceStemCandidates(p,id,move),id)) do
if not seen[v] then candidates[#candidates+1]=v;seen[v]=true end
end
end
local key,phases,variants
local attempted={}
for _,candidate in ipairs(candidates) do
local found,var=phasesFor(disc,candidate,p.phases,(id and MOVE[id]~=nil and p.candidate~=true) and true or false)
attempted[#attempted+1]=candidate
if #found>0 then key=candidate;phases=found;variants=var;break end
if not isolated then M.memory[candidate]=false end
end
if not key then
local why="no source WZX archive for candidates: "..table.concat(attempted,",")
if not isolated then M.negative[negKey]=why end
return nil,why
end

local banks,errors={},nil
if requestedPhases then
local allowed={};for _,phase in ipairs(requestedPhases)do allowed[phase]=true end
local filtered={};for _,phase in ipairs(phases)do if allowed[phase] then filtered[#filtered+1]=phase end end
phases=filtered
end
for _,phase in ipairs(phases) do
checkpoint("Decoding move effect "..tostring(key).." / "..phase)
local fx,err=extractWZX(disc,key,phase)
if fx and (#fx.textures>0 or #fx.sounds>0 or #fx.programs>0
or (type(fx.waza)=="table" and (#(fx.waza.entries or {})>0 or (tonumber(fx.waza.hsdSize) or 0)>0))) then
banks[#banks+1]=fx
else errors=err or errors end
end
local sourceAnimation=M.sourceMoveRows and M.sourceMoveRows[tonumber(id)] or nil
local meta={revision=M.revision,wazaRevision=Waza and Waza.revision or nil,type4RangeRevision=Waza and Waza.type4RangeRevision or nil,stem=key,moveId=id,style=p.style,tint=p.tint,stemCandidates=candidates,
phase=banks[1] and banks[1].phase or nil,generators=0,maxLifetime=0,
textures={},phases={},variants=variants or {},sounds={},generatorPrograms={},lookupTables={},wazaPhases={},wazaModels=0,wazaModelErrors={},wazaEffects=0,wazaEffectModels=0,wazaEffectArtifacts=0,wazaEffectErrors={},
sourceAnimation=sourceAnimation,retailModelPhasesByMove={},retailModelOverrideBlockersByMove={},retailModelOverrideSourceByMove={},retailModelSelectionDone={},
source="GC6E01 WazaSequence timeline + typed native handlers + main.dol model-specific attack selection",
sourceSelector=options and options.sourceSelector or nil,sourceItemBallField=options and options.sourceItemBallField or nil,
sourceResourceGroup=options and options.sourceResourceGroup or nil}
local nextGlobalBank=0
for _,bankFx in ipairs(banks) do
local phaseMeta={name=bankFx.phase,first=#meta.textures+1,count=0,generators=bankFx.generators or 0,roots=0,maxLifetime=bankFx.maxLifetime or 0,
resourceGroup=bankFx.resourceGroup}
meta.generators=meta.generators+(bankFx.generators or 0)
meta.maxLifetime=math.max(meta.maxLifetime,bankFx.maxLifetime or 0)






local bankMap={}
local function globalBank(localBank)
localBank=tonumber(localBank) or 1
if not bankMap[localBank] then nextGlobalBank=nextGlobalBank+1;bankMap[localBank]=nextGlobalBank end
return bankMap[localBank]
end





local rawWazaPath=("cache/movefx/%s/%s.wzx"):format(key,bankFx.phase)
if type(bankFx.blob)=="string" then write(rawWazaPath,bankFx.blob) end
if type(bankFx.waza)=="table" then
local timeline={}
for k,v in pairs(bankFx.waza) do if k~="entries" then timeline[k]=v end end




timeline.name=bankFx.phase
timeline.rawPath=rawWazaPath
timeline.resourceGroup=bankFx.resourceGroup





local cameraSize=math.max(0,math.floor(tonumber(bankFx.waza.hsdSize or (bankFx.waza.root and bankFx.waza.root.embeddedSize)) or 0))
if cameraSize>0 and HSD and type(HSD.extractCameraAnimation)=="function" and type(bankFx.blob)=="string" then
local cameraAt=0xA0
if cameraAt+cameraSize<=#bankFx.blob then
local okCamera,camera,why=pcall(HSD.extractCameraAnimation,bankFx.blob:sub(cameraAt+1,cameraAt+cameraSize),
{phase=bankFx.phase,wazaOffsetWorldUp=true})
if okCamera and type(camera)=="table" then
timeline.sourceCamera=camera
else
timeline.sourceCameraError=tostring(okCamera and why or camera)
end
else
timeline.sourceCameraError="embedded HSD camera range exceeds WZX member"
end
end
timeline.entries={}
for _,entry in ipairs(bankFx.waza.entries or {}) do
checkpoint("Preparing move effect entry")
local copy={phase=bankFx.phase};for k,v in pairs(entry) do copy[k]=v end
copy.rawPath=rawWazaPath
local localBank=entry.gptOffset and bankFx.gptBanks and bankFx.gptBanks[entry.gptOffset] or nil






local directEmbeddedParticle=false
if copy.kind=="particle" then copy.resourceKind="particle-bank" end





if not directEmbeddedParticle and not localBank and entry.kind=="particle" and (tonumber(entry.state) or 0)~=0 then
local wantedState=tonumber(entry.state)
for i=#timeline.entries,1,-1 do
local prior=timeline.entries[i]
if prior and tonumber(prior.identifier)==wantedState and prior.kind=="particle" then
localBank=tonumber(prior.sourceBank) or nil
copy.resolvedGPTOffset=prior.gptOffset or prior.resolvedGPTOffset
copy.sharedParticleBank=localBank~=nil
copy.sharedFromIdentifier=wantedState
break
end
end
end
if not directEmbeddedParticle and not localBank and entry.kind=="particle" and (entry.selector~=nil or entry.rootRef~=nil) then
local wanted=tonumber(entry.selector~=nil and entry.selector or entry.rootRef)
local matchedOffset



for _,program in ipairs(bankFx.programs or {}) do
if tonumber(program.scriptId)==wanted or tonumber(program.bankIndex)==wanted then
localBank=tonumber(program.bank) or nil
matchedOffset=program.gptOffset
break
end
end
if localBank then copy.resolvedGPTOffset=matchedOffset;copy.selectorResolvedFallback=true end
end
if localBank then
copy.sourceBank=localBank
copy.bank=globalBank(localBank)
end
if copy.kind=="model" then
local parts,seenParts={},{}
for _,linked in ipairs(bankFx.waza.entries or {}) do
if (tonumber(linked.flags) or 0)%2==1 and tonumber(linked.linkedEntryKey)==tonumber(entry.identifier) then
local part=tonumber(linked.partIndex)
if part and part>=0 and part<4096 and part==math.floor(part) and not seenParts[part] then
parts[#parts+1]=part;seenParts[part]=true
end
end
end
table.sort(parts)
local asset,assetErr=compileWazaModel(bankFx.blob,entry,key,bankFx.phase,{partIndices=parts})
if asset then
copy.modelAsset=asset;meta.wazaModels=meta.wazaModels+1
else
copy.modelError=tostring(assetErr or "Waza model decode unavailable")
meta.wazaModelErrors[#meta.wazaModelErrors+1]={phase=bankFx.phase,identifier=copy.identifier,error=copy.modelError}
end
elseif copy.kind=="particle" then


elseif copy.kind=="type4" then
meta.wazaEffects=meta.wazaEffects+1
copy.effectRuntimeReady=copy.effectSupported==true
copy.effectAssets={}
for ai,artifact in ipairs(copy.effectArtifacts or {}) do
local a={};for k,v in pairs(artifact) do a[k]=v end
local off,size=tonumber(a.offset),tonumber(a.size)
if off and size and size>0 and off>=0 and off+size<=#bankFx.blob then
local rawPath=("cache/movefx/%s/effects/%s_%03d_%02d_%s.bin"):format(key,bankFx.phase,tonumber(copy.identifier) or tonumber(copy.index) or 0,ai,tostring(a.kind or "raw"))
local okWrite,why=write(rawPath,bankFx.blob:sub(off+1,off+size))
if okWrite then
a.path=rawPath;meta.wazaEffectArtifacts=meta.wazaEffectArtifacts+1
if a.kind=="texture" then
local sourceBytes=bankFx.blob:sub(off+1,off+size)
local tex,texErr=cacheGSTextureArtifact(sourceBytes,key,bankFx.phase,tonumber(copy.identifier) or tonumber(copy.index) or 0,ai)
if tex then
a.texture=tex;copy.effectTextureAsset=copy.effectTextureAsset or tex
else
a.textureError=tostring(texErr or "serialized GStexture decode unavailable")
copy.effectRuntimeReady=false
meta.wazaEffectErrors[#meta.wazaEffectErrors+1]={phase=bankFx.phase,identifier=copy.identifier,family=copy.effectType,error=a.textureError}
end
end
else
a.error=tostring(why);copy.effectRuntimeReady=false
meta.wazaEffectErrors[#meta.wazaEffectErrors+1]={phase=bankFx.phase,identifier=copy.identifier,family=copy.effectType,error=a.error}
end
else
a.error="type-4 artifact source range invalid";copy.effectRuntimeReady=false
meta.wazaEffectErrors[#meta.wazaEffectErrors+1]={phase=bankFx.phase,identifier=copy.identifier,family=copy.effectType,error=a.error}
end
if a.kind=="model" then
copy.effectRequiresModel=true
local synthetic={identifier=50000+(tonumber(copy.identifier) or tonumber(copy.index) or 0)*16+ai,index=copy.index,dataOffset=a.offset,dataSize=a.size,embeddedSize=a.size}
local asset,assetErr=compileWazaModel(bankFx.blob,synthetic,key,bankFx.phase)
if asset then a.modelAsset=asset;copy.effectModelAsset=copy.effectModelAsset or asset;meta.wazaEffectModels=meta.wazaEffectModels+1
else
a.modelError=tostring(assetErr or "type-4 embedded model decode unavailable")
copy.effectRuntimeReady=false
meta.wazaEffectErrors[#meta.wazaEffectErrors+1]={phase=bankFx.phase,identifier=copy.identifier,family=copy.effectType,error=a.modelError}
end
end
copy.effectAssets[#copy.effectAssets+1]=a
end
local required=copy.effectRequiredArtifact or (copy.effect and copy.effect.requiredArtifact)
if required=="texture" and not (type(copy.effectTextureAsset)=="table" and copy.effectTextureAsset.path) then
copy.effectRuntimeReady=false
meta.wazaEffectErrors[#meta.wazaEffectErrors+1]={phase=bankFx.phase,identifier=copy.identifier,
family=copy.effectType,error="required serialized GS texture unavailable"}
elseif required=="model" then
copy.effectRequiresModel=true
if not (type(copy.effectModelAsset)=="table" and copy.effectModelAsset.cache) then
copy.effectRuntimeReady=false
meta.wazaEffectErrors[#meta.wazaEffectErrors+1]={phase=bankFx.phase,identifier=copy.identifier,
family=copy.effectType,error="required embedded HSD model unavailable"}
end
end
elseif copy.kind=="sound" then



meta.sounds[#meta.sounds+1]={phase=bankFx.phase,identifier=copy.identifier,
soundId=copy.soundId,soundMode=copy.soundMode,soundParam=copy.soundParam,
rawPath=rawWazaPath,sourceType=5}
end
timeline.entries[#timeline.entries+1]=copy
end
meta.wazaPhases[#meta.wazaPhases+1]=timeline
phaseMeta.wazaEntries=#timeline.entries
phaseMeta.wazaComplete=timeline.complete==true
phaseMeta.wazaDurationFrames=timeline.durationFrames
elseif bankFx.wazaError then
phaseMeta.wazaError=bankFx.wazaError
end

for _,sound in ipairs(bankFx.sounds or {}) do
local copy={phase=bankFx.phase};for k,v in pairs(sound) do copy[k]=v end
meta.sounds[#meta.sounds+1]=copy
end
for _,program in ipairs(bankFx.programs or {}) do
local copy={phase=bankFx.phase}
for k,v in pairs(program) do copy[k]=v end
copy.sourceBank=tonumber(program.bank) or 1
copy.bank=globalBank(copy.sourceBank)
if copy.root==true then phaseMeta.roots=phaseMeta.roots+1 end
meta.generatorPrograms[#meta.generatorPrograms+1]=copy
end
for localBank,lookup in pairs(bankFx.lookupTables or {}) do
local gb=globalBank(localBank)
meta.lookupTables[gb]=meta.lookupTables[gb] or {}
for tableIndex,scriptId in pairs(lookup or {}) do
meta.lookupTables[gb][tableIndex]=scriptId
end
end
for i,spec in ipairs(bankFx.raw) do
local texPath=("cache/movefx/%s/%s_%02d.rgba"):format(key,bankFx.phase,i)




local runtimeBytes=spec.gray and intensityAlpha(spec.bytes) or spec.bytes
local okWrite=write(texPath,runtimeBytes)
if okWrite then
local traits=textureTraits(runtimeBytes,spec.w,spec.h)
local sourceBank=tonumber(spec.bank) or 1
meta.textures[#meta.textures+1]={path=texPath,w=spec.w,h=spec.h,fmt=spec.fmt,gray=spec.gray,
bank=globalBank(sourceBank),sourceBank=sourceBank,container=spec.container,texture=spec.texture,phase=bankFx.phase,
coverage=traits.coverage,meanAlpha=traits.meanAlpha,contentW=traits.contentW,contentH=traits.contentH,
contentScale=traits.contentScale}
phaseMeta.count=phaseMeta.count+1
end
end
phaseMeta.duration=math.max(.12,math.min(2.4,(tonumber(phaseMeta.maxLifetime) or 0)/60))
if phaseMeta.count>0 then meta.phases[#meta.phases+1]=phaseMeta end
end
local latest=tonumber(meta.maxLifetime) or 0
for _,program in ipairs(meta.generatorPrograms) do
local start=program.sequence and tonumber(program.sequence.start) or 0
if start and start>0 and start<3600 then latest=math.max(latest,start+(tonumber(program.maxLife) or tonumber(program.lifetime) or 0)) end
end
local wazaLatest=0
for _,phase in ipairs(meta.wazaPhases or {}) do
wazaLatest=math.max(wazaLatest,tonumber(phase.durationFrames) or 0)
end
latest=math.max(latest,wazaLatest)
meta.duration=math.max(.32,math.min(8.0,latest/60))
meta.wazaReady=#(meta.wazaPhases or {})>0
if id then ensureSpecRetailModelMove(meta,id) end
local rootCount=0;for _,g in ipairs(meta.generatorPrograms) do if g.root==true then rootCount=rootCount+1 end end
meta.rootGenerators=rootCount
meta.attackReady=cachedRoleReady(meta,"attack")
meta.damageReady=cachedRoleReady(meta,"damage")
meta.fullVisualReady=meta.attackReady and (meta.damageReady or (function()
for _,ph in ipairs(meta.wazaPhases or {}) do local n=tostring(ph.name or ""):lower();if n=="damage" or n=="status" then return false end end
return true
end)())
meta.coverage={phases=#(meta.wazaPhases or {}),entries=0,kinds={},unsupported={}}
for _,ph in ipairs(meta.wazaPhases or {}) do
if ph.complete~=true or ph.parseError then
meta.coverage.unsupported[#meta.coverage.unsupported+1]={phase=ph.name,index="phase",kind="timeline",
reason=tostring(ph.parseError or "Waza phase parse incomplete")}
end
for _,e in ipairs(ph.entries or {}) do
meta.coverage.entries=meta.coverage.entries+1;meta.coverage.kinds[e.kind]=(meta.coverage.kinds[e.kind] or 0)+1
local ok,why=cachedEntryReady(meta,e);if not ok then meta.coverage.unsupported[#meta.coverage.unsupported+1]={phase=ph.name,index=e.index,kind=e.kind,reason=why} end
end
end
for moveKey,rows in pairs(meta.retailModelOverrideBlockersByMove or {}) do
for modelId,why in pairs(rows or {}) do
meta.coverage.unsupported[#meta.coverage.unsupported+1]={phase="attack-override",index=modelId,moveId=moveKey,
kind="retail-model-selector",reason=why}
end
end
if #meta.textures==0 then meta.duration=.6;meta.note=errors or "WZX has no decoded GPT1 texture bank" end



local path=metadataPath(key)
local saved,saveWhy=write(path,"return "..serialize(meta).."\n")
if not saved then return nil,saveWhy end
if not isolated then M.memory[key]=meta end
return meta
end






M.lookupPlans={}
function M.lookupPlan(moveId,move)
local id=tonumber(moveId) or (type(move)=='table' and (tonumber(move.index) or tonumber(move.colosseumMoveId)))
local name=type(move)=='table' and (move.name or move.id or move.move) or nil
local rows=id and id>=1 and id<=354 and id%1==0 and M.lookupPlans[id]
local plan=rows and rows.names[name or false]
local sourceRow=M.sourceMoveRows and M.sourceMoveRows[id]
local indexRow=not M.sourceMoveRows and type(M.indexMemory)=='table' and M.indexMemory.moves and M.indexMemory.moves[id]
if plan and plan.sourceRows==M.sourceMoveRows and plan.sourceRow==sourceRow
and plan.primaryStem==(sourceRow and sourceRow.primaryStem)
and plan.primaryAnimationId==(sourceRow and sourceRow.primaryAnimationId)
and plan.secondaryAnimationId==(sourceRow and sourceRow.secondaryAnimationId)
and plan.index==M.indexMemory and plan.indexRow==indexRow and plan.indexStem==(indexRow and indexRow.stem) then return plan end
local p,resolved=profile(moveId,move);if not p then return nil end
local candidates=sourceStemCandidates(p,resolved,move)
local first=candidates[1] or p.stem
candidates=includeIndexedStem(candidates,resolved)
indexRow=not M.sourceMoveRows and type(M.indexMemory)=='table' and M.indexMemory.moves and M.indexMemory.moves[resolved]
plan={id=resolved,candidates=candidates,first=first,sourceRows=M.sourceMoveRows,sourceRow=sourceRow,
primaryStem=sourceRow and sourceRow.primaryStem,primaryAnimationId=sourceRow and sourceRow.primaryAnimationId,
secondaryAnimationId=sourceRow and sourceRow.secondaryAnimationId,index=M.indexMemory,indexRow=indexRow,indexStem=indexRow and indexRow.stem}
if id and id>=1 and id<=354 and id%1==0 then
if not rows or rows.count>=8 then rows={count=0,names={}};M.lookupPlans[id]=rows end
if not rows.names[name or false] then rows.count=rows.count+1 end
rows.names[name or false]=plan
end
return plan
end
function M.peek(moveId,move)
local plan=M.lookupPlan(moveId,move);if not plan then return nil,"unmapped move" end
local id=plan.id
local selectorMissing=false
for _,key in ipairs(plan.candidates) do
if M.memory[key]~=nil then
if M.memory[key] then
if specRetailSelectionReady(M.memory[key],id) then refreshEmbeddedCameraCache(M.memory[key],key);return M.memory[key] end
selectorMissing=true
end
else
local cached=cacheReadLua(M.cachePath(key))
if type(cached)=="table" and cached.revision==M.revision and cached.wazaRevision==(Waza and Waza.revision or nil) and cached.stem==key
and not type4RangeStale(cached) then
M.memory[key]=cached
if specRetailSelectionReady(cached,id) then refreshEmbeddedCameraCache(cached,key);return cached end
selectorMissing=true
end
end
end
return nil,selectorMissing and "retail attack selector not prefetched" or "not prefetched"
end

local function slotMoveId(slot)
if type(slot)=="number" or type(slot)=="string" then return slot,nil end
if type(slot)~="table" then return nil,nil end
local def=type(slot.move)=="table" and slot.move or slot
local id=slot.index or slot.moveId or slot.id or (type(slot.move)~="table" and slot.move) or slot.name
return id,def
end

local function resolveMoveDef(battle,id,def)
if type(def)=="table" and (def.name or def.power or def.type or def.category) then return def end
local data=battle and battle.game and battle.game.data
local moves=data and data.moves
if type(moves)=="table" and id~=nil then
if moves[id] then return moves[id] end
local sid=tostring(id)
if moves[sid] then return moves[sid] end
end
return type(def)=="table" and def or nil
end

local function prefetchKey(id,def)
local plan=M.lookupPlan(id,def)
return plan and tostring(plan.first or id or (type(def)=="table" and def.name) or "unknown") or nil
end






function M.runtimeSpecReady(spec)
return not M.runtime or not M.runtime.WazaHandlers or
(M.preparedSpecs and M.preparedSpecs[spec] and M.runtime.WazaHandlers.specPrepared(spec)) or false
end
function M.queuePrefetch(moveId,move,battle,priority)
local def=resolveMoveDef(battle,moveId,move)
local key=prefetchKey(moveId,def)
if not key then return false,"unmapped move" end
if M.prefetchFailures[key] then return false,M.prefetchFailures[key] end
local cached=M.peek(moveId,def)
if type(cached)=="table" and M.runtimeSpecReady(cached) then return true,"cached" end
if M.pendingKeys[key] then
if priority then for i,job in ipairs(M.pending) do
if job.key==key then
job.priority=true
if job~=M.prefetchCurrent then table.remove(M.pending,i);table.insert(M.pending,1,job) end
break
end
end end
return true,"queued"
end
M.prefetchFailures[key]=nil
M.pendingKeys[key]=true
local job={id=moveId,move=def,key=key,priority=priority==true}
if priority then table.insert(M.pending,1,job) else M.pending[#M.pending+1]=job end
M.prefetchStats.queued=M.prefetchStats.queued+1
return true,"queued"
end

function M.queueBattler(battle,battler,priority)
local mon=battler and (battler.mon or battler)
local slots=mon and mon.moves or (battler and battler.moves)
if type(slots)~="table" then return {requested=0,ready=0,queued=0,failed=0} end
local out={requested=0,ready=0,queued=0,failed=0};local seen={}
for _,slot in pairs(slots) do
local id,def=slotMoveId(slot);def=resolveMoveDef(battle,id,def)
local key=prefetchKey(id,def)
if key and not seen[key] then
seen[key]=true;out.requested=out.requested+1
local spec=M.peek(id,def)
if type(spec)=="table" and M.runtimeSpecReady(spec) then out.ready=out.ready+1
else
local ok=M.queuePrefetch(id,def,battle,priority)
if ok then out.queued=out.queued+1 else out.failed=out.failed+1 end
end
end
end
return out
end

function M.faintReturnReady(stem)
stem=norm(stem)
if M.prefetchFailures['faint-return:'..stem] then return true end
local spec=M.faintReturnMemory[stem]
return type(spec)=='table' and M.runtimeSpecReady(spec) or false
end
function M.queueFaintReturn(stem)
stem=norm(stem);if stem=='' then return false,'missing ball stem' end
local key='faint-return:'..stem
if M.prefetchFailures[key] then return false,M.prefetchFailures[key] end
if M.faintReturnReady(stem)then return true,'cached' end
if M.pendingKeys[key]then return true,'queued' end
M.pendingKeys[key]=true
table.insert(M.pending,1,{key=key,stem=stem,kind='faint-return',priority=true})
M.prefetchStats.queued=M.prefetchStats.queued+1
return true,'queued'
end


local function gameParty(game)
if type(game)~="table" then return nil end
if type(game.session)=="table" and type(game.session.party)=="table" then return game.session.party end
local save=game.save
return type(save)=="table" and (save.party or save.pokemon or save.team) or nil
end
function M.queueParty(game,maxMons)
local party=gameParty(game)
if type(party)~="table" then return {requested=0,ready=0,queued=0,failed=0} end
local limit=math.max(1,math.floor(tonumber(maxMons) or 1))
local total={requested=0,ready=0,queued=0,failed=0};local used=0
local battle={game=game}
for _,mon in ipairs(party) do
if used>=limit then break end
if type(mon)=="table" then
used=used+1
local r=M.queueBattler(battle,{mon=mon})
for k,v in pairs(r) do total[k]=(total[k] or 0)+(tonumber(v) or 0) end
end
end
total.mons=used
return total
end






function M.partySignature(game,maxMons)
if not gameParty(game) then
return ("movefx-party-v1|revision=%s|waza=%s|moves="):format(tostring(M.revision),tostring(Waza and Waza.revision or "nil"))
end
local party=gameParty(game)
local limit=math.max(1,math.floor(tonumber(maxMons) or 1))
local keys,seen={},{};local used=0;local battle={game=game}
if type(party)=="table" then
for _,mon in ipairs(party) do
if used>=limit then break end
if type(mon)=="table" then
used=used+1
local slots=mon.moves
if type(slots)=="table" then
for _,slot in pairs(slots) do
local id,def=slotMoveId(slot);def=resolveMoveDef(battle,id,def)
local key=prefetchKey(id,def)
if key and not seen[key] then seen[key]=true;keys[#keys+1]=key end
end
end
end
end
end
table.sort(keys)
return ("movefx-party-v1|revision=%s|waza=%s|mons=%d|moves=%s")
:format(tostring(M.revision),tostring(Waza and Waza.revision or "nil"),used,table.concat(keys,","))
end





function M.partySpecs(game,maxMons)
local out,seen={},{}
local party=gameParty(game)
if type(party)~="table" then return out end
local battle={game=game};local used=0;local limit=math.max(1,math.floor(tonumber(maxMons) or 6))
for _,mon in ipairs(party) do
if used>=limit then break end
if type(mon)=="table" then
used=used+1
local slots=mon.moves
if type(slots)=="table" then
for _,slot in pairs(slots) do
local id,def=slotMoveId(slot);def=resolveMoveDef(battle,id,def)
local key=prefetchKey(id,def)
if key and not seen[key] then
local spec=M.peek(id,def)
if type(spec)=="table" then seen[key]=true;out[#out+1]=spec end
end
end
end
end
end
return out
end

function M.queueBattle(battle)
local total={requested=0,ready=0,queued=0,failed=0}
local battlers={battle and battle.player,battle and battle.enemy}
if battle and battle.__cbeGeneration==3 and battle.battlers then
battlers={};for id=0,3 do
local b=battle.battlers[id]
if b and not b.absent then battlers[#battlers+1]=b end
end
end
for _,battler in ipairs(battlers) do
local r=M.queueBattler(battle,battler,true)
for k,v in pairs(r) do total[k]=(total[k] or 0)+(tonumber(v) or 0) end
end
return total
end



M.prefetchBattler=M.queueBattler
M.prefetchBattle=M.queueBattle






local androidRuntimeCached=nil
local function androidRuntime()
if androidRuntimeCached~=nil then return androidRuntimeCached end
if love and love.system and type(love.system.getOS)=="function" then
local ok,v=pcall(love.system.getOS)
if ok then
androidRuntimeCached=tostring(v or "")=="Android"
return androidRuntimeCached
end
end
return false
end
function M.battlerReady(battle,battler)
local mon=battler and (battler.mon or battler)
for _,slot in pairs(mon and mon.moves or {}) do
local id,def=slotMoveId(slot);def=resolveMoveDef(battle,id,def)
local key=prefetchKey(id,def)
if key and not M.prefetchFailures[key] then
local spec=M.peek(id,def)
if not spec or not M.runtimeSpecReady(spec) then return false end
end
end
return true
end
function M.suspendPrefetch()
if M.prefetchTask and M.runtime and M.runtime.WorkBudget then M.runtime.WorkBudget.cancel(M.prefetchTask) end
M.prefetchTask=nil;M.prefetchCurrent=nil
end
function M.pumpPrefetch(maxItems,milliseconds,criticalOnly)
maxItems=math.max(0,math.floor(tonumber(maxItems) or 1))
local out={processed=0,ready=0,failed=0,failedJobs={},pending=#M.pending}
local W=M.runtime and M.runtime.WorkBudget
if criticalOnly and M.prefetchCurrent and not M.prefetchCurrent.priority and W then
W.cancel(M.prefetchTask);M.prefetchTask=nil;M.prefetchCurrent=nil
end
while out.processed<maxItems and (#M.pending>0 or M.prefetchTask) do
local job=M.prefetchCurrent or M.pending[1]
if criticalOnly and not M.prefetchCurrent then
job=nil;for _,row in ipairs(M.pending) do if row.priority then job=row;break end end
if not job then break end
end
local ok,spec,err
if W then
if not M.prefetchTask then
M.prefetchCurrent=job
M.prefetchTask=W.new(function()
local source,why
if job.kind=='faint-return' then
source,why=M.peekFaintReturn(job.stem)
if not source then source,why=M.acquireFaintReturn(job.stem) end
else source,why=M.acquire(job.id,job.move) end
if not source then return nil,why end
if M.runtime.WazaHandlers then M.runtime.WazaHandlers.prewarmSpec(source) end
if M.runtime.CurrentSpriteModels then M.runtime.CurrentSpriteModels.prewarmMoveFxSpec(source) end
if M.runtime.WazaAudioRuntime then M.runtime.WazaAudioRuntime.prewarmSpec(source,checkpoint) end
M.preparedSpecs=M.preparedSpecs or setmetatable({},{__mode='k'})
M.preparedSpecs[source]=true
return source
end,"Preparing move effects "..job.key)
end
local state
ok,state,spec,err=W.resume(M.prefetchTask,milliseconds or 3)
if ok and state~="done" then break end
if not ok then err=state end
M.prefetchTask=nil;M.prefetchCurrent=nil
elseif job.kind=='faint-return' then ok,spec,err=pcall(M.acquireFaintReturn,job.stem)
else ok,spec,err=pcall(M.acquire,job.id,job.move) end
for i,row in ipairs(M.pending) do if row==job then table.remove(M.pending,i);break end end
M.pendingKeys[job.key]=nil;out.processed=out.processed+1
if ok and type(spec)=="table" then
M.prefetchFailures[job.key]=nil
out.ready=out.ready+1;M.prefetchStats.completed=M.prefetchStats.completed+1
else
out.failed=out.failed+1;M.prefetchStats.failed=M.prefetchStats.failed+1
local why=tostring(ok and err or spec or "source Waza acquisition failed")
M.prefetchFailures[job.key]=why
out.failedJobs[#out.failedJobs+1]={move=job.id,stem=job.key,reason=why}
end
if W then break end
if androidRuntime() and type(collectgarbage)=="function" then



pcall(collectgarbage,"step",48)
end
end
out.pending=#M.pending
return out
end

function M.clear()
if M.prefetchTask and M.runtime and M.runtime.WorkBudget then M.runtime.WorkBudget.cancel(M.prefetchTask) end
M.prefetchTask=nil;M.prefetchCurrent=nil
M.preparedSpecs=nil
M.memory={};M.faintReturnMemory={};M.negative={};M.pending={};M.pendingKeys={};M.prefetchFailures={};M.prefetchStats={queued=0,completed=0,failed=0};return true
end
function M.status() return {revision=M.revision,wazaRevision=Waza and Waza.revision or nil,cached=M.memory,negative=M.negative,sourceAliases=SOURCE_STEM_ALIASES_COUNT,prefetch=true,peek=true,pending=#M.pending,prefetchFailures=M.prefetchFailures,prefetchStats=M.prefetchStats,
retailModelOverrideSource=M.retailModelOverridesMeta,
prefetchPolicy="party WZX cache promotion is paced by the stable-overworld resident scheduler; current battle banks complete before CBE world presentation; no source extraction on visible move/damage frames"} end
M._test={extractSourceMoveRows=extractSourceMoveRows,sourceStemCandidates=sourceStemCandidates,
dolReadVirtual=dolReadVirtual,extractRetailModelOverrides=extractRetailModelOverrides,retailModelPhaseMap=retailModelPhaseMap,
ensureSpecRetailModelMove=ensureSpecRetailModelMove,fsysResourceGroup=fsysResourceGroup,migrateCachedSpec34=migrateCachedSpec34,
directEmbeddedType3=directEmbeddedType3,runtimeRoot=runtimeRoot,runtimeMetaPath=runtimeMetaPath,
packPackedRows=packPackedRows,prebuildRuntimeMesh=prebuildRuntimeMesh,androidRuntime=androidRuntime}
M.releaseStems={"monsterball","superball","hyperball","masterball","safariball","netball","diveball","nestball","repeatball","timerball","gorgeousball","puremiyaball"}
M.faintReturnMemory={}
function M.faintReturnPath(stem)
stem=norm(stem)
return "cache/movefx/"..stem.."/downin_effect.lua"
end
M.faintReturnMarkerPath="cache/movefx/faint_returns_v2.complete"
local function faintReturnMarker()
return ("cbe-faint-returns=2\nextractor=%d\nwaza=%s\nstems=%s\n")
:format(M.revision,tostring(Waza and Waza.revision or "none"),table.concat(M.releaseStems,","))
end
M.faintReturnMarkerValue=faintReturnMarker()
local function validFaintReturnSpec(spec,stem)
if type(spec)~="table" or spec.revision~=M.revision or spec.wazaRevision~=(Waza and Waza.revision or nil)
or norm(spec.stem)~=norm(stem) or tonumber(spec.sourceSelector)~=0x10
or spec.sourceItemBallField~="downinWzxDataId" or tonumber(spec.sourceResourceGroup)~=4 then return false end
for _,phase in ipairs(spec.wazaPhases or {}) do
if phase.name=="downin" and phase.complete==true and tonumber(phase.sequenceKind)==10 and #(phase.entries or {})>0 then return true end
end
return false
end
function M.peekFaintReturn(stem)
stem=norm(stem);if stem=="" then return nil,"missing ball stem" end
local cached=M.faintReturnMemory[stem]
if cached~=nil then return cached or nil,cached and nil or "faint-return cache unavailable" end
cached=cacheReadLua(M.faintReturnPath(stem))
if validFaintReturnSpec(cached,stem) then M.faintReturnMemory[stem]=cached;return cached end
M.faintReturnMemory[stem]=false
return nil,"source downin WZX cache not prepared"
end
function M.acquireFaintReturn(stem)
stem=norm(stem);if stem=="" then return nil,"missing ball stem" end
local spec,why=M.acquire(nil,{name=stem},{"downin"},{isolated=true,metadataPath=M.faintReturnPath(stem),
sourceSelector=0x10,sourceItemBallField="downinWzxDataId",sourceResourceGroup=4})
if not validFaintReturnSpec(spec,stem) then return nil,why or "incomplete source downin WZX" end
M.faintReturnMemory[stem]=spec
return spec
end
function M.faintReturnBanksReady(mod)
if not (mod and mod.cache and type(mod.cache.info)=="function" and type(mod.cache.read)=="function") then return false end
local okMarker,marker=pcall(mod.cache.read,mod.cache,M.faintReturnMarkerPath)



if not okMarker or marker~=M.faintReturnMarkerValue then return false end
for _,stem in ipairs(M.releaseStems) do
local ok,info=pcall(mod.cache.info,mod.cache,M.faintReturnPath(stem))
if not ok or type(info)~="table" then return false end
end
return true
end
M.releaseMarkerPath="cache/movefx/release_banks_v1.complete"
local function releaseMarker()
return ("cbe-release-banks=1\nsource=GC6E01\nextractor=%d\nwaza=%s\nstems=%s\n")
:format(M.releaseRevision or M.revision,tostring(Waza and Waza.revision or "none"),table.concat(M.releaseStems,","))
end
M.releaseMarkerValue=releaseMarker()
function M.releaseBanksReady(mod)
if not (mod and mod.cache and type(mod.cache.read)=="function" and type(mod.cache.info)=="function") then return false end
local ok,raw=pcall(mod.cache.read,mod.cache,M.releaseMarkerPath)
if not ok or raw~=releaseMarker() then return false end


for _,stem in ipairs(M.releaseStems) do
local good,info=pcall(mod.cache.info,mod.cache,M.cachePath(stem))
if not good or type(info)~="table" then return false end
end
return true
end
function M.ensureReleaseBanks(mod,openDisc,progress,generated)
local releaseReady=M.releaseBanksReady(mod)
local faintReady=M.faintReturnBanksReady(mod)
if releaseReady and faintReady then return true,"cached" end
local oldMod,oldOpen,oldGenerated,oldSeen,oldPreserve=M.mod,M.openDisc,M.buildGenerated,M.buildGeneratedSeen,M.preserveExistingWrites
M.mod=mod;M.openDisc=openDisc;M.buildGenerated=generated;M.buildGeneratedSeen={};M.preserveExistingWrites=true
local ok,result=pcall(function()
for i,stem in ipairs(M.releaseStems)do
if not releaseReady then
local spec=M.peek(nil,{name=stem})
if not spec then
if progress then progress("BUILDING SOURCE BALL RELEASES",i,#M.releaseStems) end
local why;spec,why=M.acquire(nil,{name=stem},{"open"});assert(spec,why)
end
local found=false;for _,phase in ipairs(spec.wazaPhases or {})do if phase.name=="open" then found=true end end
assert(found,"Missing ball_open chapter: "..stem)
end
local down=M.peekFaintReturn(stem)
if not down then
if progress then progress("BUILDING SOURCE FAINT RETURNS",i,#M.releaseStems) end
local why;down,why=M.acquireFaintReturn(stem);assert(down,why)
end


assert(validFaintReturnSpec(cacheReadLua(M.faintReturnPath(stem)),stem),
"Source downin WZX sidecar was not committed: "..stem)
end
if not releaseReady then local wrote,why=write(M.releaseMarkerPath,releaseMarker());assert(wrote,why) end
if not faintReady then local wrote,why=write(M.faintReturnMarkerPath,M.faintReturnMarkerValue);assert(wrote,why) end
return true
end)
M.mod=oldMod;M.openDisc=oldOpen;M.buildGenerated=oldGenerated;M.buildGeneratedSeen=oldSeen;M.preserveExistingWrites=oldPreserve
if not ok then error(result) end;return result
end
return M
