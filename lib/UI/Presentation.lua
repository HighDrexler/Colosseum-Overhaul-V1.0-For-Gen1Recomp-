


local P={}
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end







local mobileRuntime
function P.isMobile()
if mobileRuntime==nil then
mobileRuntime=false
if love and love.system and type(love.system.getOS)=="function" then
local ok,os=pcall(love.system.getOS)
os=ok and tostring(os or ""):lower() or ""
mobileRuntime=(os=="android" or os=="ios")
end
end
return mobileRuntime
end


P.MOBILE_PILL_BAND=.135
function P.bottomReserve(sw,sh,ctx,kind)
local override=ctx and tonumber(ctx.dialogueBottomReserve)
if override then return math.max(0,override) end
if P.isMobile() then return math.min(sw,sh)*P.MOBILE_PILL_BAND end
if kind=="battle" then return 0 end
return clamp(sh*.03,8,40)
end
function P.consolePanel(ctx,x,y,w,h,u)
local polygon=function(...) ctx.g.polygon("fill",...) end
local g=ctx.g
local c=13*u

g.setColor(0,0,0,0.36)
polygon(
x+c+5*u,y+6*u,x+w-c+5*u,y+6*u,
x+w+5*u,y+c+6*u,x+w-c+5*u,y+h+6*u,
x+c+5*u,y+h+6*u,x+5*u,y+h-c+6*u,x+5*u,y+c+6*u
)

ctx.setUIColor("surface",0.095,0.11,0.105,0.91)
polygon(
x+c,y,x+w-c,y,x+w,y+c,
x+w-c,y+h,x+c,y+h,x,y+h-c,x,y+c
)

ctx.setUIColor("trim",0.50,0.52,0.47,0.90)
g.setLineWidth(math.max(1,1.4*u))
g.line(x+c+3*u,y+3*u,x+w-c-3*u,y+3*u)
g.line(x+4*u,y+c+2*u,x+4*u,y+h-c-2*u)
end

function P.compactDialogue(ctx,lines,sourceLines,waiting,frame)
local font,text=ctx.font,ctx.text
local consolePanel=function(...) P.consolePanel(ctx,...) end
if type(lines)~="table" or #lines==0 then return false end
sourceLines=type(sourceLines)=="table" and sourceLines or lines

local g=ctx.g
local sw,sh=ctx.dimensions()
local baseU=ctx.scale()
local boxScale=ctx.boxScale()
local u=baseU*boxScale
local textScale=tonumber(ctx.dialogueTextScale) or 1
local baseSize=clamp(18*baseU,15,30)*textScale
local f=font(baseSize)
local glyphH=math.max(1,f:getHeight())
local padX=clamp(25*u,18,44)
local padY=clamp(14*u,10,26)
local cursorSpace=clamp(30*u,22,48)
local margin=clamp(18*u,12,40)
local maxW=math.min(sw-margin*2,math.max(460,sw*0.90))
local minW=math.min(maxW,clamp(350*u,290,540))

local full1=tostring(sourceLines[1] or ""):gsub("","")
local full2=tostring(sourceLines[2] or ""):gsub("","")
local fullCombined=full1
if full2~="" then fullCombined=(full1.." "..full2):gsub("%s+"," ") end





local maximumContent=math.max(1,maxW-padX*2-cursorSpace)
local joinRows=full2~="" and ctx.measure(f,fullCombined)<=maximumContent
local layoutSource={}
local layoutDraw={}
if joinRows then
layoutSource[1]=fullCombined
local a=tostring(lines[1] or ""):gsub("","")
local b=tostring(lines[2] or ""):gsub("","")
layoutDraw[1]=(b~="" and (a.." "..b) or a):gsub("%s+"," ")
else
layoutSource[1]=full1
layoutDraw[1]=tostring(lines[1] or ""):gsub("","")
if full2~="" then
layoutSource[2]=full2
layoutDraw[2]=tostring(lines[2] or ""):gsub("","")
end
end

