-- Test-only launcher for LuaJIT/Lua 5.1. The engine's mod loader accepts string
-- chunks through load(); stock Lua 5.1 calls that loadstring(). No fake FFI.
local nativeLoad=load
load=function(chunk,name,mode,env)
 local f,e
 if type(chunk)=='string' then f,e=loadstring(chunk,name) else f,e=nativeLoad(chunk,name)end
 if f and env then setfenv(f,env)end
 return f,e
end
unpack=unpack or table.unpack
bit=require('bit')
-- Existing geometry fixtures use Lua 5.3 string.pack to emulate love.data.pack.
-- Supply ONLY their documented float32 formats using real LuaJIT FFI storage.
-- Reject unsupported formats rather than returning synthetic packed bytes.
if not string.pack then
 local ffi=require('ffi')
 string.pack=function(fmt,...)
  assert(ffi.abi('le'),'test float32 packing requires little endian')
  local fields=fmt:gsub('^<','')
  assert(fields:match('^f+$') and #fields==select('#',...),'unsupported test pack format: '..fmt)
  local a=ffi.new('float[?]',#fields)
  for i=1,#fields do a[i-1]=select(i,...)end
  return ffi.string(a,#fields*4)
 end
end
local target=arg[1];arg={[0]=target}
assert(loadfile(target))()
