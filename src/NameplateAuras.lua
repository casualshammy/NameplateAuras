-- luacheck: no max line length
-- luacheck: globals NAuras_LibButtonGlow strfind
-- luacheck: globals UnitReaction UnitIsFriend IsInGroup LE_PARTY_CATEGORY_INSTANCE IsInRaid
-- luacheck: globals UnitIsPlayer strsplit CombatLogGetCurrentEventInfo
-- luacheck: globals UIParent COMBATLOG_OBJECT_TYPE_PLAYER
-- luacheck: globals GetNumGroupMembers IsPartyLFG GetNumSubgroupMembers IsPartyLFG UnitDetailedThreatSituation PlaySound
-- luacheck: globals IsInInstance bit loadstring setfenv GetInstanceInfo GameTooltip UnitName
-- luacheck: globals PersonalFriendlyBuffFrame UnitIsUnit tinsert AuraUtil

local _, addonTable = ...;

local buildTimestamp = "DEVELOPER COPY";
--[===[@non-debug@
buildTimestamp = "@project-version@";
--@end-non-debug@]===]
local DEBUG = buildTimestamp == "DEVELOPER COPY"; -- luacheck: ignore DEBUG

local LBG_ShowOverlayGlow, LBG_HideOverlayGlow = NAuras_LibButtonGlow.ShowOverlayGlow, NAuras_LibButtonGlow.HideOverlayGlow;
local SML = LibStub("LibSharedMedia-3.0");
local AceComm = LibStub("AceComm-3.0");
local LibCustomGlow = LibStub("LibCustomGlow-1.0");
local LRD = LibStub("LibRedDropdown-1.0");
local DRList = LibStub("DRList-1.0");
local MSQ = LibStub("Masque", true);

-- // upvalues
local 	_G, pairs, string_find,string_format, 	GetTime, math_ceil, math_floor, wipe, C_NamePlate_GetNamePlateForUnit, UnitIsPlayer,
			UnitReaction, UnitGUID,  table_sort, CTimerAfter,	bit_band, CTimerNewTimer,   strsplit, CombatLogGetCurrentEventInfo, math_max, math_min =
		_G, pairs, 			strfind, 	format,			GetTime, ceil,		floor,		wipe, C_NamePlate.GetNamePlateForUnit, UnitIsPlayer,
			UnitReaction, UnitGUID,  table.sort, C_Timer.After,	bit.band, C_Timer.NewTimer, strsplit, CombatLogGetCurrentEventInfo, max,	  min;
local GetNumGroupMembers, IsPartyLFG, GetNumSubgroupMembers, PlaySound, PlaySoundFile = GetNumGroupMembers, IsPartyLFG, GetNumSubgroupMembers, PlaySound, PlaySoundFile;
local UnitDetailedThreatSituation, GetInstanceInfo, C_TooltipInfo = UnitDetailedThreatSituation, GetInstanceInfo, C_TooltipInfo;
local C_TooltipInfo_GetUnitBuffByAuraInstanceID = C_TooltipInfo.GetUnitBuffByAuraInstanceID;
local C_TooltipInfo_GetUnitDebuffByAuraInstanceID = C_TooltipInfo.GetUnitDebuffByAuraInstanceID;
local UnitIsUnit, AuraUtil_ForEachAura = UnitIsUnit, AuraUtil.ForEachAura;
local C_UnitAuras_GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID;
local table_insert, table_remove = table.insert, table.remove;
local GetSpellTexture = C_Spell.GetSpellTexture;

-- // variables
local AurasPerNameplate, InterruptsPerUnitGUID, Nameplates, NameplatesVisible, NameplatesVisibleGuid, DRResetTime, InstanceType, BuffFrameHookedNameplates;
local EventFrame, db, aceDB, LocalPlayerGUID, ProcessAurasForNameplate, UpdateNameplate, SetAlphaScaleForNameplate, DRDataPerGUID, TargetGUID;
local SpitefulMobs, PlayerAurasPerGuid;
do
	AurasPerNameplate 						= { };
	InterruptsPerUnitGUID					= { };
	Nameplates, NameplatesVisible 			= { }, { };
	NameplatesVisibleGuid					= { };
	addonTable.Nameplates					= Nameplates;
	addonTable.AllAuraIconFrames			= { };
	DRDataPerGUID							= { };
	DRResetTime								= DRList:GetResetTime();
	SpitefulMobs							= { };
	InstanceType							= addonTable.INSTANCE_TYPE_NONE;
	BuffFrameHookedNameplates				= { };
	PlayerAurasPerGuid 						= { };
end

-- // consts
local CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_MYAURAS, AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY, AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE,
	AURA_SORT_MODE_AURATYPE_EXPIRE,
	GLOW_TIME_INFINITE, EXPLOSIVE_ORB_SPELL_ID, VERY_LONG_COOLDOWN_DURATION, BORDER_TEXTURES;
do
	CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_MYAURAS = addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_MYAURAS;
	AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY = addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY;
	AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE, AURA_SORT_MODE_AURATYPE_EXPIRE =
		addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIRETIME, addonTable.AURA_SORT_MODE_ICONSIZE, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE;
	GLOW_TIME_INFINITE = addonTable.GLOW_TIME_INFINITE; -- // 30 days
	EXPLOSIVE_ORB_SPELL_ID = addonTable.EXPLOSIVE_ORB_SPELL_ID;
	VERY_LONG_COOLDOWN_DURATION = addonTable.VERY_LONG_COOLDOWN_DURATION; -- // 30 days
	BORDER_TEXTURES = addonTable.BORDER_TEXTURES;
end
local ATTACH_TYPE_NAMEPLATE, ATTACH_TYPE_HEALTHBAR, ATTACH_TYPE_TPTP = addonTable.ATTACH_TYPE_NAMEPLATE, addonTable.ATTACH_TYPE_HEALTHBAR, addonTable.ATTACH_TYPE_TPTP;

-- // utilities
local Print, SpellTextureByID, SpellNameByID = addonTable.Print, addonTable.SpellTextureByID, addonTable.SpellNameByID;

local UpdateUnitAurasFull, UpdateUnitAurasIncremental;
do
	local p_updateAurasCurrentUnit = nil;

	local function UpdateUnitAuras_HandleAura(_unitAuraInfo)
		if (_unitAuraInfo == nil) then
			return;
		end

		PlayerAurasPerGuid[p_updateAurasCurrentUnit][_unitAuraInfo.auraInstanceID] = _unitAuraInfo;
	end

	function UpdateUnitAurasFull(_unitId, _unitGuid)
		if (PlayerAurasPerGuid[_unitGuid] == nil) then
			PlayerAurasPerGuid[_unitGuid] = { };
		else
			wipe(PlayerAurasPerGuid[_unitGuid]);
		end

		p_updateAurasCurrentUnit = _unitGuid;

		AuraUtil_ForEachAura(_unitId, "HELPFUL", nil, UpdateUnitAuras_HandleAura, true);
		AuraUtil_ForEachAura(_unitId, "HARMFUL", nil, UpdateUnitAuras_HandleAura, true);

		p_updateAurasCurrentUnit = nil;
	end

	function UpdateUnitAurasIncremental(_unitId, _unitGuid, _unitAuraUpdateInfo)
		if (_unitAuraUpdateInfo.addedAuras ~= nil) then
			for _, aura in pairs(_unitAuraUpdateInfo.addedAuras) do
				PlayerAurasPerGuid[_unitGuid][aura.auraInstanceID] = aura;
			end
		end

		if (_unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil) then
			for _, auraInstanceID in pairs(_unitAuraUpdateInfo.updatedAuraInstanceIDs) do
				PlayerAurasPerGuid[_unitGuid][auraInstanceID] = C_UnitAuras_GetAuraDataByAuraInstanceID(_unitId, auraInstanceID);
			end
		end

		if (_unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil) then
			for _, auraInstanceID in pairs(_unitAuraUpdateInfo.removedAuraInstanceIDs) do
				PlayerAurasPerGuid[_unitGuid][auraInstanceID] = nil;
			end
		end
	end
end

