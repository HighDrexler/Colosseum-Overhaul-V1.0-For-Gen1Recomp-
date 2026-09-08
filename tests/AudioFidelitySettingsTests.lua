-- The actual settings controller for both generations; no renderer is installed.
local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local function loadMod(p,v)return assert(loadfile(root..'/'..p))(v)end
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function find(rows,prefix)
 for _,row in ipairs(rows)do if row.label:sub(1,#prefix)==prefix then return row end end
 error('missing row '..prefix)
end
local Menu={new=function(game,rows,opts)return {game=game,rows=rows,opts=opts,clampScroll=function()end}end}
package.loaded['src.ui.Menu']=Menu
package.loaded['src.ui.Screens']={push=function()error('must preserve original parent')end}
love={system={getOS=function()return 'Android'end}}
for generation=1,2 do
 local F=loadMod('lib/AudioFidelity.lua');local hook;local store={['assets/audio/old.wav']='KEEP', ['models/shiny']='KEEP SHINY'}
 local writes,removed=0,0
 local mod={cache={},hooks={wrap=function(_,name,fn)check(name=='ui.start_menu.items','native hook');hook=fn end}}
 function mod.cache:read(p)return store[p]end
 function mod.cache:write(p,b)writes=writes+1;store[p]=b;return true end
 function mod.cache:delete(p)removed=removed+1;store[p]=nil;return true end
 local S=loadMod('lib/BattleSettings.lua')
 local parent={screenId=generation==2 and 'Gen2StartMenu' or 'StartMenu'}
 local game={save={colosseumBattle={music='miror_b',doubleBattlesEnabled=false,abilitiesEnabled=false,cameraEnabled=false,battleSoundsEnabled=false}},stack={states={parent}}}
 function game.stack:top()return self.states[#self.states]end
 function game.stack:push(s)self.states[#self.states+1]=s end
 function game.stack:pop()return table.remove(self.states)end
 local mark={mark=function(p,title,rows)p.title=title;p.rows=rows end}
 check(S.install(mod,nil,nil,nil,mark,nil,nil,{current=function()return generation end},F),'install')
 local native={{label='POKEMON'},{label='OPTION'}}
 local rows=hook(function(_,a)return a end,game,native)
 find(rows,'BATTLE').onSelect()
 local main=game.stack:top()
 check(main.screenId=='CbeBattleSettings','native entry opens settings')
 check(game.stack.states[1]==parent,'generation parent retained')
 check(find(main.rows,'BATTLE SOUNDS').label=='BATTLE SOUNDS  ORIGINAL','original cue preference retained')
 local row=find(main.rows,'AUDIO FIDELITY');row.onSelect();local menu=game.stack:top()
 check(menu.title=='AUDIO FIDELITY' and #menu.rows==8,'dedicated quality screen')
 check(menu.rows[1].label=='NEW RENDERS: AUTO (FAST)','mobile default fast')
 check(writes==0 and removed==0,'merely opening menus never renders, writes or removes audio')
 menu.rows[1].onSelect();check(F.preference(mod)=='high','explicit HIGH stored')
 check(not F.pending(mod),'preference does not implicitly regenerate soundtrack')
 check(writes==1,'only the installation preference written')
 menu.rows[2].onSelect();check(not F.pending(mod),'first apply press only arms confirmation')
 check(menu.rows[2].label=='CONFIRM UPDATE ON NEXT LAUNCH','clear restart confirmation')
 menu.rows[2].onSelect();check(F.pending(mod)=='high','second press queues requested quality')
 check(row.label=='AUDIO FIDELITY  UPDATE QUEUED','parent row refreshed')
 check(menu.rows[4].label=='HIGH UPDATE QUEUED - RESTART GAME','restart instruction visible')
 check(writes==2,'queue request is sole extra write')
 menu.rows[3].onSelect();check(not F.pending(mod),'cancel clears pending only')
 check(store['assets/audio/old.wav']=='KEEP' and store['models/shiny']=='KEEP SHINY','no live cache replacement or unrelated deletion')
 menu.rows[2].onSelect();menu.rows[1].onSelect()
 check(F.preference(mod)=='fast' and not F.pending(mod),'changing quality disarms confirmation')
 check(menu.rows[2].label=='APPLY / RESUME ON NEXT LAUNCH','reconfirmation required after quality change')
 menu.rows[2].onSelect();menu.rows[2].onSelect();check(F.pending(mod)=='fast','FAST can restore old rendering on request')
 menu.rows[3].onSelect();menu.rows[1].onSelect();check(F.preference(mod)=='auto','preference cycle closes')
 local reloaded=loadMod('lib/AudioFidelity.lua');check(reloaded.preference(mod)=='auto','preference survives module reload')
 check(game.save.colosseumBattle.music=='miror_b' and game.save.colosseumBattle.doubleBattlesEnabled==false
  and game.save.colosseumBattle.abilitiesEnabled==false and game.save.colosseumBattle.cameraEnabled==false
  and game.save.colosseumBattle.battleSoundsEnabled==false,'all explicit saved choices retained')
 check(game.save.colosseumBattle.audioQuality==nil,'quality not placed in game save')
 game.stack:pop();menu.rows[8].onSelect();check(game.stack:top()==main,'BACK retains live parent settings')
 local oldWrite=mod.cache.write
 function mod.cache:write()return false,'storage fixture'end
 row.onSelect();menu=game.stack:top();menu.rows[1].onSelect()
 check(F.preference(mod)=='auto' and menu.rows[4].label:find('write failed',1,true),'preference failure visible without changing active value')
 mod.cache.write=oldWrite
 check(S.status(game).audioFidelity.effective=='fast','exported status reflects mobile resolution')
end
print('AudioFidelitySettingsTests: '..checks..' assertions passed')
