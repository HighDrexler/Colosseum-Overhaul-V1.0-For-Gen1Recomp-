local root=os.getenv('UI_COMPAT_DIR') or '.'
local n=0;local function eq(a,b,k)n=n+1;assert(a==b,k..': '..tostring(a)..' ~= '..tostring(b))end
local widthCalls,inkCalls=0,0
local font={getWidth=function(_,s)widthCalls=widthCalls+1;return #s*7 end,getHeight=function()return 12 end}
local U=assert(loadfile(root..'/lib/DoublesUI.lua')){mod={},inkMetrics=function(_,s)inkCalls=inkCalls+1;return 10,2 end}
local w,h,t;for i=1,1000 do w,h,t=U._test.textMetrics(font,'THUNDERBOLT')end
eq(w,77,'width after 1000 reads');eq(h,10,'ink height');eq(t,2,'ink offset')
eq(widthCalls,1,'width measured once');eq(inkCalls,1,'ink scan once')
for i=1,1100 do U._test.textMetrics(font,'VARIANT '..i)end
eq(U.performanceStatus().metricResets,2,'text cache has hard bound')
local other={getWidth=function()return 99 end,getHeight=font.getHeight};local w=U._test.textMetrics(other,'THUNDERBOLT');eq(w,99,'font identity invalidates measurement')
local ev={kind='move',impacts={{kind='damage',slot='enemy-left',battlerId='old',previousHP=100,hp=60,elapsed=.2,duration=.5},
 {kind='damage',slot='enemy-right',battlerId='other',previousHP=80,hp=20,elapsed=.4,duration=.5}}}
eq(U.displayHP({battlerId='old',hp=60},ev),80,'left HP animates on impact')
eq(U.displayHP({battlerId='other',hp=20},ev),20,'right HP independent clock')
eq(U.displayHP({battlerId='new',hp=70},ev),70,'replacement never inherits old HP')
local consumed={kind='damage',presentationConsumed=true,previousHP=100,elapsed=0,duration=0}
eq(U.displayHP({hp=60},consumed),60,'queued bookkeeping does not refill or replay bar')
local s={phase='present',presentation=ev,slots={}}
local seen=U.visibility(s,'commands');eq(seen['enemy-left'],true,'left impact HUD visible');eq(seen['enemy-right'],true,'right impact HUD visible')
eq(seen['player-left'],nil,'unrelated HUD not introduced')
print('DoublesPerformanceUITests: '..n..' assertions passed')
