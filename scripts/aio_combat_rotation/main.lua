-- AIO (All-In-One) Combat Rotation System
-- Advanced combat rotation that handles every class using the project's custom API

-- Import required modules
---@type enums
local enums = require("common/enums")

---@type pvp_helper
local pvp_helper = require("common/utility/pvp_helper")

---@type spell_queue
local spell_queue = require("common/modules/spell_queue")

---@type unit_helper
local unit_helper = require("common/utility/unit_helper")

---@type spell_helper
local spell_helper = require("common/utility/spell_helper")

---@type buff_manager
local buff_manager = require("common/modules/buff_manager")

---@type plugin_helper
local plugin_helper = require("common/utility/plugin_helper")

---@type spell_prediction
local spell_prediction = require("common/modules/spell_prediction")

---@type control_panel_helper
local control_panel_helper = require("common/utility/control_panel_helper")

---@type target_selector
local target_selector = require("common/modules/target_selector")

---@type key_helper
local key_helper = require("common/utility/key_helper")

-- Menu elements for AIO configuration
local menu_elements = {
    main_tree = core.menu.tree_node(),
    keybinds_tree = core.menu.tree_node(),
    class_settings_tree = core.menu.tree_node(),
    
    -- Main toggles
    enable_script = core.menu.checkbox(false, "aio_enable_script"),
    enable_toggle = core.menu.keybind(999, false, "aio_toggle_script"),
    
    -- General settings
    auto_target = core.menu.checkbox(true, "aio_auto_target"),
    draw_plugin_state = core.menu.checkbox(true, "aio_draw_plugin_state"),
    
    -- Combat settings
    enable_offensive = core.menu.checkbox(true, "aio_enable_offensive"),
    enable_defensive = core.menu.checkbox(true, "aio_enable_defensive"),
    enable_healing = core.menu.checkbox(true, "aio_enable_healing"),
    
    -- Target selector override
    override_target_selector = core.menu.checkbox(true, "aio_override_ts"),
    
    -- Advanced settings
    burst_mode = core.menu.checkbox(false, "aio_burst_mode"),
    interrupt_enabled = core.menu.checkbox(true, "aio_interrupt_enabled"),
    dispel_enabled = core.menu.checkbox(true, "aio_dispel_enabled"),
    
    -- Health thresholds
    defensive_health_threshold = core.menu.slider_float(0.6, 0.1, 1.0, "aio_defensive_health"),
    healing_health_threshold = core.menu.slider_float(0.8, 0.1, 1.0, "aio_healing_health"),
    
    -- Range settings
    combat_range = core.menu.slider_float(40.0, 5.0, 45.0, "aio_combat_range"),
    healing_range = core.menu.slider_float(40.0, 5.0, 45.0, "aio_healing_range"),
}

-- Get player information
local local_player = core.object_manager.get_local_player()
local player_class = local_player and local_player:get_class() or 0
local player_spec = core.spell_book.get_specialization_id()

-- Class-specific spell data structures
local class_spells = {}

