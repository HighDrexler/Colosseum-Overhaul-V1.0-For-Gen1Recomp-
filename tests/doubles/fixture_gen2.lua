local TYPES = {
  NORMAL = { id = "NORMAL", index = 0, category = "physical" },
  FIGHTING = { id = "FIGHTING", index = 1, category = "physical" },
  FLYING = { id = "FLYING", index = 2, category = "physical" },
  GROUND = { id = "GROUND", index = 4, category = "physical" },
  ROCK = { id = "ROCK", index = 5, category = "physical" },
  STEEL = { id = "STEEL", index = 9, category = "physical" },
  FIRE = { id = "FIRE", index = 20, category = "special" },
  WATER = { id = "WATER", index = 21, category = "special" },
  GRASS = { id = "GRASS", index = 22, category = "special" },
  ELECTRIC = { id = "ELECTRIC", index = 23, category = "special" },
  DARK = { id = "DARK", index = 27, category = "special" },
}

-- A slice of data/types/type_matchups.asm.
local MATCHUPS = {
  { attacker = "FIRE", defender = "GRASS", multiplier = 20 },
  { attacker = "FIRE", defender = "WATER", multiplier = 5 },
  { attacker = "FIRE", defender = "STEEL", multiplier = 20 },
  { attacker = "WATER", defender = "FIRE", multiplier = 20 },
  { attacker = "WATER", defender = "ROCK", multiplier = 20 },
  { attacker = "WATER", defender = "GROUND", multiplier = 20 },
  { attacker = "NORMAL", defender = "ROCK", multiplier = 5 },
  { attacker = "NORMAL", defender = "STEEL", multiplier = 5 },
  { attacker = "ELECTRIC", defender = "GROUND", multiplier = 0 },
  -- Sonic Boom is Normal; Gen 2 StaticDamage still respects Ghost immunity.
  { attacker = "NORMAL", defender = "GHOST", multiplier = 0 },
}

local MOVES = {
  TACKLE = { id = "TACKLE", name = "TACKLE", power = 35, type = "NORMAL",
    accuracy = 95, pp = 35, effect = "EFFECT_NORMAL_HIT" },
  EMBER = { id = "EMBER", name = "EMBER", power = 40, type = "FIRE",
    accuracy = 100, pp = 25, effect = "EFFECT_BURN_HIT", effectChance = 10 },
  WATER_GUN = { id = "WATER_GUN", name = "WATER GUN", power = 40,
    type = "WATER", accuracy = 100, pp = 25, effect = "EFFECT_NORMAL_HIT" },
  THUNDER_WAVE = { id = "THUNDER_WAVE", name = "THUNDERWAVE", power = 0,
    type = "ELECTRIC", accuracy = 100, pp = 20, effect = "EFFECT_PARALYZE" },
  QUICK_ATTACK = { id = "QUICK_ATTACK", name = "QUICK ATTACK", power = 40,
    type = "NORMAL", accuracy = 100, pp = 30,
    effect = "EFFECT_PRIORITY_HIT" },
  SPORE = { id = "SPORE", name = "SPORE", power = 0, type = "GRASS",
    accuracy = 100, pp = 15, effect = "EFFECT_SLEEP" },
  -- The status-shaped moves the effect layer models, at their real numbers.
  RAIN_DANCE = { id = "RAIN_DANCE", name = "RAIN DANCE", power = 0,
    type = "WATER", accuracy = 100, pp = 5, effect = "EFFECT_RAIN_DANCE" },
  SPIKES = { id = "SPIKES", name = "SPIKES", power = 0, type = "GROUND",
    accuracy = 100, pp = 20, effect = "EFFECT_SPIKES" },
  PERISH_SONG = { id = "PERISH_SONG", name = "PERISH SONG", power = 0,
    type = "NORMAL", accuracy = 100, pp = 5, effect = "EFFECT_PERISH_SONG" },
  TRANSFORM = { id = "TRANSFORM", name = "TRANSFORM", power = 0,
    type = "NORMAL", accuracy = 100, pp = 10, effect = "EFFECT_TRANSFORM" },
  ENDURE = { id = "ENDURE", name = "ENDURE", power = 0, type = "NORMAL",
    accuracy = 100, pp = 10, effect = "EFFECT_ENDURE" },
  RAGE = { id = "RAGE", name = "RAGE", power = 20, type = "NORMAL",
    accuracy = 100, pp = 20, effect = "EFFECT_RAGE" },
  -- data/moves/moves.asm:133, :230, :189 and :92 rows, unedited.
  BIDE = { id = "BIDE", name = "BIDE", power = 0, type = "NORMAL",
    accuracy = 100, pp = 10, effect = "EFFECT_BIDE" },
  SLEEP_TALK = { id = "SLEEP_TALK", name = "SLEEP TALK", power = 0,
    type = "NORMAL", accuracy = 100, pp = 10, effect = "EFFECT_SLEEP_TALK" },
  SNORE = { id = "SNORE", name = "SNORE", power = 40, type = "NORMAL",
    accuracy = 100, pp = 15, effect = "EFFECT_SNORE", effectChance = 30 },
  SOLARBEAM = { id = "SOLARBEAM", name = "SOLARBEAM", power = 120,
    type = "GRASS", accuracy = 100, pp = 10, effect = "EFFECT_SOLARBEAM" },
}

