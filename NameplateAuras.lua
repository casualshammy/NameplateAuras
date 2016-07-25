local _, addonTable = ...;
local L = addonTable.L;
local StandardSpells = addonTable.StandardSpells;

local SML = LibStub("LibSharedMedia-3.0");
SML:Register("font", "NAuras_TeenBold", "Interface\\AddOns\\NameplateAuras\\media\\teen_bold.ttf", 255);

NameplateAurasDB = {};
local nameplateAuras = {};
local TextureCache = setmetatable({}, {
	__index = function(t, key)
		local texture = GetSpellTexture(key);
		t[key] = texture;
		return texture;
	end
});
local Spells = {};
local SpellsEnabledCache = {};
local ElapsedTimer = 0;
local Nameplates = {};
local NameplatesVisible = {};
local GUIFrame;
local EventFrame;
local TestFrame;
local db;
local LocalPlayerFullName = UnitName("player").." - "..GetRealmName();

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
local AddButtonToBlizzOptions;

local AllocateIcon;
local ReallocateAllIcons;
local InitializeFrame;
local UpdateOnlyOneNameplate;
local HideCDIcon;
local ShowCDIcon;

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
		for spellID, enabledState in pairs(StandardSpells) do
			local spellName = GetSpellInfo(spellID);
			if (spellName ~= nil and Spells[spellName] == nil) then
				Spells[spellName] = enabledState;
				if (enabledState ~= "disable") then
					SpellsEnabledCache[spellName] = enabledState;
				end
				if (db.StandardSpells[spellID] == nil) then
					db.StandardSpells[spellID] = enabledState;
				end
			end
		end
		for spellID, enabledState in pairs(db.StandardSpells) do
			local spellName = GetSpellInfo(spellID);
			if (StandardSpells[spellID] ~= nil) then
				if (spellName == nil) then
					Print("<"..spellName.."> isn't exist. Removing from database...");
					db.StandardSpells[spellID] = nil;
				else
					Spells[spellName] = enabledState;
					if (enabledState ~= "disable") then
						SpellsEnabledCache[spellName] = enabledState;
					end
				end
			else
				Print("<"..spellName.."> isn't standard spell. Removing from database...");
				db.StandardSpells[spellID] = nil;
			end
		end
		for spellID, enabledState in pairs(db.CustomSpells) do
			local spellName = GetSpellInfo(spellID);
			if (spellName == nil) then
				Print("<"..spellName.."> isn't exist. Removing from database...");
				db.CustomSpells[spellID] = nil;
			else
				Spells[spellName] = enabledState;
				if (enabledState ~= "disable") then
					SpellsEnabledCache[spellName] = enabledState;
				end
			end
		end
		-- // starting OnUpdate()
		EventFrame:SetScript("OnUpdate", function(self, elapsed)
			ElapsedTimer = ElapsedTimer + elapsed;
			if (ElapsedTimer >= 1) then
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
		if (NameplateAurasDB[LocalPlayerFullName] == nil) then
			NameplateAurasDB[LocalPlayerFullName] = { };
		end
		local defaults = {
			StandardSpells = { },
			CustomSpells = { },
			IconSize = 45,
			IconXOffset = 0,
			IconYOffset = 50,
			FullOpacityAlways = false,
			Font = "NAuras_TeenBold",
			DisplayBorders = true,
		};
		for key, value in pairs(defaults) do
			if (NameplateAurasDB[LocalPlayerFullName][key] == nil) then
				NameplateAurasDB[LocalPlayerFullName][key] = value;
			end
		end
		db = NameplateAurasDB[LocalPlayerFullName];
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

	function AllocateIcon(frame)
		if (not frame.NAurasFrame) then
			frame.NAurasFrame = CreateFrame("frame", nil, db.FullOpacityAlways and WorldFrame or frame);
			frame.NAurasFrame:SetWidth(db.IconSize);
			frame.NAurasFrame:SetHeight(db.IconSize);
			frame.NAurasFrame:SetPoint("CENTER", frame, db.IconXOffset, db.IconYOffset);
			frame.NAurasFrame:Show();
		end
		local texture = frame.NAurasFrame:CreateTexture(nil, "BORDER");
		texture:SetPoint("LEFT", frame.NAurasFrame, frame.NAurasIconsCount * db.IconSize, 0);
		texture:SetWidth(db.IconSize);
		texture:SetHeight(db.IconSize);
		texture:Hide();
		texture.cooldown = frame.NAurasFrame:CreateFontString(nil, "OVERLAY");
		texture.cooldown:SetTextColor(0.7, 1, 0);
		texture.cooldown:SetAllPoints(texture);
		texture.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil(db.IconSize - db.IconSize / 2), "OUTLINE");
		texture.border = frame.NAurasFrame:CreateTexture(nil, "OVERLAY");
		texture.border:SetTexture("Interface\\AddOns\\NameplateAuras\\media\\CooldownFrameBorder.tga");
		texture.border:SetVertexColor(1, 0.35, 0);
		texture.border:SetAllPoints(texture);
		texture.border:Hide();
		texture.stacks = frame.NAurasFrame:CreateFontString(nil, "OVERLAY");
		texture.stacks:SetTextColor(1, 0.1, 0.1);
		texture.stacks:SetPoint("BOTTOMRIGHT", texture, -3, 5);
		texture.stacks:SetFont(SML:Fetch("font", db.Font), math_ceil(db.IconSize / 4), "OUTLINE");
		texture.stackcount = 0;
		frame.NAurasIconsCount = frame.NAurasIconsCount + 1;
		frame.NAurasFrame:SetWidth(db.IconSize * frame.NAurasIconsCount);
		tinsert(frame.NAurasIcons, texture);
	end
	
	function ReallocateAllIcons(clearSpells)
		for frame in pairs(Nameplates) do
			if (frame.NAurasFrame) then
				frame.NAurasFrame:SetPoint("CENTER", frame, db.IconXOffset, db.IconYOffset);
				frame.NAurasFrame:SetWidth(db.IconSize * frame.NAurasIconsCount);
				local counter = 0;
				for _, icon in pairs(frame.NAurasIcons) do
					icon:SetWidth(db.IconSize);
					icon:SetHeight(db.IconSize);
					icon:SetPoint("LEFT", frame.NAurasFrame, counter * db.IconSize, 0);
					icon.cooldown:SetFont(SML:Fetch("font", db.Font), math_ceil(db.IconSize - db.IconSize / 2), "OUTLINE");
					icon.stacks:SetFont(SML:Fetch("font", db.Font), math_ceil(db.IconSize / 4), "OUTLINE");
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
				--print(SpellsEnabledCache[buffName], buffName, buffStack, buffDuration, buffExpires, buffCaster, buffSpellID);
				if (SpellsEnabledCache[buffName] == "all" or (SpellsEnabledCache[buffName] == "my" and buffCaster == "player")) then
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
				--print(SpellsEnabledCache[debuffName], debuffName, debuffStack, debuffDuration, debuffExpires, debuffCaster, debuffSpellID);
				if (SpellsEnabledCache[debuffName] == "all" or (SpellsEnabledCache[debuffName] == "my" and debuffCaster == "player")) then
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
		if (nameplateAuras[frame]) then
			local currentTime = GetTime();
			for spellName, spellInfo in pairs(nameplateAuras[frame]) do
				local duration = spellInfo.duration;
				local last = spellInfo.expires - currentTime;
				if (last > 0) then
					if (counter > frame.NAurasIconsCount) then
						AllocateIcon(frame);
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
					else
						icon.cooldown:SetText(string_format("%.0f", last));
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
					if (not icon.shown) then
						ShowCDIcon(icon);
					end
					counter = counter + 1;
				end
			end
		end
		if (frame.NAurasFrame ~= nil) then
			frame.NAurasFrame:SetWidth(db.IconSize * (counter - 1));
		end
		for k = counter, frame.NAurasIconsCount do
			local icon = frame.NAurasIcons[k];
			if (icon.shown) then
				HideCDIcon(icon);
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
	end
	
	function ShowCDIcon(icon)
		icon.cooldown:Show();
		icon.stacks:Show();
		icon:Show();
		icon.shown = true;
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
				for spellID, spellInfo in pairs(nameplateAuras[frame]) do
					local duration = spellInfo.duration;
					local last = spellInfo.expires - currentTime;
					if (last > 0) then
						-- // allocating icon if need
						if (counter > frame.NAurasIconsCount) then
							AllocateIcon(frame);
						end
						-- // getting reference to icon
						local icon = frame.NAurasIcons[counter];
						-- // setting texture if need
						if (icon.spellID ~= spellID) then
							icon:SetTexture(TextureCache[spellInfo.spellID]);
							icon.spellID = spellID;
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
						-- // setting text
						if (last > 3600) then
							icon.cooldown:SetText("Inf");
						elseif (last >= 60) then
							icon.cooldown:SetText(math_floor(last/60).."m");
						else
							icon.cooldown:SetText(string_format("%.0f", last));
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
						-- // show icon if need
						if (not icon.shown) then
							ShowCDIcon(icon);
						end
						counter = counter + 1;
					else
						nameplateAuras[frame][spellID] = nil;
					end
				end
			end
			for k = counter, frame.NAurasIconsCount do
				if (frame.NAurasIcons[k].shown) then
					HideCDIcon(frame.NAurasIcons[k]);
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
		
		for index, value in pairs({L["General"], L["Profiles"], L["Standard spells"], L["User-defined spells"]}) do
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
				GUICategory_4(index, value);
			end
		end
	end

	function GUICategory_1(index, value)
		local buttonSwitchTestMode = GUICreateButton("NAuras_GUIGeneralButtonSwitchTestMode", GUIFrame, L["Enable test mode (need at least one visible nameplate)"]);
		buttonSwitchTestMode:SetWidth(340);
		buttonSwitchTestMode:SetHeight(40);
		buttonSwitchTestMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -40);
		buttonSwitchTestMode:SetScript("OnClick", function(self, ...)
			if (not TestFrame or not TestFrame:GetScript("OnUpdate")) then
				EnableTestMode();
				self.Text:SetText(L["Disable test mode"]);
			else
				DisableTestMode();
				self.Text:SetText(L["Enable test mode (need at least one visible nameplate)"]);
			end
		end);
		table.insert(GUIFrame.Categories[index], buttonSwitchTestMode);
		
		local sliderIconSize = GUICreateSlider(GUIFrame, 160, -90, 340, "NAuras_GUIGeneralSliderIconSize");
		sliderIconSize.label:SetText(L["Icon size"]);
		sliderIconSize.slider:SetValueStep(1);
		sliderIconSize.slider:SetMinMaxValues(1, 75);
		sliderIconSize.slider:SetValue(db.IconSize);
		sliderIconSize.slider:SetScript("OnValueChanged", function(self, value)
			sliderIconSize.editbox:SetText(tostring(math_ceil(value)));
			db.IconSize = math_ceil(value);
			ReallocateAllIcons(false);
		end);
		sliderIconSize.editbox:SetText(tostring(db.IconSize));
		sliderIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconSize.editbox:GetText());
				if (v == nil) then
					sliderIconSize.editbox:SetText(tostring(db.IconSize));
					Print(L["Value must be a number"]);
				else
					if (v > 75) then
						v = 75;
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
		sliderIconSize.hightext:SetText("75");
		table.insert(GUIFrame.Categories[index], sliderIconSize);
		
		local sliderIconXOffset = GUICreateSlider(GUIFrame, 160, -150, 155, "NAuras_GUIGeneralSliderIconXOffset");
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
		
		local sliderIconYOffset = GUICreateSlider(GUIFrame, 345, -150, 155, "NAuras_GUIGeneralSliderIconYOffset");
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
		
		local checkBoxFullOpacityAlways = GUICreateCheckBox(160, -220, L["Always display CD icons at full opacity (ReloadUI is needed)"], function(this)
			db.FullOpacityAlways = this:GetChecked();
		end, "NAuras_GUI_General_CheckBoxFullOpacityAlways");
		checkBoxFullOpacityAlways:SetChecked(db.FullOpacityAlways);
		table.insert(GUIFrame.Categories[index], checkBoxFullOpacityAlways);
		
		local checkBoxDisplayBorders = GUICreateCheckBox(160, -240, "Display red/green borders", function(this)
			db.DisplayBorders = this:GetChecked();
			ReallocateAllIcons(true);
		end, "NAuras.GUI.Cat1.CheckBoxDisplayBorders");
		checkBoxDisplayBorders:SetChecked(db.DisplayBorders);
		table.insert(GUIFrame.Categories[index], checkBoxDisplayBorders);
		
		local dropdownFont = CreateFrame("Frame", "NAuras_GUI_General_DropdownFont", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownFont, 150);
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
				NAuras_GUIGeneralSliderIconSize.slider:SetValue(db.IconSize);
				NAuras_GUIGeneralSliderIconSize.editbox:SetText(tostring(db.IconSize));
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
		local scrollAreaBackground = CreateFrame("Frame", "NAuras_GUIScrollFrameBackground_"..tostring(index - 1), GUIFrame);
		scrollAreaBackground:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 150, -60);
		scrollAreaBackground:SetPoint("BOTTOMRIGHT", GUIFrame, "BOTTOMRIGHT", -30, 15);
		scrollAreaBackground:SetBackdrop({
			bgFile = "Interface\\AddOns\\NameplateAuras\\media\\Smudge.tga",
			edgeFile = "Interface\\AddOns\\NameplateAuras\\media\\Border",
			tile = true, edgeSize = 3, tileSize = 1,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		});
		local bRed, bGreen, bBlue = GUIFrame:GetBackdropColor();
		scrollAreaBackground:SetBackdropColor(bRed, bGreen, bBlue, 0.8)
		scrollAreaBackground:SetBackdropBorderColor(0.3, 0.3, 0.5, 1);
		scrollAreaBackground:Hide();
		table.insert(GUIFrame.Categories[index], scrollAreaBackground);
		
		local scrollArea = CreateFrame("ScrollFrame", "NAuras_GUIScrollFrame_"..tostring(index - 1), scrollAreaBackground, "UIPanelScrollFrameTemplate");
		scrollArea:SetPoint("TOPLEFT", scrollAreaBackground, "TOPLEFT", 5, -5);
		scrollArea:SetPoint("BOTTOMRIGHT", scrollAreaBackground, "BOTTOMRIGHT", -5, 5);
		scrollArea:Show();
		
		local scrollAreaChildFrame = CreateFrame("Frame", "NAuras_GUIScrollFrameChildFrame_"..tostring(index - 1), scrollArea);
		scrollArea:SetScrollChild(scrollAreaChildFrame);
		scrollAreaChildFrame:SetPoint("CENTER", GUIFrame, "CENTER", 0, 1);
		scrollAreaChildFrame:SetWidth(288);
		scrollAreaChildFrame:SetHeight(288);
		
		local iterator = 1;
		for spellID in pairs(StandardSpells) do
			local n, _, icon = GetSpellInfo(spellID);
			if (not n) then
				Print(format(L["Unknown spell: %s"], spellID));
			else
				local dropdown, text, button = GUICreateCmbboxTextureText("NAuras_GUI_Cat3_Spell"..tostring(iterator), scrollAreaChildFrame, -10, ((iterator - 1) * -22) - 10)
				local info = {};
				dropdown.initialize = function()
					wipe(info);
					for idx, v in pairs({"disable", "all", "my"}) do
						info.text = v;
						info.value = v;
						info.func = function(self)
							db.StandardSpells[spellID] = self.value;
							if (self.value ~= "disable") then
								SpellsEnabledCache[n] = self.value;
							else
								SpellsEnabledCache[n] = nil;
							end
							_G[dropdown:GetName().."Text"]:SetText(self:GetText());
						end
						info.checked = v == db.StandardSpells[spellID];
						UIDropDownMenu_AddButton(info);
					end
				end
				_G[dropdown:GetName().."Text"]:SetText(db.StandardSpells[spellID]);
				text:SetText(n);
				button.texture:SetTexture(icon);
				button:SetScript("OnEnter", function(self, ...)
					GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT");
					GameTooltip:SetSpellByID(spellID);
					GameTooltip:Show();
				end)
				button:SetScript("OnLeave", function(self, ...)
					GameTooltip:Hide();
				end)
				iterator = iterator + 1;
				dropdown.spellID = spellID;
				--tinsert(GUIFrame.CustomSpellsDropdowns, dropdown);
			end
		end
	end
	
	function GUICategory_4(index, value)
		local scrollAreaBackground = CreateFrame("Frame", "NAuras_GUIScrollFrameBackground_"..tostring(index - 1), GUIFrame);
		scrollAreaBackground:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 150, -60);
		scrollAreaBackground:SetPoint("BOTTOMRIGHT", GUIFrame, "BOTTOMRIGHT", -30, 15);
		scrollAreaBackground:SetBackdrop({
			bgFile = "Interface\\AddOns\\NameplateAuras\\media\\Smudge.tga",
			edgeFile = "Interface\\AddOns\\NameplateAuras\\media\\Border",
			tile = true, edgeSize = 3, tileSize = 1,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		});
		local bRed, bGreen, bBlue = GUIFrame:GetBackdropColor();
		scrollAreaBackground:SetBackdropColor(bRed, bGreen, bBlue, 0.8)
		scrollAreaBackground:SetBackdropBorderColor(0.3, 0.3, 0.5, 1);
		scrollAreaBackground:Hide();
		table.insert(GUIFrame.Categories[index], scrollAreaBackground);
		
		local scrollArea = CreateFrame("ScrollFrame", "NAuras_GUIScrollFrame_"..tostring(index - 1), scrollAreaBackground, "UIPanelScrollFrameTemplate");
		scrollArea:SetPoint("TOPLEFT", scrollAreaBackground, "TOPLEFT", 5, -5);
		scrollArea:SetPoint("BOTTOMRIGHT", scrollAreaBackground, "BOTTOMRIGHT", -5, 5);
		scrollArea:Show();
		
		local scrollAreaChildFrame = CreateFrame("Frame", "NAuras_GUIScrollFrameChildFrame_"..tostring(index - 1), scrollArea);
		scrollArea:SetScrollChild(scrollAreaChildFrame);
		scrollAreaChildFrame:SetPoint("CENTER", GUIFrame, "CENTER", 0, 1);
		scrollAreaChildFrame:SetWidth(288);
		scrollAreaChildFrame:SetHeight(288);
		
		
		
		local iterator = 1;
		local nameIterator = 1
		local function CreateSpellEntry(spellID)
			local n, _, icon = GetSpellInfo(spellID);
			local dropdown, text, button = GUICreateCmbboxTextureText("NAuras_GUI_Cat4_Spell"..tostring(nameIterator), scrollAreaChildFrame, -10, ((iterator - 1) * -22) - 10)
			local info = {};
			dropdown.initialize = function()
				wipe(info);
				for idx, v in pairs({"disable", "all", "my"}) do
					info.text = v;
					info.value = v;
					info.func = function(self)
						db.CustomSpells[spellID] = self.value;
						if (self.value ~= "disable") then
							SpellsEnabledCache[n] = self.value;
						else
							SpellsEnabledCache[n] = nil;
						end
						_G[dropdown:GetName().."Text"]:SetText(self:GetText());
					end
					info.checked = v == db.CustomSpells[spellID];
					UIDropDownMenu_AddButton(info);
				end
			end
			_G[dropdown:GetName().."Text"]:SetText(db.CustomSpells[spellID]);
			text:SetText(n);
			button.texture:SetTexture(icon);
			button:SetScript("OnEnter", function(self, ...)
				GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT");
				GameTooltip:SetSpellByID(spellID);
				GameTooltip:Show();
			end)
			button:SetScript("OnLeave", function(self, ...)
				GameTooltip:Hide();
			end)
			iterator = iterator + 1;
			nameIterator = nameIterator + 1;
			dropdown.spellName = GetSpellInfo(spellID);
			tinsert(GUIFrame.CustomSpellsDropdowns, dropdown);
		end
		
		local function RebuildListOfDropdowns()
			iterator = 1;
			for _, dropdown in pairs(GUIFrame.CustomSpellsDropdowns) do
				if (dropdown.spellName ~= nil) then
					print(dropdown.spellName, iterator, dropdown:IsVisible());
					dropdown:SetPoint("TOPLEFT", scrollAreaChildFrame, "TOPLEFT", -10, ((iterator - 1) * -22) - 10);
					iterator = iterator + 1;
				end
			end
		end
		
		local editboxAddSpell = CreateFrame("EditBox", nil, GUIFrame);
		editboxAddSpell:SetAutoFocus(false);
		editboxAddSpell:SetFontObject(GameFontHighlightSmall);
		editboxAddSpell:SetPoint("TOPLEFT", GUIFrame, 250, -12);
		editboxAddSpell:SetHeight(20);
		editboxAddSpell:SetWidth(150);
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
		local text = editboxAddSpell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		text:SetPoint("RIGHT", -155, 0);
		text:SetText("Add new spell: "); -- todo:localization
		table.insert(GUIFrame.Categories[index], editboxAddSpell);
		
		local buttonAddSpell = GUICreateButton("ghggggggggggggggghghg", GUIFrame, "Add spell"); -- todo:localization; todo:publicname
		buttonAddSpell:SetWidth(90);
		buttonAddSpell:SetHeight(20);
		buttonAddSpell:SetPoint("LEFT", editboxAddSpell, "RIGHT", 10, 0);
		buttonAddSpell:SetScript("OnClick", function(self, ...)
			local text = editboxAddSpell:GetText();
			local textAsNumber = tonumber(text);
			if (textAsNumber ~= nil) then
				local n, _, icon = GetSpellInfo(textAsNumber);
				if (not n) then
					Print(format(L["Unknown spell: %s"], text));
				else
					local alreadyExist = false;
					for spellID in pairs(StandardSpells) do
						local spellName = GetSpellInfo(spellID);
						if (spellName == n) then
							alreadyExist = true;
						end
					end
					for spellID in pairs(db.CustomSpells) do
						local spellName = GetSpellInfo(spellID);
						if (spellName == n) then
							alreadyExist = true;
						end
					end
					if (not alreadyExist) then
						db.CustomSpells[textAsNumber] = "all";
						SpellsEnabledCache[n] = "all";
						CreateSpellEntry(textAsNumber);
					else
						Print("Spell is already exists ("..n..")"); -- todo:localization
					end
				end
				editboxAddSpell:SetText("");
			else
				Print("Please enter spell ID, not spell name"); -- todo:localization
			end
		end);
		table.insert(GUIFrame.Categories[index], buttonAddSpell);
		
		local dropdownRemoveSpell = CreateFrame("Frame", "NAuras_GUI_Cat4_CmbboxRemoveSpell", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownRemoveSpell, 135);
		dropdownRemoveSpell:SetPoint("TOPLEFT", GUIFrame, 233, -34);
		local info = {};
		dropdownRemoveSpell.initialize = function()
			wipe(info);
			for spellID in pairs(db.CustomSpells) do
				info.text = GetSpellInfo(spellID);
				info.value = spellID;
				info.func = function(self)
					local spellName = GetSpellInfo(spellID);
					db.CustomSpells[self.value] = nil;
					SpellsEnabledCache[spellName] = nil;
					for _, dropdown in pairs(GUIFrame.CustomSpellsDropdowns) do
						if (dropdown.spellName == spellName) then
							dropdown:Hide();
							dropdown.spellName = nil;
						end
					end
					RebuildListOfDropdowns();
					_G[dropdownRemoveSpell:GetName().."Text"]:SetText("");
					--UIDropDownMenu_Initialize(dropdownRemoveSpell, dropdownRemoveSpell.initialize);
				end
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownRemoveSpell:GetName().."Text"]:SetText(db.CustomSpells[spellID]);
		local text = dropdownRemoveSpell:CreateFontString("NAuras_GUI_Cat4_CmbboxRemoveSpell_Label", "ARTWORK", "GameFontNormalSmall");
		text:SetPoint("RIGHT", -171, 0);
		text:SetText("Remove spell: "); -- todo:localization
		table.insert(GUIFrame.Categories[index], dropdownRemoveSpell);
		
		
		for spellID in pairs(db.CustomSpells) do
			local n, _, icon = GetSpellInfo(spellID);
			if (not n) then
				Print(format(L["Unknown spell: %s"], spellID));
			else
				CreateSpellEntry(spellID);
			end
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
		frame.label:SetHeight(15);
		
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