-- Initialize spell data for each class
local function initialize_class_spells()
    class_spells = {
        [enums.class_id.WARRIOR] = {
            -- Arms Warrior
            [enums.class_spec_id.spec_enum.ARMS_WARRIOR] = {
                offensive = {
                    {id = 12294, name = "Mortal Strike", priority = 1},
                    {id = 163201, name = "Execute", priority = 2},
                    {id = 772, name = "Rend", priority = 3},
                    {id = 260708, name = "Sweeping Strikes", priority = 4},
                },
                defensive = {
                    {id = 871, name = "Shield Wall", health_threshold = 0.3},
                    {id = 18499, name = "Berserker Rage", priority = 1},
                    {id = 6544, name = "Heroic Leap", priority = 2},
                },
                utility = {
                    {id = 6552, name = "Pummel", type = "interrupt"},
                    {id = 5246, name = "Intimidating Shout", type = "fear"},
                }
            },
            -- Fury Warrior
            [enums.class_spec_id.spec_enum.FURY_WARRIOR] = {
                offensive = {
                    {id = 85288, name = "Raging Blow", priority = 1},
                    {id = 163201, name = "Execute", priority = 2},
                    {id = 184367, name = "Rampage", priority = 3},
                    {id = 23881, name = "Bloodthirst", priority = 4},
                },
                defensive = {
                    {id = 184364, name = "Enraged Regeneration", health_threshold = 0.5},
                    {id = 18499, name = "Berserker Rage", priority = 1},
                },
                utility = {
                    {id = 6552, name = "Pummel", type = "interrupt"},
                }
            },
            -- Protection Warrior
            [enums.class_spec_id.spec_enum.PROTECTION_WARRIOR] = {
                offensive = {
                    {id = 23922, name = "Shield Slam", priority = 1},
                    {id = 6572, name = "Revenge", priority = 2},
                    {id = 163201, name = "Execute", priority = 3},
                    {id = 6343, name = "Thunder Clap", priority = 4},
                },
                defensive = {
                    {id = 871, name = "Shield Wall", health_threshold = 0.3},
                    {id = 12975, name = "Last Stand", health_threshold = 0.2},
                    {id = 2565, name = "Shield Block", priority = 1},
                },
                utility = {
                    {id = 6552, name = "Pummel", type = "interrupt"},
                    {id = 355, name = "Taunt", type = "taunt"},
                }
            }
        },
        [enums.class_id.PALADIN] = {
            -- Holy Paladin
            [enums.class_spec_id.spec_enum.HOLY_PALADIN] = {
                offensive = {
                    {id = 35395, name = "Crusader Strike", priority = 1},
                    {id = 20473, name = "Holy Shock", priority = 2},
                    {id = 879, name = "Exorcism", priority = 3},
                },
                defensive = {
                    {id = 498, name = "Divine Protection", health_threshold = 0.4},
                    {id = 642, name = "Divine Shield", health_threshold = 0.2},
                    {id = 1022, name = "Blessing of Protection", priority = 1},
                },
                healing = {
                    {id = 635, name = "Holy Light", health_threshold = 0.7},
                    {id = 82326, name = "Holy Word: Sanctuary", health_threshold = 0.5},
                    {id = 20473, name = "Holy Shock", health_threshold = 0.8},
                },
                utility = {
                    {id = 96231, name = "Rebuke", type = "interrupt"},
                    {id = 4987, name = "Cleanse", type = "dispel"},
                }
            },
            -- Protection Paladin
            [enums.class_spec_id.spec_enum.PROTECTION_PALADIN] = {
                offensive = {
                    {id = 35395, name = "Crusader Strike", priority = 1},
                    {id = 53600, name = "Shield of the Righteous", priority = 2},
                    {id = 31935, name = "Avenger's Shield", priority = 3},
                    {id = 26573, name = "Consecration", priority = 4},
                },
                defensive = {
                    {id = 86659, name = "Guardian of Ancient Kings", health_threshold = 0.3},
                    {id = 642, name = "Divine Shield", health_threshold = 0.2},
                    {id = 853, name = "Hammer of Justice", priority = 1},
                },
                utility = {
                    {id = 96231, name = "Rebuke", type = "interrupt"},
                    {id = 62124, name = "Hand of Reckoning", type = "taunt"},
                }
            },
            -- Retribution Paladin
            [enums.class_spec_id.spec_enum.RETRIBUTION_PALADIN] = {
                offensive = {
                    {id = 35395, name = "Crusader Strike", priority = 1},
                    {id = 53385, name = "Divine Storm", priority = 2},
                    {id = 184575, name = "Blade of Justice", priority = 3},
                    {id = 85256, name = "Templar's Verdict", priority = 4},
                },
                defensive = {
                    {id = 498, name = "Divine Protection", health_threshold = 0.4},
                    {id = 642, name = "Divine Shield", health_threshold = 0.2},
                },
                utility = {
                    {id = 96231, name = "Rebuke", type = "interrupt"},
                    {id = 853, name = "Hammer of Justice", type = "stun"},
                }
            }
        },
        [enums.class_id.MAGE] = {
            -- Arcane Mage
            [enums.class_spec_id.spec_enum.ARCANE_MAGE] = {
                offensive = {
                    {id = 5143, name = "Arcane Missiles", priority = 1},
                    {id = 30451, name = "Arcane Blast", priority = 2},
                    {id = 44425, name = "Arcane Orb", priority = 3},
                    {id = 12042, name = "Arcane Power", priority = 4},
                },
                defensive = {
                    {id = 45438, name = "Ice Block", health_threshold = 0.2},
                    {id = 1463, name = "Mana Shield", health_threshold = 0.5},
                    {id = 543, name = "Mage Ward", priority = 1},
                },
                utility = {
                    {id = 2139, name = "Counterspell", type = "interrupt"},
                    {id = 118, name = "Polymorph", type = "cc"},
                }
            },
            -- Fire Mage
            [enums.class_spec_id.spec_enum.FIRE_MAGE] = {
                offensive = {
                    {id = 133, name = "Fireball", priority = 1},
                    {id = 2120, name = "Flamestrike", priority = 2},
                    {id = 11366, name = "Pyroblast", priority = 3},
                    {id = 2136, name = "Fire Blast", priority = 4},
                },
                defensive = {
                    {id = 45438, name = "Ice Block", health_threshold = 0.2},
                    {id = 1463, name = "Mana Shield", health_threshold = 0.5},
                },
                utility = {
                    {id = 2139, name = "Counterspell", type = "interrupt"},
                    {id = 118, name = "Polymorph", type = "cc"},
                }
            },
            -- Frost Mage
            [enums.class_spec_id.spec_enum.FROST_MAGE] = {
                offensive = {
                    {id = 116, name = "Frostbolt", priority = 1},
                    {id = 30455, name = "Ice Lance", priority = 2},
                    {id = 44614, name = "Flurry", priority = 3},
                    {id = 84714, name = "Frozen Orb", priority = 4},
                },
                defensive = {
                    {id = 45438, name = "Ice Block", health_threshold = 0.2},
                    {id = 1463, name = "Mana Shield", health_threshold = 0.5},
                    {id = 11426, name = "Ice Barrier", priority = 1},
                },
                utility = {
                    {id = 2139, name = "Counterspell", type = "interrupt"},
                    {id = 118, name = "Polymorph", type = "cc"},
                }
            }
        },
        [enums.class_id.PRIEST] = {
            -- Discipline Priest
            [enums.class_spec_id.spec_enum.DISCIPLINE_PRIEST] = {
                offensive = {
                    {id = 585, name = "Smite", priority = 1},
                    {id = 47540, name = "Penance", priority = 2},
                    {id = 129250, name = "Power Word: Solace", priority = 3},
                },
                defensive = {
                    {id = 47585, name = "Dispersion", health_threshold = 0.3},
                    {id = 19236, name = "Desperate Prayer", health_threshold = 0.4},
                    {id = 17, name = "Power Word: Shield", priority = 1},
                },
                healing = {
                    {id = 2061, name = "Flash Heal", health_threshold = 0.6},
                    {id = 2060, name = "Greater Heal", health_threshold = 0.5},
                    {id = 47540, name = "Penance", health_threshold = 0.7},
                },
                utility = {
                    {id = 15487, name = "Silence", type = "interrupt"},
                    {id = 527, name = "Purify", type = "dispel"},
                }
            },
            -- Holy Priest
            [enums.class_spec_id.spec_enum.HOLY_PRIEST] = {
                offensive = {
                    {id = 585, name = "Smite", priority = 1},
                    {id = 14914, name = "Holy Fire", priority = 2},
                },
                defensive = {
                    {id = 47585, name = "Dispersion", health_threshold = 0.3},
                    {id = 19236, name = "Desperate Prayer", health_threshold = 0.4},
                },
                healing = {
                    {id = 2061, name = "Flash Heal", health_threshold = 0.6},
                    {id = 2060, name = "Greater Heal", health_threshold = 0.5},
                    {id = 139, name = "Renew", health_threshold = 0.8},
                    {id = 596, name = "Prayer of Healing", priority = 1},
                },
                utility = {
                    {id = 15487, name = "Silence", type = "interrupt"},
                    {id = 527, name = "Purify", type = "dispel"},
                }
            },
            -- Shadow Priest
            [enums.class_spec_id.spec_enum.SHADOW_PRIEST] = {
                offensive = {
                    {id = 8092, name = "Mind Blast", priority = 1},
                    {id = 589, name = "Shadow Word: Pain", priority = 2},
                    {id = 34914, name = "Vampiric Touch", priority = 3},
                    {id = 15407, name = "Mind Flay", priority = 4},
                },
                defensive = {
                    {id = 47585, name = "Dispersion", health_threshold = 0.3},
                    {id = 19236, name = "Desperate Prayer", health_threshold = 0.4},
                },
                utility = {
                    {id = 15487, name = "Silence", type = "interrupt"},
                    {id = 8122, name = "Psychic Scream", type = "fear"},
                }
            }
        },
        [enums.class_id.HUNTER] = {
            -- Beast Mastery Hunter
            [enums.class_spec_id.spec_enum.BEAST_MASTERY_HUNTER] = {
                offensive = {
                    {id = 19434, name = "Aimed Shot", priority = 1},
                    {id = 56641, name = "Steady Shot", priority = 2},
                    {id = 131894, name = "A Murder of Crows", priority = 3},
                    {id = 217200, name = "Barbed Shot", priority = 4},
                },
                defensive = {
                    {id = 5384, name = "Feign Death", health_threshold = 0.3},
                    {id = 109304, name = "Exhilaration", health_threshold = 0.5},
                },
                utility = {
                    {id = 147362, name = "Counter Shot", type = "interrupt"},
                    {id = 187650, name = "Freezing Trap", type = "cc"},
                }
            },
            -- Marksmanship Hunter
            [enums.class_spec_id.spec_enum.MARKSMANSHIP_HUNTER] = {
                offensive = {
                    {id = 19434, name = "Aimed Shot", priority = 1},
                    {id = 56641, name = "Steady Shot", priority = 2},
                    {id = 257044, name = "Rapid Fire", priority = 3},
                    {id = 212431, name = "Explosive Shot", priority = 4},
                },
                defensive = {
                    {id = 5384, name = "Feign Death", health_threshold = 0.3},
                    {id = 109304, name = "Exhilaration", health_threshold = 0.5},
                },
                utility = {
                    {id = 147362, name = "Counter Shot", type = "interrupt"},
                    {id = 187650, name = "Freezing Trap", type = "cc"},
                }
            },
            -- Survival Hunter
            [enums.class_spec_id.spec_enum.SURVIVAL_HUNTER] = {
                offensive = {
                    {id = 186270, name = "Raptor Strike", priority = 1},
                    {id = 259491, name = "Serpent Sting", priority = 2},
                    {id = 190925, name = "Harpoon", priority = 3},
                    {id = 212436, name = "Butchery", priority = 4},
                },
                defensive = {
                    {id = 5384, name = "Feign Death", health_threshold = 0.3},
                    {id = 109304, name = "Exhilaration", health_threshold = 0.5},
                },
                utility = {
                    {id = 187707, name = "Muzzle", type = "interrupt"},
                    {id = 187650, name = "Freezing Trap", type = "cc"},
                }
            }
        },
        [enums.class_id.ROGUE] = {
            -- Assassination Rogue
            [enums.class_spec_id.spec_enum.ASSASSINATION_ROGUE] = {
                offensive = {
                    {id = 1752, name = "Sinister Strike", priority = 1},
                    {id = 703, name = "Garrote", priority = 2},
                    {id = 1943, name = "Rupture", priority = 3},
                    {id = 32645, name = "Envenom", priority = 4},
                },
                defensive = {
                    {id = 5277, name = "Evasion", health_threshold = 0.4},
                    {id = 1966, name = "Feint", health_threshold = 0.6},
                    {id = 31224, name = "Cloak of Shadows", priority = 1},
                },
                utility = {
                    {id = 1766, name = "Kick", type = "interrupt"},
                    {id = 2094, name = "Blind", type = "cc"},
                    {id = 1833, name = "Cheap Shot", type = "stun"},
                }
            },
            -- Outlaw Rogue
            [enums.class_spec_id.spec_enum.OUTLAW_ROGUE] = {
                offensive = {
                    {id = 1752, name = "Sinister Strike", priority = 1},
                    {id = 185763, name = "Pistol Shot", priority = 2},
                    {id = 195457, name = "Grappling Hook", priority = 3},
                    {id = 271877, name = "Blade Flurry", priority = 4},
                },
                defensive = {
                    {id = 5277, name = "Evasion", health_threshold = 0.4},
                    {id = 1966, name = "Feint", health_threshold = 0.6},
                    {id = 31224, name = "Cloak of Shadows", priority = 1},
                },
                utility = {
                    {id = 1766, name = "Kick", type = "interrupt"},
                    {id = 2094, name = "Blind", type = "cc"},
                }
            },
            -- Subtlety Rogue
            [enums.class_spec_id.spec_enum.SUBTLETY_ROGUE] = {
                offensive = {
                    {id = 1752, name = "Sinister Strike", priority = 1},
                    {id = 280719, name = "Secret Technique", priority = 2},
                    {id = 185438, name = "Shadowstrike", priority = 3},
                    {id = 53, name = "Backstab", priority = 4},
                },
                defensive = {
                    {id = 5277, name = "Evasion", health_threshold = 0.4},
                    {id = 1966, name = "Feint", health_threshold = 0.6},
                    {id = 31224, name = "Cloak of Shadows", priority = 1},
                },
                utility = {
                    {id = 1766, name = "Kick", type = "interrupt"},
                    {id = 2094, name = "Blind", type = "cc"},
                }
            }
        },
        [enums.class_id.DEATHKNIGHT] = {
            -- Blood Death Knight
            [enums.class_spec_id.spec_enum.BLOOD_DEATHKNIGHT] = {
                offensive = {
                    {id = 49930, name = "Blood Strike", priority = 1},
                    {id = 195292, name = "Death's Caress", priority = 2},
                    {id = 50842, name = "Blood Boil", priority = 3},
                    {id = 85948, name = "Festering Strike", priority = 4},
                },
                defensive = {
                    {id = 48707, name = "Anti-Magic Shell", health_threshold = 0.5},
                    {id = 55233, name = "Vampiric Blood", health_threshold = 0.4},
                    {id = 194679, name = "Rune Tap", health_threshold = 0.6},
                },
                utility = {
                    {id = 47528, name = "Mind Freeze", type = "interrupt"},
                    {id = 56222, name = "Dark Command", type = "taunt"},
                }
            },
            -- Frost Death Knight
            [enums.class_spec_id.spec_enum.FROST_DEATHKNIGHT] = {
                offensive = {
                    {id = 49143, name = "Frost Strike", priority = 1},
                    {id = 196770, name = "Remorseless Winter", priority = 2},
                    {id = 49020, name = "Obliterate", priority = 3},
                    {id = 207230, name = "Frostscythe", priority = 4},
                },
                defensive = {
                    {id = 48707, name = "Anti-Magic Shell", health_threshold = 0.5},
                    {id = 51271, name = "Pillar of Frost", priority = 1},
                },
                utility = {
                    {id = 47528, name = "Mind Freeze", type = "interrupt"},
                    {id = 45524, name = "Chains of Ice", type = "slow"},
                }
            },
            -- Unholy Death Knight
            [enums.class_spec_id.spec_enum.UNHOLY_DEATHKNIGHT] = {
                offensive = {
                    {id = 85948, name = "Festering Strike", priority = 1},
                    {id = 55090, name = "Scourge Strike", priority = 2},
                    {id = 207311, name = "Clawing Shadows", priority = 3},
                    {id = 43265, name = "Death and Decay", priority = 4},
                },
                defensive = {
                    {id = 48707, name = "Anti-Magic Shell", health_threshold = 0.5},
                    {id = 49039, name = "Lichborne", health_threshold = 0.3},
                },
                utility = {
                    {id = 47528, name = "Mind Freeze", type = "interrupt"},
                    {id = 212552, name = "Wraith Walk", type = "utility"},
                }
            }
        },
        [enums.class_id.SHAMAN] = {
            -- Elemental Shaman
            [enums.class_spec_id.spec_enum.ELEMENTAL_SHAMAN] = {
                offensive = {
                    {id = 188196, name = "Lightning Bolt", priority = 1},
                    {id = 188443, name = "Chain Lightning", priority = 2},
                    {id = 51505, name = "Lava Burst", priority = 3},
                    {id = 188089, name = "Earthen Spike", priority = 4},
                },
                defensive = {
                    {id = 108271, name = "Astral Shift", health_threshold = 0.4},
                    {id = 8004, name = "Healing Surge", health_threshold = 0.6},
                },
                healing = {
                    {id = 8004, name = "Healing Surge", health_threshold = 0.7},
                    {id = 1064, name = "Chain Heal", health_threshold = 0.6},
                    {id = 73920, name = "Healing Rain", priority = 1},
                },
                utility = {
                    {id = 57994, name = "Wind Shear", type = "interrupt"},
                    {id = 51514, name = "Hex", type = "cc"},
                }
            },
            -- Enhancement Shaman
            [enums.class_spec_id.spec_enum.ENHANCEMENT_SHAMAN] = {
                offensive = {
                    {id = 17364, name = "Stormstrike", priority = 1},
                    {id = 187837, name = "Lightning Bolt", priority = 2},
                    {id = 196884, name = "Frostbrand Weapon", priority = 3},
                    {id = 187874, name = "Crash Lightning", priority = 4},
                },
                defensive = {
                    {id = 108271, name = "Astral Shift", health_threshold = 0.4},
                    {id = 8004, name = "Healing Surge", health_threshold = 0.6},
                },
                healing = {
                    {id = 8004, name = "Healing Surge", health_threshold = 0.7},
                },
                utility = {
                    {id = 57994, name = "Wind Shear", type = "interrupt"},
                    {id = 51514, name = "Hex", type = "cc"},
                }
            },
            -- Restoration Shaman
            [enums.class_spec_id.spec_enum.RESTORATION_SHAMAN] = {
                offensive = {
                    {id = 188196, name = "Lightning Bolt", priority = 1},
                    {id = 188443, name = "Chain Lightning", priority = 2},
                },
                defensive = {
                    {id = 108271, name = "Astral Shift", health_threshold = 0.4},
                    {id = 8004, name = "Healing Surge", health_threshold = 0.6},
                },
                healing = {
                    {id = 8004, name = "Healing Surge", health_threshold = 0.7},
                    {id = 1064, name = "Chain Heal", health_threshold = 0.6},
                    {id = 73920, name = "Healing Rain", priority = 1},
                    {id = 61295, name = "Riptide", health_threshold = 0.8},
                },
                utility = {
                    {id = 57994, name = "Wind Shear", type = "interrupt"},
                    {id = 77130, name = "Purify Spirit", type = "dispel"},
                }
            }
        },
        [enums.class_id.WARLOCK] = {
            -- Affliction Warlock
            [enums.class_spec_id.spec_enum.AFFLICTION_WARLOCK] = {
                offensive = {
                    {id = 172, name = "Corruption", priority = 1},
                    {id = 980, name = "Agony", priority = 2},
                    {id = 198590, name = "Drain Soul", priority = 3},
                    {id = 63106, name = "Siphon Soul", priority = 4},
                },
                defensive = {
                    {id = 104773, name = "Unending Resolve", health_threshold = 0.3},
                    {id = 6229, name = "Shadow Ward", health_threshold = 0.5},
                },
                utility = {
                    {id = 19647, name = "Spell Lock", type = "interrupt"},
                    {id = 5782, name = "Fear", type = "cc"},
                }
            },
            -- Demonology Warlock
            [enums.class_spec_id.spec_enum.DEMONOLOGY_WARLOCK] = {
                offensive = {
                    {id = 686, name = "Shadow Bolt", priority = 1},
                    {id = 104316, name = "Call Dreadstalkers", priority = 2},
                    {id = 111771, name = "Demonic Gateway", priority = 3},
                    {id = 105174, name = "Hand of Gul'dan", priority = 4},
                },
                defensive = {
                    {id = 104773, name = "Unending Resolve", health_threshold = 0.3},
                    {id = 6229, name = "Shadow Ward", health_threshold = 0.5},
                },
                utility = {
                    {id = 19647, name = "Spell Lock", type = "interrupt"},
                    {id = 5782, name = "Fear", type = "cc"},
                }
            },
            -- Destruction Warlock
            [enums.class_spec_id.spec_enum.DESTRUCTION_WARLOCK] = {
                offensive = {
                    {id = 116858, name = "Chaos Bolt", priority = 1},
                    {id = 348, name = "Immolate", priority = 2},
                    {id = 17877, name = "Shadowburn", priority = 3},
                    {id = 5740, name = "Rain of Fire", priority = 4},
                },
                defensive = {
                    {id = 104773, name = "Unending Resolve", health_threshold = 0.3},
                    {id = 6229, name = "Shadow Ward", health_threshold = 0.5},
                },
                utility = {
                    {id = 19647, name = "Spell Lock", type = "interrupt"},
                    {id = 5782, name = "Fear", type = "cc"},
                }
            }
        },
        [enums.class_id.MONK] = {
            -- Brewmaster Monk
            [enums.class_spec_id.spec_enum.BREWMASTER_MONK] = {
                offensive = {
                    {id = 100780, name = "Tiger Palm", priority = 1},
                    {id = 205523, name = "Blackout Strike", priority = 2},
                    {id = 121253, name = "Keg Smash", priority = 3},
                    {id = 115181, name = "Breath of Fire", priority = 4},
                },
                defensive = {
                    {id = 115203, name = "Fortifying Brew", health_threshold = 0.4},
                    {id = 115176, name = "Zen Meditation", health_threshold = 0.3},
                },
                utility = {
                    {id = 116705, name = "Spear Hand Strike", type = "interrupt"},
                    {id = 115546, name = "Provoke", type = "taunt"},
                }
            },
            -- Mistweaver Monk
            [enums.class_spec_id.spec_enum.MISTWEAVER_MONK] = {
                offensive = {
                    {id = 100780, name = "Tiger Palm", priority = 1},
                    {id = 107428, name = "Rising Sun Kick", priority = 2},
                },
                defensive = {
                    {id = 115203, name = "Fortifying Brew", health_threshold = 0.4},
                    {id = 116849, name = "Life Cocoon", health_threshold = 0.2},
                },
                healing = {
                    {id = 116670, name = "Vivify", health_threshold = 0.7},
                    {id = 115151, name = "Renewing Mist", health_threshold = 0.8},
                    {id = 191837, name = "Essence Font", priority = 1},
                },
                utility = {
                    {id = 116705, name = "Spear Hand Strike", type = "interrupt"},
                    {id = 115450, name = "Detox", type = "dispel"},
                }
            },
            -- Windwalker Monk
            [enums.class_spec_id.spec_enum.WINDWALKER_MONK] = {
                offensive = {
                    {id = 100780, name = "Tiger Palm", priority = 1},
                    {id = 107428, name = "Rising Sun Kick", priority = 2},
                    {id = 113656, name = "Fists of Fury", priority = 3},
                    {id = 101545, name = "Flying Serpent Kick", priority = 4},
                },
                defensive = {
                    {id = 115203, name = "Fortifying Brew", health_threshold = 0.4},
                    {id = 122783, name = "Diffuse Magic", health_threshold = 0.5},
                },
                utility = {
                    {id = 116705, name = "Spear Hand Strike", type = "interrupt"},
                    {id = 119381, name = "Leg Sweep", type = "stun"},
                }
            }
        },
        [enums.class_id.DRUID] = {
            -- Balance Druid
            [enums.class_spec_id.spec_enum.BALANCE_DRUID] = {
                offensive = {
                    {id = 190984, name = "Wrath", priority = 1},
                    {id = 194153, name = "Starfire", priority = 2},
                    {id = 93402, name = "Sunfire", priority = 3},
                    {id = 164812, name = "Moonfire", priority = 4},
                },
                defensive = {
                    {id = 22812, name = "Barkskin", health_threshold = 0.5},
                    {id = 108238, name = "Renewal", health_threshold = 0.4},
                },
                healing = {
                    {id = 8936, name = "Regrowth", health_threshold = 0.7},
                    {id = 18562, name = "Swiftmend", health_threshold = 0.6},
                },
                utility = {
                    {id = 78675, name = "Solar Beam", type = "interrupt"},
                    {id = 339, name = "Entangling Roots", type = "cc"},
                }
            },
            -- Feral Druid
            [enums.class_spec_id.spec_enum.FERAL_DRUID] = {
                offensive = {
                    {id = 1822, name = "Rake", priority = 1},
                    {id = 5221, name = "Shred", priority = 2},
                    {id = 1079, name = "Rip", priority = 3},
                    {id = 22568, name = "Ferocious Bite", priority = 4},
                },
                defensive = {
                    {id = 22812, name = "Barkskin", health_threshold = 0.5},
                    {id = 61336, name = "Survival Instincts", health_threshold = 0.3},
                },
                utility = {
                    {id = 106839, name = "Skull Bash", type = "interrupt"},
                    {id = 99, name = "Disorienting Roar", type = "disorient"},
                }
            },
            -- Guardian Druid
            [enums.class_spec_id.spec_enum.GUARDIAN_DRUID] = {
                offensive = {
                    {id = 33917, name = "Mangle", priority = 1},
                    {id = 213771, name = "Swipe", priority = 2},
                    {id = 77758, name = "Thrash", priority = 3},
                    {id = 6807, name = "Maul", priority = 4},
                },
                defensive = {
                    {id = 22812, name = "Barkskin", health_threshold = 0.5},
                    {id = 61336, name = "Survival Instincts", health_threshold = 0.3},
                    {id = 200851, name = "Rage of the Sleeper", health_threshold = 0.4},
                },
                utility = {
                    {id = 106839, name = "Skull Bash", type = "interrupt"},
                    {id = 6795, name = "Growl", type = "taunt"},
                }
            },
            -- Restoration Druid
            [enums.class_spec_id.spec_enum.RESTORATION_DRUID] = {
                offensive = {
                    {id = 190984, name = "Wrath", priority = 1},
                    {id = 164812, name = "Moonfire", priority = 2},
                },
                defensive = {
                    {id = 22812, name = "Barkskin", health_threshold = 0.5},
                    {id = 108238, name = "Renewal", health_threshold = 0.4},
                },
                healing = {
                    {id = 8936, name = "Regrowth", health_threshold = 0.7},
                    {id = 18562, name = "Swiftmend", health_threshold = 0.6},
                    {id = 774, name = "Rejuvenation", health_threshold = 0.8},
                    {id = 48438, name = "Wild Growth", priority = 1},
                },
                utility = {
                    {id = 78675, name = "Solar Beam", type = "interrupt"},
                    {id = 2782, name = "Remove Corruption", type = "dispel"},
                }
            }
        },
        [enums.class_id.DEMONHUNTER] = {
            -- Havoc Demon Hunter
            [enums.class_spec_id.spec_enum.HAVOC_DEMON_HUNTER] = {
                offensive = {
                    {id = 162243, name = "Demon's Bite", priority = 1},
                    {id = 188499, name = "Blade Dance", priority = 2},
                    {id = 201427, name = "Annihilation", priority = 3},
                    {id = 195072, name = "Fel Rush", priority = 4},
                },
                defensive = {
                    {id = 198589, name = "Blur", health_threshold = 0.4},
                    {id = 187827, name = "Metamorphosis", health_threshold = 0.3},
                },
                utility = {
                    {id = 183752, name = "Disrupt", type = "interrupt"},
                    {id = 217832, name = "Imprison", type = "cc"},
                }
            },
            -- Vengeance Demon Hunter
            [enums.class_spec_id.spec_enum.VENGEANCE_DEMON_HUNTER] = {
                offensive = {
                    {id = 204157, name = "Throw Glaive", priority = 1},
                    {id = 228477, name = "Soul Cleave", priority = 2},
                    {id = 204596, name = "Sigil of Flame", priority = 3},
                    {id = 207407, name = "Soul Carver", priority = 4},
                },
                defensive = {
                    {id = 196555, name = "Netherwalk", health_threshold = 0.3},
                    {id = 187827, name = "Metamorphosis", health_threshold = 0.2},
                    {id = 203720, name = "Demon Spikes", health_threshold = 0.6},
                },
                utility = {
                    {id = 183752, name = "Disrupt", type = "interrupt"},
                    {id = 185123, name = "Throw Glaive", type = "taunt"},
                }
            }
        },
        [enums.class_id.EVOKER] = {
            -- Devastation Evoker
            [enums.class_spec_id.spec_enum.EVOKER_DEVASTATION] = {
                offensive = {
                    {id = 362969, name = "Azure Strike", priority = 1},
                    {id = 359073, name = "Eternity Surge", priority = 2},
                    {id = 357208, name = "Fire Breath", priority = 3},
                    {id = 358385, name = "Landslide", priority = 4},
                },
                defensive = {
                    {id = 363916, name = "Obsidian Scales", health_threshold = 0.5},
                    {id = 374348, name = "Renewing Blaze", health_threshold = 0.4},
                },
                utility = {
                    {id = 351338, name = "Quell", type = "interrupt"},
                    {id = 360806, name = "Sleep Walk", type = "cc"},
                }
            },
            -- Preservation Evoker
            [enums.class_spec_id.spec_enum.EVOKER_PRESERVATION] = {
                offensive = {
                    {id = 362969, name = "Azure Strike", priority = 1},
                    {id = 357208, name = "Fire Breath", priority = 2},
                },
                defensive = {
                    {id = 363916, name = "Obsidian Scales", health_threshold = 0.5},
                    {id = 374348, name = "Renewing Blaze", health_threshold = 0.4},
                },
                healing = {
                    {id = 361469, name = "Living Flame", health_threshold = 0.7},
                    {id = 355913, name = "Emerald Blossom", health_threshold = 0.6},
                    {id = 367230, name = "Spiritbloom", health_threshold = 0.5},
                },
                utility = {
                    {id = 351338, name = "Quell", type = "interrupt"},
                    {id = 360823, name = "Naturalize", type = "dispel"},
                }
            },
            -- Augmentation Evoker
            [enums.class_spec_id.spec_enum.EVOKER_AUGMENTATION] = {
                offensive = {
                    {id = 362969, name = "Azure Strike", priority = 1},
                    {id = 395152, name = "Ebon Might", priority = 2},
                    {id = 357208, name = "Fire Breath", priority = 3},
                },
                defensive = {
                    {id = 363916, name = "Obsidian Scales", health_threshold = 0.5},
                    {id = 374348, name = "Renewing Blaze", health_threshold = 0.4},
                },
                utility = {
                    {id = 351338, name = "Quell", type = "interrupt"},
                    {id = 360806, name = "Sleep Walk", type = "cc"},
                }
            }
        }
    }
