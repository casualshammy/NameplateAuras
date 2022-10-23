-- luacheck: no max line length
-- luacheck: globals LibStub NAuras_LibButtonGlow strfind format GetTime ceil floor wipe C_NamePlate UnitBuff
-- luacheck: globals UnitDebuff UnitReaction UnitGUID UnitIsFriend IsInGroup LE_PARTY_CATEGORY_INSTANCE IsInRaid
-- luacheck: globals UnitIsPlayer C_Timer strsplit CombatLogGetCurrentEventInfo max min GetNumAddOns GetAddOnInfo
-- luacheck: globals IsAddOnLoaded InterfaceOptionsFrameCancel GetSpellTexture CreateFrame UIParent COMBATLOG_OBJECT_TYPE_PLAYER
-- luacheck: globals GetNumGroupMembers IsPartyLFG GetNumSubgroupMembers IsPartyLFG UnitDetailedThreatSituation PlaySound
-- luacheck: globals IsInInstance PlaySoundFile bit loadstring setfenv GetInstanceInfo GameTooltip UnitName

local _, addonTable = ...;

local buildTimestamp = "DEVELOPER COPY";
--[===[@non-debug@
buildTimestamp = "@project-version@";
--@end-non-debug@]===]

local LBG_ShowOverlayGlow, LBG_HideOverlayGlow = NAuras_LibButtonGlow.ShowOverlayGlow, NAuras_LibButtonGlow.HideOverlayGlow;
local SML = LibStub("LibSharedMedia-3.0");
local AceComm = LibStub("AceComm-3.0");
local LibCustomGlow = LibStub("LibCustomGlow-1.0");
local LRD = LibStub("LibRedDropdown-1.0");
local DRList = LibStub("DRList-1.0");

-- // upvalues
local 	_G, pairs, string_find,string_format, 	GetTime, math_ceil, math_floor, wipe, C_NamePlate_GetNamePlateForUnit, UnitBuff, UnitDebuff, UnitIsPlayer,
			UnitReaction, UnitGUID,  table_sort, CTimerAfter,	bit_band, CTimerNewTimer,   strsplit, CombatLogGetCurrentEventInfo, math_max, math_min =
		_G, pairs, 			strfind, 	format,			GetTime, ceil,		floor,		wipe, C_NamePlate.GetNamePlateForUnit, UnitBuff, UnitDebuff, UnitIsPlayer,
			UnitReaction, UnitGUID,  table.sort, C_Timer.After,	bit.band, C_Timer.NewTimer, strsplit, CombatLogGetCurrentEventInfo, max,	  min;
local GetNumGroupMembers, IsPartyLFG, GetNumSubgroupMembers, PlaySound, PlaySoundFile = GetNumGroupMembers, IsPartyLFG, GetNumSubgroupMembers, PlaySound, PlaySoundFile;
local UnitDetailedThreatSituation, IsInInstance, GetInstanceInfo = UnitDetailedThreatSituation, IsInInstance, GetInstanceInfo;

-- // variables
local AurasPerNameplate, InterruptsPerUnitGUID, Nameplates, NameplatesVisible, DRResetTime, InstanceType;
local EventFrame, db, aceDB, LocalPlayerGUID, DebugWindow, ProcessAurasForNameplate, UpdateNameplate, SetAlphaScaleForNameplate, DRDataPerGUID, TargetGUID;
local SpitefulMobs;
do
	AurasPerNameplate 						= { };
	InterruptsPerUnitGUID					= { };
	Nameplates, NameplatesVisible 			= { }, { };
	addonTable.Nameplates					= Nameplates;
	addonTable.AllAuraIconFrames			= { };
	DRDataPerGUID							= { };
	DRResetTime								= DRList:GetResetTime();
	SpitefulMobs							= { };
	InstanceType							= addonTable.INSTANCE_TYPE_NONE;
end

-- // consts
local CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS, AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY, AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE,
	AURA_SORT_MODE_AURATYPE_EXPIRE,
	GLOW_TIME_INFINITE, EXPLOSIVE_ORB_SPELL_ID, VERY_LONG_COOLDOWN_DURATION, BORDER_TEXTURES;
do
	CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS = addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_ALL, addonTable.CONST_SPELL_MODE_MYAURAS;
	AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY = addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY;
	AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE, AURA_SORT_MODE_AURATYPE_EXPIRE =
		addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIRETIME, addonTable.AURA_SORT_MODE_ICONSIZE, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE;
	GLOW_TIME_INFINITE = addonTable.GLOW_TIME_INFINITE; -- // 30 days
	EXPLOSIVE_ORB_SPELL_ID = addonTable.EXPLOSIVE_ORB_SPELL_ID;
	VERY_LONG_COOLDOWN_DURATION = addonTable.VERY_LONG_COOLDOWN_DURATION; -- // 30 days
	BORDER_TEXTURES = addonTable.BORDER_TEXTURES;
end

-- // utilities
local Print, table_count, SpellTextureByID, SpellNameByID = addonTable.Print, addonTable.table_count, addonTable.SpellTextureByID, addonTable.SpellNameByID;

