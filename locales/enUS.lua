-- luacheck: no max line length

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "enUS", true); -- luacheck: ignore
L = L or {}
--[===[@non-debug@
@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="english", table-name="L")@
--@end-non-debug@]===]
--@debug@
L = L or {}
L["< 1min"] = "< 1min"
L["< 5sec"] = "< 5sec"
L["> 1min"] = "> 1min"
L["options:spells:add-new-spell"] = "Click to add new spell"
L["Add spell"] = "Add spell"
L["Always show auras cast by myself"] = "Always show auras cast by myself"
L["Anchor point"] = "Anchor point"
L["Anchor to icon"] = "Anchor to icon"
L["Any"] = "Any"
L["Aura type"] = "Aura type"
L["Border thickness"] = "Border thickness"
L["Buff"] = "Buff"
L["Check spell ID"] = [=[Check spell IDs
(comma-separated)]=]
L["Click to select spell"] = "Click to select spell"
L["Curse"] = "Curse"
L["Debuff"] = "Debuff"
L["Delete all spells"] = "Delete all spells"
L["Delete spell"] = "Delete spell"
L["Disabled"] = "Disabled"
L["Disease"] = "Disease"
L["Display auras on nameplates of friendly units"] = "Display auras on nameplates of friendly units"
L["Display auras on player's nameplate"] = "Display auras on player's nameplate"
L["Do you really want to delete ALL spells?"] = "Do you really want to delete ALL spells?"
L["Font"] = "Font"
L["Font scale"] = "Font scale"
L["Font size"] = "Font size"
L["General"] = "General"
L["Icon borders"] = "Icon borders"
L["Icon X-coord offset"] = "Icon X-coord offset"
L["Icon Y-coord offset"] = "Icon Y-coord offset"
L["Magic"] = "Magic"
L["Options are not available in combat!"] = "Options are not available in combat!"
L["options:apps:explosive-orbs:tooltip"] = [=[Show special aura above Fel Explosive's nameplates (M+ Explosive Affix)
This aura have a bright glow and default size]=]
L["options:auras:enabled-state:tooltip"] =
[=[%s: aura will not be shown

%s: aura will be shown if you've cast it

%s: show all auras]=]
L["options:auras:enabled-state-all"] = "Enabled, show all auras"
L["options:auras:enabled-state-mineonly"] = "Enabled, show only my auras"
L["options:auras:pvp-state-dontshowinpvp"] = "Don't show this aura during PvP combat"
L["options:auras:pvp-state-indefinite"] = "Show this aura during PvP combat"
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Show this aura during PvP combat only"
L["options:category:apps"] = "Apps"
L["options:category:interrupts"] = "Interrupts"
L["options:general:always-show-my-auras:tooltip"] = "This is top priority filter. If you enable this feature, your auras will be shown regardless of other filters"
L["options:general:hide-blizz-frames"] = "Hide Blizzard's aura frames (except player)"
L["options:general:hide-player-blizz-frame"] = "Hide Blizzard's aura frames on player"
L["options:general:show-aura-tooltip"] = "Show aura name when mouse is over auras icon"
L["options:interrupts:enable-interrupts"] = "Enable interrupt tracking"
L["options:interrupts:enable-only-during-pvp-battles"] = "Enable during PvP battles only"
L["options:interrupts:use-shared-icon-texture"] = "Use the same texture for all interrupt spells"
L["options:spells:appropriate-spell-ids"] = "Appropriate spell IDs:"
L["options:spells:disable-all-spells"] = "Disable all spells"
L["options:spells:enable-all-spells"] = "Enable all spells"
L["options:spells:icon-glow"] = "Show glow"
L["options:spells:icon-glow-always"] = "Show glow all the time"
L["options:spells:icon-glow-threshold"] = "Show glow if aura's remaining time is less than"
L["options:spells:please-push-once-more"] = "Please push once more"
L["options:spells:show-on-friends:warning0"] = [=[Please pay attention:
You will not see this aura on friendly nameplates until you enable this option: <General> --> <Display auras on nameplates of friendly units>]=]
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Minimum duration to display tenths of seconds"
L["options:timer-text:scale-font-size"] = "Scale font size according to icon size"
L["options:timer-text:text-color-note"] = [=[Text colour will change
depending on the time remaining:]=]
L["Other"] = "Other"
L["Please reload UI to apply changes"] = "Please reload UI to apply changes"
L["Poison"] = "Poison"
L["Profiles"] = "Profiles"
L["Reload UI"] = "Reload UI"
L["Show border around buff icons"] = "Show border around buff icons"
L["Show border around debuff icons"] = "Show border around debuff icons"
L["Show this aura on nameplates of allies"] = "Show this aura on nameplates of allies"
L["Show this aura on nameplates of enemies"] = "Show this aura on nameplates of enemies"
L["Sort mode:"] = "Sort mode:"
L["Space between icons"] = "Space between icons"
L["Spell seems to be nonexistent"] = "Spell seems to be nonexistent"
L["Spells"] = "Spells"
L["Stack text"] = "Stack text"
L["Text color"] = "Text color"
L["Timer text"] = "Timer text"
L["Value must be a number"] = "Value must be a number"
L["X offset"] = "X offset"
L["Y offset"] = "Y offset"
L["options:general:test-mode"] = "Test mode";
L["options:category:size-and-position"] = "Size & position";
L["options:apps:dispellable-spells"] = "Show dispellable/stealable auras on enemy nameplates";
L["options:apps:dispellable-spells:tooltip"] = [=[Show dispellable/stealable auras on nameplates of enemies. These auras have a dim glow and default size]=]
L["options:apps:dispellable-spells:black-list-button"] = "Open blacklist";
L["options:category:dispel"] = "Purge/steal";
L["options:glow-type"] = "Glow type";
L["options:glow-type:GLOW_TYPE_NONE"] = "None";
L["options:glow-type:GLOW_TYPE_ACTIONBUTTON"] = "Action button";
L["options:glow-type:GLOW_TYPE_AUTOUSE"] = "Auto-use button";
L["options:glow-type:GLOW_TYPE_PIXEL"] = "Pixel";
L["options:glow-type:GLOW_TYPE_ACTIONBUTTON_DIM"] = "Action button (dim)";
L["options:size-and-position:anchor-point-to-nameplate"] = "Anchor point to nameplate";
L["options:size-and-position:anchor-point-of-frame"] = "Anchor point to group of icons";
L["options:size-and-position:anchor-point-of-frame:tooltip"] = [['Group of icons' is collection of icons per nameplate]];
L["options:size-and-position:icon-align"] = "Alignment of icons";
L["options:general:icon-grow-direction"] = "Icon growing direction";
L["options:size-and-position:icon-align:bottom-left"] = "Horizontal: bottom / Vertical: left";
L["options:size-and-position:icon-align:top-right"] = "Horizontal: top / Vertical: right";
L["options:size-and-position:icon-align:center"] = "Center";
L["icon-grow-direction:right"] = "Right";
L["icon-grow-direction:left"] = "Left";
L["icon-grow-direction:up"] = "Up";
L["icon-grow-direction:down"] = "Down";
L["anchor-point:topright"] = "Top right";
L["anchor-point:right"] = "Right";
L["anchor-point:bottomright"] = "Bottom right";
L["anchor-point:top"] = "Top";
L["anchor-point:center"] = "Center";
L["anchor-point:bottom"] = "Bottom";
L["anchor-point:topleft"] = "Top left";
L["anchor-point:left"] = "Left";
L["anchor-point:bottomleft"] = "Bottom left";
L["icon-sort-mode:none"] = "Without sorting";
L["icon-sort-mode:by-expire-time"] = "By expiration time";
L["icon-sort-mode:by-icon-size"] = "By icon size";
L["icon-sort-mode:by-aura-type+by-expire-time"] = "By aura type + by expiration time";
L["options:general:show-cooldown-animation"] = "Show cooldown animation";
L["options:alpha:alpha"] = "Alpha of the icons (except the nameplate of your target)";
L["options:alpha:alpha-target"] = "Alpha of the icons on the nameplate of your target";
L["options:size-and-position:scale-target"] = "Scale of the icons on the nameplate of your target";
L["options:category:alpha"] = "Alpha";
L["options:general:show-cooldown-text"] = "Show aura's remaining time";
L["options:general:show-stacks"] = "Show aura's stacks"
L["options:spells:icon-animation"] = "Icon animation";
L["options:spells:icon-animation-threshold"] = "Show animation if aura's remaining time is less than";
L["options:spells:icon-animation-always"] = "Show animation all the time";
L["options:spells:animation-type"] = "Animation type";
L["options:animation-type:ICON_ANIMATION_TYPE_ALPHA"] = "Alpha";
L["options:size-and-position:target-strata"] = "Layer of icons on target nameplate"
L["options:size-and-position:non-target-strata"] = "Layer of icons on non-target nameplates"
L["options:borders:border-file-path"] = "Border texture file path (starts with 'Interface\\')";
L["options:borders:border-type"] = "Border type";
L["options:borders:BORDER_TYPE_BUILTIN"] = "Built-in";
L["options:borders:BORDER_TYPE_CUSTOM"] = "Custom";
L["options:size-and-position:icon-width"] = "Default icon width";
L["options:size-and-position:icon-height"] = "Default icon height";
L["options:spells:icon-width"] = "Icon width";
L["options:spells:icon-height"] = "Icon height";
L["options:spells:glow-relative"] = [[Use relative time]];
L["options:spells:glow-relative:tooltip"] =
[[This option changes the meaning of slider on the left.

If this option is checked, glow will appear when aura's remaining duration is less than the selected percent of maximum duration of this aura. It is useful, for example, if you want to know when you can safely re-apply your DoT spell without losing it's duration.

If this option is unchecked, glow will appear when aura's remaining duration is less than absolute value of slider (in seconds)]];
L["options:spells:animation-relative:tooltip"] =
[[This option changes the meaning of slider on the left.

If this option is checked, animation will start when aura's remaining duration is less than the selected percent of maximum duration of this aura. It is useful, for example, if you want to know when you can safely re-apply your DoT spell without losing it's duration.

If this option is unchecked, animation will start when aura's remaining duration is less than absolute value of slider (in seconds)]];
L["options:size-and-position:icon-zoom"] = "Icon zoom";
L["options:size-and-position:custom-sorting:tooltip"] =
[[Rules:
  - code must be an unnamed function with 2 arguments. These arguments are tables, representing auras to compare
  - this function must return true if the first aura should be placed before the second aura, and false otherwise
  - sorting is done quite often, so don't make sorting function too heavy
  - don't modify content of aura's table unless you REALLY know what you are doing
  - double-check any code you got from strangers

Aura's table content:
  - aura.duration - contains duration of aura in seconds. If aura is permanent, value of this field is 0. (type: number)
  - aura.expires - time when aura will finish. You can compare it with GetTime(). If aura is permanent, value of this field is 0. (type: number)
  - aura.stacks - number of stacks (type: number)
  - aura.spellID - ID of aura (type: number)
  - aura.spellName - name of aura (type: string)

Built-in sorting functions (result is a boolean value):
  - local result = sort_time(aura1, aura2) - sort by aura's remaining time
  - local result = sort_size(aura1, aura2) - sort by icon's size
]];
L["icon-sort-mode:custom"] = "Custom";
L["options:size-and-position:keep-aspect-ratio"] = "Keep aspect ratio of textures";
L["options:size-and-position:keep-aspect-ratio:tooltip"] = "If this option is checked and icon width and height are not equal, then texture of spell will be cropped in that way to save original image proportions";
L["options:apps:dr"] = "Enable display of diminishing return (beta)"
L["options:apps:dr:pvp"] = "PvP"
L["options:apps:dr:pve"] = "PvE (stun only)"
L["options:general:show-on-target-only"] = "Show auras on target's nameplate only"
L["options:alpha:use-target-alpha-if-not-target-selected"] = "Display auras with target's alpha if no target selected"

--@end-debug@