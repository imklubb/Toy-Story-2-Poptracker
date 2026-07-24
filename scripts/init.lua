-- Toy Story 2 (Archipelago) -- PopTracker pack entry point.
Tracker:AddItems("items/items.json")
ScriptHost:LoadScript("scripts/logic.lua")   -- defines $no_gating used by access_rules
ScriptHost:LoadScript("scripts/coin_logic.lua")  -- COIN_REQ data for $coinbundle
Tracker:AddMaps("maps/maps.json")
Tracker:AddLocations("locations/locations.json")
Tracker:AddLayouts("layouts/tracker.json")

-- Archipelago auto-tracking (settings + received items). Only when the active
-- variant carries the "ap" flag (then the Archipelago global exists).
if Archipelago then
  ScriptHost:LoadScript("scripts/ap_locmap.lua")
  ScriptHost:LoadScript("scripts/autotracking.lua")
end
