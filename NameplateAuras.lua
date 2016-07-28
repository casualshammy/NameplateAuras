local _, addonTable = ...;
local L = addonTable.L;
local DefaultSpells = addonTable.DefaultSpells;

local SML = LibStub("LibSharedMedia-3.0");
SML:Register("font", "NAuras_TeenBold", "Interface\\AddOns\\NameplateAuras\\media\\teen_bold.ttf", 255);
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
local TestFrame;
local db;
local LocalPlayerFullName = UnitName("player").." - "..GetRealmName();
-- consts
local SPELL_SHOW_MODES, SPELL_SHOW_TYPES, CONST_SORT_MODES, CONST_SORT_MODES_LOCALIZATION, CONST_DISABLED, CONST_MAX_ICON_SIZE;
do
	SPELL_SHOW_MODES = { "my", "all", "disabled" };
	SPELL_SHOW_TYPES = { "buff", "debuff", "buff/debuff" };
	CONST_SORT_MODES = { "none", "by-expire-time-asc", "by-expire-time-des", "by-icon-size-asc", "by-icon-size-des" };
	CONST_SORT_MODES_LOCALIZATION = { 
		[CONST_SORT_MODES[1]] = "None",
		[CONST_SORT_MODES[2]] = "By expire time, ascending",
		[CONST_SORT_MODES[3]] = "By expire time, descending",
		[CONST_SORT_MODES[4]] = "By icon size, ascending",
		[CONST_SORT_MODES[5]] = "By icon size, descending"
	};
	CONST_DISABLED = SPELL_SHOW_MODES[3];
	CONST_MAX_ICON_SIZE = 75;
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
local InitializeDB;
local GetDefaultDBSpellEntry;
local AddButtonToBlizzOptions;

local AllocateIcon;
local ReallocateAllIcons;
local GetNAurasFrameWidth;
local InitializeFrame;
local UpdateOnlyOneNameplate;
local HideCDIcon;
local ShowCDIcon;
local ResizeIcon;
local SortAurasForNameplate;
local UpdateCachesForSpell;

local OnUpdate;

local PLAYER_ENTERING_WORLD;
local NAME_PLATE_UNIT_ADDED;
local NAME_PLATE_UNIT_REMOVED;
local UNIT_AURA;

local EnableTestMode;
local DisableTestMode;

local ShowGUI;
local InitializeGUI;
local GUICategory_1;
local GUICategory_2;
local GUICategory_3;
local GUICategory_4;
local OnGUICategoryClick;
local ShowGUICategory;
local RebuildDropdowns;
local CreateGUICategory;
local GUICreateSlider;
local GUICreateButton;

local Print;
local deepcopy;

