local _, addonTable = ...;
local L = addonTable.L;
local DefaultSpells = addonTable.DefaultSpells;

local SML = LibStub("LibSharedMedia-3.0");
SML:Register("font", "NAuras_TeenBold", 		"Interface\\AddOns\\NameplateAuras\\media\\teen_bold.ttf", 255);
SML:Register("font", "NAuras_TexGyreHerosBold", "Interface\\AddOns\\NameplateAuras\\media\\texgyreheros-bold-webfont.ttf", 255);

NameplateAurasDB = {};
local nameplateAuras = {};
local TextureCache = setmetatable({}, {
	__index = function(t, key)
		local texture = GetSpellTexture(key);
		t[key] = texture;
		return texture;
	end
});
local SpellNamesCache = setmetatable({}, {
	__index = function(t, key)
		local spellName = GetSpellInfo(key);
		t[key] = spellName;
		return spellName;
	end
});
local SpellIDsCache = setmetatable({}, {
	__index = function(t, key)
		for spellID = 1, 500000 do
			local spellName = GetSpellInfo(spellID);
			if (spellName == key) then
				t[key] = spellID;
				return spellID;
			end
		end
		return nil;
	end
});
local Spells = {};
local SpellShowModesCache = { };
local SpellAuraTypeCache = { };
local SpellIconSizesCache = { }; -- // key is a spell name
local SpellCheckIDCache = { };
local ElapsedTimer = 0;
local Nameplates = {};
local NameplatesVisible = {};
local GUIFrame;
local EventFrame;
local db;
local aceDB;
local LocalPlayerFullName = UnitName("player").." - "..GetRealmName();
local LocalPlayerGUID;
local ProfileOptionsFrame;
-- consts
local SPELL_SHOW_MODES, SPELL_SHOW_TYPES, CONST_SORT_MODES, CONST_SORT_MODES_LOCALIZATION, CONST_DISABLED, CONST_MAX_ICON_SIZE, CONST_TIMER_STYLES, CONST_TIMER_STYLES_LOCALIZATION;
do
	
	SPELL_SHOW_MODES = { "my", "all", "disabled" };
	SPELL_SHOW_TYPES = { "buff", "debuff", "buff/debuff" };
	CONST_SORT_MODES = { "none", "by-expire-time-asc", "by-expire-time-des", "by-icon-size-asc", "by-icon-size-des", "by-aura-type-expire-time" };
	CONST_SORT_MODES_LOCALIZATION = { 
		[CONST_SORT_MODES[1]] = "None",
		[CONST_SORT_MODES[2]] = "By expire time, ascending",
		[CONST_SORT_MODES[3]] = "By expire time, descending",
		[CONST_SORT_MODES[4]] = "By icon size, ascending",
		[CONST_SORT_MODES[5]] = "By icon size, descending",
		[CONST_SORT_MODES[6]] = "By aura type (de/buff) + expire time"
	};
	CONST_DISABLED = SPELL_SHOW_MODES[3];
	CONST_MAX_ICON_SIZE = 75;
	CONST_TIMER_STYLES = { "texture-with-text", "cooldown-frame-no-text", "cooldown-frame", "circular-noomnicc-text" };
	CONST_TIMER_STYLES_LOCALIZATION = {
		[CONST_TIMER_STYLES[1]] = "Texture with timer",
		[CONST_TIMER_STYLES[2]] = "Circular",
		[CONST_TIMER_STYLES[3]] = "Circular with OmniCC support",
		[CONST_TIMER_STYLES[4]] = "Circular with timer",
	};
	
end


local _G = _G;
local pairs = pairs;
local select = select;
local WorldFrame = WorldFrame;
local string_match = strmatch;
local string_gsub = gsub;
local string_find = strfind;
local string_format = format;
local GetTime = GetTime;
local math_ceil = ceil;
local math_floor = floor;

local OnStartup;
local ReloadDB;
local InitializeDB;
local GetDefaultDBSpellEntry;
local UpdateSpellCachesFromDB;

local AllocateIcon;
local UpdateAllNameplates;
local ProcessAurasForNameplate;
local UpdateNameplate;
local UpdateNameplate_SetCooldown;
local UpdateNameplate_SetStacks;
local UpdateNameplate_SetBorder;
local HideCDIcon;
local ShowCDIcon;
local ResizeIcon;
local Nameplates_OnFontChanged;
local Nameplates_OnDefaultIconSizeOrOffsetChanged;
local Nameplates_OnSortModeChanged;
local Nameplates_OnTextPositionChanged;
local Nameplates_OnIconAnchorChanged;
local SortAurasForNameplate;

local OnUpdate;

local PLAYER_ENTERING_WORLD;
local NAME_PLATE_UNIT_ADDED;
local NAME_PLATE_UNIT_REMOVED;
local UNIT_AURA;

local ShowGUI;
local InitializeGUI;
local GUICategory_1;
local GUICategory_2;
local GUICategory_4;
local GUICategory_Fonts;
local GUICategory_Borders;
local OnGUICategoryClick;
local ShowGUICategory;
local RebuildDropdowns;
local CreateGUICategory;
local GUICreateSlider;
local GUICreateButton;

local Print;
local deepcopy;
local msg;

local optionsTable;
do
	optionsTable = {
		name = "NameplateAuras",
		type = 'group',
		args = {
			openGUI = {
				type = 'execute',
				order = 1,
				name = 'Open config dialog',
				desc = nil,
				func = function()
					ShowGUI();
					if (GUIFrame) then
						InterfaceOptionsFrameCancel:Click();
					end
				end,
			},
		},
	};
end