end

-- Initialize spell data
initialize_class_spells()

-- Get current class spells
local function get_current_class_spells()
    local class_data = class_spells[player_class]
    if not class_data then
        return {}
    end
    
    return class_data[player_spec] or {}
end

-- Check if spell is available and castable
local function is_spell_available(spell_id, caster, target)
    if not spell_helper:has_spell_equipped(spell_id) then
        return false
    end
    
    if spell_helper:is_spell_on_cooldown(spell_id) then
        return false
    end
    
    if target then
        return spell_helper:is_spell_castable(spell_id, caster, target, false, false)
    else
        return spell_helper:is_spell_castable(spell_id, caster, caster, false, false)
    end
end

-- Cast offensive spells
local function cast_offensive_spells(caster, target)
    if not menu_elements.enable_offensive:get_state() then
        return false
    end
    
    local current_spells = get_current_class_spells()
    local offensive_spells = current_spells.offensive or {}
    
    -- Sort by priority
    table.sort(offensive_spells, function(a, b)
        return (a.priority or 999) < (b.priority or 999)
    end)
    
    for _, spell_data in ipairs(offensive_spells) do
        if is_spell_available(spell_data.id, caster, target) then
            -- Check if it's an AoE spell and we have multiple targets
            if spell_data.name == "Flamestrike" or spell_data.name == "Divine Storm" or 
               spell_data.name == "Thunder Clap" or spell_data.name == "Consecration" then
                local enemies_around = unit_helper:get_enemy_list_around(target:get_position(), 8.0)
                if #enemies_around > 1 then
                    -- Use position cast for AoE spells
                    if core.spell_book.is_spell_position_cast(spell_data.id) then
                        spell_queue:queue_spell_position(spell_data.id, target:get_position(), 1, 
                            "AIO: Casting " .. spell_data.name)
                    else
                        spell_queue:queue_spell_target(spell_data.id, target, 1, 
                            "AIO: Casting " .. spell_data.name)
                    end
                    return true
                end
            else
                -- Single target spell
                spell_queue:queue_spell_target(spell_data.id, target, 1, 
                    "AIO: Casting " .. spell_data.name)
                return true
            end
        end
    end
    
    return false
