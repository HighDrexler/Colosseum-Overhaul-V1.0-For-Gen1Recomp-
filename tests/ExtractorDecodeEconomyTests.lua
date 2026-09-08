local checks=0;local function eq(a,b,l)checks=checks+1;assert(a==b,l..': '..tostring(a)..' ~= '..tostring(b))end
local single={vertexCount=3};local scene={vertexCount=6};local nc,sc=0,0
local H={extractModel=function()nc=nc+1;return single end,extractSceneModel=function()sc=sc+1;return scene end}
local P=assert(loadfile('extract/PokemonExtractor.lua'))({HSD=H,FSYS={},ColosseumDex={}})
local function decode(mode)return P._test.decodeBest('fixture',0,0,false,nil,nil,mode)end
for i=1,100 do eq(decode('auto'),single,'same preferred geometry')end
eq(nc,100,'one character decode per pose');eq(sc,0,'discarded scene path not decoded')
eq(decode('scene'),scene,'forced scene preserved');eq(nc,100,'forced scene avoids discarded single');eq(sc,1,'one forced scene decode')
eq(decode('single'),single,'forced single preserved');eq(sc,1,'forced single no scene cost')
single=nil;eq(decode('auto'),scene,'failed single falls back to scene');eq(sc,2,'fallback executed')
single={vertexCount=3};scene=nil;eq(decode('scene'),single,'failed scene falls back to single')
single={vertexCount=0};scene={vertexCount=6};eq(decode('auto'),scene,'empty single does not swallow source scene')
print('ExtractorDecodeEconomyTests: '..checks..' checks passed')
