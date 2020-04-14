local _, addonTable = ...;
--[===[@non-debug@
local buildTimestamp = "@project-version@";
--@end-non-debug@]===]

local L = LibStub("AceLocale-3.0"):GetLocale("NameplateAuras");
local LBG_ShowOverlayGlow, LBG_HideOverlayGlow = NAuras_LibButtonGlow.ShowOverlayGlow, NAuras_LibButtonGlow.HideOverlayGlow;
local SML = LibStub("LibSharedMedia-3.0");

-- // upvalues
local 	_G, pairs, select, WorldFrame, string_match,string_gsub,string_find,string_format, 	GetTime, math_ceil, math_floor, wipe, C_NamePlate_GetNamePlateForUnit, UnitBuff, UnitDebuff, string_lower,
			UnitReaction, UnitGUID, UnitIsFriend, table_insert, table_sort, table_remove, IsUsableSpell, CTimerAfter,	bit_band, math_max, CTimerNewTimer,   strsplit =
		_G, pairs, select, WorldFrame, strmatch, 	gsub,		strfind, 	format,			GetTime, ceil,		floor,		wipe, C_NamePlate.GetNamePlateForUnit, UnitBuff, UnitDebuff, string.lower,
			UnitReaction, UnitGUID, UnitIsFriend, table.insert, table.sort, table.remove, IsUsableSpell, C_Timer.After,	bit.band, math.max, C_Timer.NewTimer, strsplit;

-- // variables
local AurasPerNameplate, InterruptsPerUnitGUID, UnitGUIDHasInterruptReduction, UnitGUIDHasAdditionalInterruptReduction, EnabledAurasInfo, ElapsedTimer, Nameplates, NameplatesVisible, InPvPCombat, GUIFrame, 
	EventFrame, db, aceDB, LocalPlayerGUID, DebugWindow, ProcessAurasForNameplate, UpdateNameplate, OnUpdate;
do
	AurasPerNameplate 						= { };
	InterruptsPerUnitGUID					= { };
	UnitGUIDHasInterruptReduction			= { };
	UnitGUIDHasAdditionalInterruptReduction	= { };
	EnabledAurasInfo						= { };
	ElapsedTimer 							= 0;
	Nameplates, NameplatesVisible 			= { }, { };
	InPvPCombat								= false;
	addonTable.EnabledAurasInfo 			= EnabledAurasInfo;
	addonTable.Nameplates					= Nameplates;
	addonTable.AllAuraIconFrames			= { };
end

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
local Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID;
do

	Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID = 
		addonTable.Print, addonTable.msg, addonTable.msgWithQuestion, addonTable.table_count, addonTable.SpellTextureByID, addonTable.SpellNameByID, addonTable.UnitClassByGUID;
	
end

