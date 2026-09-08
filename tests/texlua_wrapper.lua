-- Test-only Lua 5.3 compatibility wrapper; not loaded by the mod.
unpack=unpack or table.unpack
loadstring=loadstring or load
math.atan2=math.atan2 or function(y,x)return math.atan(y,x)end
package.preload.bit=package.preload.bit or function()
 local function fold(op,a,...) for i=1,select('#',...)do a=op(a,select(i,...))end return a end
 return {band=function(a,...)return fold(function(x,y)return x&y end,a,...)end,
 bor=function(a,...)return fold(function(x,y)return x|y end,a,...)end,
 bxor=function(a,...)return fold(function(x,y)return x~y end,a,...)end,
 bnot=function(a)return (~a)&0xffffffff end,lshift=function(a,b)return (a<<b)&0xffffffff end,
 rshift=function(a,b)return (a&0xffffffff)>>b end,arshift=function(a,b)if a>=0x80000000 then a=a-0x100000000 end;return math.floor(a/2^b)end,
 tobit=function(a)a=a&0xffffffff;return a>=0x80000000 and a-0x100000000 or a end}
end
bit=require('bit')
function setfenv(fn,env)
 local i=1
 while true do
  local name=debug.getupvalue(fn,i)
  if not name then break end
  if name=='_ENV' then debug.upvaluejoin(fn,i,function()return env end,1);break end
  i=i+1
 end
 return fn
end
local target=arg[1];arg={[0]=target}
assert(loadfile(target))()