-------------------------------------------------------------------------------------------------
----- Initialize
-------------------------------------------------------------------------------------------------
do

	function OnStartup()
		InitializeDB();
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
					SpellShowModesCache[spellName] = spellInfo.enabledState;
					SpellAuraTypeCache[spellName] = spellInfo.auraType;
					SpellIconSizesCache[spellName] = spellInfo.iconSize;
					SpellCheckIDCache[spellName] = spellInfo.checkSpellID;
				end
				if (spellInfo.spellID == nil) then
					db.CustomSpells2[spellID].spellID = spellID;
				end
			end
		end
		-- // starting OnUpdate()
		EventFrame:SetScript("OnUpdate", function(self, elapsed)
			ElapsedTimer = ElapsedTimer + elapsed;
			if (ElapsedTimer >= 0.1) then
				OnUpdate();				
				ElapsedTimer = 0;
			end
		end);
		-- // starting listening for events
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
		EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
		EventFrame:RegisterEvent("UNIT_AURA");
		AddButtonToBlizzOptions();
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

	function InitializeDB()
		-- // if db is not exist for current player, create it
		if (NameplateAurasDB[LocalPlayerFullName] == nil) then
			NameplateAurasDB[LocalPlayerFullName] = { };
		end
		-- // set defaults
		local defaults = {
			DefaultSpells = { },
			CustomSpells2 = { },
			IconXOffset = 0,
			IconYOffset = 50,
			FullOpacityAlways = false,
			Font = "NAuras_TeenBold",
			DisplayBorders = true,
			HideBlizzardFrames = true,
			DefaultIconSize = 45,
			SortMode = CONST_SORT_MODES[2],
			DisplayTenthsOfSeconds = true,
		};
		for key, value in pairs(defaults) do
			if (NameplateAurasDB[LocalPlayerFullName][key] == nil) then
				NameplateAurasDB[LocalPlayerFullName][key] = value;
			end
		end
		-- // processing old and invalid entries
		if (NameplateAurasDB[LocalPlayerFullName].CustomSpells ~= nil and NameplateAurasDB[LocalPlayerFullName].CustomSpells2 == nil) then
			for spellID, enabledState in pairs(NameplateAurasDB[LocalPlayerFullName].CustomSpells) do
				NameplateAurasDB[LocalPlayerFullName]["CustomSpells2"][spellID] = GetDefaultDBSpellEntry(enabledState, spellID, defaults.DefaultIconSize, nil);
			end
			NameplateAurasDB[LocalPlayerFullName].CustomSpells = nil;
		end
		if (NameplateAurasDB[LocalPlayerFullName].StandardSpells ~= nil and NameplateAurasDB[LocalPlayerFullName]["DefaultSpells"] == nil) then
			for spellID, enabledState in pairs(NameplateAurasDB[LocalPlayerFullName].StandardSpells) do
				NameplateAurasDB[LocalPlayerFullName]["DefaultSpells"][spellID] = GetDefaultDBSpellEntry(enabledState, spellID, defaults.DefaultIconSize, nil);
			end
			NameplateAurasDB[LocalPlayerFullName].StandardSpells = nil;
		end
		if (NameplateAurasDB[LocalPlayerFullName].DefaultSpells ~= nil) then
			for spellID, spellInfo in pairs(NameplateAurasDB[LocalPlayerFullName].DefaultSpells) do
				NameplateAurasDB[LocalPlayerFullName]["CustomSpells2"][spellID] = GetDefaultDBSpellEntry(spellInfo.enabledState, spellInfo.spellID, spellInfo.iconSize or defaults.DefaultIconSize, spellInfo.checkSpellID or (DefaultSpells[spellID] ~= nil and DefaultSpells[spellID].checkSpellID or nil));
			end
			NameplateAurasDB[LocalPlayerFullName].DefaultSpells = nil;
		end
		if (NameplateAurasDB[LocalPlayerFullName].IconSize ~= nil) then
			NameplateAurasDB[LocalPlayerFullName].IconSize = nil;
		end
		-- // creating a fast reference
		db = NameplateAurasDB[LocalPlayerFullName];
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
	
	function AddButtonToBlizzOptions()
		local frame = CreateFrame("Frame", "NAuras_BlizzOptionsFrame", UIParent);
		frame.name = "NameplateAuras";
		InterfaceOptions_AddCategory(frame);
		local button = GUICreateButton("NAuras_BlizzOptionsButton", frame, "/nauras");
		button:SetWidth(80);
		button:SetHeight(40);
		button:SetPoint("CENTER", frame, "CENTER", 0, 0);
		button:SetScript("OnClick", function(self, ...)
			ShowGUI();
			if (GUIFrame) then
				InterfaceOptionsFrameCancel:Click();
			end
		end);
	end
	
end

