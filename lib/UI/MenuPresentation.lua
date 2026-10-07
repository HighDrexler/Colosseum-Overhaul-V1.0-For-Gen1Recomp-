

local M={}
function M.bind(ctx)
local love={graphics=ctx.graphics}
local GoldCompat,State,PartyMenu,DexUI=ctx.compat,ctx.state,ctx.partyMenu,ctx.dexUI
local roundedRect,finalCanvas,font=ctx.roundedRect,ctx.finalCanvas,ctx.font
local finalText,finalTextFitted,finalTextWidth=ctx.finalText,ctx.finalTextFitted,ctx.finalTextWidth
local partyLogicalCanvas,partyText,partyTextWidth=ctx.partyCanvas,ctx.partyText,ctx.partyTextWidth
local itemTargetIsStone,owStatus=ctx.itemTargetIsStone,ctx.status
local partyHPBarFinal,partyMoveName,partyMovePP,partyStat=ctx.hpBar,ctx.moveName,ctx.movePP,ctx.stat
local UI_TEXT_SCALE=ctx.textScale or 1.08
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local R={}
local function drawColosseumRunoffPanel(x,y,w,h,headerH)
local g=love.graphics
local right=math.min(162,x+w+6)
headerH=headerH or 14
g.setColor(0.00,0.01,0.015,0.34)
g.polygon("fill",x+5,y+3,right,y+3,right,y+h+3,x+5,y+h+3,
x,y+h-2,x,y+8)


GoldCompat.setUIColor("surface",0.030,0.105,0.108,0.88)
g.polygon("fill",x+5,y,right,y,right,y+h,x+5,y+h,x,y+h-5,x,y+5)
GoldCompat.setUIColor("surface",0.040,0.175,0.165,0.80)
g.polygon("fill",x+4,y+3,right,y+3,right,y+headerH,x+7,y+headerH,
x+3,y+headerH-4)
GoldCompat.setUIColor("trim",0.36,0.63,0.61,0.95)
g.setLineWidth(1.2)
g.line(x+6,y,right,y)
g.line(x+6,y+h,right,y+h)
g.line(x,y+6,x,y+h-6)
GoldCompat.setUIColor("trim",0.12,0.45,0.38,0.86)
g.rectangle("fill",x+8,y+headerH,right-x-10,1)
end

local function drawColosseumRunoffSelection(x,y,w,h)
local g=love.graphics
local right=math.min(162,x+w+5)
GoldCompat.setUIColor("selection",0.075,0.285,0.275,0.96)
g.polygon("fill",x+6,y,right,y,right,y+h,x+6,y+h,x+2,y+h*0.5)
GoldCompat.setUIColor("accent",1.00,0.34,0.16,1)
g.polygon("fill",x+5,y+h*0.5,x+1,y+h*0.22,x+1,y+h*0.78)
end
function R.start(game, state)
local g = love.graphics
local ox,oy,sc = finalCanvas()