-------------------------------------------------------------------------------------------------
----- Initialize
-------------------------------------------------------------------------------------------------
do

	function OnStartup()
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
		-- // adding slash command
		SLASH_NAMEPLATEAURAS1 = '/nauras';
		SlashCmdList["NAMEPLATEAURAS"] = function(msg, editBox)
			if (msg == "t") then
				Print("Waiting for replies...");
				SendAddonMessage("NAuras_prefix", "requesting", IsInGroup(2) and "INSTANCE_CHAT" or "RAID");
			else
				ShowGUI();
			end
		end
		OnStartup = nil;
	end

	function ReloadDB()
		db = aceDB.profile;
		Spells = {};
		SpellShowModesCache = { };
		SpellAuraTypeCache = { };
		SpellIconSizesCache = { };
		SpellCheckIDCache = { };
		-- // Convert standard spell IDs to spell names
		for spellID, spellInfo in pairs(DefaultSpells) do
			local spellName = SpellNamesCache[spellID];
			if (spellName ~= nil and Spells[spellName] == nil) then
				Spells[spellName] = spellInfo;
				if (db.CustomSpells2[spellID] == nil) then
					db.CustomSpells2[spellID] = spellInfo;
					Print("New spell is added: " .. spellName .. " (id:" .. spellID .. ")");
				end
			else
				Print("<" .. spellName .. "> not exist or is already added (id:" .. spellID .. ", id:" .. (Spells[spellName] ~= nil and Spells[spellName].spellID or "0") .. ")");
			end
		end
		for spellID, spellInfo in pairs(db.CustomSpells2) do
			local spellName = SpellNamesCache[spellID];
			if (spellName == nil) then
				Print("<"..spellName.."> isn't exist. Removing from database...");
				db.CustomSpells2[spellID] = nil;
			else
				Spells[spellName] = spellInfo;
				if (enabledState ~= CONST_DISABLED) then
					UpdateSpellCachesFromDB(spellID);
				end
				if (spellInfo.spellID == nil) then
					db.CustomSpells2[spellID].spellID = spellID;
				end
			end
		end
		-- // starting OnUpdate()
		if (db.TimerStyle == CONST_TIMER_STYLES[1] or db.TimerStyle == CONST_TIMER_STYLES[4]) then
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
		if (GUIFrame) then
			--GUIFrame:Hide();
			for _, func in pairs(GUIFrame.OnDBChangedHandlers) do
				func();
			end
		end
		Nameplates_OnFontChanged();
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				nameplate.NAurasFrame:SetPoint("CENTER", nameplate, db.IconXOffset, db.IconYOffset);
			end
		end
		Nameplates_OnTextPositionChanged();
		Nameplates_OnIconAnchorChanged();
		UpdateAllNameplates(true);
	end
	
	function InitializeDB()
		-- // set defaults
		local aceDBDefaults = {
			profile = {
				DefaultSpells = { },
				CustomSpells2 = { },
				IconXOffset = 0,
				IconYOffset = 50,
				FullOpacityAlways = false,
				Font = "NAuras_TeenBold",
				HideBlizzardFrames = true,
				DefaultIconSize = 45,
				SortMode = CONST_SORT_MODES[2],
				DisplayTenthsOfSeconds = true,
				FontScale = 1,
				TimerTextAnchor = "CENTER",
				TimerTextXOffset = 0,
				TimerTextYOffset = 0,
				TimerTextSoonToExpireColor = { 1, 0.1, 0.1 },
				TimerTextUnderMinuteColor = { 1, 1, 0.1 },
				TimerTextLongerColor = { 0.7, 1, 0 },
				StacksFont = "NAuras_TeenBold",
				StacksFontScale = 1,
				StacksTextAnchor = "BOTTOMRIGHT",
				StacksTextXOffset = -3,
				StacksTextYOffset = 5,
				StacksTextColor = { 1, 0.1, 0.1 },
				TimerStyle = CONST_TIMER_STYLES[1],
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
				AlwaysShowMyAuras = true,
			},
		};
		
		-- // ...
		aceDB = LibStub("AceDB-3.0"):New("NameplateAurasAceDB", aceDBDefaults);
		-- // convert from old DB
		if (NameplateAurasDB[LocalPlayerFullName] ~= nil) then
			Print("Converting DB to Ace3DB...");
			for index in pairs(NameplateAurasDB[LocalPlayerFullName]) do
				aceDB.profile[index] = deepcopy(NameplateAurasDB[LocalPlayerFullName][index]);
			end
			NameplateAurasDB[LocalPlayerFullName] = nil;
			Print("DB converting is completed");
		end
		-- // adding to blizz options
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras", optionsTable);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras", "NameplateAuras");
		local profilesConfig = LibStub("AceDBOptions-3.0"):GetOptionsTable(aceDB);
		LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateAuras.profiles", profilesConfig);
		ProfileOptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateAuras.profiles", "Profiles", "NameplateAuras");
		-- // processing old and invalid entries
		for _, entry in pairs({ "IconSize", "DebuffBordersColor", "DisplayBorders", "ShowMyAuras" }) do
			if (aceDB.profile[entry] ~= nil) then
				aceDB.profile[entry] = nil;
				Print("Old db record is deleted: " .. entry);
			end
		end
		-- // creating a fast reference
		aceDB.RegisterCallback("NameplateAuras", "OnProfileChanged", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileCopied", ReloadDB);
		aceDB.RegisterCallback("NameplateAuras", "OnProfileReset", ReloadDB);
	end
	
	function GetDefaultDBSpellEntry(enabledState, spellID, iconSize, checkSpellID)
		return {
			["enabledState"] = enabledState,
			["auraType"] = SPELL_SHOW_TYPES[3],
			["iconSize"] = (iconSize ~= nil) and iconSize or db.DefaultIconSize,
			["spellID"] = spellID,
			["checkSpellID"] = checkSpellID,
		};
	end
	
	function UpdateSpellCachesFromDB(spellID)
		local spellName = SpellNamesCache[spellID];
		if (db.CustomSpells2[spellID] ~= nil) then
			SpellShowModesCache[spellName] = 	db.CustomSpells2[spellID].enabledState;
			SpellAuraTypeCache[spellName] = 	db.CustomSpells2[spellID].auraType;
			SpellIconSizesCache[spellName] = 	db.CustomSpells2[spellID].iconSize;
			SpellCheckIDCache[spellName] = 		db.CustomSpells2[spellID].checkSpellID;
		else
			SpellShowModesCache[spellName] = 	nil;
			SpellAuraTypeCache[spellName] = 	nil;
			SpellIconSizesCache[spellName] = 	nil;
			SpellCheckIDCache[spellName] = 		nil;
		end
	end
		
end

-------------------------------------------------------------------------------------------------
----- Nameplates
-------------------------------------------------------------------------------------------------
do
	local cooldownCounter = 0;
	function AllocateIcon(frame, widthUsed)
		if (not frame.NAurasFrame) then
			frame.NAurasFrame = CreateFrame("frame", nil, db.FullOpacityAlways and WorldFrame or frame);
			frame.NAurasFrame:SetWidth(db.DefaultIconSize);
			frame.NAurasFrame:SetHeight(db.DefaultIconSize);
			frame.NAurasFrame:SetPoint("CENTER", frame, db.IconXOffset, db.IconYOffset);
			frame.NAurasFrame:Show();
		end
		local texture = (db.TimerStyle == CONST_TIMER_STYLES[1]) and frame.NAurasFrame:CreateTexture(nil, "BORDER") or CreateFrame("Frame", nil, frame.NAurasFrame);
		texture:SetPoint(db.IconAnchor, frame.NAurasFrame, widthUsed, 0);
		texture:SetWidth(db.DefaultIconSize);
		texture:SetHeight(db.DefaultIconSize);
		if (db.TimerStyle == CONST_TIMER_STYLES[2] or db.TimerStyle == CONST_TIMER_STYLES[3] or db.TimerStyle == CONST_TIMER_STYLES[4]) then
			texture.cooldownFrame = CreateFrame("Cooldown", nil, texture, "CooldownFrameTemplate");
			texture.cooldownFrame:SetAllPoints(texture);
			texture.cooldownFrame:SetReverse(true);
			if (db.TimerStyle == CONST_TIMER_STYLES[3]) then
				texture.cooldownFrame:SetDrawEdge(false);
				texture.cooldownFrame:SetDrawSwipe(true);
				texture.cooldownFrame:SetSwipeColor(0, 0, 0, 0.8);
				texture.cooldownFrame:SetHideCountdownNumbers(true);
			end
			texture.texture = texture:CreateTexture(nil, "BORDER");
			texture.texture:SetAllPoints(texture);
			texture.SetTexture = function(self, textureID) self.texture:SetTexture(textureID); end;
			texture.SetCooldown = function(self, startTime, duration)
				if (startTime == 0) then duration = 0; end
				texture.cooldownFrame:SetCooldown(startTime, duration);
			end;
			cooldownCounter = cooldownCounter + 1;
			texture.border = texture:CreateTexture(nil, "OVERLAY");
			texture.stacks = texture:CreateFontString("NAuras.Cooldown" .. tostring(cooldownCounter) .. ".Stacks", "OVERLAY");
			hooksecurefunc(texture.stacks, "SetText", function(self, text)
				if (text ~= "") then
					if (texture.cooldownFrame:GetCooldownDuration() == 0) then
						texture.stacks:SetParent(texture);
					else
						texture.stacks:SetParent(texture.cooldownFrame);
					end
				end
			end);
			texture.cooldown = texture:CreateFontString(nil, "OVERLAY");
			hooksecurefunc(texture.cooldown, "SetText", function(self, text)
				if (text ~= "") then
					if (texture.cooldownFrame:GetCooldownDuration() == 0) then
						texture.cooldown:SetParent(texture);
					else
						texture.cooldown:SetParent(texture.cooldownFrame);
					end
				end
			end);
		else
			texture.border = frame.NAurasFrame:CreateTexture(nil, "OVERLAY");
			texture.stacks = frame.NAurasFrame:CreateFontString(nil, "OVERLAY");
			texture.cooldown = frame.NAurasFrame:CreateFontString(nil, "OVERLAY");
		end
		texture.size = db.DefaultIconSize;
		texture:Hide();
		texture.cooldown:SetTextColor(0.7, 1, 0);
		texture.cooldown:SetPoint(db.TimerTextAnchor, texture, db.TimerTextXOffset, db.TimerTextYOffset);
		texture.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil((db.DefaultIconSize - db.DefaultIconSize / 2) * db.FontScale), "OUTLINE");
		texture.border:SetTexture("Interface\\AddOns\\NameplateAuras\\media\\CooldownFrameBorder.tga");
		texture.border:SetVertexColor(1, 0.35, 0);
		texture.border:SetAllPoints(texture);
		texture.border:Hide();
		texture.stacks:SetTextColor(unpack(db.StacksTextColor));
		texture.stacks:SetPoint(db.StacksTextAnchor, texture, db.StacksTextXOffset, db.StacksTextYOffset);
		texture.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((db.DefaultIconSize / 4) * db.StacksFontScale), "OUTLINE");
		texture.stackcount = 0;
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.DefaultIconSize * frame.NAurasIconsCount);
		tinsert(frame.NAurasIcons, texture);
	end
		
	function UpdateAllNameplates(force)
		if (force) then
			for nameplate in pairs(Nameplates) do
				if (nameplate.NAurasFrame) then
					for _, icon in pairs(nameplate.NAurasIcons) do
						HideCDIcon(icon);
					end
				end
			end
		end
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame and nameplate.UnitFrame.unit) then
				ProcessAurasForNameplate(nameplate, nameplate.UnitFrame.unit);
			end
		end
	end
		
	local function ProcessAurasForNameplate_Filter(isBuff, auraName, auraCaster, auraSpellID)
		if (db.AlwaysShowMyAuras and auraCaster == "player") then
			return true;
		else
			if (SpellShowModesCache[auraName] == "all" or (SpellShowModesCache[auraName] == "my" and auraCaster == "player")) then
				if (SpellAuraTypeCache[auraName] == "buff/debuff" or (isBuff and SpellAuraTypeCache[auraName] == "buff" or SpellAuraTypeCache[auraName] == "debuff")) then
					if (SpellCheckIDCache[auraName] == nil or SpellCheckIDCache[auraName] == auraSpellID) then
						return true;
					end
				end
			end
		end
		return false;
	end
		
	function ProcessAurasForNameplate(frame, unitID)
		wipe(nameplateAuras[frame]);
		if (LocalPlayerGUID ~= UnitGUID(unitID) or db.ShowAurasOnPlayerNameplate == true) then
			for i = 1, 40 do
				local buffName, _, _, buffStack, _, buffDuration, buffExpires, buffCaster, _, _, buffSpellID = UnitBuff(unitID, i);
				if (buffName ~= nil) then
					if (ProcessAurasForNameplate_Filter(true, buffName, buffCaster, buffSpellID)) then
						if (nameplateAuras[frame][buffName] == nil or nameplateAuras[frame][buffName].expires < buffExpires or nameplateAuras[frame][buffName].stacks ~= buffStack) then
							nameplateAuras[frame][buffName] = {
								["duration"] = buffDuration ~= 0 and buffDuration or 4000000000,
								["expires"] = buffExpires ~= 0 and buffExpires or 4000000000,
								["stacks"] = buffStack,
								["spellID"] = buffSpellID,
								["type"] = "buff"
							};
						end
					end
				end
				local debuffName, _, _, debuffStack, debuffDispelType, debuffDuration, debuffExpires, debuffCaster, _, _, debuffSpellID = UnitDebuff(unitID, i);
				if (debuffName ~= nil) then
					--print("ProcessAurasForNameplate: ", SpellShowModesCache[debuffName], debuffName, debuffStack, debuffDuration, debuffExpires, debuffCaster, debuffSpellID);
					if (ProcessAurasForNameplate_Filter(false, debuffName, debuffCaster, debuffSpellID)) then
						if (nameplateAuras[frame][debuffName] == nil or nameplateAuras[frame][debuffName].expires < debuffExpires or nameplateAuras[frame][debuffName].stacks ~= debuffStack) then
							nameplateAuras[frame][debuffName] = {
								["duration"] = debuffDuration ~= 0 and debuffDuration or 4000000000,
								["expires"] = debuffExpires ~= 0 and debuffExpires or 4000000000,
								["stacks"] = debuffStack,
								["spellID"] = debuffSpellID,
								["type"] = "debuff",
								["dispelType"] = debuffDispelType,
							};
						end
					end
				end
				if (buffName == nil and debuffName == nil) then
					break;
				end
			end
		end
		UpdateNameplate(frame);
	end
	
	function UpdateNameplate(frame)
		local counter = 1;
		local totalWidth = 0;
		local iconResized = false;
		if (nameplateAuras[frame]) then
			local currentTime = GetTime();
			if (nameplateAuras[frame].sortedAuras ~= nil) then
				wipe(nameplateAuras[frame].sortedAuras);
			end
			nameplateAuras[frame].sortedAuras = SortAurasForNameplate(nameplateAuras[frame]);
			for _, spellInfo in pairs(nameplateAuras[frame].sortedAuras) do
				local spellName = SpellNamesCache[spellInfo.spellID];
				local duration = spellInfo.duration;
				local last = spellInfo.expires - currentTime;
				if (last > 0) then
					if (counter > frame.NAurasIconsCount) then
						AllocateIcon(frame, totalWidth);
					end
					local icon = frame.NAurasIcons[counter];
					if (icon.spellID ~= spellName) then
						icon:SetTexture(TextureCache[spellInfo.spellID]);
						icon.spellID = spellName;
					end
					UpdateNameplate_SetCooldown(icon, last, spellInfo);
					-- // stacks
					UpdateNameplate_SetStacks(icon, spellInfo);
					-- // border
					UpdateNameplate_SetBorder(icon, spellInfo);
					-- // icon size
					local normalSize = SpellIconSizesCache[spellName] or db.DefaultIconSize;
					if (normalSize ~= icon.size or iconResized) then
						icon.size = normalSize;
						ResizeIcon(icon, icon.size, totalWidth);
						iconResized = true;
					end
					if (not icon.shown) then
						ShowCDIcon(icon);
					end
					totalWidth = totalWidth + icon.size + db.IconSpacing;
					counter = counter + 1;
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
		if (db.HideBlizzardFrames and frame.UnitFrame.BuffFrame ~= nil) then
			frame.UnitFrame.BuffFrame:Hide();
		end
	end
	
	function UpdateNameplate_SetCooldown(icon, last, spellInfo)
		if (db.TimerStyle == CONST_TIMER_STYLES[1] or db.TimerStyle == CONST_TIMER_STYLES[4]) then
			if (last > 3600) then
				icon.cooldown:SetText("");
			elseif (last >= 60) then
				icon.cooldown:SetText(math_floor(last/60).."m");
			elseif (last >= 10 or not db.DisplayTenthsOfSeconds) then
				icon.cooldown:SetText(string_format("%.0f", last));
			else
				icon.cooldown:SetText(string_format("%.1f", last));
			end
			if (last >= 60) then
				icon.cooldown:SetTextColor(unpack(db.TimerTextLongerColor));
			elseif (last >= 5) then
				icon.cooldown:SetTextColor(unpack(db.TimerTextUnderMinuteColor));
			else
				icon.cooldown:SetTextColor(unpack(db.TimerTextSoonToExpireColor));
			end
			if (db.TimerStyle == CONST_TIMER_STYLES[4]) then
				icon:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
			end
		elseif (db.TimerStyle == CONST_TIMER_STYLES[3] or db.TimerStyle == CONST_TIMER_STYLES[2]) then
			icon:SetCooldown(spellInfo.expires - spellInfo.duration, spellInfo.duration);
		end
	end
	
	function UpdateNameplate_SetStacks(icon, spellInfo)
		if (icon.stackcount ~= spellInfo.stacks) then
			if (spellInfo.stacks > 1) then
				icon.stacks:SetText(spellInfo.stacks);
			else
				icon.stacks:SetText("");
			end
			icon.stackcount = spellInfo.stacks;
		end
	end
	
	function UpdateNameplate_SetBorder(icon, spellInfo)
		if (db.ShowBuffBorders and spellInfo.type == "buff") then
			if (icon.borderState ~= spellInfo.type) then
				icon.border:SetVertexColor(unpack(db.BuffBordersColor));
				icon.border:Show();
				icon.borderState = spellInfo.type;
			end
		elseif (db.ShowDebuffBorders and spellInfo.type == "debuff") then
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
	
	function HideCDIcon(icon)
		icon.border:Hide();
		icon.borderState = nil;
		icon.cooldown:Hide();
		icon.stacks:Hide();
		icon:Hide();
		icon.shown = false;
		icon.spellID = -1;
		icon.stackcount = -1;
		icon.size = -1;
	end
	
	function ShowCDIcon(icon)
		icon.cooldown:Show();
		icon.stacks:Show();
		icon:Show();
		icon.shown = true;
	end
	
	function ResizeIcon(icon, size, widthAlreadyUsed)
		icon:SetWidth(size);
		icon:SetHeight(size);
		icon:SetPoint(db.IconAnchor, icon:GetParent(), widthAlreadyUsed, 0);
		icon.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil((size - size / 2) * db.FontScale), "OUTLINE");
		icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((size / 4) * db.StacksFontScale), "OUTLINE");
	end
	
	function Nameplates_OnFontChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					if (icon.shown) then
						icon.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil((icon.size - icon.size / 2) * db.FontScale), "OUTLINE");
						icon.stacks:SetFont(SML:Fetch("font", db.StacksFont), math_ceil((icon.size / 4) * db.StacksFontScale), "OUTLINE");
					end
				end
			end
		end
	end
	
	function Nameplates_OnDefaultIconSizeOrOffsetChanged(oldDefaultIconSize)
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				nameplate.NAurasFrame:SetPoint("CENTER", nameplate, db.IconXOffset, db.IconYOffset);
				local width = 0;
				for _, icon in pairs(nameplate.NAurasIcons) do
					if (icon.shown == true) then
						if (icon.size == oldDefaultIconSize) then
							icon.size = db.DefaultIconSize;
						end
						ResizeIcon(icon, icon.size, width);
						width = width + icon.size + db.IconSpacing;
					end
				end
				width = width - db.IconSpacing; -- // because we don't need last spacing
				nameplate.NAurasFrame:SetWidth(width);
			end
		end
	end
	
	function Nameplates_OnSortModeChanged()
		for nameplate in pairs(NameplatesVisible) do
			if (nameplate.NAurasFrame and nameplateAuras[nameplate] ~= nil) then
				UpdateNameplate(nameplate);
			end
		end
	end
	
	function Nameplates_OnTextPositionChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					icon.cooldown:ClearAllPoints();
					icon.cooldown:SetPoint(db.TimerTextAnchor, icon, db.TimerTextXOffset, db.TimerTextYOffset);
					icon.stacks:ClearAllPoints();
					icon.stacks:SetPoint(db.StacksTextAnchor, icon, db.StacksTextXOffset, db.StacksTextYOffset);
				end
			end
		end
	end
	
	function Nameplates_OnIconAnchorChanged()
		for nameplate in pairs(Nameplates) do
			if (nameplate.NAurasFrame) then
				for _, icon in pairs(nameplate.NAurasIcons) do
					icon:ClearAllPoints();
					icon:SetPoint(db.IconAnchor, nameplate.NAurasFrame, 0, 0);
				end
			end
		end
		UpdateAllNameplates(true);
	end
	
	function SortAurasForNameplate(auras)
		local t = { };
		for _, spellInfo in pairs(auras) do
			if (spellInfo.spellID ~= nil) then
				table.insert(t, spellInfo);
			end
		end
		if (db.SortMode == CONST_SORT_MODES[1]) then
			-- // do nothing
		elseif (db.SortMode == CONST_SORT_MODES[2]) then
			table.sort(t, function(item1, item2) return item1.expires < item2.expires end);
		elseif (db.SortMode == CONST_SORT_MODES[3]) then
			table.sort(t, function(item1, item2) return item1.expires > item2.expires end);
		elseif (db.SortMode == CONST_SORT_MODES[4]) then
			table.sort(t, function(item1, item2) return SpellIconSizesCache[SpellNamesCache[item1.spellID]] < SpellIconSizesCache[SpellNamesCache[item2.spellID]] end);
		elseif (db.SortMode == CONST_SORT_MODES[5]) then
			table.sort(t, function(item1, item2) return SpellIconSizesCache[SpellNamesCache[item1.spellID]] > SpellIconSizesCache[SpellNamesCache[item2.spellID]] end);
		elseif (db.SortMode == CONST_SORT_MODES[6]) then
			table.sort(t, function(item1, item2)
				if (item1.type ~= item2.type) then
					return (item1.type == "debuff") and true or false;
				end
				if (item1.type == "debuff") then
					return item1.expires < item2.expires;
				else
					return item1.expires > item2.expires;
				end
			end);
		end
		return t;
	end
	