-------------------------------------------------------------------------------------------------
----- Nameplates
-------------------------------------------------------------------------------------------------
do

	function AllocateIcon(frame, widthUsed)
		if (not frame.NAurasFrame) then
			frame.NAurasFrame = CreateFrame("frame", nil, db.FullOpacityAlways and WorldFrame or frame);
			frame.NAurasFrame:SetWidth(db.DefaultIconSize);
			frame.NAurasFrame:SetHeight(db.DefaultIconSize);
			frame.NAurasFrame:SetPoint("CENTER", frame, db.IconXOffset, db.IconYOffset);
			frame.NAurasFrame:Show();
		end
		local texture = frame.NAurasFrame:CreateTexture(nil, "BORDER");
		texture:SetPoint("LEFT", frame.NAurasFrame, widthUsed, 0);
		texture:SetWidth(db.DefaultIconSize);
		texture:SetHeight(db.DefaultIconSize);
		texture.size = db.DefaultIconSize;
		texture:Hide();
		texture.cooldown = frame.NAurasFrame:CreateFontString(nil, "OVERLAY");
		texture.cooldown:SetTextColor(0.7, 1, 0);
		texture.cooldown:SetAllPoints(texture);
		texture.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil(db.DefaultIconSize - db.DefaultIconSize / 2), "OUTLINE");
		texture.border = frame.NAurasFrame:CreateTexture(nil, "OVERLAY");
		texture.border:SetTexture("Interface\\AddOns\\NameplateAuras\\media\\CooldownFrameBorder.tga");
		texture.border:SetVertexColor(1, 0.35, 0);
		texture.border:SetAllPoints(texture);
		texture.border:Hide();
		texture.stacks = frame.NAurasFrame:CreateFontString(nil, "OVERLAY");
		texture.stacks:SetTextColor(1, 0.1, 0.1);
		texture.stacks:SetPoint("BOTTOMRIGHT", texture, -3, 5);
		texture.stacks:SetFont(SML:Fetch("font", db.Font), math_ceil(db.DefaultIconSize / 4), "OUTLINE");
		texture.stackcount = 0;
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.DefaultIconSize * frame.NAurasIconsCount);
		tinsert(frame.NAurasIcons, texture);
	end
	
	function ReallocateAllIcons(clearSpells)
		for frame in pairs(Nameplates) do
			if (frame.NAurasFrame) then
				frame.NAurasFrame:SetPoint("CENTER", frame, db.IconXOffset, db.IconYOffset);
				frame.NAurasFrame:SetWidth(db.DefaultIconSize * frame.NAurasIconsCount);
				local counter = 0;
				for _, icon in pairs(frame.NAurasIcons) do
					icon:SetWidth(db.DefaultIconSize);
					icon:SetHeight(db.DefaultIconSize);
					icon:SetPoint("LEFT", frame.NAurasFrame, counter * db.DefaultIconSize, 0);
					icon.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil(db.DefaultIconSize - db.DefaultIconSize / 2), "OUTLINE");
					icon.stacks:SetFont(SML:Fetch("font", db.Font), math_ceil(db.DefaultIconSize / 4), "OUTLINE");
					if (clearSpells) then
						HideCDIcon(icon);
					end
					counter = counter + 1;
				end
			end
		end
		if (clearSpells) then
			OnUpdate();
		end
	end
	
	function UpdateOnlyOneNameplate(frame, unitID)
		for i = 1, 40 do
			local buffName, _, _, buffStack, _, buffDuration, buffExpires, buffCaster, _, _, buffSpellID = UnitBuff(unitID, i);
			if (buffName ~= nil) then
				--print(SpellShowModesCache[buffName], buffName, buffStack, buffDuration, buffExpires, buffCaster, buffSpellID);
				if ((SpellShowModesCache[buffName] == "all" or (SpellShowModesCache[buffName] == "my" and buffCaster == "player")) and (SpellAuraTypeCache[buffName] == "buff" or SpellAuraTypeCache[buffName] == "buff/debuff") and (SpellCheckIDCache[buffName] == nil or SpellCheckIDCache[buffName] == buffSpellID)) then
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
			local debuffName, _, _, debuffStack, _, debuffDuration, debuffExpires, debuffCaster, _, _, debuffSpellID = UnitDebuff(unitID, i);
			if (debuffName ~= nil) then
				--print(SpellShowModesCache[debuffName], debuffName, debuffStack, debuffDuration, debuffExpires, debuffCaster, debuffSpellID);
				if ((SpellShowModesCache[debuffName] == "all" or (SpellShowModesCache[debuffName] == "my" and debuffCaster == "player")) and (SpellAuraTypeCache[debuffName] == "debuff" or SpellAuraTypeCache[debuffName] == "buff/debuff") and (SpellCheckIDCache[debuffName] == nil or SpellCheckIDCache[debuffName] == debuffSpellID)) then
					if (nameplateAuras[frame][debuffName] == nil or nameplateAuras[frame][debuffName].expires < debuffExpires or nameplateAuras[frame][debuffName].stacks ~= debuffStack) then
						nameplateAuras[frame][debuffName] = {
							["duration"] = debuffDuration ~= 0 and debuffDuration or 4000000000,
							["expires"] = debuffExpires ~= 0 and debuffExpires or 4000000000,
							["stacks"] = debuffStack,
							["spellID"] = debuffSpellID,
							["type"] = "debuff"
						};
					end
				end
			end
		end
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
					if (last > 3600) then
						icon.cooldown:SetText("Inf");
					elseif (last >= 60) then
						icon.cooldown:SetText(math_floor(last/60).."m");
					elseif (last >= 10) then
						icon.cooldown:SetText(string_format("%.0f", last));
					else
						icon.cooldown:SetText(string_format("%.1f", last));
					end
					-- // stacks
					if (icon.stackcount ~= spellInfo.stacks) then
						if (spellInfo.stacks > 1) then
							icon.stacks:SetText(spellInfo.stacks);
						else
							icon.stacks:SetText("");
						end
						icon.stackcount = spellInfo.stacks;
					end
					-- // border
					if (db.DisplayBorders) then
						if (icon.borderState ~= spellInfo.type) then
							if (spellInfo.type == "buff") then
								icon.border:SetVertexColor(0, 1, 0, 1);
							else
								icon.border:SetVertexColor(1, 0, 0, 1);
							end
							icon.border:Show();
							icon.borderState = spellInfo.type;
						end
					else
						if (icon.borderState ~= nil) then
							icon.border:Hide();
							icon.borderState = nil;
						end
					end
					-- // icon size
					if (SpellIconSizesCache[spellName] ~= icon.size or iconResized) then
						icon.size = SpellIconSizesCache[spellName];
						ResizeIcon(icon, icon.size, totalWidth);
						iconResized = true;
					end
					if (not icon.shown) then
						ShowCDIcon(icon);
					end
					totalWidth = totalWidth + icon.size;
					counter = counter + 1;
				end
			end
		end
		if (frame.NAurasFrame ~= nil) then
			frame.NAurasFrame:SetWidth(totalWidth);
		end
		for k = counter, frame.NAurasIconsCount do
			local icon = frame.NAurasIcons[k];
			if (icon.shown) then
				HideCDIcon(icon);
			end
		end
		-- // hide standart buff frame
		if (db.HideBlizzardFrames) then
			frame.UnitFrame.BuffFrame:Hide();
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
		icon:SetPoint("LEFT", icon:GetParent(), widthAlreadyUsed, 0);
		icon.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil(size - size / 2), "OUTLINE");
		icon.stacks:SetFont(SML:Fetch("font", db.Font), math_ceil(size / 4), "OUTLINE");
	end
	
	function SortAurasForNameplate(auras)
		if (db.SortMode == CONST_SORT_MODES[1]) then
			return auras;
		end
		local t = { };
		for _, spellInfo in pairs(auras) do
			table.insert(t, spellInfo);
		end
		if (db.SortMode == CONST_SORT_MODES[2]) then
			table.sort(t, function(item1, item2) return item1.expires < item2.expires end);
		elseif (db.SortMode == CONST_SORT_MODES[3]) then
			table.sort(t, function(item1, item2) return item1.expires > item2.expires end);
		elseif (db.SortMode == CONST_SORT_MODES[4]) then
			table.sort(t, function(item1, item2) return SpellIconSizesCache[SpellNamesCache[item1.spellID]] < SpellIconSizesCache[SpellNamesCache[item2.spellID]] end);
		elseif (db.SortMode == CONST_SORT_MODES[5]) then
			table.sort(t, function(item1, item2) return SpellIconSizesCache[SpellNamesCache[item1.spellID]] > SpellIconSizesCache[SpellNamesCache[item2.spellID]] end);
		end
		return t;
	end
	
	function UpdateCachesForSpell(spellInfo)
	
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
						if (last > 3600) then
							icon.cooldown:SetText("Inf");
						elseif (last >= 60) then
							icon.cooldown:SetText(math_floor(last/60).."m");
						elseif (last >= 10 or not db.DisplayTenthsOfSeconds) then
							icon.cooldown:SetText(string_format("%.0f", last));
						else
							icon.cooldown:SetText(string_format("%.1f", last));
						end
						counter = counter + 1;
					else
						--nameplateAuras[frame][spellID] = nil;
					end
				end
			end
			-- for k = counter, frame.NAurasIconsCount do
				-- if (frame.NAurasIcons[k].shown) then
					-- HideCDIcon(frame.NAurasIcons[k]);
				-- end
			-- end
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
		UpdateOnlyOneNameplate(nameplate, unitID);
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
			wipe(nameplateAuras[nameplate]);
			UpdateOnlyOneNameplate(nameplate, unitID);
			if (db.FullOpacityAlways and nameplate.NAurasFrame) then
				nameplate.NAurasFrame:Show();
			end
		end
	end
	
