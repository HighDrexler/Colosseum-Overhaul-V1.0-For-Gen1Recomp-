-- Headless checks of the carried-forward portrait cache and Gen I submenu hook.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local count=0
local function eq(a,b,k) count=count+1;assert(a==b,k..': '..tostring(a)..' ~= '..tostring(b)) end
local function yes(a,k) count=count+1;assert(a,k) end
local quadCalls,drawCalls=0,0
local lastDraw
love={graphics={setColor=function() end,newQuad=function(...)
 quadCalls=quadCalls+1;return {...}
end,draw=function(...) drawCalls=drawCalls+1;lastDraw={...} end}}
local hidden=true
local bounds=assert(loadfile(root..'/assets/portrait_bounds.lua'))()
local C=assert(loadfile(root..'/lib/UIVisualCache.lua'))({bounds=bounds,hideDexAction=function() return hidden end})
local paths={'assets/portraits/025_1.png','assets/portraits/144_1.png','assets/portraits/006_1.png',
 'assets/portraits/094_1.png','assets/portraits/042_1.png','assets/portrait_corrections/139.png',
 'assets/portrait_corrections/139_shiny.png','assets/portrait_corrections/141.png','assets/portrait_corrections/141_shiny.png'}
for _,path in ipairs(paths) do
 local image={getDimensions=function() return 48,48 end}
 C.registerPortrait(image,path)
 local rect=bounds[path];yes(rect~=nil,'crop bounds packaged for '..path)
 for i=1,1000 do yes(C.drawPortrait(image,10,20,60,60),'portrait draw succeeds') end
 eq(lastDraw[1],image,'source image unchanged');eq(lastDraw[6],lastDraw[7],'aspect ratio preserved')
 yes(lastDraw[3]>=10 and lastDraw[4]>=20,'portrait inside destination')
end
eq(quadCalls,#paths,'one quad per image, not per frame')
eq(drawCalls,#paths*1000,'all draws recorded')
eq(C.status().quadBuilds,#paths,'reported cache allocations')
local nativeCalls,actionCalls=0,0
local state={__gen3uiPokedexAction=true,index=2,onSelect=function() actionCalls=actionCalls+1 end,
 draw=function(self,extra) nativeCalls=nativeCalls+1;return extra end}
yes(C.bindDexAction(state),'instance draw is wrapped')
local wrapper=state.draw
yes(C.bindDexAction(state),'binding is idempotent');eq(state.draw,wrapper,'does not layer wrappers')
state:draw('hidden');eq(nativeCalls,0,'native submenu hidden when replacement enabled')
state.onSelect();eq(actionCalls,1,'native action unchanged');eq(state.index,2,'native selection unchanged')
hidden=false;eq(state:draw('visible'),'visible','native result restored');eq(nativeCalls,1,'native fallback draws')
-- Simulate native chooseEntry assigning its instance draw after Menu.new.
local top=nil
local class={onChoose=function(item,list)
 top={__gen3uiPokedexAction=true,draw=function() nativeCalls=nativeCalls+1 end,item=item}
 return 'native-return',nil,7
end}
yes(C.wrapDexChoose(class),'bind completed onChoose')
local bound=class.onChoose;eq(C.wrapDexChoose(class),false,'class bind idempotent');eq(class.onChoose,bound,'one class hook')
local list={game={stack={top=function() return top end}}}
hidden=true
local a,b,c=class.onChoose({value='BULBASAUR'},list)
eq(a,'native-return','native first return');eq(b,nil,'nil return preserved');eq(c,7,'native trailing return')
eq(top.item.value,'BULBASAUR','chosen species unchanged');top:draw();eq(nativeCalls,1,'late-assigned draw suppressed')
hidden=false;top:draw();eq(nativeCalls,2,'late-assigned native fallback restored')
local plain={draw=function() nativeCalls=nativeCalls+1 end};eq(C.bindDexAction(plain),false,'unrelated menu untouched')
print('UIVisualCacheTests: '..count..' assertions passed; '..quadCalls..' quads for '..drawCalls..' draws')
