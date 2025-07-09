# AIO Combat Rotation System

## Overview
The AIO (All-In-One) Combat Rotation System is an advanced combat rotation plugin that handles all classes and specializations in World of Warcraft using the project's custom API.

## Features
- **Universal Class Support**: Handles all 13 classes and all their specializations
- **Smart Target Prioritization**: Automatically selects the best target based on multiple factors
- **Resource Management**: Conserves resources when needed to prevent running out of mana/energy
- **Defensive Automation**: Automatically uses defensive abilities when health drops below thresholds
- **Healing Support**: Provides healing for classes that can heal themselves or others
- **Interrupt System**: Automatically interrupts enemy spellcasting
- **Burst Mode**: Prioritizes high-damage abilities when enabled
- **AoE Detection**: Automatically switches to AoE spells when multiple enemies are present
- **PvP Awareness**: Understands crowd control, damage immunity, and PvP mechanics

## Installation
1. Copy the `aio_combat_rotation` folder to your `scripts` directory
2. Restart the application to load the plugin
3. The plugin will be available in the menu system

## Configuration
The AIO system provides extensive configuration options:

### Main Settings
- **Enable AIO System**: Master toggle for the entire system
- **Enable/Disable Toggle**: Keybind to quickly enable/disable the rotation
- **Combat Settings**: Enable/disable offensive, defensive, and healing behaviors
- **Burst Mode**: Prioritizes high-damage abilities
- **Auto Interrupt**: Automatically interrupts enemy casting
- **Auto Dispel**: Automatically dispels harmful effects

### Health Thresholds
- **Defensive Health Threshold**: Health percentage at which defensive abilities activate
- **Healing Health Threshold**: Health percentage at which healing abilities activate

### Range Settings
- **Combat Range**: Maximum range for offensive abilities
- **Healing Range**: Maximum range for healing abilities

### Target Selector Override
- **Override Target Selector Settings**: Automatically configures the target selector for optimal performance

## Supported Classes and Specializations

### Warrior
- **Arms**: Mortal Strike, Execute, Rend, Sweeping Strikes
- **Fury**: Raging Blow, Execute, Rampage, Bloodthirst
- **Protection**: Shield Slam, Revenge, Thunder Clap (tank rotation)

### Paladin
- **Holy**: Healing-focused with offensive support
- **Protection**: Tank rotation with defensive priorities
- **Retribution**: Melee DPS with burst capabilities

### Hunter
- **Beast Mastery**: Pet-focused ranged DPS
- **Marksmanship**: Precision ranged DPS
- **Survival**: Melee/ranged hybrid DPS

### Rogue
- **Assassination**: Poison-based DPS with stealth
- **Outlaw**: Combo-based DPS with utilities
- **Subtlety**: Stealth-based DPS with burst

### Priest
- **Discipline**: Damage-based healing
- **Holy**: Pure healing specialization
- **Shadow**: DoT-based DPS

### Death Knight
- **Blood**: Tank specialization with self-healing
- **Frost**: Melee DPS with frost magic
- **Unholy**: Disease-based DPS with minions

### Shaman
- **Elemental**: Ranged magical DPS
- **Enhancement**: Melee DPS with elemental magic
- **Restoration**: Healing specialization

### Mage
- **Arcane**: Mana-based burst DPS
- **Fire**: Fire-based DPS with critical strikes
- **Frost**: Control-based DPS with slows

### Warlock
- **Affliction**: DoT-based DPS
- **Demonology**: Demon-summoning DPS
- **Destruction**: Direct damage DPS

### Monk
- **Brewmaster**: Tank specialization
- **Mistweaver**: Healing specialization
- **Windwalker**: Melee DPS

### Druid
- **Balance**: Ranged magical DPS
- **Feral**: Melee DPS in cat form
- **Guardian**: Tank specialization in bear form
- **Restoration**: Healing specialization

### Demon Hunter
- **Havoc**: Melee DPS with high mobility
- **Vengeance**: Tank specialization

### Evoker
- **Devastation**: Ranged magical DPS
- **Preservation**: Healing specialization
- **Augmentation**: Support DPS

## Target Prioritization
The AIO system uses intelligent target prioritization based on:
1. **Distance**: Closer targets have higher priority
2. **Health**: Lower health targets have higher priority
3. **Casting**: Targets currently casting spells have interrupt priority
4. **Player vs NPC**: Player targets have higher priority in PvP
5. **Role**: Healers have higher priority
6. **Burst Status**: Targets with active burst abilities have higher priority

## Resource Management
The system automatically manages resources to prevent running out:
- **Mana users**: Conserve when below 30%
- **Energy users**: Conserve when below 50%
- **Rage users**: No conservation (rage decays naturally)
- **Other power types**: Conserve when below 40%

## Advanced Features

### Burst Mode
When enabled, the system prioritizes high-damage abilities:
- Execute, Chaos Bolt, Pyroblast, Templar's Verdict, Annihilation

### AoE Detection
Automatically switches to AoE abilities when multiple enemies are present:
- Flamestrike, Divine Storm, Thunder Clap, Consecration, Chain Lightning, Blade Dance

### Defensive Automation
Automatically uses defensive abilities based on health thresholds:
- Emergency abilities (Shield Wall, Ice Block) at very low health
- Damage reduction abilities at moderate health loss
- Utility defensive abilities as needed

### Healing Support
For classes with healing capabilities:
- Automatically heals party/raid members below threshold
- Prioritizes emergency healing over damage
- Skips targets in immunity effects (Cyclone, etc.)

## Troubleshooting
- Ensure the plugin is enabled in the menu
- Check that the toggle keybind is pressed
- Verify that targets are in combat and not immune to damage
- Adjust health thresholds if defensive abilities aren't triggering
- Enable "Draw Plugin State" to see current status

## Performance
The AIO system is designed to be efficient:
- Minimal API calls per frame
- Smart target caching
- Resource-aware execution
- Optimized spell priority checking

## Customization
The system is highly customizable through the menu interface. Advanced users can modify the spell data tables in `main.lua` to adjust:
- Spell priorities
- Health thresholds
- AoE detection radius
- Resource conservation levels

## Support
This AIO system uses only the project's custom API functions and is designed to work seamlessly with the existing framework. It follows the same patterns as the example fire mage plugin but extends support to all classes and specializations.