end

-------------------------------------------------------------------------------------------------
----- OnUpdates
-------------------------------------------------------------------------------------------------
do

	function OnUpdate()
		local currentTime = GetTime();
		for frame in pairs(NameplatesVisible) do
			local counter = 1;
			if (nameplateAuras[frame]) then
				for _, spellInfo in pairs(nameplateAuras[frame].sortedAuras) do
					local duration = spellInfo.duration;
					local last = spellInfo.expires - currentTime;
					if (last > 0) then
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

-------------------------------------------------------------------------------------------------
----- Events
-------------------------------------------------------------------------------------------------
do
	
	function PLAYER_ENTERING_WORLD()
		if (OnStartup) then
			OnStartup();
		end
		for nameplate in pairs(nameplateAuras) do
			wipe(nameplateAuras[nameplate]);
		end
	end

	function NAME_PLATE_UNIT_ADDED(...)
		local unitID = ...;
		local nameplate = C_NamePlate.GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = true;
		if (not Nameplates[nameplate]) then
			nameplate.NAurasIcons = {};
			nameplate.NAurasIconsCount = 0;
			Nameplates[nameplate] = true;
			nameplateAuras[nameplate] = {};
		end
		ProcessAurasForNameplate(nameplate, unitID);
		if (db.FullOpacityAlways and nameplate.NAurasFrame) then
			nameplate.NAurasFrame:Show();
		end
	end
	
	function NAME_PLATE_UNIT_REMOVED(...)
		local unitID = ...;
		local nameplate = C_NamePlate.GetNamePlateForUnit(unitID);
		NameplatesVisible[nameplate] = nil;
		if (nameplateAuras[nameplate] ~= nil) then
			wipe(nameplateAuras[nameplate]);
		end
		if (db.FullOpacityAlways and nameplate.NAurasFrame) then
			nameplate.NAurasFrame:Hide();
		end
	end
	
	function UNIT_AURA(...)
		local unitID = ...;
		local nameplate = C_NamePlate.GetNamePlateForUnit(unitID);
		if (nameplate ~= nil and nameplateAuras[nameplate] ~= nil) then
			ProcessAurasForNameplate(nameplate, unitID);
			if (db.FullOpacityAlways and nameplate.NAurasFrame) then
				nameplate.NAurasFrame:Show();
			end
		end
	end
		
end

