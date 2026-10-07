


local F={version=1}
local attached=setmetatable({}, {__mode="k"})
local unpackArgs=table.unpack or unpack
local function top(game)
if game and game.stack and type(game.stack.top)=="function" then return game.stack:top() end
end
local function pack(...) return {n=select("#",...),...} end
function F.attach(game,callback)
if type(game)~="table" or type(game.update)~="function" then return false end
local old=attached[game]
if old and game.update==old.wrapper then old.callback=callback;return true end
local inner=game.update
local row={callback=callback}
row.wrapper=function(self,dt,...)


local nested=self.__cbeAssetUpdateDepth or 0
self.__cbeAssetUpdateDepth=nested+1
local before=top(self)
local result=pack(pcall(inner,self,dt,...))
self.__cbeAssetUpdateDepth=nested
if not result[1] then error(result[2],0) end
if nested==0 then
local ok,err=pcall(row.callback,self,before,top(self),dt)
if not ok then self.__cbeAssetUpdateError=tostring(err) end
end
return unpackArgs(result,2,result.n)
end
game.update=row.wrapper;attached[game]=row
return true
end
function F.active(game) return game and (game.__cbeAssetUpdateDepth or 0)>0 end
function F.attached(game) return attached[game]~=nil end
function F.isOverworld(game,state)
if state then return state.isOverworld==true end

return game and game.phase=="play" and game.world and game.world.map~=nil or false
end
return F