if ctx.dialogueAllRows then
local function expand(rows)
local result={}
for _,row in ipairs(rows) do
for line in (tostring(row):gsub("\v","").."\n"):gmatch("(.-)\n") do result[#result+1]=line end
end
return result
end
local full,shown=expand(sourceLines),expand(lines)
layoutSource={};layoutDraw={}
for i,row in ipairs(full) do
local _,wrapped=f:getWrap(row,maximumContent)
local cursor=1;local revealed=#(shown[i] or '')
for _,part in ipairs(wrapped) do
local first=row:find(part,cursor,true) or cursor
layoutSource[#layoutSource+1]=part
layoutDraw[#layoutDraw+1]=part:sub(1,math.max(0,revealed-first+1))
cursor=first+#part
end
end
end
local rowLimit=ctx.dialogueAllRows and #layoutSource or 2
local drawSize=baseSize
local maxLineW=0
for i=1,math.min(rowLimit,#layoutSource) do
maxLineW=math.max(maxLineW,ctx.measure(f,layoutSource[i]))
end

local standardW=clamp(520*u,340,850)
local desiredW=math.max(standardW,maxLineW+padX*2+cursorSpace)
local w=clamp(desiredW,minW,maxW)
local contentW=math.max(1,w-padX*2-cursorSpace)



while maxLineW>contentW and drawSize>9 do
drawSize=drawSize-1
f=font(drawSize)
glyphH=math.max(1,f:getHeight())
maxLineW=0
for i=1,math.min(rowLimit,#layoutSource) do
maxLineW=math.max(maxLineW,ctx.measure(f,layoutSource[i]))
end
end

local lineGap=math.max(glyphH+clamp(4*baseU,3,8),math.ceil(glyphH*1.16))
local rows=math.max(1,math.min(rowLimit,#layoutSource))
local textBlockH=glyphH+math.max(0,rows-1)*lineGap
local minH=clamp(70*u,62,110)
local maxH=math.min(sh-margin*2,math.max(minH,sh*(ctx.dialogueAllRows and .65 or .30)))
local h=clamp(math.max(minH,textBlockH+padY*2),minH,maxH)
local x=(sw-w)*0.5
local reserve=P.bottomReserve(sw,sh,ctx)
local y
if P.isMobile() and not tonumber(ctx.dialogueBottomReserve) then

y=sh-h-reserve-clamp(4*u,3,8)
else
y=sh-h-clamp(18*u,13,34)-math.max(0,tonumber(ctx.dialogueLift) or 0)-reserve
end


y=math.max(margin,y)


y=y+(sh-y)*clamp(tonumber(ctx.dialogueSlide) or 0,0,1)

g.push("all")
g.origin()
consolePanel(x,y,w,h,u)

local color={0.88,0.90,0.82,1}
local textY=y+math.max(padY,(h-textBlockH)*0.5)
g.setScissor(
math.floor(x+padX-2),
math.floor(y+math.max(4,padY*0.45)),
math.floor(math.max(1,contentW+4)),
math.floor(math.max(1,h-math.max(8,padY*0.9)))
)
for i=1,math.min(rowLimit,#layoutDraw) do
text(layoutDraw[i],x+padX,textY+(i-1)*lineGap,drawSize,
color,"left",contentW)
end
g.setScissor()

if waiting and ((tonumber(frame) or 0)%60)<30 then
ctx.setUIColor("accent",0.90,0.23,0.13,1)
local cx=x+w-clamp(28*u,20,42)
local cy=y+h-clamp(19*u,14,30)
g.polygon("fill",cx,cy,cx+10*u,cy,cx+5*u,cy+7*u)
end
g.pop()
return {x=x,y=y,w=w,h=h,u=u}
end

function P.locationBanner(ctx,name,alpha)
local font,printText=ctx.font,ctx.text
local roundedRect=ctx.roundedRect
if not name or (alpha or 0)<=0 then return end
local G=ctx.g
local sw,sh=ctx.dimensions()
local uiScale=clamp(math.min(sw/1280,sh/720),0.72,1.75)
local textSize=clamp(math.floor(22*uiScale+0.5),15,34)
local textFont=font(textSize*ctx.textScale())
local textW=textFont and ctx.measure(textFont,name) or (#tostring(name)*textSize*0.55)
local padX=math.floor(34*uiScale+0.5)
local w=clamp(math.floor(textW+padX*2+0.5),math.floor(260*uiScale),math.floor(720*uiScale))
w=math.min(w,sw-math.floor(24*uiScale))
local h=clamp(math.floor(56*uiScale+0.5),44,88)
local x=math.floor((sw-w)*0.5+0.5)
local y=math.max(10,math.floor(18*uiScale+0.5))
local a=clamp(alpha,0,1)

G.push("all")
G.origin()



G.setColor(0.01,0.015,0.02,0.42*a)
roundedRect("fill",x+math.max(2,math.floor(3*uiScale)),
y+math.max(2,math.floor(4*uiScale)),w,h,math.max(7,math.floor(12*uiScale)))
ctx.setUIColor("surface",0.055,0.105,0.115,0.84*a)
roundedRect("fill",x,y,w,h,math.max(7,math.floor(12*uiScale)))
ctx.setUIColor("surface",0.025,0.045,0.050,0.72*a)
local inset=math.max(2,math.floor(4*uiScale))
roundedRect("fill",x+inset,y+inset,w-inset*2,h-inset*2,
math.max(5,math.floor(9*uiScale)))

ctx.setUIColor("trim",0.44,0.68,0.68,0.94*a)
G.setLineWidth(math.max(1.5,2*uiScale))
roundedRect("line",x+inset,y+inset,w-inset*2,h-inset*2,
math.max(5,math.floor(9*uiScale)))



G.setColor(0.20,0.62,0.57,0.78*a)
G.rectangle("fill",x+math.floor(20*uiScale),y+inset,
math.max(1,w-math.floor(40*uiScale)),math.max(1,math.floor(2*uiScale)))
G.pop()




local glyphH=textFont and textFont:getHeight() or textSize
local weight=ctx.textWeight()
local textX=x+(w-textW)*0.5-weight*0.5
local textY=y+(h-glyphH)*0.5-0.5
printText(name,textX,textY,textSize,{0.88,1.00,0.96,a})
end
function P.portraitPod(ctx,x,y,size,u)
local function polygon(...) ctx.g.polygon("fill",...) end
local g=ctx.g
local c=8*u

g.setColor(0,0,0,0.42)
polygon(
x+c+4*u,y+5*u,
x+size-c+4*u,y+5*u,
x+size+4*u,y+c+5*u,
x+size-c+4*u,y+size+5*u,
x+c+4*u,y+size+5*u,
x+4*u,y+size-c+5*u,
x+4*u,y+c+5*u
)

ctx.setUIColor("surface",0.08,0.095,0.095,1)
polygon(
x+c,y,
x+size-c,y,
x+size,y+c,
x+size-c,y+size,
x+c,y+size,
x,y+size-c,
x,y+c
)

ctx.setUIColor("trim",0.30,0.32,0.30,1)
polygon(
x+c+2*u,y+2*u,
x+size-c-2*u,y+2*u,
x+size-2*u,y+c,
x+size-c-2*u,y+size-2*u,
x+c+2*u,y+size-2*u,
x+2*u,y+size-c,
x+2*u,y+c
)

ctx.setUIColor("surface",0.035,0.045,0.045,1)
polygon(
x+c+5*u,y+5*u,
x+size-c-5*u,y+5*u,
x+size-5*u,y+c,
x+size-c-5*u,y+size-5*u,
x+c+5*u,y+size-5*u,
x+5*u,y+size-c,
x+5*u,y+c
)
end

function P.portraitPodOverlay(ctx,x,y,size,u)
local function polygon(...) ctx.g.polygon("fill",...) end
local g=ctx.g
local c=7*u



ctx.setUIColor("trim",0.18,0.20,0.19,1)
g.polygon("fill",
x,y+c, x+c,y, x+4*u,y+4*u, x+4*u,y+size-4*u,
x+c,y+size, x,y+size-c)
g.polygon("fill",
x+size,y+c, x+size-c,y, x+size-4*u,y+4*u,
x+size-4*u,y+size-4*u, x+size-c,y+size, x+size,y+size-c)


ctx.setUIColor("trim",0.30,0.32,0.30,1)
g.setLineWidth(math.max(1,2.2*u))
g.line(x+c,y+1*u, x+size-c,y+1*u)
g.line(x+c,y+size-1*u, x+size-c,y+size-1*u)


local i=3*u
local ic=4*u
g.setColor(0.025,0.030,0.030,1)
g.setLineWidth(math.max(1,1.8*u))
g.line(x+ic+i,y+i, x+size-ic-i,y+i)
g.line(x+size-ic-i,y+i, x+size-i,y+ic+i)
g.line(x+size-i,y+ic+i, x+size-i,y+size-ic-i)
g.line(x+size-i,y+size-ic-i, x+size-ic-i,y+size-i)
g.line(x+size-ic-i,y+size-i, x+ic+i,y+size-i)
g.line(x+ic+i,y+size-i, x+i,y+size-ic-i)
g.line(x+i,y+size-ic-i, x+i,y+ic+i)
g.line(x+i,y+ic+i, x+ic+i,y+i)


g.setColor(0.40,0.42,0.39,0.95)
g.setLineWidth(math.max(1,1.0*u))
g.line(x+c,y, x+size-c,y)
g.line(x,y+c, x,y+size-c)
g.line(x+size,y+c, x+size,y+size-c)
end

function P.genderGlyph(ctx,x,y,size,gender)
if gender~="male" and gender~="female" then return false end
local G=ctx.g
size=math.max(8,size or 10)
local r=size*0.24
local cx,cy=x+r,y+r
G.push("all")
G.setLineWidth(math.max(1.3,size*0.15))
if gender=="female" then
G.setColor(0.95,0.20,0.52,1)
G.circle("line",cx,cy,r)
G.line(cx,cy+r,cx,cy+r+size*0.34)
local yy=cy+r+size*0.22
G.line(cx-size*0.16,yy,cx+size*0.16,yy)
else
G.setColor(0.02,0.63,0.84,1)
G.circle("line",cx,cy,r)
local x2,y2=cx+r+size*0.28,cy-r-size*0.28
G.line(cx+r*0.65,cy-r*0.65,x2,y2)
G.line(x2-size*0.18,y2,x2,y2)
G.line(x2,y2,x2,y2+size*0.18)
end
G.pop()
return true
end

return P