--------------------------------------------------------------------------------------------------
----- db, on start routines...
--------------------------------------------------------------------------------------------------
do

	local ReloadDB;

	local function OnAddonMessageReceived(prefix, text, distribution, sender)
		if (prefix == "NameplateAuras") then
			if (string_find(text, "reporting3")) then
				local _, toWhomGUID, build = strsplit("#", text, 3);
				if (toWhomGUID == LocalPlayerGUID) then
					Print(format("%s is using NAuras (%s)", sender, build));
				end
			elseif (string_find(text, "requesting3")) then
				local _, senderGUID = strsplit("#", text, 2);
				AceComm:SendCommMessage("NameplateAuras",
					format("reporting3#%s#%s", senderGUID, buildTimestamp or "DEVELOPER COPY"), distribution);
			end
		end
	end

	local function ChatCommand_Debug()
		DebugWindow = DebugWindow or LibStub("LibRedDropdown-1.0").CreateDebugWindow();
		DebugWindow:AddText("PRESS ESC TO CLOSE THIS WINDOW");
		DebugWindow:AddText("PRESS CTRL+A AND THEN CTRL+C TO COPY THIS TEXT");
		DebugWindow:AddText("");
		DebugWindow:AddText("Version: " .. tostring(buildTimestamp or "DEVELOPER COPY"));
		DebugWindow:AddText("");
		DebugWindow:AddText("Number of nameplates: " .. table_count(Nameplates));
		DebugWindow:AddText("Number of visible nameplates: " .. table_count(NameplatesVisible));
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
		for _, spellInfo in pairs(db.CustomSpells2) do
			DebugWindow:AddText(string_format("    %s: %s; %s; %s; %s; %s; %s; %s; %s;", spellInfo.spellName,
				tostring(enabledStateTokens[spellInfo.enabledState]),
				tostring(auraTypeTokens[spellInfo.auraType]),
				tostring(spellInfo.iconSizeWidth)..":"..tostring(spellInfo.iconSizeHeight),
				spellInfo.checkSpellID ~= nil and table.concat(spellInfo.checkSpellID, ",") or "NONE",
				tostring(spellInfo.showOnFriends),
				tostring(spellInfo.showOnEnemies),
				tostring(spellInfo.playerNpcMode),
				tostring(spellInfo.showGlow)));
		end
		DebugWindow:Show();
	end

	local function InitializeDB()
		-- // set defaults
		local aceDBDefaults = {
			profile = {
				DBVersion = 0,
				DefaultSpellsLastSetImported = 0,
				CustomSpells2 = { },
				IconXOffset = 0,
				IconYOffset = 50,
				Font = "NAuras_TeenBold",
				HideBlizzardFrames = true,
				SortMode = AURA_SORT_MODE_EXPIRETIME,
				FontScale = 1,
				TimerTextUseRelativeScale = true,
				TimerTextSize = 20,
				TimerTextAnchor = "CENTER",
				TimerTextAnchorIcon = "CENTER",
				TimerTextXOffset = 0,
				TimerTextYOffset = 0,
				TimerTextSoonToExpireColor = { 1, 0.1, 0.1, 1 },
				TimerTextUnderMinuteColor = { 1, 1, 0.1, 1 },
				TimerTextLongerColor = { 0.7, 1, 0, 1 },
				StacksFont = "NAuras_TeenBold",
				StacksFontScale = 1,
				StacksTextAnchor = "BOTTOMRIGHT",
				StacksTextAnchorIcon = "BOTTOMRIGHT",
				StacksTextXOffset = -3,
				StacksTextYOffset = 5,
				StacksTextColor = { 1, 0.1, 0.1, 1 },
				ShowBuffBorders = true,
				BuffBordersColor = {0, 1, 0, 1},
				ShowDebuffBorders = true,
				DebuffBordersMagicColor = { 0.1, 1, 1, 1 },
				DebuffBordersCurseColor = { 1, 0.1, 1, 1 },
				DebuffBordersDiseaseColor = { 1, 0.5, 0.1, 1 },
				DebuffBordersPoisonColor = { 0.1, 1, 0.1, 1 },
				DebuffBordersOtherColor = { 1, 0.1, 0.1, 1 },
				ShowAurasOnPlayerNameplate = false,
				IconSpacing = 1,
				IconAnchor = "LEFT",
				AlwaysShowMyAuras = false,
				BorderThickness = 2,
				ShowAboveFriendlyUnits = true,
				FrameAnchor = "CENTER",
				FrameAnchorToNameplate = "CENTER",
				MinTimeToShowTenthsOfSeconds = 10,
				InterruptsEnabled = true,
				InterruptsIconSizeWidth = 45,
				InterruptsIconSizeHeight = 45,
				InterruptsGlowType = addonTable.GLOW_TYPE_ACTIONBUTTON_DIM,
				InterruptsUseSharedIconTexture = false,
				InterruptsShowOnlyOnPlayers = true,
				Additions_ExplosiveOrbs = true,
				ShowAuraTooltip = false,
				HidePlayerBlizzardFrame = "undefined", -- // don't change: we convert db with that
				Additions_DispellableSpells = false,
				Additions_DispellableSpells_Blacklist = {},
				DispelIconSizeWidth = 45,
				DispelIconSizeHeight = 45,
				Additions_DispellableSpells_GlowType = addonTable.GLOW_TYPE_PIXEL,
				IconGrowDirection = addonTable.ICON_GROW_DIRECTION_RIGHT,
				ShowStacks = true,
				ShowCooldownText = true,
				ShowCooldownAnimation = true,
				IconAlpha = 1.0,
				IconAlphaTarget = 1.0,
				IconScaleTarget = 1.0,
				TargetStrata = "HIGH",
				NonTargetStrata = "MEDIUM",
				BorderType = addonTable.BORDER_TYPE_BUILTIN,
				BorderFilePath = "Interface\\AddOns\\NameplateAuras\\media\\custom-example.tga",
				DefaultIconSizeWidth = 45,
				DefaultIconSizeHeight = 45,
				IconZoom = 0.07,
				CustomSortMethod = "function(aura1, aura2) return aura1.spellName < aura2.spellName; end",
				Additions_DRPvP = false,
				Additions_DRPvE = false,
				ShowOnlyOnTarget = false,
				UseTargetAlphaIfNotTargetSelected = false,
				AffixSpiteful = true,
				AffixSpitefulSound = 5274,
				EnabledZoneTypes = {
					[addonTable.INSTANCE_TYPE_NONE] =			true,
					[addonTable.INSTANCE_TYPE_UNKNOWN] = 		true,
					[addonTable.INSTANCE_TYPE_PVP] = 			true,
					[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = 	true,
					[addonTable.INSTANCE_TYPE_ARENA] = 			true,
					[addonTable.INSTANCE_TYPE_PARTY] = 			true,
					[addonTable.INSTANCE_TYPE_RAID] = 			true,
					[addonTable.INSTANCE_TYPE_SCENARIO] =		true,
				},
				MaxAuras = nil,
				ShowAurasOnTargetEvenInDisabledAreas = false,
				AlwaysShowMyAurasBlacklist = {},
				NpcBlacklist = {},
				TimerTextUseRelativeColor = false,
				TimerTextColorZeroPercent = {1, 0.1, 0.1, 1},
				TimerTextColorHundredPercent = {0.1, 1, 0.1, 1},
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
					func = addonTable.ShowGUI,
				},
			},
		});
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras", "NameplateAuras");
		local profilesConfig = LibStub("AceDBOptions-3.0"):GetOptionsTable(aceDB);
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras.profiles", profilesConfig);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras.profiles", "Profiles", "NameplateAuras");

		aceDB.RegisterCallback("NameplateAuras", "OnProfileChanged", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileCopied", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileReset", ReloadDB);
	end

	local function OnChatCommand(_msg)
		local msg, arg1 = strsplit(" ", _msg, 2);
		if (msg == "ver") then
			local c;
			if (IsInRaid() and GetNumGroupMembers() > 0) then
				c = IsPartyLFG() and "INSTANCE_CHAT" or "RAID";
			elseif (not IsInRaid() and GetNumSubgroupMembers() > 0) then
				c = IsPartyLFG() and "INSTANCE_CHAT" or "PARTY";
			else
				c = "GUILD";
			end
			Print("Waiting for replies from " .. c);
			AceComm:SendCommMessage("NameplateAuras", "requesting3#" .. LocalPlayerGUID, c);
		elseif (msg == "debug") then
			ChatCommand_Debug();
		elseif (msg == "test") then
			addonTable.SwitchTestMode();
		elseif (msg == "batch:only-pvp") then -- luacheck: ignore

		elseif (msg == "batch:only-pve") then -- luacheck: ignore

		elseif (msg == "max-auras") then
			local count = tonumber(arg1);
			if (count ~= nil) then
				if (count <= 0) then
					db.MaxAuras = nil;
				else
					db.MaxAuras = count;
				end
				addonTable.UpdateAllNameplates();
				Print("'max-auras' is set to " .. (db.MaxAuras or "'disabled'"));
			end
		elseif (msg == "import-default-spells") then
			addonTable.ImportNewSpells(true);
		else
			addonTable.ShowGUI();
		end
	end

	function addonTable.OnStartup()
		-- // getting player's GUID
		LocalPlayerGUID = UnitGUID("player");
		-- // ...
		InitializeDB();
		-- // ...
		ReloadDB();
		addonTable.CompileSortFunction();
		addonTable.RebuildSpellCache();
		-- // starting listening for events
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
		EventFrame:RegisterEvent("UNIT_AURA");
		EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
		EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		EventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE");
		-- // adding slash command
		SLASH_NAMEPLATEAURAS1 = '/nauras'; -- luacheck: ignore
		SlashCmdList["NAMEPLATEAURAS"] = OnChatCommand; -- luacheck: ignore
		AceComm:RegisterComm("NameplateAuras", OnAddonMessageReceived);
		addonTable.OnStartup = nil;
	end

	function ReloadDB()
		db = aceDB.profile;
		addonTable.db = aceDB.profile;
		-- set texture for interrupt spells
		for spellID in pairs(addonTable.Interrupts) do
			SpellTextureByID[spellID] = db.InterruptsUseSharedIconTexture and "Interface\\AddOns\\NameplateAuras\\media\\warrior_disruptingshout.tga" or GetSpellTexture(spellID); -- // icon of Interrupting Shout
		end
		-- // convert values
		addonTable.MigrateDB();
		-- // import default spells
		addonTable.ImportNewSpells();
		-- //
		if (addonTable.GUIFrame) then
			for _, func in pairs(addonTable.GUIFrame.OnDBChangedHandlers) do
				func();
			end
		end
		-- //
		addonTable.IsNpcBlacklistEnabled = addonTable.table_count(db.NpcBlacklist) > 0;
		addonTable.UpdateAllNameplates(true);
	end
	addonTable.ReloadDB = ReloadDB;

end