end

-------------------------------------------------------------------------------------------------
----- Test mode
-------------------------------------------------------------------------------------------------
do

	local _t = 0;
	local _spellNames = {156925, 2645};
	
	local function refreshCDs()
		local cTime = GetTime();
		for frame in pairs(NameplatesVisible) do
			for index, spellID in pairs(_spellNames) do
				local _spellName = GetSpellInfo(spellID);
				if (nameplateAuras[frame][_spellName] == nil or nameplateAuras[frame][_spellName].expires < cTime) then
					nameplateAuras[frame][_spellName] = {
						["duration"] = 30,
						["expires"] = index % 2 == 0 and 4000000000 or (cTime + 10),
						["stacks"] = index % 2 == 0 and 0 or 7,
						["spellID"] = spellID,
						["type"] = index % 2 == 0 and "buff" or "debuff"
					};
				end
			end
			UpdateOnlyOneNameplate(frame, "invalid");
		end
	end
	
	function EnableTestMode()
		if (not TestFrame) then
			TestFrame = CreateFrame("frame");
		end
		TestFrame:SetScript("OnUpdate", function(self, elapsed)
			_t = _t + elapsed;
			if (_t >= 2) then
				refreshCDs();
				_t = 0;
			end
		end);
		refreshCDs(); 	-- // for instant start
		OnUpdate();		-- // for instant start
	end
	
	function DisableTestMode()
		TestFrame:SetScript("OnUpdate", nil);
		local cTime = GetTime();
		for frame in pairs(NameplatesVisible) do
			for index, spellID in pairs(_spellNames) do
				local _spellName = GetSpellInfo(spellID);
				if (nameplateAuras[frame][_spellName] ~= nil and nameplateAuras[frame][_spellName].expires > cTime) then
					nameplateAuras[frame][_spellName] = {
						["duration"] = 30,
						["expires"] = cTime - 1,
						["stacks"] = 7,
						["spellID"] = index,
						["type"] = "debuff"
					};
				end
			end
		end
		OnUpdate();		-- // for instant start
	end
	
