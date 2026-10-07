

local V=...
local req=V.engineRequire or require
local M={}
function M.release()
if M.active then for _,v in ipairs(M.active.rows) do if v.actor then v.actor:release() end end end
M.active=nil
if V.PokemonActors.cancelInformation then V.PokemonActors.cancelInformation() end
end
function M.pump(dt)
local a=M.active;if not a then return end
if not a.native.open or a.native._mon~=a.mon then M.release();return end
local A=V.PokemonActors
for i,v in ipairs(a.rows) do
if not v.actor and not v.error then
local ready,why,pending=A.pumpInformation(v.game,v.battler,'body')
if ready then
v.actor,v.error=A.acquireCached('cbe-evolution-'..i,v.dex,v.variant,
{context={game=v.game,arena={figureScale=1},services={informationSurface=true}},battler=v.battler,noSource=true})
if v.actor then v.actor.worldScale=18/math.max(.1,v.actor.height or 16);v.framingScale=v.actor.worldScale;v.actor:spawn(1);v.actor:idle() end
elseif not pending and why then v.error=tostring(why) end
if not v.actor then break end
end
end
a.ready=a.rows[1].actor~=nil and a.rows[2].actor~=nil
for _,v in ipairs(a.rows) do if v.actor then v.actor:update(dt or 0) end end
end
function M.draw(c,N)
local a=M.active;if not a or a.native~=N then return false end
local pre={fade_in=true,intro_msg=true,intro_cry=true,intro_sound=true,start_music=true,cancel=true}
local indices=pre[N._state] and {1} or N._state=='cycle' and {1,2} or {2}
local U=V.Gen3UI;local previous=U.viewer
for _,i in ipairs(indices) do
local v=a.rows[i];local scale=N._state=='cycle' and (i==1 and N._preScale or N._postScale) or 1
if v.actor and scale>.05 then
U.viewer=v;v.owner=N;v.silhouette=N._state=='cycle'
local originalScale=v.actor.worldScale;v.actor.worldScale=originalScale*scale
c.model(v.mon,66,9,108,99,N)
v.actor.worldScale=originalScale
end
end
U.viewer=previous
if not a.ready then
local failed=a.rows[1].error or a.rows[2].error
c.text(failed and 'MODEL COULD NOT LOAD' or 'PREPARING EVOLUTION MODELS',15,81,210,16,5.5)
if failed then c.text('B CANCEL',15,97,210,10,4) end
end
return true
end
function M.install()
if M.installed then return end
local N=req('src.ui.game3.evolution_scene');local start,update,input=N.start,N.update,N.handleInput
N.start=function(mon,target,opts)
M.release();local result=start(mon,target,opts)
if not result or N._headless or V.Gen3Runtime.prefs().menuModels==false
or not V.PokemonActors.pumpInformation or not V.PokemonActors.acquireCached then return result end
local a={native=N,mon=mon,rows={}};local game=V.Gen3Runtime.game or V.mod.game
for i,species in ipairs({N._preSpecies,N._postSpecies}) do
local copy={};for k,v in pairs(mon) do copy[k]=v end
copy.species=species;copy.speciesNumbering='internal'
local dex,variant=V.ModelIdentity.resolve(game,copy)
a.rows[i]={mon=copy,dex=dex,variant=variant,game=game,battler={mon=copy},noControls=true}
end
M.active=a;return result
end
N.update=function(dt,...)
if M.active then
local game=V.Gen3Runtime.game or V.mod.game;local speed=game and game.logicSpeed and game:logicSpeed() or 1
M.pump((dt or 1/60)/math.max(1,speed))
if M.active and not M.active.ready and N._state=='fade_in' then return end
end
local result=update(dt,...)
if M.active and not N.open then M.release() end
return result
end
N.handleInput=function(inp,...)
if M.active and not M.active.ready and N._state=='fade_in' and N._canStop and inp:wasPressed('b') then
N._state='cycle';N._speed=8
end
return input(inp,...)
end
M.installed=true
end
return M
