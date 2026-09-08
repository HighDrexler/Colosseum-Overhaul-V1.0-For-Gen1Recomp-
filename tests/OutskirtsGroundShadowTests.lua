local R=assert(loadfile('lib/Arena.lua'))({})
local B=assert(loadfile('extract/ArenaBuilder.lua'))({})
local n=0;local function eq(a,b,l)n=n+1;assert(a==b,l)end
-- Measured min/max raw source Y of the six S1_out_bf shadow groups. All
-- surrounding architecture and actor placement remain authored coordinates.
local bounds={{.165515,1.996094},{.167969,2.056143},{.242188,.242188},{.120321,.120321},{.120321,.120321},{.120321,.120321}}
local function fixture(lo,hi)return {xlu=true,noz=true,vertices={{0,lo,0},{1,hi,0},{0,lo,1}}}end
local function check(g,id,want,label)
 local direct=R._test.dropGhostLayer(g,id);local packed=B._test.runtimeDropGhost(g,id)
 eq(direct,want,label..' direct visibility');eq(packed,want,label..' packed visibility');eq(direct,packed,label..' route parity')
end
for i,b in ipairs(bounds)do
 local g=fixture(b[1],b[2]);check(g,'outskirts',false,'source shadow '..i)
 for _,id in ipairs({'water','relic_chamber','deep_colosseum','realgam_colosseum'})do check(g,id,true,'unverified venue '..id)end
end
-- The two T1_ancient_colo ground shadows measured at the same floor height.
for i,b in ipairs({{.499973,.499975},{.499973,.499975}})do
 local g=fixture(b[1],b[2]);check(g,'orre_colosseum',false,'Orre source shadow '..i)
 for _,id in ipairs({'water','relic_chamber','deep_colosseum','realgam_colosseum'})do check(g,id,true,'unverified venue '..id)end
end
for _,id in ipairs({'outskirts','orre_colosseum'})do
 check(fixture(0,3.01),id,true,'raised helper still rejected '..id)
 check(fixture(-.11,1),id,true,'below-floor helper still rejected '..id)
 check({xlu=true,noz=true,vertices={}},id,true,'missing geometry never admitted '..id)
 local solid=fixture(0,30);solid.xlu=false;check(solid,id,false,'ordinary solid geometry unchanged '..id)
end
print('OutskirtsGroundShadowTests: '..n..' assertions passed')
