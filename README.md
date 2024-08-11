# Open-VTT
Open source Virtual Tabletop for Dungeons and Dragons and other TTRPG game systems. Based on Godot game engine. Basis for finished [bachelor's thesis](https://www.vut.cz/en/students/final-thesis/detail/156289).

Project is still activelly under development but is fully functional for the purposes of playing TTRPGs.
Goal is to implement modern video game features into a more traditional VTT formula to extend the toolbox of players and DM. Current focus for development is QOL improvements such as `Undo` system.

Project was tested on Windows machines, currently testing linux and android devices including crossplay.

If you have any requests or ideas, feel free to contact me on our [Discord Server](https://discord.gg/W3JvgEwU).

## Features

The project support basic features of other VTTs like campain and map management, rolling dice, map and grid options, characters with tokens and character sheets, item library, dynamic lighting, etc. All for free with no paywalls or subsriptions. Some of the more interisting features are listed below.

See following for more and [todo list](#todo) for features which are planned.

Feel free to make a fork and modify this project to your needs. Godot is very begginer friendly, if you will have any questions, ask me on discord.

No ruleset is prepared by default, but Virtual Tabletop strives to allow users to customize and create their own rulesets and potentially share it with other people. Currently there are no plans on official support for any ruleset to avoid copyright issues. You can share or find community rulesets on our [Discord Server](https://discord.gg/W3JvgEwU)

### Local Hosting

VTT is always hosted on your devices, so the network performance is not dependent on any central server (you won't be getting lag spikes because Roll20's servers are overloaded). Local hosting also removes limits on file size and storage capacity is only limited to the storage size of your device. Currently the hosting player is the DM (as he has access to all the campaign files), other players join as players via IP adress. To play via internet you ideally either need public IP address from your ISP (so it won't change all the time - or you can get your [public IP before every session](https://icanhazip.com/)) or use VPN software like ZeroTier. To make server accessible to internet clients without using a VPN you will need to forward the server port on your router for both TCP and UDP, as described in [Godot Docs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#hosting-considerations).

Once the project is ready for full release I will work on steam integration for easier connecting over internet. Might even consider implementing public server browser a way to look for games that are looking for players.

### Endless Maps

Maps are not restricted in their size. You could create your entire world in just one map. (Probably highly not recommended due to performance issues due to the sheer scale of a usual World and the number of objects it would require, not sure about the extent of godot optimizations, but it will extend save and load times massively). Added benefit is unknown map (dungeon) size by the players if used in combination with FOV system. The cave could be quite small or it could be the entrance to a massive labyrinth that stretches for miles, and there is no way to tell until players explore it.

### Multi-layer Support

VTT allows the DM to create and manage layers in maps in a manner simmilar to layers in image editing software, these layers can act as DM layers, map layers, token layers, etc.

This system simplifies the creation and usage of multi-layered maps, whether it is a house with cellar, 15 story wizard tower, or a big spaceship.

![Example of Multi-Layered Map](https://github.com/Khazlor/Open-VTT/blob/main/README-IMG/multilayer.gif?raw=true)


### Targetting system

Character macros have the ability to be targeted, you can access and modify attributes of both the caster and the target character in them. There are many supported targetting modes, from single target select to large area of effect shapes.

![Example of AOE targetted ability](https://github.com/Khazlor/Open-VTT/blob/main/README-IMG/AOE.gif?raw=true)

### Inventory system

Create custom items and place them in the world. Items placed on map stack in containers, items placed on character tokens are placed directly in their inventory. Characters can drag items from their inventory to drop it on ground or on another character to give it to them. Inventory is sorted based on item types and calculates character encumberance. You can open inventories of multiple character and containers at once by selecting them and pressing I.

Inventory system is extendyd by equipment system where you can create equipment slots to fit your ruleset. Items equiped in slots have their attribute modifiers applied directly to character attributes.

![Example of Inventory and Equipment system](https://github.com/Khazlor/Open-VTT/blob/main/README-IMG/inventory.gif?raw=true)

### Character Sheet system

Each character has a character sheet. This character sheet is split into multiple parts. In character sheet you can see and edit character attributes and macros, token settings, access inventory and mainly use the actual character sheet.

VTT allows it's users to create custom character sheet with integrated character sheet editor, or create one directly from PDF with included python tool. Here is an example of converted Stars Without Number Character Sheet PDF to the VTT.

![Example of SWN character sheet](https://github.com/Khazlor/Open-VTT/blob/main/README-IMG/char_sheet_swn.jpg?raw=true)

Unfortunately getting information from PDF is not easy and not very precise so things like precise alignment and some font sizes might change, but they should be easy to fix with integrated character sheet editor.

### Lighting System

VTT supports a dynamic lighting system, where the DM can edit properties of individual objects to specify if and from where do they cast light (and the properties of this light) and if they cast shadows. These object can be moved at will and the lighting system will take care of the rest. Lights will illuminate all objects in their range, so be sure to create a floor which can be illuminated.

To really see the lights darkness needs to be enabled in map settings. Darkness can be set to be completely Black or to just slightly darken the scene to enhance it with lights without taking away the sight of players. Darkness can be set separately for DM and players to allow DM to see in darkness.

Lighting can be used across multiple layers, there are total of 18 lighting layers and any map layer can be influenced by a combination of any lighting layers.

In addition FOV mode can be toggled in map settings so the players will see only line of sight of their selected character and not the entire map. FOV opacity of unselected player characters can be adjusted to the preferences of the DM.

![Example of bulk hit-dice macro](https://github.com/Khazlor/Open-VTT/blob/main/README-IMG/fov.gif?raw=true)

### Chat Commands and Character Macros

VTT contains side panel with chat in which any dice can be rolled using /r command. In addition to chatting and rolling dice, the macro engine also supports calculation of expressions, evaluation of conditions and launching of queries. Character attributes and macros (and equiped item attributes) are also directly accessible from the macro command and can be both read and edited directly from the command.

For ease access character macros can be added to a action bar at the bottom of the screen. When multiple characters are selected the action bar is filled with combination of all their action bar macros. Clicking on macro in action bar will trigger the macro for each character that has a macro under that name defined.

![Example of bulk hit-dice macro](https://github.com/Khazlor/Open-VTT/blob/main/README-IMG/macro.gif?raw=true)

### Control Groups

For easier selection of player characters or groups of monsters there is the option of creating control groups like in RTS games. Simply select all objects you want in the group and press CTRL + 0-9 to create control group. Pressing 0-9 will select all the control group object.

## TODO

- Refactor + Documentation - now that I am not bound by my Bachelor's Theses other people can contribute aswell = need for code clarity and documentation
- Undo/Redo System
- Spells/Abilities - library + character sheet tabs
- Character Traits/Perks
- TileMap system - DEMO done - neet to create tools to work with
- Procedural generation of maps
- Character Wizard - something like Charactermancer or level up system in Pathfinder:WOTR - just universal and adjustable

- BUG fixes

## Set up from source
1. download godot game engine: https://godotengine.org/ - currently used version = 4.2.x
2. download repository
3. open godot and import project ("Godot" folder from repository)
4. Press play in top-right of the GUI or press F5 to run in debug mode

To build executable from source follow the instructions in [Godot Docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)

## Releases
I will try to release stable releases after each major feature or bug fix.