--------------------------------------------------------------------------------------------------
----- db, on start routines...
--------------------------------------------------------------------------------------------------
do
	
	local ReloadDB;
	
	local function DeleteAllSpellsFromDB()
		if (not StaticPopupDialogs["NAURAS_MSG_DELETE_ALL_SPELLS"]) then
			StaticPopupDialogs["NAURAS_MSG_DELETE_ALL_SPELLS"] = {
				text = L["Do you really want to delete ALL spells?"],
				button1 = YES,
				button2 = NO,
				OnAccept = function()
					for spellID in pairs(db.CustomSpells2) do
						db.CustomSpells2[spellID] = nil;
					end
					ReloadDB();
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			};
		end
		StaticPopup_Show("NAURAS_MSG_DELETE_ALL_SPELLS");
	end
	addonTable.DeleteAllSpellsFromDB = DeleteAllSpellsFromDB;

	local function ChatCommand_Debug()
		DebugWindow = DebugWindow or LibStub("LibRedDropdown-1.0").CreateDebugWindow();
		DebugWindow:AddText("PRESS ESC TO CLOSE THIS WINDOW");
		DebugWindow:AddText("PRESS CTRL+A AND THEN CTRL+C TO COPY THIS TEXT");
		DebugWindow:AddText("");
		DebugWindow:AddText("Version: " .. tostring(buildTimestamp or "DEVELOPER COPY"));
		DebugWindow:AddText("");
		DebugWindow:AddText("InPvPCombat: " .. tostring(InPvPCombat));
		DebugWindow:AddText("Number of nameplates: " .. table_count(Nameplates));
		DebugWindow:AddText("Number of visible nameplates: " .. table_count(NameplatesVisible));
		DebugWindow:AddText("EnabledAurasInfo count: " .. table_count(EnabledAurasInfo));
		DebugWindow:AddText("AurasPerNameplate count: " .. table_count(AurasPerNameplate));
		DebugWindow:AddText("");
		DebugWindow:AddText("LIST OF ENABLED ADDONS----------");
		for i = 1, GetNumAddOns() do
			local name, _, _, _, _, security = GetAddOnInfo(i);
			if (security == "INSECURE" and IsAddOnLoaded(name)) then
				DebugWindow:AddText("    " .. name);
			end
		end
		DebugWindow:AddText("");
		DebugWindow:AddText("CONFIG----------");
		for index, value in pairs(db) do
			if (type(value) ~= "table") then
				DebugWindow:AddText(string_format("    %s: %s (%s)", index, tostring(value), type(value)));
			end
		end
		DebugWindow:AddText("");
		DebugWindow:AddText("LIST OF SPELLS----------");
		local enabledStateTokens = { [CONST_SPELL_MODE_DISABLED] = "DISABLED", [CONST_SPELL_MODE_ALL] = "ALL", [CONST_SPELL_MODE_MYAURAS] = "MYAURAS" };
		local auraTypeTokens = { [AURA_TYPE_BUFF] = "BUFF", [AURA_TYPE_DEBUFF] = "DEBUFF", [AURA_TYPE_ANY] = "ANY" };
		for spellName, spellInfo in pairs(EnabledAurasInfo) do
			DebugWindow:AddText(string_format("    %s: %s; %s; %s; %s; %s; %s; %s; %s; %s;", spellName,
				tostring(enabledStateTokens[spellInfo.enabledState]),
				tostring(auraTypeTokens[spellInfo.auraType]),
				tostring(spellInfo.iconSize),
				tostring(spellInfo.checkSpellID),
				tostring(spellInfo.showOnFriends),
				tostring(spellInfo.showOnEnemies),
				tostring(spellInfo.allowMultipleInstances),
				tostring(spellInfo.pvpCombat),
				tostring(spellInfo.showGlow)));
		end
		DebugWindow:Show();
	end

	local function InitializeDB()
		-- // set defaults
		local aceDBDefaults = {
			profile = {
				DefaultSpellsLastSetImported = 0,
				CustomSpells2 = { },
				IconXOffset = 0,
				IconYOffset = 50,
				FullOpacityAlways = false,
				Font = "NAuras_TeenBold",
				HideBlizzardFrames = true,
				DefaultIconSize = 45,
				SortMode = AURA_SORT_MODE_EXPIREASC,
				FontScale = 1,
				TimerTextUseRelativeScale = true,
				TimerTextSize = 20,
				TimerTextAnchor = "CENTER",
				TimerTextAnchorIcon = "UNKNOWN",
				TimerTextXOffset = 0,
				TimerTextYOffset = 0,
				TimerTextSoonToExpireColor = { 1, 0.1, 0.1 },
				TimerTextUnderMinuteColor = { 1, 1, 0.1 },
				TimerTextLongerColor = { 0.7, 1, 0 },
				StacksFont = "NAuras_TeenBold",
				StacksFontScale = 1,
				StacksTextAnchor = "BOTTOMRIGHT",
				StacksTextAnchorIcon = "UNKNOWN",
				StacksTextXOffset = -3,
				StacksTextYOffset = 5,
				StacksTextColor = { 1, 0.1, 0.1 },
				TimerStyle = TIMER_STYLE_TEXTURETEXT,
				ShowBuffBorders = true,
				BuffBordersColor = {0, 1, 0},
				ShowDebuffBorders = true,
				DebuffBordersMagicColor = { 0.1, 1, 1 },
				DebuffBordersCurseColor = { 1, 0.1, 1 },
				DebuffBordersDiseaseColor = { 1, 0.5, 0.1 },
				DebuffBordersPoisonColor = { 0.1, 1, 0.1 },
				DebuffBordersOtherColor = { 1, 0.1, 0.1 },
				ShowAurasOnPlayerNameplate = false,
				IconSpacing = 1,
				IconAnchor = "LEFT",
				AlwaysShowMyAuras = false,
				BorderThickness = 2,
				ShowAboveFriendlyUnits = true,
				FrameAnchor = "CENTER",
				MinTimeToShowTenthsOfSeconds = 10,
				InterruptsEnabled = true,
				InterruptsIconSize = 45, -- // must be equal to DefaultIconSize
				InterruptsGlow = false,
				InterruptsUseSharedIconTexture = false,
				InterruptsShowOnlyOnPlayers = true,
				UseDimGlow = nil,
				Additions_ExplosiveOrbs = true,
				Additions_Raid_Zul = true,
				ShowAuraTooltip = false,
				HidePlayerBlizzardFrame = "undefined", -- // don't change: we convert db with that
			},
		};
		
		-- // ...
		aceDB = LibStub("AceDB-3.0"):New("NameplateAurasAceDB", aceDBDefaults);
		-- // adding to blizz options
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras", {
			name = "NameplateAuras",
			type = 'group',
			args = {
				openGUI = {
					type = 'execute',
					order = 1,
					name = 'Open config dialog',
					desc = nil,
					func = function()
						addonTable.ShowGUI();
						if (GUIFrame) then
							InterfaceOptionsFrameCancel:Click();
						end
					end,
				},
			},
		});
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras", "NameplateAuras");
		local profilesConfig = LibStub("AceDBOptions-3.0"):GetOptionsTable(aceDB);
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras.profiles", profilesConfig);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras.profiles", "Profiles", "NameplateAuras");
		-- // processing old and invalid entries
		if (aceDB.profile.TimerTextAnchorIcon == aceDBDefaults.profile.TimerTextAnchorIcon) then
			aceDB.profile.TimerTextAnchorIcon = aceDB.profile.TimerTextAnchor;
		end
		if (aceDB.profile.StacksTextAnchorIcon == aceDBDefaults.profile.StacksTextAnchorIcon) then
			aceDB.profile.StacksTextAnchorIcon = aceDB.profile.StacksTextAnchor;
		end
		-- // creating a fast reference
		aceDB.RegisterCallback("NameplateAuras", "OnProfileChanged", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileCopied", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileReset", ReloadDB);
	end

	function addonTable.OnStartup()
		-- // getting player's GUID
		LocalPlayerGUID = UnitGUID("player");
		-- // ...
		InitializeDB();
		-- // ...
		ReloadDB();
		-- // starting listening for events
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
		EventFrame:RegisterEvent("UNIT_AURA");
		if (db.InterruptsEnabled) then
			EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		-- // adding slash command
		SLASH_NAMEPLATEAURAS1 = '/nauras';
		SlashCmdList["NAMEPLATEAURAS"] = function(msg, editBox)
			if (msg == "ver") then
				local c = UNKNOWN;
				if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
					c = "INSTANCE_CHAT";
				elseif (IsInRaid()) then
					c = "RAID";
				else
					c = "GUILD";
				end
				Print("Waiting for replies from " .. c);
				C_ChatInfo.SendAddonMessage("NAuras_prefix", "requesting2", c);
			elseif (msg == "delete-all-spells") then
				DeleteAllSpellsFromDB();
			elseif (msg == "debug") then
				ChatCommand_Debug();
			else
				addonTable.ShowGUI();
			end
		end
		C_ChatInfo.RegisterAddonMessagePrefix("NAuras_prefix");
		addonTable.OnStartup = nil;
	end

	local function UpdateSpellCachesFromDB(spellID)
		local spellName = SpellNameByID[spellID];
		if (db.CustomSpells2[spellID] ~= nil and db.CustomSpells2[spellID].enabledState ~= CONST_SPELL_MODE_DISABLED) then
			EnabledAurasInfo[spellName] = {
				["enabledState"] =				db.CustomSpells2[spellID].enabledState,
				["auraType"] =					db.CustomSpells2[spellID].auraType,
				["iconSize"] =					db.CustomSpells2[spellID].iconSize,
				["checkSpellID"] =				db.CustomSpells2[spellID].checkSpellID,
				["showOnFriends"] =				db.CustomSpells2[spellID].showOnFriends,
				["showOnEnemies"] =				db.CustomSpells2[spellID].showOnEnemies,
				["allowMultipleInstances"] =	db.CustomSpells2[spellID].allowMultipleInstances,
				["pvpCombat"] =					db.CustomSpells2[spellID].pvpCombat,
				["showGlow"] =					db.CustomSpells2[spellID].showGlow,
			};
		else
			EnabledAurasInfo[spellName] = nil;
		end
	end
	addonTable.UpdateSpellCachesFromDB = UpdateSpellCachesFromDB;
	
	local function ReloadDB_SetSpellCache()
		for spellID, spellInfo in pairs(db.CustomSpells2) do
			local spellName = SpellNameByID[spellID];
			if (spellName == nil) then
				Print("<spellid:"..spellID.."> isn't exist. Removing from database...");
				db.CustomSpells2[spellID] = nil;
			else
				if (spellInfo.showOnFriends == nil) then
					spellInfo.showOnFriends = true;
				end
				if (spellInfo.showOnEnemies == nil) then
					spellInfo.showOnEnemies = true;
				end
				if (spellInfo.pvpCombat == nil) then
					spellInfo.pvpCombat = CONST_SPELL_PVP_MODES_UNDEFINED;
				end
				if (spellInfo.spellID == nil) then
					db.CustomSpells2[spellID].spellID = spellID;
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
				UpdateSpellCachesFromDB(spellID);
			end
		end
	end
	
	local function ReloadDB_ImportNewSpells()
		if (db.DefaultSpellsLastSetImported < #addonTable.DefaultSpells2) then
			local spellNamesAlreadyInUsersDB = { };
			for _, spellInfo in pairs(db.CustomSpells2) do
				local spellName = SpellNameByID[spellInfo.spellID];
				if (spellName ~= nil) then
					spellNamesAlreadyInUsersDB[spellName] = true;
				end
			end
			local allNewSpells = { };
			for i = db.DefaultSpellsLastSetImported + 1, #addonTable.DefaultSpells2 do
				local set = addonTable.DefaultSpells2[i];
				for spellID, spellInfo in pairs(set) do
					if (SpellNameByID[spellID] ~= nil and not spellNamesAlreadyInUsersDB[SpellNameByID[spellID]]) then
						allNewSpells[spellID] = spellInfo;
					end
				end
			end
			if (db.DefaultSpellsLastSetImported == 0) then
				for spellID, spellInfo in pairs(allNewSpells) do
					db.CustomSpells2[spellID] = spellInfo;
				end
			else
				if (table_count(allNewSpells) > 0) then
					msgWithQuestion("NameplateAuras\n\nNew and changed spells (total " .. table_count(allNewSpells) .. ") are available for import. Do you want to print their names in chat window?\n(If you click \"Yes\", you will be able to import new spells. If you click \"No\", this prompt will not appear again)",
						function()
							for spellID in pairs(allNewSpells) do
								local link = GetSpellLink(spellID);
								if (link ~= nil) then Print(link); end
							end
							C_Timer.After(0.5, function()
								msgWithQuestion("NameplateAuras\n\nDo you want to import new spells?",
									function()
										for spellID, spellInfo in pairs(allNewSpells) do
											db.CustomSpells2[spellID] = spellInfo;
										end
										ReloadDB_SetSpellCache();
										Print("Imported successfully");
									end,
									function() end);
							end);
						end,
						function() end);
				end
			end
			db.DefaultSpellsLastSetImported = #addonTable.DefaultSpells2;
		end
	end
	
	local function ReloadDB_ConvertInvalidValues()
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
	
	local function ReloadDB_AddAppsToEnabledAurasInfo()
		-- // set interrupt spells infos
		for spellID in pairs(addonTable.Interrupts) do
			local spellName = SpellNameByID[spellID];
			EnabledAurasInfo[spellName] = {
				["enabledState"] =				CONST_SPELL_MODE_DISABLED,
				["auraType"] =					AURA_TYPE_DEBUFF,
				["iconSize"] =					db.InterruptsIconSize,
				["showGlow"] =					db.InterruptsGlow and GLOW_TIME_INFINITE or nil,
			};
			SpellTextureByID[spellID] = db.InterruptsUseSharedIconTexture and "Interface\\AddOns\\NameplateAuras\\media\\warrior_disruptingshout.tga" or GetSpellTexture(spellID); -- // icon of Interrupting Shout
		end
		-- // apps
		local spellIDs = { addonTable.EXPLOSIVE_ORB_SPELL_ID, addonTable.ZUL_NPC1_SPELL_ID, addonTable.ZUL_NPC2_SPELL_ID };
		for _, spellID in pairs(spellIDs) do
			local spellName = SpellNameByID[spellID];
			EnabledAurasInfo[spellName] = {
				["enabledState"] =	CONST_SPELL_MODE_DISABLED,
				["auraType"] =		AURA_TYPE_DEBUFF,
				["iconSize"] =		db.DefaultIconSize,
				["showGlow"] =		GLOW_TIME_INFINITE,
			};
		end
	end
	
	function ReloadDB()
		db = aceDB.profile;
		addonTable.db = aceDB.profile;
		-- // resetting all caches
		wipe(EnabledAurasInfo);
		ReloadDB_AddAppsToEnabledAurasInfo();
		-- // convert values
		ReloadDB_ConvertInvalidValues();
		-- // import default spells
		ReloadDB_ImportNewSpells();
		-- // setting caches...
		ReloadDB_SetSpellCache();
		-- // starting OnUpdate()
		if (db.TimerStyle == TIMER_STYLE_TEXTURETEXT or db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
			EventFrame:SetScript("OnUpdate", function(self, elapsed)
				ElapsedTimer = ElapsedTimer + elapsed;
				if (ElapsedTimer >= 0.1) then
					OnUpdate();				
					ElapsedTimer = 0;
				end
			end);
		else
			EventFrame:SetScript("OnUpdate", nil);
		end
		-- // COMBAT_LOG_EVENT_UNFILTERED
		if (db.InterruptsEnabled) then
			EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		else
			EventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		-- //
		if (GUIFrame) then
			for _, func in pairs(GUIFrame.OnDBChangedHandlers) do
				func();
			end
		end
		addonTable.UpdateAllNameplates(true);
	end
	
end

--------------------------------------------------------------------------------------------------
----- Nameplates
--------------------------------------------------------------------------------------------------
do
	
	local EXPLOSIVE_ORB_NPC_ID_AS_STRING, ZUL_NPC1_ID_AS_STRING, ZUL_NPC2_ID_AS_STRING, ZUL_NPC1_SPELL_ID, ZUL_NPC2_SPELL_ID = 
		addonTable.EXPLOSIVE_ORB_NPC_ID_AS_STRING, addonTable.ZUL_NPC1_ID_AS_STRING, addonTable.ZUL_NPC2_ID_AS_STRING, addonTable.ZUL_NPC1_SPELL_ID, addonTable.ZUL_NPC2_SPELL_ID;
	local glowInfo = { };
	local symmetricAnchors = { 
		["TOPLEFT"] = "TOPRIGHT", 
		["LEFT"] = "RIGHT",
		["BOTTOMLEFT"] = "BOTTOMRIGHT",
	};
	
	local function AllocateIcon_SetAuraTooltip(icon)
		if (db.ShowAuraTooltip) then
			icon:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(SpellNameByID[icon.spellID]); GameTooltip:Show(); end);
			icon:SetScript("OnLeave", function() GameTooltip:SetOwner(UIParent, "ANCHOR_NONE"); GameTooltip:Hide(); end);
		else
			icon:SetScript("OnEnter", nil);
			icon:SetScript("OnLeave", nil);
		end
	end
	addonTable.AllocateIcon_SetAuraTooltip = AllocateIcon_SetAuraTooltip;
	
	local function AllocateIcon(frame)
		if (not frame.NAurasFrame) then
			frame.NAurasFrame = CreateFrame("frame", nil, db.FullOpacityAlways and WorldFrame or frame);
			frame.NAurasFrame:SetWidth(db.DefaultIconSize);
			frame.NAurasFrame:SetHeight(db.DefaultIconSize);
			frame.NAurasFrame:SetPoint(db.FrameAnchor, frame, db.IconXOffset, db.IconYOffset);
			frame.NAurasFrame:Show();
		end
		local icon = CreateFrame("Frame", nil, frame.NAurasFrame);
		AllocateIcon_SetAuraTooltip(icon);
		if (frame.NAurasIconsCount == 0) then
			icon:SetPoint(db.IconAnchor, frame.NAurasFrame, 0, 0);
		else
			icon:SetPoint(db.IconAnchor, frame.NAurasIcons[frame.NAurasIconsCount], symmetricAnchors[db.IconAnchor], db.IconSpacing, 0);
		end
		icon:SetSize(db.DefaultIconSize, db.DefaultIconSize);
		icon.texture = icon:CreateTexture(nil, "BORDER");
		icon.texture:SetAllPoints(icon);
		icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		icon.border = icon:CreateTexture(nil, "OVERLAY");
		icon.stacks = icon:CreateFontString(nil, "OVERLAY");
		icon.cooldownText = icon:CreateFontString(nil, "OVERLAY");
		if (db.TimerStyle == TIMER_STYLE_CIRCULAR or db.TimerStyle == TIMER_STYLE_CIRCULAROMNICC or db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
			icon.cooldownFrame = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
			icon.cooldownFrame:SetAllPoints(icon);
			icon.cooldownFrame:SetReverse(true);
			icon.cooldownFrame:SetHideCountdownNumbers(true);
			if (db.TimerStyle == TIMER_STYLE_CIRCULAROMNICC) then
				icon.cooldownFrame:SetDrawEdge(false);
				icon.cooldownFrame:SetDrawSwipe(true);
				icon.cooldownFrame:SetSwipeColor(0, 0, 0, 0.8);
			else
				icon.cooldownFrame.noCooldownCount = true;
			end
			icon.SetCooldown = function(self, startTime, duration)
				if (startTime == 0) then duration = 0; end
				icon.cooldownFrame:SetCooldown(startTime, duration);
			end;
			hooksecurefunc(icon.stacks, "SetText", function(self, text)
				if (text ~= "") then
					if (icon.cooldownFrame:GetCooldownDuration() == 0) then
						icon.stacks:SetParent(icon);
					else
						icon.stacks:SetParent(icon.cooldownFrame);
					end
				end
			end);
			hooksecurefunc(icon.cooldownText, "SetText", function(self, text)
				if (text ~= "") then
					if (icon.cooldownFrame:GetCooldownDuration() == 0) then
						icon.cooldownText:SetParent(icon);
					else
						icon.cooldownText:SetParent(icon.cooldownFrame);
					end
				end
			end);
		end
		icon.size = db.DefaultIconSize;
		icon:Hide();
		icon.cooldownText:SetTextColor(0.7, 1, 0);
		icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
		if (db.TimerTextUseRelativeScale) then
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((db.DefaultIconSize - db.DefaultIconSize / 2) * db.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
		end
		icon.border:SetTexture(BORDER_TEXTURES[db.BorderThickness]);
		icon.border:SetVertexColor(1, 0.35, 0);
		icon.border:SetAllPoints(icon);
		icon.border:Hide();
		icon.stacks:SetTextColor(unpack(db.StacksTextColor));
		icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextAnchorIcon, db.StacksTextXOffset, db.StacksTextYOffset);
		icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((db.DefaultIconSize / 4) * db.StacksFontScale), "OUTLINE");
		icon.stackcount = 0;
		tinsert(addonTable.AllAuraIconFrames, icon);
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.DefaultIconSize * frame.NAurasIconsCount);
		tinsert(frame.NAurasIcons, icon);
	end
		
	local function HideCDIcon(icon)
		icon.border:Hide();
		icon.borderState = nil;
		icon.cooldownText:Hide();
		icon.stacks:Hide();
		icon:Hide();
		icon.shown = false;
		icon.spellID = -1;
		icon.stackcount = -1;
		icon.size = -1;
		LBG_HideOverlayGlow(icon);
	end
	
	local function ShowCDIcon(icon)
		icon.cooldownText:Show();
		icon.stacks:Show();
		icon:Show();
		icon.shown = true;
	end
	
	local function ResizeIcon(icon, size)
		icon:SetSize(size, size);
		if (db.TimerTextUseRelativeScale) then
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((size - size / 2) * db.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
		end
		icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((size / 4) * db.StacksFontScale), "OUTLINE");
	end
	addonTable.ResizeIcon = ResizeIcon;
	
	local function UpdateAllNameplates(force)
		if (force) then
			for nameplate in pairs(Nameplates) do
				if (nameplate.NAurasFrame) then
					nameplate.NAurasFrame:ClearAllPoints();
					nameplate.NAurasFrame:SetPoint(db.FrameAnchor, nameplate, db.IconXOffset, db.IconYOffset);
					for iconIndex, icon in pairs(nameplate.NAurasIcons) do
						if (icon.shown) then
							if (db.TimerTextUseRelativeScale) then
								icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((icon.size - icon.size / 2) * db.FontScale), "OUTLINE");
							else
								icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
							end
							icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((icon.size / 4) * db.StacksFontScale), "OUTLINE");
						end
						icon:ClearAllPoints();
						if (iconIndex == 1) then
							icon:SetPoint(db.IconAnchor, nameplate.NAurasFrame, 0, 0);
						else
							icon:SetPoint(db.IconAnchor, nameplate.NAurasIcons[iconIndex-1], symmetricAnchors[db.IconAnchor], db.IconSpacing, 0);
						end
						icon.cooldownText:ClearAllPoints();
						icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
						icon.stacks:ClearAllPoints();
						icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextAnchorIcon, db.StacksTextXOffset, db.StacksTextYOffset);
						HideCDIcon(icon);
					end
				end
			end
		end
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame and nameplate.UnitFrame ~= nil and nameplate.UnitFrame.unit ~= nil) then
				ProcessAurasForNameplate(nameplate, nameplate.UnitFrame.unit);
			end
		end
	end
	addonTable.UpdateAllNameplates = UpdateAllNameplates;
		
	local function ProcessAurasForNameplate_Filter(isBuff, auraName, auraCaster, auraSpellID, unitIsFriend)
		if (db.AlwaysShowMyAuras and auraCaster == "player") then
			return true;
		else
			local spellInfo = EnabledAurasInfo[auraName];
			if (spellInfo ~= nil) then
				if (spellInfo.enabledState == CONST_SPELL_MODE_ALL or (spellInfo.enabledState == CONST_SPELL_MODE_MYAURAS and auraCaster == "player")) then
					if ((not unitIsFriend and spellInfo.showOnEnemies) or (unitIsFriend and spellInfo.showOnFriends)) then
						if (spellInfo.auraType == AURA_TYPE_ANY or (isBuff and spellInfo.auraType == AURA_TYPE_BUFF or spellInfo.auraType == AURA_TYPE_DEBUFF)) then
							local showInPvPCombat = spellInfo.pvpCombat;
							if (showInPvPCombat == CONST_SPELL_PVP_MODES_UNDEFINED or (showInPvPCombat == CONST_SPELL_PVP_MODES_INPVPCOMBAT and InPvPCombat) or (showInPvPCombat == CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT and not InPvPCombat)) then
								if (spellInfo.checkSpellID == nil or spellInfo.checkSpellID[auraSpellID]) then
									return true;
								end
							end
						end
					end
				end
			end
		end
		return false;
	end
	
	local function ProcessAurasForNameplate_MultipleAuraInstances(frame, auraName, auraExpires, auraStack)
		if (EnabledAurasInfo[auraName] ~= nil and EnabledAurasInfo[auraName].allowMultipleInstances) then
			return true;
		else
			for index, value in pairs(AurasPerNameplate[frame]) do
				if (value.spellName == auraName) then
					if (value.expires < auraExpires or value.stacks ~= auraStack) then
						AurasPerNameplate[frame][index] = nil;
						return true;
					else
						return false;
					end
				end
			end
			return true;
		end
		error("Fatal error in <ProcessAurasForNameplate_MultipleAuraInstances>");
	end
	
	local function ProcessAurasForNameplate_ProcessAdditions(unitGUID, frame)
		if (unitGUID ~= nil) then
			local _, _, _, _, _, npcID = strsplit("-", unitGUID);
			if (db.Additions_ExplosiveOrbs and npcID == EXPLOSIVE_ORB_NPC_ID_AS_STRING) then
				table_insert(AurasPerNameplate[frame], {
					["duration"] = 0,
					["expires"] = 0,
					["stacks"] = 1,
					["spellID"] = EXPLOSIVE_ORB_SPELL_ID,
					["type"] = AURA_TYPE_DEBUFF,
					["spellName"] = SpellNameByID[EXPLOSIVE_ORB_SPELL_ID],
					["overrideDimGlow"] = false,
					["infinite_duration"] = true,
				});
			end
			if (db.Additions_Raid_Zul) then
				if (npcID == ZUL_NPC1_ID_AS_STRING) then
					table_insert(AurasPerNameplate[frame], {
						["duration"] = 0,
						["expires"] = 0,
						["stacks"] = 1,
						["spellID"] = ZUL_NPC1_SPELL_ID,
						["type"] = AURA_TYPE_DEBUFF,
						["spellName"] = SpellNameByID[ZUL_NPC1_SPELL_ID],
						["overrideDimGlow"] = false,
						["infinite_duration"] = true,
					});
				elseif (npcID == ZUL_NPC2_ID_AS_STRING) then
					table_insert(AurasPerNameplate[frame], {
						["duration"] = 0,
						["expires"] = 0,
						["stacks"] = 1,
						["spellID"] = ZUL_NPC2_SPELL_ID,
						["type"] = AURA_TYPE_DEBUFF,
						["spellName"] = SpellNameByID[ZUL_NPC2_SPELL_ID],
						["overrideDimGlow"] = false,
						["infinite_duration"] = true,
					});
				end
			end
		end
	end
	
	function ProcessAurasForNameplate(frame, unitID)
		wipe(AurasPerNameplate[frame]);
		local unitIsFriend = UnitIsFriend("player", unitID);
		local unitGUID = UnitGUID(unitID);
		if ((LocalPlayerGUID ~= unitGUID or db.ShowAurasOnPlayerNameplate) and (db.ShowAboveFriendlyUnits or not unitIsFriend)) then
			for i = 1, 40 do
				local buffName, _, buffStack, _, buffDuration, buffExpires, buffCaster, _, _, buffSpellID = UnitBuff(unitID, i);
				if (buffName ~= nil) then
					if (ProcessAurasForNameplate_Filter(true, buffName, buffCaster, buffSpellID, unitIsFriend)) then
						if (ProcessAurasForNameplate_MultipleAuraInstances(frame, buffName, buffExpires, buffStack)) then
							table_insert(AurasPerNameplate[frame], {
								["duration"] = buffDuration,
								["expires"] = buffExpires,
								["stacks"] = buffStack,
								["spellID"] = buffSpellID,
								["type"] = AURA_TYPE_BUFF,
								["spellName"] = buffName,
								["infinite_duration"] = buffDuration == 0,
							});
						end
					end
				end
				local debuffName, _, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, _, _, debuffSpellID = UnitDebuff(unitID, i);
				if (debuffName ~= nil) then
					if (ProcessAurasForNameplate_Filter(false, debuffName, debuffCaster, debuffSpellID, unitIsFriend)) then
						if (ProcessAurasForNameplate_MultipleAuraInstances(frame, debuffName, debuffExpires, debuffStack)) then
							table_insert(AurasPerNameplate[frame], {
								["duration"] = debuffDuration,
								["expires"] = debuffExpires,
								["stacks"] = debuffStack,
								["spellID"] = debuffSpellID,
								["type"] = AURA_TYPE_DEBUFF,
								["dispelType"] = debuffDispelType,
								["spellName"] = debuffName,
								["infinite_duration"] = debuffDuration == 0,
							});
						end
					end
				end
				if (buffName == nil and debuffName == nil) then
					break;
				end
			end
		end
		if (db.InterruptsEnabled) then
			local interrupt = InterruptsPerUnitGUID[unitGUID];
			if (interrupt ~= nil and interrupt.expires - GetTime() > 0) then
				table_insert(AurasPerNameplate[frame], interrupt);
			end
		end
		ProcessAurasForNameplate_ProcessAdditions(unitGUID, frame);
		UpdateNameplate(frame, unitGUID);
	end
	
	local function SortAurasForNameplate_AURA_SORT_MODE_EXPIREASC(item1, item2)
		return item1.expires < item2.expires;
	end
	
	local function SortAurasForNameplate_AURA_SORT_MODE_EXPIREDES(item1, item2)
		return item1.expires > item2.expires;
	end
	
	local function SortAurasForNameplate_AURA_SORT_MODE_ICONSIZEASC(item1, item2)
		local enabledAuraInfo1 = EnabledAurasInfo[item1.spellName];
		local enabledAuraInfo2 = EnabledAurasInfo[item2.spellName];
		return (enabledAuraInfo1 and enabledAuraInfo1.iconSize or db.DefaultIconSize) < (enabledAuraInfo2 and enabledAuraInfo2.iconSize or db.DefaultIconSize);
	end
	
	local function SortAurasForNameplate_AURA_SORT_MODE_ICONSIZEDES(item1, item2)
		local enabledAuraInfo1 = EnabledAurasInfo[item1.spellName];
		local enabledAuraInfo2 = EnabledAurasInfo[item2.spellName];
		return (enabledAuraInfo1 and enabledAuraInfo1.iconSize or db.DefaultIconSize) > (enabledAuraInfo2 and enabledAuraInfo2.iconSize or db.DefaultIconSize);
	end
	
	local function SortAurasForNameplate_AURA_SORT_MODE_AURATYPE_EXPIRE(item1, item2)
		if (item1.type ~= item2.type) then
			return (item1.type == AURA_TYPE_DEBUFF) and true or false;
		end
		if (item1.type == AURA_TYPE_DEBUFF) then
			return item1.expires < item2.expires;
		else
			return item1.expires > item2.expires;
		end
	end
	
	local function SortAurasForNameplate(auras)
		local t = { };
		for _, spellInfo in pairs(auras) do
			if (spellInfo.spellID ~= nil) then
				table_insert(t, spellInfo);
			end
		end
		if (db.SortMode == AURA_SORT_MODE_NONE) then
			-- // do nothing
		elseif (db.SortMode == AURA_SORT_MODE_EXPIREASC) then
			table_sort(t, SortAurasForNameplate_AURA_SORT_MODE_EXPIREASC);
		elseif (db.SortMode == AURA_SORT_MODE_EXPIREDES) then
			table_sort(t, SortAurasForNameplate_AURA_SORT_MODE_EXPIREDES);
		elseif (db.SortMode == AURA_SORT_MODE_ICONSIZEASC) then
			table_sort(t, SortAurasForNameplate_AURA_SORT_MODE_ICONSIZEASC);
		elseif (db.SortMode == AURA_SORT_MODE_ICONSIZEDES) then
			table_sort(t, SortAurasForNameplate_AURA_SORT_MODE_ICONSIZEDES);
		elseif (db.SortMode == AURA_SORT_MODE_AURATYPE_EXPIRE) then
			table_sort(t, SortAurasForNameplate_AURA_SORT_MODE_AURATYPE_EXPIRE);
		end
		return t;
	end
	
	local function UpdateNameplate_SetCooldown(icon, last, spellInfo)
		if (icon.info == nil) then
			icon.info = {
				["text"] = nil,
				["colorState"] = nil,
				["cooldownExpires"] = 0,
				["cooldownDuration"] = 0,
			};
		end
		local info = icon.info;
		if (db.TimerStyle == TIMER_STYLE_TEXTURETEXT or db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
			if (last > 3600 or spellInfo.infinite_duration) then
				if (info.text ~= "") then
					icon.cooldownText:SetText("");
					info.text = "";
				end
			elseif (last >= 60) then
				local newValue = math_floor(last/60).."m";
				if (info.text ~= newValue) then
					icon.cooldownText:SetText(newValue);
					info.text = newValue;
				end
			elseif (last >= db.MinTimeToShowTenthsOfSeconds) then
				local newValue = string_format("%d", last);
				if (info.text ~= newValue) then
					icon.cooldownText:SetText(newValue);
					info.text = newValue;
				end
			else
				icon.cooldownText:SetText(string_format("%.1f", last));
				info.text = nil;
			end
			if (last >= 60 or spellInfo.infinite_duration) then
				if (info.colorState ~= db.TimerTextLongerColor) then
					icon.cooldownText:SetTextColor(unpack(db.TimerTextLongerColor));
					info.colorState = db.TimerTextLongerColor;
				end
			elseif (last >= 5) then
				if (info.colorState ~= db.TimerTextUnderMinuteColor) then
					icon.cooldownText:SetTextColor(unpack(db.TimerTextUnderMinuteColor));
					info.colorState = db.TimerTextUnderMinuteColor;
				end
			else
				if (info.colorState ~= db.TimerTextSoonToExpireColor) then
					icon.cooldownText:SetTextColor(unpack(db.TimerTextSoonToExpireColor));
					info.colorState = db.TimerTextSoonToExpireColor;
				end
			end
			if (db.TimerStyle == TIMER_STYLE_CIRCULARTEXT) then
				if (spellInfo.expires ~= info.cooldownExpires or spellInfo.duration ~= info.cooldownDuration) then
					if (spellInfo.infinite_duration) then
						icon:SetCooldown(0, VERY_LONG_COOLDOWN_DURATION);
					else
						icon:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
					end
					info.cooldownExpires = spellInfo.expires;
					info.cooldownDuration = spellInfo.duration;
				end
			end
		elseif (db.TimerStyle == TIMER_STYLE_CIRCULAROMNICC or db.TimerStyle == TIMER_STYLE_CIRCULAR) then
			if (spellInfo.expires ~= info.cooldownExpires or spellInfo.duration ~= info.cooldownDuration) then
				if (spellInfo.infinite_duration) then
					icon:SetCooldown(0, VERY_LONG_COOLDOWN_DURATION);
				else
					icon:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
				end
				info.cooldownExpires = spellInfo.expires;
				info.cooldownDuration = spellInfo.duration;
			end
		end
	end
	
	local function UpdateNameplate_SetStacks(icon, spellInfo)
		if (icon.stackcount ~= spellInfo.stacks) then
			if (spellInfo.stacks > 1) then
				icon.stacks:SetText(spellInfo.stacks);
			else
				icon.stacks:SetText("");
			end
			icon.stackcount = spellInfo.stacks;
		end
	end
	
	local function UpdateNameplate_SetBorder(icon, spellInfo)
		if (db.ShowBuffBorders and spellInfo.type == AURA_TYPE_BUFF) then
			if (icon.borderState ~= spellInfo.type) then
				icon.border:SetVertexColor(unpack(db.BuffBordersColor));
				icon.border:Show();
				icon.borderState = spellInfo.type;
			end
		elseif (db.ShowDebuffBorders and spellInfo.type == AURA_TYPE_DEBUFF) then
			local preciseType = spellInfo.type .. (spellInfo.dispelType or "OTHER");
			if (icon.borderState ~= preciseType) then
				local color = db["DebuffBorders" .. (spellInfo.dispelType or "Other") .. "Color"];
				icon.border:SetVertexColor(unpack(color));
				icon.border:Show();
				icon.borderState = preciseType;
			end
		else
			if (icon.borderState ~= nil) then
				icon.border:Hide();
				icon.borderState = nil;
			end
		end
	end
	
	local function UpdateNameplate_SetGlow(icon, auraInfo, iconResized, dimGlow, remainingAuraTime, spellInfo)
		if (glowInfo[icon]) then
			glowInfo[icon]:Cancel(); -- // cancel delayed glow
			glowInfo[icon] = nil;
		end
		if (auraInfo and auraInfo.showGlow ~= nil) then
			if (auraInfo.showGlow == GLOW_TIME_INFINITE) then -- okay, we should show glow and user wants to see it without time limit
				LBG_ShowOverlayGlow(icon, iconResized, dimGlow);
			elseif (spellInfo.infinite_duration) then -- // okay, user has limited time for glow, but aura is permanent
				LBG_HideOverlayGlow(icon);
			elseif (remainingAuraTime < auraInfo.showGlow) then -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is less than user's limit
				LBG_ShowOverlayGlow(icon, iconResized, dimGlow);
			else -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is bigger than user's limit
				LBG_HideOverlayGlow(icon); -- // hide glow
				glowInfo[icon] = CTimerNewTimer(remainingAuraTime - auraInfo.showGlow, function() LBG_ShowOverlayGlow(icon, iconResized, dimGlow); end); -- // queue delayed glow
			end
		else
			LBG_HideOverlayGlow(icon); -- // this aura doesn't require glow
		end
	end
	
	function UpdateNameplate(frame, unitGUID)
		local counter = 1;
		local totalWidth = 0;
		if (AurasPerNameplate[frame]) then
			local currentTime = GetTime();
			AurasPerNameplate[frame] = SortAurasForNameplate(AurasPerNameplate[frame]);
			for _, spellInfo in pairs(AurasPerNameplate[frame]) do
				local spellName = SpellNameByID[spellInfo.spellID];
				local duration = spellInfo.duration;
				local last = spellInfo.expires - currentTime;
				if (last > 0 or spellInfo.infinite_duration) then
					if (counter > frame.NAurasIconsCount) then
						AllocateIcon(frame);
					end
					local icon = frame.NAurasIcons[counter];
					if (icon.spellID ~= spellInfo.spellID) then
						icon.texture:SetTexture(SpellTextureByID[spellInfo.spellID]);
						icon.spellID = spellInfo.spellID;
					end
					UpdateNameplate_SetCooldown(icon, last, spellInfo);
					-- // stacks
					UpdateNameplate_SetStacks(icon, spellInfo);
					-- // border
					UpdateNameplate_SetBorder(icon, spellInfo);
					-- // icon size
					local enabledAuraInfo = EnabledAurasInfo[spellName];
					local normalSize = enabledAuraInfo and enabledAuraInfo.iconSize or db.DefaultIconSize;
					local iconResized = false;
					if (normalSize ~= icon.size) then
						icon.size = normalSize;
						ResizeIcon(icon, icon.size);
						iconResized = true;
					end
					-- // glow
					if (spellInfo.overrideDimGlow == nil) then
						UpdateNameplate_SetGlow(icon, enabledAuraInfo, iconResized, db.UseDimGlow, last, spellInfo);
					else
						UpdateNameplate_SetGlow(icon, enabledAuraInfo, iconResized, spellInfo.overrideDimGlow, last, spellInfo);
					end
					if (not icon.shown) then
						ShowCDIcon(icon);
					end
					counter = counter + 1;
					totalWidth = totalWidth + icon.size + db.IconSpacing;
				end
			end
		end
		if (frame.NAurasFrame ~= nil) then
			totalWidth = totalWidth - db.IconSpacing; -- // because we don't need last spacing
			frame.NAurasFrame:SetWidth(totalWidth);
		end
		for k = counter, frame.NAurasIconsCount do
			local icon = frame.NAurasIcons[k];
			if (icon.shown) then
				HideCDIcon(icon);
			end
		end
		-- // hide standart buff frame
		if (db.HideBlizzardFrames and frame.UnitFrame ~= nil and frame.UnitFrame.BuffFrame ~= nil and unitGUID ~= LocalPlayerGUID) then
			frame.UnitFrame.BuffFrame:SetAlpha(0);
		end
		if (db.HidePlayerBlizzardFrame and frame.UnitFrame ~= nil and frame.UnitFrame.BuffFrame ~= nil and unitGUID == LocalPlayerGUID) then
			frame.UnitFrame.BuffFrame:SetAlpha(0);
		end
	end
	
	function OnUpdate()
		local currentTime = GetTime();
		for frame in pairs(NameplatesVisible) do
			local counter = 1;
			if (AurasPerNameplate[frame]) then
				for _, spellInfo in pairs(AurasPerNameplate[frame]) do
					local duration = spellInfo.duration;
					local last = spellInfo.expires - currentTime;
					if (last > 0 or spellInfo.infinite_duration) then
						-- // getting reference to icon
						local icon = frame.NAurasIcons[counter];
						-- // setting text
						UpdateNameplate_SetCooldown(icon, last, spellInfo);
						counter = counter + 1;
					end
				end
			end
		end
	end
	
end

--------------------------------------------------------------------------------------------------
----- Frame for events
--------------------------------------------------------------------------------------------------
do
	
	local TalentsReducingInterruptTime = addonTable.TalentsReducingInterruptTime;
	local MarkerSpellsForRestorationShamansAndShadowPriests = addonTable.MarkerSpellsForRestorationShamansAndShadowPriests;
	local InterruptSpells = addonTable.Interrupts;
	local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER;
	
	EventFrame = CreateFrame("Frame");
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	EventFrame:RegisterEvent("CHAT_MSG_ADDON");
	EventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); end);
	addonTable.EventFrame = EventFrame;
	
	function EventFrame.PLAYER_ENTERING_WORLD()
		if (addonTable.OnStartup) then
			addonTable.OnStartup();
		end
		for nameplate in pairs(AurasPerNameplate) do
			wipe(AurasPerNameplate[nameplate]);
		end
		wipe(UnitGUIDHasAdditionalInterruptReduction);
	end

	function EventFrame.NAME_PLATE_UNIT_ADDED(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = unitID;
		if (not Nameplates[nameplate]) then
			nameplate.NAurasIcons = {};
			nameplate.NAurasIconsCount = 0;
			Nameplates[nameplate] = true;
			AurasPerNameplate[nameplate] = {};
		end
		ProcessAurasForNameplate(nameplate, unitID);
		if (db.FullOpacityAlways and nameplate.NAurasFrame) then
			nameplate.NAurasFrame:Show();
		end
		if (db.InterruptsEnabled) then
			local interrupt = InterruptsPerUnitGUID[UnitGUID(unitID)];
			if (interrupt ~= nil) then
				local remainingTime = interrupt.expires - GetTime();
				if (remainingTime > 0) then
					CTimerAfter(remainingTime, function() ProcessAurasForNameplate(nameplate, unitID); end);
				end
			end
		end
	end
	
	function EventFrame.NAME_PLATE_UNIT_REMOVED(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = nil;
		if (AurasPerNameplate[nameplate] ~= nil) then
			wipe(AurasPerNameplate[nameplate]);
		end
		if (db.FullOpacityAlways and nameplate.NAurasFrame) then
			nameplate.NAurasFrame:Hide();
		end
	end
	
	function EventFrame.UNIT_AURA(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		if (nameplate ~= nil and AurasPerNameplate[nameplate] ~= nil) then
			ProcessAurasForNameplate(nameplate, unitID);
			if (db.FullOpacityAlways and nameplate.NAurasFrame) then
				nameplate.NAurasFrame:Show();
			end
		end
	end
	
	function EventFrame.CHAT_MSG_ADDON(prefix, message, channel, sender)
		if (prefix == "NAuras_prefix") then
			if (string_find(message, "reporting2")) then
				local _, toWhom, build = strsplit("^", message, 3);
				local myName = UnitName("player").."-"..string_gsub(GetRealmName(), " ", "");
				if (toWhom == myName) then
					Print(format("%s is using NAuras (%s)", sender, build));
				end
			elseif (string_find(message, "requesting2")) then
				C_ChatInfo.SendAddonMessage("NAuras_prefix", format("reporting2\^%s\^%s", sender, buildTimestamp or "DEVELOPER COPY"), channel);
			end
		end
	end
	
	function EventFrame.COMBAT_LOG_EVENT_UNFILTERED()
		local _, event, _, sourceGUID, _, _, _,destGUID,_,destFlags,_, spellID, spellName = CombatLogGetCurrentEventInfo();
		-- SPELL_INTERRUPT is not invoked for some channeled spells - implement later
		if (event == "SPELL_INTERRUPT") then
			local spellDuration = InterruptSpells[spellID];
			if (spellDuration ~= nil) then
				if (not db.InterruptsShowOnlyOnPlayers or bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0) then
					-- // warlocks have 30% interrupt lockout reduction
					if (UnitClassByGUID[destGUID] == "WARLOCK") then
						spellDuration = spellDuration * 0.7;
					-- // Restoration Shamans and Shadow Priests have 30% interrupt lockout reduction
					elseif (UnitGUIDHasAdditionalInterruptReduction[destGUID]) then
						spellDuration = spellDuration * 0.7;
					end
					-- // pvp talents
					if (UnitGUIDHasInterruptReduction[destGUID]) then
						spellDuration = spellDuration * 0.3;
					end
					InterruptsPerUnitGUID[destGUID] = {
						["duration"] = spellDuration,
						["expires"] = GetTime() + spellDuration,
						["stacks"] = 1,
						["spellID"] = spellID,
						["type"] = AURA_TYPE_DEBUFF,
						["spellName"] = spellName,
						["infinite_duration"] = false,
					};
					for frame, unitID in pairs(NameplatesVisible) do
						if (destGUID == UnitGUID(unitID)) then
							ProcessAurasForNameplate(frame, unitID);
							CTimerAfter(spellDuration, function() ProcessAurasForNameplate(frame, unitID); end);
							break;
						end
					end
				end
			end
		elseif (event == "SPELL_AURA_APPLIED") then
			if (TalentsReducingInterruptTime[spellName]) then
				UnitGUIDHasInterruptReduction[destGUID] = true;
			end
		elseif (event == "SPELL_AURA_REMOVED") then
			if (TalentsReducingInterruptTime[spellName]) then
				UnitGUIDHasInterruptReduction[destGUID] = nil;
			end
		elseif (event == "SPELL_CAST_SUCCESS") then
			if (MarkerSpellsForRestorationShamansAndShadowPriests[spellID]) then
				if (not UnitGUIDHasAdditionalInterruptReduction[sourceGUID]) then
					UnitGUIDHasAdditionalInterruptReduction[sourceGUID] = true;
					CTimerAfter(60, function() UnitGUIDHasAdditionalInterruptReduction[sourceGUID] = nil; end);
				end
				
			end
		end
	end
	
	local function UpdatePvPState()
		local inPvPCombat = IsUsableSpell(SpellNameByID[195710]); -- // Honorable Medallion
		if (inPvPCombat ~= InPvPCombat) then
			InPvPCombat = inPvPCombat;
			addonTable.UpdateAllNameplates(false);
		end
		CTimerAfter(1, UpdatePvPState);
	end
	CTimerAfter(1, UpdatePvPState);
	
end
