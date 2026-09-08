-- Render/service ownership must use encounter identity, never game identity.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local D=assert(loadfile(root..'/lib/doubles/Runtime.lua'))({mod={exports={}}})
local count=0
local function eq(a,b,k)count=count+1;assert(a==b,k..': '..tostring(a)..' ~= '..tostring(b))end
local game={}
local screen={game=game};local model={};local calls=0
local s={screen=screen,host=model,core={snapshot=function()calls=calls+1;return 'real doubles snapshot'end}}
D.byState[screen]=s;D.byState[model]=s;D.active=s
for _,value in ipairs({screen,model,{_view=screen},{_model=model},{battle=model}})do
 eq(D.session(value),s,'real battle/model/view association retained')
 eq(D.service.snapshot(value),'real doubles snapshot','real encounter receives its snapshot')
end
eq(D.session(),s,'explicit active-session API retained')
local singles={game=game,phase='messages',current={text='Will RED change POKeMON?'}}
for _,value in ipairs({singles,{game=game,battle=singles},{game=game,_view=singles},{game=game,forceSwitch=true}})do
 eq(D.session(value),nil,'unrelated singles/party state cannot inherit doubles')
 eq(D.combat(value),nil,'no doubles command owner for a single battle')
 eq(D.presentation(value),nil,'no four-actor presentation for a single battle')
 eq(D.service.snapshot(value),nil,'no doubles replacement picker for a single battle')
end
eq(calls,5,'rejected single-battle lookups never request a core snapshot')
eq(D.session({__gen3Source=screen}),s,'UI source adapter resolves exact encounter')
s.progressing=true
eq(D.combat(screen),nil,'native reward progression still suppresses doubles commands')
eq(D.presentation(screen),s,'native reward progression still retains arena actors')
s.progressing=nil;s.handoff=true
eq(D.combat(screen),nil,'native handoff still suppresses commands')
eq(D.presentation(screen),nil,'handoff presentation remains unchanged')
s.handoff=nil;s.closed=true
eq(D.combat(screen),nil,'closed session cannot command')
eq(D.presentation(screen),nil,'closed session cannot present')
D.byState[screen]=nil;D.byState[model]=nil;D.active=nil
eq(D.session(singles),nil,'clean transition remains single');eq(D.service.snapshot(),nil,'no snapshot after cleanup')
print('DoublesEncounterIsolationTests: '..count..' assertions passed')
