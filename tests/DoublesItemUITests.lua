-- Paired bridge input tests; no native UI/party/inventory mutators are available.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local n=0
local function eq(a,b,tag)n=n+1;assert(a==b,tag..': '..tostring(a)..' ~= '..tostring(b))end
local function yes(a,tag)n=n+1;assert(a,tag)end
local function copy(t)local c={};for k,v in pairs(t)do c[k]=type(v)=='table' and copy(v) or v end;return c end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local calls={};local reject=false
local api={version=1,submit=function(req)calls[#calls+1]=req;if reject then return false,'It will have no effect.'end;return true end}
-- Colosseum Overhaul merge: DoublesUI.lua's service() now reads
-- T.mod.exports.doubles directly (CBE and the paired UI are the same mod).
local U=assert(loadfile(root..'/lib/DoublesUI.lua'))({mod={exports={doubles=api},find=function()return {exports={doubles=api}}end}})
local C=assert(loadfile(root..'/lib/DoublesDisplayCompat.lua'))()
for gen=1,2 do
 local s={battleId='items-'..gen,ticket=10,turn=5,phase='command',commandSlot='player-right',battlerId='player-3',generation=gen,
  itemApiVersion=1,limitations={bag=true},items={},party={},slots={{id='player-left',partyIndex=5,side='player',position=1},{id='player-right',partyIndex=3,side='player',position=2}},moves={}}
 for i=1,14 do s.items[i]={id='ITEM_'..i,name='ITEM '..i,count=3,available=3,target='party'}end
 s.items[1]={id='POTION',name='Potion',count=1,available=0,reserved=1,target='party'}
 s.items[2]={id='ETHER',name='Ether',count=3,available=3,target='party',moveRequired=true}
 s.items[3]={id='X_ATTACK',name='X Attack',count=1,available=1,target='active-player'}
 for i=1,6 do s.party[i]={index=i,name='Mon '..i,active=i==3 or i==5,hp=i==2 and 0 or 30,maxHP=100,egg=i==6,moves={{index=1,id='A',name='A',pp=5,maxPP=5},{index=2,id='B',name='B',pp=0,maxPP=15}},display={species='A',moves={}}}end
 local before=copy(s);local u=U._test.state(s)
 eq(U._test.rows(s,u)[3].enabled,true,'Bag button enabled')
 u.index=3;U.input(api,s,{a=true});eq(u.page,'bag','open Bag')
 U.input(api,s,{a=true});eq(u.page,'bag','reserved item cannot advance');yes(u.error:find('Reserved',1,true),'reservation reason')
 U.input(api,s,{right=true});eq(u.index,7,'page forward six');local off,visible=U.bagWindow(s,u);eq(off,1,'scroll retains six rows');eq(visible,6,'six visible')
 U.input(api,s,{right=true});eq(u.index,13,'second page');off,visible=U.bagWindow(s,u);eq(off,7,'selected item visible')
 U.input(api,s,{down=true});eq(u.index,14,'last item');U.input(api,s,{down=true});eq(u.index,14,'bounded bottom')
 U.input(api,s,{left=true});eq(u.index,8,'page backward six')
 u.index=2;U.input(api,s,{a=true});eq(u.page,'item-party','PP item target selection');eq(u.index,3,'current command owner preferred')
 U.input(api,s,{a=true});eq(u.page,'item-moves','PP move selector');eq(u.index,2,'first depleted move preferred')
 local rows=U._test.rows(s,u);eq(rows[1].enabled,false,'full PP visually disabled');eq(rows[2].enabled,true,'depleted move enabled')
 local count=#calls;U.input(api,s,{b=true});eq(u.page,'item-party','back restores recipient');eq(u.index,3,'recipient index retained');eq(#calls,count,'back does not submit')
 U.input(api,s,{a=true});U.input(api,s,{a=true});local req=calls[#calls]
 eq(req.kind,'item','controller item request');eq(req.item,'ETHER','item identity');eq(req.partyIndex,3,'original party index');eq(req.moveIndex,2,'PP target index')
 eq(req.battleId,s.battleId,'battle identity');eq(req.battlerId,s.battlerId,'actor identity');eq(req.ticket,10,'ticket identity');eq(req.turn,5,'turn identity');eq(req.slot,'player-right','second command actor')
 -- No-effect rejection stays in the item flow, without consuming inventory.
 reject=true;U.input(api,s,{a=true});eq(u.page,'item-moves','rejection preserves PP picker');eq(u.error,'It will have no effect.','native reason retained');reject=false
 U.input(api,s,{b=true});U.input(api,s,{b=true});eq(u.page,'bag','back to Bag');eq(u.index,2,'Bag selection retained')
 u.index=3;U.input(api,s,{a=true});u.index=1;count=#calls;U.input(api,s,{a=true});eq(#calls,count,'stat item rejects bench');yes(u.error~=nil,'active target error')
 u.index=5;U.input(api,s,{a=true});eq(calls[#calls].partyIndex,5,'stat item can target active partner')
 u.page='bag';u.index=4;U.input(api,s,{a=true});u.index=2;U.input(api,s,{a=true});eq(calls[#calls].partyIndex,2,'fainted recipient reaches native item validation')
 u.index=6;count=#calls;U.input(api,s,{a=true});eq(#calls,count,'Egg blocked')
 yes(same(s,before),'UI never mutates authoritative snapshot')
 -- A revised actor/ticket invalidates all retained targeting state.
 s.ticket=11;s.battlerId='new-owner';U.input(api,s,{});eq(u.page,'commands','new ticket resets page');eq(u.item,nil,'item cleared');eq(u.itemPartyIndex,nil,'recipient cleared');eq(u.error,nil,'old error cleared')
 u.index=3;s.itemApiVersion=nil;U.input(api,s,{a=true});eq(u.page,'commands','old bridge never enters unsupported Bag');yes(u.error~=nil,'old producer message')
 s.itemApiVersion=1;s.items={};U.input(api,s,{a=true});eq(u.page,'bag','empty Bag opens');U.input(api,s,{a=true});yes(u.error:find('No usable',1,true),'empty Bag explains');U.input(api,s,{b=true});eq(u.page,'commands','empty Bag exits');eq(u.index,3,'Bag command highlight')
 s.phase='replace';s.ticket=12;U.input(api,s,{b=true});eq(u.page,'party','forced replacement cannot escape')
end
for _,sample in ipairs({'Text.{PROMPT}','Text.{prompt}','Text.{PrOmPt}','Text.{DONE}'})do eq(U._test.clean(sample),'Text.','control token hidden')end
eq(U._test.clean('A prompt remains an ordinary word'),'A prompt remains an ordinary word','ordinary prose retained')
-- Sanitize shared Gen1/Gen2 message adapter too; execute its actual function.
-- Colosseum Overhaul merge: the paired UI's main.lua now ships as UIMain.lua
-- (this merged mod's own main.lua is CBE's original file, verbatim, with a
-- small bootstrap appended -- see main.lua's own trailing comment).
local f=assert(io.open(root..'/UIMain.lua','rb'));local src=f:read('*a');f:close()
local block=assert(src:match('(function GoldCompat%.cleanBattleText%(value%).-\nend)\n\nlocal function messageLinesForBattle'))
local env={GoldCompat={},tostring=tostring};local fn=assert(loadstring(block));setfenv(fn,env);fn()
eq(env.GoldCompat.cleanBattleText('Yes{PROMPT}\nNo{DONE}'),'Yes\nNo','shared sanitation retains line breaks')
for _,size in ipairs({{1280,720},{1920,1080},{568,320},{390,844}})do
 local l=U.layout(size[1],size[2],'bag',size[1]<640)
 yes(l.menu.x>=0 and l.menu.y>=0,'Bag nonnegative');yes(l.menu.x+l.menu.w<=size[1] and l.menu.y+l.menu.h<=size[2],'Bag inside window')
end
print('DoublesItemUITests: '..n..' assertions passed')
