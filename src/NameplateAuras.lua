local _, addonTable = ...;
--[===[@non-debug@
local buildTimestamp = "@project-version@";
--@end-non-debug@]===]

local L = LibStub("AceLocale-3.0"):GetLocale("NameplateAuras");
local LBG_ShowOverlayGlow, LBG_HideOverlayGlow = NAuras_LibButtonGlow.ShowOverlayGlow, NAuras_LibButtonGlow.HideOverlayGlow;
local SML = LibStub("LibSharedMedia-3.0");
local AceComm = LibStub("AceComm-3.0");
local LibCustomGlow = LibStub("LibCustomGlow-1.0");

-- // upvalues
local 	_G, pairs, select, WorldFrame, string_match,string_gsub,string_find,string_format, 	GetTime, math_ceil, math_floor, wipe, C_NamePlate_GetNamePlateForUnit, UnitBuff, UnitDebuff, string_lower,
			UnitReaction, UnitGUID, UnitIsFriend, table_insert, table_sort, table_remove, IsUsableSpell, CTimerAfter,	bit_band, CTimerNewTimer,   strsplit, CombatLogGetCurrentEventInfo =
		_G, pairs, select, WorldFrame, strmatch, 	gsub,		strfind, 	format,			GetTime, ceil,		floor,		wipe, C_NamePlate.GetNamePlateForUnit, UnitBuff, UnitDebuff, string.lower,
			UnitReaction, UnitGUID, UnitIsFriend, table.insert, table.sort, table.remove, IsUsableSpell, C_Timer.After,	bit.band, C_Timer.NewTimer, strsplit, CombatLogGetCurrentEventInfo;

-- // variables
local AurasPerNameplate, InterruptsPerUnitGUID, UnitGUIDHasInterruptReduction, UnitGUIDHasAdditionalInterruptReduction, ElapsedTimer, Nameplates, NameplatesVisible, InPvPCombat, GUIFrame,
	EventFrame, db, aceDB, LocalPlayerGUID, DebugWindow, ProcessAurasForNameplate, UpdateNameplate, OnUpdate;
