-- Access logic helpers, referenced from locations' access_rules as "$no_gating".
-- Each location rule is ["unlock_<level>", "$no_gating"] (OR). Unlock-item gating
-- only makes sense in OPEN mode once connected: in LINEAR mode levels are
-- token-gated (the unlock is not an item), and before connecting nothing is
-- known. In both of those cases no_gating() returns 1 so checks are NOT greyed.
-- DEPRECATED, kept only so a stray rule that still says $no_gating does not error.
-- It returned 1 for LINEAR, which meant linear seeds had NO level gating at all:
-- every location in every level showed reachable. Use $gating_ok|<level>.
function no_gating()
  if not SETTINGS then return 1 end
  return (tonumber(SETTINGS.game_mode) == 1) and 1 or 0
end

-- ── Level gating ────────────────────────────────────────────────────────────
-- Linear IS gated -- just not by unlock items. An area opens by DEFEATING the
-- previous area's boss, and each boss has its own token gate from slot_data.
-- This mirrors can_access_level() in rules.py exactly, including its definition
-- of "defeated": you can logically REACH that boss level and have the attack it
-- needs -- not that you have actually beaten it. That is what the AP generator
-- and Universal Tracker use, so the pack now agrees with both.
function ts2_has(code)  return (Tracker:ProviderCountForCode(code) or 0) > 0 end
function ts2_tokens()   return Tracker:ProviderCountForCode("pizza_planet_token") or 0 end
function ts2_gate(key)  return tonumber(SETTINGS and SETTINGS[key]) or 0 end
function ts2_any_attack() return ts2_has("laser") or ts2_has("spin") or ts2_has("stomp") end

-- Each gate references only STRICTLY EARLIER areas, so this recursion
-- terminates -- the same reason rules.py can recurse here safely.
function lin_bombs() return linear_reached("bombs_away") == 1 and ts2_any_attack() end
function lin_slime() return linear_reached("slime_time") == 1 and ts2_has("laser") end
function lin_tbe()
  return linear_reached("toy_barn_encounter") == 1 and ts2_has("laser")
         and (ts2_has("spin") or ts2_has("stomp"))
end
function lin_zurg() return linear_reached("the_evil_emperor_zurg") == 1 and ts2_has("spin") end

function linear_reached(level)
  local t = ts2_tokens()
  -- Area 0 is free
  if level == "andys_house" or level == "andys_neighborhood" then return 1 end
  if level == "bombs_away" then
    return (t >= ts2_gate("bombs_away_token_gate")) and 1 or 0 end
  -- Area 1, opened by Bombs Away!
  if level == "construction_yard" or level == "alleys_and_gullies" then
    return lin_bombs() and 1 or 0 end
  if level == "slime_time" then
    return (lin_bombs() and t >= ts2_gate("slime_time_token_gate")) and 1 or 0 end
  -- Area 2, opened by Slime Time
  if level == "als_toy_barn" or level == "als_space_land" then
    return lin_slime() and 1 or 0 end
  if level == "toy_barn_encounter" then
    return (lin_slime() and t >= ts2_gate("toy_barn_encounter_token_gate")) and 1 or 0 end
  -- Area 3, opened by the Toy Barn Encounter
  if level == "elevator_hop" or level == "als_penthouse" then
    return lin_tbe() and 1 or 0 end
  if level == "the_evil_emperor_zurg" then
    return (lin_tbe() and t >= ts2_gate("evil_emperor_zurg_token_gate")) and 1 or 0 end
  -- Area 4, opened by Zurg
  if level == "airport_infiltration" or level == "tarmac_trouble" then
    return lin_zurg() and 1 or 0 end
  if level == "final_showdown" then
    return (lin_zurg() and t >= ts2_gate("linear_final_showdown_token_gate")) and 1 or 0 end
  return 0
end

-- The half of every access rule that used to be a bare $no_gating.
--   not connected -> 1, so nothing is greyed before a slot is known (unchanged)
--   OPEN          -> 0, so the unlock ITEM is the only gate (unchanged)
--   LINEAR        -> the area/boss/token chain above (this is the fix)
function gating_ok(level)
  if not SETTINGS then return 1 end
  if tonumber(SETTINGS.game_mode) ~= 1 then return 0 end
  return linear_reached(level)