-------------------------------------------------------------------------------------------------
----- GUI
-------------------------------------------------------------------------------------------------
do

	local function PopupReloadUI()
		if (StaticPopupDialogs["NAURAS_MSG_RELOAD"] == nil) then
			StaticPopupDialogs["NAURAS_MSG_RELOAD"] = {
				text = "Please reload UI to apply changes",
				button1 = "Reload UI",
				OnAccept = function() ReloadUI(); end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			};
		end
		StaticPopup_Show("NAURAS_MSG_RELOAD");
	end

	local function GUICreateCheckBox(x, y, text, func, publicName)
		local checkBox = CreateFrame("CheckButton", publicName, GUIFrame);
		checkBox:SetHeight(20);
		checkBox:SetWidth(20);
		checkBox:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", x, y);
		checkBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
		checkBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
		checkBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
		checkBox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
		checkBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
		checkBox.Text = checkBox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		checkBox.Text:SetPoint("LEFT", 20, 0);
		checkBox.Text:SetText(text);
		checkBox:EnableMouse(true);
		checkBox:SetScript("OnClick", func);
		checkBox:Hide();
		return checkBox;
	end
	
	local function GUICreateCheckBoxWithColorPicker(publicName, x, y, text, checkedChangedCallback)
		local checkBox = GUICreateCheckBox(x, y, text, checkedChangedCallback, publicName);
		checkBox.Text:SetPoint("LEFT", 40, 0);
		
		checkBox.ColorButton = CreateFrame("Button", nil, checkBox);
		checkBox.ColorButton:SetPoint("LEFT", 19, 0);
		checkBox.ColorButton:SetWidth(20);
		checkBox.ColorButton:SetHeight(20);
		checkBox.ColorButton:Hide();

		checkBox.ColorButton:EnableMouse(true);

		checkBox.ColorButton.colorSwatch = checkBox.ColorButton:CreateTexture(nil, "OVERLAY");
		checkBox.ColorButton.colorSwatch:SetWidth(19);
		checkBox.ColorButton.colorSwatch:SetHeight(19);
		checkBox.ColorButton.colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
		checkBox.ColorButton.colorSwatch:SetPoint("LEFT");
		checkBox.ColorButton.SetColor = checkBox.ColorButton.colorSwatch.SetVertexColor;

		checkBox.ColorButton.texture = checkBox.ColorButton:CreateTexture(nil, "BACKGROUND");
		checkBox.ColorButton.texture:SetWidth(16);
		checkBox.ColorButton.texture:SetHeight(16);
		checkBox.ColorButton.texture:SetTexture(1, 1, 1);
		checkBox.ColorButton.texture:SetPoint("CENTER", checkBox.ColorButton.colorSwatch);
		checkBox.ColorButton.texture:Show();

		checkBox.ColorButton.checkers = checkBox.ColorButton:CreateTexture(nil, "BACKGROUND");
		checkBox.ColorButton.checkers:SetWidth(14);
		checkBox.ColorButton.checkers:SetHeight(14);
		checkBox.ColorButton.checkers:SetTexture("Tileset\\Generic\\Checkers");
		checkBox.ColorButton.checkers:SetTexCoord(.25, 0, 0.5, .25);
		checkBox.ColorButton.checkers:SetDesaturated(true);
		checkBox.ColorButton.checkers:SetVertexColor(1, 1, 1, 0.75);
		checkBox.ColorButton.checkers:SetPoint("CENTER", checkBox.ColorButton.colorSwatch);
		checkBox.ColorButton.checkers:Show();
		
		checkBox:HookScript("OnShow", function(self) self.ColorButton:Show(); end);
		checkBox:HookScript("OnHide", function(self) self.ColorButton:Hide(); end);
		
		return checkBox;
	end
	
	local function GUICreateCmbboxTextureText(publicName, parent, x, y)
		local dropdown = CreateFrame("Frame", publicName.."_Cmbbox", parent, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdown, 100);
		dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);
		
		local text = dropdown:CreateFontString(publicName.."_Text", "ARTWORK", "GameFontNormalSmall");
		text:SetPoint("LEFT", 165, 0);
		
		local button = CreateFrame("button", publicName.."_Button", dropdown, "SecureActionButtonTemplate");
		button:SetHeight(20);
		button:SetWidth(20);
		button:SetPoint("RIGHT", 10, 0);
		button.texture = button:CreateTexture();
		button.texture:SetAllPoints(button);
		button:EnableMouse(true);
		
		return dropdown, text, button;
	end
	
	local function GUICreateColorPicker(publicName, parent, x, y, text)
		local colorButton = CreateFrame("Button", publicName, parent);
		colorButton:SetPoint("TOPLEFT", x, y);
		colorButton:SetWidth(20);
		colorButton:SetHeight(20);
		colorButton:Hide();
		colorButton:EnableMouse(true);

		colorButton.colorSwatch = colorButton:CreateTexture(nil, "OVERLAY");
		colorButton.colorSwatch:SetWidth(19);
		colorButton.colorSwatch:SetHeight(19);
		colorButton.colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
		colorButton.colorSwatch:SetPoint("LEFT");

		colorButton.texture = colorButton:CreateTexture(nil, "BACKGROUND");
		colorButton.texture:SetWidth(16);
		colorButton.texture:SetHeight(16);
		colorButton.texture:SetTexture(1, 1, 1);
		colorButton.texture:SetPoint("CENTER", colorButton.colorSwatch);
		colorButton.texture:Show();

		colorButton.checkers = colorButton:CreateTexture(nil, "BACKGROUND");
		colorButton.checkers:SetWidth(14);
		colorButton.checkers:SetHeight(14);
		colorButton.checkers:SetTexture("Tileset\\Generic\\Checkers");
		colorButton.checkers:SetTexCoord(.25, 0, 0.5, .25);
		colorButton.checkers:SetDesaturated(true);
		colorButton.checkers:SetVertexColor(1, 1, 1, 0.75);
		colorButton.checkers:SetPoint("CENTER", colorButton.colorSwatch);
		colorButton.checkers:Show();
		
		colorButton.text = colorButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		colorButton.text:SetPoint("LEFT", 22, 0);
		colorButton.text:SetText(text);
		return colorButton;
	end
	
	function ShowGUI()
		if (not InCombatLockdown()) then
			if (not GUIFrame) then
				InitializeGUI();
			end
			GUIFrame:Show();
			OnGUICategoryClick(GUIFrame.CategoryButtons[1]);
		else
			Print(L["Options are not available in combat!"]);
		end
	end
	
	function InitializeGUI()
		GUIFrame = CreateFrame("Frame", "NAuras_GUIFrame", UIParent);
		GUIFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
		GUIFrame:SetScript("OnEvent", function() GUIFrame:Hide(); end);
		GUIFrame:SetHeight(400);
		GUIFrame:SetWidth(530);
		GUIFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80);
		GUIFrame:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 } 
		});
		GUIFrame:SetBackdropColor(0.25, 0.24, 0.32, 1);
		GUIFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);
		GUIFrame:EnableMouse(1);
		GUIFrame:SetMovable(1);
		GUIFrame:SetFrameStrata("DIALOG");
		GUIFrame:SetToplevel(1);
		GUIFrame:SetClampedToScreen(1);
		GUIFrame:SetScript("OnMouseDown", function() GUIFrame:StartMoving(); end);
		GUIFrame:SetScript("OnMouseUp", function() GUIFrame:StopMovingOrSizing(); end);
		GUIFrame:Hide();
		
		GUIFrame.SpellSelector = CreateSpellSelector();
		
		GUIFrame.CategoryButtons = {};
		GUIFrame.ActiveCategory = 1;
		
		local header = GUIFrame:CreateFontString("NAuras_GUIHeader", "ARTWORK", "GameFontHighlight");
		header:SetFont(GameFontNormal:GetFont(), 22, "THICKOUTLINE");
		header:SetPoint("CENTER", GUIFrame, "CENTER", 0, 210);
		header:SetText("NameplateAuras");
		
		GUIFrame.outline = CreateFrame("Frame", "NAuras_GUI_GUIFrame_outline", GUIFrame);
		GUIFrame.outline:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		GUIFrame.outline:SetBackdropColor(0.1, 0.1, 0.2, 1);
		GUIFrame.outline:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		GUIFrame.outline:SetPoint("TOPLEFT", 12, -12);
		GUIFrame.outline:SetPoint("BOTTOMLEFT", 12, 12);
		GUIFrame.outline:SetWidth(130);
		
		local closeButton = CreateFrame("Button", "NAuras_GUICloseButton", GUIFrame, "UIPanelButtonTemplate");
		closeButton:SetWidth(24);
		closeButton:SetHeight(24);
		closeButton:SetPoint("TOPRIGHT", 0, 22);
		closeButton:SetScript("OnClick", function() GUIFrame:Hide(); end);
		closeButton.text = closeButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		closeButton.text:SetPoint("CENTER", closeButton, "CENTER", 1, -1);
		closeButton.text:SetText("X");
		
		local scrollFramesTipText = GUIFrame:CreateFontString("NAuras_GUIScrollFramesTipText", "OVERLAY", "GameFontNormal");
		scrollFramesTipText:SetPoint("CENTER", GUIFrame, "LEFT", 300, 130);
		scrollFramesTipText:SetText(L["Click on icon to enable/disable tracking"]);
		
		GUIFrame.Categories = {};
		GUIFrame.OnDBChangedHandlers = {};
		table.insert(GUIFrame.OnDBChangedHandlers, function() OnGUICategoryClick(GUIFrame.CategoryButtons[1]); end);
		
		local categories = { L["General"], L["Profiles"], "Text", "Icon borders", "Spells" };
		for index, value in pairs(categories) do
			local b = CreateGUICategory();
			b.index = index;
			b.text:SetText(value);
			if (index == 1) then
				b:LockHighlight();
				b.text:SetTextColor(1, 1, 1);
				b:SetPoint("TOPLEFT", GUIFrame.outline, "TOPLEFT", 5, -6);
			elseif (index == #categories) then
				b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 26);
			else
				b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 6);
			end
			
			GUIFrame.Categories[index] = {};
			
			if (index == 1) then
				GUICategory_1(index, value);
			elseif (index == 2) then
				GUICategory_2(index, value);
			elseif (index == 3) then
				GUICategory_Fonts(index, value);
			elseif (index == 4) then
				GUICategory_Borders(index, value);
			elseif (index == 5) then
				GUICategory_4(index, value);
			else
				
			end
		end
	end

	function CreateSpellSelector()
		local scrollAreaBackground = CreateFrame("Frame", "NAuras.SpellSelector", GUIFrame);
		scrollAreaBackground:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -60);
		scrollAreaBackground:SetPoint("BOTTOMRIGHT", GUIFrame, "BOTTOMRIGHT", -30, 15);
		scrollAreaBackground:SetBackdrop({
			bgFile = 	"Interface\\AddOns\\NameplateAuras\\media\\Smudge.tga",
			edgeFile = 	"Interface\\AddOns\\NameplateAuras\\media\\Border",
			tile = true, edgeSize = 3, tileSize = 1,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		});
		local bRed, bGreen, bBlue = GUIFrame:GetBackdropColor();
		scrollAreaBackground:SetBackdropColor(bRed, bGreen, bBlue, 0.8)
		scrollAreaBackground:SetBackdropBorderColor(0.3, 0.3, 0.5, 1);
		scrollAreaBackground:Hide();
		
		scrollAreaBackground.scrollArea = CreateFrame("ScrollFrame", "NAuras.SpellSelector.ScrollArea", scrollAreaBackground, "UIPanelScrollFrameTemplate");
		scrollAreaBackground.scrollArea:SetPoint("TOPLEFT", scrollAreaBackground, "TOPLEFT", 5, -5);
		scrollAreaBackground.scrollArea:SetPoint("BOTTOMRIGHT", scrollAreaBackground, "BOTTOMRIGHT", -5, 5);
		scrollAreaBackground.scrollArea:Show();
		
		local scrollAreaChildFrame = CreateFrame("Frame", "NAuras.SpellSelector.ScrollArea.Child", scrollAreaBackground.scrollArea);
		scrollAreaBackground.scrollArea:SetScrollChild(scrollAreaChildFrame);
		scrollAreaChildFrame:SetPoint("CENTER", GUIFrame, "CENTER", 0, 1);
		scrollAreaChildFrame:SetWidth(288);
		scrollAreaChildFrame:SetHeight(288);
		
		scrollAreaBackground.buttons = { };
		
		local function GetButton(counter)
			if (scrollAreaBackground.buttons[counter] == nil) then
				local button = GUICreateButton("NAuras.SpellSelector.Button" .. tostring(counter), scrollAreaChildFrame, "");
				button:SetWidth(280);
				button:SetHeight(20);
				button:SetPoint("TOPLEFT", 38, -counter * 22 + 15);
				button.Icon = button:CreateTexture();
				button.Icon:SetPoint("RIGHT", button, "LEFT", -3, 0);
				button.Icon:SetWidth(20);
				button.Icon:SetHeight(20);
				button:Hide();
				scrollAreaBackground.buttons[counter] = button;
				--print("New button is created: " .. tostring(counter));
				return button;
				--button:SetScript("OnClick", function() scrollAreaBackground.selectedItem =  end);
			else
				return scrollAreaBackground.buttons[counter];
			end
		end
		
		scrollAreaBackground.SetList = function(t)
			for _, button in pairs(scrollAreaBackground.buttons) do
				button:Hide();
			end
			local counter = 1;
			for index, value in pairs(t) do
				local button = GetButton(counter);
				button.Text:SetText(value.text);
				button.Icon:SetTexture(value.icon);
				button:SetScript("OnClick", function()
					value:func();
					scrollAreaBackground:Hide();
				end);
				button:Show();
				counter = counter + 1;
			end
		end
		
		scrollAreaBackground.GetButtonByText = function(text)
			for _, button in pairs(scrollAreaBackground.buttons) do
				if (button.Text:GetText() == text) then
					return button;
				end
			end
			return nil;
		end
		
		return scrollAreaBackground;
	end
	
	function GUICategory_1(index, value)
		
		-- // sliderIconSize
		do
		
			local sliderIconSize = GUICreateSlider(GUIFrame, 160, -30, 155, "NAuras.GUI.Cat1.SliderIconSize");
			sliderIconSize.label:SetText("Default icon size");
			sliderIconSize.slider:SetValueStep(1);
			sliderIconSize.slider:SetMinMaxValues(1, CONST_MAX_ICON_SIZE);
			sliderIconSize.slider:SetValue(db.DefaultIconSize);
			sliderIconSize.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconSize.editbox:SetText(tostring(math_ceil(value)));
				for spellID, spellInfo in pairs(db.CustomSpells2) do
					if (spellInfo.iconSize == db.DefaultIconSize) then
						db.CustomSpells2[spellID].iconSize = math_ceil(value);
						UpdateSpellCachesFromDB(spellID);
					end
				end
				local oldSize = db.DefaultIconSize;
				db.DefaultIconSize = math_ceil(value);
				Nameplates_OnDefaultIconSizeOrOffsetChanged(oldSize);
			end);
			sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize));
			sliderIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconSize.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconSize.editbox:GetText());
					if (v == nil) then
						sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize));
						msg(L["Value must be a number"]);
					else
						if (v > CONST_MAX_ICON_SIZE) then
							v = CONST_MAX_ICON_SIZE;
						end
						if (v < 1) then
							v = 1;
						end
						sliderIconSize.slider:SetValue(v);
					end
					sliderIconSize.editbox:ClearFocus();
				end
			end);
			sliderIconSize.lowtext:SetText("1");
			sliderIconSize.hightext:SetText(tostring(CONST_MAX_ICON_SIZE));
			table.insert(GUIFrame.Categories[index], sliderIconSize);
			table.insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSize.slider:SetValue(db.DefaultIconSize); sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize)); end);
		
		end
		
		-- // sliderIconSpacing
		do
			local minValue, maxValue = 0, 50;
			local sliderIconSpacing = GUICreateSlider(GUIFrame, 345, -30, 155, "NAuras.GUI.Cat1.SliderIconSpacing");
			sliderIconSpacing.label:SetText("Space between icons");
			sliderIconSpacing.slider:SetValueStep(1);
			sliderIconSpacing.slider:SetMinMaxValues(minValue, maxValue);
			sliderIconSpacing.slider:SetValue(db.IconSpacing);
			sliderIconSpacing.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconSpacing.editbox:SetText(tostring(math_ceil(value)));
				db.IconSpacing = math_ceil(value);
				UpdateAllNameplates(true);
			end);
			sliderIconSpacing.editbox:SetText(tostring(db.IconSpacing));
			sliderIconSpacing.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconSpacing.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconSpacing.editbox:GetText());
					if (v == nil) then
						sliderIconSpacing.editbox:SetText(tostring(db.IconSpacing));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderIconSpacing.slider:SetValue(v);
					end
					sliderIconSpacing.editbox:ClearFocus();
				end
			end);
			sliderIconSpacing.lowtext:SetText(tostring(minValue));
			sliderIconSpacing.hightext:SetText(tostring(maxValue));
			table.insert(GUIFrame.Categories[index], sliderIconSpacing);
			table.insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSpacing.slider:SetValue(db.IconSpacing); sliderIconSpacing.editbox:SetText(tostring(db.IconSpacing)); end);
		
		end
		
		-- // sliderIconXOffset
		do
		
			local sliderIconXOffset = GUICreateSlider(GUIFrame, 160, -90, 155, "NAuras_GUIGeneralSliderIconXOffset");
			sliderIconXOffset.label:SetText(L["Icon X-coord offset"]);
			sliderIconXOffset.slider:SetValueStep(1);
			sliderIconXOffset.slider:SetMinMaxValues(-200, 200);
			sliderIconXOffset.slider:SetValue(db.IconXOffset);
			sliderIconXOffset.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconXOffset.editbox:SetText(tostring(math_ceil(value)));
				db.IconXOffset = math_ceil(value);
				Nameplates_OnDefaultIconSizeOrOffsetChanged(db.DefaultIconSize);
			end);
			sliderIconXOffset.editbox:SetText(tostring(db.IconXOffset));
			sliderIconXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconXOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconXOffset.editbox:GetText());
					if (v == nil) then
						sliderIconXOffset.editbox:SetText(tostring(db.IconXOffset));
						Print(L["Value must be a number"]);
					else
						if (v > 200) then
							v = 200;
						end
						if (v < -200) then
							v = -200;
						end
						sliderIconXOffset.slider:SetValue(v);
					end
					sliderIconXOffset.editbox:ClearFocus();
				end
			end);
			sliderIconXOffset.lowtext:SetText("-200");
			sliderIconXOffset.hightext:SetText("200");
			table.insert(GUIFrame.Categories[index], sliderIconXOffset);
			table.insert(GUIFrame.OnDBChangedHandlers, function() sliderIconXOffset.slider:SetValue(db.IconXOffset); sliderIconXOffset.editbox:SetText(tostring(db.IconXOffset)); end);
		
		end
	
		-- // sliderIconYOffset
		do
		
			local sliderIconYOffset = GUICreateSlider(GUIFrame, 345, -90, 155, "NAuras_GUIGeneralSliderIconYOffset");
			sliderIconYOffset.label:SetText(L["Icon Y-coord offset"]);
			sliderIconYOffset.slider:SetValueStep(1);
			sliderIconYOffset.slider:SetMinMaxValues(-200, 200);
			sliderIconYOffset.slider:SetValue(db.IconYOffset);
			sliderIconYOffset.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconYOffset.editbox:SetText(tostring(math_ceil(value)));
				db.IconYOffset = math_ceil(value);
				Nameplates_OnDefaultIconSizeOrOffsetChanged(db.DefaultIconSize);
			end);
			sliderIconYOffset.editbox:SetText(tostring(db.IconYOffset));
			sliderIconYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconYOffset.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconYOffset.editbox:GetText());
					if (v == nil) then
						sliderIconYOffset.editbox:SetText(tostring(db.IconYOffset));
						Print(L["Value must be a number"]);
					else
						if (v > 200) then
							v = 200;
						end
						if (v < -200) then
							v = -200;
						end
						sliderIconYOffset.slider:SetValue(v);
					end
					sliderIconYOffset.editbox:ClearFocus();
				end
			end);
			sliderIconYOffset.lowtext:SetText("-200");
			sliderIconYOffset.hightext:SetText("200");
			table.insert(GUIFrame.Categories[index], sliderIconYOffset);
			table.insert(GUIFrame.OnDBChangedHandlers, function() sliderIconYOffset.slider:SetValue(db.IconYOffset); sliderIconYOffset.editbox:SetText(tostring(db.IconYOffset)); end);
		
		end
		
		
		local checkBoxFullOpacityAlways = GUICreateCheckBox(160, -160, "Always display icons at full opacity (ReloadUI is required)", function(this)
			db.FullOpacityAlways = this:GetChecked();
			PopupReloadUI();
		end, "NAuras_GUI_General_CheckBoxFullOpacityAlways");
		checkBoxFullOpacityAlways:SetChecked(db.FullOpacityAlways);
		table.insert(GUIFrame.Categories[index], checkBoxFullOpacityAlways);
		table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxFullOpacityAlways:SetChecked(db.FullOpacityAlways); end);
		
		local checkBoxHideBlizzardFrames = GUICreateCheckBox(160, -180, "Hide Blizzard's aura frames (Reload UI is required)", function(this)
			db.HideBlizzardFrames = this:GetChecked();
			PopupReloadUI();
		end, "NAuras.GUI.Cat1.CheckBoxHideBlizzardFrames");
		checkBoxHideBlizzardFrames:SetChecked(db.HideBlizzardFrames);
		table.insert(GUIFrame.Categories[index], checkBoxHideBlizzardFrames);
		table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxHideBlizzardFrames:SetChecked(db.HideBlizzardFrames); end);
		
		local checkBoxDisplayTenthsOfSeconds = GUICreateCheckBox(160, -200, "Display tenths of seconds", function(this)
			db.DisplayTenthsOfSeconds = this:GetChecked();
		end, "NAuras.GUI.Cat1.CheckBoxDisplayTenthsOfSeconds");
		checkBoxDisplayTenthsOfSeconds:SetChecked(db.DisplayTenthsOfSeconds);
		table.insert(GUIFrame.Categories[index], checkBoxDisplayTenthsOfSeconds);
		table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxDisplayTenthsOfSeconds:SetChecked(db.DisplayTenthsOfSeconds); end);
			
		-- // checkBoxShowAurasOnPlayerNameplate
		do
		
			local checkBoxShowAurasOnPlayerNameplate = GUICreateCheckBox(160, -220, "Display auras on player's nameplate", function(this)
				db.ShowAurasOnPlayerNameplate = this:GetChecked();
			end, "NAuras.GUI.Cat1.CheckBoxShowAurasOnPlayerNameplate");
			checkBoxShowAurasOnPlayerNameplate:SetChecked(db.ShowAurasOnPlayerNameplate);
			table.insert(GUIFrame.Categories[index], checkBoxShowAurasOnPlayerNameplate);
			table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowAurasOnPlayerNameplate:SetChecked(db.ShowAurasOnPlayerNameplate); end);
		
		end
			
		-- // checkBoxShowMyAuras
		do
		
			local checkBoxShowMyAuras = GUICreateCheckBox(160, -240, "Always show auras cast by myself", function(this)
				db.AlwaysShowMyAuras = this:GetChecked();
				UpdateAllNameplates(false);
			end, "NAuras.GUI.Cat1.CheckBoxShowMyAuras");
			checkBoxShowMyAuras:SetChecked(db.AlwaysShowMyAuras);
			table.insert(GUIFrame.Categories[index], checkBoxShowMyAuras);
			table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowMyAuras:SetChecked(db.AlwaysShowMyAuras); end);
		
		end
			
		-- // dropdownTimerStyle
		do
		
			local dropdownTimerStyle = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownTimerStyle", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownTimerStyle, 300);
			dropdownTimerStyle:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -275);
			local info = {};
			dropdownTimerStyle.initialize = function()
				wipe(info);
				for _, timerStyle in pairs(CONST_TIMER_STYLES) do
					info.text = CONST_TIMER_STYLES_LOCALIZATION[timerStyle];
					info.value = timerStyle;
					info.func = function(self)
						db.TimerStyle = self.value;
						_G[dropdownTimerStyle:GetName().."Text"]:SetText(self:GetText());
						PopupReloadUI();
					end
					info.checked = (db.TimerStyle == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownTimerStyle:GetName().."Text"]:SetText(CONST_TIMER_STYLES_LOCALIZATION[db.TimerStyle]);
			dropdownTimerStyle.text = dropdownTimerStyle:CreateFontString("NAuras.GUI.Cat1.DropdownTimerStyle.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownTimerStyle.text:SetPoint("LEFT", 20, 15);
			dropdownTimerStyle.text:SetText("Timer style:");
			table.insert(GUIFrame.Categories[index], dropdownTimerStyle);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerStyle:GetName().."Text"]:SetText(CONST_TIMER_STYLES_LOCALIZATION[db.TimerStyle]); end);
			
		end
		
		-- // dropdownIconAnchor
		do
			
			local anchors = { "TOPLEFT", "LEFT", "BOTTOMLEFT" };
			local dropdownIconAnchor = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownIconAnchor", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownIconAnchor, 300);
			dropdownIconAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -310);
			local info = {};
			dropdownIconAnchor.initialize = function()
				wipe(info);
				for _, anchor in pairs(anchors) do
					info.text = anchor;
					info.value = anchor;
					info.func = function(self)
						db.IconAnchor = self.value;
						_G[dropdownIconAnchor:GetName().."Text"]:SetText(self:GetText());
						Nameplates_OnIconAnchorChanged();
					end
					info.checked = (db.IconAnchor == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownIconAnchor:GetName().."Text"]:SetText(db.IconAnchor);
			dropdownIconAnchor.text = dropdownIconAnchor:CreateFontString("NAuras.GUI.Cat1.DropdownIconAnchor.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownIconAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownIconAnchor.text:SetText("Icon anchor:");
			table.insert(GUIFrame.Categories[index], dropdownIconAnchor);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownIconAnchor:GetName().."Text"]:SetText(db.IconAnchor); end);
		
		end
		
		-- // dropdownSortMode
		do
		
			local dropdownSortMode = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownSortMode", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownSortMode, 300);
			dropdownSortMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -345);
			local info = {};
			dropdownSortMode.initialize = function()
				wipe(info);
				for _, sortMode in pairs(CONST_SORT_MODES) do
					info.text = CONST_SORT_MODES_LOCALIZATION[sortMode];
					info.value = sortMode;
					info.func = function(self)
						db.SortMode = self.value;
						_G[dropdownSortMode:GetName().."Text"]:SetText(self:GetText());
						Nameplates_OnSortModeChanged();
					end
					info.checked = (db.SortMode == info.value);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownSortMode:GetName().."Text"]:SetText(CONST_SORT_MODES_LOCALIZATION[db.SortMode]);
			dropdownSortMode.text = dropdownSortMode:CreateFontString("NAuras.GUI.Cat1.DropdownSortMode.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownSortMode.text:SetPoint("LEFT", 20, 15);
			dropdownSortMode.text:SetText("Sort mode:");
			table.insert(GUIFrame.Categories[index], dropdownSortMode);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownSortMode:GetName().."Text"]:SetText(CONST_SORT_MODES_LOCALIZATION[db.SortMode]); end);
			
		end
		
	end
	
	function GUICategory_2(index, value)
		local button = GUICreateButton("NAuras.GUI.Profiles.MainButton", GUIFrame, "Open profiles dialog");
		button:SetWidth(140);
		button:SetHeight(40);
		button:SetPoint("CENTER", GUIFrame, "CENTER", 70, 0);
		button:SetScript("OnClick", function(self, ...)
			InterfaceOptionsFrame_OpenToCategory(ProfileOptionsFrame);
			GUIFrame:Hide();
		end);
		table.insert(GUIFrame.Categories[index], button);
	end
	
	function GUICategory_Fonts(index, value)
		
		local textAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
		local timerTextArea, stacksTextArea;
		
		-- // timerTextArea
		do
		
			timerTextArea = CreateFrame("Frame", "NAuras.GUI.Fonts.TimerTextArea", GUIFrame);
			timerTextArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			timerTextArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			timerTextArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			timerTextArea:SetPoint("TOPLEFT", 150, -12);
			timerTextArea:SetPoint("LEFT", 150, 95);
			timerTextArea:SetWidth(360);
			table.insert(GUIFrame.Categories[index], timerTextArea);
		
		end
		
		-- // stacksTextArea
		do
		
			stacksTextArea = CreateFrame("Frame", "NAuras.GUI.Fonts.StacksTextArea", GUIFrame);
			stacksTextArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			stacksTextArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			stacksTextArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			stacksTextArea:SetPoint("TOPLEFT", 150, -210);
			stacksTextArea:SetPoint("LEFT", 150, -99);
			stacksTextArea:SetWidth(360);
			table.insert(GUIFrame.Categories[index], stacksTextArea);
		
		end
		
		-- // dropdownFont
		do
		
			local dropdownFont = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownFont", timerTextArea, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownFont, 300);
			dropdownFont:SetPoint("TOPLEFT", timerTextArea, "TOPLEFT", -4, -18);
			local info = {};
			dropdownFont.initialize = function()
				wipe(info);
				for idx, font in next, LibStub("LibSharedMedia-3.0"):List("font") do
					info.text = font;
					info.value = font;
					info.func = function(self)
						db.Font = self.value;
						_G[dropdownFont:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnFontChanged();
					end
					info.checked = font == db.Font;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownFont:GetName() .. "Text"]:SetText(db.Font);
			dropdownFont.text = dropdownFont:CreateFontString("NAuras.GUI.Fonts.DropdownFont.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownFont.text:SetPoint("LEFT", 20, 15);
			dropdownFont.text:SetText("Timer font:");
			table.insert(GUIFrame.Categories[index], dropdownFont);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownFont:GetName() .. "Text"]:SetText(db.Font); end);
			
		end
		
		-- // sliderTimerFontScale
		do
			
			local minValue, maxValue = 0.3, 3;
			local sliderTimerFontScale = GUICreateSlider(timerTextArea, 10, -58, 325, "NAuras.GUI.Fonts.SliderTimerFontScale");
			sliderTimerFontScale.label:SetText("Timer font scale");
			sliderTimerFontScale.slider:SetValueStep(0.1);
			sliderTimerFontScale.slider:SetMinMaxValues(minValue, maxValue);
			sliderTimerFontScale.slider:SetValue(db.FontScale);
			sliderTimerFontScale.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.1f", value));
				sliderTimerFontScale.editbox:SetText(tostring(actualValue));
				db.FontScale = actualValue;
				Nameplates_OnFontChanged();
			end);
			sliderTimerFontScale.editbox:SetText(tostring(db.FontScale));
			sliderTimerFontScale.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderTimerFontScale.editbox:GetText() ~= "") then
					local v = tonumber(sliderTimerFontScale.editbox:GetText());
					if (v == nil) then
						sliderTimerFontScale.editbox:SetText(tostring(db.FontScale));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderTimerFontScale.slider:SetValue(v);
					end
					sliderTimerFontScale.editbox:ClearFocus();
				end
			end);
			sliderTimerFontScale.lowtext:SetText(tostring(minValue));
			sliderTimerFontScale.hightext:SetText(tostring(maxValue));
			table.insert(GUIFrame.Categories[index], sliderTimerFontScale);
			table.insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontScale.editbox:SetText(tostring(db.FontScale)); sliderTimerFontScale.slider:SetValue(db.FontScale); end);
		
		end
		
		-- // dropdownTimerTextAnchor
		do
			
			local dropdownTimerTextAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchor", timerTextArea, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownTimerTextAnchor, 120);
			dropdownTimerTextAnchor:SetPoint("TOPLEFT", timerTextArea, "TOPLEFT", -4, -108);
			local info = {};
			dropdownTimerTextAnchor.initialize = function()
				wipe(info);
				for _, anchorPoint in pairs(textAnchors) do
					info.text = anchorPoint;
					info.value = anchorPoint;
					info.func = function(self)
						db.TimerTextAnchor = self.value;
						_G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnTextPositionChanged();
					end
					info.checked = anchorPoint == db.TimerTextAnchor;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(db.TimerTextAnchor);
			dropdownTimerTextAnchor.text = dropdownTimerTextAnchor:CreateFontString("NAuras.GUI.Fonts.DropdownTimerTextAnchor.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownTimerTextAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownTimerTextAnchor.text:SetText("Timer text anchor:");
			table.insert(GUIFrame.Categories[index], dropdownTimerTextAnchor);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(db.TimerTextAnchor); end);
		
		end
		
		-- // editboxTimerTextXOffset
		do
		
			local editboxTimerTextXOffset = CreateFrame("EditBox", "NAuras.GUI.Fonts.EditboxTimerTextXOffset", timerTextArea);
			editboxTimerTextXOffset:SetAutoFocus(false);
			editboxTimerTextXOffset:SetFontObject(GameFontHighlightSmall);
			editboxTimerTextXOffset:SetPoint("TOPLEFT", timerTextArea, 160, -113);
			editboxTimerTextXOffset:SetHeight(20);
			editboxTimerTextXOffset:SetWidth(80);
			editboxTimerTextXOffset:SetJustifyH("RIGHT");
			editboxTimerTextXOffset:EnableMouse(true);
			editboxTimerTextXOffset:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxTimerTextXOffset:SetBackdropColor(0, 0, 0, 0.5);
			editboxTimerTextXOffset:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxTimerTextXOffset:SetScript("OnEscapePressed", function() editboxTimerTextXOffset:ClearFocus(); end);
			editboxTimerTextXOffset:SetScript("OnEnterPressed", function()
				local offset = tonumber(editboxTimerTextXOffset:GetText());
				if (offset ~= nil) then
					db.TimerTextXOffset = offset;
					Nameplates_OnTextPositionChanged();
				else
					editboxTimerTextXOffset:SetText(tostring(db.TimerTextXOffset));
				end
				editboxTimerTextXOffset:ClearFocus();
			end);
			editboxTimerTextXOffset:SetText(tostring(db.TimerTextXOffset));
			local text = editboxTimerTextXOffset:CreateFontString("NAuras.GUI.Fonts.EditboxTimerTextXOffset.Label", "ARTWORK", "GameFontNormalSmall");
			text:SetPoint("LEFT", 5, 15);
			text:SetText("X offset:"); -- todo:localization
			table.insert(GUIFrame.Categories[index], editboxTimerTextXOffset);
			table.insert(GUIFrame.OnDBChangedHandlers, function() editboxTimerTextXOffset:SetText(tostring(db.TimerTextXOffset)); end);
		
		end
		
		-- // editboxTimerTextYOffset
		do
		
			local editboxTimerTextYOffset = CreateFrame("EditBox", "NAuras.GUI.Fonts.EditboxTimerTextYOffset", timerTextArea);
			editboxTimerTextYOffset:SetAutoFocus(false);
			editboxTimerTextYOffset:SetFontObject(GameFontHighlightSmall);
			editboxTimerTextYOffset:SetPoint("TOPLEFT", timerTextArea, 250, -113);
			editboxTimerTextYOffset:SetHeight(20);
			editboxTimerTextYOffset:SetWidth(80);
			editboxTimerTextYOffset:SetJustifyH("RIGHT");
			editboxTimerTextYOffset:EnableMouse(true);
			editboxTimerTextYOffset:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxTimerTextYOffset:SetBackdropColor(0, 0, 0, 0.5);
			editboxTimerTextYOffset:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxTimerTextYOffset:SetScript("OnEscapePressed", function() editboxTimerTextYOffset:ClearFocus(); end);
			editboxTimerTextYOffset:SetScript("OnEnterPressed", function()
				local offset = tonumber(editboxTimerTextYOffset:GetText());
				if (offset ~= nil) then
					db.TimerTextYOffset = offset;
					Nameplates_OnTextPositionChanged();
				else
					editboxTimerTextYOffset:SetText(tostring(db.TimerTextYOffset));
				end
				editboxTimerTextYOffset:ClearFocus();
			end);
			editboxTimerTextYOffset:SetText(tostring(db.TimerTextYOffset));
			local text = editboxTimerTextYOffset:CreateFontString("NAuras.GUI.Fonts.EditboxTimerTextYOffset.Label", "ARTWORK", "GameFontNormalSmall");
			text:SetPoint("LEFT", 5, 15);
			text:SetText("Y offset:"); -- todo:localization
			table.insert(GUIFrame.Categories[index], editboxTimerTextYOffset);
			table.insert(GUIFrame.OnDBChangedHandlers, function() editboxTimerTextYOffset:SetText(tostring(db.TimerTextYOffset)); end);
		
		end
		
		-- // colorPickerTimerTextFiveSeconds
		do
		
			local colorPickerTimerTextFiveSeconds = GUICreateColorPicker("NAuras.GUI.Fonts.ColorPickerTimerTextFiveSeconds", timerTextArea, 15, -148, "< 5sec");
			colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(db.TimerTextSoonToExpireColor));
			colorPickerTimerTextFiveSeconds:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.TimerTextSoonToExpireColor = {r, g, b};
					colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(db.TimerTextSoonToExpireColor));
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.TimerTextSoonToExpireColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.TimerTextSoonToExpireColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerTimerTextFiveSeconds);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(db.TimerTextSoonToExpireColor)); end);
			
		end
		
		-- // colorPickerTimerTextMinute
		do
		
			local colorPickerTimerTextMinute = GUICreateColorPicker("NAuras.GUI.Fonts.ColorPickerTimerTextMinute", timerTextArea, 140, -148, "< 1min");
			colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(db.TimerTextUnderMinuteColor));
			colorPickerTimerTextMinute:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.TimerTextUnderMinuteColor = {r, g, b};
					colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(db.TimerTextUnderMinuteColor));
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.TimerTextUnderMinuteColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.TimerTextUnderMinuteColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerTimerTextMinute);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(db.TimerTextUnderMinuteColor)); end);
		
		end
		
		-- // colorPickerTimerTextMore
		do
		
			local colorPickerTimerTextMore = GUICreateColorPicker("NAuras.GUI.Fonts.ColorPickerTimerTextMore", timerTextArea, 270, -148, "> 1min");
			colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(db.TimerTextLongerColor));
			colorPickerTimerTextMore:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.TimerTextLongerColor = {r, g, b};
					colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(db.TimerTextLongerColor));
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.TimerTextLongerColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.TimerTextLongerColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerTimerTextMore);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(db.TimerTextLongerColor)); end);
		
		end
		
		-- // dropdownStacksFont
		do
		
			local dropdownStacksFont = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksFont", stacksTextArea, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownStacksFont, 285);
			dropdownStacksFont:SetPoint("TOPLEFT", stacksTextArea, "TOPLEFT", -4, -18);
			local info = {};
			dropdownStacksFont.initialize = function()
				wipe(info);
				for idx, font in next, LibStub("LibSharedMedia-3.0"):List("font") do
					info.text = font;
					info.value = font;
					info.func = function(self)
						db.StacksFont = self.value;
						_G[dropdownStacksFont:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnFontChanged();
					end
					info.checked = font == db.StacksFont;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownStacksFont:GetName() .. "Text"]:SetText(db.StacksFont);
			dropdownStacksFont.text = dropdownStacksFont:CreateFontString("NAuras.GUI.Fonts.DropdownStacksFont.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownStacksFont.text:SetPoint("LEFT", 20, 15);
			dropdownStacksFont.text:SetText("Stacks font:");
			table.insert(GUIFrame.Categories[index], dropdownStacksFont);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksFont:GetName() .. "Text"]:SetText(db.StacksFont); end);
			
		end
		
		-- // sliderStacksFontScale
		do
			
			local minValue, maxValue = 0.3, 3;
			local sliderStacksFontScale = GUICreateSlider(stacksTextArea, 10, -58, 325, "NAuras.GUI.Fonts.SliderStacksFontScale");
			sliderStacksFontScale.label:SetText("Stacks text's font scale");
			sliderStacksFontScale.slider:SetValueStep(0.1);
			sliderStacksFontScale.slider:SetMinMaxValues(minValue, maxValue);
			sliderStacksFontScale.slider:SetValue(db.StacksFontScale);
			sliderStacksFontScale.slider:SetScript("OnValueChanged", function(self, value)
				local actualValue = tonumber(string_format("%.1f", value));
				sliderStacksFontScale.editbox:SetText(tostring(actualValue));
				db.StacksFontScale = actualValue;
				Nameplates_OnFontChanged();
			end);
			sliderStacksFontScale.editbox:SetText(tostring(db.StacksFontScale));
			sliderStacksFontScale.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderStacksFontScale.editbox:GetText() ~= "") then
					local v = tonumber(sliderStacksFontScale.editbox:GetText());
					if (v == nil) then
						sliderStacksFontScale.editbox:SetText(tostring(db.StacksFontScale));
						msg(L["Value must be a number"]);
					else
						if (v > maxValue) then
							v = maxValue;
						end
						if (v < minValue) then
							v = minValue;
						end
						sliderStacksFontScale.slider:SetValue(v);
					end
					sliderStacksFontScale.editbox:ClearFocus();
				end
			end);
			sliderStacksFontScale.lowtext:SetText(tostring(minValue));
			sliderStacksFontScale.hightext:SetText(tostring(maxValue));
			table.insert(GUIFrame.Categories[index], sliderStacksFontScale);
			table.insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksFontScale.editbox:SetText(tostring(db.StacksFontScale)); sliderStacksFontScale.slider:SetValue(db.StacksFontScale); end);
		
		end
		
		-- // dropdownStacksAnchor
		do
			
			local dropdownStacksAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchor", stacksTextArea, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownStacksAnchor, 120);
			dropdownStacksAnchor:SetPoint("TOPLEFT", stacksTextArea, "TOPLEFT", -4, -108);
			local info = {};
			dropdownStacksAnchor.initialize = function()
				wipe(info);
				for _, anchorPoint in pairs(textAnchors) do
					info.text = anchorPoint;
					info.value = anchorPoint;
					info.func = function(self)
						db.StacksTextAnchor = self.value;
						_G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(self:GetText());
						Nameplates_OnTextPositionChanged();
					end
					info.checked = anchorPoint == db.StacksTextAnchor;
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(db.StacksTextAnchor);
			dropdownStacksAnchor.text = dropdownStacksAnchor:CreateFontString("NAuras.GUI.Fonts.DropdownStacksAnchor.Label", "ARTWORK", "GameFontNormalSmall");
			dropdownStacksAnchor.text:SetPoint("LEFT", 20, 15);
			dropdownStacksAnchor.text:SetText("Stacks text anchor:");
			table.insert(GUIFrame.Categories[index], dropdownStacksAnchor);
			table.insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(db.StacksTextAnchor); end);
		
		end
		
		-- // editboxStacksXOffset
		do
		
			local editboxStacksXOffset = CreateFrame("EditBox", "NAuras.GUI.Fonts.EditboxStacksXOffset", stacksTextArea);
			editboxStacksXOffset:SetAutoFocus(false);
			editboxStacksXOffset:SetFontObject(GameFontHighlightSmall);
			editboxStacksXOffset:SetPoint("TOPLEFT", stacksTextArea, 160, -113);
			editboxStacksXOffset:SetHeight(20);
			editboxStacksXOffset:SetWidth(80);
			editboxStacksXOffset:SetJustifyH("RIGHT");
			editboxStacksXOffset:EnableMouse(true);
			editboxStacksXOffset:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxStacksXOffset:SetBackdropColor(0, 0, 0, 0.5);
			editboxStacksXOffset:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxStacksXOffset:SetScript("OnEscapePressed", function() editboxStacksXOffset:ClearFocus(); end);
			editboxStacksXOffset:SetScript("OnEnterPressed", function()
				local offset = tonumber(editboxStacksXOffset:GetText());
				if (offset ~= nil) then
					db.StacksTextXOffset = offset;
					Nameplates_OnTextPositionChanged();
				else
					editboxStacksXOffset:SetText(tostring(db.StacksTextXOffset));
				end
				editboxStacksXOffset:ClearFocus();
			end);
			editboxStacksXOffset:SetText(tostring(db.StacksTextXOffset));
			local text = editboxStacksXOffset:CreateFontString("NAuras.GUI.Fonts.EditboxStacksXOffset.Label", "ARTWORK", "GameFontNormalSmall");
			text:SetPoint("LEFT", 5, 15);
			text:SetText("X offset:"); -- todo:localization
			table.insert(GUIFrame.Categories[index], editboxStacksXOffset);
			table.insert(GUIFrame.OnDBChangedHandlers, function() editboxStacksXOffset:SetText(tostring(db.StacksTextXOffset)); end);
		
		end
		
		-- // editboxStacksYOffset
		do
		
			local editboxStacksYOffset = CreateFrame("EditBox", "NAuras.GUI.Fonts.EditboxStacksYOffset", stacksTextArea);
			editboxStacksYOffset:SetAutoFocus(false);
			editboxStacksYOffset:SetFontObject(GameFontHighlightSmall);
			editboxStacksYOffset:SetPoint("TOPLEFT", stacksTextArea, 250, -113);
			editboxStacksYOffset:SetHeight(20);
			editboxStacksYOffset:SetWidth(80);
			editboxStacksYOffset:SetJustifyH("RIGHT");
			editboxStacksYOffset:EnableMouse(true);
			editboxStacksYOffset:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxStacksYOffset:SetBackdropColor(0, 0, 0, 0.5);
			editboxStacksYOffset:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxStacksYOffset:SetScript("OnEscapePressed", function() editboxStacksYOffset:ClearFocus(); end);
			editboxStacksYOffset:SetScript("OnEnterPressed", function()
				local offset = tonumber(editboxStacksYOffset:GetText());
				if (offset ~= nil) then
					db.StacksTextYOffset = offset;
					Nameplates_OnTextPositionChanged();
				else
					editboxStacksYOffset:SetText(tostring(db.StacksTextYOffset));
				end
				editboxStacksYOffset:ClearFocus();
			end);
			editboxStacksYOffset:SetText(tostring(db.StacksTextYOffset));
			local text = editboxStacksYOffset:CreateFontString("NAuras.GUI.Fonts.EditboxStacksYOffset.Label", "ARTWORK", "GameFontNormalSmall");
			text:SetPoint("LEFT", 5, 15);
			text:SetText("Y offset:"); -- todo:localization
			table.insert(GUIFrame.Categories[index], editboxStacksYOffset);
			table.insert(GUIFrame.OnDBChangedHandlers, function() editboxStacksYOffset:SetText(tostring(db.StacksTextYOffset)); end);
		
		end
		
		-- // colorPickerStacksTextColor
		do
		
			local colorPickerStacksTextColor = GUICreateColorPicker("NAuras.GUI.Fonts.ColorPickerStacksTextColor", stacksTextArea, 15, -148, "Stacks text color");
			colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(db.StacksTextColor));
			colorPickerStacksTextColor:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.StacksTextColor = {r, g, b};
					colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(db.StacksTextColor));
					for nameplate in pairs(Nameplates) do
						if (nameplate.NAurasFrame) then
							for _, icon in pairs(nameplate.NAurasIcons) do
								icon.stacks:SetTextColor(unpack(db.StacksTextColor));
							end
						end
					end
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.StacksTextColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.StacksTextColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerStacksTextColor);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(db.StacksTextColor)); end);
		
		end
		
	end
	
	function GUICategory_Borders(index, value)
		
		local debuffArea;
		
		-- // checkBoxBuffBorder
		do
		
			local checkBoxBuffBorder = GUICreateCheckBoxWithColorPicker("NAuras.GUI.Borders.CheckBoxBuffBorder", 160, -30, "Show border around buff icons", function(this)
				db.ShowBuffBorders = this:GetChecked();
				UpdateAllNameplates();
			end);
			checkBoxBuffBorder:SetChecked(db.ShowBuffBorders);
			checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(db.BuffBordersColor));
			checkBoxBuffBorder.ColorButton:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.BuffBordersColor = {r, g, b};
					checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(db.BuffBordersColor));
					UpdateAllNameplates(true);
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.BuffBordersColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.BuffBordersColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], checkBoxBuffBorder);
			table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxBuffBorder:SetChecked(db.ShowBuffBorders); checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(db.BuffBordersColor)); end);
			
		end
		
		-- // debuffArea
		do
		
			debuffArea = CreateFrame("Frame", "NAuras.GUI.Borders.DebuffArea", GUIFrame);
			debuffArea:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = 1,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			});
			debuffArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
			debuffArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
			debuffArea:SetPoint("TOPLEFT", 150, -60);
			debuffArea:SetPoint("LEFT", 150, 85);
			debuffArea:SetWidth(360);
			table.insert(GUIFrame.Categories[index], debuffArea);
		
		end
		
		-- // checkBoxDebuffBorder
		do
		
			local checkBoxDebuffBorder = GUICreateCheckBox(160, -60, "Show border around debuff icons", function(this)
				db.ShowDebuffBorders = this:GetChecked();
				UpdateAllNameplates();
			end, "NAuras.GUI.Borders.CheckBoxDebuffBorder");
			checkBoxDebuffBorder:SetParent(debuffArea);
			checkBoxDebuffBorder:SetPoint("TOPLEFT", 15, -15);
			checkBoxDebuffBorder:SetChecked(db.ShowDebuffBorders);
			table.insert(GUIFrame.Categories[index], checkBoxDebuffBorder);
			table.insert(GUIFrame.OnDBChangedHandlers, function() checkBoxDebuffBorder:SetChecked(db.ShowDebuffBorders); end);
			
		end
		
		-- // colorPickerDebuffMagic
		do
		
			local colorPickerDebuffMagic = GUICreateColorPicker("NAuras.GUI.Borders.ColorPickerDebuffMagic", debuffArea, 15, -45, "Magic");
			colorPickerDebuffMagic.colorSwatch:SetVertexColor(unpack(db.DebuffBordersMagicColor));
			colorPickerDebuffMagic:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersMagicColor = {r, g, b};
					colorPickerDebuffMagic.colorSwatch:SetVertexColor(unpack(db.DebuffBordersMagicColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersMagicColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersMagicColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerDebuffMagic);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffMagic.colorSwatch:SetVertexColor(unpack(db.DebuffBordersMagicColor)); end);
		
		end
		
		-- // colorPickerDebuffCurse
		do
		
			local colorPickerDebuffCurse = GUICreateColorPicker("NAuras.GUI.Borders.ColorPickerDebuffCurse", debuffArea, 135, -45, "Curse");
			colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(db.DebuffBordersCurseColor));
			colorPickerDebuffCurse:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersCurseColor = {r, g, b};
					colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(db.DebuffBordersCurseColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersCurseColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersCurseColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerDebuffCurse);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(db.DebuffBordersCurseColor)); end);
		
		end
		
		-- // colorPickerDebuffDisease
		do
		
			local colorPickerDebuffDisease = GUICreateColorPicker("NAuras.GUI.Borders.ColorPickerDebuffDisease", debuffArea, 255, -45, "Disease");
			colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(db.DebuffBordersDiseaseColor));
			colorPickerDebuffDisease:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersDiseaseColor = {r, g, b};
					colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(db.DebuffBordersDiseaseColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersDiseaseColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersDiseaseColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerDebuffDisease);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(db.DebuffBordersDiseaseColor)); end);
		
		end
		
		-- // colorPickerDebuffPoison
		do
		
			local colorPickerDebuffPoison = GUICreateColorPicker("NAuras.GUI.Borders.ColorPickerDebuffPoison", debuffArea, 15, -70, "Poison");
			colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(db.DebuffBordersPoisonColor));
			colorPickerDebuffPoison:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersPoisonColor = {r, g, b};
					colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(db.DebuffBordersPoisonColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersPoisonColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersPoisonColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerDebuffPoison);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(db.DebuffBordersPoisonColor)); end);
		
		end
		
		-- // colorPickerDebuffOther
		do
		
			local colorPickerDebuffOther = GUICreateColorPicker("NAuras.GUI.Borders.ColorPickerDebuffOther", debuffArea, 135, -70, "Other");
			colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(db.DebuffBordersOtherColor));
			colorPickerDebuffOther:SetScript("OnClick", function()
				ColorPickerFrame:Hide();
				local function callback(restore)
					local r, g, b;
					if (restore) then
						r, g, b = unpack(restore);
					else
						r, g, b = ColorPickerFrame:GetColorRGB();
					end
					db.DebuffBordersOtherColor = {r, g, b};
					colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(db.DebuffBordersOtherColor));
					UpdateAllNameplates();
				end
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
				ColorPickerFrame:SetColorRGB(unpack(db.DebuffBordersOtherColor));
				ColorPickerFrame.hasOpacity = false;
				ColorPickerFrame.previousValues = { unpack(db.DebuffBordersOtherColor) };
				ColorPickerFrame:Show();
			end);
			table.insert(GUIFrame.Categories[index], colorPickerDebuffOther);
			table.insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(db.DebuffBordersOtherColor)); end);
		
		end
		
	end
	
	function GUICategory_4(index, value)
		local controls = { };
		local selectedSpell = 0;
		local editboxAddSpell, buttonAddSpell, dropdownSelectSpell, dropdownSpellShowMode, sliderSpellIconSize, dropdownSpellShowType, editboxSpellID, buttonDeleteSpell, selectSpell;
		
		-- // editboxAddSpell, buttonAddSpell
		do
		
			editboxAddSpell = CreateFrame("EditBox", "NAuras.GUI.Cat4.EditboxAddSpell", GUIFrame);
			editboxAddSpell:SetAutoFocus(false);
			editboxAddSpell:SetFontObject(GameFontHighlightSmall);
			editboxAddSpell:SetPoint("TOPLEFT", GUIFrame, 167, -30);
			editboxAddSpell:SetHeight(20);
			editboxAddSpell:SetWidth(215);
			editboxAddSpell:SetJustifyH("LEFT");
			editboxAddSpell:EnableMouse(true);
			editboxAddSpell:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxAddSpell:SetBackdropColor(0, 0, 0, 0.5);
			editboxAddSpell:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxAddSpell:SetScript("OnEscapePressed", function() editboxAddSpell:ClearFocus(); end);
			editboxAddSpell:SetScript("OnEnterPressed", function() buttonAddSpell:Click(); end);
			local text = editboxAddSpell:CreateFontString("NAuras.GUI.Cat4.EditboxAddSpell.Label", "ARTWORK", "GameFontNormalSmall");
			text:SetPoint("LEFT", 5, 15);
			text:SetText("Add new spell: "); -- todo:localization
			table.insert(GUIFrame.Categories[index], editboxAddSpell);
			
			buttonAddSpell = GUICreateButton("NAuras.GUI.Cat4.ButtonAddSpell", GUIFrame, "Add spell"); -- todo:localization
			buttonAddSpell:SetWidth(90);
			buttonAddSpell:SetHeight(20);
			buttonAddSpell:SetPoint("LEFT", editboxAddSpell, "RIGHT", 10, 0);
			buttonAddSpell:SetScript("OnClick", function(self, ...)
				local text = editboxAddSpell:GetText();
				if (tonumber(text) ~= nil) then
					msg("You should enter spell name instead of spell id.\nUse \"Check spell ID\" option if you want to track spell with specific id"); -- todo:localization
				else
					local spellID = SpellIDsCache[text];
					if (spellID ~= nil) then
						local spellName = SpellNamesCache[spellID];
						if (spellName == nil) then
							Print(format(L["Unknown spell: %s"], text));
						else
							local alreadyExist = false;
							for spellIDCustom in pairs(db.CustomSpells2) do
								local spellNameCustom = SpellNamesCache[spellIDCustom];
								if (spellNameCustom == spellName) then
									alreadyExist = true;
								end
							end
							if (not alreadyExist) then
								db.CustomSpells2[spellID] = GetDefaultDBSpellEntry(SPELL_SHOW_MODES[2], spellID, db.DefaultIconSize, nil);
								UpdateSpellCachesFromDB(spellID);
								selectSpell:Click();
								local btn = GUIFrame.SpellSelector.GetButtonByText(spellName);
								if (btn ~= nil) then btn:Click(); end
							else
								msg("Spell already exists ("..spellName..")"); -- todo:localization
							end
						end
						editboxAddSpell:SetText("");
						editboxAddSpell:ClearFocus();
					else
						msg("Spell seems to be nonexistent"); -- todo:localization
					end
				end
			end);
			table.insert(GUIFrame.Categories[index], buttonAddSpell);
			
		end
	
		-- // selectSpell
		do
		
			selectSpell = GUICreateButton("NAuras.GUI.Cat4.ButtonSelectSpell", GUIFrame, "Click to select spell");
			selectSpell:SetWidth(314);
			selectSpell:SetHeight(24);
			selectSpell:SetPoint("TOPLEFT", 168, -60);
			selectSpell:SetScript("OnClick", function()
				local t = { };
				for _, spellInfo in pairs(db.CustomSpells2) do
					table.insert(t, {
						icon = TextureCache[spellInfo.spellID],
						text = SpellNamesCache[spellInfo.spellID],
						info = spellInfo,
						func = function(self)
							for _, control in pairs(controls) do
								control:Show();
							end
							selectedSpell = self.info.spellID;
							print(self.info.spellID, db.CustomSpells2[selectedSpell].enabledState, db.CustomSpells2[selectedSpell].iconSize, db.CustomSpells2[selectedSpell].auraType, db.CustomSpells2[selectedSpell].checkSpellID);
							selectSpell.Text:SetText(self.text);
							_G[dropdownSpellShowMode:GetName().."Text"]:SetText(db.CustomSpells2[selectedSpell].enabledState);
							sliderSpellIconSize.slider:SetValue(db.CustomSpells2[selectedSpell].iconSize);
							sliderSpellIconSize.editbox:SetText(tostring(db.CustomSpells2[selectedSpell].iconSize));
							_G[dropdownSpellShowType:GetName().."Text"]:SetText(db.CustomSpells2[selectedSpell].auraType);
							editboxSpellID:SetText(db.CustomSpells2[selectedSpell].checkSpellID or "");
						end,
					});
				end
				table.sort(t, function(item1, item2) return SpellNamesCache[item1.info.spellID] < SpellNamesCache[item2.info.spellID] end);
				GUIFrame.SpellSelector:Show();
				GUIFrame.SpellSelector.SetList(t);
				GUIFrame.SpellSelector:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -90);
				for _, control in pairs(controls) do
					control:Hide();
				end
			end);
			selectSpell:SetScript("OnHide", function(self)
				for _, control in pairs(controls) do
					control:Hide();
				end
				selectSpell.Text:SetText("Click to select spell");
				GUIFrame.SpellSelector:Hide();
			end);
			table.insert(GUIFrame.Categories[index], selectSpell);
			
		end
	
		-- // dropdownSpellShowMode
		do
		
			dropdownSpellShowMode = CreateFrame("Frame", "NAuras.GUI.Cat4.DropdownSpellShowMode", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownSpellShowMode, 150);
			dropdownSpellShowMode.text = dropdownSpellShowMode:CreateFontString("NAuras.GUI.Cat4.DropdownSpellShowMode.Label", "ARTWORK", "GameFontNormal");
			dropdownSpellShowMode.text:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 170, -125);
			dropdownSpellShowMode.text:SetText("Show mode:");
			dropdownSpellShowMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 300, -115);
			local info = {};
			dropdownSpellShowMode.initialize = function()
				wipe(info);
				for _, showMode in pairs(SPELL_SHOW_MODES) do
					info.text = showMode;
					info.value = showMode;
					info.func = function(self)
						db.CustomSpells2[selectedSpell].enabledState = self.value;
						UpdateSpellCachesFromDB(selectedSpell);
						_G[dropdownSpellShowMode:GetName().."Text"]:SetText(self:GetText());
					end
					info.checked = (showMode == db.CustomSpells2[selectedSpell].enabledState);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownSpellShowMode:GetName().."Text"]:SetText("");
			table.insert(controls, dropdownSpellShowMode);
			
		end
		
		-- // dropdownSpellShowType
		do
		
			dropdownSpellShowType = CreateFrame("Frame", "NAuras.GUI.Cat4.DropdownSpellShowType", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownSpellShowType, 150);
			dropdownSpellShowType.text = dropdownSpellShowType:CreateFontString("NAuras.GUI.Cat4.DropdownSpellShowType.Label", "ARTWORK", "GameFontNormal");
			dropdownSpellShowType.text:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 170, -165);
			dropdownSpellShowType.text:SetText("Aura type:");
			dropdownSpellShowType:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 300, -155);
			local info = {};
			dropdownSpellShowType.initialize = function()
				wipe(info);
				for _, auraType in pairs(SPELL_SHOW_TYPES) do
					info.text = auraType;
					info.value = auraType;
					info.func = function(self)
						db.CustomSpells2[selectedSpell].auraType = self.value;
						UpdateSpellCachesFromDB(selectedSpell);
						_G[dropdownSpellShowType:GetName().."Text"]:SetText(self:GetText());
					end
					info.checked = (info.value == db.CustomSpells2[selectedSpell].auraType);
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdownSpellShowType:GetName().."Text"]:SetText("");
			table.insert(controls, dropdownSpellShowType);
		
		end
		
		-- // sliderSpellIconSize
		do
		
			sliderSpellIconSize = GUICreateSlider(GUIFrame, 170, -120, 200, "NAuras.GUI.Cat4.SliderSpellIconSize");
			sliderSpellIconSize.label:ClearAllPoints();
			sliderSpellIconSize.label:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 170, -205);
			sliderSpellIconSize.label:SetText("Icon size:");
			sliderSpellIconSize:ClearAllPoints();
			sliderSpellIconSize:SetPoint("LEFT", sliderSpellIconSize.label, "RIGHT", 20, 0);
			sliderSpellIconSize.slider:ClearAllPoints();
			sliderSpellIconSize.slider:SetPoint("LEFT", 3, 0)
			sliderSpellIconSize.slider:SetPoint("RIGHT", -3, 0)
			sliderSpellIconSize.slider:SetValueStep(1);
			sliderSpellIconSize.slider:SetMinMaxValues(1, CONST_MAX_ICON_SIZE);
			sliderSpellIconSize.slider:SetScript("OnValueChanged", function(self, value)
				sliderSpellIconSize.editbox:SetText(tostring(math_ceil(value)));
				db.CustomSpells2[selectedSpell].iconSize = math_ceil(value);
				UpdateSpellCachesFromDB(selectedSpell);
				for nameplate in pairs(NameplatesVisible) do
					UpdateNameplate(nameplate);
				end
			end);
			sliderSpellIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderSpellIconSize.editbox:GetText() ~= "") then
					local v = tonumber(sliderSpellIconSize.editbox:GetText());
					if (v == nil) then
						sliderSpellIconSize.editbox:SetText(tostring(db.CustomSpells2[selectedSpell].iconSize));
						Print(L["Value must be a number"]);
					else
						if (v > CONST_MAX_ICON_SIZE) then
							v = CONST_MAX_ICON_SIZE;
						end
						if (v < 1) then
							v = 1;
						end
						sliderSpellIconSize.slider:SetValue(v);
					end
					sliderSpellIconSize.editbox:ClearFocus();
				end
			end);
			sliderSpellIconSize.lowtext:SetText("1");
			sliderSpellIconSize.hightext:SetText(tostring(CONST_MAX_ICON_SIZE));
			table.insert(controls, sliderSpellIconSize);
			
		end
		
		-- // editboxSpellID
		do
		
			editboxSpellID = CreateFrame("EditBox", "NAuras.GUI.Cat4.EditboxSpellID", GUIFrame);
			editboxSpellID:SetAutoFocus(false);
			editboxSpellID:SetFontObject(GameFontHighlightSmall);
			editboxSpellID.text = editboxSpellID:CreateFontString("NAuras.GUI.Cat4.EditboxSpellID.Label", "ARTWORK", "GameFontNormal");
			editboxSpellID.text:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 170, -245);
			editboxSpellID.text:SetText("Check spell id: "); -- todo:localization
			editboxSpellID:SetPoint("LEFT", editboxSpellID.text, "RIGHT", 5, 0);
			editboxSpellID:SetPoint("RIGHT", GUIFrame, "RIGHT", -45, 0);
			editboxSpellID:SetHeight(20);
			editboxSpellID:SetWidth(215);
			editboxSpellID:SetJustifyH("LEFT");
			editboxSpellID:EnableMouse(true);
			editboxSpellID:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = true, edgeSize = 1, tileSize = 5,
			});
			editboxSpellID:SetBackdropColor(0, 0, 0, 0.5);
			editboxSpellID:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80);
			editboxSpellID:SetScript("OnEscapePressed", function() editboxSpellID:ClearFocus(); end);
			editboxSpellID:SetScript("OnEnterPressed", function(self, value)
				local text = self:GetText();
				local textAsNumber = tonumber(text);
				db.CustomSpells2[selectedSpell].checkSpellID = textAsNumber;
				UpdateSpellCachesFromDB(selectedSpell);
				if (textAsNumber == nil) then
					self:SetText("");
				end
				self:ClearFocus();
			end);
			table.insert(controls, editboxSpellID);
		
		end
		
		-- // buttonDeleteSpell
		do
		
			buttonDeleteSpell = GUICreateButton("NAuras.GUI.Cat4.ButtonDeleteSpell", GUIFrame, "Delete spell"); -- todo:localization
			buttonDeleteSpell:SetWidth(90);
			buttonDeleteSpell:SetHeight(20);
			buttonDeleteSpell:SetPoint("LEFT", GUIFrame, "LEFT", 165, -130);
			buttonDeleteSpell:SetPoint("RIGHT", GUIFrame, "RIGHT", -45, 0);
			buttonDeleteSpell:SetScript("OnClick", function(self, ...)
				db.CustomSpells2[selectedSpell] = nil;
				Spells[SpellNamesCache[selectedSpell]] = nil;
				UpdateSpellCachesFromDB(selectedSpell);
				selectSpell.Text:SetText("Click to select spell");
				for _, control in pairs(controls) do
					control:Hide();
				end
			end);
			table.insert(controls, buttonDeleteSpell);
		
		end
		
		
	end
	
	function OnGUICategoryClick(self, ...)
		GUIFrame.CategoryButtons[GUIFrame.ActiveCategory].text:SetTextColor(1, 0.82, 0);
		GUIFrame.CategoryButtons[GUIFrame.ActiveCategory]:UnlockHighlight();
		GUIFrame.ActiveCategory = self.index;
		self.text:SetTextColor(1, 1, 1);
		self:LockHighlight();
		PlaySound("igMainMenuOptionCheckBoxOn");
		ShowGUICategory(GUIFrame.ActiveCategory);
	end
	
	function ShowGUICategory(index)
		for i, v in pairs(GUIFrame.Categories) do
			for k, l in pairs(v) do
				l:Hide();
			end
		end
		for i, v in pairs(GUIFrame.Categories[index]) do
			v:Show();
		end
		-- if (index > 2) then
			-- NAuras_GUIScrollFramesTipText:Show();
		-- else
		NAuras_GUIScrollFramesTipText:Hide();
		-- end
	end
	
	function RebuildDropdowns()
		local info = {};
		NAuras_GUIProfilesDropdownCopyProfile.myvalue = nil;
		UIDropDownMenu_SetText(NAuras_GUIProfilesDropdownCopyProfile, "");
		local initCopyProfile = function()
			wipe(info);
			for index in pairs(NameplateAurasDB) do
				if (index ~= LocalPlayerFullName) then
					info.text = index;
					info.func = function(self)
						NAuras_GUIProfilesDropdownCopyProfile.myvalue = index;
						UIDropDownMenu_SetText(NAuras_GUIProfilesDropdownCopyProfile, index);
					end
					info.notCheckable = true;
					UIDropDownMenu_AddButton(info);
				end
			end
		end
		UIDropDownMenu_Initialize(NAuras_GUIProfilesDropdownCopyProfile, initCopyProfile);
		
		NAuras_GUIProfilesDropdownDeleteProfile.myvalue = nil;
		UIDropDownMenu_SetText(NAuras_GUIProfilesDropdownDeleteProfile, "");
		local initDeleteProfile = function()
			wipe(info);
			for index in pairs(NameplateAurasDB) do
				info.text = index;
				info.func = function(self)
					NAuras_GUIProfilesDropdownDeleteProfile.myvalue = index;
					UIDropDownMenu_SetText(NAuras_GUIProfilesDropdownDeleteProfile, index);
				end
				info.notCheckable = true;
				UIDropDownMenu_AddButton(info);
			end
		end
		UIDropDownMenu_Initialize(NAuras_GUIProfilesDropdownDeleteProfile, initDeleteProfile);
	end
	
	function CreateGUICategory()
		local b = CreateFrame("Button", nil, GUIFrame.outline);
		b:SetWidth(GUIFrame.outline:GetWidth() - 8);
		b:SetHeight(18);
		b:SetScript("OnClick", OnGUICategoryClick);
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
		b:GetHighlightTexture():SetAlpha(0.7);
		b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		b.text:SetPoint("LEFT", 3, 0);
		GUIFrame.CategoryButtons[#GUIFrame.CategoryButtons + 1] = b;
		return b;
	end
	
	function GUICreateSlider(parent, x, y, size, publicName)
		local frame = CreateFrame("Frame", publicName, parent);
		frame:SetHeight(100);
		frame:SetWidth(size);
		frame:SetPoint("TOPLEFT", x, y);

		frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		frame.label:SetPoint("TOPLEFT");
		frame.label:SetPoint("TOPRIGHT");
		frame.label:SetJustifyH("CENTER");
		--frame.label:SetHeight(15);
		
		frame.slider = CreateFrame("Slider", nil, frame);
		frame.slider:SetOrientation("HORIZONTAL")
		frame.slider:SetHeight(15)
		frame.slider:SetHitRectInsets(0, 0, -10, 0)
		frame.slider:SetBackdrop({
			bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true, tileSize = 8, edgeSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 }
		});
		frame.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		frame.slider:SetPoint("TOP", frame.label, "BOTTOM")
		frame.slider:SetPoint("LEFT", 3, 0)
		frame.slider:SetPoint("RIGHT", -3, 0)

		frame.lowtext = frame.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.lowtext:SetPoint("TOPLEFT", frame.slider, "BOTTOMLEFT", 2, 3)

		frame.hightext = frame.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.hightext:SetPoint("TOPRIGHT", frame.slider, "BOTTOMRIGHT", -2, 3)

		frame.editbox = CreateFrame("EditBox", nil, frame)
		frame.editbox:SetAutoFocus(false)
		frame.editbox:SetFontObject(GameFontHighlightSmall)
		frame.editbox:SetPoint("TOP", frame.slider, "BOTTOM")
		frame.editbox:SetHeight(14)
		frame.editbox:SetWidth(70)
		frame.editbox:SetJustifyH("CENTER")
		frame.editbox:EnableMouse(true)
		frame.editbox:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true, edgeSize = 1, tileSize = 5,
		});
		frame.editbox:SetBackdropColor(0, 0, 0, 0.5)
		frame.editbox:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80)
		frame.editbox:SetScript("OnEscapePressed", function() frame.editbox:ClearFocus(); end)
		frame:Hide();
		return frame;
	end
	
	function GUICreateButton(publicName, parentFrame, text)
		-- After creation we need to set up :SetWidth, :SetHeight, :SetPoint, :SetScript
		local button = CreateFrame("Button", publicName, parentFrame);
		button.Background = button:CreateTexture(nil, "BORDER");
		button.Background:SetPoint("TOPLEFT", 1, -1);
		button.Background:SetPoint("BOTTOMRIGHT", -1, 1);
		button.Background:SetColorTexture(0, 0, 0, 1);

		button.Border = button:CreateTexture(nil, "BACKGROUND");
		button.Border:SetPoint("TOPLEFT", 0, 0);
		button.Border:SetPoint("BOTTOMRIGHT", 0, 0);
		button.Border:SetColorTexture(unpack({0.73, 0.26, 0.21, 1}));

		button.Normal = button:CreateTexture(nil, "ARTWORK");
		button.Normal:SetPoint("TOPLEFT", 2, -2);
		button.Normal:SetPoint("BOTTOMRIGHT", -2, 2);
		button.Normal:SetColorTexture(unpack({0.38, 0, 0, 1}));
		button:SetNormalTexture(button.Normal);

		button.Disabled = button:CreateTexture(nil, "OVERLAY");
		button.Disabled:SetPoint("TOPLEFT", 3, -3);
		button.Disabled:SetPoint("BOTTOMRIGHT", -3, 3);
		button.Disabled:SetColorTexture(0.6, 0.6, 0.6, 0.2);
		button:SetDisabledTexture(button.Disabled);

		button.Highlight = button:CreateTexture(nil, "OVERLAY");
		button.Highlight:SetPoint("TOPLEFT", 3, -3);
		button.Highlight:SetPoint("BOTTOMRIGHT", -3, 3);
		button.Highlight:SetColorTexture(0.6, 0.6, 0.6, 0.2);
		button:SetHighlightTexture(button.Highlight);

		button.Text = button:CreateFontString(publicName.."Text", "OVERLAY", "GameFontNormal");
		button.Text:SetPoint("CENTER", 0, 0);
		button.Text:SetJustifyH("CENTER");
		button.Text:SetTextColor(1, 0.82, 0, 1);
		button.Text:SetText(text);

		button:SetScript("OnMouseDown", function(self) self.Text:SetPoint("CENTER", 1, -1) end);
		button:SetScript("OnMouseUp", function(self) self.Text:SetPoint("CENTER", 0, 0) end);
		return button;
	end
	
