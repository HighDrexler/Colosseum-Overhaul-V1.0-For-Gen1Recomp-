

local P={}
function P.decode(bytes,w,h,path)
local label='packaged RGBA '..tostring(path)
if not(type(w)=='number'and type(h)=='number'and w>=1 and h>=1
and w<=4096 and h<=4096 and w%1==0 and h%1==0)then
return nil,label..': invalid dimensions'
end
if type(bytes)~='string'then return nil,label..': missing package asset'end
local expected=w*h*4
if #bytes~=expected then
local decompress=love and love.data and love.data.decompress
if type(decompress)~='function'then return nil,label..': zlib decoder unavailable'end
local ok,decoded=pcall(decompress,'string','zlib',bytes)
if not(ok and type(decoded)=='string')then
return nil,label..': invalid compressed RGBA ('..tostring(decoded)..')'
end
bytes=decoded
end
if #bytes~=expected then
return nil,('%s: expected %d RGBA bytes, got %d'):format(label,expected,#bytes)
end
return bytes
end
function P.read(mod,path,w,h)
if not(mod and type(mod.read)=='function')then return nil,'package reader unavailable: '..tostring(path)end
local ok,bytes,why=pcall(mod.read,mod,path)
if not ok or bytes==nil then return nil,'packaged RGBA '..tostring(path)..': '..tostring(ok and why or bytes or 'missing package asset')end
return P.decode(bytes,w,h,path)
end
return P
