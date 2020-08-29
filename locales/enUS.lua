local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "enUS", true);
L = L or {}
--[===[@non-debug@
@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="english", table-name="L")@
--@end-non-debug@]===]
--@debug@
L = L or {}
L["< 1min"] = "< 1min"
L["< 5sec"] = "< 5sec"
L["> 1min"] = "> 1min"
L["Add new spell: "] = "Add new spell: "
L["Add spell"] = "Add spell"
L["All auras"] = "All auras"
L["options:general:full-opacity-always"] = "Icons are always completely opaque"
L["options:general:full-opacity-always:tooltip"] = 
[[If this option is enabled, the icons will 
always be completely opaque. If not, the opacity
will be the same as the health bar]]
L["Always show auras cast by myself"] = "Always show auras cast by myself"
L["Anchor point"] = "Anchor point"
L["Anchor to icon"] = "Anchor to icon"
L["Any"] = "Any"
L["Aura type"] = "Aura type"
L["Border thickness"] = "Border thickness"
L["BOTTOM"] = "Bottom"
L["BOTTOMLEFT"] = "Bottom left"
L["BOTTOMRIGHT"] = "Bottom right"
L["Buff"] = "Buff"
L["By aura type (de/buff) + expire time"] = "By aura type (de/buff) + expire time"
L["By expire time, ascending"] = "By expire time, ascending"
L["By expire time, descending"] = "By expire time, descending"
L["By icon size, ascending"] = "By icon size, ascending"
L["By icon size, descending"] = "By icon size, descending"
L["CENTER"] = "Center"
L["Check spell ID"] = [=[Check spell IDs
(comma-separated)]=]
L["Circular"] = "Circular"
L["Circular with OmniCC support"] = "Circular with OmniCC support"
L["Circular with timer"] = "Circular with timer"
L["Click to select spell"] = "Click to select spell"
L["Curse"] = "Curse"
L["Debuff"] = "Debuff"
L["Default icon size"] = "Default icon size"
L["Delete all spells"] = "Delete all spells"
L["Delete spell"] = "Delete spell"
L["Disabled"] = "Disabled"
L["Disease"] = "Disease"
L["Display auras on nameplates of friendly units"] = "Display auras on nameplates of friendly units"
L["Display auras on player's nameplate"] = "Display auras on player's nameplate"
L["Display tenths of seconds"] = "Display tenths of seconds"
L["Do you really want to delete ALL spells?"] = "Do you really want to delete ALL spells?"
L["Font"] = "Font"
L["Font scale"] = "Font scale"
L["Font size"] = "Font size"
L["Frame anchor:"] = "Frame anchor:"
L["General"] = "General"
L["Icon anchor:"] = "Icon anchor:"
L["Icon borders"] = "Icon borders"
L["Icon size"] = "Icon size"
L["Icon X-coord offset"] = "Icon X-coord offset"
L["Icon Y-coord offset"] = "Icon Y-coord offset"
L["LEFT"] = "Left"
L["Magic"] = "Magic"
L["Mode"] = "Mode"
L["No"] = "No"
L["None"] = "None"
L["Only my auras"] = "Only my auras"
L["Open profiles dialog"] = "Open profiles dialog"
L["Options are not available in combat!"] = "Options are not available in combat!"
L["options:apps:explosive-orbs:tooltip"] = [=[Show special aura above Fel Explosive's nameplates (M+ Explosive Affix)
This aura have a bright glow and default size]=]
L["options:aura-options:allow-multiple-instances"] = "Allow multiple instances of this aura"
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[If this option is checked, you will see all instances of this aura, even on the same nameplate.
Otherwise you will see only one instance of this aura (the longest one)]=]
L["options:auras:add-new-spell:error1"] = [=[You should enter spell name instead of spell id.
Use "%s" option if you want to track spell with specific id]=]
L["options:auras:enabled-state:tooltip"] = [=[Enables/disables aura

%s: aura will not be shown
%s: aura will be shown if you've cast it
%s: show all auras]=]
L["options:auras:enabled-state-all"] = "Enabled, show all auras"
L["options:auras:enabled-state-mineonly"] = "Enabled, show only my auras"
L["options:auras:pvp-state-dontshowinpvp"] = "Don't show this aura during PvP combat"
L["options:auras:pvp-state-indefinite"] = "Show this aura during PvP combat"
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Show this aura during PvP combat only"
L["options:category:apps"] = "Apps"
L["options:category:interrupts"] = "Interrupts"
L["options:general:always-show-my-auras:tooltip"] = [=[This is top priority filter. If you enable this feature,
your auras will be shown regardless of other filters]=]
L["options:general:error-omnicc-is-not-loaded"] = "You cannot select this option because OmniCC is not loaded!"
L["options:general:hide-blizz-frames"] = "Hide Blizzard's aura frames (except player)"
L["options:general:hide-player-blizz-frame"] = "Hide Blizzard's aura frames on player"
L["options:general:show-aura-tooltip"] = "Show aura name when mouse is over auras icon"
L["options:interrupts:enable-interrupts"] = "Enable interrupt tracking"
L["options:interrupts:enable-only-during-pvp-battles"] = "Enable during PvP battles only"
L["options:interrupts:icon-size"] = "Icon size"
L["options:interrupts:use-shared-icon-texture"] = "Use the same texture for all interrupt spells"
L["options:selector:search"] = "Search:"
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
L["options:timer-text:scale-font-size"] = [=[Scale font size
according to
icon size]=]
L["options:timer-text:text-color-note"] = [=[Text colour will change
depending on the time remaining:]=]
L["Other"] = "Other"
L["Please reload UI to apply changes"] = "Please reload UI to apply changes"
L["Poison"] = "Poison"
L["Profiles"] = "Profiles"
L["Reload UI"] = "Reload UI"
L["RIGHT"] = "Right"
L["Show border around buff icons"] = "Show border around buff icons"
L["Show border around debuff icons"] = "Show border around debuff icons"
L["Show this aura on nameplates of allies"] = "Show this aura on nameplates of allies"
L["Show this aura on nameplates of enemies"] = "Show this aura on nameplates of enemies"
L["Sort mode:"] = "Sort mode:"
L["Space between icons"] = "Space between icons"
L["Spell already exists (%s)"] = "Spell already exists (%s)"
L["Spell seems to be nonexistent"] = "Spell seems to be nonexistent"
L["Spells"] = "Spells"
L["Stack text"] = "Stack text"
L["Text"] = "Text"
L["Text color"] = "Text color"
L["Texture with timer"] = "Texture with timer"
L["Timer style:"] = "Timer style:"
L["Timer text"] = "Timer text"
L["TOP"] = "Top"
L["TOPLEFT"] = "Top left"
L["TOPRIGHT"] = "Top right"
L["Unknown spell: %s"] = "Unknown spell: %s"
L["Value must be a number"] = "Value must be a number"
L["X offset"] = "X offset"
L["Y offset"] = "Y offset"
L["Yes"] = "Yes"
L["options:general:test-mode"] = "Test mode on/off";
L["options:category:size-and-position"] = "Size & position";
L["options:apps:dispellable-spells"] = "Show dispellable/stealable auras on enemy nameplates";
L["options:apps:dispellable-spells:tooltip"] = [=[Show dispellable/stealable auras on nameplates of enemies
These auras have a dim glow and default size]=]
L["options:apps:dispellable-spells:black-list-button"] = "Open blacklist";
L["options:category:dispel"] = "Purge/steal";
L["options:glow-type"] = "Glow type";
L["options:glow-type:GLOW_TYPE_NONE"] = "None";
L["options:glow-type:GLOW_TYPE_ACTIONBUTTON"] = "Action button";
L["options:glow-type:GLOW_TYPE_AUTOUSE"] = "Auto-use button";
L["options:glow-type:GLOW_TYPE_PIXEL"] = "Pixel";
L["options:glow-type:GLOW_TYPE_ACTIONBUTTON_DIM"] = "Action button (dim)";

--@end-debug@