--------------------------------------------------------------------------------------------------
----- db, on start routines...
--------------------------------------------------------------------------------------------------
do

	addonTable.GetIconGroupDefaultOptions = function(_iconGroupName)
		return {
			IconGroupName = _iconGroupName or "IG " .. date("%Y-%m-%d-%H-%M-%S"),
			ShowAurasOnPlayerNameplate = false,
			IconXOffset = 0,
			IconYOffset = 50,
			Font = "NAuras_TeenBold",
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
			IconSpacing = 1,
			IconAnchor = 1,
			AlwaysShowMyAuras = false,
			BorderThickness = 2,
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
			Additions_DispellableSpells = false,
			Additions_Dispel_InstanceTypes = {
				[addonTable.INSTANCE_TYPE_NONE] =					true,
				[addonTable.INSTANCE_TYPE_UNKNOWN] = 			true,
				[addonTable.INSTANCE_TYPE_PVP] = 					true,
				[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = true,
				[addonTable.INSTANCE_TYPE_ARENA] = 				true,
				[addonTable.INSTANCE_TYPE_PARTY] = 				true,
				[addonTable.INSTANCE_TYPE_RAID] = 				true,
				[addonTable.INSTANCE_TYPE_SCENARIO] =			true,
			},
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
			AlwaysShowMyAurasBlacklist = {},
			NpcBlacklist = {},
			TimerTextUseRelativeColor = false,
			TimerTextColorZeroPercent = {1, 0.1, 0.1, 1},
			TimerTextColorHundredPercent = {0.1, 1, 0.1, 1},
			KeepAspectRatio = true,
			UseDefaultAuraTooltip = false,
			MasqueEnabled = false,
			NameplateIsParent = false,
			ShowCooldownSwipeEdge = true,
			FriendlyUnitsAurasEnabledZoneTypes = {
				[addonTable.INSTANCE_TYPE_NONE] =					true,
				[addonTable.INSTANCE_TYPE_UNKNOWN] = 			true,
				[addonTable.INSTANCE_TYPE_PVP] = 					true,
				[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = true,
				[addonTable.INSTANCE_TYPE_ARENA] = 				true,
				[addonTable.INSTANCE_TYPE_PARTY] = 				true,
				[addonTable.INSTANCE_TYPE_RAID] = 				true,
				[addonTable.INSTANCE_TYPE_SCENARIO] =			true,
			},
			EnemyUnitsAurasEnabledZoneTypes = {
				[addonTable.INSTANCE_TYPE_NONE] =					true,
				[addonTable.INSTANCE_TYPE_UNKNOWN] = 			true,
				[addonTable.INSTANCE_TYPE_PVP] = 					true,
				[addonTable.INSTANCE_TYPE_PVP_BG_40PPL] = true,
				[addonTable.INSTANCE_TYPE_ARENA] = 				true,
				[addonTable.INSTANCE_TYPE_PARTY] = 				true,
				[addonTable.INSTANCE_TYPE_RAID] = 				true,
				[addonTable.INSTANCE_TYPE_SCENARIO] =			true,
			},
			ShowAurasOnEnemyTargetEvenInDisabledAreas = false,
			ShowAurasOnAlliedTargetEvenInDisabledAreas = false,
			AttachType = ATTACH_TYPE_NAMEPLATE,
		};
	end

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

	local function InitializeDB()
		-- // set defaults
		local aceDBDefaults = {
			profile = {
				DBVersion = 0,
				DefaultSpellsLastSetImported = 0,
				CustomSpells2 = { },
				HideBlizzardFrames = true,
				HidePlayerBlizzardFrame = "undefined", -- // don't change: we convert db with that
				IconGroups = { },
			},
		};
		addonTable.AceDBDefaults = addonTable.deepcopy(aceDBDefaults);

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
		local msg = strsplit(" ", _msg, 2);
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
		elseif (msg == "test") then
			addonTable.SwitchTestMode();
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
		addonTable.RebuildAuraSortFunctions();
		addonTable.RebuildSpellCache();
		-- // starting listening for events
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
		EventFrame:RegisterEvent("UNIT_AURA");
		EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
		EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		EventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE");
		-- // adding slash command
		SLASH_NAMEPLATEAURAS1 = '/nauras';
		SlashCmdList["NAMEPLATEAURAS"] = OnChatCommand;
		AceComm:RegisterComm("NameplateAuras", OnAddonMessageReceived);
		addonTable.OnStartup = nil;
	end

	function ReloadDB()
		db = aceDB.profile;
		addonTable.db = aceDB.profile;
		-- // convert values
		addonTable.MigrateDB();
		-- // import default spells
		addonTable.ImportNewSpells();
		-- set texture for interrupt spells
		for spellID in pairs(addonTable.Interrupts) do
			SpellTextureByID[spellID] = db.IconGroups[1].InterruptsUseSharedIconTexture and "Interface\\AddOns\\NameplateAuras\\media\\warrior_disruptingshout.tga" or GetSpellTexture(spellID); -- // icon of Interrupting Shout
		end
		-- //
		addonTable.GuiOnProfileChanged();
		-- //
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
	local SHOW_ON_PLAYERS, SHOW_ON_NPC = addonTable.SHOW_ON_PLAYERS, addonTable.SHOW_ON_NPC;
	local glowInfo = { };
	local animationInfo = { };
	local defaultCustomSortFunction = function(aura1, aura2) return aura1.spellName < aura2.spellName; end;
	local AuraSortFunctions;
	AuraSortFunctions = {
		[AURA_SORT_MODE_EXPIRETIME] = {},
		[AURA_SORT_MODE_ICONSIZE] = {},
		[AURA_SORT_MODE_AURATYPE_EXPIRE] = {},
		[AURA_SORT_MODE_CUSTOM] = {},
	};

	local function GetAuraTextFromUnitAura(_unit, _auraData)
		local data;
		if (_auraData.isHarmful) then
			data = C_TooltipInfo_GetUnitDebuffByAuraInstanceID(_unit, _auraData.auraInstanceID);
		else
			data = C_TooltipInfo_GetUnitBuffByAuraInstanceID(_unit, _auraData.auraInstanceID);
		end

		if (data == nil) then
			return nil;
		end

		local tooltip = data.lines[2].leftText;

		return tooltip;
	end

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

	local function CompileCustomSortFunctionForIconGroup(_iconGroupIndex, _iconGroup)
		local sort_time = AuraSortFunctions[AURA_SORT_MODE_EXPIRETIME][_iconGroupIndex];
		local sort_size = AuraSortFunctions[AURA_SORT_MODE_ICONSIZE][_iconGroupIndex];
		local exec_env = setmetatable({}, {
			__index = function(_, k)
				if (k == "sort_time") then
					return sort_time;
				elseif (k == "sort_size") then
					return sort_size;
				else
					return _G[k];
				end
			end
		});

		local script = _iconGroup.CustomSortMethod;
		script = "return " .. script;
		local func, errorMsg = loadstring(script);
		if (not func) then
			addonTable.Print("Your custom sorting function contains error: \n" .. errorMsg);
			return defaultCustomSortFunction;
		else
			setfenv(func, exec_env);
			local success, sortFunc = pcall(assert(func));
			if (success) then
				return sortFunc;
			end
		end
	end

	function addonTable.RebuildAuraSortFunctions()
		wipe(AuraSortFunctions[AURA_SORT_MODE_EXPIRETIME]);
		wipe(AuraSortFunctions[AURA_SORT_MODE_ICONSIZE]);
		wipe(AuraSortFunctions[AURA_SORT_MODE_AURATYPE_EXPIRE]);
		wipe(AuraSortFunctions[AURA_SORT_MODE_CUSTOM]);

		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			AuraSortFunctions[AURA_SORT_MODE_EXPIRETIME][iconGroupIndex] = function(item1, item2)
				local expires1, expires2 = item1.expires, item2.expires;
				if (expires1 == 0) then expires1 = VERY_LONG_COOLDOWN_DURATION; end
				if (expires2 == 0) then expires2 = VERY_LONG_COOLDOWN_DURATION; end
				return expires1 < expires2;
			end
			AuraSortFunctions[AURA_SORT_MODE_ICONSIZE][iconGroupIndex] = function(item1, item2)
				local shouldOverrideSize1 = item1.dbEntry ~= nil and item1.dbEntry.overrideSize;
				local shouldOverrideSize2 = item2.dbEntry ~= nil and item2.dbEntry.overrideSize;
				local size1 = (shouldOverrideSize1 and math_min(item1.dbEntry.iconSizeWidth, item1.dbEntry.iconSizeHeight) or math_min(iconGroup.DefaultIconSizeHeight, iconGroup.DefaultIconSizeWidth));
				local size2 = (shouldOverrideSize2 and math_min(item2.dbEntry.iconSizeWidth, item2.dbEntry.iconSizeHeight) or math_min(iconGroup.DefaultIconSizeHeight, iconGroup.DefaultIconSizeWidth));
				return size1 < size2;
			end
			AuraSortFunctions[AURA_SORT_MODE_AURATYPE_EXPIRE][iconGroupIndex] = function(item1, item2)
				if (item1.type ~= item2.type) then
					return (item1.type == AURA_TYPE_DEBUFF) and true or false;
				end
				return AuraSortFunctions[AURA_SORT_MODE_EXPIRETIME][iconGroupIndex](item1, item2);
			end
			AuraSortFunctions[AURA_SORT_MODE_CUSTOM][iconGroupIndex] = CompileCustomSortFunctionForIconGroup(iconGroupIndex, iconGroup);
		end
	end

	local iconTooltip = LRD.CreateTooltip();
	local function AllocateIcon_SetAuraTooltip(icon, _iconGroup)
		icon:SetScript("OnEnter", nil);
		icon:SetScript("OnLeave", nil);
		if (_iconGroup.ShowAuraTooltip) then
			icon:SetScript("OnEnter", function(self)
				if (_iconGroup.UseDefaultAuraTooltip) then
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
				if (_iconGroup.UseDefaultAuraTooltip) then
					GameTooltip:Hide();
				else
					iconTooltip:Hide();
				end
			end);
		end
	end
	addonTable.AllocateIcon_SetAuraTooltip = AllocateIcon_SetAuraTooltip;

	local function SetFrameSize(frame, maxIconWidth, maxIconHeight, totalWidth, totalHeight, _iconGroup)
		if (_iconGroup.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_RIGHT or _iconGroup.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_LEFT) then
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

	function SetAlphaScaleForNameplate(nameplate, _iconGroupIndex, _iconGroup)
		if (nameplate ~= nil and nameplate.NAurasFrames ~= nil) then
			local frameLevel = nameplate:GetFrameLevel();
			local frame = nameplate.NAurasFrames[_iconGroupIndex];
			if (frame == nil) then
				return;
			end

			frame:SetFrameLevel((frameLevel or 1)*10);

			local unitID = NameplatesVisible[nameplate];
			if (unitID ~= nil) then
				local unitGUID = UnitGUID(unitID);
				if (unitGUID == TargetGUID or (TargetGUID == nil and _iconGroup.UseTargetAlphaIfNotTargetSelected)) then
					frame:SetAlpha(_iconGroup.IconAlphaTarget);
				else
					frame:SetAlpha(_iconGroup.IconAlpha);
				end
				if (unitGUID == TargetGUID) then
					frame:SetFrameStrata(_iconGroup.TargetStrata);
				else
					frame:SetFrameStrata(_iconGroup.NonTargetStrata);
				end
			end
		end
	end

	local function AllocateIcon_SetIconPlace(frame, icon, iconIndex, _iconGroupIndex, _iconGroup)
		icon:ClearAllPoints();
		local index = iconIndex == nil and (frame.NAurasIconsCount[_iconGroupIndex] or 0) or (iconIndex-1)
		if (index == 0) then
			local anchor = iconAligns0[_iconGroup.IconAnchor][_iconGroup.IconGrowDirection];
			icon:SetPoint(anchor, frame.NAurasFrames[_iconGroupIndex], anchor, 0, 0);
		else
			local anchor0 = iconAligns0[_iconGroup.IconAnchor][_iconGroup.IconGrowDirection];
			local anchor1 = iconAlignsOther[_iconGroup.IconAnchor][_iconGroup.IconGrowDirection];
			if (_iconGroup.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_RIGHT) then
				icon:SetPoint(anchor0, frame.NAurasIcons[_iconGroupIndex][index], anchor1, _iconGroup.IconSpacing, 0);
			elseif (_iconGroup.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_LEFT) then
				icon:SetPoint(anchor0, frame.NAurasIcons[_iconGroupIndex][index], anchor1, -_iconGroup.IconSpacing, 0);
			elseif (_iconGroup.IconGrowDirection == addonTable.ICON_GROW_DIRECTION_UP) then
				icon:SetPoint(anchor0, frame.NAurasIcons[_iconGroupIndex][index], anchor1, 0, _iconGroup.IconSpacing);
			else -- // down
				icon:SetPoint(anchor0, frame.NAurasIcons[_iconGroupIndex][index], anchor1, 0, -_iconGroup.IconSpacing);
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
	local function IconSetCooldown(icon, remainingTime, spellInfo, _iconGroup)
		if (_iconGroup.ShowCooldownText) then
			-- cooldown text
			local text;
			if (remainingTime > 3600 or spellInfo.duration == 0) then
				text = "";
			elseif (remainingTime >= 60) then
				text = math_floor(remainingTime/60).."m";
			elseif (remainingTime >= _iconGroup.MinTimeToShowTenthsOfSeconds) then
				text = string_format("%d", remainingTime);
			else
				text = string_format("%.1f", remainingTime);
			end
			if (icon.text ~= text) then
				icon.cooldownText:SetText(text);
				icon.text = text;
				if (spellInfo.duration == 0 or not _iconGroup.ShowCooldownAnimation) then
					icon.cooldownText:SetParent(icon);
				else
					icon.cooldownText:SetParent(icon.cooldownFrame);
				end
			end

			-- cooldown text color
			if (_iconGroup.TimerTextUseRelativeColor and spellInfo.duration ~= 0) then
				local percent = math_floor(remainingTime * 10 / spellInfo.duration);
				if (icon.textColor ~= percent) then
					local color = CalculateRelativeColor(_iconGroup.TimerTextColorZeroPercent, _iconGroup.TimerTextColorHundredPercent, percent / 10);
					icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
					icon.textColor = percent;
				end
			else
				if (remainingTime >= 60 or spellInfo.duration == 0) then
					if (icon.textColor ~= colortype_long) then
						local color = _iconGroup.TimerTextLongerColor;
						icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
						icon.textColor = colortype_long;
					end
				elseif (remainingTime >= 5) then
					if (icon.textColor ~= colortype_medium) then
						local color = _iconGroup.TimerTextUnderMinuteColor;
						icon.cooldownText:SetTextColor(color[1], color[2], color[3], color[4]);
						icon.textColor = colortype_medium;
					end
				else
					if (icon.textColor ~= colortype_short) then
						local color = _iconGroup.TimerTextSoonToExpireColor;
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
		local stacks = _iconGroup.ShowStacks and spellInfo.stacks or 1;
		if (icon.stackcount ~= stacks) then
			if (stacks > 1) then
				icon.stacks:SetText(stacks);
				if (spellInfo.duration == 0 or not _iconGroup.ShowCooldownAnimation) then
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
		if (_iconGroup.ShowCooldownAnimation) then
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
		local animation = icon.alphaAnimationGroup:CreateAnimation("Alpha");
		animation:SetFromAlpha(1);
		animation:SetToAlpha(0);
		animation:SetDuration(0.5);
		animation:SetOrder(1);
	end

	local function GetNameplateAddonFrame(_nameplate, _iconGroup)
		local attachType = _iconGroup.AttachType;

		if (attachType == ATTACH_TYPE_NAMEPLATE) then
			return _nameplate;
		end

		if (attachType == ATTACH_TYPE_HEALTHBAR) then
			if (_nameplate.UnitFrame == nil) then
				if (DEBUG) then
					addonTable.Print(string_format("Nameplate %s doesn't have 'UnitFrame'", _nameplate:GetName()));
				end
			elseif (_nameplate.UnitFrame.HealthBarsContainer == nil) then
				if (DEBUG) then
					addonTable.Print(string_format("Nameplate %s doesn't have 'HealthBarsContainer'", _nameplate:GetName()));
				end
			else
				return _nameplate.UnitFrame.HealthBarsContainer;
			end
		end

		if (attachType == ATTACH_TYPE_TPTP) then
			local frame = _nameplate.TPFrame;
			if (frame ~= nil) then
				return frame;
			end
		end

		return _nameplate;
	end
	addonTable.GetNameplateAddonFrame = GetNameplateAddonFrame;

	local function AllocateIcon(frame, _iconGroupIndex)
		if (not frame.NAurasFrames) then
			frame.NAurasFrames = { };
		end

		local iconGroup = db.IconGroups[_iconGroupIndex];

		if (frame.NAurasFrames[_iconGroupIndex] == nil) then
			local anchorFrame = GetNameplateAddonFrame(frame, iconGroup);
			frame.NAurasFrames[_iconGroupIndex] = CreateFrame("frame", nil, iconGroup.NameplateIsParent == true and anchorFrame or UIParent);
			frame.NAurasFrames[_iconGroupIndex]:SetWidth(iconGroup.DefaultIconSizeWidth);
			frame.NAurasFrames[_iconGroupIndex]:SetHeight(iconGroup.DefaultIconSizeHeight);
			frame.NAurasFrames[_iconGroupIndex]:SetPoint(iconGroup.FrameAnchor, anchorFrame, iconGroup.FrameAnchorToNameplate, iconGroup.IconXOffset, iconGroup.IconYOffset);
			SetAlphaScaleForNameplate(frame, _iconGroupIndex, iconGroup);
			frame.NAurasFrames[_iconGroupIndex]:Show();
		end
		local icon = CreateFrame("Frame", nil, frame.NAurasFrames[_iconGroupIndex]);
		AllocateIcon_SetAuraTooltip(icon, iconGroup);
		AllocateIcon_SetIconPlace(frame, icon, nil, _iconGroupIndex, iconGroup);
		icon:SetSize(iconGroup.DefaultIconSizeWidth, iconGroup.DefaultIconSizeHeight);
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
		icon.cooldownFrame:SetDrawEdge(iconGroup.ShowCooldownSwipeEdge);
		icon.SetCooldown = IconSetCooldown;
		icon.sizeWidth = iconGroup.DefaultIconSizeWidth;
		icon.sizeHeight = iconGroup.DefaultIconSizeHeight;
		icon:Hide();
		icon.cooldownText:SetTextColor(0.7, 1, 0);
		icon.cooldownText:SetShadowColor(0, 0, 0, 1);
		icon.cooldownText:SetShadowOffset(1, -1);
		icon.cooldownText:SetPoint(iconGroup.TimerTextAnchor, icon, iconGroup.TimerTextAnchorIcon, iconGroup.TimerTextXOffset, iconGroup.TimerTextYOffset);
		if (iconGroup.TimerTextUseRelativeScale) then
			local sizeMin = math_min(iconGroup.DefaultIconSizeWidth, iconGroup.DefaultIconSizeHeight);
			icon.cooldownText:SetFont(SML:Fetch("font", iconGroup.Font), math_ceil((sizeMin - sizeMin / 2) * iconGroup.FontScale), "OUTLINE");
		else
			icon.cooldownText:SetFont(SML:Fetch("font", iconGroup.Font), iconGroup.TimerTextSize, "OUTLINE");
		end
		if (iconGroup.BorderType == addonTable.BORDER_TYPE_BUILTIN) then
			icon.border:SetTexture(BORDER_TEXTURES[iconGroup.BorderThickness]);
		elseif (iconGroup.BorderType == addonTable.BORDER_TYPE_CUSTOM) then
			icon.border:SetTexture(iconGroup.BorderFilePath);
		end
		icon.border:SetVertexColor(1, 0.35, 0);
		icon.border:SetAllPoints(icon);
		icon.border:Hide();
		local color = iconGroup.StacksTextColor;
		icon.stacks:SetTextColor(color[1] or 0, color[2] or 0, color[3] or 0, color[4]);
		icon.stacks:SetPoint(iconGroup.StacksTextAnchor, icon, iconGroup.StacksTextAnchorIcon, iconGroup.StacksTextXOffset, iconGroup.StacksTextYOffset);
		icon.stacks:SetFont(SML:Fetch("font", iconGroup.StacksFont), math_ceil((math_min(iconGroup.DefaultIconSizeWidth, iconGroup.DefaultIconSizeHeight) / 4) * iconGroup.StacksFontScale), "OUTLINE");
		icon.stackcount = 0;

		if (iconGroup.MasqueEnabled and MSQ ~= nil) then
			icon.msqGroup = MSQ:Group("NameplateAuras", "Icon group: " .. iconGroup.IconGroupName);
			icon.msqGroup:AddButton(icon, {Icon = icon.texture, Cooldown = icon.cooldownFrame, IconBorder = icon.border });
		end

		addonTable.AllAuraIconFrames[#addonTable.AllAuraIconFrames+1] = icon;
		frame.NAurasIconsCount[_iconGroupIndex] = (frame.NAurasIconsCount[_iconGroupIndex] or 0) + 1;
		frame.NAurasFrames[_iconGroupIndex]:SetWidth(iconGroup.DefaultIconSizeWidth * frame.NAurasIconsCount[_iconGroupIndex]);

		if (frame.NAurasIcons[_iconGroupIndex] == nil) then
			frame.NAurasIcons[_iconGroupIndex] = { };
		end
		frame.NAurasIcons[_iconGroupIndex][#frame.NAurasIcons[_iconGroupIndex]+1] = icon;
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
				for frameIndex, frame in pairs(nameplate.NAurasFrames) do
					local iconGroup = db.IconGroups[frameIndex];
					if (iconGroup ~= nil) then
						local anchorFrame = GetNameplateAddonFrame(nameplate, iconGroup);
						frame:ClearAllPoints();
						frame:SetPoint(iconGroup.FrameAnchor, anchorFrame, iconGroup.FrameAnchorToNameplate, iconGroup.IconXOffset, iconGroup.IconYOffset);
						frame:SetParent(iconGroup.NameplateIsParent == true and anchorFrame or UIParent);
						for iconIndex, icon in pairs(nameplate.NAurasIcons[frameIndex]) do
							if (icon.shown) then
								local sizeMin = math_min(iconGroup.DefaultIconSizeWidth, iconGroup.DefaultIconSizeHeight);
								if (iconGroup.TimerTextUseRelativeScale) then
									icon.cooldownText:SetFont(SML:Fetch("font", iconGroup.Font), math_ceil((sizeMin - sizeMin / 2) * iconGroup.FontScale), "OUTLINE");
								else
									icon.cooldownText:SetFont(SML:Fetch("font", iconGroup.Font), iconGroup.TimerTextSize, "OUTLINE");
								end
								icon.stacks:SetFont(SML:Fetch("font", iconGroup.StacksFont), math_ceil((sizeMin / 4) * iconGroup.StacksFontScale), "OUTLINE");
							end
							AllocateIcon_SetIconPlace(nameplate, icon, iconIndex, frameIndex, iconGroup);
							icon.cooldownFrame:SetDrawEdge(iconGroup.ShowCooldownSwipeEdge);
							icon.cooldownText:ClearAllPoints();
							icon.cooldownText:SetPoint(iconGroup.TimerTextAnchor, icon, iconGroup.TimerTextAnchorIcon, iconGroup.TimerTextXOffset, iconGroup.TimerTextYOffset);
							icon.textColor = nil;
							icon.stacks:ClearAllPoints();
							icon.stacks:SetPoint(iconGroup.StacksTextAnchor, icon, iconGroup.StacksTextAnchorIcon, iconGroup.StacksTextXOffset, iconGroup.StacksTextYOffset);
							local color = iconGroup.StacksTextColor;
							icon.stacks:SetTextColor(color[1], color[2], color[3], color[4]);
							if (iconGroup.BorderType == addonTable.BORDER_TYPE_BUILTIN) then
								icon.border:SetTexture(BORDER_TEXTURES[iconGroup.BorderThickness]);
							elseif (iconGroup.BorderType == addonTable.BORDER_TYPE_CUSTOM) then
								icon.border:SetTexture(iconGroup.BorderFilePath);
							end
							HideCDIcon(icon);
						end
						SetAlphaScaleForNameplate(nameplate, frameIndex, iconGroup);
					else
						frame:Hide();
					end
				end
			end
		end
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrames and nameplate.UnitFrame ~= nil and nameplate.UnitFrame.unit ~= nil) then
				local unitId = NameplatesVisible[nameplate];
				local unitGuid = NameplatesVisibleGuid[nameplate];
				if (unitId ~= nil and unitGuid ~= nil) then
					UpdateUnitAurasFull(unitId, unitGuid);
				end

				ProcessAurasForNameplate(nameplate, nameplate.UnitFrame.unit);
			end
		end
	end
	addonTable.UpdateAllNameplates = UpdateAllNameplates;

	local function ProcAurasForNmplt_Filter(auraType, _auraData, unitIsFriend, dbEntry, unitIsPlayer, unitId, _iconGroupIndex)
		if (dbEntry == nil) then
			return false;
		end

		if (not dbEntry.iconGroups[_iconGroupIndex]) then
			return false;
		end

		if (dbEntry.enabledState == CONST_SPELL_MODE_DISABLED or (dbEntry.enabledState == CONST_SPELL_MODE_MYAURAS and _auraData.sourceUnit ~= "player" and _auraData.sourceUnit ~= "pet")) then
			return false;
		end

		if ((unitIsFriend and not dbEntry.showOnFriends) or (not unitIsFriend and not dbEntry.showOnEnemies)) then
			return false;
		end

		if (dbEntry.auraType ~= AURA_TYPE_ANY and dbEntry.auraType ~= auraType) then
			return false;
		end

		local playerNpcMode = dbEntry.playerNpcMode;
		if ((playerNpcMode == SHOW_ON_NPC and unitIsPlayer) or (playerNpcMode == SHOW_ON_PLAYERS and not unitIsPlayer)) then
			return false;
		end

		if (dbEntry.checkSpellID ~= nil and not dbEntry.checkSpellID[_auraData.spellId]) then
			return false;
		end

		if (dbEntry.spellTooltip ~= nil) then
			local tooltip = GetAuraTextFromUnitAura(unitId, _auraData);
			if (not string_find(tooltip, dbEntry.spellTooltip, 1, true)) then
				return false;
			end
		end

		return true;
	end

	local function ProcAurasForNmplt_Additions(unitGUID, frame, _iconGroupsToUpdate)
		if (unitGUID ~= nil) then
			for iconGroupIndex, iconGroup in pairs(_iconGroupsToUpdate) do
				local _, _, _, _, _, npcID = strsplit("-", unitGUID);
				if (iconGroup.Additions_ExplosiveOrbs and npcID == EXPLOSIVE_ORB_NPC_ID_AS_STRING) then
					local tSize = #AurasPerNameplate[frame][iconGroupIndex];
					AurasPerNameplate[frame][iconGroupIndex][tSize+1] = {
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
				if (iconGroup.AffixSpiteful and npcID == addonTable.SPITEFUL_NPC_ID_STRING and SpitefulMobs[unitGUID]) then
					local tSize = #AurasPerNameplate[frame][iconGroupIndex];
					local iconSize = math_max(iconGroup.DefaultIconSizeWidth, iconGroup.DefaultIconSizeHeight);
					AurasPerNameplate[frame][iconGroupIndex][tSize+1] = {
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
							["overrideSize"] = true,
						},
					};
				end
			end
		end
	end

	local function ProcAurasForNmplt_DR(unitGUID, frame, _iconGroupsToUpdate)
		for iconGroupIndex, iconGroup in pairs(_iconGroupsToUpdate) do
			if ((iconGroup.Additions_DRPvE or iconGroup.Additions_DRPvP) and unitGUID ~= nil and DRDataPerGUID[iconGroupIndex] ~= nil and DRDataPerGUID[iconGroupIndex][unitGUID] ~= nil) then
				local tSize = #AurasPerNameplate[frame][iconGroupIndex];
				for category, categoryData in pairs(DRDataPerGUID[iconGroupIndex][unitGUID]) do
					if (categoryData.drAppliedCount > 0) then
						AurasPerNameplate[frame][iconGroupIndex][tSize+1] = {
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
	end

	local function ProcAurasForNmplt_Interrupts(unitGUID, frame, _iconGroupsToUpdate)
		local now = GetTime();
		for iconGroupIndex, iconGroup in pairs(_iconGroupsToUpdate) do
			if (iconGroup.InterruptsEnabled and InterruptsPerUnitGUID[iconGroupIndex] ~= nil) then
				local interrupt = InterruptsPerUnitGUID[iconGroupIndex][unitGUID];
				if (interrupt ~= nil and interrupt.expires - now > 0) then
					local tSize = #AurasPerNameplate[frame][iconGroupIndex];
					AurasPerNameplate[frame][iconGroupIndex][tSize+1] = interrupt;
				end
			end
		end
	end

	local function ProcAurasForNmplt_OnNewAuraEx(_auraData, unitIsFriend, frame, unitIsPlayer, unitId, _iconGroupsToUpdate)
		local auraType = _auraData.isHarmful and AURA_TYPE_DEBUFF or AURA_TYPE_BUFF;
		local auraName = _auraData.name;
		for iconGroupIndex, iconGroup in pairs(_iconGroupsToUpdate) do
			local foundInDB = false;
			local tSize = #AurasPerNameplate[frame][iconGroupIndex];
			local cache = spellCache[auraName];
			if (cache ~= nil) then
				for _, dbEntry in pairs(cache) do
					if (ProcAurasForNmplt_Filter(auraType, _auraData, unitIsFriend, dbEntry, unitIsPlayer, unitId, iconGroupIndex)) then
						AurasPerNameplate[frame][iconGroupIndex][tSize+1] = {
							["duration"] = _auraData.duration,
							["expires"] = _auraData.expirationTime,
							["stacks"] = _auraData.applications,
							["spellID"] = _auraData.spellId,
							["type"] = auraType,
							["dispelType"] = _auraData.dispelName,
							["spellName"] = auraName,
							["dbEntry"] = dbEntry,
						};
						tSize = tSize + 1;
						foundInDB = true;
					end
				end
			end
			if (not foundInDB) then
				if (iconGroup.AlwaysShowMyAuras and _auraData.sourceUnit == "player" and not iconGroup.AlwaysShowMyAurasBlacklist[auraName]) then
					AurasPerNameplate[frame][iconGroupIndex][tSize+1] = {
						["duration"] = _auraData.duration,
						["expires"] = _auraData.expirationTime,
						["stacks"] = _auraData.applications,
						["spellID"] = _auraData.spellId,
						["type"] = auraType,
						["dispelType"] = _auraData.dispelName,
						["spellName"] = auraName,
					};
					tSize = tSize + 1;
				end
				if (iconGroup.Additions_DispellableSpells and not unitIsFriend and _auraData.isStealable and iconGroup.Additions_Dispel_InstanceTypes[InstanceType]) then
					if (iconGroup.Additions_DispellableSpells_Blacklist[auraName] == nil) then
						AurasPerNameplate[frame][iconGroupIndex][tSize+1] = {
							["duration"] = _auraData.duration,
							["expires"] = _auraData.expirationTime,
							["stacks"] = _auraData.applications,
							["spellID"] = _auraData.spellId,
							["type"] = auraType,
							["spellName"] = auraName,
							["dbEntry"] = {
								["iconSizeWidth"] = iconGroup.DispelIconSizeWidth,
								["iconSizeHeight"] = iconGroup.DispelIconSizeHeight,
								["overrideSize"] = true,
								["showGlow"] = GLOW_TIME_INFINITE,
								["glowType"] = iconGroup.Additions_DispellableSpells_GlowType,
							},
						};
					end
				end
			end
		end
	end

	local function ProcAurasForNmplt_Merge(_frame, _iconGroupsToUpdate)
		for iconGroupIndex in pairs(_iconGroupsToUpdate) do
			local dataPerSpellId = nil;
			for ndx, aura in pairs(AurasPerNameplate[_frame][iconGroupIndex]) do
				if (aura.dbEntry ~= nil and aura.dbEntry.consolidate) then
					if (dataPerSpellId == nil) then
						dataPerSpellId = {};
					end

					local data = dataPerSpellId[aura.spellID]
					if (data == nil) then
						data = {
							["stacks"] = 0,
							["longestAuraIndex"] = 0,
							["longestAuraData"] = nil,
							["indexesToRemove"] = {}
						};
						dataPerSpellId[aura.spellID] = data;
					end

					data.stacks = data.stacks + math_max(1, aura.stacks);
					if (data.longestAuraData == nil) then
						data.longestAuraData = aura;
						data.longestAuraIndex = ndx;
					elseif (data.longestAuraData.expires < aura.expires) then
						table_insert(data.indexesToRemove, data.longestAuraIndex);
						data.longestAuraData = aura;
						data.longestAuraIndex = ndx;
					else
						table_insert(data.indexesToRemove, ndx);
					end
				end
			end

			if (dataPerSpellId ~= nil) then
				for _, data in pairs(dataPerSpellId) do
					if (#data.indexesToRemove > 0) then
						AurasPerNameplate[_frame][iconGroupIndex][data.longestAuraIndex].stacks = data.stacks;
						for _, ndx in pairs(data.indexesToRemove) do
							table_remove(AurasPerNameplate[_frame][iconGroupIndex], ndx);
						end
					end
				end
			end
		end
	end

	function ProcessAurasForNameplate(frame, unitID)
		for iconGroupIndex in pairs(AurasPerNameplate[frame]) do
			wipe(AurasPerNameplate[frame][iconGroupIndex]);
		end

		local unitIsFriend = (UnitReaction("player", unitID) or 0) > 4; -- 4 = neutral
		local unitIsPlayer = UnitIsPlayer(unitID);
		local unitGUID = UnitGUID(unitID);

		local iconGroupsToUpdate = {};
		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			if (LocalPlayerGUID ~= unitGUID or iconGroup.ShowAurasOnPlayerNameplate) then
				if (not iconGroup.ShowOnlyOnTarget or unitGUID == TargetGUID) then
					if (unitIsFriend or iconGroup.EnemyUnitsAurasEnabledZoneTypes[InstanceType] or (iconGroup.ShowAurasOnEnemyTargetEvenInDisabledAreas and unitGUID == TargetGUID)) then
						if (not unitIsFriend or iconGroup.FriendlyUnitsAurasEnabledZoneTypes[InstanceType] or (iconGroup.ShowAurasOnAlliedTargetEvenInDisabledAreas and unitGUID == TargetGUID)) then
							local add = true;
							if (not unitIsPlayer and unitGUID ~= nil) then
								local unitName = addonTable.GetOrAddUnitNameByGuid(unitGUID, unitID);
								if (unitName ~= nil and iconGroup.NpcBlacklist[unitName] == true) then
									add = false;
								end
							end
							if (add) then
								iconGroupsToUpdate[iconGroupIndex] = iconGroup;
								if (AurasPerNameplate[frame][iconGroupIndex] == nil) then
									AurasPerNameplate[frame][iconGroupIndex] = {};
								end
							end
						end
					end
				end
			end
		end

		if (#iconGroupsToUpdate > 0) then
			local auras = PlayerAurasPerGuid[unitGUID];
			if (auras ~= nil) then
				for _, auraData in pairs(auras) do
					ProcAurasForNmplt_OnNewAuraEx(auraData, unitIsFriend, frame, unitIsPlayer, unitID, iconGroupsToUpdate);
				end
			end

			ProcAurasForNmplt_Merge(frame, iconGroupsToUpdate);

			ProcAurasForNmplt_Interrupts(unitGUID, frame, iconGroupsToUpdate);
			ProcAurasForNmplt_Additions(unitGUID, frame, iconGroupsToUpdate);
			ProcAurasForNmplt_DR(unitGUID, frame, iconGroupsToUpdate);
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

	local function UpdateNameplate_SetBorder(icon, spellInfo, _iconGroup)
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
		elseif (_iconGroup.ShowBuffBorders and spellInfo.type == AURA_TYPE_BUFF) then
			UpdateNameplate_SetBorderTextureAndColor(icon, _iconGroup.BorderType, spellInfo.type, _iconGroup.BorderThickness, _iconGroup.BorderFilePath, _iconGroup.BuffBordersColor);
		elseif (_iconGroup.ShowDebuffBorders and spellInfo.type == AURA_TYPE_DEBUFF) then
			local preciseType = spellInfo.type .. (spellInfo.dispelType or "OTHER");
			local color = _iconGroup["DebuffBorders" .. (spellInfo.dispelType or "Other") .. "Color"];
			UpdateNameplate_SetBorderTextureAndColor(icon, _iconGroup.BorderType, preciseType, _iconGroup.BorderThickness, _iconGroup.BorderFilePath, color);
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

	local function UpdateNameplate_SetIconSize(dbEntry, icon, unitGUID, _iconGroup)
		local spellWidth, spellHeight;
		if (dbEntry ~= nil and dbEntry.overrideSize) then
			spellWidth = dbEntry.iconSizeWidth or _iconGroup.DefaultIconSizeWidth;
			spellHeight = dbEntry.iconSizeHeight or _iconGroup.DefaultIconSizeHeight;
		else
			spellWidth, spellHeight = _iconGroup.DefaultIconSizeWidth, _iconGroup.DefaultIconSizeHeight;
		end
		if (unitGUID == TargetGUID) then
			spellWidth = spellWidth * _iconGroup.IconScaleTarget;
			spellHeight = spellHeight * _iconGroup.IconScaleTarget;
		end
		local iconResized = false;
		if (spellWidth ~= icon.sizeWidth or spellHeight ~= icon.sizeHeight) then
			icon.sizeWidth = spellWidth;
			icon.sizeHeight = spellHeight;
			icon:SetSize(spellWidth, spellHeight);
			local sizeMin = math_min(spellWidth, spellHeight);
			if (_iconGroup.TimerTextUseRelativeScale) then
				icon.cooldownText:SetFont(SML:Fetch("font", _iconGroup.Font), math_ceil((sizeMin - sizeMin / 2) * _iconGroup.FontScale), "OUTLINE");
			else
				icon.cooldownText:SetFont(SML:Fetch("font", _iconGroup.Font), _iconGroup.TimerTextSize, "OUTLINE");
			end
			icon.stacks:SetFont(SML:Fetch("font", _iconGroup.StacksFont), math_ceil((sizeMin / 4) * _iconGroup.StacksFontScale), "OUTLINE");
			iconResized = true;
			if (icon.msqGroup ~= nil) then
				icon.msqGroup:ReSkin(icon);
			end
		end
		return spellWidth, spellHeight, iconResized;
	end

	local function UpdateNameplate_SetAspectRatio(icon, spellWidth, spellHeight, _iconGroup, _iconResized)
		local xOffset, yOffset = _iconGroup.IconZoom, _iconGroup.IconZoom;
		if (_iconGroup.KeepAspectRatio) then
			local aspectRatio = spellWidth / spellHeight;
			local freeSpace = 0.5 - _iconGroup.IconZoom;
			if (aspectRatio > 1) then
				yOffset = _iconGroup.IconZoom + (freeSpace - freeSpace*(1/aspectRatio));
			elseif (aspectRatio < 1) then
				xOffset = _iconGroup.IconZoom + (freeSpace - freeSpace*aspectRatio);
			end
		end
		if (_iconResized or icon.textureXOffset ~= xOffset or icon.textureYOffset ~= yOffset) then
			icon.texture:SetTexCoord(xOffset, 1-xOffset, yOffset, 1-yOffset);
			icon.textureXOffset = xOffset;
			icon.textureYOffset = yOffset;
		end
	end

	function UpdateNameplate(frame, unitGUID)
		local currentTime = GetTime();
		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			local counter = 1;
			local maxIconWidth = 0;
			local maxIconHeight = 0;
			local totalWidth = 0;
			local totalHeight = 0;
			if (AurasPerNameplate[frame][iconGroupIndex]) then
				if (iconGroup.SortMode ~= AURA_SORT_MODE_NONE) then
					table_sort(AurasPerNameplate[frame][iconGroupIndex], AuraSortFunctions[iconGroup.SortMode][iconGroupIndex]);
				end
				for _, spellInfo in pairs(AurasPerNameplate[frame][iconGroupIndex]) do
					local last = spellInfo.expires - currentTime;
					if (last > 0 or spellInfo.duration == 0) then
						if (counter > (frame.NAurasIconsCount[iconGroupIndex] or 0)) then
							AllocateIcon(frame, iconGroupIndex);
						end
						local icon = frame.NAurasIcons[iconGroupIndex][counter];
						if (icon.spellID ~= spellInfo.spellID) then
							if (spellInfo.overrideTexture ~= nil) then
								icon.texture:SetTexture(spellInfo.overrideTexture);
							else
								icon.texture:SetTexture(SpellTextureByID[spellInfo.spellID]);
							end
							icon.spellID = spellInfo.spellID;
						end
						icon:SetCooldown(last, spellInfo, iconGroup);
						-- // border
						UpdateNameplate_SetBorder(icon, spellInfo, iconGroup);
						-- // icon size
						local spellWidth, spellHeight, iconResized = UpdateNameplate_SetIconSize(spellInfo.dbEntry, icon, unitGUID, iconGroup);
						UpdateNameplate_SetAspectRatio(icon, spellWidth, spellHeight, iconGroup, iconResized);
						maxIconWidth = math_max(maxIconWidth, spellWidth);
						maxIconHeight = math_max(maxIconHeight, spellHeight);
						totalWidth = totalWidth + icon.sizeWidth + iconGroup.IconSpacing;
						totalHeight = totalHeight + icon.sizeHeight + iconGroup.IconSpacing;
						-- // glow
						UpdateNameplate_SetGlow(icon, iconResized, last, spellInfo);
						UpdateNameplate_SetAnimation(icon, last, spellInfo);
						if (not icon.shown) then
							ShowCDIcon(icon);
						end
						counter = counter + 1;
					end
				end
			end
			local nAurasFrame = frame.NAurasFrames[iconGroupIndex];
			if (nAurasFrame ~= nil) then
				totalWidth = totalWidth - iconGroup.IconSpacing; -- // because we don't need last spacing
				totalHeight = totalHeight - iconGroup.IconSpacing; -- // because we don't need last spacing
				SetFrameSize(nAurasFrame, maxIconWidth, maxIconHeight, totalWidth, totalHeight, iconGroup);
			end

			local totalIconsCount = frame.NAurasIconsCount[iconGroupIndex];
			if (totalIconsCount ~= nil) then
				for k = counter, totalIconsCount do
					local icon = frame.NAurasIcons[iconGroupIndex][k];
					if (icon.shown) then
						HideCDIcon(icon);
					end
				end
			end
		end
	end

	local function OnUpdate()
		local currentTime = GetTime();
		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			if (iconGroup.ShowCooldownText) then
				for nameplate in pairs(NameplatesVisible) do
					local counter = 1;
					if (AurasPerNameplate[nameplate][iconGroupIndex]) then
						for _, spellInfo in pairs(AurasPerNameplate[nameplate][iconGroupIndex]) do
							local last = spellInfo.expires - currentTime;
							if (last > 0 or spellInfo.duration == 0) then
								-- // getting reference to icon
								if (nameplate.NAurasIcons[iconGroupIndex] ~= nil) then
									local icon = nameplate.NAurasIcons[iconGroupIndex][counter];
									-- // setting text
									if (icon ~= nil) then icon:SetCooldown(last, spellInfo, iconGroup); end
									counter = counter + 1;
								end
							end
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
		local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo();
		if (instanceType == nil or instanceType == addonTable.INSTANCE_TYPE_NONE) then
			newInstanceType = instanceType;
		elseif (instanceType == "pvp") then
			if (addonTable.EPIC_BG_ZONE_IDS[instanceID]) then
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

	local function HideBuffFrame(_frame)
		if (_frame == nil) then
			return;
		end

		local unitId = _frame.unit;
		if (unitId == nil) then
			return;
		end

		if (UnitIsUnit(unitId, "player")) then
			_frame:SetShown(not db.HidePlayerBlizzardFrame);
		else
			_frame:SetShown(not db.HideBlizzardFrames);
		end

		-- friendly buff frame may appear on non-player nameplate if this nameplate is "reused player nameplate"
		-- thus we need to workaround this cases
		if (PersonalFriendlyBuffFrame ~= nil) then
			local parentNameplate = PersonalFriendlyBuffFrame:GetParent();
			if (parentNameplate ~= nil and parentNameplate.UnitFrame ~= nil and not UnitIsUnit(parentNameplate.UnitFrame.unit, "player")) then
				--addonTable.Print("PersonalFriendlyBuffFrame is attached to wrong nameplate, fixing...");
				PersonalFriendlyBuffFrame:Hide();
			else
				PersonalFriendlyBuffFrame:SetShown(not db.HidePlayerBlizzardFrame);
			end
		end
	end

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
		if (not Nameplates[nameplate]) then
			nameplate.NAurasIcons = {};
			nameplate.NAurasIconsCount = {};
			nameplate.NAurasFrames = {};
			Nameplates[nameplate] = true;
			AurasPerNameplate[nameplate] = {};
		end

		local unitGuid = UnitGUID(unitID);
		local now = GetTime();

		NameplatesVisible[nameplate] = unitID;
		NameplatesVisibleGuid[nameplate] = unitGuid;

		UpdateUnitAurasFull(unitID, unitGuid);
		ProcessAurasForNameplate(nameplate, unitID);

		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			if (iconGroup.InterruptsEnabled and InterruptsPerUnitGUID[iconGroupIndex] ~= nil) then
				local interrupt = InterruptsPerUnitGUID[iconGroupIndex][unitGuid];
				if (interrupt ~= nil) then
					local remainingTime = interrupt.expires - now;
					if (remainingTime > 0) then
						CTimerAfter(remainingTime, function() ProcessAurasForNameplate(nameplate, unitID); end);
					end
				end
			end

			SetAlphaScaleForNameplate(nameplate, iconGroupIndex, iconGroup);

			local iconGroupFrame = nameplate.NAurasFrames[iconGroupIndex];
			if (iconGroupFrame ~= nil) then
				local anchorFrame = addonTable.GetNameplateAddonFrame(nameplate, iconGroup);
				iconGroupFrame:ClearAllPoints();
				iconGroupFrame:SetPoint(iconGroup.FrameAnchor, anchorFrame, iconGroup.FrameAnchorToNameplate, iconGroup.IconXOffset, iconGroup.IconYOffset);
				iconGroupFrame:SetParent(iconGroup.NameplateIsParent == true and anchorFrame or UIParent);
				iconGroupFrame:Show();
			end
		end

		EventFrame.UNIT_THREAT_LIST_UPDATE(unitID);

		if (not BuffFrameHookedNameplates[nameplate]) then
			if (nameplate.UnitFrame ~= nil and nameplate.UnitFrame.BuffFrame ~= nil) then
				nameplate.UnitFrame.BuffFrame:HookScript("OnShow", HideBuffFrame);
				HideBuffFrame(nameplate.UnitFrame.BuffFrame);
				BuffFrameHookedNameplates[nameplate] = true;
			else
				error("Nameplate " .. nameplate:GetName() .. " doesn't have buff frame!");
			end
		end
	end

	function EventFrame.NAME_PLATE_UNIT_REMOVED(unitID)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = nil;
		if (AurasPerNameplate[nameplate] ~= nil) then
			wipe(AurasPerNameplate[nameplate]);
		end

		for iconGroupIndex in pairs(nameplate.NAurasFrames) do
			if (nameplate.NAurasFrames[iconGroupIndex] ~= nil) then
				nameplate.NAurasFrames[iconGroupIndex]:Hide();
			end
		end

		local unitGuid = NameplatesVisibleGuid[nameplate];
		if (unitGuid ~= nil and PlayerAurasPerGuid[unitGuid] ~= nil) then
			wipe(PlayerAurasPerGuid[unitGuid]);
			NameplatesVisibleGuid[nameplate] = nil;
		end
	end

	function EventFrame.UNIT_AURA(unitID, _unitAuraUpdateInfo)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unitID);
		if (nameplate ~= nil and AurasPerNameplate[nameplate] ~= nil) then
			local unitGuid = UnitGUID(unitID);
			if (_unitAuraUpdateInfo == nil or _unitAuraUpdateInfo.isFullUpdate or PlayerAurasPerGuid[unitGuid] == nil) then
				UpdateUnitAurasFull(unitID, unitGuid);
			else
				UpdateUnitAurasIncremental(unitID, unitGuid, _unitAuraUpdateInfo);
			end

			ProcessAurasForNameplate(nameplate, unitID);
		end
	end

	function EventFrame.UNIT_THREAT_LIST_UPDATE(unitID)
		for _, iconGroup in pairs(db.IconGroups) do
			if (iconGroup.AffixSpiteful) then
				local unitGUID = UnitGUID(unitID);
				if (unitGUID ~= nil) then
					local _, _, _, _, _, npcID = strsplit("-", unitGUID);
					if (not SpitefulMobs[unitGUID] and npcID == addonTable.SPITEFUL_NPC_ID_STRING) then
						local _, _, threatPct = UnitDetailedThreatSituation("player", unitID);
						if (threatPct == 100) then
							if (type(iconGroup.AffixSpitefulSound) == "number") then
								PlaySound(iconGroup.AffixSpitefulSound, "Master");
							else
								PlaySoundFile(SML:Fetch(SML.MediaType.SOUND, iconGroup.AffixSpitefulSound), "Master");
							end
							SpitefulMobs[unitGUID] = true;
							EventFrame.UNIT_AURA(unitID);
							return;
						end
					end
				end
			end
		end
	end

	local function ProcessInterrupts(event, destGUID, destFlags, spellID, spellName)
		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			if (iconGroup.InterruptsEnabled) then
				-- SPELL_INTERRUPT is not invoked for some channeled spells - it could not be implemented (2023/04/01)
				if (event == "SPELL_INTERRUPT") then
					local spellDuration = InterruptSpells[spellID];
					if (spellDuration ~= nil) then
						if (not iconGroup.InterruptsShowOnlyOnPlayers or bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0) then
							if (InterruptsPerUnitGUID[iconGroupIndex] == nil) then
								InterruptsPerUnitGUID[iconGroupIndex] = {};
							end
							InterruptsPerUnitGUID[iconGroupIndex][destGUID] = {
								["duration"] = spellDuration,
								["expires"] = GetTime() + spellDuration,
								["stacks"] = 1,
								["spellID"] = spellID,
								["type"] = AURA_TYPE_DEBUFF,
								["spellName"] = spellName,
								["dbEntry"] = {
									["enabledState"] =				CONST_SPELL_MODE_DISABLED,
									["auraType"] =					AURA_TYPE_DEBUFF,
									["iconSizeWidth"] = 			iconGroup.InterruptsIconSizeWidth,
									["iconSizeHeight"] = 			iconGroup.InterruptsIconSizeHeight,
									["overrideSize"] = 				true,
									["showGlow"] =					GLOW_TIME_INFINITE,
									["glowType"] =					iconGroup.InterruptsGlowType,
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
	end

	local function ProcessDR(event, spellID, destGUID, destFlags, spellAuraType)
		for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
			if ((iconGroup.Additions_DRPvP or iconGroup.Additions_DRPvE) and spellAuraType == "DEBUFF") then
				local category = DRList:GetCategoryBySpellID(spellID);
				if (category and category ~= "knockback") then
					local isPlayer = bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0;
					if ((isPlayer and iconGroup.Additions_DRPvP) or (not isPlayer and category == "stun" and iconGroup.Additions_DRPvE)) then
						if (DRDataPerGUID[iconGroupIndex] == nil) then DRDataPerGUID[iconGroupIndex] = { }; end
						if (DRDataPerGUID[iconGroupIndex][destGUID] == nil) then DRDataPerGUID[iconGroupIndex][destGUID] = { }; end
						if (DRDataPerGUID[iconGroupIndex][destGUID][category] == nil) then
							DRDataPerGUID[iconGroupIndex][destGUID][category] = {
								["drAppliedCount"] = 0,
								["lastTimeDRApplied"] = 0,
							};
						end
						local data = DRDataPerGUID[iconGroupIndex][destGUID][category];
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
							drTimers[data] = CTimerNewTimer(DRResetTime, function() DRDataPerGUID[iconGroupIndex][destGUID][category] = nil; end);
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
	end

	function EventFrame.COMBAT_LOG_EVENT_UNFILTERED()
		local _, event, _, _, _, _, _,destGUID,_,destFlags,_, spellID, spellName, _, spellAuraType = CombatLogGetCurrentEventInfo();
		ProcessInterrupts(event, destGUID, destFlags, spellID, spellName);
		ProcessDR(event, spellID, destGUID, destFlags, spellAuraType);
	end

	function EventFrame.PLAYER_TARGET_CHANGED()
		TargetGUID = UnitGUID("target");
		for nameplate in pairs(NameplatesVisible) do
			for iconGroupIndex, iconGroup in pairs(db.IconGroups) do
				SetAlphaScaleForNameplate(nameplate, iconGroupIndex, iconGroup);
			end
		end
		addonTable.UpdateAllNameplates(false);
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
	local testTable = {};

	local function GetSpells(_iconGroupIndex)
		if (GetTime() - spellsLastTimeUpdated >= intervalBetweenRefreshes) then
			spellsLastTimeUpdated = GetTime();
		end
		if (testTable[_iconGroupIndex] == nil) then
			testTable[_iconGroupIndex] = {
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
						["overrideSize"] = true,
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
						["overrideSize"] = true,
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
						["overrideSize"] = true,
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
						["iconSizeWidth"] = db.IconGroups[_iconGroupIndex].DefaultIconSizeWidth,
						["iconSizeHeight"] = db.IconGroups[_iconGroupIndex].DefaultIconSizeHeight,
						["overrideSize"] = true,
						["showGlow"] = GLOW_TIME_INFINITE,
						["glowType"] = db.IconGroups[_iconGroupIndex].Additions_DispellableSpells_GlowType,
					},
				},
			};
		else
			testTable[_iconGroupIndex][1]["duration"] = intervalBetweenRefreshes-3;
			testTable[_iconGroupIndex][1]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes-3;

			testTable[_iconGroupIndex][2]["duration"] = intervalBetweenRefreshes*20;
			testTable[_iconGroupIndex][2]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*20;

			testTable[_iconGroupIndex][3]["duration"] = intervalBetweenRefreshes*2;
			testTable[_iconGroupIndex][3]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*2;

			testTable[_iconGroupIndex][4]["dbEntry"]["iconSizeWidth"] = db.IconGroups[_iconGroupIndex].DefaultIconSizeWidth;
			testTable[_iconGroupIndex][4]["dbEntry"]["iconSizeHeight"] = db.IconGroups[_iconGroupIndex].DefaultIconSizeHeight;
			testTable[_iconGroupIndex][4]["dbEntry"]["glowType"] = db.IconGroups[_iconGroupIndex].Additions_DispellableSpells_GlowType;
		end
		if (addonTable.GetCurrentlyEditingSpell ~= nil) then
			local dbEntry, spellID = addonTable.GetCurrentlyEditingSpell();
			if (dbEntry ~= nil and spellID ~= nil) then
				if (testTable[_iconGroupIndex][5] == nil) then
					testTable[_iconGroupIndex][5] = {
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
					testTable[_iconGroupIndex][5]["duration"] = intervalBetweenRefreshes;
					testTable[_iconGroupIndex][5]["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes;
					testTable[_iconGroupIndex][5]["spellID"] = spellID;
					testTable[_iconGroupIndex][5]["type"] = (dbEntry.auraType == AURA_TYPE_DEBUFF) and AURA_TYPE_DEBUFF or AURA_TYPE_BUFF;
					testTable[_iconGroupIndex][5]["spellName"] = SpellNameByID[spellID];
					testTable[_iconGroupIndex][5]["dbEntry"] = dbEntry;
				end
			else
				testTable[_iconGroupIndex][5] = nil;
			end
		else
			testTable[_iconGroupIndex][5] = nil;
		end
		return testTable[_iconGroupIndex];
	end

	local function Ticker_OnTick()
		for iconGroupIndex in pairs(db.IconGroups) do
			local spells = GetSpells(iconGroupIndex);
			for nameplate, unitID in pairs(NameplatesVisible) do
				if (AurasPerNameplate[nameplate][iconGroupIndex] == nil) then
					AurasPerNameplate[nameplate][iconGroupIndex] = { };
				else
					wipe(AurasPerNameplate[nameplate][iconGroupIndex]);
				end

				-- local unitGuid = UnitGUID(unitID);
				-- if (InterruptsPerUnitGUID[iconGroupIndex] == nil) then
				-- 	InterruptsPerUnitGUID[iconGroupIndex] = {};
				-- end
				-- InterruptsPerUnitGUID[iconGroupIndex][unitGuid] = {
				-- 	["duration"] = 5,
				-- 	["expires"] = GetTime() + 5,
				-- 	["stacks"] = 1,
				-- 	["spellID"] = 6552,
				-- 	["type"] = AURA_TYPE_DEBUFF,
				-- 	["spellName"] = SpellNameByID[6552],
				-- 	["dbEntry"] = {
				-- 		["enabledState"] =				CONST_SPELL_MODE_DISABLED,
				-- 		["auraType"] =					AURA_TYPE_DEBUFF,
				-- 		["iconSizeWidth"] = 			iconGroup.InterruptsIconSizeWidth,
				-- 		["iconSizeHeight"] = 			iconGroup.InterruptsIconSizeHeight,
				-- 		["overrideSize"] = 				true,
				-- 		["showGlow"] =					GLOW_TIME_INFINITE,
				-- 		["glowType"] =					iconGroup.InterruptsGlowType,
				-- 	},
				-- };

				for _, spell in pairs(spells) do
					tinsert(AurasPerNameplate[nameplate][iconGroupIndex], spell);
				end

				if (unitID ~= nil) then
					UpdateNameplate(nameplate, UnitGUID(unitID));
				end
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