end

-- ── Skip-tier helpers ──
-- Read the live "Skips" toggle (the set_skips staged item). applySettings sets
-- this item's stage from slot_data on connect, and it is also the manual UI
-- toggle, so reading the item reflects the player's setting whether they are
-- connected to a slot OR previewing logic by hand. (Reading SETTINGS.skips only
-- worked on a live connection and left manual/preview toggling with no effect.)
function skips_value()
  local o = Tracker:FindObjectForCode("set_skips")
  return (o and o.CurrentStage) or 0
end
function skips_off()          return (skips_value() == 0) and 1 or 0 end
-- Skip gates are monotonic: a skip enabled from a given tier upward stays
-- enabled at every harder tier. "easy_or_hard" = enabled from Easy upward
-- (Easy/Hard/Insane); "hard" = from Hard upward (Hard/Insane); "insane" = Insane
-- only. (Behaviour for Off/Easy/Hard is identical to before, since those used to
-- be the max tier; this purely adds correct Insane coverage.)
function skips_easy_or_hard() return (skips_value() >= 1) and 1 or 0 end
function skips_hard()         return (skips_value() >= 2) and 1 or 0 end
function skips_insane()       return (skips_value() >= 3) and 1 or 0 end

-- ── Coin display mode: individual coins (bundle size 1) vs bundled ──
-- set_coin_check holds the Coinsanity Checks Bundle Size (applySettings copies it
-- from slot_data on connect; it is also the manual UI consumable, so this reflects
-- the player's setting whether connected or previewing by hand). 1 = each coin is
-- its own check (show the per-group diamonds); anything else (5/10/15/20/25, or 0
-- = "all") = bundled (show the single lump pin instead).
function coins_individual()
  return (Tracker:ProviderCountForCode("set_coin_check") == 1) and 1 or 0
end
function coins_bundled()
  return (Tracker:ProviderCountForCode("set_coin_check") ~= 1) and 1 or 0
end

-- True whenever coinsanity is on at all (any bundle size). Used by the coin
-- counter pins (lump + level-select), whose badge = coins/bundles remaining.
function coins_any()
  return (Tracker:ProviderCountForCode("set_coin_check") >= 1) and 1 or 0
end

-- ── Coin-bundle reachability: "are >= N*bundle_size of this level's coins reachable?" ──
-- COIN_REQ (per level/skip-tier per-coin DNFs) is provided by coin_logic.lua.
local function code_met(code)
  local nm, n = code:match("^(.-):(%d+)$")
  if nm then return Tracker:ProviderCountForCode(nm) >= tonumber(n) end
  return Tracker:ProviderCountForCode(code) >= 1
end
function coinbundle(li, bn)
  li = tonumber(li); bn = tonumber(bn)
  if not COIN_REQ or not COIN_REQ[li] then return 1 end
  local tier = skips_value()
  local coins = COIN_REQ[li][tier] or COIN_REQ[li][0]
  if not coins then return 1 end
  local total = #coins
  local bsize = (SETTINGS and tonumber(SETTINGS.coinsanity_checks_bundle_size)) or 5
  local K = (bsize == 0) and total or math.min(bn * bsize, total)
  if K <= 0 then return 1 end
  local cnt = 0
  for _, terms in ipairs(coins) do
    local ok = false
    for _, term in ipairs(terms) do
      local all = true
      for _, c in ipairs(term) do if not code_met(c) then all = false break end end
      if all then ok = true break end
    end
    if ok then cnt = cnt + 1; if cnt >= K then return 1 end end
  end
  return (cnt >= K) and 1 or 0
end

-- Per-COIN reachability for individual-coin (CHECK bundle size 1) pins. Unlike
-- coinbundle (which is ordinal: "are at least N coins reachable" and therefore greys
-- the highest-indexed coins regardless of which are actually blocked), this tests the
-- specific coin's own requirement DNF, so e.g. "On Low Swing" greys iff you actually
-- lack Double Jump + Ledge Grab, and an enemy coin greys iff you lack an attack.
function coin_reachable(li, idx)
  li = tonumber(li); idx = tonumber(idx)
  if not COIN_REQ or not COIN_REQ[li] then return 1 end
  local tier = skips_value()
  local coins = COIN_REQ[li][tier] or COIN_REQ[li][0]
  if not coins or not coins[idx] then return 1 end
  for _, term in ipairs(coins[idx]) do
    local all = true
    for _, c in ipairs(term) do if not code_met(c) then all = false break end end
    if all then return 1 end
  end
  return 0
end

-- True (1) only when EVERY coin in level `li` is reachable at the active skip
-- tier. Drives the "Coins Remaining" counter pin's colour: it goes red/unreachable
-- the moment any single coin in the level can't be reached with current gadgets.
function coins_all_reachable(li)
  li = tonumber(li)
  if not COIN_REQ or not COIN_REQ[li] then return 1 end
  local tier = skips_value()
  local coins = COIN_REQ[li][tier] or COIN_REQ[li][0]
  if not coins then return 1 end
  for _, terms in ipairs(coins) do
    local ok = false
    for _, term in ipairs(terms) do
      local all = true
      for _, c in ipairs(term) do if not code_met(c) then all = false break end end
      if all then ok = true break end
    end
    if not ok then return 0 end           -- a coin we can't reach -> not all reachable
  end
  return 1
end

-- True (1) when AT LEAST ONE coin in level `li` is reachable at the active skip
-- tier. Paired with coins_all_reachable in a bracketed access rule this gives the
-- counter pin a three-state colour: all reachable = green, some = orange
-- (sequence break), none = red.
function coins_any_reachable(li)
  li = tonumber(li)
  if not COIN_REQ or not COIN_REQ[li] then return 1 end
  local tier = skips_value()
  local coins = COIN_REQ[li][tier] or COIN_REQ[li][0]
  if not coins then return 1 end
  for _, terms in ipairs(coins) do
    for _, term in ipairs(terms) do
      local all = true
      for _, c in ipairs(term) do if not code_met(c) then all = false break end end
      if all then return 1 end            -- a coin we can reach
    end
  end
  return 0
end

-- Per-level unlock item codes (open-mode gating). Mirrors the "<unlock>" half of
-- each level's location access rules.
local COIN_UNLOCK = {
  [0]="unlock_andys_house",        [1]="unlock_andys_neighborhood", [2]="unlock_construction_yard",
  [3]="unlock_alleys_and_gullies", [4]="unlock_als_toy_barn",       [5]="unlock_als_space_land",
  [6]="unlock_elevator_hop",       [7]="unlock_als_penthouse",      [8]="unlock_airport_infiltration",
  [9]="unlock_tarmac_trouble",
}

-- Number of coins in level `li` reachable at the active skip tier. The autotracker
-- uses this to fill the "Reachable Coins Remaining" counter (reachable - collected)
-- and to decide whether the "Unreachable Coins" marker is shown (drives the pin's
-- green / FF9F20 / red colour without needing a per-coin section list on the pin).
function coins_reachable_count(li)
  li = tonumber(li)
  if not COIN_REQ or not COIN_REQ[li] then return 0 end
  local tier = skips_value()
  local coins = COIN_REQ[li][tier] or COIN_REQ[li][0]
  if not coins then return 0 end
  local cnt = 0
  for _, terms in ipairs(coins) do
    for _, term in ipairs(terms) do
      local all = true
      for _, c in ipairs(term) do if not code_met(c) then all = false break end end
      if all then cnt = cnt + 1 break end
    end
  end
  return cnt
end

-- Always-false rule: the "Unreachable Coins" marker section uses "$coins_never" so
-- its (autotracked) check is rendered unreachable, mixing red into the counter pin
-- whenever any coin in the level can't be reached -> light orange (FF9F20).
function coins_never() return 0 end

-- ── Hamm's 50 Coins Token reachability ──
-- Coinsanity ON: gated by RECEIVED coins (coin_<level> counts coins; need >= 50).
-- Coinsanity OFF: coins are collected in-level, so gate by whether >= 50 of the
-- level's coins are REACHABLE with current moves/skips (mirrors the apworld rule:
-- sum(can_reach_coin) >= 50). The Hamm-reach moves stay in the access rule itself.
-- Coinsanity is ON when the Coinsanity item sits on its "On" stage (code
-- set_coinsanity_1). This reflects BOTH the slot_data value (autotracking stages
-- the item on connect) and a manual toggle, so it's correct whether or not a game
-- is connected. SETTINGS.coinsanity only carries the connected value and is blind
-- to manual toggles, which is why it can't be used here.
function coinsanity_on()
  return Tracker:ProviderCountForCode("set_coinsanity_1") >= 1