if state.__gen3uiUISettings then
local visible=math.min(state.maxVisible or #state.items,#state.items)
local rowH=11
local w=state.width or 104
local h=visible*rowH+20
local x=state.left or 52
local y=math.max(4,math.floor((144-h)/2))

g.push("all")
g.translate(ox,oy)
g.scale(sc,sc)



drawColosseumRunoffPanel(x,y,w,h,16)

for row=1,visible do
local item=state.items[state.scroll+row]
if not item then break end
local yy=y+18+(row-1)*rowH
if (state.scroll+row)==state.index then
drawColosseumRunoffSelection(x+3,yy-1,w-3,rowH-1)
end
end
g.pop()

if state.title then
finalTextFitted(state.title,x+9,y+6,4.7,2.4,{1,1,1,1},ox,oy,sc,"left",w-14,8)
else
finalText("UI OPTIONS",x+9,y+6,4.7,{1,1,1,1},ox,oy,sc)
end

for row=1,visible do
local item=state.items[state.scroll+row]
if not item then break end
local yy=y+18+(row-1)*rowH
local selected=(state.scroll+row)==state.index
local cfg=item.__gen3uiUIRow
local value=cfg and DexUI.optionDisplay(cfg) or ""
finalTextFitted(item.label,x+8,yy+1,3.2,1.65,
selected and {1,1,1,1} or {0.73,0.86,0.81,1},
ox,oy,sc,"left",state.fullWidthRows and w-14 or 49,rowH-2)
finalTextFitted(value,x+59,yy+1,3.1,1.45,
selected and {1,1,1,1} or {0.55,0.78,0.69,1},
ox,oy,sc,"right",45,rowH-2)
end

if state.footer then
finalTextFitted(state.footer,x+8,y+h-6,2.55,1.8,{0.62,0.79,0.72,1},ox,oy,sc,"left",w-12,5)
else
finalText("A: CHANGE   B: BACK",x+8,y+h-6,2.55,{0.62,0.79,0.72,1},ox,oy,sc)
end
return
end

local visible = (state.maxVisible and math.min(state.maxVisible, #state.items)) or #state.items




local metricPx=math.max(4,math.floor(4.2*sc+0.5))
local metricH=font(metricPx*UI_TEXT_SCALE*GoldCompat.userTextScale()):getHeight()
/ math.max(sc,0.001)
local rowH=clamp(math.ceil(metricH+3),12,16)
local widest=0
for _,item in ipairs(state.items or {}) do
widest=math.max(widest,finalTextWidth(item.label or "",4.2,sc))
end
local w=clamp(math.ceil(widest+20),60,88)
local h = visible*rowH + 8
local x = 156-w
local y = math.max(3, math.floor((144-h)/2))

g.push("all")
g.translate(ox,oy)
g.scale(sc,sc)

drawColosseumRunoffPanel(x,y,w,h,0)

for row=1,visible do
local item = state.items[state.scroll + row]
if not item then break end
local ry = y + 4 + (row-1)*rowH
if (state.scroll + row) == state.index then
drawColosseumRunoffSelection(x+3,ry,w-3,rowH-1)
end
end
g.pop()

for row=1,visible do
local item = state.items[state.scroll + row]
if not item then break end
local ry = y + 4 + (row-1)*rowH
local selected = (state.scroll + row) == state.index
finalTextFitted(item.label,x+9,ry+1,4.2,2.2,
selected and {1,1,1,1} or {0.74,0.87,0.82,1},
ox,oy,sc,"left",w-15,rowH-2)
end
end

function R.party(game, state)
if not (game and state) then return false end

local party=state.party or (game.save and game.save.party) or {}
local ox,oy,sc=partyLogicalCanvas()
local doubles=state.__cbeDoublesParty==true
local originalPartyText,originalPartyWidth=partyText,partyTextWidth
local doublesRenderer=GoldCompat.ColosseumUI and GoldCompat.ColosseumUI.doubles
local function partyText(value,x,y,size,color,align,width)
if doubles and doublesRenderer and doublesRenderer.partyText then
return doublesRenderer.partyText(value,x,y,size,color,align,width,ox,oy,sc)
end
return originalPartyText(value,x,y,size,color,align,width)
end
local function partyTextWidth(value,size)
if doubles and doublesRenderer and doublesRenderer.partyTextWidth then
return doublesRenderer.partyTextWidth(value,size,sc)
end
return originalPartyWidth(value,size)
end
local g=love.graphics
ctx.setPartyTransform(ox,oy,sc)
state.isOpaque=false
state.__gen3uiColosseumParty=true

local function panel(x,y,w,h,selected,alpha)
GoldCompat.setUIColor("surface",0.015,0.025,0.030,0.48)
roundedRect("fill",x+1.5,y+1.5,w,h,3)
GoldCompat.setUIColor("surface",0.055,0.105,0.115,alpha or 0.86)
roundedRect("fill",x,y,w,h,3)
GoldCompat.setUIColor(selected and "accent" or "trim",selected and {0.78,0.14,0.10,0.98}
or {0.45,0.57,0.55,0.96})
roundedRect("line",x,y,w,h,3)
GoldCompat.setUIColor(selected and "accent" or "trim",selected and {0.98,0.34,0.18,0.96}
or {0.12,0.22,0.22,0.92})
roundedRect("line",x+1.4,y+1.4,w-2.8,h-2.8,2)
end

local function icon(mon,x,y,w,h)
GoldCompat.setUIColor("surface",0.015,0.025,0.030,0.92)
roundedRect("fill",x,y,w,h,2)
GoldCompat.setUIColor("trim",0.36,0.46,0.44,0.96)
roundedRect("line",x,y,w,h,2)



if GoldCompat.drawColosseumPortrait(game,mon,x+0.8,y+0.8,w-1.6,h-1.6) then return end

g.push("all")
g.translate(x+1,y+1)
if type(state.drawIcon)=="function" then
pcall(state.drawIcon,state,mon,0,0)
else
pcall(PartyMenu.drawIcon,game,mon,0,0,false,state.blink or 0)
end
g.pop()
end

local function maxHPFor(mon)
return math.max(1,tonumber(mon and (mon.maxHp
or (mon.stats and mon.stats.hp))) or 1)
end

local function definition(mon)
if not mon then return nil end
local defs=state.pokemon or (game.data and game.data.pokemon)
return defs and defs[mon.species] or nil
end

local function displayName(mon)
local def=definition(mon)
return tostring(mon and (mon.isEgg and "EGG"
or mon.nickname or (def and def.name) or mon.species) or "POKéMON")
end

local function itemName(mon)
if not (mon and mon.item and mon.item~=0 and mon.item~="") then
return "NONE"
end
local items=state.items or (game.data and game.data.items)
local def=items and items[mon.item]
return tostring((def and def.name) or mon.item)
end

local function targetLabel(mon)
if state.targetLabel then return state.targetLabel(mon) end
if state.tmhm then
local move=state.tmhm.move or state.tmhm
local def=definition(mon)
local able=false
for _,moveId in ipairs((def and def.tmhm) or {}) do
if moveId==move then able=true break end
end
return able and "ABLE" or "NOT ABLE",
able and {0.38,0.95,0.52,1} or {1.00,0.40,0.32,1}
end
if state.__gen3uiItemTarget and itemTargetIsStone(state) then
local able=GoldCompat.stoneAllowedForMon(game,state,mon)
return able and "ALLOWED" or "NOT ALLOWED",
able and {0.38,0.95,0.52,1} or {1.00,0.40,0.32,1}
end
return nil,nil
end

g.push("all")
g.translate(ox,oy)
g.scale(sc,sc)

if #party==0 then
panel(29,54,102,30,true,0.90)
partyText("No POKéMON!",45,64,5,{0.98,0.98,0.94,1})
g.pop()
return true
end

local selected=clamp(state.index or 1,1,#party)
local selectedMon=party[selected]
local cardW,cardH=74,23
local cardXs={5,81}
local cardYs={5,31,57}

if doubles then




for _,card in ipairs(state.doublesCards or {}) do
local x,y,w,h=card.x,card.y,card.w,card.h
local mon=card.index and party[card.index]
local isSelected=mon and card.index==selected and not state.doublesExit
panel(x,y,w,h,isSelected,mon and 0.90 or 0.54)
if mon then
local pod=h-4
icon(mon,x+2,y+2,pod,pod)
local textX=x+pod+5
local right=x+w-3
local available=right-textX
local name=displayName(mon)
local nameSize=card.active and 2.95 or 2.75
local nameMax=math.max(12,available-15)
while nameSize>1.55 and partyTextWidth(name,nameSize)>nameMax do nameSize=nameSize-0.10 end
partyText(name,textX,y+2.2,nameSize,{0.98,0.98,0.94,1},"left",nameMax)
if not mon.isEgg then
partyText("Lv"..tostring(mon.level or "?"),right-14,y+2.2,2.25,{0.94,0.86,0.42,1},"right",14)
local gender=GoldCompat.genderSymbol(mon)
if gender then


pcall(GoldCompat.drawGenderIcon,ox+(textX-2)*sc,oy+(y+h-5.5)*sc,
math.max(8,2.2*sc),gender)
end
local hpMax=maxHPFor(mon)
local hpNow=math.max(0,tonumber(mon.hp) or 0)
local hpText=tostring(hpNow).."/"..tostring(hpMax)
local hpSize=1.95
local valueW=math.min(available*.53,partyTextWidth(hpText,hpSize))
local valueX=right-valueW
local hpY=y+(card.active and 13 or 9)
partyHPBarFinal(textX,hpY,math.max(9,valueX-textX-2),mon)
partyText(hpText,valueX,hpY-0.3,hpSize,{0.98,0.98,0.94,1},"right",valueW)
local status=owStatus(mon)
local note=(state.doublesLabels or {})[card.index]
local noteText=note or status or "READY"
if note and status and status~="OK" and note~="FAINTED" then noteText=note.." / "..status end
local noteY=y+h-5
partyText(noteText,textX+3,noteY,1.65,
status=="FNT" and {1.00,0.40,0.32,1} or note=="RESERVED" and {1.00,0.76,0.30,1}
or {0.66,0.85,0.78,1},"left",available-3)
else
partyText("EGG",textX,y+h-6,2.05,{0.72,0.79,0.75,1},"left",available)
end
else
partyText(card.placeholder or "EMPTY",x+5,y+h*.40,2.25,{0.55,0.65,0.62,0.85},"center",w-10)
end
end
if (state.doublesReserveCount or 0)>4 then
partyText(tostring((state.doublesReserveOffset or 0)+1).."-"..
tostring(math.min((state.doublesReserveOffset or 0)+4,state.doublesReserveCount))..
"/"..tostring(state.doublesReserveCount),126,79,1.55,{0.72,0.80,0.76,1},"right",28)
end
else
for i=1,6 do
local col=(i-1)%2+1
local row=math.floor((i-1)/2)+1
local x,y=cardXs[col],cardYs[row]
local mon=party[i]

if mon then
local isSelected=i==selected and not state.exitSelected
panel(x,y,cardW,cardH,isSelected,0.84)
icon(mon,x+2,y+2,19,19)

local name=displayName(mon)
local nameSize=2.85
local nameMax=33
while nameSize>1.75 and partyTextWidth(name,nameSize)>nameMax do
nameSize=nameSize-0.12
end
partyText(name,x+23,y+3,nameSize,{0.98,0.98,0.94,1},"left",nameMax)

if not mon.isEgg then
local level="Lv"..tostring(mon.level or "?")
partyText(level,x+cardW-17,y+3,2.35,{0.94,0.86,0.42,1},"left",14)

local gender=GoldCompat.genderSymbol(mon)
if gender then
local gx=math.min(x+23+partyTextWidth(name,nameSize)+1,x+cardW-21)
pcall(GoldCompat.drawGenderIcon,ox+gx*sc,oy+(y+3)*sc,7,gender)
end

local hpMax=maxHPFor(mon)
local hpNow=math.max(0,tonumber(mon.hp) or 0)
local hpText=tostring(hpNow).."/"..tostring(hpMax)
local valueW=partyTextWidth(hpText,1.95)
local barX=x+23
local valueX=x+cardW-3-valueW
local barW=math.max(12,valueX-barX-2)
partyHPBarFinal(barX,y+13,barW,mon)
partyText(hpText,valueX,y+12,1.95,{0.98,0.98,0.94,1})

local target,colr=targetLabel(mon)
local status=owStatus(mon)
if target then
partyText(target,x+23,y+17,1.75,colr,"left",cardW-26)
elseif status then
partyText(status,x+23,y+17,1.75,
status=="FNT" and {1.00,0.35,0.28,1} or {0.92,0.54,1.00,1})
end
end
else
panel(x,y,cardW,cardH,false,0.50)
partyText("—",x+35,y+8,3,{0.56,0.64,0.62,0.72})
end
end

end


local dx,dy,dw,dh=5,83,150,44
panel(dx,dy,dw,dh,true,0.88)
local selectedName=displayName(selectedMon)
partyText(selectedName,dx+5,dy+3,3.0,{0.98,0.98,0.94,1},"left",38)
partyText("Lv"..tostring(selectedMon.level or "?"),dx+45,dy+3,2.5,
{0.94,0.86,0.42,1})

local selectedStatus=owStatus(selectedMon) or "OK"
partyText(selectedStatus,dx+62,dy+3,2.15,
selectedStatus=="FNT" and {1.00,0.35,0.28,1} or {0.72,0.84,0.80,1})
local held="HELD  "..itemName(selectedMon)
local heldSize=2.15
while heldSize>1.55 and partyTextWidth(held,heldSize)>49 do
heldSize=heldSize-0.10
end
partyText(held,dx+96,dy+3,heldSize,{0.78,0.84,0.80,1},"left",49)

partyText("EXP",dx+5,dy+10,1.9,{0.36,0.72,1.00,1})
GoldCompat.drawPartyExpBar(game,selectedMon,dx+16,dy+11,43)
partyText("MOVES",dx+63,dy+10,1.9,{0.78,0.84,0.80,1})

local learn=state.__gen3uiGoldBattleMoveParty
and State.activeGoldBattleMoveLearn or State.activeMoveLearn
if doubles then learn=nil end
local battleLearn=State.activeBattleMoveLearn
if state.__gen3uiBattleMoveParty and battleLearn and battleLearn.selecting then
learn=battleLearn
end
local ppPicker=not doubles and state.__gen3uiPPMoveParty and State.activePPMoveList or nil
if ppPicker then
learn={selecting=true,mon=selectedMon,index=ppPicker.index or 1,__ppItem=true}
end
local replacing=learn and learn.selecting and learn.mon==selectedMon
if replacing and not learn.__ppItem then
local newDef=game.data and game.data.moves and game.data.moves[learn.newMoveId]
local newName=(newDef and newDef.name)
or GoldCompat.humanizeIdentifier(learn.newMoveId or "MOVE")
local incoming="NEW  "..newName
local incomingSize=1.9
while incomingSize>1.35 and partyTextWidth(incoming,incomingSize)>70 do
incomingSize=incomingSize-0.10
end
partyText(incoming,dx+76,dy+10,incomingSize,{1.00,0.76,0.30,1},"left",70)
end

local moves=selectedMon.moves or {}
local moveX,moveY=dx+4,dy+16
local moveGap=2
local moveW=(dw-8-moveGap*3)/4
local moveH=13
for i=1,4 do
local mx=moveX+(i-1)*(moveW+moveGap)
local picked=replacing and (learn.index or 1)==i
GoldCompat.setUIColor(picked and "selection" or "surface",picked and {0.54,0.12,0.08,0.96} or {0.02,0.04,0.045,0.78})
roundedRect("fill",mx,moveY,moveW,moveH,1.5)
GoldCompat.setUIColor(picked and "accent" or "trim",picked and {1.00,0.34,0.18,1} or {0.28,0.40,0.39,0.96})
roundedRect("line",mx,moveY,moveW,moveH,1.5)

local entry=moves[i]
local moveName=partyMoveName(game,entry)
local pp=partyMovePP(game,entry)
local moveSize=2.2
while moveSize>1.35 and partyTextWidth(moveName,moveSize)>moveW-3 do
moveSize=moveSize-0.10
end
partyText(moveName,mx+1.5,moveY+2,moveSize,
{0.98,0.98,0.94,1},"center",moveW-3)
if pp~="" then
partyText(pp,mx+1.5,moveY+8,1.55,{0.66,0.75,0.72,1},"center",moveW-3)
end
end

local stats
if GoldCompat.generation=="gen2" then
stats={
{"ATK",partyStat(selectedMon,"attack","atk")},
{"DEF",partyStat(selectedMon,"defense","def")},
{"SPD",partyStat(selectedMon,"speed","spd")},
{"SPA",partyStat(selectedMon,"specialAttack","spAtk","special")},
{"SDF",partyStat(selectedMon,"specialDefense","spDef","special")},
}
else
stats={
{"ATK",partyStat(selectedMon,"attack","atk")},
{"DEF",partyStat(selectedMon,"defense","def")},
{"SPD",partyStat(selectedMon,"speed","spd")},
{"SPC",partyStat(selectedMon,"special","spc","specialAttack")},
}
end
local statW=(dw-8)/#stats
for i,stat in ipairs(stats) do
local sx=dx+4+(i-1)*statW
local text=stat[1].." "..tostring(stat[2])
partyText(text,sx,dy+32,1.9,{0.78,0.84,0.80,1},"center",statW)
end

local submenuOpen=state.submenu~=nil and state.submenu~=false


if not state.hideFooter then
panel(5,130,117,10,false,0.88)
panel(125,130,30,10,(doubles and state.doublesExit) or state.exitSelected,0.88)
local prompt
if replacing then
local count=#moves
prompt=(learn.index or 1)>count and "Cancel move learning?"
or "Choose a move to replace."
elseif state.switchFrom then
prompt="Move to where?"
elseif state.__gen3uiItemTarget and itemTargetIsStone(state) then
prompt="Use stone on which POKéMON?"
elseif state.__gen3uiItemTarget then
prompt="Use item on which POKéMON?"
elseif type(state.bottomMessage)=="function" then
local ok,value=pcall(state.bottomMessage,state)
prompt=ok and value or nil
end
prompt=tostring(prompt or state.prompt or "Choose a POKéMON.")
:gsub("<PK><MN>","POKéMON"):gsub("\n"," ")
local promptSize=2.7
while promptSize>1.7 and partyTextWidth(prompt,promptSize)>107 do
promptSize=promptSize-0.10
end
partyText(prompt,9,133,promptSize,{0.98,0.98,0.94,1},"left",107)
partyText(state.exitLabel or (doubles and (state.doublesRequired and "REQUIRED" or "B: EXIT") or (submenuOpen and "B: BACK" or "B: EXIT")),128,133,2.25,
{0.98,0.98,0.94,1},"center",24)
end







local submenuItems=state.subItems
local submenuIndex=state.subIndex
local submenuState=type(state.submenu)=="table" and state.submenu or nil
if submenuState and type(submenuState.items)=="table" then
submenuItems=submenuState.items
submenuIndex=submenuState.index
end

local battleSubmenu=submenuOpen and (
state.wantsBattleSubmenu==true
or (submenuState and submenuState.battle==true)
or (state.battle and state.onSwitch~=nil))




if battleSubmenu and type(submenuItems)~="table" then
submenuItems={
{label="SWITCH",action="battle_switch"},
{label="STATS",action="stats"},
{label="CANCEL",action="cancel"},
}
submenuIndex=tonumber(submenuIndex) or 1
end

if submenuOpen and type(submenuItems)=="table" and #submenuItems>0 then
local count=#submenuItems
local leftMargin=math.max(0,ox/sc)

if battleSubmenu then




local sw=46
local sh=10+count*9
local sx=leftMargin>=sw+4 and -(sw+3) or 109
local sy=math.max(18,math.floor((82-sh)*0.5)+18)
panel(sx,sy,sw,sh,true,0.985)
partyText("BATTLE",sx+5,sy+3,1.75,{1.00,0.72,0.28,1},"left",sw-10)
for i,entry in ipairs(submenuItems) do
local yy=sy+8+(i-1)*9
local picked=i==(tonumber(submenuIndex) or 1)
if picked then
g.setColor(0.62,0.14,0.09,0.98)
roundedRect("fill",sx+3,yy,sw-6,8,1.5)
end
local label=type(entry)=="table"
and (entry.label or entry.name or entry.id) or entry
partyText(tostring(label or ""),sx+6,yy+1.7,2.45,
picked and {1,1,1,1} or {0.86,0.90,0.88,1},"left",sw-10)
end
else
local sw=42
local sh=math.min(ctx.partyActionMaxHeight or 64,6+count*10)



local sx=leftMargin>=sw+4 and -(sw+3) or 5



local sy=leftMargin>=sw+4 and math.max(18,(144-sh)*0.5) or 5
panel(sx,sy,sw,sh,true,0.96)
for i,entry in ipairs(submenuItems) do
local yy=sy+3+(i-1)*10
local picked=i==(tonumber(submenuIndex) or 1)
if picked then
g.setColor(0.62,0.14,0.09,0.96)
roundedRect("fill",sx+3,yy,sw-6,9,1.5)
end
local label=type(entry)=="table"
and (entry.label or entry.name or entry.id) or entry
partyText(tostring(label or ""),sx+6,yy+2,2.6,
picked and {1,1,1,1} or {0.86,0.90,0.88,1},"left",sw-10)
end
end
end

g.setColor(1,1,1,1)
g.pop()
return true
end

function R.bag(pack,winW,winH,embedded)
local G=love.graphics
winW=winW or G.getWidth()
winH=winH or G.getHeight()
local ox,oy,sc=finalCanvas()



if pack.give and not embedded then
local party=GoldCompat.flowStateBelow(pack.game,pack,"party")
if party then
pcall(GoldCompat.drawGoldPartyMenu,party,winW,winH)
end
end

if embedded then




local x=5
local y=24
local w=150
local h=112

G.push("all")
G.translate(ox,oy)
G.scale(sc,sc)

drawColosseumRunoffPanel(x,y,w,h,13)
G.setColor(0.006,0.026,0.030,0.91)
G.polygon("fill",x+4,y+17,x+w+3,y+17,x+w+3,y+h-7,
x+8,y+h-7,x+4,y+h-11)
G.setColor(0.25,0.55,0.53,0.74)
G.line(x+7,y+18,x+w-2,y+18)

local pocket=pack.pocket and pack:pocket() or {id="ITEM",label="ITEMS"}
local tabs={"ITEMS","BALLS","KEY","TM/HM"}
local ids=pack.pocketIds or {"ITEM","BALL","KEY_ITEM","TM_HM"}
local tabW=(w-8)/4
for i,label in ipairs(tabs) do
local tx=x+4+(i-1)*tabW
local selected=pocket.id==ids[i]
G.setColor(selected and 0.06 or 0.025,
selected and 0.31 or 0.085,
selected and 0.28 or 0.09,selected and 0.96 or 0.72)
G.polygon("fill",tx,y+5,tx+tabW-4,y+5,tx+tabW-1,y+8,
tx+tabW-4,y+14,tx,y+14)
end


G.setColor(0.22,0.52,0.49,0.76)
G.rectangle("fill",x+5,y+18,w-10,1)

local rows=pack.rows or {}
local first=(pack.scroll or 0)+1
local visible=tonumber(pack.visibleRows) or 6
for r=1,visible do
local idx=first+r-1
local yy=y+23+(r-1)*10
if idx==(pack.index or 1) then
drawColosseumRunoffSelection(x+6,yy-1,w-12,9)
end
end


G.setColor(0.008,0.033,0.036,0.96)
roundedRect("fill",x+5,y+h-29,w-10,22,2)
G.setColor(0.26,0.58,0.56,0.86)
roundedRect("line",x+5,y+h-29,w-10,22,2)

G.pop()

for i,label in ipairs(tabs) do
local tx=x+4+(i-1)*tabW
GoldCompat.panelText(label,tx,y+7,2.15,
pocket.id==ids[i] and {0.94,1.00,0.97,1} or {0.48,0.67,0.63,1},
"center",tabW-1)
end


if (pack.scroll or 0)>0 then
GoldCompat.panelText("▲",x+w-11,y+20,2.1,{0.40,0.83,0.72,1})
end
if ((pack.scroll or 0)+visible)<#rows then
GoldCompat.panelText("▼",x+w-11,y+h-34,2.1,{0.40,0.83,0.72,1})
end

for r=1,visible do
local idx=first+r-1
local yy=y+23+(r-1)*10
local row=rows[idx]
local selected=idx==(pack.index or 1)
if row then
local label=tostring(row.name or row.id or "")
GoldCompat.panelText(label,x+9,yy+1,3.0,
selected and {1,1,1,1} or {0.68,0.83,0.79,1},"left",w-27)
if row.showCount then
GoldCompat.panelText("×"..tostring(row.count or 1),x+w-20,yy+1,2.55,
selected and {1,1,1,1} or {0.48,0.68,0.64,1},"right",12)
elseif row.teaches then
GoldCompat.panelText(row.teaches,x+w-31,yy+1,2.15,
selected and {0.90,1.00,0.91,1} or {0.43,0.66,0.61,1},"right",24)
end
elseif idx==#rows+1 then
GoldCompat.panelText("CANCEL",x+9,yy+1,3.0,
selected and {1,1,1,1} or {0.68,0.83,0.79,1})
end
end

local desc
if pack.message then
desc=table.concat(pack.message," ")
elseif pack.description then
local ok,v=pcall(pack.description,pack)
if ok then desc=v end
end
desc=GoldCompat.cleanItemDescription(desc or "Choose an item.")
local f=font(2.55*UI_TEXT_SCALE*GoldCompat.userTextScale())
local _,wrapped=f:getWrap(desc,w-18)
for i=1,math.min(2,#wrapped) do
GoldCompat.panelText(wrapped[i],x+10,y+h-24+(i-1)*7,2.55,
{0.84,0.94,0.90,1},"left",w-20)
end


if pack.submenu then
local m=pack.submenu
local count=#(m.rows or {})
local mw=34
local mh=count*9+8
local mx=x+5
local my=math.max(y+20,y+h-mh-32)
G.push("all"); G.translate(ox,oy); G.scale(sc,sc)
G.setColor(0.005,0.025,0.029,0.97); roundedRect("fill",mx,my,mw,mh,2)
G.setColor(0.28,0.61,0.58,0.96); roundedRect("line",mx,my,mw,mh,2)
for i=1,count do
if i==m.index then
drawColosseumRunoffSelection(mx+3,my+4+(i-1)*9,mw-6,8)
end
end
G.pop()
for i,id in ipairs(m.rows or {}) do
local labels={use="USE",give="GIVE",toss="TOSS",sel="SEL",quit="QUIT"}
GoldCompat.panelText(labels[id] or tostring(id),mx+8,my+5+(i-1)*9,2.7,
i==m.index and {1,1,1,1} or {0.66,0.82,0.77,1})
end
end

if pack.qtyState then
local q=pack.qtyState
GoldCompat.panelText(("HOW MANY?  ×%02d"):format(q.qty or 1),
x+10,y+h-41,2.9,{0.84,0.96,0.90,1})
end
if pack.confirm then
GoldCompat.panelText(pack.confirm.choice==1 and "YES  /  no" or "yes  /  NO",
x+w-40,y+h-41,2.6,{0.84,0.96,0.90,1})
end

return
end
















local pocket=pack.pocket and pack:pocket() or {id="ITEM",label="ITEMS"}
local ids=pack.pocketIds or {"ITEM","BALL","KEY_ITEM","TM_HM"}
local pocketTitles={ITEM="ITEMS",BALL="BALLS",KEY_ITEM="KEY ITEMS",TM_HM="TM/HM"}
local dotColors={
ITEM={0.34,0.64,0.66},
BALL={0.30,0.52,0.78},
KEY_ITEM={0.38,0.68,0.44},
TM_HM={0.54,0.44,0.76},
}
local headerTitle=pocketTitles[pocket.id] or pocket.label or "ITEMS"

local listX,listY,listW,listH = 76,8,84,90
local headerH,tabRowH,topChevH,footerChevH = 11,12,5,5
local listBodyTop=listY+headerH+tabRowH+topChevH
local listBodyBottom=listY+listH-footerChevH





local visible=tonumber(pack.visibleRows) or 7
local rowH=(listBodyBottom-listBodyTop)/visible

local descX,descY,descW,descH = 4,listY+listH+4,68,32

local rows=pack.rows or {}
local first=(pack.scroll or 0)+1
local rx=listX+4
local rw=listW-8

G.push("all")
G.translate(ox,oy)
G.scale(sc,sc)


local hx1,hx2=listX+3,listX+listW-3
G.setColor(0.03,0.07,0.08,0.55)
G.polygon("fill",hx1+1,listY+1,hx2+1,listY+1,listX+listW+1,listY+headerH*0.5+1,
hx2+1,listY+headerH+1,hx1+1,listY+headerH+1,listX+1,listY+headerH*0.5+1)
G.setColor(0.18,0.36,0.36,0.96)
G.polygon("fill",hx1,listY,hx2,listY,listX+listW,listY+headerH*0.5,
hx2,listY+headerH,hx1,listY+headerH,listX,listY+headerH*0.5)
G.setColor(0.40,0.66,0.63,0.55)
G.line(hx1+2,listY+1.4,hx2-2,listY+1.4)
G.setColor(0.05,0.15,0.16,0.95)
G.setLineWidth(0.6)
G.polygon("line",hx1,listY,hx2,listY,listX+listW,listY+headerH*0.5,
hx2,listY+headerH,hx1,listY+headerH,listX,listY+headerH*0.5)


local cx=listX+listW/2
local usable=listW-20
local step=usable/math.max(1,#ids-1)
local dotY=listY+headerH+tabRowH*0.5
for i=1,#ids do
local dx=listX+10+(i-1)*step
G.setColor(0.10,0.24,0.24,0.75)
G.setLineWidth(0.7)
G.line(cx,listY+headerH+0.5,dx,dotY-3.5)
end
for i=1,#ids do
local dx=listX+10+(i-1)*step
local selected=pocket.id==ids[i]
local c=dotColors[ids[i]] or {0.4,0.6,0.6}
if selected then
GoldCompat.setUIColor("accent",1.00,0.36,0.16,0.9)
G.circle("line",dx,dotY,4.4)
G.setColor(0.92,0.98,0.95,1)
G.circle("fill",dx,dotY,3.4)
else
G.setColor(c[1]*0.55,c[2]*0.55,c[3]*0.55,0.85)
G.circle("fill",dx,dotY,2.9)
G.setColor(0.05,0.10,0.11,0.9)
G.setLineWidth(0.5)
G.circle("line",dx,dotY,2.9)
end
end


local canScrollUp=(pack.scroll or 0)>0
local canScrollDown=((pack.scroll or 0)+visible)<#rows
G.setColor(0.03,0.09,0.10,0.85)
roundedRect("fill",rx,listBodyTop-topChevH,rw,topChevH,1.4)
roundedRect("fill",rx,listBodyBottom,rw,footerChevH,1.4)
G.setColor(canScrollUp and 0.44 or 0.16,canScrollUp and 0.86 or 0.24,
canScrollUp and 0.78 or 0.25,canScrollUp and 1 or 0.6)
G.polygon("fill",cx-3.5,listBodyTop-1.6,cx+3.5,listBodyTop-1.6,cx,listBodyTop-4.4)
G.setColor(canScrollDown and 0.44 or 0.16,canScrollDown and 0.86 or 0.24,
canScrollDown and 0.78 or 0.25,canScrollDown and 1 or 0.6)
G.polygon("fill",cx-3.5,listBodyBottom+1.6,cx+3.5,listBodyBottom+1.6,cx,listBodyBottom+4.4)


GoldCompat.setUIColor("surface",0.006,0.028,0.031,0.90)
G.rectangle("fill",rx,listBodyTop,rw,listBodyBottom-listBodyTop)
G.setColor(0.20,0.44,0.42,0.55)
G.rectangle("line",rx,listBodyTop,rw,listBodyBottom-listBodyTop)

for r=1,visible do
local idx=first+r-1
local ry=listBodyTop+(r-1)*rowH
local selected=idx==(pack.index or 1)
if selected then
G.setColor(0.05,0.26,0.23,0.95)
roundedRect("fill",rx+1.5,ry+0.7,rw-3,rowH-1.4,(rowH-1.4)*0.5)
G.setColor(0.30,0.92,0.62,0.95)
G.setLineWidth(0.7)
roundedRect("line",rx+1.5,ry+0.7,rw-3,rowH-1.4,(rowH-1.4)*0.5)
GoldCompat.setUIColor("accent",1.00,0.36,0.16,1)
G.circle("fill",rx+1.5+(rowH-1.4)*0.5,ry+0.7+(rowH-1.4)*0.5,(rowH-1.4)*0.30)
end
end

G.pop()


GoldCompat.panelText(headerTitle,listX,listY+2.2,3.6,
{0.95,1.00,0.97,1},"center",listW)

for r=1,visible do
local idx=first+r-1
local ry=listBodyTop+(r-1)*rowH
local row=rows[idx]
local selected=idx==(pack.index or 1)
local textX=rx+(selected and 10 or 6)
if row then
local label=tostring(row.name or row.id or "")
GoldCompat.panelText(label,textX,ry+rowH*0.16,2.9,
selected and {1,1,1,1} or {0.66,0.82,0.78,1},"left",rw-30)
if row.showCount then
GoldCompat.panelText("×"..tostring(row.count or 1),rx+rw-20,ry+rowH*0.16,2.5,
selected and {1,1,1,1} or {0.48,0.68,0.64,1},"right",16)
elseif row.teaches then
GoldCompat.panelText(row.teaches,rx+rw-30,ry+rowH*0.16,2.1,
selected and {0.90,1.00,0.91,1} or {0.43,0.66,0.61,1},"right",26)
end
elseif idx==#rows+1 then
GoldCompat.panelText("CANCEL",textX,ry+rowH*0.16,2.9,
selected and {1,1,1,1} or {0.66,0.82,0.78,1})
end
end



G.push("all")
G.translate(ox,oy)
G.scale(sc,sc)
G.setColor(0.02,0.04,0.05,0.45)
roundedRect("fill",descX+1,descY+1.4,descW,descH,4)
G.setColor(0.008,0.032,0.035,0.93)
roundedRect("fill",descX,descY,descW,descH,3.5)
G.setColor(0.30,0.60,0.58,0.85)
G.setLineWidth(0.8)
roundedRect("line",descX,descY,descW,descH,3.5)
G.setColor(0.45,0.78,0.72,0.30)
G.line(descX+4,descY+1.6,descX+descW-4,descY+1.6)
G.pop()

if pack.qtyState then
local q=pack.qtyState
GoldCompat.panelText("HOW MANY?",descX+6,descY+5,3.0,{0.90,0.98,0.94,1})
GoldCompat.panelText(("×%02d"):format(q.qty or 1),descX+6,descY+15,4.2,
{1.00,0.78,0.55,1})
elseif pack.confirm then
GoldCompat.panelText(pack.confirm.prompt or "USE THIS ITEM?",descX+6,descY+5,2.8,{0.90,0.98,0.94,1})
GoldCompat.panelText(pack.confirm.choice==1 and "YES  /  no" or "yes  /  NO",
descX+6,descY+16,3.1,{1.00,0.78,0.55,1})
else
local desc
if pack.message then
desc=table.concat(pack.message," ")
elseif pack.description then
local ok,v=pcall(pack.description,pack)
if ok then desc=v end
end
desc=GoldCompat.cleanItemDescription(desc or "Choose an item.")
local f=font(2.5*UI_TEXT_SCALE*GoldCompat.userTextScale())
local _,wrapped=f:getWrap(desc,descW-10)
for i=1,math.min(3,#wrapped) do
GoldCompat.panelText(wrapped[i],descX+5,descY+5+(i-1)*8,2.5,
{0.84,0.94,0.90,1},"left",descW-10)
end
end



if pack.submenu then
local m=pack.submenu
local count=#(m.rows or {})
local mw=36
local mh=count*9+7
local mx=listX-mw-3
local my=math.max(listBodyTop,math.min(listY+listH-mh,
listBodyTop+((pack.index or 1)-first)*rowH-2))

G.push("all")
G.translate(ox,oy)
G.scale(sc,sc)
G.setColor(0.02,0.04,0.05,0.5)
roundedRect("fill",mx+1,my+1.4,mw,mh,3)
GoldCompat.setUIColor("surface",0.006,0.030,0.033,0.96)
roundedRect("fill",mx,my,mw,mh,2.6)
G.setColor(0.30,0.60,0.58,0.9)
roundedRect("line",mx,my,mw,mh,2.6)
for i=1,count do
if i==m.index then
local ry=my+4+(i-1)*9
G.setColor(0.05,0.26,0.23,0.95)
roundedRect("fill",mx+2,ry-0.5,mw-4,8,3.5)
GoldCompat.setUIColor("accent",1.00,0.36,0.16,1)
G.circle("fill",mx+6.5,ry+3.5,1.6)
end
end
G.pop()

local labels={use="USE",give="GIVE",toss="TOSS",sel="SEL",quit="CANCEL"}
for i,id in ipairs(m.rows or {}) do
GoldCompat.panelText(labels[id] or tostring(id):upper(),mx+11,my+5+(i-1)*9,2.6,
i==m.index and {1,1,1,1} or {0.66,0.82,0.77,1})
end
end
end
return R
end
return M
