local _, addonTable = ...;

-- // consts
local CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS, AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY, AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIREASC, AURA_SORT_MODE_EXPIREDES, AURA_SORT_MODE_ICONSIZEASC, 
	AURA_SORT_MODE_ICONSIZEDES, AURA_SORT_MODE_AURATYPE_EXPIRE, TIMER_STYLE_TEXTURETEXT, TIMER_STYLE_CIRCULAR, TIMER_STYLE_CIRCULAROMNICC, TIMER_STYLE_CIRCULARTEXT, CONST_SPELL_PVP_MODES_UNDEFINED, CONST_SPELL_PVP_MODES_INPVPCOMBAT, 
	CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT, GLOW_TIME_INFINITE, EXPLOSIVE_ORB_SPELL_ID, VERY_LONG_COOLDOWN_DURATION, BORDER_TEXTURES;
do
	CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS = addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_ALL, addonTable.CONST_SPELL_MODE_MYAURAS;
	AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY = addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY;
	AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIREASC, AURA_SORT_MODE_EXPIREDES, AURA_SORT_MODE_ICONSIZEASC, AURA_SORT_MODE_ICONSIZEDES, AURA_SORT_MODE_AURATYPE_EXPIRE = 
		addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIREASC, addonTable.AURA_SORT_MODE_EXPIREDES, addonTable.AURA_SORT_MODE_ICONSIZEASC, addonTable.AURA_SORT_MODE_ICONSIZEDES, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE;
	TIMER_STYLE_TEXTURETEXT, TIMER_STYLE_CIRCULAR, TIMER_STYLE_CIRCULAROMNICC, TIMER_STYLE_CIRCULARTEXT = addonTable.TIMER_STYLE_TEXTURETEXT, addonTable.TIMER_STYLE_CIRCULAR, addonTable.TIMER_STYLE_CIRCULAROMNICC, addonTable.TIMER_STYLE_CIRCULARTEXT;
	CONST_SPELL_PVP_MODES_UNDEFINED, CONST_SPELL_PVP_MODES_INPVPCOMBAT, CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT = addonTable.CONST_SPELL_PVP_MODES_UNDEFINED, addonTable.CONST_SPELL_PVP_MODES_INPVPCOMBAT, addonTable.CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT;
	GLOW_TIME_INFINITE = addonTable.GLOW_TIME_INFINITE; -- // 30 days
	EXPLOSIVE_ORB_SPELL_ID = addonTable.EXPLOSIVE_ORB_SPELL_ID;
	VERY_LONG_COOLDOWN_DURATION = addonTable.VERY_LONG_COOLDOWN_DURATION; -- // 30 days
	BORDER_TEXTURES = addonTable.BORDER_TEXTURES;
end

-- // utilities
local Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID, table_insert;
do

	Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID, table_insert = 
		addonTable.Print, addonTable.msg, addonTable.msgWithQuestion, addonTable.table_count, addonTable.SpellTextureByID, addonTable.SpellNameByID, addonTable.UnitClassByGUID, table.insert;
	
end

local function MigrateDB_0()
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
        local replacements = { ["none"] = AURA_SORT_MODE_NONE, ["by-expire-time-asc"] = AURA_SORT_MODE_EXPIREASC, ["by-expire-time-des"] = AURA_SORT_MODE_EXPIREDES,
            ["by-icon-size-asc"] = AURA_SORT_MODE_ICONSIZEASC, ["by-icon-size-des"] = AURA_SORT_MODE_ICONSIZEDES, ["by-aura-type-expire-time"] = AURA_SORT_MODE_AURATYPE_EXPIRE };
        db.SortMode = replacements[db.SortMode];
    end
    if (db.TimerStyle ~= nil and type(db.TimerStyle) == "string") then
        local replacements = { [TIMER_STYLE_TEXTURETEXT] = "texture-with-text", [TIMER_STYLE_CIRCULAR] = "cooldown-frame-no-text", [TIMER_STYLE_CIRCULAROMNICC] = "cooldown-frame", [TIMER_STYLE_CIRCULARTEXT] = "circular-noomnicc-text" };
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
    for spellID, spellInfo in pairs(db.CustomSpells2) do
        if (type(spellInfo.checkSpellID) == "number") then
            spellInfo.checkSpellID = { [spellInfo.checkSpellID] = true };
        end
    end
    for spellID, spellInfo in pairs(db.CustomSpells2) do
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
    for spellID, spellInfo in pairs(db.CustomSpells2) do
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
end

local function MigrateDB_1()
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
end

local function MigrateDB_2()
    local db = addonTable.db;
    db.CustomSpells3 = nil;
    for _, spellInfo in pairs(db.CustomSpells2) do
        spellInfo.allowMultipleInstances = nil;
    end
end

local function MigrateDB_3()
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
end

local function MigrateDB_4()
    local db = addonTable.db;
    if (not db.InterruptsGlow) then
        db.InterruptsGlowType = addonTable.GLOW_TYPE_NONE;
    else
        db.InterruptsGlowType = addonTable.GLOW_TYPE_ACTIONBUTTON_DIM;
    end
    db.InterruptsGlow = nil;
end

local function FillInMissingEntriesIsSpells()
    local db = addonTable.db;
    for index, spellInfo in pairs(db.CustomSpells2) do
        if (spellInfo.spellName == nil) then
            -- we don't know what spell it is
            db.CustomSpells2[index] = nil;
        else
            if (spellInfo.enabledState == nil) then
                spellInfo.enabledState = CONST_SPELL_MODE_ALL;
            end
            if (spellInfo.showOnFriends == nil) then
                spellInfo.showOnFriends = true;
            end
            if (spellInfo.showOnEnemies == nil) then
                spellInfo.showOnEnemies = true;
            end
            if (spellInfo.pvpCombat == nil) then
                spellInfo.pvpCombat = CONST_SPELL_PVP_MODES_UNDEFINED;
            end
            if (spellInfo.auraType == nil) then
                spellInfo.auraType = AURA_TYPE_ANY;
            end
            if (spellInfo.glowType == nil) then
                spellInfo.glowType = addonTable.GLOW_TYPE_AUTOUSE;
            end
            -- iconSize my be nil
            -- checkSpellID may be nil
            -- showGlow may be nil
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
        end
    end
end

function addonTable.MigrateDB()
    if (addonTable.db.DBVersion == 0) then
        MigrateDB_0();
        addonTable.db.DBVersion = 1;
    end
    if (addonTable.db.DBVersion == 1) then
        MigrateDB_1();
        addonTable.db.DBVersion = 2;
    end
    if (addonTable.db.DBVersion == 2) then
        MigrateDB_2();
        addonTable.db.DBVersion = 3;
    end
    if (addonTable.db.DBVersion == 3) then
        MigrateDB_3();
        addonTable.db.DBVersion = 4;
    end
    if (addonTable.db.DBVersion == 4) then
        MigrateDB_4();
        addonTable.db.DBVersion = 5;
    end
    FillInMissingEntriesIsSpells();
end

function addonTable.ImportNewSpells()
    local db = addonTable.db;
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
            if (table_count(allNewSpells) > 0) then
                msgWithQuestion("NameplateAuras\n\nDo you want to import new spells?",
                    function()
                        for _, spellInfo in pairs(allNewSpells) do
                            table.insert(db.CustomSpells2, spellInfo);
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