do
	AurasPerNameplate 						= { };
	InterruptsPerUnitGUID					= { };
	UnitGUIDHasInterruptReduction			= { };
	UnitGUIDHasAdditionalInterruptReduction	= { };
	ElapsedTimer 							= 0;
	Nameplates, NameplatesVisible 			= { }, { };
	InPvPCombat								= false;
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
		DebugWindow:AddText("InPvPCombat: " .. tostring(InPvPCombat));
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
				tostring(spellInfo.iconSize),
				spellInfo.checkSpellID ~= nil and table.concat(spellInfo.checkSpellID, ",") or "NONE",
				tostring(spellInfo.showOnFriends),
				tostring(spellInfo.showOnEnemies),
				tostring(spellInfo.pvpCombat),
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
				InterruptsGlowType = addonTable.GLOW_TYPE_ACTIONBUTTON_DIM,
				InterruptsUseSharedIconTexture = false,
				InterruptsShowOnlyOnPlayers = true,
				Additions_ExplosiveOrbs = true,
				ShowAuraTooltip = false,
				HidePlayerBlizzardFrame = "undefined", -- // don't change: we convert db with that
				Additions_DispellableSpells = false,
				Additions_DispellableSpells_Blacklist = {},
				Additions_DispellableSpells_IconSize = 45, -- // must be equal to DefaultIconSize
				Additions_DispellableSpells_GlowType = addonTable.GLOW_TYPE_PIXEL,
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
		-- // set default values
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
				AceComm:SendCommMessage("NameplateAuras", "requesting3#" .. LocalPlayerGUID, c);
			elseif (msg == "debug") then
				ChatCommand_Debug();
			elseif (msg == "test") then
				addonTable.SwitchTestMode();
			else
				addonTable.ShowGUI();
			end
		end
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

	local EXPLOSIVE_ORB_NPC_ID_AS_STRING = addonTable.EXPLOSIVE_ORB_NPC_ID_AS_STRING;
	local GLOW_TYPE_NONE, GLOW_TYPE_ACTIONBUTTON, GLOW_TYPE_AUTOUSE, GLOW_TYPE_PIXEL, GLOW_TYPE_ACTIONBUTTON_DIM = 
		addonTable.GLOW_TYPE_NONE, addonTable.GLOW_TYPE_ACTIONBUTTON, addonTable.GLOW_TYPE_AUTOUSE, addonTable.GLOW_TYPE_PIXEL, addonTable.GLOW_TYPE_ACTIONBUTTON_DIM;
	local glowInfo = { };
	local symmetricAnchors = {
		["TOPLEFT"] = "TOPRIGHT",
		["LEFT"] = "RIGHT",
		["BOTTOMLEFT"] = "BOTTOMRIGHT",
	};
	local AuraSortFunctions = {
		[AURA_SORT_MODE_EXPIREASC] = function(item1, item2) return item1.expires < item2.expires; end,
		[AURA_SORT_MODE_EXPIREDES] = function(item1, item2) return item1.expires > item2.expires; end,
		[AURA_SORT_MODE_ICONSIZEASC] = function(item1, item2)
			local enabledAuraInfo1 = item1.dbEntry;
			local enabledAuraInfo2 = item2.dbEntry;
			return (enabledAuraInfo1 and enabledAuraInfo1.iconSize or db.DefaultIconSize) < (enabledAuraInfo2 and enabledAuraInfo2.iconSize or db.DefaultIconSize);
		end,
		[AURA_SORT_MODE_ICONSIZEDES] = function(item1, item2)
			local enabledAuraInfo1 = item1.dbEntry;
			local enabledAuraInfo2 = item2.dbEntry;
			return (enabledAuraInfo1 and enabledAuraInfo1.iconSize or db.DefaultIconSize) > (enabledAuraInfo2 and enabledAuraInfo2.iconSize or db.DefaultIconSize);
		end,
		[AURA_SORT_MODE_AURATYPE_EXPIRE] = function(item1, item2)
			if (item1.type ~= item2.type) then
				return (item1.type == AURA_TYPE_DEBUFF) and true or false;
			end
			if (item1.type == AURA_TYPE_DEBUFF) then
				return item1.expires < item2.expires;
			else
				return item1.expires > item2.expires;
			end
		end
	};

	local function AllocateIcon_SetAuraTooltip(icon)
		if (db.ShowAuraTooltip) then
			icon:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
				GameTooltip:SetHyperlink(GetSpellLink(icon.spellID));
				GameTooltip:Show();
			end);
			icon:SetScript("OnLeave", function() GameTooltip:Hide(); end);
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
		table_insert(addonTable.AllAuraIconFrames, icon);
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.DefaultIconSize * frame.NAurasIconsCount);
		table_insert(frame.NAurasIcons, icon);
	end

	local function HideGlow(icon)
		if (icon.glowType ~= nil) then
			LBG_HideOverlayGlow(icon);
			LibCustomGlow.PixelGlow_Stop(icon);
			LibCustomGlow.AutoCastGlow_Stop(icon);
			icon.glowType = nil;
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
		icon.size = -1;
		HideGlow(icon);
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

	local function ProcessAurasForNameplate_Filter(auraType, auraName, auraCaster, auraSpellID, unitIsFriend, dbEntry)
		if (dbEntry ~= nil) then
			if (dbEntry.enabledState == CONST_SPELL_MODE_ALL or (dbEntry.enabledState == CONST_SPELL_MODE_MYAURAS and auraCaster == "player")) then
				if ((not unitIsFriend and dbEntry.showOnEnemies) or (unitIsFriend and dbEntry.showOnFriends)) then
					if (dbEntry.auraType == AURA_TYPE_ANY or dbEntry.auraType == auraType) then
						local showInPvPCombat = dbEntry.pvpCombat;
						if (showInPvPCombat == CONST_SPELL_PVP_MODES_UNDEFINED or (showInPvPCombat == CONST_SPELL_PVP_MODES_INPVPCOMBAT and InPvPCombat) or (showInPvPCombat == CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT and not InPvPCombat)) then
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

	local function ProcessAurasForNameplate_ProcessAdditions(unitGUID, frame, unitID, unitIsFriend)
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
					["dbEntry"] = {
						["showGlow"] = GLOW_TIME_INFINITE,
						["glowType"] = GLOW_TYPE_ACTIONBUTTON,
					},
				});
			end
		end
	end

	local function ProcessAurasForNameplate_OnNewAura(auraType, auraName, auraStack, auraDispelType, auraDuration, auraExpires, auraCaster, auraIsStealable, auraSpellID, unitIsFriend, frame)
		local foundInDB = false;
		for _, dbEntry in pairs(db.CustomSpells2) do
			if (auraName == dbEntry.spellName) then
				if (ProcessAurasForNameplate_Filter(auraType, auraName, auraCaster, auraSpellID, unitIsFriend, dbEntry)) then
					table_insert(AurasPerNameplate[frame], {
						["duration"] = auraDuration,
						["expires"] = auraExpires,
						["stacks"] = auraStack,
						["spellID"] = auraSpellID,
						["type"] = auraType,
						["dispelType"] = auraDispelType,
						["spellName"] = auraName,
						["dbEntry"] = dbEntry,
					});
					foundInDB = true;
				end
			end
		end
		if (not foundInDB) then
			if (db.AlwaysShowMyAuras and auraCaster == "player") then
				table_insert(AurasPerNameplate[frame], {
					["duration"] = auraDuration,
					["expires"] = auraExpires,
					["stacks"] = auraStack,
					["spellID"] = auraSpellID,
					["type"] = auraType,
					["dispelType"] = auraDispelType,
					["spellName"] = auraName,
				});
			end
			if (db.Additions_DispellableSpells and not unitIsFriend and auraIsStealable) then
				if (db.Additions_DispellableSpells_Blacklist[auraName] == nil) then
					table_insert(AurasPerNameplate[frame], {
						["duration"] = auraDuration,
						["expires"] = auraExpires,
						["stacks"] = auraStack,
						["spellID"] = auraSpellID,
						["type"] = auraType,
						["spellName"] = auraName,
						["dbEntry"] = {
							["iconSize"] = db.Additions_DispellableSpells_IconSize,
							["showGlow"] = GLOW_TIME_INFINITE,
							["glowType"] = db.Additions_DispellableSpells_GlowType,
						},
					});
				end
			end
		end
	end

	function ProcessAurasForNameplate(frame, unitID)
		wipe(AurasPerNameplate[frame]);
		local unitIsFriend = (UnitReaction("player", unitID) or 0) > 4; -- 4 = neutral
		local unitGUID = UnitGUID(unitID);
		if ((LocalPlayerGUID ~= unitGUID or db.ShowAurasOnPlayerNameplate) and (db.ShowAboveFriendlyUnits or not unitIsFriend)) then
			for i = 1, 40 do
				local buffName, _, buffStack, _, buffDuration, buffExpires, buffCaster, buffIsStealable, _, buffSpellID = UnitBuff(unitID, i);
				if (buffName ~= nil) then
					ProcessAurasForNameplate_OnNewAura(AURA_TYPE_BUFF, buffName, buffStack, nil, buffDuration, buffExpires, buffCaster, buffIsStealable, buffSpellID, unitIsFriend, frame);
				end
				local debuffName, _, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, _, _, debuffSpellID = UnitDebuff(unitID, i);
				if (debuffName ~= nil) then
					ProcessAurasForNameplate_OnNewAura(AURA_TYPE_DEBUFF, debuffName, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, nil, debuffSpellID, unitIsFriend, frame);
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
		ProcessAurasForNameplate_ProcessAdditions(unitGUID, frame, unitID, unitIsFriend);
		UpdateNameplate(frame, unitGUID);
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
			if (last > 3600 or spellInfo.duration == 0) then
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
			if (last >= 60 or spellInfo.duration == 0) then
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
					if (spellInfo.duration == 0) then
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
				if (spellInfo.duration == 0) then
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

	local glowMethods = {
		[GLOW_TYPE_NONE] = function(icon) HideGlow(icon); end,
		[GLOW_TYPE_ACTIONBUTTON] = function(icon, iconResized)
			if (icon.glowType ~= GLOW_TYPE_ACTIONBUTTON) then
				LBG_ShowOverlayGlow(icon, iconResized, false);
				icon.glowType = GLOW_TYPE_ACTIONBUTTON;
			end
		end,
		[GLOW_TYPE_AUTOUSE] = function(icon)
			if (icon.glowType ~= GLOW_TYPE_AUTOUSE) then
				LibCustomGlow.AutoCastGlow_Start(icon, nil, nil, 0.2, 1.5);
				icon.glowType = GLOW_TYPE_AUTOUSE;
			end
		end,
		[GLOW_TYPE_PIXEL] = function(icon)
			if (icon.glowType ~= GLOW_TYPE_PIXEL) then
				LibCustomGlow.PixelGlow_Start(icon, nil, nil, nil, nil, 2);
				icon.glowType = GLOW_TYPE_PIXEL;
			end
		end,
		[GLOW_TYPE_ACTIONBUTTON_DIM] = function(icon, iconResized)
			if (icon.glowType ~= GLOW_TYPE_ACTIONBUTTON_DIM) then
				LBG_ShowOverlayGlow(icon, iconResized, true);
				icon.glowType = GLOW_TYPE_ACTIONBUTTON_DIM;
			end
		end,
	};

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
			elseif (remainingAuraTime < dbEntry.showGlow) then -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is less than user's limit
				glowMethods[dbEntry.glowType](icon, iconResized);
			else -- // okay, user has limited time for glow, aura is not permanent and aura's remaining time is bigger than user's limit
				HideGlow(icon); -- // hide glow
				glowInfo[icon] = CTimerNewTimer(remainingAuraTime - dbEntry.showGlow, function() glowMethods[dbEntry.glowType](icon, iconResized); end); -- // queue delayed glow
			end
		else
			HideGlow(icon); -- // this aura doesn't require glow
		end
	end

	function UpdateNameplate(frame, unitGUID)
		local counter = 1;
		local totalWidth = 0;
		if (AurasPerNameplate[frame]) then
			local currentTime = GetTime();
			if (db.SortMode ~= AURA_SORT_MODE_NONE) then table_sort(AurasPerNameplate[frame], AuraSortFunctions[db.SortMode]); end
			for _, spellInfo in pairs(AurasPerNameplate[frame]) do
				local spellName = SpellNameByID[spellInfo.spellID];
				local duration = spellInfo.duration;
				local last = spellInfo.expires - currentTime;
				if (last > 0 or spellInfo.duration == 0) then
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
					local enabledAuraInfo = spellInfo.dbEntry;
					local normalSize = enabledAuraInfo and enabledAuraInfo.iconSize or db.DefaultIconSize;
					local iconResized = false;
					if (normalSize ~= icon.size) then
						icon.size = normalSize;
						ResizeIcon(icon, icon.size);
						iconResized = true;
					end
					-- // glow
					UpdateNameplate_SetGlow(icon, iconResized, last, spellInfo);
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
					local last = spellInfo.expires - currentTime;
					if (last > 0 or spellInfo.duration == 0) then
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
						["dbEntry"] = {
							["enabledState"] =				CONST_SPELL_MODE_DISABLED,
							["auraType"] =					AURA_TYPE_DEBUFF,
							["iconSize"] =					db.InterruptsIconSize,
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

--------------------------------------------------------------------------------------------------
----- Test mode
--------------------------------------------------------------------------------------------------
do
	local TestModeIsActive = false;
	local intervalBetweenRefreshes = 10;
	local ticker = nil;
	local spellsLastTimeUpdated = GetTime() - intervalBetweenRefreshes;

	local function GetSpells()
		if (GetTime() - spellsLastTimeUpdated >= intervalBetweenRefreshes) then
			spellsLastTimeUpdated = GetTime();
		end
		return {
			{
				["duration"] = intervalBetweenRefreshes,
				["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes,
				["stacks"] = 1,
				["spellID"] = 139,
				["type"] = AURA_TYPE_BUFF,
				["spellName"] = SpellNameByID[139],
				["dbEntry"] = {
					["iconSize"] = 45,
				},
			},
			{
				["duration"] = intervalBetweenRefreshes*2,
				["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*2,
				["stacks"] = 1,
				["spellID"] = 215336,
				["type"] = AURA_TYPE_BUFF,
				["spellName"] = SpellNameByID[215336],
				["dbEntry"] = {
					["iconSize"] = 30,
				},
			},
			{
				["duration"] = intervalBetweenRefreshes*20,
				["expires"] = spellsLastTimeUpdated + intervalBetweenRefreshes*20,
				["stacks"] = 3,
				["spellID"] = 188389,
				["type"] = AURA_TYPE_DEBUFF,
				["dispelType"] = "Magic",
				["spellName"] = SpellNameByID[188389],
				["dbEntry"] = {
					["iconSize"] = 40,
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
					["iconSize"] = 35,
					["showGlow"] = GLOW_TIME_INFINITE,
					["glowType"] = db.Additions_DispellableSpells_GlowType,
				},
			},

		};
	end

	local function Ticker_OnTick()
		for nameplate, auras in pairs(AurasPerNameplate) do
			local unitID = NameplatesVisible[nameplate];
			if (unitID ~= nil) then
				wipe(auras);
				for _, spellInfo in pairs(GetSpells()) do
					table_insert(auras, spellInfo);
				end
				UpdateNameplate(nameplate, unitID);
				if (db.FullOpacityAlways and nameplate.NAurasFrame) then
					nameplate.NAurasFrame:Show();
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
