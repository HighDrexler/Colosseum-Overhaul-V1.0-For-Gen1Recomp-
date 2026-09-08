local root=assert(os.getenv('CBE_MOD_ROOT'),'set CBE_MOD_ROOT')
local engine=assert(os.getenv('CBE_ENGINE_ROOT'),'set CBE_ENGINE_ROOT')
local output=assert(os.getenv('CBE_RENDER_OUT'),'set CBE_RENDER_OUT to an existing output directory')
package.path=engine..'/?.lua;'..engine..'/?/init.lua;'..package.path
local function M(p,v)return assert(loadfile(root..'/'..p))(v)end
local gen=tonumber(os.getenv('CBE_VIEW_GEN')) or 1
local Game=require(gen==1 and 'src.core.Game' or 'src.core.Game2');local Renderer=require('src.render.Renderer')
local Stack=require('src.core.StateStack');local Runtime=require('src.mods.Runtime');local Hooks=require('src.mods.Hooks')
local hook=Hooks.new();Runtime.install({emit=function()end},hook,{})
local stack=setmetatable({},{__index=Stack});stack:init()
local game=setmetatable({phase='boot',options={},data={pokemon={}},stack=stack,save={options={}},input={wasPressed=function()return false end}},{__index=Game})
local V={mod={hooks=hook},engineRequire=require,CacheScreen=M('lib/CacheScreen.lua'),
 WorkBudget=M('lib/WorkBudget.lua'),PokemonActors={prepareSessionModel=function()return true end},
 GenerationCompat={current=function()return gen end},
 ModelIdentity={resolve=function()return 25,'normal'end}}
local C=M('lib/BattleCache.lua',V)
-- Use the actual native Game.draw/Renderer palette pipeline and the shipped
-- post-palette HUD function. No ROM, no loading task, no game data required.
local context=os.getenv('CBE_CACHE_CONTEXT') or 'manual'
local request=context~='manual' and {save={},newGame=context=='new',onDone=function()error('render-only probe must never load a game')end} or nil
C.openMenu(game,{},request)
hook:wrap('render.hud',C.drawHud,20000)
function love.load()
 Renderer:init()
 require('src.core.TouchControls').enabled=false
end
local n=0
function love.draw()
 Game.draw(game)
 n=n+1
 if n==2 then
  love.graphics.captureScreenshot(function(data)
   local f=assert(io.open(output..'/native-gen'..gen..'-'..context..'-choice.png','wb'));f:write(data:encode('png'):getString());f:close()
   print('PASS real native generation '..gen..' Game.draw + post-palette cache HUD')
   love.event.quit()
  end)
 end
end
function love.errorhandler(msg)print(debug.traceback(msg,2));os.exit(1)end