--------------------------------------------------------------------------------------------------
----- Nameplates
--------------------------------------------------------------------------------------------------
do
	local EXPLOSIVE_ORB_NPC_ID_AS_STRING = addonTable.EXPLOSIVE_ORB_NPC_ID_AS_STRING;
	local GLOW_TYPE_NONE, GLOW_TYPE_ACTIONBUTTON, GLOW_TYPE_AUTOUSE, GLOW_TYPE_PIXEL, GLOW_TYPE_ACTIONBUTTON_DIM =
		addonTable.GLOW_TYPE_NONE, addonTable.GLOW_TYPE_ACTIONBUTTON, addonTable.GLOW_TYPE_AUTOUSE, addonTable.GLOW_TYPE_PIXEL, addonTable.GLOW_TYPE_ACTIONBUTTON_DIM;
	local AURA_SORT_MODE_CUSTOM = addonTable.AURA_SORT_MODE_CUSTOM;
	local SHOW_ON_PLAYERS_AND_NPC, SHOW_ON_PLAYERS, SHOW_ON_NPC = addonTable.SHOW_ON_PLAYERS_AND_NPC, addonTable.SHOW_ON_PLAYERS, addonTable.SHOW_ON_NPC;
	local glowInfo = { };
	local animationInfo = { };
	local defaultCustomSortFunction = function(aura1, aura2) return aura1.spellName < aura2.spellName; end;
	local AuraSortFunctions;
	AuraSortFunctions = {
		[AURA_SORT_MODE_EXPIRETIME] = function(item1, item2)
			local expires1, expires2 = item1.expires, item2.expires;
			if (expires1 == 0) then expires1 = VERY_LONG_COOLDOWN_DURATION; end
			if (expires2 == 0) then expires2 = VERY_LONG_COOLDOWN_DURATION; end
			return expires1 < expires2;
		end,
		[AURA_SORT_MODE_ICONSIZE] = function(item1, item2)
			local size1 = (item1.dbEntry == nil and math_min(db.DefaultIconSizeHeight, db.DefaultIconSizeWidth) or math_min(item1.dbEntry.iconSizeWidth, item1.dbEntry.iconSizeHeight));
			local size2 = (item2.dbEntry == nil and math_min(db.DefaultIconSizeHeight, db.DefaultIconSizeWidth) or math_min(item2.dbEntry.iconSizeWidth, item2.dbEntry.iconSizeHeight));
			return size1 < size2;
		end,
		[AURA_SORT_MODE_AURATYPE_EXPIRE] = function(item1, item2)
			if (item1.type ~= item2.type) then
				return (item1.type == AURA_TYPE_DEBUFF) and true or false;
			end
			return AuraSortFunctions[AURA_SORT_MODE_EXPIRETIME](item1, item2);
		end,
		[AURA_SORT_MODE_CUSTOM] = defaultCustomSortFunction,
	};

	local spellCache = { };
	function addonTable.RebuildSpellCache()
		wipe(spellCache);
		for _, dbEntry in pairs(db.CustomSpells2) do
			if (spellCache[dbEntry.spellName] == nil) then
				spellCache[dbEntry.spellName] = { };
			end
			spellCache[dbEntry.spellName][#spellCache[dbEntry.spellName]+1] = dbEntry;
		end
	end

	function addonTable.CompileSortFunction()
		local sort_time = AuraSortFunctions[AURA_SORT_MODE_EXPIRETIME];
		local sort_size = AuraSortFunctions[AURA_SORT_MODE_ICONSIZE];
		local exec_env = setmetatable({}, { __index =
			function(t, k) -- luacheck: ignore
				if (k == "sort_time") then
					return sort_time;
				elseif (k == "sort_size") then
					return sort_size;
				else
					return _G[k];
				end
			end
		});
		local script = db.CustomSortMethod;
		script = "return " .. script;
		local func, errorMsg = loadstring(script);
		if (not func) then
			addonTable.Print("Your custom sorting function contains error: \n" .. errorMsg);
			AuraSortFunctions[AURA_SORT_MODE_CUSTOM] = defaultCustomSortFunction;
		else
			setfenv(func, exec_env);
			local success, sortFunc = pcall(assert(func));
			if (success) then
				AuraSortFunctions[AURA_SORT_MODE_CUSTOM] = sortFunc;
			end
		end
	end

	local iconTooltip = LRD.CreateTooltip();
	local function AllocateIcon_SetAuraTooltip(icon)
		icon:SetScript("OnEnter", nil);
		icon:SetScript("OnLeave", nil);
		if (db.ShowAuraTooltip) then
			icon:SetScript("OnEnter", function(self)
				if (db.UseDefaultAuraTooltip) then
					GameTooltip:Hide();
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetSpellByID(self.spellID);
					GameTooltip:Show();
				else
					iconTooltip:ClearAllPoints();
					iconTooltip:SetPoint("BOTTOM", self, "TOP", 0, 0);
					iconTooltip:SetSpellById(self.spellID);
					iconTooltip:Show();
				end
			end);
			icon:SetScript("OnLeave", function()
				if (db.UseDefaultAuraTooltip) then
					GameTooltip:Hide();
				else
					iconTooltip:Hide();
				end
			end);
		end
	end
	addonTable.AllocateIcon_SetAuraTooltip = AllocateIcon_SetAuraTooltip;

	local function SetFrameSize(frame, maxIconWidth, maxIconHeight, totalWidth, totalHeight)
		if (db.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_RIGHT or db.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_LEFT) then
			frame:SetWidth(totalWidth);
			frame:SetHeight(maxIconHeight);
		else
			frame:SetWidth(maxIconWidth);
			frame:SetHeight(totalHeight);
		end
	end

	local iconAligns0 = {
		[addonTable.ICON_ALIGN_BOTTOM_LEFT] = {
			[addonTable.ICON_GROW_DIRECTION_RIGHT] = "BOTTOMLEFT",
			[addonTable.ICON_GROW_DIRECTION_LEFT] = "BOTTOMRIGHT",
			[addonTable.ICON_GROW_DIRECTION_UP] = "BOTTOMLEFT",
			[addonTable.ICON_GROW_DIRECTION_DOWN] = "TOPLEFT",
		},
		[addonTable.ICON_ALIGN_TOP_RIGHT] = {
			[addonTable.ICON_GROW_DIRECTION_RIGHT] = "TOPLEFT",
			[addonTable.ICON_GROW_DIRECTION_LEFT] = "TOPRIGHT",
			[addonTable.ICON_GROW_DIRECTION_UP] = "BOTTOMRIGHT",
			[addonTable.ICON_GROW_DIRECTION_DOWN] = "TOPRIGHT",
		},
		[addonTable.ICON_ALIGN_CENTER] = {
			[addonTable.ICON_GROW_DIRECTION_RIGHT] = "LEFT",
			[addonTable.ICON_GROW_DIRECTION_LEFT] = "RIGHT",
			[addonTable.ICON_GROW_DIRECTION_UP] = "BOTTOM",
			[addonTable.ICON_GROW_DIRECTION_DOWN] = "TOP",
		},
	};

	local iconAlignsOther = {
		[addonTable.ICON_ALIGN_BOTTOM_LEFT] = {
			[addonTable.ICON_GROW_DIRECTION_RIGHT] = "BOTTOMRIGHT",
			[addonTable.ICON_GROW_DIRECTION_LEFT] = "BOTTOMLEFT",
			[addonTable.ICON_GROW_DIRECTION_UP] = "TOPLEFT",
			[addonTable.ICON_GROW_DIRECTION_DOWN] = "BOTTOMLEFT",
		},
		[addonTable.ICON_ALIGN_TOP_RIGHT] = {
			[addonTable.ICON_GROW_DIRECTION_RIGHT] = "TOPRIGHT",
			[addonTable.ICON_GROW_DIRECTION_LEFT] = "TOPLEFT",
			[addonTable.ICON_GROW_DIRECTION_UP] = "TOPRIGHT",
			[addonTable.ICON_GROW_DIRECTION_DOWN] = "BOTTOMRIGHT",
		},
		[addonTable.ICON_ALIGN_CENTER] = {
			[addonTable.ICON_GROW_DIRECTION_RIGHT] = "RIGHT",
			[addonTable.ICON_GROW_DIRECTION_LEFT] = "LEFT",
			[addonTable.ICON_GROW_DIRECTION_UP] = "TOP",
			[addonTable.ICON_GROW_DIRECTION_DOWN] = "BOTTOM",
		},
	};

	function SetAlphaScaleForNameplate(nameplate)
		if (nameplate ~= nil and nameplate.NAurasFrame ~= nil) then
			local frameLevel = nameplate:GetFrameLevel();
			nameplate.NAurasFrame:SetFrameLevel((frameLevel or 1)*10);

			local unitID = NameplatesVisible[nameplate];
			if (unitID ~= nil) then
				local unitGUID = UnitGUID(unitID);
				if (unitGUID == TargetGUID or (TargetGUID == nil and db.UseTargetAlphaIfNotTargetSelected)) then
					nameplate.NAurasFrame:SetAlpha(db.IconAlphaTarget);
				else
					nameplate.NAurasFrame:SetAlpha(db.IconAlpha);
				end
				-- if (unitGUID == TargetGUID) then
				-- 	nameplate.NAurasFrame:SetScale(db.IconScaleTarget);
				-- else
				-- 	nameplate.NAurasFrame:SetScale(1.0);
				-- end
				if (unitGUID == TargetGUID) then
					nameplate.NAurasFrame:SetFrameStrata(db.TargetStrata);
				else
					nameplate.NAurasFrame:SetFrameStrata(db.NonTargetStrata);
				end
			end
		end
	end

	local function AllocateIcon_SetIconPlace(frame, icon, iconIndex)
		icon:ClearAllPoints();
		local index = iconIndex == nil and frame.NAurasIconsCount or (iconIndex-1)
		if (index == 0) then
			local anchor = iconAligns0[db.IconAnchor][db.IconGrowDirection];
			icon:SetPoint(anchor, frame.NAurasFrame, anchor, 0, 0);
		else
			local anchor0 = iconAligns0[db.IconAnchor][db.IconGrowDirection];
			local anchor1 = iconAlignsOther[db.IconAnchor][db.IconGrowDirection];
			if (db.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_RIGHT) then
				icon:SetPoint(anchor0, frame.NAurasIcons[index], anchor1, db.IconSpacing, 0);
			elseif (db.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_LEFT) then
				icon:SetPoint(anchor0, frame.NAurasIcons[index], anchor1, -db.IconSpacing, 0);
			elseif (db.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_UP) then
				icon:SetPoint(anchor0, frame.NAurasIcons[index], anchor1, 0, db.IconSpacing);
			else -- // down
				icon:SetPoint(anchor0, frame.NAurasIcons[index], anchor1, 0, -db.IconSpacing);
			end
		end
	end

	local function CalculateRelativeColor(_colorMin, _colorMax, _percent)
		local r = _colorMax[1] - _colorMin[1];
		local g = _colorMax[2] - _colorMin[2];
		local b = _colorMax[3] - _colorMin[3];
		local a = _colorMax[4] - _colorMin[4];

		return {
			_colorMin[1] + r*_percent,
			_colorMin[2] + g*_percent,
			_colorMin[3] + b*_percent,
			_colorMin[4] + a*_percent
		};
	end

	local colortype_long, colortype_medium, colortype_short = 1, 2, 3;
	local function IconSetCooldown(icon, remainingTime, spellInfo)
		if (db.ShowCooldownText) then
			-- cooldown text
			local text;
			if (remainingTime > 3600 or spellInfo.duration == 0) then
				text = "";
			elseif (remainingTime >= 60) then
				text = math_floor(remainingTime/60).."m";
			elseif (remainingTime >= db.MinTimeToShowTenthsOfSeconds) then
				text = string_format("%d", remainingTime);
			else
				text = string_format("%.1f", remainingTime);
			end
			if (icon.text ~= text) then
				icon.cooldownText:SetText(text);
				icon.text = text;
				if (spellInfo.duration == 0 or not db.ShowCooldownAnimation) then
					icon.cooldownText:SetParent(icon);
				else
					icon.cooldownText:SetParent(icon.cooldownFrame);
				end
			end

			-- cooldown text color
			if (db.TimerTextUseRelativeColor and spellInfo.duration ~= 0) then
				local percent = math_floor(remainingTime * 10 / spellInfo.duration);
				if (icon.textColor ~= percent) then
					local color = CalculateRelativeColor(db.TimerTextColorZeroPercent, db.TimerTextColorHundredPercent, percent / 10);
					icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
					icon.textColor = percent;
				end
			else
				if (remainingTime >= 60 or spellInfo.duration == 0) then
					if (icon.textColor ~= colortype_long) then
						local color = db.TimerTextLongerColor;
						icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
						icon.textColor = colortype_long;
					end
				elseif (remainingTime >= 5) then
					if (icon.textColor ~= colortype_medium) then
						local color = db.TimerTextUnderMinuteColor;
						icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
						icon.textColor = colortype_medium;
					end
				else
					if (icon.textColor ~= colortype_short) then
						local color = db.TimerTextSoonToExpireColor;
						icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
						icon.textColor = colortype_short;
					end
				end
			end
		elseif (icon.text ~= "") then
			icon.cooldownText:SetText("");
			icon.text = "";
		end

		-- stacks
		local stacks = db.ShowStacks and spellInfo.stacks or 1;
		if (icon.stackcount ~= stacks) then
			if (stacks > 1) then
				icon.stacks:SetText(stacks);
				if (spellInfo.duration == 0 or not db.ShowCooldownAnimation) then
					icon.stacks:SetParent(icon);
				else
					icon.stacks:SetParent(icon.cooldownFrame);
				end
			else
				icon.stacks:SetText("");
			end
			icon.stackcount = stacks;
		end

		-- cooldown animation
		if (db.ShowCooldownAnimation) then
			if (spellInfo.expires ~= icon.cooldownExpires or spellInfo.duration ~= icon.cooldownDuration) then
				if (spellInfo.duration == 0) then
					icon.cooldownFrame:Hide();
				else
					icon.cooldownFrame:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
					icon.cooldownFrame:Show();
				end
				icon.cooldownExpires = spellInfo.expires;
				icon.cooldownDuration = spellInfo.duration;
			end
		else
			icon.cooldownFrame:Hide();
		end
	end

	-- this method is called only if icon really need animation functionality
	local function CreateIconAnimation(icon)
		icon.alphaAnimationGroup = icon:CreateAnimationGroup();
		icon.alphaAnimationGroup:SetLooping("BOUNCE");
		local animation0 = icon.alphaAnimationGroup:CreateAnimation("Alpha");
		animation0:SetFromAlpha(1);
		animation0:SetToAlpha(0);
		animation0:SetDuration(0.5);
		animation0:SetOrder(1);
	end

	local function AllocateIcon(frame)
		if (not frame.NAurasFrame) then
			frame.NAurasFrame = CreateFrame("frame", nil, UIParent);
			frame.NAurasFrame:SetWidth(db.DefaultIconSizeWidth);
			frame.NAurasFrame:SetHeight(db.DefaultIconSizeHeight);
			frame.NAurasFrame:SetPoint(db.FrameAnchor, frame, db.FrameAnchorToNameplate, db.IconXOffset, db.IconYOffset);
			SetAlphaScaleForNameplate(frame);
			frame.NAurasFrame:Show();
		end
		local icon = CreateFrame("Frame", nil, frame.NAurasFrame);
		AllocateIcon_SetAuraTooltip(icon);
		AllocateIcon_SetIconPlace(frame, icon);
		icon:SetSize(db.DefaultIconSizeWidth, db.DefaultIconSizeHeight);
		icon.texture = icon:CreateTexture(nil, "BORDER");
		icon.texture:SetAllPoints(icon);
		icon.border = icon:CreateTexture(nil, "ARTWORK");
		icon.stacks = icon:CreateFontString(nil, "ARTWORK");
		icon.cooldownText = icon:CreateFontString(nil, "ARTWORK");
		icon.cooldownFrame = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
		icon.cooldownFrame:SetAllPoints(icon);
		icon.cooldownFrame:SetReverse(true);
		icon.cooldownFrame:SetHideCountdownNumbers(true);
		icon.cooldownFrame.noCooldownCount = true; -- refuse OmniCC
		icon.SetCooldown = IconSetCooldown;
		icon.sizeWidth = db.DefaultIconSizeWidth;
		icon.sizeHeight = db.DefaultIconSizeHeight;
		icon:Hide();
		icon.cooldownText:SetTextColor(0.7, 1, 0);
		icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
		if (db.TimerTextUseRelativeScale) then
			local sizeMin = math_min(db.DefaultIconSizeWidth, db.DefaultIconSizeHeight);
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((sizeMin - sizeMin / 2) * db.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
		end
		if (db.BorderType == addonTable.BORDER_TYPE_BUILTIN) then
			icon.border:SetTexture(BORDER_TEXTURES[db.BorderThickness]);
		elseif (db.BorderType == addonTable.BORDER_TYPE_CUSTOM) then
			icon.border:SetTexture(db.BorderFilePath);
		end
		icon.border:SetVertexColor(1, 0.35, 0);
		icon.border:SetAllPoints(icon);
		icon.border:Hide();
		local color = db.StacksTextColor;
		icon.stacks:SetTextColor(color[1], color[2], color[3], color[4]);
		icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextAnchorIcon, db.StacksTextXOffset, db.StacksTextYOffset);
		icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((math_min(db.DefaultIconSizeWidth, db.DefaultIconSizeHeight) / 4) * db.StacksFontScale), "OUTLINE");
		icon.stackcount = 0;
		addonTable.AllAuraIconFrames[#addonTable.AllAuraIconFrames+1] = icon;
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.DefaultIconSizeWidth * frame.NAurasIconsCount);
		frame.NAurasIcons[#frame.NAurasIcons+1] = icon;
	end

	local function HideGlow(icon)
		if (icon.glowType ~= nil) then
			LBG_HideOverlayGlow(icon);
			LibCustomGlow.PixelGlow_Stop(icon);
			LibCustomGlow.AutoCastGlow_Stop(icon);
			icon.glowType = nil;
		end
	end

	local function HideAnimation(icon)
		if (icon.animationType ~= nil) then
			icon.alphaAnimationGroup:Stop();
			icon.animationType = nil;
		end
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
		icon.sizeWidth = -1;
		icon.sizeHeight = -1;
		icon.text = nil;
		icon.cooldownExpires = nil;
		HideGlow(icon);
		HideAnimation(icon);
	end

	local function ShowCDIcon(icon)
		icon.cooldownText:Show();
		icon.stacks:Show();
		icon:Show();
		icon.shown = true;
	end

	local function UpdateAllNameplates(force)
		if (force) then
			for nameplate in pairs(Nameplates) do
				if (nameplate.NAurasFrame) then
					nameplate.NAurasFrame:ClearAllPoints();
					nameplate.NAurasFrame:SetPoint(db.FrameAnchor, nameplate, db.FrameAnchorToNameplate, db.IconXOffset, db.IconYOffset);
					for iconIndex, icon in pairs(nameplate.NAurasIcons) do
						if (icon.shown) then
							local sizeMin = math_min(db.DefaultIconSizeWidth, db.DefaultIconSizeHeight);
							if (db.TimerTextUseRelativeScale) then
								icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((sizeMin - sizeMin / 2) * db.FontScale), "OUTLINE");
							else
								icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
							end
							icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((sizeMin / 4) * db.StacksFontScale), "OUTLINE");
						end
						AllocateIcon_SetIconPlace(nameplate, icon, iconIndex);
						icon.cooldownText:ClearAllPoints();
						icon.cooldownText:SetPoint(db.TimerTextAnchor, icon, db.TimerTextAnchorIcon, db.TimerTextXOffset, db.TimerTextYOffset);
						icon.textColor = nil;
						icon.stacks:ClearAllPoints();
						icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextAnchorIcon, db.StacksTextXOffset, db.StacksTextYOffset);
						local color = db.StacksTextColor;
						icon.stacks:SetTextColor(color[1], color[2], color[3], color[4]);
						if (db.BorderType == addonTable.BORDER_TYPE_BUILTIN) then
							icon.border:SetTexture(BORDER_TEXTURES[db.BorderThickness]);
						elseif (db.BorderType == addonTable.BORDER_TYPE_CUSTOM) then
							icon.border:SetTexture(db.BorderFilePath);
						end
						HideCDIcon(icon);
					end
					SetAlphaScaleForNameplate(nameplate);
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

	local function ProcAurasForNmplt_Filter(auraType, auraCaster, auraSpellID, unitIsFriend, dbEntry, unitIsPlayer)
		if (dbEntry ~= nil) then
			if (dbEntry.enabledState == CONST_SPELL_MODE_ALL or (dbEntry.enabledState == CONST_SPELL_MODE_MYAURAS and (auraCaster == "player" or auraCaster == "pet"))) then
				if ((not unitIsFriend and dbEntry.showOnEnemies) or (unitIsFriend and dbEntry.showOnFriends)) then
					if (dbEntry.auraType == AURA_TYPE_ANY or dbEntry.auraType == auraType) then
						local playerNpcMode = dbEntry.playerNpcMode;
						if (playerNpcMode == SHOW_ON_PLAYERS_AND_NPC or (playerNpcMode == SHOW_ON_PLAYERS and unitIsPlayer) or (playerNpcMode == SHOW_ON_NPC and not unitIsPlayer)) then
							if (dbEntry.checkSpellID == nil or dbEntry.checkSpellID[auraSpellID]) then
								return true;
							end
						end
					end
				end
			end
		end
		return false;
	end

	local function ProcAurasForNmplt_Additions(unitGUID, frame)
		if (unitGUID ~= nil) then
			local _, _, _, _, _, npcID = strsplit("-", unitGUID);
			if (db.Additions_ExplosiveOrbs and npcID == EXPLOSIVE_ORB_NPC_ID_AS_STRING) then
				local tSize = #AurasPerNameplate[frame];
				AurasPerNameplate[frame][tSize+1] = {
					["duration"] = 0,
					["expires"] = 0,
					["stacks"] = 1,
					["spellID"] = EXPLOSIVE_ORB_SPELL_ID,
					["type"] = AURA_TYPE_DEBUFF,
					["spellName"] = SpellNameByID[EXPLOSIVE_ORB_SPELL_ID],
					["dbEntry"] = {
						["showGlow"] = GLOW_TIME_INFINITE,
						["glowType"] = GLOW_TYPE_ACTIONBUTTON,
					},
				};
			end
			if (db.AffixSpiteful and npcID == addonTable.SPITEFUL_NPC_ID_STRING and SpitefulMobs[unitGUID]) then
				local tSize = #AurasPerNameplate[frame];
				local iconSize = math_max(db.DefaultIconSizeWidth, db.DefaultIconSizeHeight);
				AurasPerNameplate[frame][tSize+1] = {
					["duration"] = 0,
					["expires"] = 0,
					["stacks"] = 1,
					["spellID"] = addonTable.SPITEFUL_SPELL_ID,
					["type"] = AURA_TYPE_DEBUFF,
					["spellName"] = SpellNameByID[addonTable.SPITEFUL_SPELL_ID],
					["dbEntry"] = {
						["showGlow"] = GLOW_TIME_INFINITE,
						["glowType"] = GLOW_TYPE_ACTIONBUTTON,
						["iconSizeWidth"] = iconSize,
						["iconSizeHeight"] = iconSize,
					},
				};
			end
		end
	end

	local function ProcAurasForNmplt_DR(unitGUID, frame)
		if ((db.Additions_DRPvE or db.Additions_DRPvP) and unitGUID ~= nil and DRDataPerGUID[unitGUID] ~= nil) then
			local tSize = #AurasPerNameplate[frame];
			for category, categoryData in pairs(DRDataPerGUID[unitGUID]) do
				if (categoryData.drAppliedCount > 0) then
					AurasPerNameplate[frame][tSize+1] = {
						["duration"] = categoryData.lastTimeDRApplied == 0 and 0 or DRResetTime,
						["expires"] = categoryData.lastTimeDRApplied == 0 and 0 or (categoryData.lastTimeDRApplied + DRResetTime),
						["stacks"] = (1 - DRList:GetNextDR(categoryData.drAppliedCount, category))*100, --25 + 25*categoryData.drAppliedCount,
						["spellID"] = 222468, -- https://www.wowhead.com/spell=222468/immunepc
						["type"] = AURA_TYPE_BUFF,
						["spellName"] = SpellNameByID[222468], -- https://www.wowhead.com/spell=222468/immunepc
						["overrideTexture"] = addonTable.DR_TEXTURES[category],
					};
					tSize = tSize + 1;
				end
			end
		end
	end

	local function ProcAurasForNmplt_OnNewAura(auraType, auraName, auraStack, auraDispelType, auraDuration, auraExpires, auraCaster, auraIsStealable, auraSpellID, unitIsFriend, frame, unitIsPlayer)
		local foundInDB = false;
		local tSize = #AurasPerNameplate[frame];
		local cache = spellCache[auraName];
		if (cache ~= nil) then
			for _, dbEntry in pairs(cache) do
				if (ProcAurasForNmplt_Filter(auraType, auraCaster, auraSpellID, unitIsFriend, dbEntry, unitIsPlayer)) then
					AurasPerNameplate[frame][tSize+1] = {
						["duration"] = auraDuration,
						["expires"] = auraExpires,
						["stacks"] = auraStack,
						["spellID"] = auraSpellID,
						["type"] = auraType,
						["dispelType"] = auraDispelType,
						["spellName"] = auraName,
						["dbEntry"] = dbEntry,
					};
					tSize = tSize + 1;
					foundInDB = true;
				end
			end
		end
		if (not foundInDB) then
			if (db.AlwaysShowMyAuras and auraCaster == "player" and not db.AlwaysShowMyAurasBlacklist[auraName]) then
				AurasPerNameplate[frame][tSize+1] = {
					["duration"] = auraDuration,
					["expires"] = auraExpires,
					["stacks"] = auraStack,
					["spellID"] = auraSpellID,
					["type"] = auraType,
					["dispelType"] = auraDispelType,
					["spellName"] = auraName,
				};
				tSize = tSize + 1;
			end
			if (db.Additions_DispellableSpells and not unitIsFriend and auraIsStealable) then
				if (db.Additions_DispellableSpells_Blacklist[auraName] == nil) then
					AurasPerNameplate[frame][tSize+1] = {
						["duration"] = auraDuration,
						["expires"] = auraExpires,
						["stacks"] = auraStack,
						["spellID"] = auraSpellID,
						["type"] = auraType,
						["spellName"] = auraName,
						["dbEntry"] = {
							["iconSizeWidth"] = db.DispelIconSizeWidth,
							["iconSizeHeight"] = db.DispelIconSizeHeight,
							["showGlow"] = GLOW_TIME_INFINITE,
							["glowType"] = db.Additions_DispellableSpells_GlowType,
						},
					};
				end
			end
		end
	end

	function ProcessAurasForNameplate(frame, unitID)
		wipe(AurasPerNameplate[frame]);
		local unitIsFriend = (UnitReaction("player", unitID) or 0) > 4; -- 4 = neutral
		local unitIsPlayer = UnitIsPlayer(unitID);
		local unitGUID = UnitGUID(unitID);

		if (addonTable.IsNpcBlacklistEnabled and not unitIsPlayer and unitGUID ~= nil) then
			local npcName = addonTable.NpcNameByGUID[unitGUID];
			if (db.NpcBlacklist[npcName] == true) then
				UpdateNameplate(frame, unitGUID);
				return;
			end
		end

		if (db.EnabledZoneTypes[InstanceType] or (db.ShowAurasOnTargetEvenInDisabledAreas and unitGUID == TargetGUID)) then
			if ((LocalPlayerGUID ~= unitGUID or db.ShowAurasOnPlayerNameplate) and (db.ShowAboveFriendlyUnits or not unitIsFriend) and (not db.ShowOnlyOnTarget or unitGUID == TargetGUID)) then
				for i = 1, 40 do
					local buffName, _, buffStack, _, buffDuration, buffExpires, buffCaster, buffIsStealable, _, buffSpellID = UnitBuff(unitID, i);
					if (buffName ~= nil) then
						ProcAurasForNmplt_OnNewAura(AURA_TYPE_BUFF, buffName, buffStack, nil, buffDuration, buffExpires, buffCaster, buffIsStealable, buffSpellID, unitIsFriend, frame, unitIsPlayer);
					end
					local debuffName, _, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, _, _, debuffSpellID = UnitDebuff(unitID, i);
					if (debuffName ~= nil) then
						ProcAurasForNmplt_OnNewAura(AURA_TYPE_DEBUFF, debuffName, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, nil, debuffSpellID, unitIsFriend, frame, unitIsPlayer);
					end
					if (buffName == nil and debuffName == nil) then
						break;
					end
				end
				if (db.InterruptsEnabled) then
					local interrupt = InterruptsPerUnitGUID[unitGUID];
					if (interrupt ~= nil and interrupt.expires - GetTime() > 0) then
						local tSize = #AurasPerNameplate[frame];
						AurasPerNameplate[frame][tSize+1] = interrupt;
					end
				end
				ProcAurasForNmplt_Additions(unitGUID, frame);
				ProcAurasForNmplt_DR(unitGUID, frame);
			end
		end
		UpdateNameplate(frame, unitGUID);
	end

	local function UpdateNameplate_SetBorderTextureAndColor(icon, borderType, preciseType, borderSize, texturePath, color)
		if (icon.borderState ~= preciseType) then
			if (borderType == addonTable.BORDER_TYPE_BUILTIN) then
				icon.border:SetTexture(BORDER_TEXTURES[borderSize]);
			elseif (borderType == addonTable.BORDER_TYPE_CUSTOM) then
				icon.border:SetTexture(texturePath);
			end
			icon.border:SetVertexColor(color[1], color[2], color[3], color[4]);
			icon.border:Show();
			icon.borderState = preciseType;
		end
	end

	local function UpdateNameplate_SetBorder(icon, spellInfo)
		local dbEntry = spellInfo.dbEntry;
		if (dbEntry ~= nil and dbEntry.customBorderType ~= nil and dbEntry.customBorderType ~= addonTable.BORDER_TYPE_DISABLED) then
			local borderType = dbEntry.customBorderType;
			local borderColor = dbEntry.customBorderColor;
			local preciseType = string_format("%s%s%s%s%s%s",
				borderType,
				borderColor[1],
				borderColor[2],
				borderColor[3],
				borderColor[4],
				borderType == addonTable.BORDER_TYPE_BUILTIN and dbEntry.customBorderSize or (dbEntry.customBorderPath or "")
			);
			UpdateNameplate_SetBorderTextureAndColor(icon, borderType, preciseType, dbEntry.customBorderSize, dbEntry.customBorderPath, borderColor);
		elseif (db.ShowBuffBorders and spellInfo.type == AURA_TYPE_BUFF) then
			UpdateNameplate_SetBorderTextureAndColor(icon, db.BorderType, spellInfo.type, db.BorderThickness, db.BorderFilePath, db.BuffBordersColor);
		elseif (db.ShowDebuffBorders and spellInfo.type == AURA_TYPE_DEBUFF) then
			local preciseType = spellInfo.type .. (spellInfo.dispelType or "OTHER");
			local color = db["DebuffBorders" .. (spellInfo.dispelType or "Other") .. "Color"];
			UpdateNameplate_SetBorderTextureAndColor(icon, db.BorderType, preciseType, db.BorderThickness, db.BorderFilePath, color);
		else
			if (icon.borderState ~= nil) then
				icon.border:Hide();
				icon.borderState = nil;
			end
		end
	end

	local glowMethods = {
		[GLOW_TYPE_NONE] = function(icon) HideGlow(icon); end,
		[GLOW_TYPE_ACTIONBUTTON] = function(icon, iconResized)
			if (icon.glowType ~= GLOW_TYPE_ACTIONBUTTON) then
				HideGlow(icon);
				LBG_ShowOverlayGlow(icon, iconResized, false);
				icon.glowType = GLOW_TYPE_ACTIONBUTTON;
			end
		end,
		[GLOW_TYPE_AUTOUSE] = function(icon)
			if (icon.glowType ~= GLOW_TYPE_AUTOUSE) then
				HideGlow(icon);
				LibCustomGlow.AutoCastGlow_Start(icon, nil, nil, 0.2, 1.5);
				icon.glowType = GLOW_TYPE_AUTOUSE;
			end
		end,
		[GLOW_TYPE_PIXEL] = function(icon)
			if (icon.glowType ~= GLOW_TYPE_PIXEL) then
				HideGlow(icon);
				LibCustomGlow.PixelGlow_Start(icon, nil, nil, nil, nil, 2);
				icon.glowType = GLOW_TYPE_PIXEL;
			end
		end,
		[GLOW_TYPE_ACTIONBUTTON_DIM] = function(icon, iconResized)
			if (icon.glowType ~= GLOW_TYPE_ACTIONBUTTON_DIM) then
				HideGlow(icon);
				LBG_ShowOverlayGlow(icon, iconResized, true);
				icon.glowType = GLOW_TYPE_ACTIONBUTTON_DIM;
			end
		end,
	};

	local ICON_ANIMATION_DISPLAY_MODE_NONE, ICON_ANIMATION_DISPLAY_MODE_ALWAYS =
		addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE, addonTable.ICON_ANIMATION_DISPLAY_MODE_ALWAYS;
	local ICON_ANIMATION_TYPE_ALPHA = addonTable.ICON_ANIMATION_TYPE_ALPHA;
	local animationMethods = {
		[ICON_ANIMATION_TYPE_ALPHA] = function(icon)
			if (icon.animationType ~= ICON_ANIMATION_TYPE_ALPHA) then
				if (not icon.animationInitialized) then
					CreateIconAnimation(icon);
					icon.animationInitialized = true;
				end
				icon.alphaAnimationGroup:Play();
				icon.animationType = ICON_ANIMATION_TYPE_ALPHA;
			end
		end,
	};

	local function UpdateNameplate_SetAnimation(icon, remainingAuraTime, spellInfo)
		if (animationInfo[icon]) then
			animationInfo[icon]:Cancel(); -- // cancel delayed animation
			animationInfo[icon] = nil;
		end
		local dbEntry = spellInfo.dbEntry;
		if (dbEntry and dbEntry.animationDisplayMode ~= nil and dbEntry.animationDisplayMode ~= ICON_ANIMATION_DISPLAY_MODE_NONE) then
			if (dbEntry.animationDisplayMode == ICON_ANIMATION_DISPLAY_MODE_ALWAYS) then -- okay, we should show animation and user wants to see it without time limit
				animationMethods[dbEntry.animationType](icon);
			elseif (spellInfo.duration == 0) then -- // okay, user has limited time for animation, but aura is permanent
				HideAnimation(icon);
			elseif (not dbEntry.useRelativeAnimationTimer and remainingAuraTime < dbEntry.animationTimer) then -- // okay, user has limited time for animation, aura is not permanent and aura's remaining time is less than user's limit
				animationMethods[dbEntry.animationType](icon);
			elseif (dbEntry.useRelativeAnimationTimer and (remainingAuraTime*100/spellInfo.duration) < dbEntry.animationTimer) then -- // okay, user has limited time for animation, aura is not permanent and aura's remaining time is less than user's limit
				animationMethods[dbEntry.animationType](icon);
			else -- // okay, user has limited time for animation, aura is not permanent and aura's remaining time is bigger than user's limit
				HideAnimation(icon); -- // hide animation
				if (not dbEntry.useRelativeAnimationTimer) then
					animationInfo[icon] = CTimerNewTimer(remainingAuraTime - dbEntry.animationTimer, function() animationMethods[dbEntry.animationType](icon); end); -- // queue delayed animation
				else
					animationInfo[icon] = CTimerNewTimer(
						remainingAuraTime - dbEntry.animationTimer/100*spellInfo.duration,
						function() animationMethods[dbEntry.animationType](icon); end); -- // queue delayed animation
				end
			end
		else
			HideAnimation(icon); -- // this aura doesn't require animation
		end
	end

	local function UpdateNameplate_SetGlow(icon, iconResized, remainingAuraTime, spellInfo)
		if (glowInfo[icon]) then
			glowInfo[icon]:Cancel(); -- // cancel delayed glow
			glowInfo[icon] = nil;
		end
		local dbEntry = spellInfo.dbEntry;
		if (dbEntry and dbEntry.showGlow ~= nil and dbEntry.glowType ~= nil) then
			if (dbEntry.showGlow == GLOW_TIME_INFINITE) then -- okay, we should show glow and user wants to see it without time limit
				glowMethods[dbEntry.glowType](icon, iconResized);
			elseif (spellInfo.duration == 0) then -- // okay, user has limited time for glow, but aura is permanent
				HideGlow(icon);
			elseif (not dbEntry.useRelativeGlowTimer and remainingAuraTime < dbEntry.showGlow) then -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is less than user's limit
				glowMethods[dbEntry.glowType](icon, iconResized);
			elseif (dbEntry.useRelativeGlowTimer and (remainingAuraTime*100/spellInfo.duration) < dbEntry.showGlow) then -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is less than user's limit
				glowMethods[dbEntry.glowType](icon, iconResized);
			else -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is bigger than user's limit
				HideGlow(icon); -- // hide glow
				if (not dbEntry.useRelativeGlowTimer) then
					glowInfo[icon] = CTimerNewTimer(remainingAuraTime - dbEntry.showGlow, function() glowMethods[dbEntry.glowType](icon, iconResized); end); -- // queue delayed glow
				else
					glowInfo[icon] = CTimerNewTimer(
						remainingAuraTime - dbEntry.showGlow/100*spellInfo.duration,
						function() glowMethods[dbEntry.glowType](icon, iconResized); end); -- // queue delayed glow
				end
			end
		else
			HideGlow(icon); -- // this aura doesn't require glow
		end
	end

	local function UpdateNameplate_SetIconSize(dbEntry, icon, unitGUID)
		local spellWidth, spellHeight;
		if (dbEntry ~= nil) then
			spellWidth = dbEntry.iconSizeWidth or db.DefaultIconSizeWidth;
			spellHeight = dbEntry.iconSizeHeight or db.DefaultIconSizeHeight;
		else
			spellWidth, spellHeight = db.DefaultIconSizeWidth, db.DefaultIconSizeHeight;
		end
		if (unitGUID == TargetGUID) then
			spellWidth = spellWidth * db.IconScaleTarget;
			spellHeight = spellHeight * db.IconScaleTarget;
		end
		local iconResized = false;
		if (spellWidth ~= icon.sizeWidth or spellHeight ~= icon.sizeHeight) then
			icon.sizeWidth = spellWidth;
			icon.sizeHeight = spellHeight;
			icon:SetSize(spellWidth, spellHeight);
			local sizeMin = math_min(spellWidth, spellHeight);
			if (db.TimerTextUseRelativeScale) then
				icon.cooldownText:SetFont(SML:Fetch("font", db.Font), math_ceil((sizeMin - sizeMin / 2) * db.FontScale), "OUTLINE");
			else
				icon.cooldownText:SetFont(SML:Fetch("font", db.Font), db.TimerTextSize, "OUTLINE");
			end
			icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((sizeMin / 4) * db.StacksFontScale), "OUTLINE");
			iconResized = true;
		end
		return spellWidth, spellHeight, iconResized;
	end

	local function UpdateNameplate_SetAspectRatio(icon, spellWidth, spellHeight)
		local xOffset, yOffset = db.IconZoom, db.IconZoom;
		if (db.KeepAspectRatio) then
			local aspectRatio = spellWidth / spellHeight;
			local freeSpace = 0.5 - db.IconZoom;
			if (aspectRatio > 1) then
				yOffset = db.IconZoom + (freeSpace - freeSpace*(1/aspectRatio));
			elseif (aspectRatio < 1) then
				xOffset = db.IconZoom + (freeSpace - freeSpace*aspectRatio);
			end
		end
		if (icon.textureXOffset ~= xOffset or icon.textureYOffset ~= yOffset) then
			icon.texture:SetTexCoord(xOffset, 1-xOffset, yOffset, 1-yOffset);
			icon.textureXOffset = xOffset;
			icon.textureYOffset = yOffset;
		end
	end

	function UpdateNameplate(frame, unitGUID)
		local counter = 1;
		local maxIconWidth = 0;
		local maxIconHeight = 0;
		local totalWidth = 0;
		local totalHeight = 0;
		if (AurasPerNameplate[frame]) then
			local currentTime = GetTime();
			if (db.SortMode ~= AURA_SORT_MODE_NONE) then table_sort(AurasPerNameplate[frame], AuraSortFunctions[db.SortMode]); end
			for _, spellInfo in pairs(AurasPerNameplate[frame]) do
				local last = spellInfo.expires - currentTime;
				if (last > 0 or spellInfo.duration == 0) then
					if (counter > frame.NAurasIconsCount) then
						AllocateIcon(frame);
					end
					local icon = frame.NAurasIcons[counter];
					if (icon.spellID ~= spellInfo.spellID) then
						if (spellInfo.overrideTexture ~= nil) then
							icon.texture:SetTexture(spellInfo.overrideTexture);
						else
							icon.texture:SetTexture(SpellTextureByID[spellInfo.spellID]);
						end
						icon.spellID = spellInfo.spellID;
					end
					icon:SetCooldown(last, spellInfo);
					-- // border
					UpdateNameplate_SetBorder(icon, spellInfo);
					-- // icon size
					local spellWidth, spellHeight, iconResized = UpdateNameplate_SetIconSize(spellInfo.dbEntry, icon, unitGUID);
					UpdateNameplate_SetAspectRatio(icon, spellWidth, spellHeight);
					maxIconWidth = math_max(maxIconWidth, spellWidth);
					maxIconHeight = math_max(maxIconHeight, spellHeight);
					totalWidth = totalWidth + icon.sizeWidth + db.IconSpacing;
					totalHeight = totalHeight + icon.sizeHeight + db.IconSpacing;
					-- // glow
					UpdateNameplate_SetGlow(icon, iconResized, last, spellInfo);
					UpdateNameplate_SetAnimation(icon, last, spellInfo);
					if (not icon.shown) then
						ShowCDIcon(icon);
					end
					counter = counter + 1;
					if (db.MaxAuras ~= nil and db.MaxAuras < counter) then break; end
				end
			end
		end
		if (frame.NAurasFrame ~= nil) then
			totalWidth = totalWidth - db.IconSpacing; -- // because we don't need last spacing
			totalHeight = totalHeight - db.IconSpacing; -- // because we don't need last spacing
			SetFrameSize(frame.NAurasFrame, maxIconWidth, maxIconHeight, totalWidth, totalHeight);
		end
		for k = counter, frame.NAurasIconsCount do
			local icon = frame.NAurasIcons[k];
			if (icon.shown) then
				HideCDIcon(icon);
			end
		end
		-- // hide/show standart buff frame
		if (frame.UnitFrame ~= nil and frame.UnitFrame.BuffFrame ~= nil) then
			if (unitGUID ~= LocalPlayerGUID) then
				if (db.HideBlizzardFrames) then
					frame.UnitFrame.BuffFrame:SetAlpha(0);
				else
					frame.UnitFrame.BuffFrame:SetAlpha(1);
				end
			else
				if (db.HidePlayerBlizzardFrame) then
					frame.UnitFrame.BuffFrame:SetAlpha(0);
				else
					frame.UnitFrame.BuffFrame:SetAlpha(1);
				end
			end
		end
	end

	local function OnUpdate()
		if (db.ShowCooldownText) then
			local currentTime = GetTime();
			for frame in pairs(NameplatesVisible) do
				local counter = 1;
				if (AurasPerNameplate[frame]) then
					for _, spellInfo in pairs(AurasPerNameplate[frame]) do
						local last = spellInfo.expires - currentTime;
						if (last > 0 or spellInfo.duration == 0) then
							-- // getting reference to icon
							local icon = frame.NAurasIcons[counter];
							-- // setting text
							if (icon ~= nil) then icon:SetCooldown(last, spellInfo); end
							counter = counter + 1;
						end
					end
				end
			end
		end
		CTimerAfter(0.1, OnUpdate);
	end
	CTimerAfter(0.1, OnUpdate);

