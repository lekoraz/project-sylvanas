-- AIO (All-In-One) Combat Rotation System
-- Handles all classes and specializations in a single plugin

local plugin = {}

plugin["name"] = "AIO Combat Rotation"
plugin["version"] = "1.0.0"
plugin["author"] = "AIO System"
plugin["load"] = true

-- Check if local player exists before loading the script
local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin["load"] = false
    return plugin
end

-- AIO system supports all classes, so no class restriction
-- We'll handle class-specific logic in the main.lua file

return plugin