end

-- Cast defensive spells
local function cast_defensive_spells(caster)
    if not menu_elements.enable_defensive:get_state() then
        return false
    end
    
    local current_health = unit_helper:get_health_percentage(caster)
    local defensive_threshold = menu_elements.defensive_health_threshold:get()
    
    if current_health > defensive_threshold then
        return false
    end
    
    local current_spells = get_current_class_spells()
    local defensive_spells = current_spells.defensive or {}
    
    -- Sort by priority, but prioritize health threshold spells when health is low
    table.sort(defensive_spells, function(a, b)
        local a_threshold = a.health_threshold or 1.0
        local b_threshold = b.health_threshold or 1.0
        
        if current_health <= a_threshold and current_health > b_threshold then
            return true
        elseif current_health <= b_threshold and current_health > a_threshold then
            return false
        end
        
        return (a.priority or 999) < (b.priority or 999)
    end)
    
    for _, spell_data in ipairs(defensive_spells) do
        local health_threshold = spell_data.health_threshold or defensive_threshold
        
        if current_health <= health_threshold and is_spell_available(spell_data.id, caster, nil) then
            spell_queue:queue_spell_target(spell_data.id, caster, 1, 
                "AIO: Casting Defensive " .. spell_data.name)
            return true
        end
    end
    
    return false
