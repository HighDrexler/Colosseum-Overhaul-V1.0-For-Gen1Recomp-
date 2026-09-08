local files={['build/stage_movefx.complete']='ok',['build/movefx_coverage.txt']='source coverage'}
local function index(revision)
 local rows={};for id=1,251 do rows[#rows+1]=(' [%d]={stem="m%d"},'):format(id,id);files['cache/movefx/m'..id..'/effect.lua']='return {}' end
 files['cache/movefx/index.lua']='return {revision='..revision..',wazaRevision=12,total=251,ready=251,missing=0,fullVisualReady=200,moves={'..table.concat(rows)..'}}'
end
local mod={cache={read=function(_,path)return files[path]end,info=function(_,path)if files[path] then return {type='file'} end end}}
local soundReady=true
local B=assert(loadfile('extract/BuildPipeline.lua'))({MoveFXExtractor={revision=30},WazaSequenceExtractor={revision=12},WazaSfxBuilder={ready=function()return soundReady end}})
index(30)
assert(B.moveFxCacheReady(mod),'current complete source cache triggers full rebuild')
assert(not B.moveFxReady(mod),'partial visual coverage falsely marked full parity')
files['cache/movefx/m53/effect.lua']=nil
assert(not B.moveFxCacheReady(mod),'missing move cache incorrectly reused')
index(29);assert(not B.moveFxCacheReady(mod),'old extractor revision incorrectly reused')
index(30);soundReady=false;assert(not B.moveFxCacheReady(mod),'missing source audio incorrectly reused')
print('MoveFXCacheReuseTests: OK')