local GROWTH = {
  -- data/growth_rates.asm rows.
  GROWTH_MEDIUM_FAST = { numerator = 1, denominator = 1, squared = 0,
    linear = 0, constant = 0 },
  GROWTH_MEDIUM_SLOW = { numerator = 6, denominator = 5, squared = -15,
    linear = 100, constant = 140 },
  GROWTH_FAST = { numerator = 4, denominator = 5, squared = 0, linear = 0,
    constant = 0 },
  GROWTH_SLOW = { numerator = 5, denominator = 4, squared = 0, linear = 0,
    constant = 0 },
}

local POKEMON = {
  growthRates = GROWTH,
  CYNDAQUIL = {
    id = "CYNDAQUIL", index = 155, name = "CYNDAQUIL",
    baseStats = { hp = 39, attack = 52, defense = 43, speed = 65,
      specialAttack = 60, specialDefense = 50 },
    types = { "FIRE", "FIRE" }, catchRate = 45, baseExp = 65,
    growthRate = "GROWTH_MEDIUM_SLOW", genderRatio = 31,
    levelMoves = {
      { level = 1, move = "TACKLE" }, { level = 1, move = "LEER" },
      { level = 6, move = "SMOKESCREEN" }, { level = 12, move = "EMBER" },
      { level = 19, move = "QUICK_ATTACK" }, { level = 27, move = "FLAME_WHEEL" },
    },
    evolutions = { { method = "EVOLVE_LEVEL", level = 14, into = "QUILAVA" } },
  },
  TOTODILE = {
    id = "TOTODILE", index = 158, name = "TOTODILE",
    baseStats = { hp = 50, attack = 65, defense = 64, speed = 43,
      specialAttack = 44, specialDefense = 48 },
    types = { "WATER", "WATER" }, catchRate = 45, baseExp = 66,
    growthRate = "GROWTH_MEDIUM_SLOW", genderRatio = 31,
    levelMoves = { { level = 1, move = "SCRATCH" },
      { level = 7, move = "WATER_GUN" } },
    evolutions = {},
  },
  PIDGEY = {
    id = "PIDGEY", index = 16, name = "PIDGEY",
    baseStats = { hp = 40, attack = 45, defense = 40, speed = 56,
      specialAttack = 35, specialDefense = 35 },
    types = { "NORMAL", "FLYING" }, catchRate = 255, baseExp = 55,
    growthRate = "GROWTH_MEDIUM_SLOW", genderRatio = 127,
    levelMoves = { { level = 1, move = "TACKLE" } },
    evolutions = {},
  },
  GEODUDE = {
    id = "GEODUDE", index = 74, name = "GEODUDE",
    baseStats = { hp = 40, attack = 80, defense = 100, speed = 20,
      specialAttack = 30, specialDefense = 30 },
    types = { "ROCK", "GROUND" }, catchRate = 255, baseExp = 73,
    growthRate = "GROWTH_MEDIUM_SLOW", genderRatio = 31,
    levelMoves = { { level = 1, move = "TACKLE" } },
    evolutions = {},
  },
  GASTLY = {
    id = "GASTLY", index = 92, name = "GASTLY",
    baseStats = { hp = 30, attack = 35, defense = 30, speed = 80,
      specialAttack = 100, specialDefense = 35 },
    types = { "GHOST", "POISON" }, catchRate = 190, baseExp = 62,
    growthRate = "GROWTH_MEDIUM_SLOW", genderRatio = 127,
    levelMoves = { { level = 1, move = "LICK" } },
    evolutions = {},
  },
  -- GENDER_UNKNOWN (data/pokemon/base_stats/magnemite.asm).
  MAGNEMITE = {
    id = "MAGNEMITE", index = 81, name = "MAGNEMITE",
    baseStats = { hp = 25, attack = 35, defense = 70, speed = 45,
      specialAttack = 95, specialDefense = 55 },
    types = { "ELECTRIC", "STEEL" }, catchRate = 190, baseExp = 89,
    growthRate = "GROWTH_MEDIUM_FAST", genderRatio = 0xff,
    levelMoves = { { level = 1, move = "TACKLE" } },
    evolutions = {},
  },
}

local DATA = {
  pokemon = POKEMON,
  moves = MOVES,
  type_chart = { types = TYPES, matchups = MATCHUPS },
  items = {
    POKE_BALL = { id = "POKE_BALL", pocket = "BALL" },
    POTION = { id = "POTION", pocket = "ITEM" },
  },
}

-- Deterministic "random": always returns 0, i.e. the first outcome.  Passed as
-- random(n) -> 0..n-1, which is the same contract BattleRandom has.
local function zeroRandom() return 0 end
-- Always the *last* outcome.
local function maxRandom(n) return n - 1 end


return {data=DATA,Mon=require("src.battle.gen2.Mon")}