end

-- Cast healing spells
local function cast_healing_spells(caster)
    if not menu_elements.enable_healing:get_state() then
        return false
    end
    
    local current_spells = get_current_class_spells()
    local healing_spells = current_spells.healing or {}
    
    if #healing_spells == 0 then
        return false
    end
    
    -- Get healing targets
    local heal_targets = target_selector:get_targets_heal(3)
    
    for _, heal_target in ipairs(heal_targets) do
        -- Skip targets in cyclone or other immunity
        if pvp_helper:is_crowd_controlled(heal_target, pvp_helper.cc_flags.combine("CYCLONE"), 100) then
            goto continue
        end
        
        local target_health = unit_helper:get_health_percentage(heal_target)
        local healing_threshold = menu_elements.healing_health_threshold:get()
        
        if target_health < healing_threshold then
            for _, spell_data in ipairs(healing_spells) do
                local spell_threshold = spell_data.health_threshold or healing_threshold
                
                if target_health <= spell_threshold and is_spell_available(spell_data.id, caster, heal_target) then
                    spell_queue:queue_spell_target(spell_data.id, heal_target, 1, 
                        "AIO: Healing " .. heal_target:get_name() .. " with " .. spell_data.name)
                    return true
                end
            end
        end
        
        ::continue::
    end
    
    return false
