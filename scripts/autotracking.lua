-- Toy Story 2 (Archipelago) auto-tracking
-- Reads slot_data (the player's YAML options) on connect and fills the Settings
-- tab, auto-fills received items onto the bar, and wires the autotab bridge.
-- Loaded from init.lua only when the active variant has the "ap" flag.
if not Archipelago then return end

-- AP item name -> tracker item code (generated from the apworld item list)
local AP_ITEM_TO_CODE = {
  ["Airport Infiltration Unlock"] = "unlock_airport_infiltration",
  ["Al's Penthouse Unlock"] = "unlock_als_penthouse",
  ["Al's Space Land Unlock"] = "unlock_als_space_land",
  ["Al's Toy Barn Unlock"] = "unlock_als_toy_barn",
  ["Alien"] = "alien",
  ["Alleys and Gullies Unlock"] = "unlock_alleys_and_gullies",
  ["Andy's House Unlock"] = "unlock_andys_house",
  ["Andy's Neighborhood Unlock"] = "unlock_andys_neighborhood",
  ["Bombs Away! Unlock"] = "unlock_bombs_away",
  ["Chick"] = "chick",
  ["Coin Bundle - Airport Infiltration"] = "coin_airport_infiltration",
  ["Coin Bundle - Al's Penthouse"] = "coin_als_penthouse",
  ["Coin Bundle - Al's Space Land"] = "coin_als_space_land",
  ["Coin Bundle - Al's Toy Barn"] = "coin_als_toy_barn",
  ["Coin Bundle - Alleys and Gullies"] = "coin_alleys_and_gullies",
  ["Coin Bundle - Andy's House"] = "coin_andys_house",
  ["Coin Bundle - Andy's Neighborhood"] = "coin_andys_neighborhood",
  ["Coin Bundle - Construction Yard"] = "coin_construction_yard",
  ["Coin Bundle - Elevator Hop"] = "coin_elevator_hop",
  ["Coin Bundle - Tarmac Trouble"] = "coin_tarmac_trouble",
  ["Construction Yard Unlock"] = "unlock_construction_yard",
  ["Cosmic Shield - Al's Penthouse"] = "gadget_als_penthouse_cosmic_shield",
  ["Cosmic Shield - Al's Space Land"] = "gadget_als_space_land_cosmic_shield",
  ["Cosmic Shield - Andy's House"] = "gadget_andys_house_cosmic_shield",
  ["Critter"] = "critter",
  ["Disc Launcher - Al's Toy Barn"] = "gadget_als_toy_barn_disc_launcher",
  ["Disc Launcher - Alleys and Gullies"] = "gadget_alleys_and_gullies_disc_launcher",
  ["Disc Launcher - Construction Yard"] = "gadget_construction_yard_disc_launcher",
  ["Double Jump"] = "double_jump",
  ["Duck"] = "duck",
  ["Elevator Hop Unlock"] = "unlock_elevator_hop",
  ["Final Showdown Ticket"] = "final_showdown_ticket",
  ["Final Showdown Unlock"] = "unlock_final_showdown",
  ["Grappling Hook - Alleys and Gullies"] = "gadget_alleys_and_gullies_grappling_hook",
  ["Grappling Hook - Elevator Hop"] = "gadget_elevator_hop_grappling_hook",
  ["Hover Boots - Airport Infiltration"] = "gadget_airport_infiltration_hover_boots",
  ["Hover Boots - Al's Toy Barn"] = "gadget_als_toy_barn_hover_boots",
  ["Ledge Grab"] = "ledge_grab",
  ["Luggage"] = "luggage",
  ["Missing Arm"] = "missing_arm",
  ["Missing Ear"] = "missing_ear",
  ["Missing Eye"] = "missing_eye",
  ["Missing Foot"] = "missing_foot",
  ["Missing Mouth"] = "missing_mouth",
  ["Mouse"] = "mouse",
  ["Passenger Tike"] = "passenger_tike",
  ["Pizza Planet Token"] = "pizza_planet_token",
  ["Pole Climb"] = "pole_climb",
  ["Pole Vault"] = "pole_vault",
  ["Progressive Laser"] = "laser",
  ["Push"] = "push",
  ["Rocket Boots - Al's Toy Barn"] = "gadget_als_toy_barn_rocket_boots",
  ["Rocket Boots - Alleys and Gullies"] = "gadget_alleys_and_gullies_rocket_boots",
  ["Rocket Boots - Andy's Neighborhood"] = "gadget_andys_neighborhood_rocket_boots",
  ["Rocket Boots - Tarmac Trouble"] = "gadget_tarmac_trouble_rocket_boots",
  ["Rope Sliding"] = "rope_sliding",
  ["Sheep"] = "sheep",
  ["Slime Time Unlock"] = "unlock_slime_time",
  ["Soldier"] = "soldier",
  ["Progressive Spin"] = "spin",
  ["Stomp"] = "stomp",
  ["Tarmac Trouble Unlock"] = "unlock_tarmac_trouble",
  ["The Evil Emperor Zurg Unlock"] = "unlock_the_evil_emperor_zurg",
  ["Toy Barn Encounter Unlock"] = "unlock_toy_barn_encounter",
  ["Visor"] = "visor",
  ["Worker Tike"] = "worker_tike",
}
-- which of those codes are consumables (count) vs toggles (on/off)
local CONSUMABLE = {
  ["alien"] = true,
  ["chick"] = true,
  ["coin_airport_infiltration"] = true,
  ["coin_alleys_and_gullies"] = true,
  ["coin_als_penthouse"] = true,
  ["coin_als_space_land"] = true,
  ["coin_als_toy_barn"] = true,
  ["coin_andys_house"] = true,
  ["coin_andys_neighborhood"] = true,
  ["coin_construction_yard"] = true,
  ["coin_elevator_hop"] = true,
  ["coin_tarmac_trouble"] = true,
  ["critter"] = true,
  ["duck"] = true,
  ["final_showdown_ticket"] = true,
  ["luggage"] = true,
  ["mouse"] = true,
  ["passenger_tike"] = true,
  ["laser"] = true,
  ["spin"] = true,
  ["pizza_planet_token"] = true,
  ["sheep"] = true,
  ["soldier"] = true,
  ["worker_tike"] = true,
}
-- every auto-filled code, reset on (re)connect
local ALL_CODES = {
  "alien",
  "chick",
  "coin_airport_infiltration",
  "coin_alleys_and_gullies",
  "coin_als_penthouse",
  "coin_als_space_land",
  "coin_als_toy_barn",
  "coin_andys_house",
  "coin_andys_neighborhood",
  "coin_construction_yard",
  "coin_elevator_hop",
  "coin_tarmac_trouble",
  "critter",
  "double_jump",
  "duck",
  "final_showdown_ticket",
  "gadget_airport_infiltration_hover_boots",
  "gadget_alleys_and_gullies_disc_launcher",
  "gadget_alleys_and_gullies_grappling_hook",
  "gadget_alleys_and_gullies_rocket_boots",
  "gadget_als_penthouse_cosmic_shield",
  "gadget_als_space_land_cosmic_shield",
  "gadget_als_toy_barn_disc_launcher",
  "gadget_als_toy_barn_hover_boots",
  "gadget_als_toy_barn_rocket_boots",
  "gadget_andys_house_cosmic_shield",
  "gadget_andys_neighborhood_rocket_boots",
  "gadget_construction_yard_disc_launcher",
  "gadget_elevator_hop_grappling_hook",
  "gadget_tarmac_trouble_rocket_boots",
  "laser",
  "ledge_grab",
  "luggage",
  "missing_arm",
  "missing_ear",
  "missing_eye",
  "missing_foot",
  "missing_mouth",
  "mouse",
  "passenger_tike",
  "pizza_planet_token",
  "pole_climb",
  "pole_vault",
  "push",
  "rope_sliding",
  "sheep",
  "soldier",
  "spin",
  "stomp",
  "unlock_airport_infiltration",
  "unlock_alleys_and_gullies",
  "unlock_als_penthouse",
  "unlock_als_space_land",
  "unlock_als_toy_barn",
  "unlock_andys_house",
  "unlock_andys_neighborhood",
  "unlock_bombs_away",
  "unlock_construction_yard",
  "unlock_elevator_hop",
  "unlock_final_showdown",
  "unlock_slime_time",
  "unlock_tarmac_trouble",
  "unlock_the_evil_emperor_zurg",
  "unlock_toy_barn_encounter",
  "visor",
  "worker_tike",
}

-- Parsed options, exposed globally so later logic/marker scripts can read it.
SETTINGS = {}

local function obj(code) return Tracker:FindObjectForCode(code) end

-- Per-level coin totals (used by applySettings for the bundle visibility counts).
local COIN_COUNT  = {AH=93,AN=99,CY=72,AaG=103,ATB=71,ASL=89,EH=63,AP=72,AI=72,TT=88}

-- ── Coins Remaining counter ──────────────────────────────────────────────
-- One "Coins Remaining" section per level (item_count = that level's total). Its
-- map-pin BADGE shows the number still uncollected and ticks down as coin checks
-- arrive. We map each cleared AP id to its level via the (contiguous) coin-id
-- ranges, count per level, and set AvailableChestCount = total - collected.
local COIN_RANGES = {
  AH={1966214073,1966214165}, AN={1966214183,1966214281}, CY={1966214293,1966214364},
  AaG={1966214403,1966214505}, ATB={1966214513,1966214583}, ASL={1966214623,1966214711},
  EH={1966214733,1966214795}, AP={1966214843,1966214914}, AI={1966214953,1966215024},
  TT={1966215063,1966215150},
}
local COINS_COLLECTED, COIN_COUNTED = {}, {}
local function coinLevelForId(id)
  for ab,r in pairs(COIN_RANGES) do if id>=r[1] and id<=r[2] then return ab end end
  return nil
end

-- At Coinsanity CHECK bundle size 1, each coin is its own AP location with a
-- DESCRIPTOR id (_COIN_DESC_OFFSET + level*150 + coin_index) rather than the
-- "Coin Bundle N" id the rest of the tracker keys on (_COIN_BUNDLE_OFFSET +
-- level*110 + N). Translate a descriptor id to the equivalent bundle id so the
-- existing clear/count path handles both check-bundle modes.
local DESC_OFFSET = 1966217072          -- LOC_BASE + 5000  (LOC_BASE = 0x75320000 + 1000)
local DESC_PER    = 150
local AB_BY_LI = {[0]="AH",[1]="AN",[2]="CY",[3]="AaG",[4]="ATB",
                  [5]="ASL",[6]="EH",[7]="AP",[8]="AI",[9]="TT"}
local function toBundleId(id)
  if id and id >= DESC_OFFSET then
    local off = id - DESC_OFFSET
    local li  = math.floor(off / DESC_PER)
    local n   = off - li * DESC_PER            -- 1-based coin index within the level
    local ab  = AB_BY_LI[li]
    if ab and COIN_RANGES[ab] and n >= 1 then
      local bid = COIN_RANGES[ab][1] + (n - 1)
      if bid <= COIN_RANGES[ab][2] then return bid end
    end
  end
  return id
end
local LI_BY_AB = {AH=0,AN=1,CY=2,AaG=3,ATB=4,ASL=5,EH=6,AP=7,AI=8,TT=9}
-- Fill the per-level counter pin: "Reachable Coins Remaining" badge = (reachable now
-- - collected), and the "Unreachable Coins" marker = 1 when any coin is currently
-- unreachable (else 0). The marker is what mixes red into the pin -> light orange
-- (FF9F20) when some coins can't be reached; badge counts only reachable coins so the
-- pin reads as a clean counter. Recomputed on every item/location/settings change so
-- the colour and count track gadget pickups live.
local function recomputeCoinCounts()
  for ab,total in pairs(COIN_COUNT) do
    local li = LI_BY_AB[ab]
    local reach = (li ~= nil and coins_reachable_count and coins_reachable_count(li)) or total
    local collected = COINS_COLLECTED[ab] or 0
    local r = Tracker:FindObjectForCode("@"..ab.."/Reachable Coins Remaining")
    if r then r.AvailableChestCount = math.max(0, reach - collected) end
    local u = Tracker:FindObjectForCode("@"..ab.."/Unreachable Coins")
    if u then u.AvailableChestCount = (reach < total) and 1 or 0 end
  end
end
local function resetCoinsRemaining()
  COINS_COLLECTED, COIN_COUNTED = {}, {}
  recomputeCoinCounts()
end

local function clearLoc(id)
  id = toBundleId(id)   -- size-1 sends descriptor ids; map them to the bundle id
  local code = AP_LOC and AP_LOC[id]
  if code then
    local o = Tracker:FindObjectForCode(code)
    if o then o.AvailableChestCount = 0 end
  end
  local ab = coinLevelForId(id)
  if ab then
    -- mirror the clear onto the parallel "Coin Bundle N" section (bundle-mode pins)
    local N = id - COIN_RANGES[ab][1] + 1
    local b = Tracker:FindObjectForCode("@"..ab.."/Coin Bundle "..N)
    if b then b.AvailableChestCount = 0 end
    if not COIN_COUNTED[id] then
      COIN_COUNTED[id] = true
      COINS_COLLECTED[ab] = (COINS_COLLECTED[ab] or 0) + 1
    end
  end
end
-- Un-clear EVERY location so stale checks from a previously-tracked seed don't
-- linger grey after connecting to a new one. Called on every (re)sync before the
-- new seed's already-checked locations are re-applied.
local function resetLocations()
  if not AP_LOC then return end
  for _,code in pairs(AP_LOC) do
    local o = Tracker:FindObjectForCode(code)
    if o and o.ChestCount then o.AvailableChestCount = o.ChestCount end
  end
  -- reset the parallel "Coin Bundle N" sections too (they aren't in AP_LOC)
  for ab,r in pairs(COIN_RANGES) do
    for N=1,(r[2]-r[1]+1) do
      local b = Tracker:FindObjectForCode("@"..ab.."/Coin Bundle "..N)
      if b and b.ChestCount then b.AvailableChestCount = b.ChestCount end
    end
  end
  resetCoinsRemaining()
end
local function setCount(code,n)  local o=obj(code); if o then o.AcquiredCount=n end end
local function setActive(code,b) local o=obj(code); if o then o.Active = b and true or false end end
local function setText(code,s)   local o=obj(code); if o then o.Active=true; o:SetOverlay(tostring(s)) end end
local function setStage(code,n)  local o=obj(code); if o then o.Active=true; o.CurrentStage=n end end
local function setBadge(code,s)  local o=obj(code); if o then o:SetOverlay(tostring(s or "")) end end
local function num(sd,k) local v=sd and sd[k]; return tonumber(v) or 0 end

local MODE  = {[0]="OPEN",[1]="LINEAR"}
local SKIPS = {[0]="OFF",[1]="EASY",[2]="HARD",[3]="INSANE"}
local MOVES = {[0]="OFF",[1]="FULL",[2]="LITE-W",[3]="LITE-T"}
local GOAL  = {[0]="PPT",[1]="BOSS",[2]="UNLK",[3]="PPT+BOSS",[4]="PPT+UNLK",[5]="BOSS+UNLK",[6]="PPT+BOSS+UNLK"}

-- Level/boss display name -> unlock item code, for pre-marking starting levels
-- (precollected unlocks) so their checks aren't greyed by the access rules.
local NAME2UNLOCK = {
  ["Andy's House"]="unlock_andys_house", ["Andy's Neighborhood"]="unlock_andys_neighborhood",
  ["Construction Yard"]="unlock_construction_yard", ["Alleys and Gullies"]="unlock_alleys_and_gullies",
  ["Al's Toy Barn"]="unlock_als_toy_barn", ["Al's Space Land"]="unlock_als_space_land",
  ["Elevator Hop"]="unlock_elevator_hop", ["Al's Penthouse"]="unlock_als_penthouse",
  ["Airport Infiltration"]="unlock_airport_infiltration", ["Tarmac Trouble"]="unlock_tarmac_trouble",
  ["Bombs Away!"]="unlock_bombs_away", ["Slime Time"]="unlock_slime_time",
  ["Toy Barn Encounter"]="unlock_toy_barn_encounter", ["The Evil Emperor Zurg"]="unlock_the_evil_emperor_zurg",
  ["Prospector Showdown"]="unlock_final_showdown",
}

local function applySettings(sd)
  sd = sd or {}
  SETTINGS = sd
  setStage("set_mode",       num(sd,"game_mode"))
  setStage("set_skips",      num(sd,"skips"))
  local mv=num(sd,"movesanity")
  setStage("set_movesanity", mv)
  setBadge("set_movesanity", mv==2 and "W" or (mv==3 and "T" or ""))
  local gc = num(sd,"goal_conditions")
  setActive("set_goal_ppt",    gc==0 or gc==3 or gc==4 or gc==6)
  setActive("set_goal_bosses", gc==1 or gc==3 or gc==5 or gc==6)
  setActive("set_goal_unlock", gc==2 or gc==4 or gc==5 or gc==6)
  setCount("set_token_pool",   num(sd,"pizza_planet_token_pool"))
  setCount("set_bosses_req",   num(sd,"defeated_bosses_required"))
  setCount("set_gate_bombs",   num(sd,"bombs_away_token_gate"))
  setCount("set_gate_slime",   num(sd,"slime_time_token_gate"))
  setCount("set_gate_toybarn", num(sd,"toy_barn_encounter_token_gate"))
  setCount("set_gate_zurg",    num(sd,"evil_emperor_zurg_token_gate"))
  setCount("set_gate_final",   num(sd,"final_showdown_token_gate"))
  setCount("set_gate_linfinal",num(sd,"linear_final_showdown_token_gate"))
  setCount("set_coin_check",   num(sd,"coinsanity_checks_bundle_size"))
  setCount("set_coin_recv",    num(sd,"coinsanity_received_bundle_size"))
  setCount("set_toy_recv",     num(sd,"missing_toy_bundle_size"))
  setStage("set_coinsanity",       num(sd,"coinsanity"))
  -- Hamm's 50-coin turn-ins (2.2.0). Older seeds have no such key, so a
  -- missing value must mean ON -- that was the only behaviour before the
  -- option existed, and defaulting it off would hide ten real checks.
  local _hamm = sd["hamm_fifty_coin_checks"]
  setStage("set_hamm", (_hamm == nil) and 1 or num(sd,"hamm_fifty_coin_checks"))
  setActive("set_lifesanity",      num(sd,"lifesanity")~=0)
  setActive("set_batterysanity",   num(sd,"batterysanity")~=0)
  setActive("set_greenlasersanity",num(sd,"green_laser_sanity")~=0)
  setActive("set_rexsanity",       num(sd,"rexsanity")~=0)
  setActive("set_hintblocksanity", num(sd,"hint_block_sanity")~=0)
  setActive("set_omit_airport",    num(sd,"omit_airport_infiltration")~=0)
  setActive("set_omit_elevator",   num(sd,"omit_elevator_hop")~=0)
  -- Pre-mark starting levels' (precollected) unlocks so their checks aren't greyed.
  if type(sd.starting_levels)=="table" then
    for _,lv in ipairs(sd.starting_levels) do
      local code = NAME2UNLOCK[lv]
      if code then local o=obj(code); if o then o.Active=true end end
    end
  end
  -- Coinsanity: number of Coins check-bundles per level = total / checks bundle size
  -- (size 0 = one bundle for the whole level; coinsanity off = none).
  local csan  = num(sd,"coinsanity")
  local bsize = num(sd,"coinsanity_checks_bundle_size")
  local CL = {"AH","AN","CY","AaG","ATB","ASL","EH","AP","AI","TT"}
  for idx,abbr in ipairs(CL) do
    local total = COIN_COUNT[abbr] or 0
    local n = 0
    if csan ~= 0 then n = (bsize==0) and 1 or math.ceil(total / bsize) end
    local it = obj("coinbundle"..(idx-1))
    if it then it.AcquiredCount = n end
  end
  print("[TS2] settings: mode="..(MODE[num(sd,"game_mode")] or "?")
      .." goal="..(GOAL[num(sd,"goal_conditions")] or "?")
      .." movesanity="..(MOVES[num(sd,"movesanity")] or "?")
      .." token_pool="..num(sd,"pizza_planet_token_pool")
      .." coinsanity="..tostring(num(sd,"coinsanity")~=0)
      .." check_bundle="..num(sd,"coinsanity_checks_bundle_size")
      .." recv_bundle="..num(sd,"coinsanity_received_bundle_size"))
  recomputeCoinCounts()
end

local function resetItems()
  for _,code in ipairs(ALL_CODES) do
    local o=obj(code)
    if o then if CONSUMABLE[code] then o.AcquiredCount=0 else o.Active=false end end
  end
end

-- ---- autotab bridge (ready; activates once the AP client writes the key) ----
-- The client should DataStorage-Set this key to the tab title to switch to,
-- e.g. "Andy's House", "Bosses", or "Level Select".
local LEVEL_KEY = nil
local function activateTab(v) if v and v~="" then pcall(function() Tracker:UiHint("ActivateTab", tostring(v)) end) end end

-- ---- hint highlighting --------------------------------------------------
-- Glow locations that have been hinted on AP. Hints live in AP data storage
-- under "_read_hints_<team>_<slot>"; we Get + SetNotify it (same pattern as the
-- autotab key above) and set each matching location section's Highlight.
local HINTS_KEY = nil
local hinted_codes = {}            -- section codes currently highlighted (for reset)

-- AP HintStatus -> PopTracker Highlight. PopTracker exposes a global `Highlight`
-- enum since it gained hint support (0.32.0); fall back to the raw AP status.
-- PopTracker Highlight enum (since 0.32.0): Avoid=-1, None=0, NoPriority=1,
-- Unspecified=2, Priority=3. Always return a number so the setter never gets nil.
local function highlight_for(status)
  if status == 20 then return (Highlight and Highlight.Avoid) or -1 end       -- HINT_AVOID
  if status == 10 then return (Highlight and Highlight.NoPriority) or 1 end    -- HINT_NO_PRIORITY
  if status == 1  then return (Highlight and Highlight.Unspecified) or 2 end   -- HINT_UNSPECIFIED
  return (Highlight and Highlight.Priority) or 3                               -- HINT_PRIORITY (30) / default
end

local function clearHints()
  for code in pairs(hinted_codes) do
    local o = Tracker:FindObjectForCode(code)
    if o and o.Highlight ~= nil then
      o.Highlight = (Highlight and Highlight.None) or 0
    end
  end
  hinted_codes = {}
end

local function applyHints(value)
  local ok, err = pcall(function()
    clearHints()
    if type(value) ~= "table" then return end
    local myslot = Archipelago.PlayerNumber
    local n, lit = 0, 0
    for _, h in ipairs(value) do
      n = n + 1
      -- our own locations only, not yet found
      if h.finding_player == myslot and not h.found then
        -- Coins in bundle-size-1 mode are hinted by their DESCRIPTOR id, which
        -- isn't in AP_LOC; map it to the parallel bundle id (no-op for everything
        -- else), exactly as clearLoc does for checks. Without this, hinted coin
        -- diamonds never glowed in size-1 mode.
        local code = AP_LOC and AP_LOC[toBundleId(h.location)]
        if code then
          local o = Tracker:FindObjectForCode(code)
          if o and o.Highlight ~= nil then
            o.Highlight = highlight_for(h.status or 30)
            hinted_codes[code] = true
            lit = lit + 1
          end
        end
      end
    end
  end)
  if not ok then print("[TS2] applyHints error: "..tostring(err)) end
end

local function onClear(slot_data)
  local ok,err = pcall(function()
    clearHints()          -- wipe stale hint glow from any previously-tracked seed
    resetItems()
    resetLocations()
    applySettings(slot_data)
    if Archipelago.CheckedLocations then
      for _,id in ipairs(Archipelago.CheckedLocations) do clearLoc(id) end
    end
    recomputeCoinCounts()
    LEVEL_KEY = "ts2_current_level_"..tostring(Archipelago.PlayerNumber)
    Archipelago:Get({LEVEL_KEY})
    Archipelago:SetNotify({LEVEL_KEY})
    local team = Archipelago.TeamNumber
    if not team or team < 0 then team = 0 end
    HINTS_KEY = "_read_hints_"..tostring(team).."_"..tostring(Archipelago.PlayerNumber)
    Archipelago:Get({HINTS_KEY})
    Archipelago:SetNotify({HINTS_KEY})
  end)
  if not ok then print("[TS2] onClear error: "..tostring(err)) end
end

-- Bundle toys: a single "5 X" item grants all 5 of that level's toys, so it
-- adds 5 to the matching consumable instead of 1.
local TOY_BUNDLE_TO_CODE = {
  ["5 Sheep"]="sheep", ["5 Soldiers"]="soldier", ["5 Worker Tikes"]="worker_tike",
  ["5 Ducks"]="duck", ["5 Chicks"]="chick", ["5 Aliens"]="alien",
  ["5 Mice"]="mouse", ["5 Critters"]="critter",
  ["5 Passenger Tikes"]="passenger_tike", ["5 Luggage"]="luggage",
}
local function onItem(index, item_id, item_name, player)
  local bcode = TOY_BUNDLE_TO_CODE[item_name]
  if bcode then
    local bo = obj(bcode)
    if bo then bo.AcquiredCount = (bo.AcquiredCount or 0) + 5 end
    return
  end
  local code = AP_ITEM_TO_CODE[item_name]
  if not code then return end
  local o = obj(code)
  if not o then return end
  if item_name:sub(1, 14) == "Coin Bundle - " then
    -- Received coin bundles: display COINS = bundles * received-bundle-size,
    -- not the raw bundle count (and makes Hamm's "50 coins" logic size-agnostic).
    local rb = (SETTINGS and tonumber(SETTINGS.coinsanity_received_bundle_size)) or 5
    o.AcquiredCount = (o.AcquiredCount or 0) + rb
  elseif CONSUMABLE[code] then
    o.AcquiredCount = (o.AcquiredCount or 0) + 1
  else
    o.Active = true
  end
  recomputeCoinCounts()   -- a new gadget can change how many coins are reachable
end

local function onLocation(location_id, location_name)
  clearLoc(location_id)
  recomputeCoinCounts()
end
local function onRetrieved(key, value)
  if key==LEVEL_KEY then activateTab(value) elseif key==HINTS_KEY then applyHints(value) end
end
local function onSetReply(key, value, old)
  if key==LEVEL_KEY then activateTab(value) elseif key==HINTS_KEY then applyHints(value) end
end

Archipelago:AddClearHandler("ts2_clear", onClear)
Archipelago:AddItemHandler("ts2_item", onItem)
Archipelago:AddLocationHandler("ts2_loc", onLocation)
Archipelago:AddRetrievedHandler("ts2_get", onRetrieved)
Archipelago:AddSetReplyHandler("ts2_setreply", onSetReply)
print("[TS2] autotracking loaded")