end

-------------------------------------------------------------------------------------------------
----- Useful stuff
-------------------------------------------------------------------------------------------------
do

	function Print(...)
		local text = "";
		for i = 1, select("#", ...) do
			text = text..tostring(select(i, ...)).." "
		end
		DEFAULT_CHAT_FRAME:AddMessage(format("NameplateAuras: %s", text), 0, 128, 128);
	end

	function deepcopy(object)
		local lookup_table = {}
		local function _copy(object)
			if type(object) ~= "table" then
				return object
			elseif lookup_table[object] then
				return lookup_table[object]
			end
			local new_table = {}
			lookup_table[object] = new_table
			for index, value in pairs(object) do
				new_table[_copy(index)] = _copy(value)
			end
			return setmetatable(new_table, getmetatable(object))
		end
		return _copy(object)
	end
	
	function msg(text)
		if (StaticPopupDialogs["NAURAS_MSG"] == nil) then
			StaticPopupDialogs["NAURAS_MSG"] = {
				text = "NAURAS_MSG",
				button1 = OKAY,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			};
		end
		StaticPopupDialogs["NAURAS_MSG"].text = text;
		StaticPopup_Show("NAURAS_MSG");
	end
	
end

-------------------------------------------------------------------------------------------------
----- Frame for events
-------------------------------------------------------------------------------------------------
EventFrame = CreateFrame("Frame");
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
EventFrame:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		PLAYER_ENTERING_WORLD();
	elseif (event == "NAME_PLATE_UNIT_ADDED") then
		NAME_PLATE_UNIT_ADDED(...);
	elseif (event == "NAME_PLATE_UNIT_REMOVED") then
		NAME_PLATE_UNIT_REMOVED(...);
	elseif (event == "UNIT_AURA") then
		UNIT_AURA(...);
	end
end);

-------------------------------------------------------------------------------------------------
----- Frame for fun
-------------------------------------------------------------------------------------------------
local funFrame = CreateFrame("Frame");
funFrame:RegisterEvent("CHAT_MSG_ADDON");
funFrame:SetScript("OnEvent", function(self, event, ...)
	local prefix, message, _, sender = ...;
	if (prefix == "NAuras_prefix") then
		if (string_find(message, "reporting")) then
			local _, toWhom = strsplit(":", message, 2);
			local myName = UnitName("player").."-"..string_gsub(GetRealmName(), " ", "");
			if (toWhom == myName and sender ~= myName) then
				Print(sender.." is using NAuras");
			end
		elseif (string_find(message, "requesting")) then
			SendAddonMessage("NAuras_prefix", "reporting:"..sender, IsInGroup(2) and "INSTANCE_CHAT" or "RAID");
		end
	end
end);
RegisterAddonMessagePrefix("NAuras_prefix");