end

-- Cast utility spells (interrupts, dispels, etc.)
local function cast_utility_spells(caster, target)
    local current_spells = get_current_class_spells()
    local utility_spells = current_spells.utility or {}
    
    for _, spell_data in ipairs(utility_spells) do
        if spell_data.type == "interrupt" and menu_elements.interrupt_enabled:get_state() then
            -- Check if target is casting and interruptible
            if target and target:is_casting() and is_spell_available(spell_data.id, caster, target) then
                spell_queue:queue_spell_target(spell_data.id, target, 1, 
                    "AIO: Interrupting " .. target:get_name())
                return true
            end
        elseif spell_data.type == "dispel" and menu_elements.dispel_enabled:get_state() then
            -- Basic dispel logic - can be expanded
            if is_spell_available(spell_data.id, caster, target) then
                spell_queue:queue_spell_target(spell_data.id, target, 1, 
                    "AIO: Dispelling " .. target:get_name())
                return true
            end
        end
    end
    
    return false
end

-- Main rotation logic
local function execute_rotation()
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return
    end
    
    -- Check if script is enabled
    if not menu_elements.enable_script:get_state() then
        return
    end
    
    -- Check if toggled on
    if not plugin_helper:is_toggle_enabled(menu_elements.enable_toggle) then
        return
    end
    
    -- Defensive logic first (highest priority)
    if cast_defensive_spells(local_player) then
        return
    end
    
    -- Healing logic (second priority)
    if cast_healing_spells(local_player) then
        return
    end
    
    -- Get targets for offensive actions
    local targets = target_selector:get_targets(3)
    
    for _, target in ipairs(targets) do
        -- Check if target is in combat
        if not unit_helper:is_in_combat(target) then
            goto continue
        end
        
        -- Check if target is immune to damage
        if pvp_helper:is_damage_immune(target, pvp_helper.damage_type_flags.ANY) then
            goto continue
        end
        
        -- Check if target is in CC that we shouldn't break
        if pvp_helper:is_crowd_controlled(target, 
            pvp_helper.cc_flags.combine("DISORIENT", "INCAPACITATE", "SAP"), 1000) then
            goto continue
        end
        
        -- Try utility spells first
        if cast_utility_spells(local_player, target) then
            return
        end
        
        -- Try offensive spells
        if cast_offensive_spells(local_player, target) then
            return
        end
        
        ::continue::
    end