end

-------------------------------------------------------------------------------------------------
----- GUI
-------------------------------------------------------------------------------------------------
do

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
		GUIFrame:SetHeight(350);
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
		header:SetPoint("CENTER", GUIFrame, "CENTER", 0, 185);
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
		GUIFrame.SpellIcons = {};
		GUIFrame.CustomSpellsDropdowns = {};
		
		for index, value in pairs({ L["General"], L["Profiles"], "Spells" }) do
			local b = CreateGUICategory();
			b.index = index;
			b.text:SetText(value);
			if (index == 1) then
				b:LockHighlight();
				b.text:SetTextColor(1, 1, 1);
				b:SetPoint("TOPLEFT", GUIFrame.outline, "TOPLEFT", 5, -6);
			elseif (index == 2) then
				b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -24);
			else
				b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 26);
			end
			
			GUIFrame.Categories[index] = {};
			
			if (index == 1) then
				GUICategory_1(index, value);
			elseif (index == 2) then
				GUICategory_2(index, value);
			elseif (index == 3) then
				GUICategory_3(index, value);
			else
				--GUICategory_4(index, value);
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
				print("New button is created: " .. tostring(counter));
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
		
		return scrollAreaBackground;
	end
	
	function GUICategory_1(index, value)
		
		-- // sliderIconSize
		do
		
			local sliderIconSize = GUICreateSlider(GUIFrame, 160, -30, 340, "NAuras.GUI.Cat1.SliderIconSize");
			sliderIconSize.label:SetText("Default icon size");
			sliderIconSize.slider:SetValueStep(1);
			sliderIconSize.slider:SetMinMaxValues(1, CONST_MAX_ICON_SIZE);
			sliderIconSize.slider:SetValue(db.DefaultIconSize);
			sliderIconSize.slider:SetScript("OnValueChanged", function(self, value)
				sliderIconSize.editbox:SetText(tostring(math_ceil(value)));
				for spellID, spellInfo in pairs(db.CustomSpells2) do
					if (spellInfo.iconSize == db.DefaultIconSize) then
						db.CustomSpells2[spellID].iconSize = math_ceil(value);
						SpellIconSizesCache[SpellNamesCache[spellID]] = db.CustomSpells2[spellID].iconSize;
					end
				end
				db.DefaultIconSize = math_ceil(value);
			end);
			sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize));
			sliderIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
				if (sliderIconSize.editbox:GetText() ~= "") then
					local v = tonumber(sliderIconSize.editbox:GetText());
					if (v == nil) then
						sliderIconSize.editbox:SetText(tostring(db.DefaultIconSize));
						message(L["Value must be a number"]);
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
				ReallocateAllIcons(false);
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
				ReallocateAllIcons(false);
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
		
		end
		
		
		local checkBoxFullOpacityAlways = GUICreateCheckBox(160, -160, "Always display icons at full opacity (ReloadUI is needed)", function(this)
			db.FullOpacityAlways = this:GetChecked();
		end, "NAuras_GUI_General_CheckBoxFullOpacityAlways");
		checkBoxFullOpacityAlways:SetChecked(db.FullOpacityAlways);
		table.insert(GUIFrame.Categories[index], checkBoxFullOpacityAlways);
		
		local checkBoxDisplayBorders = GUICreateCheckBox(160, -180, "Display red/green borders", function(this)
			db.DisplayBorders = this:GetChecked();
			ReallocateAllIcons(true);
		end, "NAuras.GUI.Cat1.CheckBoxDisplayBorders");
		checkBoxDisplayBorders:SetChecked(db.DisplayBorders);
		table.insert(GUIFrame.Categories[index], checkBoxDisplayBorders);
		
		local checkBoxHideBlizzardFrames = GUICreateCheckBox(160, -200, "Hide Blizzard's aura frames (Reload UI required)", function(this)
			db.HideBlizzardFrames = this:GetChecked();
		end, "NAuras.GUI.Cat1.CheckBoxHideBlizzardFrames");
		checkBoxHideBlizzardFrames:SetChecked(db.HideBlizzardFrames);
		table.insert(GUIFrame.Categories[index], checkBoxHideBlizzardFrames);
		
		local checkBoxDisplayTenthsOfSeconds = GUICreateCheckBox(160, -220, "Display tenths of seconds", function(this)
			db.DisplayTenthsOfSeconds = this:GetChecked();
		end, "NAuras.GUI.Cat1.CheckBoxDisplayTenthsOfSeconds");
		checkBoxDisplayTenthsOfSeconds:SetChecked(db.DisplayTenthsOfSeconds);
		table.insert(GUIFrame.Categories[index], checkBoxDisplayTenthsOfSeconds);
		
		-- // dropdownSortMode
		do
			local dropdownSortMode = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownSortMode", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownSortMode, 200);
			dropdownSortMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -275);
			local info = {};
			dropdownSortMode.initialize = function()
				wipe(info);
				for _, sortMode in pairs(CONST_SORT_MODES) do
					info.text = CONST_SORT_MODES_LOCALIZATION[sortMode];
					info.value = sortMode;
					info.func = function(self)
						db.SortMode = self.value;
						_G[dropdownSortMode:GetName().."Text"]:SetText(self:GetText());
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
		end
		
		-- // dropdownFont
		do
			local dropdownFont = CreateFrame("Frame", "NAuras_GUI_General_DropdownFont", GUIFrame, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetWidth(dropdownFont, 200);
			dropdownFont:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -310);
			local info = {};
			dropdownFont.initialize = function()
				wipe(info);
				for idx, font in next, LibStub("LibSharedMedia-3.0"):List("font") do
					info.text = font;
					info.value = font;
					info.func = function(self)
						db.Font = self.value;
						ReallocateAllIcons(false);
						NAuras_GUI_General_DropdownFontText:SetText(self:GetText());
					end
					info.checked = font == db.Font;
					UIDropDownMenu_AddButton(info);
				end
			end
			NAuras_GUI_General_DropdownFontText:SetText(db.Font);
			dropdownFont.text = dropdownFont:CreateFontString("NAuras_GUI_General_DropdownFontNoteText", "ARTWORK", "GameFontNormalSmall");
			dropdownFont.text:SetPoint("LEFT", 20, 15);
			dropdownFont.text:SetText(L["Font:"]);
			table.insert(GUIFrame.Categories[index], dropdownFont);
		end
		
	end
	
	function GUICategory_2(index, value)
		local textProfilesCurrentProfile = GUIFrame:CreateFontString("NAuras_GUIProfilesTextCurrentProfile", "OVERLAY", "GameFontNormal");
		textProfilesCurrentProfile:SetPoint("CENTER", GUIFrame, "LEFT", 330, 130);
		textProfilesCurrentProfile:SetText(format(L["Current profile: [%s]"], LocalPlayerFullName));
		table.insert(GUIFrame.Categories[index], textProfilesCurrentProfile);
		
		local dropdownCopyProfile = CreateFrame("Frame", "NAuras_GUIProfilesDropdownCopyProfile", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownCopyProfile, 210);
		dropdownCopyProfile:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 150, -80);
		dropdownCopyProfile.text = dropdownCopyProfile:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownCopyProfile.text:SetPoint("LEFT", 20, 20);
		dropdownCopyProfile.text:SetText(L["Copy other profile to current profile:"]);
		table.insert(GUIFrame.Categories[index], dropdownCopyProfile);
		
		local buttonCopyProfile = GUICreateButton("NAuras_GUIProfilesButtonCopyProfile", GUIFrame, L["Copy"]);
		buttonCopyProfile:SetWidth(90);
		buttonCopyProfile:SetHeight(24);
		buttonCopyProfile:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 410, -82);
		buttonCopyProfile:SetScript("OnClick", function(self, ...)
			if (dropdownCopyProfile.myvalue ~= nil) then
				NameplateAurasDB[LocalPlayerFullName] = deepcopy(NameplateAurasDB[dropdownCopyProfile.myvalue]);
				db = NameplateAurasDB[LocalPlayerFullName];
				Print(format(L["Data from '%s' has been successfully copied to '%s'"], dropdownCopyProfile.myvalue, LocalPlayerFullName));
				RebuildDropdowns();
				NAuras_GUIGeneralSliderIconXOffset.slider:SetValue(db.IconXOffset);
				NAuras_GUIGeneralSliderIconXOffset.editbox:SetText(tostring(db.IconXOffset));
				NAuras_GUIGeneralSliderIconYOffset.slider:SetValue(db.IconYOffset);
				NAuras_GUIGeneralSliderIconYOffset.editbox:SetText(tostring(db.IconYOffset));
				for _, v in pairs(GUIFrame.SpellIcons) do
					if (db.CDsTable[v.spellID] == true) then
						v.tex:SetAlpha(1.0);
					else
						v.tex:SetAlpha(0.3);
					end
				end
			end
		end);
		table.insert(GUIFrame.Categories[index], buttonCopyProfile);
		
		local dropdownDeleteProfile = CreateFrame("Frame", "NAuras_GUIProfilesDropdownDeleteProfile", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownDeleteProfile, 210);
		dropdownDeleteProfile:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 150, -120);
		dropdownDeleteProfile.text = dropdownDeleteProfile:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownDeleteProfile.text:SetPoint("LEFT", 20, 20);
		dropdownDeleteProfile.text:SetText(L["Delete profile:"]);
		table.insert(GUIFrame.Categories[index], dropdownDeleteProfile);
		
		local buttonDeleteProfile = GUICreateButton("NAuras_GUIProfilesButtonDeleteProfile", GUIFrame, L["Delete"]);
		buttonDeleteProfile:SetWidth(90);
		buttonDeleteProfile:SetHeight(24);
		buttonDeleteProfile:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 410, -122);
		buttonDeleteProfile:SetScript("OnClick", function(self, ...)
			if (dropdownDeleteProfile.myvalue ~= nil) then
				NameplateAurasDB[dropdownDeleteProfile.myvalue] = nil;
				Print(format(L["Profile '%s' has been successfully deleted"], dropdownDeleteProfile.myvalue));
				RebuildDropdowns();
			end
		end);
		table.insert(GUIFrame.Categories[index], buttonDeleteProfile);
		
		
		-- /////////////////////////
		
		-- local editboxNewProfile = CreateFrame("EditBox", "NAuras_GUIProfilesEditboxNewProfile", GUIFrame)
		-- editboxNewProfile:SetAutoFocus(false);
		-- editboxNewProfile:SetFont("Fonts\\FRIZQT__.TTF", 12, nil);
		-- editboxNewProfile:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 135, -162);
		-- editboxNewProfile:SetHeight(24);
		-- editboxNewProfile:SetWidth(230);
		-- editboxNewProfile:SetJustifyH("LEFT");
		-- editboxNewProfile:EnableMouse(true);
		-- editboxNewProfile:SetBackdrop({
			-- bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			-- edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			-- tile = true, edgeSize = 1, tileSize = 5,
		-- });
		-- editboxNewProfile:SetBackdropColor(0, 0, 0, 0.5)
		-- editboxNewProfile:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80)
		-- editboxNewProfile:SetScript("OnEscapePressed", function() editboxNewProfile:ClearFocus(); end);
		-- table.insert(GUIFrame.Categories[index], editboxNewProfile);
		
		-- local buttonNewProfile = GUICreateButton("NAuras_GUIProfilesButtonNewProfile", GUIFrame, "Add"); -- // todo: localize
		-- buttonNewProfile:SetWidth(90);
		-- buttonNewProfile:SetHeight(24);
		-- buttonNewProfile:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 380, -162);
		-- buttonNewProfile:SetScript("OnClick", function(self, ...)
			
		-- end);
		-- table.insert(GUIFrame.Categories[index], buttonNewProfile);
		
		-- /////////////////////////
		
		
		RebuildDropdowns();
	end
	
	function GUICategory_3(index, value)
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
				local textAsNumber = tonumber(text) or SpellIDsCache[text];
				if (textAsNumber ~= nil) then
					local spellName = SpellNamesCache[textAsNumber];
					if (spellName == nil) then
						Print(format(L["Unknown spell: %s"], text));
					else
						local alreadyExist = false;
						-- for spellIDDefault in pairs(DefaultSpells) do
							-- local spellNameDefault = SpellNamesCache[spellIDDefault];
							-- if (spellNameDefault == spellName) then
								-- alreadyExist = true;
							-- end
						-- end
						for spellIDCustom in pairs(db.CustomSpells2) do
							local spellNameCustom = SpellNamesCache[spellIDCustom];
							if (spellNameCustom == spellName) then
								alreadyExist = true;
							end
						end
						if (not alreadyExist) then
							db.CustomSpells2[textAsNumber] = GetDefaultDBSpellEntry(SPELL_SHOW_MODES[2], textAsNumber, db.DefaultIconSize, nil);
							SpellShowModesCache[spellName] = db.CustomSpells2[textAsNumber].enabledState;
							SpellAuraTypeCache[spellName] = db.CustomSpells2[textAsNumber].auraType;
							SpellIconSizesCache[spellName] = db.DefaultIconSize;
							selectSpell:Click();
						else
							message("Spell already exists ("..spellName..")"); -- todo:localization
						end
					end
					editboxAddSpell:SetText("");
					editboxAddSpell:ClearFocus();
				else
					message("Spell seems to be missing"); -- todo:localization
				end
			end);
			table.insert(GUIFrame.Categories[index], buttonAddSpell);
			
		end
	
		-- // selectSpell
		do
		
			selectSpell = GUICreateButton("NAuras.GUI.Cat4.ButtonSelectSpell", GUIFrame, "Click to select spell");
			selectSpell:SetWidth(300);
			selectSpell:SetHeight(24);
			selectSpell:SetPoint("TOPLEFT", 180, -60);
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
						if (self.value ~= CONST_DISABLED) then
							SpellShowModesCache[SpellNamesCache[selectedSpell]] = self.value;
							SpellAuraTypeCache[SpellNamesCache[selectedSpell]] = db.CustomSpells2[selectedSpell].auraType
						else
							SpellShowModesCache[SpellNamesCache[selectedSpell]] = nil;
							SpellAuraTypeCache[SpellNamesCache[selectedSpell]] = nil;
						end
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
						SpellAuraTypeCache[SpellNamesCache[selectedSpell]] = db.CustomSpells2[selectedSpell].auraType;
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
				SpellIconSizesCache[SpellNamesCache[selectedSpell]] = db.CustomSpells2[selectedSpell].iconSize;
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
				if (textAsNumber ~= nil) then
					db.CustomSpells2[selectedSpell].checkSpellID = textAsNumber;
					SpellCheckIDCache[SpellNamesCache[selectedSpell]] = textAsNumber;
				else
					db.CustomSpells2[selectedSpell].checkSpellID = nil;
					SpellCheckIDCache[SpellNamesCache[selectedSpell]] = nil;
					self:SetText("");
					--message("Value must be a number!");
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
				local spellName = SpellNamesCache[selectedSpell];
				Spells[spellName] = nil;
				SpellShowModesCache[spellName] = nil;
				SpellAuraTypeCache[spellName] = nil;
				SpellIconSizesCache[spellName] = nil;
				SpellCheckIDCache[spellName] = nil;
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
