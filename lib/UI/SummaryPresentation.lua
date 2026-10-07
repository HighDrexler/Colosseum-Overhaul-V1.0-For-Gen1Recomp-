
local M={}
function M.bind(ctx)
local love={graphics=ctx.graphics,timer=ctx.timer}
local GoldCompat=setmetatable({},{__index=ctx.compat})
local safeFullCanvas,roundedRect,finalText=ctx.finalCanvas,ctx.roundedRect,ctx.finalText
local owStatus,hpColor,Growth,DexUI=ctx.status,ctx.hpColor,ctx.growth,ctx.dexUI
local partyExpRatio=ctx.expRatio
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
function GoldCompat.drawColosseumSummaryTabs(page,ox,oy,sc)
local G=love.graphics
page=ctx.activeTab or page
local labels=ctx.tabs or {"STATUS","MOVES","PROFILE"}
for i,label in ipairs(labels) do
local id=type(label)=="table" and label.id or i
label=type(label)=="table" and label.label or label
local x=(ctx.tabsStart or 82)+(i-1)*24
G.push("all"); G.translate(ox,oy); G.scale(sc,sc)
if id==page then
G.setColor(0.055,0.31,0.28,0.98)
G.polygon("fill",x,7,x+21,7,x+23,10.5,x+21,15,x,15,x-2,11)
G.setColor(0.26,1.00,0.48,1)
G.rectangle("fill",x+2,14,17,1)
else
G.setColor(0.055,0.13,0.14,0.92)
G.polygon("fill",x,8,x+21,8,x+22,11.5,x+20,14,x,14,x-1,11)
end
G.pop()
finalText(label,x,10,1.62,
id==page and {0.92,1.00,0.94,1} or {0.54,0.70,0.68,1},
ox,oy,sc,"center",21)
end
end

function GoldCompat.drawColosseumStatusPage(game,summary,mon,def,gen2)
local G=love.graphics
local ox,oy,sc=safeFullCanvas()
local white={0.98,0.99,0.96,1}
local lime={0.58,0.94,0.20,1}
local gold={1.00,0.80,0.25,1}
local muted={0.66,0.78,0.75,1}
local glass={0.018,0.040,0.044,0.80}
local rim={0.35,0.55,0.54,0.96}
local stats=mon.stats or {}
local hpMax=tonumber(stats.hp or mon.maxHp) or 0
local rows={
{"HP",tonumber(mon.hp) or 0,hpMax},
{"ATTACK",tonumber(stats.attack) or 0},
{"DEFENSE",tonumber(stats.defense) or 0},
{"SP. ATK",tonumber(stats.specialAttack or stats.special) or 0},
{"SP. DEF",tonumber(stats.specialDefense or stats.special) or 0},
{"SPEED",tonumber(stats.speed) or 0},
}
local maxStat=1
for i=2,#rows do maxStat=math.max(maxStat,rows[i][2]) end

G.push("all"); G.translate(ox,oy); G.scale(sc,sc)

G.setColor(glass); roundedRect("fill",3,3,154,128,5)
G.setColor(rim); roundedRect("line",3,3,154,128,5)
G.setColor(0.015,0.030,0.033,0.86); roundedRect("fill",6,6,148,12,4)
G.setColor(0.10,0.12,0.12,0.86); roundedRect("fill",7,22,55,70,4)
G.setColor(rim); roundedRect("line",7,22,55,70,4)
G.setColor(0.12,0.14,0.14,0.78); roundedRect("fill",10,25,49,48,3)
G.setColor(0.015,0.030,0.033,0.84); roundedRect("fill",65,22,89,70,4)
G.setColor(rim); roundedRect("line",65,22,89,70,4)
G.setColor(0.015,0.030,0.033,0.84); roundedRect("fill",7,95,147,32,4)
G.setColor(rim); roundedRect("line",7,95,147,32,4)

for i,row in ipairs(rows) do
local yy=27+(i-1)*10
local ratio=i==1 and ((hpMax>0) and clamp(row[2]/hpMax,0,1) or 0)
or clamp(row[2]/maxStat,0,1)
G.setColor(0.10,0.13,0.13,1); roundedRect("fill",94,yy+4,46,3,1.5)
local rr,gg,bb
if i==1 then rr,gg,bb=hpColor(ratio)
else rr,gg,bb=0.64,0.82,0.18 end
G.setColor(rr,gg,bb,1); roundedRect("fill",95,yy+5,44*ratio,1.5,0.8)
end
G.pop()