end

-- Airport Infiltration's Hamm token: with Coinsanity OFF you must have Ledge Grab
-- to climb back after the fall (the level is played on the floor past that point);
-- with Coinsanity ON you can just reset the level since coins carry over.
function lg_or_coinsanity()
  if coinsanity_on() then return 1 end
  return (Tracker:ProviderCountForCode("ledge_grab") >= 1) and 1 or 0
end

function hamm50(li, coin_code)
  li = tonumber(li)
  -- Coinsanity ON: 50 coins come from received Coin Bundle items.
  if coinsanity_on() then
    return (Tracker:ProviderCountForCode(coin_code) >= 50) and 1 or 0
  end
  -- Coinsanity OFF: coins are collected in-level, so "50 coins" means the player's
  -- current moves can physically reach at least 50 of this level's coins. This is
  -- the same as the AP's _fifty_coins_ok: count reachable coins, need >= 50. The
  -- token's own Hamm-reach moves are ANDed in by the rest of the access rule.
  if not COIN_REQ or not COIN_REQ[li] then return 1 end
  local tier = skips_value()
  local coins = COIN_REQ[li][tier] or COIN_REQ[li][0]
  if not coins then return 1 end
  local cnt = 0
  for _, terms in ipairs(coins) do
    local ok = false
    for _, term in ipairs(terms) do
      local all = true
      for _, c in ipairs(term) do if not code_met(c) then all = false; break end end
      if all then ok = true; break end
    end
    if ok then
      cnt = cnt + 1
      if cnt >= 50 then return 1 end
    end
  end
  return (cnt >= 50) and 1 or 0
