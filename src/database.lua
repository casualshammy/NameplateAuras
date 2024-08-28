-- luacheck: no max line length
-- luacheck: globals wipe

local _, addonTable = ...;

-- // consts
local CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS, AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY, AURA_SORT_MODE_NONE;
local AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE, AURA_SORT_MODE_AURATYPE_EXPIRE, GLOW_TIME_INFINITE;
do
	CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS = addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_ALL, addonTable.CONST_SPELL_MODE_MYAURAS;
	AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY = addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY;
	AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE, AURA_SORT_MODE_AURATYPE_EXPIRE =
		addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIRETIME, addonTable.AURA_SORT_MODE_ICONSIZE, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE;
	GLOW_TIME_INFINITE = addonTable.GLOW_TIME_INFINITE; -- // 30 days
end

-- // utilities
local Print, msgWithQuestion, table_count, SpellNameByID, table_insert;
do
	Print, msgWithQuestion, table_count, SpellNameByID, table_insert =
		addonTable.Print, addonTable.msgWithQuestion, addonTable.table_count, addonTable.SpellNameByID, table.insert;
end

local migrations = {
    [0] = function()
        local db = addonTable.db;
        -- delete unused fields
        for _, entry in pairs({ "IconSize", "DebuffBordersColor", "DisplayBorders", "ShowMyAuras", "DefaultSpells", "InterruptsEnableOnlyInPvP" }) do
            if (db[entry] ~= nil) then
                db[entry] = nil;
                Print("Old db record is deleted: " .. entry);
            end
        end
        if (db.TimerTextSizeMode ~= nil) then
            db.TimerTextUseRelativeScale = (db.TimerTextSizeMode == "relative");
            db.TimerTextSizeMode = nil;
        end
        if (db.SortMode ~= nil and type(db.SortMode) == "string") then
            local replacements = { ["none"] = AURA_SORT_MODE_NONE, ["by-expire-time-asc"] = AURA_SORT_MODE_EXPIRETIME, ["by-expire-time-des"] = 3,
                ["by-icon-size-asc"] = AURA_SORT_MODE_ICONSIZE, ["by-icon-size-des"] = 5, ["by-aura-type-expire-time"] = AURA_SORT_MODE_AURATYPE_EXPIRE };
            db.SortMode = replacements[db.SortMode];
        end
        if (db.TimerStyle ~= nil and type(db.TimerStyle) == "string") then
            local replacements = { [1] = "texture-with-text", [2] = "cooldown-frame-no-text", [3] = "cooldown-frame", [4] = "circular-noomnicc-text" };
            for newValue, oldValue in pairs(replacements) do
                if (db.TimerStyle == oldValue) then
                    db.TimerStyle = newValue;
                    break;
                end
            end
        end
        if (db.DisplayTenthsOfSeconds ~= nil) then
            db.MinTimeToShowTenthsOfSeconds = db.DisplayTenthsOfSeconds and 10 or 0;
            db.DisplayTenthsOfSeconds = nil;
        end
        if (db.DefaultSpellsAreImported ~= nil) then
            db.DefaultSpellsLastSetImported = 1;
            db.DefaultSpellsAreImported = nil;
        end
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (type(spellInfo.checkSpellID) == "number") then
                spellInfo.checkSpellID = { [spellInfo.checkSpellID] = true };
            end
        end
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.checkSpellID ~= nil) then
                local toAdd = { };
                for key in pairs(spellInfo.checkSpellID) do
                    if (type(key) == "string") then
                        spellInfo.checkSpellID[key] = nil;
                        local nmbr = tonumber(key);
                        if (nmbr ~= nil) then
                            table_insert(toAdd, nmbr);
                        end
                    end
                end
                for _, value in pairs(toAdd) do
                    spellInfo.checkSpellID[value] = true;
                end
            end
        end
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.checkSpellID ~= nil) then
                local toAdd = { };
                for key, value in pairs(spellInfo.checkSpellID) do
                    if (type(value) == "number") then
                        table_insert(toAdd, value);
                        spellInfo.checkSpellID[key] = nil;
                    end
                end
                for _, value in pairs(toAdd) do
                    spellInfo.checkSpellID[value] = true;
                end
            end
        end
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.showGlow ~= nil and type(spellInfo.showGlow) == "boolean") then
                spellInfo.showGlow = GLOW_TIME_INFINITE;
            end
        end
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.allowMultipleInstances ~= nil and type(spellInfo.allowMultipleInstances) == "boolean" and spellInfo.allowMultipleInstances == false) then
                spellInfo.allowMultipleInstances = nil;
            end
        end
        if (db.HidePlayerBlizzardFrame == "undefined") then
            db.HidePlayerBlizzardFrame = db.HideBlizzardFrames;
        end
    end,
    [1] = function()
        local db = addonTable.db;
        local tempTable = { };
        for spellID, spellInfo in pairs(db.CustomSpells2) do
            local entry = addonTable.deepcopy(spellInfo);
            entry.spellName = SpellNameByID[spellID];
            entry.spellID = nil;
            table.insert(tempTable, entry);
        end
        wipe(db.CustomSpells2);
        for _, spellInfo in pairs(tempTable) do
            table.insert(db.CustomSpells2, spellInfo);
        end
    end,
    [2] = function()
        local db = addonTable.db;
        db.CustomSpells3 = nil;
        for _, spellInfo in pairs(db.CustomSpells2) do
            spellInfo.allowMultipleInstances = nil;
        end
    end,
    [3] = function()
        local db = addonTable.db;
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (db.UseDimGlow) then
                spellInfo.glowType = addonTable.GLOW_TYPE_ACTIONBUTTON_DIM;
            else
                spellInfo.glowType = addonTable.GLOW_TYPE_AUTOUSE;
            end
        end
        db.UseDimGlow = nil;
        db.Additions_DispellableSpells_DimGlow = nil;
    end,
    [4] = function()
        local db = addonTable.db;
        if (not db.InterruptsGlow) then
            db.InterruptsGlowType = addonTable.GLOW_TYPE_NONE;
        else
            db.InterruptsGlowType = addonTable.GLOW_TYPE_ACTIONBUTTON_DIM;
        end
        db.InterruptsGlow = nil;
    end,
    [5] = function()
        local db = addonTable.db;
        db.FrameAnchorToNameplate = db.FrameAnchor;
    end,
    [6] = function()
        local db = addonTable.db;
        local iconAligh = {
            ["TOPLEFT"] = addonTable.ICON_ALIGN_TOP_RIGHT,
            ["LEFT"] = addonTable.ICON_ALIGN_CENTER,
            ["BOTTOMLEFT"] = addonTable.ICON_ALIGN_BOTTOM_LEFT,
        };
        db.IconAnchor = iconAligh[db.IconAnchor];
    end,
    [7] = function()
        local db = addonTable.db;
        if (db.TimerStyle == 2 or db.TimerStyle == 3) then
            db.TimerStyle = 4;
            db.ShowStacks = db.TimerStyle == 3;
            db.ShowCooldownText = db.TimerStyle == 3;
        end
    end,
    [8] = function()
        local db = addonTable.db;
        if (db.TimerStyle ~= nil) then
            db.ShowCooldownAnimation = db.TimerStyle == 4;
            db.TimerStyle = nil;
        end
    end,
    [9] = function()
        local db = addonTable.db;
        if (db.SortMode == 3) then
            db.IconGrowDirection = addonTable.ICON_GROW_DIRECTION_LEFT;
            db.SortMode = addonTable.AURA_SORT_MODE_EXPIRETIME;
        end
        if (db.SortMode == 5) then
            db.IconGrowDirection = addonTable.ICON_GROW_DIRECTION_LEFT;
            db.SortMode = addonTable.AURA_SORT_MODE_ICONSIZE;
        end
    end,
    [10] = function()
        local db = addonTable.db;
        if (db.IgnoreNameplateScale ~= nil) then
            if (not db.IgnoreNameplateScale) then
                db.IconScaleTarget = 1.2;
            end
            db.IgnoreNameplateScale = nil;
        end
        if (db.FullOpacityAlways ~= nil) then
            if (not db.FullOpacityAlways) then
                db.IconAlpha = 0.6;
            end
            db.FullOpacityAlways = nil;
        end
    end,
    [11] = function()
        local db = addonTable.db;
        db.IconScale = nil;
    end,
    [12] = function()
        local db = addonTable.db;
        if (db.TimerTextSoonToExpireColor ~= nil and #db.TimerTextSoonToExpireColor == 3) then
            db.TimerTextSoonToExpireColor[#db.TimerTextSoonToExpireColor+1] = 1;
        end
        if (db.TimerTextUnderMinuteColor ~= nil and #db.TimerTextUnderMinuteColor == 3) then
            db.TimerTextUnderMinuteColor[#db.TimerTextUnderMinuteColor+1] = 1;
        end
        if (db.TimerTextLongerColor ~= nil and #db.TimerTextLongerColor == 3) then
            db.TimerTextLongerColor[#db.TimerTextLongerColor+1] = 1;
        end
    end,
    [13] = function()
        local db = addonTable.db;
        if (db.DefaultIconSize ~= nil) then
            db.DefaultIconSizeWidth = db.DefaultIconSize;
            db.DefaultIconSizeHeight = db.DefaultIconSize;
            db.DefaultIconSize = nil;
        end
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.iconSize ~= nil) then
                spellInfo.iconSizeWidth = spellInfo.iconSize;
                spellInfo.iconSizeHeight = spellInfo.iconSize;
                spellInfo.iconSize = nil;
            end
        end
    end,
    [14] = function()
        local db = addonTable.db;
        if (db.InterruptsIconSize ~= nil) then
            db.InterruptsIconSizeWidth = db.InterruptsIconSize;
            db.InterruptsIconSizeHeight = db.InterruptsIconSize;
            db.InterruptsIconSize = nil;
        end
        if (db.Additions_DispellableSpells_IconSize ~= nil) then
            db.DispelIconSizeWidth = db.Additions_DispellableSpells_IconSize;
            db.DispelIconSizeHeight = db.Additions_DispellableSpells_IconSize;
            db.Additions_DispellableSpells_IconSize = nil;
        end
    end,
    [15] = function()
        local db = addonTable.db;
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.animationType == 3) then -- ICON_ANIMATION_TYPE_SCALE
                spellInfo.animationType = addonTable.ICON_ANIMATION_TYPE_ALPHA;
            end
        end
    end,
    [16] = function()
        local db = addonTable.db;
        if (db.StacksTextColor ~= nil and #db.StacksTextColor == 3) then
            db.StacksTextColor[#db.StacksTextColor+1] = 1;
        end
    end,
    [17] = function()
        local db = addonTable.db;
        local values = { "DebuffBordersMagicColor", "DebuffBordersCurseColor", "DebuffBordersDiseaseColor", "DebuffBordersPoisonColor", "DebuffBordersOtherColor", "BuffBordersColor" };
        for _, value in pairs(values) do
            if (db[value] ~= nil and #db[value] == 3) then
                db[value][4] = 1;
            end
        end
    end,
    [18] = function()
        local db = addonTable.db;
        for _, spellInfo in pairs(db.CustomSpells2) do
            spellInfo.pvpCombat = nil;
        end
    end,
    [19] = function()
        local db = addonTable.db;
        for _, spellInfo in pairs(db.CustomSpells2) do
            spellInfo.customBorderEnabled = nil;
            spellInfo.customBorderType = addonTable.BORDER_TYPE_DISABLED;
        end
    end,
    [20] = function()
        local db = addonTable.db;
        if (db.AlwaysShowMyAurasBlacklist == nil) then
            db.AlwaysShowMyAurasBlacklist = {};
        end
    end,
    [21] = function()
        local db = addonTable.db;
        db.MaxAuras = nil;
    end,
    [22] = function()
        local db = addonTable.db;
        local keys = {
            "ShowAurasOnPlayerNameplate",
            "IconXOffset",
            "IconYOffset",
            "Font",
            "SortMode",
            "FontScale",
            "TimerTextUseRelativeScale",
            "TimerTextSize",
            "TimerTextAnchor",
            "TimerTextAnchorIcon",
            "TimerTextXOffset",
            "TimerTextYOffset",
            "TimerTextSoonToExpireColor",
            "TimerTextUnderMinuteColor",
            "TimerTextLongerColor",
            "StacksFont",
            "StacksFontScale",
            "StacksTextAnchor",
            "StacksTextAnchorIcon",
            "StacksTextXOffset",
            "StacksTextYOffset",
            "StacksTextColor",
            "ShowBuffBorders",
            "BuffBordersColor",
            "ShowDebuffBorders",
            "DebuffBordersMagicColor",
            "DebuffBordersCurseColor",
            "DebuffBordersDiseaseColor",
            "DebuffBordersPoisonColor",
            "DebuffBordersOtherColor",
            "IconSpacing",
            "IconAnchor",
            "AlwaysShowMyAuras",
            "BorderThickness",
            "ShowAboveFriendlyUnits",
            "FrameAnchor",
            "FrameAnchorToNameplate",
            "MinTimeToShowTenthsOfSeconds",
            "InterruptsEnabled",
            "InterruptsIconSizeWidth",
            "InterruptsIconSizeHeight",
            "InterruptsGlowType",
            "InterruptsUseSharedIconTexture",
            "InterruptsShowOnlyOnPlayers",
            "Additions_ExplosiveOrbs",
            "ShowAuraTooltip",
            "Additions_DispellableSpells",
            "Additions_DispellableSpells_Blacklist",
            "DispelIconSizeWidth",
            "DispelIconSizeHeight",
            "Additions_DispellableSpells_GlowType",
            "IconGrowDirection",
            "ShowStacks",
            "ShowCooldownText",
            "ShowCooldownAnimation",
            "IconAlpha",
            "IconAlphaTarget",
            "IconScaleTarget",
            "TargetStrata",
            "NonTargetStrata",
            "BorderType",
            "BorderFilePath",
            "DefaultIconSizeWidth",
            "DefaultIconSizeHeight",
            "IconZoom",
            "CustomSortMethod",
            "Additions_DRPvP",
            "Additions_DRPvE",
            "ShowOnlyOnTarget",
            "UseTargetAlphaIfNotTargetSelected",
            "AffixSpiteful",
            "AffixSpitefulSound",
            "EnabledZoneTypes",
            "MaxAuras",
            "ShowAurasOnTargetEvenInDisabledAreas",
            "AlwaysShowMyAurasBlacklist",
            "NpcBlacklist",
            "TimerTextUseRelativeColor",
            "TimerTextColorZeroPercent",
            "TimerTextColorHundredPercent",
            "KeepAspectRatio",
            "UseDefaultAuraTooltip",
        };
        if (db.IconGroups == nil or db.IconGroups[1] == nil) then
            db.IconGroups[1] = addonTable.GetIconGroupDefaultOptions("First Icon Group");
        end
        for _, key in pairs(keys) do
            local value = db[key];
            if (value ~= nil) then
                db.IconGroups[1][key] = value;
                db[key] = nil;
            end
        end
    end,
    [23] = function()
        local db = addonTable.db;
        for igIndex, igData in pairs(db.IconGroups) do
            if (igData.IconGroupName == nil or igData.IconGroupName == "") then
                igData.IconGroupName = "[" .. tostring(igIndex) .. "] " .. date("%Y-%m-%d-%H-%M-%S");
            end
        end
    end,
    [24] = function()
        local db = addonTable.db;
        local ref = addonTable.GetIconGroupDefaultOptions();
        local colorKeys = {
            "TimerTextSoonToExpireColor",
            "TimerTextUnderMinuteColor",
            "TimerTextLongerColor",
            "StacksTextColor",
            "BuffBordersColor",
            "DebuffBordersMagicColor",
            "DebuffBordersCurseColor",
            "DebuffBordersDiseaseColor",
            "DebuffBordersPoisonColor",
            "DebuffBordersOtherColor",
            "TimerTextColorZeroPercent",
            "TimerTextColorHundredPercent",
        };
        for _, igData in pairs(db.IconGroups) do
            for _, key in pairs(colorKeys) do
                local entry = igData[key];
                local refEntry = ref[key];
                if (entry ~= nil and refEntry ~= nil) then
                    for refKey, refValue in pairs(refEntry) do
                        if (entry[refKey] == nil) then
                            entry[refKey] = refValue;
                        end
                    end
                end
            end
        end
    end,
    [25] = function()
        local db = addonTable.db;
        local count = 0;
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.overrideSize == nil) then
                local groups = spellInfo.iconGroups;
                if (groups ~= nil) then
                    local firstEnabledGroup = 0;
                    for groupIndex, groupEnabled in pairs(groups) do
                        if (groupEnabled) then
                            firstEnabledGroup = groupIndex;
                            break;
                        end
                    end
                    if (firstEnabledGroup > 0) then
                        local groupInfo = db.IconGroups[firstEnabledGroup];
                        if (groupInfo ~= nil) then
                            if (spellInfo.iconSizeWidth ~= groupInfo.DefaultIconSizeWidth or spellInfo.iconSizeHeight ~= groupInfo.DefaultIconSizeHeight) then
                                spellInfo.overrideSize = true;
                                count = count + 1;
                            end
                        end
                    end
                end
            end
        end
        if (count > 0) then
            addonTable.Print("Total spells with custom size: "..count);
        end
    end,
    [26] = function()
        local db = addonTable.db;
        for _, igData in pairs(db.IconGroups) do
            if (igData.ShowCooldownSwipeEdge == nil) then
                igData.ShowCooldownSwipeEdge = true;
            end
        end
    end,
    [27] = function() -- yes, 27 and 28 should be the same
        local db = addonTable.db;
        for _, igData in pairs(db.IconGroups) do
            if (igData.FriendlyUnitsAurasEnabledZoneTypes == nil) then
                igData.FriendlyUnitsAurasEnabledZoneTypes = {
                    [addonTable.INSTANCE_TYPE_NONE] =			true,
                    [addonTable.INSTANCE_TYPE_UNKNOWN] = 		true,
                    [addonTable.INSTANCE_TYPE_PVP] = 			true,
                    [addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = 	true,
                    [addonTable.INSTANCE_TYPE_ARENA] = 			true,
                    [addonTable.INSTANCE_TYPE_PARTY] = 			true,
                    [addonTable.INSTANCE_TYPE_RAID] = 			true,
                    [addonTable.INSTANCE_TYPE_SCENARIO] =		true,
                };
            end
        end
    end,
    [28] = function() -- yes, 27 and 28 should be the same
        local db = addonTable.db;
        for _, igData in pairs(db.IconGroups) do
            if (igData.FriendlyUnitsAurasEnabledZoneTypes == nil) then
                local enabled = igData.ShowAboveFriendlyUnits;

                igData.FriendlyUnitsAurasEnabledZoneTypes = {
                    [addonTable.INSTANCE_TYPE_NONE] =			enabled,
                    [addonTable.INSTANCE_TYPE_UNKNOWN] = 		enabled,
                    [addonTable.INSTANCE_TYPE_PVP] = 			enabled,
                    [addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = 	enabled,
                    [addonTable.INSTANCE_TYPE_ARENA] = 			enabled,
                    [addonTable.INSTANCE_TYPE_PARTY] = 			enabled,
                    [addonTable.INSTANCE_TYPE_RAID] = 			enabled,
                    [addonTable.INSTANCE_TYPE_SCENARIO] =		enabled,
                };

                igData.ShowAboveFriendlyUnits = nil;
            end
        end
    end,
    [29] = function()
        local db = addonTable.db;
        for _, igData in pairs(db.IconGroups) do
            if (igData.EnemyUnitsAurasEnabledZoneTypes == nil) then
                igData.EnemyUnitsAurasEnabledZoneTypes = addonTable.deepcopy(igData.EnabledZoneTypes);
                igData.EnabledZoneTypes = nil;
            end
        end
    end,
    [30] = function()
        local db = addonTable.db;
        for _, igData in pairs(db.IconGroups) do
            if (igData.ShowAurasOnEnemyTargetEvenInDisabledAreas == nil) then
                igData.ShowAurasOnEnemyTargetEvenInDisabledAreas = igData.ShowAurasOnTargetEvenInDisabledAreas
                igData.ShowAurasOnTargetEvenInDisabledAreas = nil;
            end
            igData.ShowAurasOnAlliedTargetEvenInDisabledAreas = false;
        end
    end,
    [31] = function()
        local db = addonTable.db;
        for _, igData in pairs(db.IconGroups) do
            if (igData.AttachToAddonFrame == true) then
                igData.AttachType = addonTable.ATTACH_TYPE_TPTP;
            else
                igData.AttachType = addonTable.ATTACH_TYPE_NAMEPLATE;
            end
            igData.AttachToAddonFrame = nil;
        end
    end,
};

local function FillInMissingEntriesIsSpells()
    local db = addonTable.db;
    local ref = addonTable.GetIconGroupDefaultOptions();
    for index, spellInfo in pairs(db.CustomSpells2) do
        if (spellInfo.spellName == nil) then
            -- we don't know what spell it is
            db.CustomSpells2[index] = nil;
        else
            -- useRelativeGlowTimer may be nil
            -- useRelativeAnimationTimer may be nil
            -- checkSpellID may be nil
            -- showGlow may be nil
            -- spellTooltip may be nil
            -- spellInfo.customBorderPath may be nil
            -- consolidate may be nil
            -- overrideSize may be nil
            if (spellInfo.enabledState == nil) then
                spellInfo.enabledState = CONST_SPELL_MODE_ALL;
            end
            if (spellInfo.showOnFriends == nil) then
                spellInfo.showOnFriends = true;
            end
            if (spellInfo.showOnEnemies == nil) then
                spellInfo.showOnEnemies = true;
            end
            if (spellInfo.playerNpcMode == nil) then
                spellInfo.playerNpcMode = addonTable.SHOW_ON_PLAYERS_AND_NPC;
            end
            if (spellInfo.auraType == nil) then
                spellInfo.auraType = AURA_TYPE_ANY;
            end
            if (spellInfo.glowType == nil) then
                spellInfo.glowType = addonTable.GLOW_TYPE_AUTOUSE;
            end
            if (spellInfo.animationType == nil) then
                spellInfo.animationType = addonTable.ICON_ANIMATION_TYPE_ALPHA;
            end
            if (spellInfo.animationTimer == nil) then
                spellInfo.animationTimer = 10;
            end
            if (spellInfo.animationDisplayMode == nil) then
                spellInfo.animationDisplayMode = addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE;
            end
            if (spellInfo.iconSizeWidth == nil) then
                spellInfo.iconSizeWidth = ref.DefaultIconSizeWidth;
            end
            if (spellInfo.iconSizeHeight == nil) then
                spellInfo.iconSizeHeight = ref.DefaultIconSizeHeight;
            end
            if (spellInfo.customBorderType == nil) then
                spellInfo.customBorderType = addonTable.BORDER_TYPE_DISABLED;
            end
            if (spellInfo.customBorderSize == nil) then
                spellInfo.customBorderSize = ref.BorderThickness;
            end
            if (spellInfo.customBorderColor == nil) then
                spellInfo.customBorderColor = { 1, 0.1, 0.1, 1 };
            end
            if (spellInfo.customBorderPath == nil) then
                spellInfo.customBorderPath = "";
            end

            if (spellInfo.enabledState == "disabled") then
                spellInfo.enabledState = CONST_SPELL_MODE_DISABLED;
            elseif (spellInfo.enabledState == "all") then
                spellInfo.enabledState = CONST_SPELL_MODE_ALL;
            elseif (spellInfo.enabledState == "my") then
                spellInfo.enabledState = CONST_SPELL_MODE_MYAURAS;
            end

            if (spellInfo.auraType == "buff") then
                spellInfo.auraType = AURA_TYPE_BUFF;
            elseif (spellInfo.auraType == "debuff") then
                spellInfo.auraType = AURA_TYPE_DEBUFF;
            elseif (spellInfo.auraType == "buff/debuff") then
                spellInfo.auraType = AURA_TYPE_ANY;
            end

            if (spellInfo.iconGroups == nil or #spellInfo.iconGroups == 0) then
                spellInfo.iconGroups = { [1] = true };
            end
        end
    end
end

function addonTable.MigrateDB()
    for i = addonTable.db.DBVersion, (table_count(migrations)-1) do
        local migration = migrations[i];
        if (migration ~= nil) then
            migration();
        end
        addonTable.Print("Converted DB up to version", i);
    end
    addonTable.db.DBVersion = table_count(migrations);
    FillInMissingEntriesIsSpells();

    if (#addonTable.db.IconGroups == 0) then
        addonTable.db.IconGroups[1] = addonTable.GetIconGroupDefaultOptions();
    end
end

function addonTable.ImportNewSpells(force)
    local db = addonTable.db;
    if (force == true) then
        db.DefaultSpellsLastSetImported = 0;
    end
    if (db.DefaultSpellsLastSetImported < #addonTable.DefaultSpells2) then
        local spellNamesAlreadyInUsersDB = { };
        for _, spellInfo in pairs(db.CustomSpells2) do
            if (spellInfo.spellName ~= nil) then
                spellNamesAlreadyInUsersDB[spellInfo.spellName] = true;
            end
        end
        local allNewSpells = { };
        for i = db.DefaultSpellsLastSetImported + 1, #addonTable.DefaultSpells2 do
            local set = addonTable.DefaultSpells2[i];
            for _, spellInfo in pairs(set) do
                if (spellInfo.spellName ~= nil and not spellNamesAlreadyInUsersDB[spellInfo.spellName]) then
                    table.insert(allNewSpells, spellInfo);
                end
            end
        end
        if (db.DefaultSpellsLastSetImported == 0) then
            for _, spellInfo in pairs(allNewSpells) do
                table.insert(db.CustomSpells2, spellInfo);
            end
            FillInMissingEntriesIsSpells();
        else
            local allNewSpellsCount = table_count(allNewSpells);
            if (allNewSpellsCount > 0) then
                msgWithQuestion("NameplateAuras\n\nDo you want to import new spells? (Total: " .. allNewSpellsCount .. ")",
                    function()
                        for _, spellInfo in pairs(allNewSpells) do
                            table.insert(db.CustomSpells2, spellInfo);
                            Print("Imported '" .. spellInfo.spellName .. "'");
                        end
                        FillInMissingEntriesIsSpells();
                        Print("Imported successfully");
                    end,
                    function() end
                );
            end
        end
        db.DefaultSpellsLastSetImported = #addonTable.DefaultSpells2;
    end
end