finalText("POKéMON INFO",9,9,3.15,white,ox,oy,sc)
GoldCompat.drawColosseumSummaryTabs(1,ox,oy,sc)

G.push("all"); G.origin()
pcall(GoldCompat.drawStatsInformationPortrait,game,mon,
ox+12*sc,oy+27*sc,45*sc,43*sc)
G.pop()
local name=tostring(mon.nickname or mon.name or def.name or mon.species or "POKéMON")
finalText(name,11,76,3.0,white,ox,oy,sc,"left",35)
finalText("Lv"..tostring(mon.level or "?"),45,76,2.4,gold,ox,oy,sc,"right",13)
local status=owStatus(mon) or tostring(mon.status or "OK")
finalText(status,11,84,2.1,status=="OK" and lime or {1,0.42,0.30,1},ox,oy,sc)

for i,row in ipairs(rows) do
local yy=27+(i-1)*10
finalText(row[1],69,yy,2.35,i==1 and {1,0.28,0.19,1} or gold,
ox,oy,sc,"left",23)
local value=i==1 and (tostring(row[2]).." / "..tostring(row[3]))
or tostring(row[2])
finalText(value,ctx.statValueX or 140,yy,2.5,white,ox,oy,sc,"right",ctx.statValueWidth or 11)
end