end

-- ── Goal condition check (open mode): tokens / bosses / unlock per slot_data ──
-- Linear mode needs only (Stomp|Spin)+access, so returns 1 there. Boss count uses
-- cleared boss "Defeat Reward 1" checks (the bosses you've actually beaten).
function goalcond()
  if not SETTINGS then return 1 end
  if tonumber(SETTINGS.game_mode) == 1 then return 1 end   -- linear
  local goal = tonumber(SETTINGS.goal_conditions) or 0
  local needs_tokens = (goal==0 or goal==3 or goal==4 or goal==6)
  local needs_bosses = (goal==1 or goal==3 or goal==5 or goal==6)
  local needs_unlock = (goal==2 or goal==4 or goal==5 or goal==6)
  if needs_tokens then
    local gate = tonumber(SETTINGS.final_showdown_token_gate) or 0
    if Tracker:ProviderCountForCode("pizza_planet_token") < gate then return 0 end
  end
  if needs_bosses then
    local req = tonumber(SETTINGS.defeated_bosses_required) or 0
    local cnt = 0
    for _, ab in ipairs({"BA","ST","TBE","EEZ"}) do
      local o = Tracker:FindObjectForCode("@"..ab.."/Defeat Reward 1")
      if o and (o.AvailableChestCount or 1) == 0 then cnt = cnt + 1 end
    end
    if cnt < req then return 0 end
  end
  if needs_unlock then
    if Tracker:ProviderCountForCode("unlock_final_showdown") < 1 then return 0 end
  end
  return 1
end
