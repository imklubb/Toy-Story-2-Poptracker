-- Toy Story 2 (Archipelago) -- PopTracker pack entry point.
Tracker:AddItems("items/items.json")
ScriptHost:LoadScript("scripts/logic.lua")   -- defines $no_gating used by access_rules
ScriptHost:LoadScript("scripts/coin_logic.lua")  -- COIN_REQ data for $coinbundle
ScriptHost:LoadScript("scripts/souls.lua")       -- 3.4.0 Souls: $soul, $fs_souls, layout parts
Tracker:AddMaps("maps/maps.json")
Tracker:AddLocations("locations/locations.json")
Tracker:AddLayouts("layouts/tracker.json")
-- 3.4.0: hide what the settings don't use (Coins, Level Unlocks, soul groups);
-- connecting re-runs this with the seed's settings.
if ts2_sync_layouts then ts2_sync_layouts() end

-- Archipelago auto-tracking (settings + received items). Only when the active
-- variant carries the "ap" flag (then the Archipelago global exists).
if Archipelago then
  ScriptHost:LoadScript("scripts/ap_locmap.lua")
  ScriptHost:LoadScript("scripts/autotracking.lua")
end