local typeNames={}
for _,id in ipairs(def.types or {}) do
typeNames[#typeNames+1]=GoldCompat.normalizeTypeLabel(id,"--")
end
local typeLabel=#typeNames>0 and table.concat(typeNames," / ") or "--"
local itemId=mon.item
local items=summary.items or (game and game.data and game.data.items) or {}
local item=items[itemId]
local exp=tonumber(mon.experience or mon.exp) or 0
local nextExp=0
if gen2 then nextExp=summary.expToNext and summary:expToNext() or 0
elseif mon.level and mon.level<100 then
local ok,value=pcall(Growth.expForLevel,def.growthRate,mon.level+1,
game.data and game.data.growth_rates)
if ok then nextExp=math.max(0,(tonumber(value) or exp)-exp) end
end
finalText("EXP. POINTS",11,99,1.9,muted,ox,oy,sc)
finalText(tostring(exp),11,105,2.45,white,ox,oy,sc,"left",33)
finalText("NEXT LV.",47,99,1.9,muted,ox,oy,sc)
finalText(tostring(nextExp),47,105,2.45,white,ox,oy,sc,"left",28)
finalText("TYPE",79,99,1.9,muted,ox,oy,sc)
finalText(typeLabel,79,105,2.2,white,ox,oy,sc,"left",30)
finalText("ABILITY",112,99,1.9,muted,ox,oy,sc)
finalText(GoldCompat.summaryAbilityName(game,mon,def),112,105,2.05,white,
ox,oy,sc,"left",38)
finalText("HELD  "..tostring((item and item.name) or itemId or "NONE"),
11,116,2.05,muted,ox,oy,sc,"left",65)
local ot=gen2 and summary.otName and summary:otName()
or mon.otName or mon.originalTrainer or "--"
local id=gen2 and summary.otId and summary:otId()
or mon.otId or mon.trainerId or 0
finalText("OT  "..tostring(ot).."   ID "..("%05d"):format(tonumber(id) or 0),
79,116,1.95,muted,ox,oy,sc,"left",70)
finalText("←/→ PAGE   ↑/↓ POKéMON",9,134,1.9,white,ox,oy,sc)
finalText("B: BACK",133,134,1.9,muted,ox,oy,sc,"right",18)
if ctx.afterStatus then ctx.afterStatus(summary,ox,oy,sc) end
end


function GoldCompat.drawColosseumEggSummary(summary)



if GoldCompat.__stadiumUiActors and GoldCompat.__stadiumUiActors.summary
and type(GoldCompat.releaseStadiumUiActor)=="function" then
GoldCompat.releaseStadiumUiActor("summary")
end

local G=love.graphics
local ox,oy,sc=safeFullCanvas()
local white={0.97,0.99,0.96,1}
local muted={0.62,0.78,0.74,1}
local lime={0.48,1.00,0.63,1}
local gold={1.00,0.80,0.27,1}
local rim={0.27,0.55,0.52,0.96}
local glass={0.010,0.035,0.038,0.91}
local now=(love.timer and love.timer.getTime and love.timer.getTime()) or 0
local bob=math.sin(now*1.75)*1.0
local glow=0.5+0.5*math.sin(now*1.35)
local cycles=summary and summary.mon and tonumber(summary.mon.eggCycles)
local incubation="INCUBATING"
local status="UNHATCHED"
if cycles then
if cycles<=5 then incubation,status="MOVEMENT DETECTED","HATCHING VERY SOON"
elseif cycles<=10 then incubation,status="VERY ACTIVE","GETTING CLOSE"
elseif cycles<=40 then incubation,status="DEVELOPING","NEEDS MORE TIME"
else incubation,status="EARLY INCUBATION","A LONG WAY TO GO" end
end

local function eggPolygon(cx,cy,rx,ry)
local pts={}
local steps=40
for i=0,steps-1 do
local t=(i/steps)*math.pi*2
local sy=math.sin(t)


local width=0.90+0.13*sy
pts[#pts+1]=cx+math.cos(t)*rx*width
pts[#pts+1]=cy+sy*ry
end
return pts
end

G.push("all")
G.translate(ox,oy); G.scale(sc,sc)
G.setColor(0.004,0.018,0.020,0.34); G.rectangle("fill",0,0,160,144)
G.setColor(glass); roundedRect("fill",3,3,154,128,5)
G.setColor(rim); roundedRect("line",3,3,154,128,5)
G.setColor(0.012,0.032,0.035,0.94); roundedRect("fill",6,6,148,12,4)


G.setColor(0.025,0.075,0.078,0.92); roundedRect("fill",7,22,61,99,5)
G.setColor(rim); roundedRect("line",7,22,61,99,5)
G.setColor(0.020,0.045,0.048,0.96); roundedRect("fill",11,27,53,70,4)
G.setColor(0.11,0.32,0.31,0.72); roundedRect("line",11,27,53,70,4)

G.setColor(0.09,0.24,0.23,0.38)
for gx=16,60,8 do G.line(gx,31,gx,92) end
for gy=33,91,8 do G.line(14,gy,61,gy) end
G.setColor(0.20,0.75,0.63,0.16+0.12*glow)
G.ellipse("line",37.5,65+bob,22+glow*2,31+glow*2)
G.ellipse("line",37.5,65+bob,18+glow*1.5,27+glow*1.5)
G.setColor(0,0,0,0.28); G.ellipse("fill",37.5,88,17,4)


local shell=eggPolygon(37.5,62+bob,15.5,24.5)
G.setColor(0.92,0.94,0.88,1)
G.polygon("fill",shell)
G.setColor(0.45,0.69,0.62,0.92)
G.polygon("line",shell)
G.setColor(0.58,0.83,0.68,0.88)
G.ellipse("fill",31.5,55+bob,4.2,3.0)
G.ellipse("fill",42.5,67+bob,4.8,3.4)
G.ellipse("fill",35.0,76+bob,3.2,2.3)
G.setColor(1,1,1,0.54)
G.ellipse("fill",32.2,46+bob,4.3,6.8)


G.setColor(0.012,0.032,0.035,0.94); roundedRect("fill",72,22,82,99,5)
G.setColor(rim); roundedRect("line",72,22,82,99,5)
G.setColor(0.055,0.15,0.15,0.95); roundedRect("fill",77,29,72,16,3)
G.setColor(0.16,0.42,0.38,0.92); roundedRect("line",77,29,72,16,3)
G.setColor(0.028,0.075,0.075,0.92); roundedRect("fill",77,50,72,18,3)
G.setColor(0.16,0.42,0.38,0.80); roundedRect("line",77,50,72,18,3)
G.setColor(0.028,0.075,0.075,0.92); roundedRect("fill",77,73,72,41,3)
G.setColor(0.16,0.42,0.38,0.80); roundedRect("line",77,73,72,41,3)


local scanY=34+((now*13)%56)
G.setColor(0.34,1.00,0.67,0.12+0.16*glow); G.rectangle("fill",13,scanY,49,0.8)


G.setColor(0.008,0.027,0.030,0.97); roundedRect("fill",5,133,150,8,2)
G.setColor(0.18,0.47,0.44,0.88); roundedRect("line",5,133,150,8,2)
G.pop()

finalText("EGG INFORMATION",9,9,3.15,white,ox,oy,sc)
finalText("UNHATCHED EGG",80,32,3.25,white,ox,oy,sc,"left",65)
finalText(incubation,80,39,2.05,lime,ox,oy,sc,"left",63)
finalText("STATUS",80,53,1.8,muted,ox,oy,sc)
finalText(status,80,59,2.05,gold,ox,oy,sc,"left",65)
finalText("CARE",80,76,1.8,muted,ox,oy,sc)
finalText("KEEP THIS EGG WITH",80,83,1.95,white,ox,oy,sc,"left",65)
finalText("YOUR PARTY AS YOU",80,90,1.95,white,ox,oy,sc,"left",65)
finalText("TRAVEL. SOMETHING",80,97,1.95,white,ox,oy,sc,"left",65)
finalText("MAY HATCH FROM IT.",80,104,1.95,white,ox,oy,sc,"left",65)
finalText("SPECIES / TYPE / MOVES / STATS LOCKED UNTIL HATCHING",12,111,1.30,muted,ox,oy,sc,"left",52)
finalText("UNHATCHED POKéMON EGG",9,135,1.55,muted,ox,oy,sc)
finalText("B: BACK",135,135,1.85,white,ox,oy,sc,"right",17)
return true
end

function GoldCompat.drawColosseumSummary(game,summary)
if not (summary and summary.mon) then return end
game=game or summary.game
local mon=summary.mon
local defs=summary.pokemon or (game and game.data and game.data.pokemon) or {}
local def=defs[mon.species]
if not def then return end



if mon.isEgg then
return GoldCompat.drawColosseumEggSummary(summary)
end

local G=love.graphics
local ox,oy,sc=safeFullCanvas()
local page=math.max(1,tonumber(summary.page) or 1)
local gen2=GoldCompat.generation=="gen2" or summary.pokemon~=nil
if summary.__colosseumMoveManager
and GoldCompat.moveManagerPresentationEnabled() then
return GoldCompat.drawGoldMoveManager(summary)
end
local moveManager=gen2 and (summary.moveDetail or summary.moveScreen)
if page==1 and not moveManager then
return GoldCompat.drawColosseumStatusPage(game,summary,mon,def,gen2)
end
local body={0.055,0.105,0.115,0.91}
local steel={0.42,0.63,0.63,1}
local cyan={0.08,0.64,0.95,1}
local white={0.98,0.98,0.94,1}
local gold={1.00,0.82,0.32,1}
local muted={0.70,0.79,0.77,1}

local function panel(x,y,w,h)
G.setColor(0.01,0.02,0.025,0.55)
roundedRect("fill",x+1.5,y+1.5,w,h,2.5)
G.setColor(body)
roundedRect("fill",x,y,w,h,2.5)
G.setColor(steel)
roundedRect("line",x,y,w,h,2.5)
end
local function section(x,y,w,label)
G.push("all")
G.translate(ox,oy)
G.scale(sc,sc)
G.setColor(0.01,0.025,0.035,0.94)
roundedRect("fill",x,y,w,5.5,1.2)
G.setColor(cyan)
roundedRect("fill",x,y,w*0.48,5.5,1.2)
G.pop()
finalText(label,x+2,y+0.5,2.5,white,ox,oy,sc)
end
local function moveDef(entry)
if gen2 then return GoldCompat.summaryMoveDef(summary,entry) end
local id=type(entry)=="table" and (entry.id or entry.move) or entry
return game and game.data and game.data.moves and game.data.moves[id]
end
local function moveName(entry)
if gen2 then return GoldCompat.summaryMoveName(summary,entry) end
local md=moveDef(entry)
local id=type(entry)=="table" and (entry.id or entry.move) or entry
local fallback=GoldCompat.humanizeIdentifier(id)
return tostring((md and md.name) or (fallback~="" and fallback) or "---")
end

G.push("all")
G.translate(ox,oy)
G.scale(sc,sc)
G.setColor(0.01,0.02,0.025,0.28)
G.rectangle("fill",0,0,160,144)
panel(3,3,154,16)
panel(3,22,53,109)
panel(59,22,98,109)
G.setColor(0.01,0.025,0.035,0.94)
roundedRect("fill",5,5,150,12,2)
G.setColor(0.02,0.04,0.05,0.92)
roundedRect("fill",7,25,45,48,2)
G.setColor(0.18,0.38,0.44,0.85)
for gx=10,49,8 do G.line(gx,27,gx,70) end
for gy=29,69,8 do G.line(9,gy,50,gy) end
G.pop()

finalText(moveManager and "MOVE MANAGER" or "POKéMON INFO",
8,7,3.25,white,ox,oy,sc)
GoldCompat.drawColosseumSummaryTabs(page,ox,oy,sc)

G.push("all")
G.origin()
pcall(GoldCompat.drawStatsInformationPortrait,game,mon,
ox+10*sc,oy+28*sc,39*sc,42*sc)
G.pop()

local name=tostring(mon.nickname or mon.name or def.name or mon.species or "POKéMON")
finalText(name,7,76,3.4,white,ox,oy,sc,"left",45)
finalText("Lv"..tostring(mon.level or "?"),39,83,2.5,gold,ox,oy,sc,"right",13)
local itemId=mon.item
local items=summary.items or (game and game.data and game.data.items) or {}
local item=items[itemId]
finalText("ITEM",7,90,2.0,muted,ox,oy,sc)
finalText(tostring((item and item.name) or itemId or "NONE"),7,95,2.45,white,
ox,oy,sc,"left",45)
local status=owStatus(mon) or tostring(mon.status or "OK")
finalText("STATUS  "..status,7,104,2.15,
status=="OK" and {0.40,0.94,0.55,1} or {1.00,0.46,0.34,1},ox,oy,sc)
local dexNo=tonumber(def.dex or def.number or def.id)
finalText(dexNo and ("#%03d"):format(dexNo) or tostring(mon.species or ""),
7,113,2.3,muted,ox,oy,sc,"left",45)
if not gen2 then
local evo=def.evolutions and def.evolutions[1]
local into=evo and defs[evo.species]
finalText("EVOLUTION",7,119,1.75,muted,ox,oy,sc)
finalText(evo and tostring((into and into.name) or evo.species or "SPECIAL")
or "NONE",7,124,1.95,white,ox,oy,sc,"left",45)
end

if ctx.drawBody and ctx.drawBody(game,summary,ox,oy,sc,section) then return end

if moveManager then
section(62,25,92,"CURRENT MOVES")
local moves=mon.moves or {}
for i=1,4 do
local mv=moves[i]
local md=moveDef(mv)
local y=34+(i-1)*18
G.push("all") G.translate(ox,oy) G.scale(sc,sc)
G.setColor(i==(summary.moveIndex or 1) and {0.68,0.12,0.08,0.96}
or {0.015,0.035,0.040,0.88})
roundedRect("fill",63,y,90,15,2)
G.setColor(i==(summary.moveIndex or 1) and {1.0,0.32,0.17,1} or steel)
roundedRect("line",63,y,90,15,2)
G.pop()
finalText(moveName(mv),66,y+2,2.8,white,ox,oy,sc,"left",49)
if mv then
local pp=type(mv)=="table" and (mv.pp or "?") or "?"
local maxpp=type(mv)=="table" and (mv.maxPp or mv.maxPP) or nil
maxpp=maxpp or (md and md.pp) or pp
finalText("PP "..tostring(pp).."/"..tostring(maxpp),116,y+2,2.1,muted,
ox,oy,sc,"right",34)
finalText(GoldCompat.moveTypeName(md),116,y+8,1.9,gold,
ox,oy,sc,"right",34)
end
end
local current=moves[summary.moveIndex or 1]
local currentDef=moveDef(current)
finalText(currentDef and tostring(currentDef.description or "") or "NO MOVE",
64,108,2.0,muted,ox,oy,sc,"left",87)
finalText(summary.swapFrom and "A: PLACE   B: CANCEL" or "A: PICK UP   B: BACK",
7,134,2.15,white,ox,oy,sc)
return
end

local type1,type2
if gen2 then
type1,type2=GoldCompat.summaryTypeNames(summary)
else
local ok,TypeChart=pcall(require,"src.battle.TypeChart")
local names={}
for _,id in ipairs(def.types or {}) do
names[#names+1]=(ok and TypeChart.displayName and TypeChart.displayName(id)) or tostring(id)
end
type1,type2=names[1],names[2]
end
local types=type1 or "N/A"
if type2 and type2~=type1 then types=types.." / "..type2 end

if page==3 then
section(62,25,92,"TRAINER")
local ot=gen2 and summary.otName and summary:otName()
or mon.otName or mon.originalTrainer or "—"
local id=gen2 and summary.otId and summary:otId()
or mon.otId or mon.trainerId or 0
finalText("OT/ "..tostring(ot),65,34,2.65,gold,ox,oy,sc,"left",48)
finalText(("ID No.%05d"):format(tonumber(id) or 0),114,34,2.35,gold,
ox,oy,sc,"right",37)
finalText("TYPE/  "..types,65,42,2.55,white,ox,oy,sc,"left",83)

section(62,52,92,"DETAILS")
local dex=gen2 and (GoldCompat.summaryDexEntry(summary) or {}) or {}
finalText("SPECIES  "..tostring(dex.kind or def.name or mon.species),65,61,2.2,
white,ox,oy,sc,"left",83)
local heightLabel,weightLabel
if gen2 then
local pseudo={dexEntry={gen2Height=dex.height,gen2Weight=dex.weight}}
heightLabel=DexUI.heightLabel(pseudo); weightLabel=DexUI.weightLabel(pseudo)
else
heightLabel=DexUI.heightLabel(def); weightLabel=DexUI.weightLabel(def)
end
finalText("HT  "..heightLabel,65,68,2.15,muted,ox,oy,sc)
finalText("WT  "..weightLabel,111,68,2.15,muted,ox,oy,sc)
local evoLabel="NONE"
if gen2 then
local evos=GoldCompat.summaryEvolutionRows(summary)
local evo=evos[1]
if evo then evoLabel=evo.name.." / "..evo.how end
else
local evo=def.evolutions and def.evolutions[1]
local into=evo and defs[evo.species]
if evo then evoLabel=tostring((into and into.name) or evo.species or "SPECIAL") end
end
finalText("EVOLUTION  "..evoLabel,
65,75,2.05,muted,ox,oy,sc,"left",83)

local machines={}
for _,moveId in ipairs(def.tmhm or {}) do
machines[#machines+1]=moveName(moveId)
end
table.sort(machines)
local perPage=10
local pages=math.max(1,math.ceil(#machines/perPage))
local tmPage=math.max(1,math.min(tonumber(summary.__colosseumTmPage) or 1,pages))
summary.__colosseumTmPage=tmPage
summary.__colosseumTmPages=pages
section(62,85,92,("TM/HM COMPATIBILITY  %d/%d"):format(tmPage,pages))
local first=(tmPage-1)*perPage+1
for slot=1,perPage do
local machine=machines[first+slot-1]
if not machine then break end
local col=(slot-1)>=5 and 1 or 0
local row=(slot-1)%5
finalText(machine,64+col*44,94+row*6,1.85,white,
ox,oy,sc,"left",42)
end
if #machines==0 then finalText("NONE",64,95,2.2,muted,ox,oy,sc) end
if pages>1 then
finalText("SELECT: NEXT LIST",111,125,1.55,{0.42,0.94,0.58,1},
ox,oy,sc,"right",38)
end
elseif page==2 then
section(62,25,92,"CURRENT MOVES")
local moves=mon.moves or {}
for i=1,4 do
local mv=moves[i]
local md=moveDef(mv)
local y=33+(i-1)*13
finalText(moveName(mv),64,y,2.65,white,ox,oy,sc,"left",48)
local pp=mv and type(mv)=="table" and (mv.pp or "?") or "—"
local maxpp=mv and type(mv)=="table" and (mv.maxPp or mv.maxPP) or nil
maxpp=maxpp or (md and md.pp) or pp
finalText("PP "..tostring(pp).."/"..tostring(maxpp),115,y,2.0,muted,
ox,oy,sc,"right",36)
finalText(GoldCompat.moveTypeName(md),115,y+5,1.8,gold,
ox,oy,sc,"right",36)
end
section(62,86,92,"LEVEL-UP LEARNSET")
local learned={}
if gen2 then
learned=GoldCompat.summaryLevelUpLearnset(summary)
else
for _,id in ipairs(def.level1Moves or {}) do
learned[#learned+1]={level=1,name=moveName(id)}
end
for _,entry in ipairs(def.learnset or {}) do
if entry and entry.move then
learned[#learned+1]={level=tonumber(entry.level) or 1,name=moveName(entry.move)}
end
end
table.sort(learned,function(a,b) return a.level<b.level end)
end
for i=1,math.min(10,#learned) do
local entry=learned[i]
local col=(i-1)>=5 and 1 or 0
local row=(i-1)%5
finalText(("L%02d %s"):format(entry.level,entry.name),64+col*44,94+row*6,
1.85,white,ox,oy,sc,"left",42)
end
if #learned==0 then finalText("NO LEVEL MOVES",64,95,1.8,muted,ox,oy,sc) end
else
section(62,25,92,"PROFILE")
local ot=gen2 and summary.otName and summary:otName()
or mon.otName or mon.originalTrainer or "—"
local id=gen2 and summary.otId and summary:otId()
or mon.otId or mon.trainerId or 0
finalText("OT/ "..tostring(ot),65,33,2.5,gold,ox,oy,sc,"left",48)
finalText(("ID No.%05d"):format(tonumber(id) or 0),114,33,2.25,gold,
ox,oy,sc,"right",37)
finalText("TYPE/  "..types,65,40,2.6,white,ox,oy,sc,"left",83)
finalText("SPECIES/  "..tostring(def.name or mon.species),65,47,2.2,muted,
ox,oy,sc,"left",83)
local heightLabel="—"
local weightLabel="—"
if gen2 then
local dex=GoldCompat.summaryDexEntry(summary) or {}
local pseudo={dexEntry={gen2Height=dex.height,gen2Weight=dex.weight}}
heightLabel=DexUI.heightLabel(pseudo)
weightLabel=DexUI.weightLabel(pseudo)
else
heightLabel=DexUI.heightLabel(def)
weightLabel=DexUI.weightLabel(def)
end
finalText("HT "..heightLabel.."   WT "..weightLabel,65,52,1.85,muted,
ox,oy,sc,"left",83)

section(62,57,92,"STATS")
local stats=mon.stats or {}
local rows={{"HP",stats.hp or mon.maxHp or 0},{"ATTACK",stats.attack or 0},
{"DEFENSE",stats.defense or 0},{"SP. ATK",stats.specialAttack or stats.special or 0},
{"SP. DEF",stats.specialDefense or stats.special or 0},{"SPEED",stats.speed or 0}}
for i,row in ipairs(rows) do
local col=(i-1)>=3 and 1 or 0
local ry=(i-1)%3
finalText(row[1],65+col*45,66+ry*7,2.25,gold,ox,oy,sc)
finalText(tostring(row[2]),94+col*45,66+ry*7,2.55,white,
ox,oy,sc,"right",12)
end

section(62,89,92,"EXP.")
local exp=tonumber(mon.experience or mon.exp) or 0
local nextExp=0
local ratio=0
if gen2 then
nextExp=summary.expToNext and summary:expToNext() or 0
ratio=GoldCompat.summaryExpRatio(summary)
else
ratio=partyExpRatio(game,mon)
if mon.level and mon.level<100 then
local ok,value=pcall(Growth.expForLevel,def.growthRate,mon.level+1,
game.data and game.data.growth_rates)
if ok then nextExp=math.max(0,(tonumber(value) or exp)-exp) end
end
end
finalText("EXP. POINTS",65,98,2.2,gold,ox,oy,sc)
finalText(tostring(exp),113,98,2.55,white,ox,oy,sc,"right",36)
finalText("NEXT LV.",65,105,2.2,gold,ox,oy,sc)
finalText(tostring(nextExp),113,105,2.55,white,ox,oy,sc,"right",36)
G.push("all") G.translate(ox,oy) G.scale(sc,sc)
G.setColor(0.01,0.025,0.03,1) roundedRect("fill",65,114,84,4,1.5)
G.setColor(0.08,0.46,0.96,1) roundedRect("fill",66,115,82*clamp(ratio,0,1),2,1)
G.pop()
end

finalText("←/→ SELECT TIER",7,134,1.75,white,ox,oy,sc)
finalText(page==2 and "↑/↓ MON   SELECT: MANAGE" or "↑/↓ POKéMON",
66,134,page==2 and 1.32 or 1.50,muted,
ox,oy,sc,"center",73)
finalText("B: BACK",133,134,1.95,white,ox,oy,sc,"right",18)
end

return {tabs=GoldCompat.drawColosseumSummaryTabs,status=GoldCompat.drawColosseumStatusPage,
egg=GoldCompat.drawColosseumEggSummary,summary=GoldCompat.drawColosseumSummary}
end
return M