end

-- Override target selector settings
local ts_overridden = false
local function override_target_selector()
    if ts_overridden then
        return
    end
    
    if not menu_elements.override_target_selector:get_state() then
        return
    end
    
    -- Set general target selector settings
    target_selector.menu_elements.settings.max_range_damage:set(menu_elements.combat_range:get())
    target_selector.menu_elements.settings.max_range_heal:set(menu_elements.healing_range:get())
    
    -- Enable multiple hits weighting for AoE classes
    if player_class == enums.class_id.MAGE or player_class == enums.class_id.WARLOCK then
        target_selector.menu_elements.damage.weight_multiple_hits:set(true)
        target_selector.menu_elements.damage.slider_weight_multiple_hits:set(3)
        target_selector.menu_elements.damage.slider_weight_multiple_hits_radius:set(8)
    end
    
    ts_overridden = true
end

-- Menu rendering
local function render_menu()
    menu_elements.main_tree:render("AIO Combat Rotation", function()
        menu_elements.enable_script:render("Enable AIO System")
        
        if not menu_elements.enable_script:get_state() then
            return
        end
        
        menu_elements.keybinds_tree:render("Keybinds", function()
            menu_elements.enable_toggle:render("Enable/Disable Toggle")
        end)
        
        menu_elements.class_settings_tree:render("Combat Settings", function()
            menu_elements.enable_offensive:render("Enable Offensive")
            menu_elements.enable_defensive:render("Enable Defensive")
            menu_elements.enable_healing:render("Enable Healing")
            
            menu_elements.burst_mode:render("Burst Mode")
            menu_elements.interrupt_enabled:render("Auto Interrupt")
            menu_elements.dispel_enabled:render("Auto Dispel")
            
            menu_elements.defensive_health_threshold:render("Defensive Health Threshold")
            menu_elements.healing_health_threshold:render("Healing Health Threshold")
            
            menu_elements.combat_range:render("Combat Range")
            menu_elements.healing_range:render("Healing Range")
        end)
        
        menu_elements.auto_target:render("Auto Target")
        menu_elements.override_target_selector:render("Override Target Selector Settings")
        menu_elements.draw_plugin_state:render("Draw Plugin State")
    end)