end

--------------------------------------------------------------------------------------------------
----- Frame for events
--------------------------------------------------------------------------------------------------
do
	local InterruptSpells = addonTable.Interrupts;
	local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER;
	local drTimers = { };

	EventFrame = CreateFrame("Frame");
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	EventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); end);
	addonTable.EventFrame = EventFrame;

	-- we do polling because 'GetInstanceInfo' works unstable
	local function UpdateZoneType()
		local newInstanceType;
		local inInstance, instanceType = IsInInstance();
		if (not inInstance) then
			newInstanceType = instanceType;
		elseif (inInstance and instanceType == "none") then
			newInstanceType = addonTable.INSTANCE_TYPE_UNKNOWN;
		elseif (inInstance and instanceType == "pvp") then
			local maxInstanceGroup = select(5, GetInstanceInfo());
			if (maxInstanceGroup == 40) then
				newInstanceType = addonTable.INSTANCE_TYPE_PVP_BG_40PPL;
			else
				newInstanceType = instanceType;
			end
		else
			newInstanceType = instanceType;
		end
		if (newInstanceType ~= InstanceType) then
			InstanceType = newInstanceType;
			addonTable.UpdateAllNameplates(false);
		end
		CTimerAfter(2, UpdateZoneType);
	end
	CTimerAfter(2, UpdateZoneType);

	function EventFrame.PLAYER_ENTERING_WORLD()
		if (addonTable.OnStartup) then
			addonTable.OnStartup();
		end
		for nameplate in pairs(AurasPerNameplate) do
			wipe(AurasPerNameplate[nameplate]);
		end
		wipe(SpitefulMobs);
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
		if (db.InterruptsEnabled) then
			local interrupt = InterruptsPerUnitGUID[UnitGUID(unitID)];
			if (interrupt ~= nil) then
				local remainingTime = interrupt.expires - GetTime();
				if (remainingTime > 0) then
					CTimerAfter(remainingTime, function() ProcessAurasForNameplate(nameplate, unitID); end);
				end
			end
		end
		SetAlphaScaleForNameplate(nameplate);
		if (nameplate.NAurasFrame ~= nil) then
			nameplate.NAurasFrame:Show();
		end
		EventFrame.UNIT_THREAT_LIST_UPDATE(unitID);
	end

	function EventFrame.NAME_PLATE_UNIT_REMOVED(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = nil;
		if (AurasPerNameplate[nameplate] ~= nil) then
			wipe(AurasPerNameplate[nameplate]);
		end
		if (nameplate.NAurasFrame ~= nil) then
			nameplate.NAurasFrame:Hide();
		end
	end

	function EventFrame.UNIT_AURA(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		if (nameplate ~= nil and AurasPerNameplate[nameplate] ~= nil) then
			ProcessAurasForNameplate(nameplate, unitID);
		end
	end

	function EventFrame.UNIT_THREAT_LIST_UPDATE(unitID)
		if (db.AffixSpiteful) then
			local unitGUID = UnitGUID(unitID);
			if (unitGUID ~= nil) then
				local _, _, _, _, _, npcID = strsplit("-", unitGUID);
				if (not SpitefulMobs[unitGUID] and npcID == addonTable.SPITEFUL_NPC_ID_STRING) then
					local _, _, threatPct = UnitDetailedThreatSituation("player", unitID);
					if (threatPct == 100) then
						if (type(db.AffixSpitefulSound) == "number") then
							PlaySound(db.AffixSpitefulSound, "Master");
						else
							PlaySoundFile(SML:Fetch(SML.MediaType.SOUND, db.AffixSpitefulSound), "Master");
						end
						SpitefulMobs[unitGUID] = true;
						EventFrame.UNIT_AURA(unitID);
					end
				end
			end
		end
	end

	local function ProcessInterrupts(event, destGUID, destFlags, spellID, spellName)
		if (db.InterruptsEnabled) then
			-- SPELL_INTERRUPT is not invoked for some channeled spells - implement later
			if (event == "SPELL_INTERRUPT") then
				local spellDuration = InterruptSpells[spellID];
				if (spellDuration ~= nil) then
					if (not db.InterruptsShowOnlyOnPlayers or bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0) then
						InterruptsPerUnitGUID[destGUID] = {
							["duration"] = spellDuration,
							["expires"] = GetTime() + spellDuration,
							["stacks"] = 1,
							["spellID"] = spellID,
							["type"] = AURA_TYPE_DEBUFF,
							["spellName"] = spellName,
							["dbEntry"] = {
								["enabledState"] =				CONST_SPELL_MODE_DISABLED,
								["auraType"] =					AURA_TYPE_DEBUFF,
								["iconSizeWidth"] = 			db.InterruptsIconSizeWidth,
								["iconSizeHeight"] = 			db.InterruptsIconSizeHeight,
								["showGlow"] =					GLOW_TIME_INFINITE,
								["glowType"] =					db.InterruptsGlowType,
							},
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
			end
		end
	end

	local function ProcessDR(event, spellID, destGUID, destFlags, spellAuraType)
		if ((db.Additions_DRPvP or db.Additions_DRPvE) and spellAuraType == "DEBUFF") then
			local category = DRList:GetCategoryBySpellID(spellID);
			if (category and category ~= "knockback") then
				local isPlayer = bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0;
				if ((isPlayer and db.Additions_DRPvP) or (not isPlayer and category == "stun" and db.Additions_DRPvE)) then
					if (DRDataPerGUID[destGUID] == nil) then DRDataPerGUID[destGUID] = { }; end
					if (DRDataPerGUID[destGUID][category] == nil) then
						DRDataPerGUID[destGUID][category] = {
							["drAppliedCount"] = 0,
							["lastTimeDRApplied"] = 0,
						};
					end
					local data = DRDataPerGUID[destGUID][category];
					if (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") then
						if (drTimers[data] ~= nil) then
							drTimers[data]:Cancel();
							drTimers[data] = nil;
						end
						data.drAppliedCount = data.drAppliedCount + 1;
						data.lastTimeDRApplied = 0;
						for frame, unitID in pairs(NameplatesVisible) do
							if (destGUID == UnitGUID(unitID)) then
								ProcessAurasForNameplate(frame, unitID);
								break;
							end
						end
					elseif (event == "SPELL_AURA_REMOVED") then
						data.lastTimeDRApplied = GetTime();
						drTimers[data] = CTimerNewTimer(DRResetTime, function() DRDataPerGUID[destGUID][category] = nil; end);
						for frame, unitID in pairs(NameplatesVisible) do
							if (destGUID == UnitGUID(unitID)) then
								ProcessAurasForNameplate(frame, unitID);
								CTimerAfter(DRResetTime, function() ProcessAurasForNameplate(frame, unitID); end);
								break;
							end
						end
					end
				end
			end
		end
	end

	function EventFrame.COMBAT_LOG_EVENT_UNFILTERED()
		local _, event, _, _, _, _, _,destGUID,_,destFlags,_, spellID, spellName, _, spellAuraType = CombatLogGetCurrentEventInfo();
		ProcessInterrupts(event, destGUID, destFlags, spellID, spellName);
		ProcessDR(event, spellID, destGUID, destFlags, spellAuraType);
	end

	function EventFrame.PLAYER_TARGET_CHANGED()
		TargetGUID = UnitGUID("target");
		for nameplate in pairs(NameplatesVisible) do
			SetAlphaScaleForNameplate(nameplate);
		end
		addonTable.UpdateAllNameplates(false);
		-- if (db.ShowOnlyOnTarget) then
		-- 	addonTable.UpdateAllNameplates(false);
		-- end
	end

end

--------------------------------------------------------------------------------------------------
----- Test mode
--------------------------------------------------------------------------------------------------
do
	local TestModeIsActive = false;
	local intervalBetweenRefreshes = 13;
	local ticker = nil;
	local spellsLastTimeUpdated = GetTime() - intervalBetweenRefreshes;
	local testTable;

	local function GetSpells()
		if (GetTime() - spellsLastTimeUpdated >= intervalBetweenRefreshes) then
			spellsLastTimeUpdated = GetTime();
		end
		if (testTable == nil) then
			testTable = {
				{
					["duration"] = intervalBetweenRefreshes-3,
					["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes-3,
					["stacks"] = 2,
					["spellID"] = 139,
					["type"] = AURA_TYPE_BUFF,
					["spellName"] = SpellNameByID[139],
					["dbEntry"] = {
						["iconSizeWidth"] = 45,
						["iconSizeHeight"] = 45,
					},
				},
				{
					["duration"] = intervalBetweenRefreshes*20,
					["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*20,
					["stacks"] = 1,
					["spellID"] = 215336,
					["type"] = AURA_TYPE_BUFF,
					["spellName"] = SpellNameByID[215336],
					["dbEntry"] = {
						["iconSizeWidth"] = 30,
						["iconSizeHeight"] = 30,
					},
				},
				{
					["duration"] = intervalBetweenRefreshes*2,
					["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*2,
					["stacks"] = 3,
					["spellID"] = 188389,
					["type"] = AURA_TYPE_DEBUFF,
					["dispelType"] = "Magic",
					["spellName"] = SpellNameByID[188389],
					["dbEntry"] = {
						["iconSizeWidth"] = 30,
						["iconSizeHeight"] = 30,
					},
				},
				{
					["duration"] = 0,
					["expires"] = 0,
					["stacks"] = 10,
					["spellID"] = 100407,
					["type"] = AURA_TYPE_DEBUFF,
					["dispelType"] = "Curse",
					["spellName"] = SpellNameByID[100407],
					["dbEntry"] = {
						["iconSizeWidth"] = db.DefaultIconSizeWidth,
						["iconSizeHeight"] = db.DefaultIconSizeHeight,
						["showGlow"] = GLOW_TIME_INFINITE,
						["glowType"] = db.Additions_DispellableSpells_GlowType,
					},
				},
			};
		else
			testTable[1]["duration"] = intervalBetweenRefreshes-3;
			testTable[1]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes-3;

			testTable[2]["duration"] = intervalBetweenRefreshes*20;
			testTable[2]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*20;

			testTable[3]["duration"] = intervalBetweenRefreshes*2;
			testTable[3]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*2;

			testTable[4]["dbEntry"]["iconSizeWidth"] = db.DefaultIconSizeWidth;
			testTable[4]["dbEntry"]["iconSizeHeight"] = db.DefaultIconSizeHeight;
			testTable[4]["dbEntry"]["glowType"] = db.Additions_DispellableSpells_GlowType;
		end
		if (addonTable.GetCurrentlyEditingSpell ~= nil) then
			local dbEntry, spellID = addonTable.GetCurrentlyEditingSpell();
			if (dbEntry ~= nil and spellID ~= nil) then
				if (testTable[5] == nil) then
					testTable[5] = {
						["duration"] = intervalBetweenRefreshes,
						["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes,
						["stacks"] = 5,
						["spellID"] = spellID,
						["type"] = (dbEntry.auraType == AURA_TYPE_DEBUFF) and AURA_TYPE_DEBUFF or AURA_TYPE_BUFF,
						["dispelType"] = "Magic",
						["spellName"] = SpellNameByID[spellID],
						["dbEntry"] = dbEntry,
					};
				else
					testTable[5]["duration"] = intervalBetweenRefreshes;
					testTable[5]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes;
					testTable[5]["spellID"] = spellID;
					testTable[5]["type"] = (dbEntry.auraType == AURA_TYPE_DEBUFF) and AURA_TYPE_DEBUFF or AURA_TYPE_BUFF;
					testTable[5]["spellName"] = SpellNameByID[spellID];
					testTable[5]["dbEntry"] = dbEntry;
				end
			else
				testTable[5] = nil;
			end
		else
			testTable[5] = nil;
		end
		return testTable;
	end

	local function Ticker_OnTick()
		for nameplate, auras in pairs(AurasPerNameplate) do
			local unitID = NameplatesVisible[nameplate];
			if (unitID ~= nil) then
				wipe(auras);
				for _, spellInfo in pairs(GetSpells()) do
					auras[#auras+1] = spellInfo;
				end
				UpdateNameplate(nameplate, UnitGUID(unitID));
			end
		end
	end

	addonTable.SwitchTestMode = function()
		if (TestModeIsActive) then
			ticker:Cancel();
			EventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); end);
			addonTable.UpdateAllNameplates();
		else
			EventFrame:SetScript("OnEvent", function(self, event, ...) self[event](...); Ticker_OnTick(); end);
			Ticker_OnTick();
			ticker = C_Timer.NewTicker(0.1, Ticker_OnTick);
		end
		TestModeIsActive = not TestModeIsActive;
	end

end