end

-- Update callback
local function on_update()
    control_panel_helper:on_update(menu_elements)
    
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return
    end
    
    override_target_selector()
    execute_rotation()
end

-- Render callback
local function on_render()
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return
    end
    
    if not menu_elements.enable_script:get_state() then
        return
    end
    
    if not plugin_helper:is_toggle_enabled(menu_elements.enable_toggle) then
        if menu_elements.draw_plugin_state:get_state() then
            plugin_helper:draw_text_character_center("AIO: DISABLED")
        end
    else
        if menu_elements.draw_plugin_state:get_state() then
            local class_name = enums.class_id_to_name[player_class] or "Unknown"
            plugin_helper:draw_text_character_center("AIO: " .. class_name .. " ACTIVE")
        end
    end
end

-- Control panel render
local function on_control_panel_render()
    local control_panel_elements = {}
    
    control_panel_helper:insert_toggle(control_panel_elements, {
        name = "[AIO] Enable (" .. key_helper:get_key_name(menu_elements.enable_toggle:get_key_code()) .. ")",
        keybind = menu_elements.enable_toggle
    })
    
    return control_panel_elements
end

-- Register callbacks
core.register_on_update_callback(on_update)
core.register_on_render_callback(on_render)
core.register_on_render_menu_callback(render_menu)
core.register_on_render_control_panel_callback(on_control_panel_render)