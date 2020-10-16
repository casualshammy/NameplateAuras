local addonName, addonTable = ...;
local VGUI = LibStub("LibRedDropdown-1.0");
local L = LibStub("AceLocale-3.0"):GetLocale("NameplateAuras");
local SML = LibStub("LibSharedMedia-3.0");

local 	_G, pairs, select, WorldFrame, string_match,string_gsub,string_find,string_format, 	GetTime, math_ceil, math_floor, wipe, C_NamePlate_GetNamePlateForUnit, UnitBuff, UnitDebuff, string_lower,
			UnitReaction, UnitGUID, UnitIsFriend, table_insert, table_sort, table_remove, IsUsableSpell, CTimerAfter,	bit_band, math_max, CTimerNewTimer,   strsplit =
		_G, pairs, select, WorldFrame, strmatch, 	gsub,		strfind, 	format,			GetTime, ceil,		floor,		wipe, C_NamePlate.GetNamePlateForUnit, UnitBuff, UnitDebuff, string.lower,
			UnitReaction, UnitGUID, UnitIsFriend, table.insert, table.sort, table.remove, IsUsableSpell, C_Timer.After,	bit.band, math.max, C_Timer.NewTimer, strsplit;

local AllSpellIDsAndIconsByName, GUIFrame = { };

-- // consts
local CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS, AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY, AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE,
	AURA_SORT_MODE_AURATYPE_EXPIRE, CONST_SPELL_PVP_MODES_UNDEFINED, CONST_SPELL_PVP_MODES_INPVPCOMBAT,
	CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT, GLOW_TIME_INFINITE, EXPLOSIVE_ORB_SPELL_ID, VERY_LONG_COOLDOWN_DURATION, BORDER_TEXTURES;
do
	CONST_SPELL_MODE_DISABLED, CONST_SPELL_MODE_ALL, CONST_SPELL_MODE_MYAURAS = addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_ALL, addonTable.CONST_SPELL_MODE_MYAURAS;
	AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY = addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY;
	AURA_SORT_MODE_NONE, AURA_SORT_MODE_EXPIRETIME, AURA_SORT_MODE_ICONSIZE, AURA_SORT_MODE_AURATYPE_EXPIRE =
		addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIRETIME, addonTable.AURA_SORT_MODE_ICONSIZE, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE;
	CONST_SPELL_PVP_MODES_UNDEFINED, CONST_SPELL_PVP_MODES_INPVPCOMBAT, CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT = addonTable.CONST_SPELL_PVP_MODES_UNDEFINED, addonTable.CONST_SPELL_PVP_MODES_INPVPCOMBAT, addonTable.CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT;
	GLOW_TIME_INFINITE = addonTable.GLOW_TIME_INFINITE; -- // 30 days
	EXPLOSIVE_ORB_SPELL_ID = addonTable.EXPLOSIVE_ORB_SPELL_ID;
	VERY_LONG_COOLDOWN_DURATION = addonTable.VERY_LONG_COOLDOWN_DURATION; -- // 30 days
	BORDER_TEXTURES = addonTable.BORDER_TEXTURES;
end

-- // utilities
local Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID, CoroutineProcessor;
do

	Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID, CoroutineProcessor =
		addonTable.Print, addonTable.msg, addonTable.msgWithQuestion, addonTable.table_count, addonTable.SpellTextureByID, addonTable.SpellNameByID, addonTable.UnitClassByGUID, addonTable.CoroutineProcessor;

end


function addonTable.OnSpellInfoCachesReady()

end

local function GetDefaultDBSpellEntry(enabledState, spellName, checkSpellID)
	return {
		["enabledState"] =				enabledState,
		["auraType"] =					AURA_TYPE_ANY,
		["iconSizeWidth"] =				addonTable.db.DefaultIconSizeWidth,
		["iconSizeHeight"] =			addonTable.db.DefaultIconSizeHeight,
		["spellName"] =					spellName,
		["checkSpellID"] =				checkSpellID,
		["showOnFriends"] =				true,
		["showOnEnemies"] =				true,
		["pvpCombat"] =					CONST_SPELL_PVP_MODES_UNDEFINED,
		["showGlow"] =					nil,
		["glowType"] =					addonTable.GLOW_TYPE_AUTOUSE,
		["animationType"] =				addonTable.ICON_ANIMATION_TYPE_ALPHA,
		["animationTimer"] =			10,
		["animationDisplayMode"] =		addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE,
	};
end

local function ShowGUICategory(index)
	for i, v in pairs(GUIFrame.Categories) do
		for k, l in pairs(v) do
			l:Hide();
		end
	end
	for i, v in pairs(GUIFrame.Categories[index]) do
		v:Show();
	end
end

local function OnGUICategoryClick(self, ...)
	GUIFrame.CategoryButtons[GUIFrame.ActiveCategory].text:SetTextColor(1, 0.82, 0);
	GUIFrame.CategoryButtons[GUIFrame.ActiveCategory]:UnlockHighlight();
	GUIFrame.ActiveCategory = self.index;
	self.text:SetTextColor(1, 1, 1);
	self:LockHighlight();
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	ShowGUICategory(GUIFrame.ActiveCategory);
end

local function CreateGUICategory()
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

local function GUICategory_1(index, value)

	local checkBoxHideBlizzardFrames, checkBoxHidePlayerBlizzardFrame, checkBoxShowAurasOnPlayerNameplate,
		checkBoxShowAboveFriendlyUnits, checkBoxShowMyAuras, checkboxAuraTooltip, checkboxShowCooldownAnimation;

	-- checkBoxHideBlizzardFrames
	do
		checkBoxHideBlizzardFrames = VGUI.CreateCheckBox();
		checkBoxHideBlizzardFrames:SetText(L["options:general:hide-blizz-frames"]);
		checkBoxHideBlizzardFrames:SetOnClickHandler(function(this)
			addonTable.db.HideBlizzardFrames = this:GetChecked();
			addonTable.PopupReloadUI();
		end);
		checkBoxHideBlizzardFrames:SetChecked(addonTable.db.HideBlizzardFrames);
		checkBoxHideBlizzardFrames:SetParent(GUIFrame);
		checkBoxHideBlizzardFrames:SetPoint("TOPLEFT", GUIFrame, 160, -20);
		table_insert(GUIFrame.Categories[index], checkBoxHideBlizzardFrames);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			if (checkBoxHideBlizzardFrames:GetChecked() ~= addonTable.db.HideBlizzardFrames) then
				addonTable.PopupReloadUI();
			end
			checkBoxHideBlizzardFrames:SetChecked(addonTable.db.HideBlizzardFrames);
		end);
	end

	-- checkBoxHidePlayerBlizzardFrame
	do
		checkBoxHidePlayerBlizzardFrame = VGUI.CreateCheckBox();
		checkBoxHidePlayerBlizzardFrame:SetText(L["options:general:hide-player-blizz-frame"]);
		checkBoxHidePlayerBlizzardFrame:SetOnClickHandler(function(this)
			addonTable.db.HidePlayerBlizzardFrame = this:GetChecked();
			addonTable.PopupReloadUI();
		end);
		checkBoxHidePlayerBlizzardFrame:SetChecked(addonTable.db.HidePlayerBlizzardFrame);
		checkBoxHidePlayerBlizzardFrame:SetParent(GUIFrame);
		checkBoxHidePlayerBlizzardFrame:SetPoint("TOPLEFT", checkBoxHideBlizzardFrames, "BOTTOMLEFT", 0, 0);
		table_insert(GUIFrame.Categories[index], checkBoxHidePlayerBlizzardFrame);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			if (checkBoxHidePlayerBlizzardFrame:GetChecked() ~= addonTable.db.HidePlayerBlizzardFrame) then
				addonTable.PopupReloadUI();
			end
			checkBoxHidePlayerBlizzardFrame:SetChecked(addonTable.db.HidePlayerBlizzardFrame);
		end);
	end

	-- // checkBoxShowAurasOnPlayerNameplate
	do
		checkBoxShowAurasOnPlayerNameplate = VGUI.CreateCheckBox();
		checkBoxShowAurasOnPlayerNameplate:SetText(L["Display auras on player's nameplate"]);
		checkBoxShowAurasOnPlayerNameplate:SetOnClickHandler(function(this)
			addonTable.db.ShowAurasOnPlayerNameplate = this:GetChecked();
		end);
		checkBoxShowAurasOnPlayerNameplate:SetChecked(addonTable.db.ShowAurasOnPlayerNameplate);
		checkBoxShowAurasOnPlayerNameplate:SetParent(GUIFrame);
		checkBoxShowAurasOnPlayerNameplate:SetPoint("TOPLEFT", checkBoxHidePlayerBlizzardFrame, "BOTTOMLEFT", 0, 0);
		table_insert(GUIFrame.Categories[index], checkBoxShowAurasOnPlayerNameplate);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowAurasOnPlayerNameplate:SetChecked(addonTable.db.ShowAurasOnPlayerNameplate); end);

	end

	-- // checkBoxShowAboveFriendlyUnits
	do
		checkBoxShowAboveFriendlyUnits = VGUI.CreateCheckBox();
		checkBoxShowAboveFriendlyUnits:SetText(L["Display auras on nameplates of friendly units"]);
		checkBoxShowAboveFriendlyUnits:SetOnClickHandler(function(this)
			addonTable.db.ShowAboveFriendlyUnits = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
		end);
		checkBoxShowAboveFriendlyUnits:SetChecked(addonTable.db.ShowAboveFriendlyUnits);
		checkBoxShowAboveFriendlyUnits:SetParent(GUIFrame);
		checkBoxShowAboveFriendlyUnits:SetPoint("TOPLEFT", checkBoxShowAurasOnPlayerNameplate, "BOTTOMLEFT", 0, 0);
		table_insert(GUIFrame.Categories[index], checkBoxShowAboveFriendlyUnits);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowAboveFriendlyUnits:SetChecked(addonTable.db.ShowAboveFriendlyUnits); end);

	end

	-- // checkBoxShowMyAuras
	do
		checkBoxShowMyAuras = VGUI.CreateCheckBox();
		checkBoxShowMyAuras:SetText(L["Always show auras cast by myself"]);
		checkBoxShowMyAuras:SetOnClickHandler(function(this)
			addonTable.db.AlwaysShowMyAuras = this:GetChecked();
			addonTable.UpdateAllNameplates(false);
		end);
		checkBoxShowMyAuras:SetChecked(addonTable.db.AlwaysShowMyAuras);
		checkBoxShowMyAuras:SetParent(GUIFrame);
		checkBoxShowMyAuras:SetPoint("TOPLEFT", checkBoxShowAboveFriendlyUnits, "BOTTOMLEFT", 0, 0);
		VGUI.SetTooltip(checkBoxShowMyAuras, L["options:general:always-show-my-auras:tooltip"]);
		table_insert(GUIFrame.Categories[index], checkBoxShowMyAuras);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxShowMyAuras:SetChecked(addonTable.db.AlwaysShowMyAuras); end);

	end

	-- // checkboxAuraTooltip
	do
		checkboxAuraTooltip = VGUI.CreateCheckBox();
		checkboxAuraTooltip:SetText(L["options:general:show-aura-tooltip"]);
		checkboxAuraTooltip:SetOnClickHandler(function(this)
			addonTable.db.ShowAuraTooltip = this:GetChecked();
			for _, icon in pairs(addonTable.AllAuraIconFrames) do
				addonTable.AllocateIcon_SetAuraTooltip(icon);
			end
			GameTooltip:Hide();
		end);
		checkboxAuraTooltip:SetChecked(addonTable.db.ShowAuraTooltip);
		checkboxAuraTooltip:SetParent(GUIFrame);
		checkboxAuraTooltip:SetPoint("TOPLEFT", checkBoxShowMyAuras, "BOTTOMLEFT", 0, 0);
		table_insert(GUIFrame.Categories[index], checkboxAuraTooltip);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxAuraTooltip:SetChecked(addonTable.db.ShowAuraTooltip); end);

	end

	-- // checkboxShowCooldownAnimation
	do
		checkboxShowCooldownAnimation = VGUI.CreateCheckBox();
		checkboxShowCooldownAnimation:SetText(L["options:general:show-cooldown-animation"]);
		checkboxShowCooldownAnimation:SetOnClickHandler(function(this)
			addonTable.db.ShowCooldownAnimation = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
		end);
		checkboxShowCooldownAnimation:SetChecked(addonTable.db.ShowCooldownAnimation);
		checkboxShowCooldownAnimation:SetParent(GUIFrame);
		checkboxShowCooldownAnimation:SetPoint("TOPLEFT", checkboxAuraTooltip, "BOTTOMLEFT", 0, 0);
		table_insert(GUIFrame.Categories[index], checkboxShowCooldownAnimation);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkboxShowCooldownAnimation:SetChecked(addonTable.db.ShowCooldownAnimation); end);

	end

end

local function GUICategory_Fonts(index, value)
	local dropdownMenuFont = VGUI.CreateDropdownMenu();
	local textAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
	local textAnchorsLocalization = {
		[textAnchors[1]] = L["anchor-point:topright"],
		[textAnchors[2]] = L["anchor-point:right"],
		[textAnchors[3]] = L["anchor-point:bottomright"],
		[textAnchors[4]] = L["anchor-point:top"],
		[textAnchors[5]] = L["anchor-point:center"],
		[textAnchors[6]] = L["anchor-point:bottom"],
		[textAnchors[7]] = L["anchor-point:topleft"],
		[textAnchors[8]] = L["anchor-point:left"],
		[textAnchors[9]] = L["anchor-point:bottomleft"]
	};
	local sliderTimerFontScale, sliderTimerFontSize, timerTextColorArea, tenthsOfSecondsArea, checkboxShowCooldownText, auraTextArea, buttonFont, checkBoxUseRelativeFontSize, sliderTimerTextXOffset;
	local dropdownTimerTextAnchor, sliderTimerTextYOffset;

	-- // checkboxShowCooldownText
	do
		checkboxShowCooldownText = VGUI.CreateCheckBox();
		checkboxShowCooldownText:SetText(L["options:general:show-cooldown-text"]);
		checkboxShowCooldownText:SetOnClickHandler(function(this)
			addonTable.db.ShowCooldownText = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
			if (addonTable.db.ShowCooldownText) then
				auraTextArea:Show();
			else
				auraTextArea:Hide();
			end
		end);
		checkboxShowCooldownText:SetChecked(addonTable.db.ShowCooldownText);
		checkboxShowCooldownText:SetParent(GUIFrame);
		checkboxShowCooldownText:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -20);
		table_insert(GUIFrame.Categories[index], checkboxShowCooldownText);
		table_insert(GUIFrame.OnDBChangedHandlers, function() 
			checkboxShowCooldownText:SetChecked(addonTable.db.ShowCooldownText);
			addonTable.UpdateAllNameplates(true);
		end);
		checkboxShowCooldownText:SetScript("OnShow", function(self)
			if (addonTable.db.ShowCooldownText) then
				auraTextArea:Show();
			else
				auraTextArea:Hide();
			end
		end);
		checkboxShowCooldownText:SetScript("OnHide", function(self)
			auraTextArea:Hide();
		end);
	end

	-- // auraTextArea;
	do
		auraTextArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		auraTextArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		auraTextArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		auraTextArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		auraTextArea:SetPoint("TOPLEFT", checkboxShowCooldownText, "BOTTOMLEFT", 0, 0);
		auraTextArea:SetPoint("BOTTOMRIGHT", GUIFrame.ControlsFrame, "BOTTOMRIGHT", 0, 0);
		auraTextArea:Hide();
	end

	-- // dropdownFont
	do
		local fonts = { };
		buttonFont = VGUI.CreateButton();
		buttonFont:SetParent(auraTextArea);
		buttonFont:SetText(L["Font"] .. ": " .. addonTable.db.Font);

		for idx, font in next, SML:List("font") do
			table_insert(fonts, {
				["text"] = font,
				["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
				["func"] = function(info)
					buttonFont.Text:SetText(L["Font"] .. ": " .. info.text);
					addonTable.db.Font = info.text;
					addonTable.UpdateAllNameplates(true);
				end,
				["font"] = SML:Fetch("font", font),
			});
		end
		table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);

		buttonFont:SetHeight(24);
		buttonFont:SetPoint("TOPLEFT", auraTextArea, "TOPLEFT", 10, -10);
		buttonFont:SetPoint("TOPRIGHT", auraTextArea, "TOPRIGHT", -10, -10);
		buttonFont:SetScript("OnClick", function(self, ...)
			if (dropdownMenuFont:IsVisible()) then
				dropdownMenuFont:Hide();
			else
				dropdownMenuFont:SetList(fonts);
				dropdownMenuFont:SetParent(self);
				dropdownMenuFont:ClearAllPoints();
				dropdownMenuFont:SetPoint("TOP", self, "BOTTOM", 0, 0);
				dropdownMenuFont:Show();
			end
		end);
	end

	-- // checkBoxUseRelativeFontSize
	do

		checkBoxUseRelativeFontSize = VGUI.CreateCheckBox();
		checkBoxUseRelativeFontSize:SetText(L["options:timer-text:scale-font-size"]);
		checkBoxUseRelativeFontSize:SetOnClickHandler(function(this)
			addonTable.db.TimerTextUseRelativeScale = this:GetChecked();
			if (addonTable.db.TimerTextUseRelativeScale) then
				sliderTimerFontScale:Show();
				sliderTimerFontSize:Hide();
			else
				sliderTimerFontScale:Hide();
				sliderTimerFontSize:Show();
			end
		end);
		checkBoxUseRelativeFontSize:SetChecked(addonTable.db.TimerTextUseRelativeScale);
		checkBoxUseRelativeFontSize:SetParent(auraTextArea);
		checkBoxUseRelativeFontSize:SetPoint("TOPLEFT", buttonFont, "BOTTOMLEFT", 0, -10);
		table_insert(GUIFrame.Categories[index], checkBoxUseRelativeFontSize);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxUseRelativeFontSize:SetChecked(addonTable.db.TimerTextUseRelativeScale);
		end);
		checkBoxUseRelativeFontSize:SetScript("OnShow", function(self)
			if (addonTable.db.TimerTextUseRelativeScale) then
				sliderTimerFontScale:Show();
				sliderTimerFontSize:Hide();
			else
				sliderTimerFontScale:Hide();
				sliderTimerFontSize:Show();
			end
		end);
		checkBoxUseRelativeFontSize:SetScript("OnHide", function(self)
			sliderTimerFontScale:Hide();
			sliderTimerFontSize:Hide();
		end);

	end

	-- // sliderTimerFontScale
	do
		local minValue, maxValue = 0.3, 3;
		sliderTimerFontScale = VGUI.CreateSlider();
		sliderTimerFontScale:SetParent(auraTextArea);
		sliderTimerFontScale:SetWidth(170);
		sliderTimerFontScale:SetPoint("TOPLEFT", checkBoxUseRelativeFontSize, "BOTTOMLEFT", 0, -10);
		sliderTimerFontScale.label:SetText(L["Font scale"]);
		sliderTimerFontScale.slider:SetValueStep(0.1);
		sliderTimerFontScale.slider:SetMinMaxValues(minValue, maxValue);
		sliderTimerFontScale.slider:SetValue(addonTable.db.FontScale);
		sliderTimerFontScale.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.1f", value));
			sliderTimerFontScale.editbox:SetText(tostring(actualValue));
			addonTable.db.FontScale = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale));
		sliderTimerFontScale.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderTimerFontScale.editbox:GetText() ~= "") then
				local v = tonumber(sliderTimerFontScale.editbox:GetText());
				if (v == nil) then
					sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale));
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
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale));
			sliderTimerFontScale.slider:SetValue(addonTable.db.FontScale);
		end);
	end

	-- // sliderTimerTextXOffset
	do
		local minValue, maxValue = -100, 100;
		sliderTimerTextXOffset = VGUI.CreateSlider();
		sliderTimerTextXOffset:SetParent(auraTextArea);
		sliderTimerTextXOffset:SetWidth(170);
		sliderTimerTextXOffset:SetPoint("LEFT", sliderTimerFontScale, "RIGHT", 0, 0);
		sliderTimerTextXOffset.label:SetText(L["X offset"]);
		sliderTimerTextXOffset.slider:SetValueStep(1);
		sliderTimerTextXOffset.slider:SetMinMaxValues(minValue, maxValue);
		sliderTimerTextXOffset.slider:SetValue(addonTable.db.TimerTextXOffset);
		sliderTimerTextXOffset.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderTimerTextXOffset.editbox:SetText(tostring(actualValue));
			addonTable.db.TimerTextXOffset = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset));
		sliderTimerTextXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderTimerTextXOffset.editbox:GetText() ~= "") then
				local v = tonumber(sliderTimerTextXOffset.editbox:GetText());
				if (v == nil) then
					sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderTimerTextXOffset.slider:SetValue(v);
				end
				sliderTimerTextXOffset.editbox:ClearFocus();
			end
		end);
		sliderTimerTextXOffset.lowtext:SetText(tostring(minValue));
		sliderTimerTextXOffset.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset));
			sliderTimerTextXOffset.slider:SetValue(addonTable.db.TimerTextXOffset);
		end);
		sliderTimerTextXOffset:Show();
	end

	-- // sliderTimerTextYOffset
	do
		local minValue, maxValue = -100, 100;
		local sliderTimerTextYOffset = VGUI.CreateSlider();
		sliderTimerTextYOffset:SetParent(auraTextArea);
		sliderTimerTextYOffset:SetWidth(170);
		sliderTimerTextYOffset:SetPoint("LEFT", sliderTimerTextXOffset, "RIGHT", 0, 0);
		sliderTimerTextYOffset.label:SetText(L["Y offset"]);
		sliderTimerTextYOffset.slider:SetValueStep(1);
		sliderTimerTextYOffset.slider:SetMinMaxValues(minValue, maxValue);
		sliderTimerTextYOffset.slider:SetValue(addonTable.db.TimerTextYOffset);
		sliderTimerTextYOffset.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderTimerTextYOffset.editbox:SetText(tostring(actualValue));
			addonTable.db.TimerTextYOffset = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset));
		sliderTimerTextYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderTimerTextYOffset.editbox:GetText() ~= "") then
				local v = tonumber(sliderTimerTextYOffset.editbox:GetText());
				if (v == nil) then
					sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderTimerTextYOffset.slider:SetValue(v);
				end
				sliderTimerTextYOffset.editbox:ClearFocus();
			end
		end);
		sliderTimerTextYOffset.lowtext:SetText(tostring(minValue));
		sliderTimerTextYOffset.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset));
			sliderTimerTextYOffset.slider:SetValue(addonTable.db.TimerTextYOffset);
		end);
		sliderTimerTextYOffset:Show();
	end

	-- // sliderTimerFontSize
	do
		local minValue, maxValue = 6, 96;
		sliderTimerFontSize = VGUI.CreateSlider();
		sliderTimerFontSize:SetParent(auraTextArea);
		sliderTimerFontSize:SetWidth(170);
		sliderTimerFontSize:SetPoint("TOPLEFT", checkBoxUseRelativeFontSize, "BOTTOMLEFT", 0, -10);
		sliderTimerFontSize.label:SetText(L["Font size"]);
		sliderTimerFontSize.slider:SetValueStep(1);
		sliderTimerFontSize.slider:SetMinMaxValues(minValue, maxValue);
		sliderTimerFontSize.slider:SetValue(addonTable.db.TimerTextSize);
		sliderTimerFontSize.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderTimerFontSize.editbox:SetText(tostring(actualValue));
			addonTable.db.TimerTextSize = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderTimerFontSize.editbox:SetText(tostring(addonTable.db.TimerTextSize));
		sliderTimerFontSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderTimerFontSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderTimerFontSize.editbox:GetText());
				if (v == nil) then
					sliderTimerFontSize.editbox:SetText(tostring(addonTable.db.TimerTextSize));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderTimerFontSize.slider:SetValue(v);
				end
				sliderTimerFontSize.editbox:ClearFocus();
			end
		end);
		sliderTimerFontSize.lowtext:SetText(tostring(minValue));
		sliderTimerFontSize.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontSize.editbox:SetText(tostring(addonTable.db.TimerTextSize)); sliderTimerFontSize.slider:SetValue(addonTable.db.TimerTextSize); end);
	end

	-- // dropdownTimerTextAnchor
	do
		dropdownTimerTextAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchor", auraTextArea, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownTimerTextAnchor, 210);
		dropdownTimerTextAnchor:SetPoint("TOPLEFT", sliderTimerFontScale, "BOTTOMLEFT", 0, 20);
		local info = {};
		dropdownTimerTextAnchor.initialize = function()
			wipe(info);
			for _, anchorPoint in pairs(textAnchors) do
				info.text = textAnchorsLocalization[anchorPoint];
				info.value = anchorPoint;
				info.func = function(self)
					addonTable.db.TimerTextAnchor = self.value;
					_G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = anchorPoint == addonTable.db.TimerTextAnchor;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchor]);
		dropdownTimerTextAnchor.text = dropdownTimerTextAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownTimerTextAnchor.text:SetPoint("LEFT", 20, 20);
		dropdownTimerTextAnchor.text:SetText(L["Anchor point"]);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchor]); end);
	end

	-- // dropdownTimerTextAnchorIcon
	do
		local dropdownTimerTextAnchorIcon = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchorIcon", auraTextArea, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownTimerTextAnchorIcon, 210);
		dropdownTimerTextAnchorIcon:SetPoint("LEFT", dropdownTimerTextAnchor, "RIGHT", 0, 0);
		local info = {};
		dropdownTimerTextAnchorIcon.initialize = function()
			wipe(info);
			for _, anchorPoint in pairs(textAnchors) do
				info.text = textAnchorsLocalization[anchorPoint];
				info.value = anchorPoint;
				info.func = function(self)
					addonTable.db.TimerTextAnchorIcon = self.value;
					_G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = anchorPoint == addonTable.db.TimerTextAnchorIcon;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchorIcon]);
		dropdownTimerTextAnchorIcon.text = dropdownTimerTextAnchorIcon:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownTimerTextAnchorIcon.text:SetPoint("LEFT", 20, 20);
		dropdownTimerTextAnchorIcon.text:SetText(L["Anchor to icon"]);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchorIcon]); end);
	end

	-- // timerTextColorArea
	do
		timerTextColorArea = CreateFrame("Frame", nil, auraTextArea, BackdropTemplateMixin and "BackdropTemplate");
		timerTextColorArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		timerTextColorArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		timerTextColorArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		timerTextColorArea:SetPoint("TOP", auraTextArea, "TOP", 0, -200);
		timerTextColorArea:SetWidth(400);
		timerTextColorArea:SetHeight(71);
	end

	-- // timerTextColorInfo
	do

		local timerTextColorInfo = timerTextColorArea:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		timerTextColorInfo:SetText(L["options:timer-text:text-color-note"]);
		timerTextColorInfo:SetPoint("TOP", 0, -10);

	end

	-- // colorPickerTimerTextFiveSeconds
	do
		local colorPickerTimerTextFiveSeconds = VGUI.CreateColorPicker();
		colorPickerTimerTextFiveSeconds:SetParent(timerTextColorArea);
		colorPickerTimerTextFiveSeconds:SetPoint("TOPLEFT", 10, -40);
		colorPickerTimerTextFiveSeconds:SetText(L["< 5sec"]);
		local t = addonTable.db.TimerTextSoonToExpireColor;
		colorPickerTimerTextFiveSeconds:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerTimerTextFiveSeconds.func = function(self, r, g, b, a)
			addonTable.db.TimerTextSoonToExpireColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		colorPickerTimerTextFiveSeconds:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.TimerTextSoonToExpireColor;
			colorPickerTimerTextFiveSeconds:SetColor(t[1], t[2], t[3], t[4]);
		end);
	end

	-- // colorPickerTimerTextMinute
	do
		local colorPickerTimerTextMinute = VGUI.CreateColorPicker();
		colorPickerTimerTextMinute:SetParent(timerTextColorArea);
		colorPickerTimerTextMinute:SetPoint("TOPLEFT", 135, -40);
		colorPickerTimerTextMinute:SetText(L["< 1min"]);
		local t = addonTable.db.TimerTextUnderMinuteColor;
		colorPickerTimerTextMinute:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerTimerTextMinute.func = function(self, r, g, b, a)
			addonTable.db.TimerTextUnderMinuteColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		colorPickerTimerTextMinute:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.TimerTextUnderMinuteColor;
			colorPickerTimerTextMinute:SetColor(t[1], t[2], t[3], t[4]);
		end);
	end

	-- // colorPickerTimerTextMore
	do
		local colorPickerTimerTextMore = VGUI.CreateColorPicker();
		colorPickerTimerTextMore:SetParent(timerTextColorArea);
		colorPickerTimerTextMore:SetPoint("TOPLEFT", 260, -40);
		colorPickerTimerTextMore:SetText(L["> 1min"]);
		local t = addonTable.db.TimerTextLongerColor;
		colorPickerTimerTextMore:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerTimerTextMore.func = function(self, r, g, b, a)
			addonTable.db.TimerTextLongerColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		colorPickerTimerTextMore:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.TimerTextLongerColor;
			colorPickerTimerTextMore:SetColor(t[1], t[2], t[3], t[4]);
		end);
	end

	-- // tenthsOfSecondsArea
	do
		tenthsOfSecondsArea = CreateFrame("Frame", nil, auraTextArea, BackdropTemplateMixin and "BackdropTemplate");
		tenthsOfSecondsArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		tenthsOfSecondsArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		tenthsOfSecondsArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		tenthsOfSecondsArea:SetPoint("TOP", timerTextColorArea, "BOTTOM", 0, -10);
		tenthsOfSecondsArea:SetWidth(360);
		tenthsOfSecondsArea:SetHeight(71);
	end

	-- // sliderDisplayTenthsOfSeconds
	do
		local minValue, maxValue = 0, 10;
		local sliderDisplayTenthsOfSeconds = VGUI.CreateSlider();
		sliderDisplayTenthsOfSeconds:SetParent(tenthsOfSecondsArea);
		sliderDisplayTenthsOfSeconds:SetWidth(340);
		sliderDisplayTenthsOfSeconds:SetPoint("TOPLEFT", 10, -10);
		sliderDisplayTenthsOfSeconds.label:SetText(L["options:timer-text:min-duration-to-display-tenths-of-seconds"]);
		sliderDisplayTenthsOfSeconds.slider:SetValueStep(0.1);
		sliderDisplayTenthsOfSeconds.slider:SetMinMaxValues(minValue, maxValue);
		sliderDisplayTenthsOfSeconds.slider:SetValue(addonTable.db.MinTimeToShowTenthsOfSeconds);
		sliderDisplayTenthsOfSeconds.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.1f", value));
			sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(actualValue));
			addonTable.db.MinTimeToShowTenthsOfSeconds = actualValue;
		end);
		sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(addonTable.db.MinTimeToShowTenthsOfSeconds));
		sliderDisplayTenthsOfSeconds.editbox:SetScript("OnEnterPressed", function(self, value)
			if (self:GetText() ~= "") then
				local v = tonumber(self:GetText());
				if (v == nil) then
					self:SetText(tostring(addonTable.db.MinTimeToShowTenthsOfSeconds));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderDisplayTenthsOfSeconds.slider:SetValue(v);
				end
				self:ClearFocus();
			else
				self:SetText(tostring(addonTable.db.MinTimeToShowTenthsOfSeconds));
				msg(L["Value must be a number"]);
			end
		end);
		sliderDisplayTenthsOfSeconds.lowtext:SetText(tostring(minValue));
		sliderDisplayTenthsOfSeconds.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(addonTable.db.MinTimeToShowTenthsOfSeconds));
			sliderDisplayTenthsOfSeconds.slider:SetValue(addonTable.db.MinTimeToShowTenthsOfSeconds);
		end);
		sliderDisplayTenthsOfSeconds:Show();
	end

end

local function GUICategory_AuraStackFont(index, value)
	local dropdownMenuFont = VGUI.CreateDropdownMenu();
	local textAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
	local textAnchorsLocalization = {
		[textAnchors[1]] = L["anchor-point:topright"],
		[textAnchors[2]] = L["anchor-point:right"],
		[textAnchors[3]] = L["anchor-point:bottomright"],
		[textAnchors[4]] = L["anchor-point:top"],
		[textAnchors[5]] = L["anchor-point:center"],
		[textAnchors[6]] = L["anchor-point:bottom"],
		[textAnchors[7]] = L["anchor-point:topleft"],
		[textAnchors[8]] = L["anchor-point:left"],
		[textAnchors[9]] = L["anchor-point:bottomleft"]
	};
	local checkboxShowStacks, auraTextArea, sliderStacksFontScale, buttonFont, sliderStacksTextXOffset, dropdownStacksAnchor;

	-- // checkboxShowStacks
	do
		checkboxShowStacks = VGUI.CreateCheckBox();
		checkboxShowStacks:SetText(L["options:general:show-stacks"]);
		checkboxShowStacks:SetOnClickHandler(function(this)
			addonTable.db.ShowStacks = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
			if (addonTable.db.ShowStacks) then
				auraTextArea:Show();
			else
				auraTextArea:Hide();
			end
		end);
		checkboxShowStacks:SetChecked(addonTable.db.ShowStacks);
		checkboxShowStacks:SetParent(GUIFrame);
		checkboxShowStacks:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -20);
		table_insert(GUIFrame.Categories[index], checkboxShowStacks);
		table_insert(GUIFrame.OnDBChangedHandlers, function() 
			checkboxShowStacks:SetChecked(addonTable.db.ShowStacks);
			addonTable.UpdateAllNameplates(true);
		end);
		checkboxShowStacks:SetScript("OnShow", function(self)
			if (addonTable.db.ShowStacks) then
				auraTextArea:Show();
			else
				auraTextArea:Hide();
			end
		end);
		checkboxShowStacks:SetScript("OnHide", function(self)
			auraTextArea:Hide();
		end);
	end

	-- // auraTextArea;
	do
		auraTextArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		auraTextArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		auraTextArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		auraTextArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		auraTextArea:SetPoint("TOPLEFT", checkboxShowStacks, "BOTTOMLEFT", 0, 0);
		auraTextArea:SetPoint("BOTTOMRIGHT", GUIFrame.ControlsFrame, "BOTTOMRIGHT", 0, 0);
		auraTextArea:Hide();
	end

	-- // dropdownStacksFont, buttonFont
	do
		local fonts = { };
		buttonFont = VGUI.CreateButton();
		buttonFont:SetParent(auraTextArea);
		buttonFont:SetText(L["Font"] .. ": " .. addonTable.db.StacksFont);

		for idx, font in next, SML:List("font") do
			table_insert(fonts, {
				["text"] = font,
				["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
				["func"] = function(info)
					buttonFont.Text:SetText(L["Font"] .. ": " .. info.text);
					addonTable.db.StacksFont = info.text;
					addonTable.UpdateAllNameplates(true);
				end,
				["font"] = SML:Fetch("font", font),
			});
		end
		table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);

		buttonFont:SetWidth(170);
		buttonFont:SetHeight(24);
		buttonFont:SetPoint("TOPLEFT", auraTextArea, "TOPLEFT", 10, -10);
		buttonFont:SetPoint("TOPRIGHT", auraTextArea, "TOPRIGHT", -10, -10);
		buttonFont:SetScript("OnClick", function(self, ...)
			if (dropdownMenuFont:IsVisible()) then
				dropdownMenuFont:Hide();
			else
				dropdownMenuFont:SetList(fonts);
				dropdownMenuFont:SetParent(self);
				dropdownMenuFont:ClearAllPoints();
				dropdownMenuFont:SetPoint("TOP", self, "BOTTOM", 0, 0);
				dropdownMenuFont:Show();
			end
		end);
		buttonFont:Show();
	end

	-- // sliderStacksFontScale
	do
		local minValue, maxValue = 0.3, 3;
		sliderStacksFontScale = VGUI.CreateSlider();
		sliderStacksFontScale:SetParent(auraTextArea);
		sliderStacksFontScale:SetWidth(170);
		sliderStacksFontScale:SetPoint("TOPLEFT", buttonFont, "BOTTOMLEFT", 0, -20);
		sliderStacksFontScale.label:SetText(L["Font scale"]);
		sliderStacksFontScale.slider:SetValueStep(0.1);
		sliderStacksFontScale.slider:SetMinMaxValues(minValue, maxValue);
		sliderStacksFontScale.slider:SetValue(addonTable.db.StacksFontScale);
		sliderStacksFontScale.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.1f", value));
			sliderStacksFontScale.editbox:SetText(tostring(actualValue));
			addonTable.db.StacksFontScale = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderStacksFontScale.editbox:SetText(tostring(addonTable.db.StacksFontScale));
		sliderStacksFontScale.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderStacksFontScale.editbox:GetText() ~= "") then
				local v = tonumber(sliderStacksFontScale.editbox:GetText());
				if (v == nil) then
					sliderStacksFontScale.editbox:SetText(tostring(addonTable.db.StacksFontScale));
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
		sliderStacksFontScale:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksFontScale.editbox:SetText(tostring(addonTable.db.StacksFontScale)); sliderStacksFontScale.slider:SetValue(addonTable.db.StacksFontScale); end);

	end

	-- // sliderStacksTextXOffset
	do

		local minValue, maxValue = -100, 100;
		sliderStacksTextXOffset = VGUI.CreateSlider();
		sliderStacksTextXOffset:SetParent(auraTextArea);
		sliderStacksTextXOffset:SetWidth(170);
		sliderStacksTextXOffset:SetPoint("LEFT", sliderStacksFontScale, "RIGHT", 0, 0);
		sliderStacksTextXOffset.label:SetText(L["X offset"]);
		sliderStacksTextXOffset.slider:SetValueStep(1);
		sliderStacksTextXOffset.slider:SetMinMaxValues(minValue, maxValue);
		sliderStacksTextXOffset.slider:SetValue(addonTable.db.StacksTextXOffset);
		sliderStacksTextXOffset.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderStacksTextXOffset.editbox:SetText(tostring(actualValue));
			addonTable.db.StacksTextXOffset = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderStacksTextXOffset.editbox:SetText(tostring(addonTable.db.StacksTextXOffset));
		sliderStacksTextXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderStacksTextXOffset.editbox:GetText() ~= "") then
				local v = tonumber(sliderStacksTextXOffset.editbox:GetText());
				if (v == nil) then
					sliderStacksTextXOffset.editbox:SetText(tostring(addonTable.db.StacksTextXOffset));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderStacksTextXOffset.slider:SetValue(v);
				end
				sliderStacksTextXOffset.editbox:ClearFocus();
			end
		end);
		sliderStacksTextXOffset.lowtext:SetText(tostring(minValue));
		sliderStacksTextXOffset.hightext:SetText(tostring(maxValue));
		sliderStacksTextXOffset:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksTextXOffset.editbox:SetText(tostring(addonTable.db.StacksTextXOffset)); sliderStacksTextXOffset.slider:SetValue(addonTable.db.StacksTextXOffset); end);

	end

	-- // sliderStacksTextYOffset
	do

		local minValue, maxValue = -100, 100;
		local sliderStacksTextYOffset = VGUI.CreateSlider();
		sliderStacksTextYOffset:SetParent(auraTextArea);
		sliderStacksTextYOffset:SetWidth(165);
		sliderStacksTextYOffset:SetPoint("LEFT", sliderStacksTextXOffset, "RIGHT", 0, 0);
		sliderStacksTextYOffset.label:SetText(L["Y offset"]);
		sliderStacksTextYOffset.slider:SetValueStep(1);
		sliderStacksTextYOffset.slider:SetMinMaxValues(minValue, maxValue);
		sliderStacksTextYOffset.slider:SetValue(addonTable.db.StacksTextYOffset);
		sliderStacksTextYOffset.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderStacksTextYOffset.editbox:SetText(tostring(actualValue));
			addonTable.db.StacksTextYOffset = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderStacksTextYOffset.editbox:SetText(tostring(addonTable.db.StacksTextYOffset));
		sliderStacksTextYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderStacksTextYOffset.editbox:GetText() ~= "") then
				local v = tonumber(sliderStacksTextYOffset.editbox:GetText());
				if (v == nil) then
					sliderStacksTextYOffset.editbox:SetText(tostring(addonTable.db.StacksTextYOffset));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderStacksTextYOffset.slider:SetValue(v);
				end
				sliderStacksTextYOffset.editbox:ClearFocus();
			end
		end);
		sliderStacksTextYOffset.lowtext:SetText(tostring(minValue));
		sliderStacksTextYOffset.hightext:SetText(tostring(maxValue));
		sliderStacksTextYOffset:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksTextYOffset.editbox:SetText(tostring(addonTable.db.StacksTextYOffset)); sliderStacksTextYOffset.slider:SetValue(addonTable.db.StacksTextYOffset); end);

	end

	-- // dropdownStacksAnchor
	do
		dropdownStacksAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchor", auraTextArea, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownStacksAnchor, 210);
		dropdownStacksAnchor:SetPoint("TOPLEFT", sliderStacksFontScale, "BOTTOMLEFT", 0, 20);
		local info = {};
		dropdownStacksAnchor.initialize = function()
			wipe(info);
			for _, anchorPoint in pairs(textAnchors) do
				info.text = textAnchorsLocalization[anchorPoint];
				info.value = anchorPoint;
				info.func = function(self)
					addonTable.db.StacksTextAnchor = self.value;
					_G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = anchorPoint == addonTable.db.StacksTextAnchor;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.StacksTextAnchor]);
		dropdownStacksAnchor.text = dropdownStacksAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownStacksAnchor.text:SetPoint("LEFT", 20, 20);
		dropdownStacksAnchor.text:SetText(L["Anchor point"]);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.StacksTextAnchor]); end);
	end

	-- // dropdownStacksAnchorIcon
	do

		local dropdownStacksAnchorIcon = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchorIcon", auraTextArea, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownStacksAnchorIcon, 210);
		dropdownStacksAnchorIcon:SetPoint("LEFT", dropdownStacksAnchor, "RIGHT", 0, 0);
		local info = {};
		dropdownStacksAnchorIcon.initialize = function()
			wipe(info);
			for _, anchorPoint in pairs(textAnchors) do
				info.text = textAnchorsLocalization[anchorPoint];
				info.value = anchorPoint;
				info.func = function(self)
					addonTable.db.StacksTextAnchorIcon = self.value;
					_G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = anchorPoint == addonTable.db.StacksTextAnchorIcon;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.StacksTextAnchorIcon]);
		dropdownStacksAnchorIcon.text = dropdownStacksAnchorIcon:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownStacksAnchorIcon.text:SetPoint("LEFT", 20, 20);
		dropdownStacksAnchorIcon.text:SetText(L["Anchor to icon"]);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.StacksTextAnchorIcon]); end);

	end

	-- // colorPickerStacksTextColor
	do
		local colorPickerStacksTextColor = VGUI.CreateColorPicker();
		colorPickerStacksTextColor:SetParent(auraTextArea);
		colorPickerStacksTextColor:SetPoint("TOPLEFT", dropdownStacksAnchor, "BOTTOMLEFT", 20, -20);
		colorPickerStacksTextColor:SetText(L["Text color"]);
		local t = addonTable.db.StacksTextColor;
		colorPickerStacksTextColor:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerStacksTextColor.func = function(self, r, g, b, a)
			addonTable.db.StacksTextColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.StacksTextColor;
			colorPickerStacksTextColor:SetColor(t[1], t[2], t[3], t[4]);
		end);
		colorPickerStacksTextColor:Show();
	end

end

local function GUICategory_Borders(index, value)

	local debuffArea, dropdownBorderType, editBoxBorderFilePath, sliderBorderThickness;
	local SetControls;

	-- // dropdownBorderType
	do
		local borderTypes = { 
			[addonTable.BORDER_TYPE_BUILTIN] = L["options:borders:BORDER_TYPE_BUILTIN"],
			[addonTable.BORDER_TYPE_CUSTOM] = L["options:borders:BORDER_TYPE_CUSTOM"],
		};
		dropdownBorderType = CreateFrame("Frame", "NAuras.GUI.Border.dropdownBorderType", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownBorderType, 150);
		dropdownBorderType:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -20);
		local info = {};
		dropdownBorderType.initialize = function()
			wipe(info);
			for borderType, borderTypeL in pairs(borderTypes) do
				info.text = borderTypeL;
				info.value = borderType;
				info.func = function(self)
					addonTable.db.BorderType = self.value;
					_G[dropdownBorderType:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
					SetControls();
				end
				info.checked = borderType == addonTable.db.BorderType;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownBorderType:GetName() .. "Text"]:SetText(borderTypes[addonTable.db.BorderType]);
		dropdownBorderType.text = dropdownBorderType:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownBorderType.text:SetPoint("LEFT", 20, 20);
		dropdownBorderType.text:SetText(L["options:borders:border-type"]);

		function SetControls()
			if (addonTable.db.BorderType == addonTable.BORDER_TYPE_BUILTIN) then
				editBoxBorderFilePath:Hide();
				sliderBorderThickness:Show();
			elseif (addonTable.db.BorderType == addonTable.BORDER_TYPE_CUSTOM) then
				editBoxBorderFilePath:Show();
				sliderBorderThickness:Hide();
			end
		end

		table_insert(GUIFrame.Categories[index], dropdownBorderType);
		table_insert(GUIFrame.OnDBChangedHandlers, function() 
			_G[dropdownBorderType:GetName() .. "Text"]:SetText(borderTypes[addonTable.db.BorderType]);
			addonTable.UpdateAllNameplates(true);
			SetControls();
		end);
		
	end

	-- // editBoxBorderFilePath
	do
		editBoxBorderFilePath = CreateFrame("EditBox", nil, dropdownBorderType, "InputBoxTemplate");
		editBoxBorderFilePath:SetAutoFocus(false);
		editBoxBorderFilePath:SetFontObject(GameFontHighlightSmall);
		editBoxBorderFilePath:SetPoint("LEFT", dropdownBorderType, "RIGHT", 0, 0);
		editBoxBorderFilePath:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -10, 0);
		editBoxBorderFilePath:SetHeight(20);
		editBoxBorderFilePath:SetJustifyH("LEFT");
		editBoxBorderFilePath:EnableMouse(true);
		editBoxBorderFilePath:SetScript("OnEscapePressed", function() editBoxBorderFilePath:ClearFocus(); end);
		editBoxBorderFilePath:SetScript("OnEnterPressed", function() editBoxBorderFilePath:ClearFocus(); end);
		editBoxBorderFilePath:SetScript("OnTextChanged", function(self)
			local inputText = self:GetText();
			addonTable.db.BorderFilePath = inputText;
			addonTable.UpdateAllNameplates(true);
		end);
		local text = editBoxBorderFilePath:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		text:SetPoint("LEFT", 0, 15);
		text:SetText(L["options:borders:border-file-path"]);
		editBoxBorderFilePath:SetText(addonTable.db.BorderFilePath or "");
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			editBoxBorderFilePath:SetText(addonTable.db.BorderFilePath or "");
		end);
	end

	-- // sliderBorderThickness
	do

		local minValue, maxValue = 1, 5;
		sliderBorderThickness = VGUI.CreateSlider();
		sliderBorderThickness:SetParent(dropdownBorderType);
		sliderBorderThickness:SetWidth(325);
		sliderBorderThickness:SetPoint("LEFT", dropdownBorderType, "RIGHT", 0, -25);
		sliderBorderThickness:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -10, 0);
		sliderBorderThickness.label:SetText(L["Border thickness"]);
		sliderBorderThickness.slider:SetValueStep(1);
		sliderBorderThickness.slider:SetMinMaxValues(minValue, maxValue);
		sliderBorderThickness.slider:SetValue(addonTable.db.BorderThickness);
		sliderBorderThickness.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderBorderThickness.editbox:SetText(tostring(actualValue));
			addonTable.db.BorderThickness = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderBorderThickness.editbox:SetText(tostring(addonTable.db.BorderThickness));
		sliderBorderThickness.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderBorderThickness.editbox:GetText() ~= "") then
				local v = tonumber(sliderBorderThickness.editbox:GetText());
				if (v == nil) then
					sliderBorderThickness.editbox:SetText(tostring(addonTable.db.BorderThickness));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderBorderThickness.slider:SetValue(v);
				end
				sliderBorderThickness.editbox:ClearFocus();
			end
		end);
		sliderBorderThickness.lowtext:SetText(tostring(minValue));
		sliderBorderThickness.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderBorderThickness.editbox:SetText(tostring(addonTable.db.BorderThickness));
			sliderBorderThickness.slider:SetValue(addonTable.db.BorderThickness);
			addonTable.UpdateAllNameplates(true);
		end);

	end

	-- // debuffArea
	do

		debuffArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
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
		debuffArea:SetPoint("TOPLEFT", dropdownBorderType, "BOTTOMLEFT", 0, -10);
		debuffArea:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -10, 0);
		debuffArea:SetHeight(110);
		table_insert(GUIFrame.Categories[index], debuffArea);

	end

	-- // checkBoxDebuffBorder
	do

		local checkBoxDebuffBorder = VGUI.CreateCheckBox();
		checkBoxDebuffBorder:SetText(L["Show border around debuff icons"]);
		checkBoxDebuffBorder:SetOnClickHandler(function(this)
			addonTable.db.ShowDebuffBorders = this:GetChecked();
			addonTable.UpdateAllNameplates();
		end);
		checkBoxDebuffBorder:SetParent(debuffArea);
		checkBoxDebuffBorder:SetPoint("TOPLEFT", 15, -15);
		checkBoxDebuffBorder:SetChecked(addonTable.db.ShowDebuffBorders);
		table_insert(GUIFrame.Categories[index], checkBoxDebuffBorder);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxDebuffBorder:SetChecked(addonTable.db.ShowDebuffBorders); end);

	end

	-- // colorPickerDebuffMagic
	do
		local colorPickerDebuffMagic = VGUI.CreateColorPicker();
		colorPickerDebuffMagic:SetParent(debuffArea);
		colorPickerDebuffMagic:SetPoint("TOPLEFT", 15, -45);
		colorPickerDebuffMagic:SetText(L["Magic"]);
		local t = addonTable.db.DebuffBordersMagicColor;
		colorPickerDebuffMagic:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerDebuffMagic.func = function(self, r, g, b, a)
			addonTable.db.DebuffBordersMagicColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.Categories[index], colorPickerDebuffMagic);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.DebuffBordersMagicColor;
			colorPickerDebuffMagic:SetColor(t[1], t[2], t[3], t[4]);
		end);
	end

	-- // colorPickerDebuffCurse
	do

		local colorPickerDebuffCurse = VGUI.CreateColorPicker();
		colorPickerDebuffCurse:SetParent(debuffArea);
		colorPickerDebuffCurse:SetPoint("TOPLEFT", 135, -45);
		colorPickerDebuffCurse:SetText(L["Curse"]);
		local t = addonTable.db.DebuffBordersCurseColor;
		colorPickerDebuffCurse:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerDebuffCurse.func = function(self, r, g, b, a)
			addonTable.db.DebuffBordersCurseColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.Categories[index], colorPickerDebuffCurse);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.DebuffBordersCurseColor;
			colorPickerDebuffCurse:SetColor(t[1], t[2], t[3], t[4]);
		end);

	end

	-- // colorPickerDebuffDisease
	do

		local colorPickerDebuffDisease = VGUI.CreateColorPicker();
		colorPickerDebuffDisease:SetParent(debuffArea);
		colorPickerDebuffDisease:SetPoint("TOPLEFT", 255, -45);
		colorPickerDebuffDisease:SetText(L["Disease"]);
		local t = addonTable.db.DebuffBordersDiseaseColor;
		colorPickerDebuffDisease:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerDebuffDisease.func = function(self, r, g, b, a)
			addonTable.db.DebuffBordersDiseaseColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.Categories[index], colorPickerDebuffDisease);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.DebuffBordersDiseaseColor;
			colorPickerDebuffDisease:SetColor(t[1], t[2], t[3], t[4]);
		end);

	end

	-- // colorPickerDebuffPoison
	do

		local colorPickerDebuffPoison = VGUI.CreateColorPicker();
		colorPickerDebuffPoison:SetParent(debuffArea);
		colorPickerDebuffPoison:SetPoint("TOPLEFT", 375, -45);
		colorPickerDebuffPoison:SetText(L["Poison"]);
		local t = addonTable.db.DebuffBordersPoisonColor;
		colorPickerDebuffPoison:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerDebuffPoison.func = function(self, r, g, b, a)
			addonTable.db.DebuffBordersPoisonColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.Categories[index], colorPickerDebuffPoison);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.DebuffBordersPoisonColor;
			colorPickerDebuffPoison:SetColor(t[1], t[2], t[3], t[4]);
		end);

	end

	-- // colorPickerDebuffOther
	do
		local colorPickerDebuffOther = VGUI.CreateColorPicker();
		colorPickerDebuffOther:SetParent(debuffArea);
		colorPickerDebuffOther:SetPoint("TOPLEFT", 15, -70);
		colorPickerDebuffOther:SetText(L["Other"]);
		local t = addonTable.db.DebuffBordersOtherColor;
		colorPickerDebuffOther:SetColor(t[1], t[2], t[3], t[4]);
		colorPickerDebuffOther.func = function(self, r, g, b, a)
			addonTable.db.DebuffBordersOtherColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.Categories[index], colorPickerDebuffOther);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			local t = addonTable.db.DebuffBordersOtherColor;
			colorPickerDebuffOther:SetColor(t[1], t[2], t[3], t[4]);
		end);
	end

	-- // checkBoxBuffBorder
	do

		local checkBoxBuffBorder = VGUI.CreateCheckBoxWithColorPicker();
		checkBoxBuffBorder:SetText(L["Show border around buff icons"]);
		checkBoxBuffBorder:SetOnClickHandler(function(this)
			addonTable.db.ShowBuffBorders = this:GetChecked();
			addonTable.UpdateAllNameplates();
		end);
		checkBoxBuffBorder:SetChecked(addonTable.db.ShowBuffBorders);
		checkBoxBuffBorder:SetParent(GUIFrame);
		checkBoxBuffBorder:SetPoint("TOPLEFT", debuffArea, "BOTTOMLEFT", 0, -10);
		local t = addonTable.db.BuffBordersColor;
		checkBoxBuffBorder.ColorButton:SetColor(t[1], t[2], t[3], t[4]);
		checkBoxBuffBorder.ColorButton.func = function(self, r, g, b, a)
			addonTable.db.BuffBordersColor = {r, g, b, a};
			addonTable.UpdateAllNameplates(true);
		end
		table_insert(GUIFrame.Categories[index], checkBoxBuffBorder);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxBuffBorder:SetChecked(addonTable.db.ShowBuffBorders);
			local t = addonTable.db.BuffBordersColor;
			checkBoxBuffBorder.ColorButton:SetColor(t[1], t[2], t[3], t[4]);
		end);

	end

	SetControls();
end

local function GUICategory_4(index, value)
	local controls = { };
	local selectedSpell = 0;
	local dropdownMenuSpells = VGUI.CreateDropdownMenu();
	local spellArea, editboxAddSpell, buttonAddSpell, dropdownSelectSpell, sliderSpellIconSizeWidth, dropdownSpellShowType, editboxSpellID, buttonDeleteSpell, checkboxShowOnFriends, checkboxAnimationRelative,
		checkboxShowOnEnemies, selectSpell, checkboxPvPMode, checkboxEnabled, checkboxGlow, areaGlow, sliderGlowThreshold, areaIconSize, areaAuraType, areaIDs, checkboxGlowRelative,
		areaMaxAuraDurationFilter, sliderMaxAuraDurationFilter, dropdownGlowType, areaAnimation, checkboxAnimation, dropdownAnimationType, sliderAnimationThreshold, sliderSpellIconSizeHeight;
	local AuraTypesLocalization = {
		[AURA_TYPE_BUFF] =		L["Buff"],
		[AURA_TYPE_DEBUFF] =	L["Debuff"],
		[AURA_TYPE_ANY] =		L["Any"],
	};

	local glowTypes = {
		[addonTable.GLOW_TYPE_ACTIONBUTTON] = L["options:glow-type:GLOW_TYPE_ACTIONBUTTON"],
		[addonTable.GLOW_TYPE_AUTOUSE] = L["options:glow-type:GLOW_TYPE_AUTOUSE"],
		[addonTable.GLOW_TYPE_PIXEL] = L["options:glow-type:GLOW_TYPE_PIXEL"],
		[addonTable.GLOW_TYPE_ACTIONBUTTON_DIM] = L["options:glow-type:GLOW_TYPE_ACTIONBUTTON_DIM"],
	};

	local animationTypes = {
		[addonTable.ICON_ANIMATION_TYPE_ALPHA] = L["options:animation-type:ICON_ANIMATION_TYPE_ALPHA"],
	};

	local function GetButtonNameForSpell(spellInfo)
		local text = spellInfo.spellName;
		if (spellInfo.checkSpellID ~= nil and table_count(spellInfo.checkSpellID) > 0) then
			local t = { };
			for spellID in pairs(spellInfo.checkSpellID) do
				table_insert(t, spellID);
			end
			text = text .. " (" .. table.concat(t, ",") .. ")";
		end
		return text;
	end

	local function GetIDAndTextureForSpell(spellInfo)
		local spellID, textureID;
		if (spellInfo.checkSpellID ~= nil and table_count(spellInfo.checkSpellID) > 0) then
			spellID = next(spellInfo.checkSpellID);
			textureID = SpellTextureByID[spellID];
		else
			spellID = next(AllSpellIDsAndIconsByName[spellInfo.spellName]);
			textureID = SpellTextureByID[spellID];
		end
		return spellID, textureID;
	end

	function addonTable.GetCurrentlyEditingSpell()
		if (spellArea:IsVisible()) then
			if (selectedSpell ~= nil and selectedSpell > 0) then
				local spellID;
				local spell = addonTable.db.CustomSpells2[selectedSpell];
				if (spell.checkSpellID ~= nil and #spell.checkSpellID > 0) then
					spellID = next(spell.checkSpellID);
				else
					spellID = next(AllSpellIDsAndIconsByName[spell.spellName]);
				end
				return spell, spellID;
			else
				return nil;
			end
		else
			return nil;
		end
	end

	-- // enable & disable all spells buttons
	do

		local enableAllSpellsButton = VGUI.CreateButton();
		enableAllSpellsButton.clickedOnce = false;
		enableAllSpellsButton:SetParent(dropdownMenuSpells);
		enableAllSpellsButton:SetPoint("TOPLEFT", dropdownMenuSpells, "BOTTOMLEFT", 0, -10);
		enableAllSpellsButton:SetHeight(18);
		enableAllSpellsButton:SetWidth(dropdownMenuSpells:GetWidth() / 2 - 10);
		enableAllSpellsButton:SetText(L["options:spells:enable-all-spells"]);
		enableAllSpellsButton:SetScript("OnClick", function(self)
			if (self.clickedOnce) then
				for index in pairs(addonTable.db.CustomSpells2) do
					addonTable.db.CustomSpells2[index].enabledState = CONST_SPELL_MODE_ALL;
				end
				addonTable.UpdateAllNameplates(false);
				selectSpell:Click();
				self.clickedOnce = false;
				self:SetText(L["options:spells:enable-all-spells"]);
			else
				self.clickedOnce = true;
				self:SetText(L["options:spells:please-push-once-more"]);
				CTimerAfter(3, function()
					self.clickedOnce = false;
					self:SetText(L["options:spells:enable-all-spells"]);
				end);
			end
		end);
		enableAllSpellsButton:SetScript("OnHide", function(self)
			self.clickedOnce = false;
			self:SetText(L["options:spells:enable-all-spells"]);
		end);

		local disableAllSpellsButton = VGUI.CreateButton();
		disableAllSpellsButton.clickedOnce = false;
		disableAllSpellsButton:SetParent(dropdownMenuSpells);
		disableAllSpellsButton:SetPoint("LEFT", enableAllSpellsButton, "RIGHT", 10, 0);
		disableAllSpellsButton:SetPoint("TOPRIGHT", dropdownMenuSpells, "BOTTOMRIGHT", 0, -10);
		disableAllSpellsButton:SetHeight(18);
		disableAllSpellsButton:SetText(L["options:spells:disable-all-spells"]);
		disableAllSpellsButton:SetScript("OnClick", function(self)
			if (self.clickedOnce) then
				for index in pairs(addonTable.db.CustomSpells2) do
					addonTable.db.CustomSpells2[index].enabledState = CONST_SPELL_MODE_DISABLED;
				end
				addonTable.UpdateAllNameplates(false);
				selectSpell:Click();
				self.clickedOnce = false;
				self:SetText(L["options:spells:disable-all-spells"]);
			else
				self.clickedOnce = true;
				self:SetText(L["options:spells:please-push-once-more"]);
				CTimerAfter(3, function()
					self.clickedOnce = false;
					self:SetText(L["options:spells:disable-all-spells"]);
				end);
			end
		end);
		disableAllSpellsButton:SetScript("OnHide", function(self)
			self.clickedOnce = false;
			self:SetText(L["options:spells:disable-all-spells"]);
		end);

	end

	-- // delete all spells button
	do

		local function DeleteAllSpellsFromDB()
			if (not StaticPopupDialogs["NAURAS_MSG_DELETE_ALL_SPELLS"]) then
				StaticPopupDialogs["NAURAS_MSG_DELETE_ALL_SPELLS"] = {
					text = L["Do you really want to delete ALL spells?"],
					button1 = YES,
					button2 = NO,
					OnAccept = function()
						wipe(addonTable.db.CustomSpells2);
						selectSpell:Click();
						addonTable.UpdateAllNameplates(true);
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				};
			end
			StaticPopup_Show("NAURAS_MSG_DELETE_ALL_SPELLS");
		end

		local deleteAllSpellsButton = VGUI.CreateButton();
		deleteAllSpellsButton.clickedOnce = false;
		deleteAllSpellsButton:SetParent(dropdownMenuSpells);
		deleteAllSpellsButton:SetPoint("TOPLEFT", dropdownMenuSpells, "BOTTOMLEFT", 0, -29);
		deleteAllSpellsButton:SetPoint("TOPRIGHT", dropdownMenuSpells, "BOTTOMRIGHT", 0, -29);
		deleteAllSpellsButton:SetHeight(18);
		deleteAllSpellsButton:SetText(L["Delete all spells"]);
		deleteAllSpellsButton:SetScript("OnClick", function(self)
			if (self.clickedOnce) then
				DeleteAllSpellsFromDB();
				self.clickedOnce = false;
				self:SetText(L["Delete all spells"]);
			else
				self.clickedOnce = true;
				self:SetText(L["options:spells:please-push-once-more"]);
				CTimerAfter(3, function()
					self.clickedOnce = false;
					self:SetText(L["Delete all spells"]);
				end);
			end
		end);
		deleteAllSpellsButton:SetScript("OnHide", function(self)
			self.clickedOnce = false;
			self:SetText(L["Delete all spells"]);
		end);

	end

	-- // spellArea
	do

		spellArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		spellArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		spellArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		spellArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		spellArea:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -70);
		spellArea:SetPoint("BOTTOMRIGHT", GUIFrame.ControlsFrame, "BOTTOMRIGHT", -10, 0);

		spellArea.scrollArea = CreateFrame("ScrollFrame", nil, spellArea, "UIPanelScrollFrameTemplate");
		spellArea.scrollArea:SetPoint("TOPLEFT", spellArea, "TOPLEFT", 0, -3);
		spellArea.scrollArea:SetPoint("BOTTOMRIGHT", spellArea, "BOTTOMRIGHT", -8, 3);
		spellArea.scrollArea:Show();

		spellArea.controlsFrame = CreateFrame("Frame", nil, spellArea.scrollArea);
		spellArea.scrollArea:SetScrollChild(spellArea.controlsFrame);
		spellArea.controlsFrame:SetWidth(360);
		spellArea.controlsFrame:SetHeight(spellArea:GetHeight() + 150);

		spellArea.scrollBG = CreateFrame("Frame", nil, spellArea, BackdropTemplateMixin and "BackdropTemplate")
		spellArea.scrollBG:SetBackdrop({
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
			insets = { left = 4, right = 3, top = 4, bottom = 3 }
		});
		spellArea.scrollBG:SetBackdropColor(0, 0, 0)
		spellArea.scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)
		spellArea.scrollBG:SetWidth(20);
		spellArea.scrollBG:SetHeight(spellArea.scrollArea:GetHeight());
		spellArea.scrollBG:SetPoint("TOPRIGHT", spellArea.scrollArea, "TOPRIGHT", 23, 0)


		table_insert(controls, spellArea);

	end

	-- // editboxAddSpell, buttonAddSpell
	do

		editboxAddSpell = CreateFrame("EditBox", nil, GUIFrame, "InputBoxTemplate");
		editboxAddSpell:SetAutoFocus(false);
		editboxAddSpell:SetFontObject(GameFontHighlightSmall);
		editboxAddSpell:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, 10, -10);
		editboxAddSpell:SetHeight(20);
		editboxAddSpell:SetWidth(380);
		editboxAddSpell:SetJustifyH("LEFT");
		editboxAddSpell:EnableMouse(true);
		editboxAddSpell:SetScript("OnEscapePressed", function() editboxAddSpell:ClearFocus(); end);
		editboxAddSpell:SetScript("OnEnterPressed", function() buttonAddSpell:Click(); end);
		local text = editboxAddSpell:CreateFontString(nil, "ARTWORK", "GameFontDisable");
		text:SetPoint("LEFT", 0, 0);
		text:SetText(L["options:spells:add-new-spell"]);
		editboxAddSpell:SetScript("OnEditFocusGained", function() text:Hide(); end);
		editboxAddSpell:SetScript("OnEditFocusLost", function() text:Show(); end);
		hooksecurefunc("ChatEdit_InsertLink", function(link)
			if (editboxAddSpell:IsVisible() and editboxAddSpell:HasFocus() and link ~= nil) then
				local spellName = string.match(link, "%[\"?(.-)\"?%]");
				if (spellName ~= nil) then
					editboxAddSpell:SetText(spellName);
					editboxAddSpell:ClearFocus();
					return true;
				end
			end
		end);
		table_insert(GUIFrame.Categories[index], editboxAddSpell);

		buttonAddSpell = VGUI.CreateButton();
		buttonAddSpell:SetParent(GUIFrame);
		buttonAddSpell:SetText(L["Add spell"]);
		buttonAddSpell:SetHeight(20);
		buttonAddSpell:SetPoint("LEFT", editboxAddSpell, "RIGHT", 10, 0);
		buttonAddSpell:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -10, 0);
		buttonAddSpell:SetScript("OnClick", function(self, ...)
			local text = editboxAddSpell:GetText();
			local customSpellID = nil;
			if (tonumber(text) ~= nil) then
				customSpellID = tonumber(text);
				text = SpellNameByID[tonumber(text)] or "";
			end
			local spellID;
			-- if user entered name of spell
			if (customSpellID == nil) then
				if (AllSpellIDsAndIconsByName[text] == nil) then
					for _spellName, _spellInfo in pairs(AllSpellIDsAndIconsByName) do
						if (string_lower(_spellName) == string_lower(text)) then
							text = _spellName;
						end
					end
				end
			end
			if (text ~= nil and AllSpellIDsAndIconsByName[text] ~= nil) then
				local spellName = text;
				local newSpellInfo = GetDefaultDBSpellEntry(CONST_SPELL_MODE_ALL, spellName, (customSpellID ~= nil) and { [customSpellID] = true } or nil);
				table_insert(addonTable.db.CustomSpells2, newSpellInfo);
				selectSpell:Click();
				local btn = dropdownMenuSpells:GetButtonByText(GetButtonNameForSpell(newSpellInfo));
				if (btn ~= nil) then btn:Click(); end
				addonTable.UpdateAllNameplates(false);
				editboxAddSpell:SetText("");
				editboxAddSpell:ClearFocus();
			else
				msg(L["Spell seems to be nonexistent"]);
			end
		end);
		buttonAddSpell:Disable();
		hooksecurefunc(addonTable, "OnSpellInfoCachesReady", function() buttonAddSpell:Enable(); end);
		GUIFrame:HookScript("OnHide", function() buttonAddSpell:Disable(); end);
		table_insert(GUIFrame.Categories[index], buttonAddSpell);

	end

	-- // selectSpell
	do

		local function OnSpellSelected(buttonInfo)
			local spellInfo = buttonInfo.info;
			for _, control in pairs(controls) do
				control:Show();
			end
			selectedSpell = buttonInfo.indexInDB;
			selectSpell.Text:SetText(buttonInfo.text);
			selectSpell:SetScript("OnEnter", function(self, ...)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
				GameTooltip:SetSpellByID(GetIDAndTextureForSpell(spellInfo));
				GameTooltip:Show();
			end);
			selectSpell:SetScript("OnLeave", function(self, ...) GameTooltip:Hide(); end);
			selectSpell.icon:SetTexture(select(2, GetIDAndTextureForSpell(spellInfo)));
			selectSpell.icon:Show();
			sliderSpellIconSizeWidth.slider:SetValue(spellInfo.iconSizeWidth);
			sliderSpellIconSizeWidth.editbox:SetText(tostring(spellInfo.iconSizeWidth));
			sliderSpellIconSizeHeight.slider:SetValue(spellInfo.iconSizeHeight);
			sliderSpellIconSizeHeight.editbox:SetText(tostring(spellInfo.iconSizeHeight));
			_G[dropdownSpellShowType:GetName().."Text"]:SetText(AuraTypesLocalization[spellInfo.auraType]);
			if (spellInfo.checkSpellID) then
				local t = { };
				for key in pairs(spellInfo.checkSpellID) do
					table_insert(t, key);
				end
				editboxSpellID:SetText(table.concat(t, ","));
			else
				editboxSpellID:SetText("");
			end
			checkboxShowOnFriends:SetChecked(spellInfo.showOnFriends);
			checkboxShowOnEnemies:SetChecked(spellInfo.showOnEnemies);
			if (spellInfo.enabledState == CONST_SPELL_MODE_DISABLED) then
				checkboxEnabled:SetTriState(0);
			elseif (spellInfo.enabledState == CONST_SPELL_MODE_ALL) then
				checkboxEnabled:SetTriState(2);
			else
				checkboxEnabled:SetTriState(1);
			end
			if (spellInfo.pvpCombat == CONST_SPELL_PVP_MODES_UNDEFINED) then
				checkboxPvPMode:SetTriState(0);
			elseif (spellInfo.pvpCombat == CONST_SPELL_PVP_MODES_INPVPCOMBAT) then
				checkboxPvPMode:SetTriState(1);
			else
				checkboxPvPMode:SetTriState(2);
			end
			if (spellInfo.showGlow == nil) then
				checkboxGlow:SetTriState(0);
				sliderGlowThreshold:Hide();
				checkboxGlowRelative:Hide();
				dropdownGlowType:Hide();
				areaGlow:SetHeight(40);
			elseif (spellInfo.showGlow == GLOW_TIME_INFINITE) then
				checkboxGlow:SetTriState(2);
				sliderGlowThreshold:Hide();
				checkboxGlowRelative:Hide();
				areaGlow:SetHeight(80);
			else
				checkboxGlow:SetTriState(1);
				sliderGlowThreshold.slider:SetValue(spellInfo.showGlow);
				checkboxGlowRelative:SetChecked(spellInfo.useRelativeGlowTimer);
				areaGlow:SetHeight(80);
			end
			_G[dropdownGlowType:GetName().."Text"]:SetText(glowTypes[spellInfo.glowType]);
			if (spellInfo.animationDisplayMode == addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE) then
				checkboxAnimation:SetTriState(0);
				sliderAnimationThreshold:Hide();
				checkboxAnimationRelative:Hide();
				dropdownAnimationType:Hide();
				areaAnimation:SetHeight(40);
			elseif (spellInfo.animationDisplayMode == addonTable.ICON_ANIMATION_DISPLAY_MODE_ALWAYS) then
				checkboxAnimation:SetTriState(2);
				sliderAnimationThreshold:Hide();
				checkboxAnimationRelative:Hide();
				areaAnimation:SetHeight(80);
			elseif (spellInfo.animationDisplayMode == addonTable.ICON_ANIMATION_DISPLAY_MODE_THRESHOLD) then
				checkboxAnimation:SetTriState(1);
				sliderAnimationThreshold.slider:SetValue(spellInfo.animationTimer);
				checkboxAnimationRelative:SetChecked(spellInfo.useRelativeAnimationTimer);
				areaAnimation:SetHeight(80);
			end
			_G[dropdownAnimationType:GetName().."Text"]:SetText(animationTypes[spellInfo.animationType]);
		end

		local function HideGameTooltip()
			GameTooltip:Hide();
		end

		local function ResetSelectSpell()
			for _, control in pairs(controls) do
				control:Hide();
			end
			selectSpell.Text:SetText(L["Click to select spell"]);
			selectSpell:SetScript("OnEnter", nil);
			selectSpell:SetScript("OnLeave", nil);
			selectSpell.icon:Hide();
		end

		selectSpell = VGUI.CreateButton();
		selectSpell:SetParent(GUIFrame);
		selectSpell:SetText(L["Click to select spell"]);
		selectSpell:SetWidth(285);
		selectSpell:SetHeight(24);
		selectSpell.icon = selectSpell:CreateTexture(nil, "OVERLAY");
		selectSpell.icon:SetPoint("RIGHT", selectSpell.Text, "LEFT", -3, 0);
		selectSpell.icon:SetWidth(20);
		selectSpell.icon:SetHeight(20);
		selectSpell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		selectSpell.icon:Hide();
		selectSpell:SetPoint("BOTTOMLEFT", spellArea, "TOPLEFT", 15, 5);
		selectSpell:SetPoint("BOTTOMRIGHT", spellArea, "TOPRIGHT", -15, 5);
		selectSpell:SetScript("OnClick", function(button)
			local t = { };
			for index, spellInfo in pairs(addonTable.db.CustomSpells2) do
				table_insert(t, {
					icon = select(2, GetIDAndTextureForSpell(spellInfo)),
					text = GetButtonNameForSpell(spellInfo),
					info = spellInfo,
					indexInDB = index,
					onEnter = function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetSpellByID(GetIDAndTextureForSpell(spellInfo));
						local allSpellIDs = AllSpellIDsAndIconsByName[spellInfo.spellName];
						if (allSpellIDs ~= nil and table_count(allSpellIDs) > 0) then
							local descText = "\n" .. L["options:spells:appropriate-spell-ids"];
							for id, icon in pairs(allSpellIDs) do
								descText = string_format("%s\n|T%d:0|t: %d", descText, icon, id);
							end
							GameTooltip:AddLine(descText);
						end
						GameTooltip:Show();
					end,
					onLeave = HideGameTooltip,
					func = OnSpellSelected,
					checkBoxEnabled = true,
					checkBoxState = spellInfo.enabledState ~= CONST_SPELL_MODE_DISABLED,
					onCheckBoxClick = function(checkbox)
						if (checkbox:GetChecked()) then
							spellInfo.enabledState = CONST_SPELL_MODE_ALL;
						else
							spellInfo.enabledState = CONST_SPELL_MODE_DISABLED;
						end
						addonTable.UpdateAllNameplates(false);
					end,
					onCloseButtonClick = function(buttonInfo) OnSpellSelected(buttonInfo); buttonDeleteSpell:Click(); selectSpell:Click(); end,
				});
			end
			table_sort(t, function(item1, item2) return item1.text < item2.text end);
			dropdownMenuSpells:SetList(t);
			dropdownMenuSpells:SetWidth(400);
			dropdownMenuSpells:SetParent(button);
			dropdownMenuSpells:ClearAllPoints();
			dropdownMenuSpells:SetPoint("TOP", button, "BOTTOM", 0, 0);
			dropdownMenuSpells:Show();
			dropdownMenuSpells.searchBox:SetFocus();
			dropdownMenuSpells.searchBox:SetText("");
			ResetSelectSpell();
			HideGameTooltip();
		end);
		selectSpell:SetScript("OnHide", function(self)
			ResetSelectSpell();
			dropdownMenuSpells:Hide();
		end);
		selectSpell:Disable();
		hooksecurefunc(addonTable, "OnSpellInfoCachesReady", function() selectSpell:Enable(); end);
		GUIFrame:HookScript("OnHide", function() selectSpell:Disable(); end);
		table_insert(GUIFrame.Categories[index], selectSpell);

	end

	-- // checkboxEnabled
	do
		checkboxEnabled = VGUI.CreateCheckBoxTristate();
		checkboxEnabled:SetTextEntries({
			addonTable.ColorizeText(L["Disabled"], 1, 1, 1),
			addonTable.ColorizeText(L["options:auras:enabled-state-mineonly"], 0, 1, 1),
			addonTable.ColorizeText(L["options:auras:enabled-state-all"], 0, 1, 0),
		});
		checkboxEnabled:SetOnClickHandler(function(self)
			if (self:GetTriState() == 0) then
				addonTable.db.CustomSpells2[selectedSpell].enabledState = CONST_SPELL_MODE_DISABLED;
			elseif (self:GetTriState() == 1) then
				addonTable.db.CustomSpells2[selectedSpell].enabledState = CONST_SPELL_MODE_MYAURAS;
			else
				addonTable.db.CustomSpells2[selectedSpell].enabledState = CONST_SPELL_MODE_ALL;
			end
			addonTable.UpdateAllNameplates(false);
		end);
		checkboxEnabled:SetParent(spellArea.controlsFrame);
		checkboxEnabled:SetPoint("TOPLEFT", 15, -15);
		VGUI.SetTooltip(checkboxEnabled, format(L["options:auras:enabled-state:tooltip"],
			addonTable.ColorizeText(L["Disabled"], 1, 1, 1),
			addonTable.ColorizeText(L["options:auras:enabled-state-mineonly"], 0, 1, 1),
			addonTable.ColorizeText(L["options:auras:enabled-state-all"], 0, 1, 0)), "LEFT");
		table_insert(controls, checkboxEnabled);

	end

	-- // checkboxShowOnFriends
	do
		checkboxShowOnFriends = VGUI.CreateCheckBox();
		checkboxShowOnFriends:SetText(L["Show this aura on nameplates of allies"]);
		checkboxShowOnFriends:SetOnClickHandler(function(this)
			addonTable.db.CustomSpells2[selectedSpell].showOnFriends = this:GetChecked();
			if (this:GetChecked() and not addonTable.db.ShowAboveFriendlyUnits) then
				msg(L["options:spells:show-on-friends:warning0"]);
			end
			addonTable.UpdateAllNameplates(false);
		end);
		checkboxShowOnFriends:SetParent(spellArea.controlsFrame);
		checkboxShowOnFriends:SetPoint("TOPLEFT", 15, -35);
		table_insert(controls, checkboxShowOnFriends);
	end

	-- // checkboxShowOnEnemies
	do
		checkboxShowOnEnemies = VGUI.CreateCheckBox();
		checkboxShowOnEnemies:SetText(L["Show this aura on nameplates of enemies"]);
		checkboxShowOnEnemies:SetOnClickHandler(function(this)
			addonTable.db.CustomSpells2[selectedSpell].showOnEnemies = this:GetChecked();
			addonTable.UpdateAllNameplates(false);
		end);
		checkboxShowOnEnemies:SetParent(spellArea.controlsFrame);
		checkboxShowOnEnemies:SetPoint("TOPLEFT", 15, -55);
		table_insert(controls, checkboxShowOnEnemies);
	end

	-- // checkboxPvPMode
	do
		checkboxPvPMode = VGUI.CreateCheckBoxTristate();
		checkboxPvPMode:SetTextEntries({
			L["options:auras:pvp-state-indefinite"],
			addonTable.ColorizeText(L["options:auras:pvp-state-onlyduringpvpbattles"], 0, 1, 0),
			addonTable.ColorizeText(L["options:auras:pvp-state-dontshowinpvp"], 1, 0, 0),
		});
		checkboxPvPMode:SetOnClickHandler(function(self)
			if (self:GetTriState() == 0) then
				addonTable.db.CustomSpells2[selectedSpell].pvpCombat = CONST_SPELL_PVP_MODES_UNDEFINED;
			elseif (self:GetTriState() == 1) then
				addonTable.db.CustomSpells2[selectedSpell].pvpCombat = CONST_SPELL_PVP_MODES_INPVPCOMBAT;
			else
				addonTable.db.CustomSpells2[selectedSpell].pvpCombat = CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT;
			end
			addonTable.UpdateAllNameplates(false);
		end);
		checkboxPvPMode:SetParent(spellArea.controlsFrame);
		checkboxPvPMode:SetPoint("TOPLEFT", 15, -75);
		table_insert(controls, checkboxPvPMode);

	end

	-- // areaGlow
	do

		areaGlow = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
		areaGlow:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		areaGlow:SetBackdropColor(0.1, 0.1, 0.2, 1);
		areaGlow:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		areaGlow:SetPoint("TOPLEFT", spellArea.controlsFrame, "TOPLEFT", 10, -95);
		areaGlow:SetWidth(500);
		areaGlow:SetHeight(80);
		table_insert(controls, areaGlow);

	end

	-- // checkboxGlow
	do
		checkboxGlow = VGUI.CreateCheckBoxTristate();
		checkboxGlow:SetTextEntries({
			addonTable.ColorizeText(L["options:spells:icon-glow"], 1, 1, 1),
			addonTable.ColorizeText(L["options:spells:icon-glow-threshold"], 0, 1, 1),
			addonTable.ColorizeText(L["options:spells:icon-glow-always"], 0, 1, 0),
		});
		checkboxGlow:SetOnClickHandler(function(self)
			if (self:GetTriState() == 0) then
				addonTable.db.CustomSpells2[selectedSpell].showGlow = nil; -- // making addonTable.db smaller
				sliderGlowThreshold:Hide();
				checkboxGlowRelative:Hide();
				dropdownGlowType:Hide();
				areaGlow:SetHeight(40);
			elseif (self:GetTriState() == 1) then
				addonTable.db.CustomSpells2[selectedSpell].showGlow = 5;
				sliderGlowThreshold:Show();
				checkboxGlowRelative:Show();
				dropdownGlowType:Show();
				sliderGlowThreshold.slider:SetValue(5);
				areaGlow:SetHeight(80);
			else
				addonTable.db.CustomSpells2[selectedSpell].showGlow = GLOW_TIME_INFINITE;
				sliderGlowThreshold:Hide();
				checkboxGlowRelative:Hide();
				dropdownGlowType:Show();
				areaGlow:SetHeight(80);
			end
			addonTable.UpdateAllNameplates(false);
		end);
		checkboxGlow:SetParent(areaGlow);
		checkboxGlow:SetPoint("TOPLEFT", 10, -10);
		table_insert(controls, checkboxGlow);
	end

	-- // dropdownGlowType
	do
		dropdownGlowType = CreateFrame("Frame", "NAurasGUI.Spell.dropdownGlowType", areaGlow, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownGlowType, 145);
		dropdownGlowType:SetPoint("TOPLEFT", areaGlow, "TOPLEFT", -5, -40);
		local info = {};
		dropdownGlowType.initialize = function()
			wipe(info);
			for glowType, glowTypeLocalized in pairs(glowTypes) do
				info.text = glowTypeLocalized;
				info.value = glowType;
				info.func = function(self)
					addonTable.db.CustomSpells2[selectedSpell].glowType = self.value;
					_G[dropdownGlowType:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = glowType == addonTable.db.CustomSpells2[selectedSpell].glowType;
				UIDropDownMenu_AddButton(info);
			end
		end
		dropdownGlowType.text = dropdownGlowType:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownGlowType.text:SetPoint("LEFT", 20, 20);
		dropdownGlowType.text:SetText(L["options:glow-type"]);
		table_insert(controls, dropdownGlowType);

	end

	-- // sliderGlowThreshold
	do

		local minV, maxV = 1, 100;
		sliderGlowThreshold = VGUI.CreateSlider();
		sliderGlowThreshold:SetParent(areaGlow);
		sliderGlowThreshold:SetWidth(140);
		sliderGlowThreshold.label:ClearAllPoints();
		sliderGlowThreshold.label:SetPoint("CENTER", sliderGlowThreshold, "CENTER", 0, 15);
		sliderGlowThreshold.label:SetText();
		sliderGlowThreshold:ClearAllPoints();
		sliderGlowThreshold:SetPoint("LEFT", dropdownGlowType, "RIGHT", 0, 10);
		sliderGlowThreshold.slider:ClearAllPoints();
		sliderGlowThreshold.slider:SetPoint("LEFT", 3, 0)
		sliderGlowThreshold.slider:SetPoint("RIGHT", -3, 0)
		sliderGlowThreshold.slider:SetValueStep(1);
		sliderGlowThreshold.slider:SetMinMaxValues(minV, maxV);
		sliderGlowThreshold.slider:SetScript("OnValueChanged", function(self, value)
			sliderGlowThreshold.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.CustomSpells2[selectedSpell].showGlow = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderGlowThreshold.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderGlowThreshold.editbox:GetText() ~= "") then
				local v = tonumber(sliderGlowThreshold.editbox:GetText());
				if (v == nil) then
					sliderGlowThreshold.editbox:SetText(tostring(addonTable.db.CustomSpells2[selectedSpell].showGlow));
					Print(L["Value must be a number"]);
				else
					if (v > maxV) then
						v = maxV;
					end
					if (v < minV) then
						v = minV;
					end
					sliderGlowThreshold.slider:SetValue(v);
				end
				sliderGlowThreshold.editbox:ClearFocus();
			end
		end);
		sliderGlowThreshold.lowtext:SetText(tostring(minV));
		sliderGlowThreshold.hightext:SetText(tostring(maxV));
		table_insert(controls, sliderGlowThreshold);

	end

	-- // checkboxGlowRelative
	do
		checkboxGlowRelative = VGUI.CreateCheckBox();
		checkboxGlowRelative:SetText(L["options:spells:glow-relative"]);
		checkboxGlowRelative:SetOnClickHandler(function(this)
			addonTable.db.CustomSpells2[selectedSpell].useRelativeGlowTimer = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
		end);
		VGUI.SetTooltip(checkboxGlowRelative, L["options:spells:glow-relative:tooltip"]);
		checkboxGlowRelative:SetParent(areaGlow);
		checkboxGlowRelative:SetPoint("LEFT", sliderGlowThreshold, "RIGHT", 10, 0);
		table_insert(controls, checkboxGlowRelative);
	end

	-- // areaAnimation
	do
		areaAnimation = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
		areaAnimation:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		areaAnimation:SetBackdropColor(0.1, 0.1, 0.2, 1);
		areaAnimation:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		areaAnimation:SetPoint("TOPLEFT", areaGlow, "BOTTOMLEFT", 0, 0);
		areaAnimation:SetPoint("TOPRIGHT", areaGlow, "BOTTOMRIGHT", 0, 0);
		areaAnimation:SetHeight(80);
		table_insert(controls, areaAnimation);
	end

	-- // checkboxAnimation
	do
		checkboxAnimation = VGUI.CreateCheckBoxTristate();
		checkboxAnimation:SetTextEntries({
			addonTable.ColorizeText(L["options:spells:icon-animation"], 1, 1, 1),
			addonTable.ColorizeText(L["options:spells:icon-animation-threshold"], 0, 1, 1),
			addonTable.ColorizeText(L["options:spells:icon-animation-always"], 0, 1, 0),
		});
		checkboxAnimation:SetOnClickHandler(function(self)
			if (self:GetTriState() == 0) then
				addonTable.db.CustomSpells2[selectedSpell].animationDisplayMode = addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE;
				sliderAnimationThreshold:Hide();
				checkboxAnimationRelative:Hide();
				dropdownAnimationType:Hide();
				areaAnimation:SetHeight(40);
			elseif (self:GetTriState() == 1) then
				addonTable.db.CustomSpells2[selectedSpell].animationDisplayMode = addonTable.ICON_ANIMATION_DISPLAY_MODE_THRESHOLD;
				sliderAnimationThreshold:Show();
				checkboxAnimationRelative:Show();
				dropdownAnimationType:Show();
				sliderAnimationThreshold.slider:SetValue(5);
				areaAnimation:SetHeight(80);
			else
				addonTable.db.CustomSpells2[selectedSpell].animationDisplayMode = addonTable.ICON_ANIMATION_DISPLAY_MODE_ALWAYS;
				sliderAnimationThreshold:Hide();
				checkboxAnimationRelative:Hide();
				dropdownAnimationType:Show();
				areaAnimation:SetHeight(80);
			end
			addonTable.UpdateAllNameplates(true);
		end);
		checkboxAnimation:SetParent(areaAnimation);
		checkboxAnimation:SetPoint("TOPLEFT", 10, -10);
		table_insert(controls, checkboxAnimation);
	end

	-- // dropdownAnimationType
	do
		dropdownAnimationType = CreateFrame("Frame", "NAurasGUI.Spell.dropdownAnimationType", areaAnimation, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownAnimationType, 145);
		dropdownAnimationType:SetPoint("TOPLEFT", areaAnimation, "TOPLEFT", -5, -40);
		local info = {};
		dropdownAnimationType.initialize = function()
			wipe(info);
			for animationType, animationTypeLocalized in pairs(animationTypes) do
				info.text = animationTypeLocalized;
				info.value = animationType;
				info.func = function(self)
					addonTable.db.CustomSpells2[selectedSpell].animationType = self.value;
					_G[dropdownAnimationType:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = animationType == addonTable.db.CustomSpells2[selectedSpell].animationType;
				UIDropDownMenu_AddButton(info);
			end
		end
		dropdownAnimationType.text = dropdownAnimationType:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownAnimationType.text:SetPoint("LEFT", 20, 20);
		dropdownAnimationType.text:SetText(L["options:spells:animation-type"]);
		table_insert(controls, dropdownAnimationType);

	end

	-- // sliderAnimationThreshold
	do

		local minV, maxV = 1, 100;
		sliderAnimationThreshold = VGUI.CreateSlider();
		sliderAnimationThreshold:SetParent(areaAnimation);
		sliderAnimationThreshold:SetWidth(140);
		sliderAnimationThreshold.label:ClearAllPoints();
		sliderAnimationThreshold.label:SetPoint("CENTER", sliderAnimationThreshold, "CENTER", 0, 15);
		sliderAnimationThreshold.label:SetText();
		sliderAnimationThreshold:ClearAllPoints();
		sliderAnimationThreshold:SetPoint("LEFT", dropdownAnimationType, "RIGHT", 0, 10);
		sliderAnimationThreshold.slider:ClearAllPoints();
		sliderAnimationThreshold.slider:SetPoint("LEFT", 3, 0)
		sliderAnimationThreshold.slider:SetPoint("RIGHT", -3, 0)
		sliderAnimationThreshold.slider:SetValueStep(1);
		sliderAnimationThreshold.slider:SetMinMaxValues(minV, maxV);
		sliderAnimationThreshold.slider:SetScript("OnValueChanged", function(self, value)
			sliderAnimationThreshold.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.CustomSpells2[selectedSpell].animationTimer = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderAnimationThreshold.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderAnimationThreshold.editbox:GetText() ~= "") then
				local v = tonumber(sliderAnimationThreshold.editbox:GetText());
				if (v == nil) then
					sliderAnimationThreshold.editbox:SetText(tostring(addonTable.db.CustomSpells2[selectedSpell].animationTimer));
					Print(L["Value must be a number"]);
				else
					if (v > maxV) then
						v = maxV;
					end
					if (v < minV) then
						v = minV;
					end
					sliderAnimationThreshold.slider:SetValue(v);
				end
				sliderAnimationThreshold.editbox:ClearFocus();
			end
		end);
		sliderAnimationThreshold.lowtext:SetText(tostring(minV));
		sliderAnimationThreshold.hightext:SetText(tostring(maxV));
		table_insert(controls, sliderAnimationThreshold);

	end

	-- // checkboxAnimationRelative
	do
		checkboxAnimationRelative = VGUI.CreateCheckBox();
		checkboxAnimationRelative:SetText(L["options:spells:glow-relative"]);
		checkboxAnimationRelative:SetOnClickHandler(function(this)
			addonTable.db.CustomSpells2[selectedSpell].useRelativeAnimationTimer = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
		end);
		VGUI.SetTooltip(checkboxAnimationRelative, L["options:spells:animation-relative:tooltip"]);
		checkboxAnimationRelative:SetParent(areaAnimation);
		checkboxAnimationRelative:SetPoint("LEFT", sliderAnimationThreshold, "RIGHT", 10, 0);
		table_insert(controls, checkboxAnimationRelative);
	end

	-- // areaAuraType
	do

		areaAuraType = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
		areaAuraType:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		areaAuraType:SetBackdropColor(0.1, 0.1, 0.2, 1);
		areaAuraType:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		areaAuraType:SetPoint("TOPLEFT", areaAnimation, "BOTTOMLEFT", 0, 0);
		areaAuraType:SetWidth(167);
		areaAuraType:SetHeight(70);
		table_insert(controls, areaAuraType);

	end

	-- // dropdownSpellShowType
	do

		dropdownSpellShowType = CreateFrame("Frame", "NAuras.GUI.Cat4.DropdownSpellShowType", areaAuraType, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownSpellShowType, 130);

		dropdownSpellShowType.text = dropdownSpellShowType:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		dropdownSpellShowType.text:SetPoint("CENTER", areaAuraType, "CENTER", 0, 15);
		dropdownSpellShowType.text:SetText(L["Aura type"]);
		dropdownSpellShowType:SetPoint("CENTER", 0, -11);
		local info = {};
		dropdownSpellShowType.initialize = function()
			wipe(info);
			for _, auraType in pairs({ AURA_TYPE_BUFF, AURA_TYPE_DEBUFF, AURA_TYPE_ANY }) do
				info.text = AuraTypesLocalization[auraType];
				info.value = auraType;
				info.func = function(self)
					addonTable.db.CustomSpells2[selectedSpell].auraType = self.value;
					_G[dropdownSpellShowType:GetName().."Text"]:SetText(self:GetText());
				end
				info.checked = (info.value == addonTable.db.CustomSpells2[selectedSpell].auraType);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownSpellShowType:GetName().."Text"]:SetText("");
		table_insert(controls, dropdownSpellShowType);

	end

	-- // areaIconSize
	do

		areaIconSize = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
		areaIconSize:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		areaIconSize:SetBackdropColor(0.1, 0.1, 0.2, 1);
		areaIconSize:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		areaIconSize:SetPoint("TOPLEFT", areaAuraType, "TOPRIGHT", 0, 0);
		areaIconSize:SetWidth(333);
		areaIconSize:SetHeight(70);
		table_insert(controls, areaIconSize);

	end

	-- // sliderSpellIconSizeWidth
	do

		sliderSpellIconSizeWidth = VGUI.CreateSlider();
		sliderSpellIconSizeWidth:SetParent(areaIconSize);
		sliderSpellIconSizeWidth:SetWidth(160);
		sliderSpellIconSizeWidth:SetPoint("TOPLEFT", 18, -23);
		sliderSpellIconSizeWidth.label:ClearAllPoints();
		sliderSpellIconSizeWidth.label:SetPoint("CENTER", sliderSpellIconSizeWidth, "CENTER", 0, 15);
		sliderSpellIconSizeWidth.label:SetText(L["options:spells:icon-width"]);
		sliderSpellIconSizeWidth:ClearAllPoints();
		sliderSpellIconSizeWidth:SetPoint("LEFT", areaIconSize, "LEFT", 5, 0);
		sliderSpellIconSizeWidth.slider:ClearAllPoints();
		sliderSpellIconSizeWidth.slider:SetPoint("LEFT", 3, 0)
		sliderSpellIconSizeWidth.slider:SetPoint("RIGHT", -3, 0)
		sliderSpellIconSizeWidth.slider:SetValueStep(1);
		sliderSpellIconSizeWidth.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderSpellIconSizeWidth.slider:SetScript("OnValueChanged", function(self, value)
			sliderSpellIconSizeWidth.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.CustomSpells2[selectedSpell].iconSizeWidth = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderSpellIconSizeWidth.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderSpellIconSizeWidth.editbox:GetText() ~= "") then
				local v = tonumber(sliderSpellIconSizeWidth.editbox:GetText());
				if (v == nil) then
					sliderSpellIconSizeWidth.editbox:SetText(tostring(addonTable.db.CustomSpells2[selectedSpell].iconSizeWidth));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderSpellIconSizeWidth.slider:SetValue(v);
				end
				sliderSpellIconSizeWidth.editbox:ClearFocus();
			end
		end);
		sliderSpellIconSizeWidth.lowtext:SetText("1");
		sliderSpellIconSizeWidth.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		table_insert(controls, sliderSpellIconSizeWidth);

	end

	-- // sliderSpellIconSizeHeight
	do

		sliderSpellIconSizeHeight = VGUI.CreateSlider();
		sliderSpellIconSizeHeight:SetParent(areaIconSize);
		sliderSpellIconSizeHeight:SetWidth(160);
		sliderSpellIconSizeHeight:SetPoint("TOPLEFT", 18, -23);
		sliderSpellIconSizeHeight.label:ClearAllPoints();
		sliderSpellIconSizeHeight.label:SetPoint("CENTER", sliderSpellIconSizeHeight, "CENTER", 0, 15);
		sliderSpellIconSizeHeight.label:SetText(L["options:spells:icon-height"]);
		sliderSpellIconSizeHeight:ClearAllPoints();
		sliderSpellIconSizeHeight:SetPoint("LEFT", sliderSpellIconSizeWidth, "RIGHT", 0, 0);
		sliderSpellIconSizeHeight.slider:ClearAllPoints();
		sliderSpellIconSizeHeight.slider:SetPoint("LEFT", 3, 0)
		sliderSpellIconSizeHeight.slider:SetPoint("RIGHT", -3, 0)
		sliderSpellIconSizeHeight.slider:SetValueStep(1);
		sliderSpellIconSizeHeight.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderSpellIconSizeHeight.slider:SetScript("OnValueChanged", function(self, value)
			sliderSpellIconSizeHeight.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.CustomSpells2[selectedSpell].iconSizeHeight = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderSpellIconSizeHeight.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderSpellIconSizeHeight.editbox:GetText() ~= "") then
				local v = tonumber(sliderSpellIconSizeHeight.editbox:GetText());
				if (v == nil) then
					sliderSpellIconSizeHeight.editbox:SetText(tostring(addonTable.db.CustomSpells2[selectedSpell].iconSizeHeight));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderSpellIconSizeHeight.slider:SetValue(v);
				end
				sliderSpellIconSizeHeight.editbox:ClearFocus();
			end
		end);
		sliderSpellIconSizeHeight.lowtext:SetText("1");
		sliderSpellIconSizeHeight.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		table_insert(controls, sliderSpellIconSizeHeight);

	end

	-- // areaIDs
	do

		areaIDs = CreateFrame("Frame", nil, spellArea.controlsFrame, BackdropTemplateMixin and "BackdropTemplate");
		areaIDs:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		areaIDs:SetBackdropColor(0.1, 0.1, 0.2, 1);
		areaIDs:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		areaIDs:SetPoint("TOPLEFT", areaAuraType, "BOTTOMLEFT", 0, 0);
		areaIDs:SetWidth(500);
		areaIDs:SetHeight(40);
		table_insert(controls, areaIDs);

	end

	-- // editboxSpellID
	do

		local function StringToTableKeys(str)
			local t = { };
			for key in gmatch(str, "%w+") do
				local nmbr = tonumber(key);
				if (nmbr ~= nil) then
					t[nmbr] = true;
				end
			end
			return t;
		end

		editboxSpellID = CreateFrame("EditBox", nil, areaIDs, BackdropTemplateMixin and "BackdropTemplate");
		editboxSpellID:SetAutoFocus(false);
		editboxSpellID:SetFontObject(GameFontHighlightSmall);
		editboxSpellID.text = editboxSpellID:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		editboxSpellID.text:SetPoint("TOPLEFT", areaIDs, "TOPLEFT", 10, -10);
		editboxSpellID.text:SetText(L["Check spell ID"]);
		editboxSpellID:SetPoint("LEFT", editboxSpellID.text, "RIGHT", 5, 0);
		editboxSpellID:SetPoint("RIGHT", areaIDs, "RIGHT", -15, 0);
		editboxSpellID:SetHeight(20);
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
			local t = StringToTableKeys(text);
			addonTable.db.CustomSpells2[selectedSpell].checkSpellID = (table_count(t) > 0) and t or nil;
			addonTable.UpdateAllNameplates(true);
			if (table_count(t) == 0) then
				self:SetText("");
			end
			self:ClearFocus();
		end);
		table_insert(controls, editboxSpellID);

	end

	-- // buttonDeleteSpell
	do

		buttonDeleteSpell = VGUI.CreateButton();
		buttonDeleteSpell:SetParent(spellArea.controlsFrame);
		buttonDeleteSpell:SetText(L["Delete spell"]);
		buttonDeleteSpell:SetWidth(90);
		buttonDeleteSpell:SetHeight(20);
		buttonDeleteSpell:SetPoint("TOPLEFT", areaIDs, "BOTTOMLEFT", 10, -10);
		buttonDeleteSpell:SetPoint("TOPRIGHT", areaIDs, "BOTTOMRIGHT", -10, -10);
		buttonDeleteSpell:SetScript("OnClick", function(self, ...)
			addonTable.db.CustomSpells2[selectedSpell] = nil;
			addonTable.UpdateAllNameplates(false);
			selectSpell.Text:SetText(L["Click to select spell"]);
			selectSpell.icon:SetTexture(nil);
			for _, control in pairs(controls) do
				control:Hide();
			end
		end);
		table_insert(controls, buttonDeleteSpell);

	end

end

local function GUICategory_Interrupts(index, value)

	local interruptOptionsArea, checkBoxInterrupts, checkBoxUseSharedIconTexture, checkBoxEnableOnlyInPvPMode, sizeArea, sliderInterruptIconSizeWidth, sliderInterruptIconSizeHeight;

	-- // checkBoxInterrupts
	do

		checkBoxInterrupts = VGUI.CreateCheckBox();
		checkBoxInterrupts:SetText(L["options:interrupts:enable-interrupts"]);
		checkBoxInterrupts:SetOnClickHandler(function(this)
			addonTable.db.InterruptsEnabled = this:GetChecked();
			if (addonTable.db.InterruptsEnabled) then
				addonTable.EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
				interruptOptionsArea:Show();
			else
				addonTable.EventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
				interruptOptionsArea:Hide();
			end
		end);
		checkBoxInterrupts:SetChecked(addonTable.db.InterruptsEnabled);
		checkBoxInterrupts:SetParent(GUIFrame);
		checkBoxInterrupts:SetPoint("TOPLEFT", 160, -20);
		checkBoxInterrupts:HookScript("OnShow", function() if (addonTable.db.InterruptsEnabled) then interruptOptionsArea:Show(); end end);
		checkBoxInterrupts:HookScript("OnHide", function() interruptOptionsArea:Hide(); end);
		table_insert(GUIFrame.Categories[index], checkBoxInterrupts);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxInterrupts:SetChecked(addonTable.db.InterruptsEnabled);
		end);

	end

	-- // interruptOptionsArea
	do

		interruptOptionsArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		interruptOptionsArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		interruptOptionsArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		interruptOptionsArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		interruptOptionsArea:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -30);
		interruptOptionsArea:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -5, 0);
		interruptOptionsArea:SetHeight(200);
		interruptOptionsArea:Hide();

	end

	-- // checkBoxUseSharedIconTexture
	do
		checkBoxUseSharedIconTexture = VGUI.CreateCheckBox();
		checkBoxUseSharedIconTexture:SetText(L["options:interrupts:use-shared-icon-texture"]);
		checkBoxUseSharedIconTexture:SetOnClickHandler(function(this)
			addonTable.db.InterruptsUseSharedIconTexture = this:GetChecked();
			for spellID in pairs(addonTable.Interrupts) do
				SpellTextureByID[spellID] = addonTable.db.InterruptsUseSharedIconTexture and "Interface\\AddOns\\NameplateAuras\\media\\warrior_disruptingshout.tga" or SpellTextureByID[spellID]; -- // icon of Interrupting Shout
			end
			addonTable.UpdateAllNameplates(true);
		end);
		checkBoxUseSharedIconTexture:SetChecked(addonTable.db.InterruptsUseSharedIconTexture);
		checkBoxUseSharedIconTexture:SetParent(interruptOptionsArea);
		checkBoxUseSharedIconTexture:SetPoint("TOPLEFT", 20, -10);
		checkBoxUseSharedIconTexture:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxUseSharedIconTexture:SetChecked(addonTable.db.InterruptsUseSharedIconTexture);
		end);

	end

	-- // checkBoxEnableOnlyInPvPMode
	do
		checkBoxEnableOnlyInPvPMode = VGUI.CreateCheckBox();
		checkBoxEnableOnlyInPvPMode:Show();
		checkBoxEnableOnlyInPvPMode:SetText(L["options:interrupts:enable-only-during-pvp-battles"]);
		checkBoxEnableOnlyInPvPMode:SetOnClickHandler(function(this)
			addonTable.db.InterruptsShowOnlyOnPlayers = this:GetChecked();
			addonTable.UpdateAllNameplates(false);
		end);
		checkBoxEnableOnlyInPvPMode:SetChecked(addonTable.db.InterruptsShowOnlyOnPlayers);
		checkBoxEnableOnlyInPvPMode:SetParent(interruptOptionsArea);
		checkBoxEnableOnlyInPvPMode:SetPoint("TOPLEFT", checkBoxUseSharedIconTexture, "BOTTOMLEFT", 0, 0);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxEnableOnlyInPvPMode:SetChecked(addonTable.db.InterruptsShowOnlyOnPlayers);
		end);
	end

	-- // sizeArea
	do

		sizeArea = CreateFrame("Frame", nil, interruptOptionsArea, BackdropTemplateMixin and "BackdropTemplate");
		sizeArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		sizeArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		sizeArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		sizeArea:SetPoint("TOPLEFT", checkBoxEnableOnlyInPvPMode, "BOTTOMLEFT", 0, -10);
		sizeArea:SetPoint("RIGHT", interruptOptionsArea, "RIGHT", -10, 0);
		sizeArea:SetHeight(80);

	end

	-- // sliderInterruptIconSizeWidth
	do

		sliderInterruptIconSizeWidth = VGUI.CreateSlider();
		sliderInterruptIconSizeWidth:Show();
		sliderInterruptIconSizeWidth:SetParent(sizeArea);
		sliderInterruptIconSizeWidth:SetWidth((sizeArea:GetWidth() - 20 - 10)/2);
		sliderInterruptIconSizeWidth:ClearAllPoints();
		sliderInterruptIconSizeWidth:SetPoint("LEFT", sizeArea, "LEFT", 10, 0);
		sliderInterruptIconSizeWidth.label:ClearAllPoints();
		sliderInterruptIconSizeWidth.label:SetPoint("CENTER", sliderInterruptIconSizeWidth, "CENTER", 0, 15);
		sliderInterruptIconSizeWidth.label:SetText(L["options:spells:icon-width"]);
		sliderInterruptIconSizeWidth.slider:ClearAllPoints();
		sliderInterruptIconSizeWidth.slider:SetPoint("LEFT", 3, 0)
		sliderInterruptIconSizeWidth.slider:SetPoint("RIGHT", -3, 0)
		sliderInterruptIconSizeWidth.slider:SetValueStep(1);
		sliderInterruptIconSizeWidth.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderInterruptIconSizeWidth.slider:SetScript("OnValueChanged", function(self, value)
			sliderInterruptIconSizeWidth.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.InterruptsIconSizeWidth = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderInterruptIconSizeWidth.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderInterruptIconSizeWidth.editbox:GetText() ~= "") then
				local v = tonumber(sliderInterruptIconSizeWidth.editbox:GetText());
				if (v == nil) then
					sliderInterruptIconSizeWidth.editbox:SetText(tostring(addonTable.db.InterruptsIconSizeWidth));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderInterruptIconSizeWidth.slider:SetValue(v);
				end
				sliderInterruptIconSizeWidth.editbox:ClearFocus();
			end
		end);
		sliderInterruptIconSizeWidth.lowtext:SetText("1");
		sliderInterruptIconSizeWidth.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		sliderInterruptIconSizeWidth.slider:SetValue(addonTable.db.InterruptsIconSizeWidth);
		sliderInterruptIconSizeWidth.editbox:SetText(tostring(addonTable.db.InterruptsIconSizeWidth));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderInterruptIconSizeWidth.slider:SetValue(addonTable.db.InterruptsIconSizeWidth);
			sliderInterruptIconSizeWidth.editbox:SetText(tostring(addonTable.db.InterruptsIconSizeWidth));
		end);

	end

	-- // sliderInterruptIconSizeHeight
	do

		sliderInterruptIconSizeHeight = VGUI.CreateSlider();
		sliderInterruptIconSizeHeight:Show();
		sliderInterruptIconSizeHeight:SetParent(sizeArea);
		sliderInterruptIconSizeHeight:SetWidth((sizeArea:GetWidth() - 20 - 10)/2);
		sliderInterruptIconSizeHeight:ClearAllPoints();
		sliderInterruptIconSizeHeight:SetPoint("LEFT", sliderInterruptIconSizeWidth, "RIGHT", 10, 0);
		sliderInterruptIconSizeHeight.label:ClearAllPoints();
		sliderInterruptIconSizeHeight.label:SetPoint("CENTER", sliderInterruptIconSizeHeight, "CENTER", 0, 15);
		sliderInterruptIconSizeHeight.label:SetText(L["options:spells:icon-height"]);
		sliderInterruptIconSizeHeight.slider:ClearAllPoints();
		sliderInterruptIconSizeHeight.slider:SetPoint("LEFT", 3, 0)
		sliderInterruptIconSizeHeight.slider:SetPoint("RIGHT", -3, 0)
		sliderInterruptIconSizeHeight.slider:SetValueStep(1);
		sliderInterruptIconSizeHeight.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderInterruptIconSizeHeight.slider:SetScript("OnValueChanged", function(self, value)
			sliderInterruptIconSizeHeight.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.InterruptsIconSizeHeight = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderInterruptIconSizeHeight.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderInterruptIconSizeHeight.editbox:GetText() ~= "") then
				local v = tonumber(sliderInterruptIconSizeHeight.editbox:GetText());
				if (v == nil) then
					sliderInterruptIconSizeHeight.editbox:SetText(tostring(addonTable.db.InterruptsIconSizeHeight));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderInterruptIconSizeHeight.slider:SetValue(v);
				end
				sliderInterruptIconSizeHeight.editbox:ClearFocus();
			end
		end);
		sliderInterruptIconSizeHeight.lowtext:SetText("1");
		sliderInterruptIconSizeHeight.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		sliderInterruptIconSizeHeight.slider:SetValue(addonTable.db.InterruptsIconSizeHeight);
		sliderInterruptIconSizeHeight.editbox:SetText(tostring(addonTable.db.InterruptsIconSizeHeight));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderInterruptIconSizeHeight.slider:SetValue(addonTable.db.InterruptsIconSizeHeight);
			sliderInterruptIconSizeHeight.editbox:SetText(tostring(addonTable.db.InterruptsIconSizeHeight));
		end);

	end

	-- // dropdownGlowType
	do
		local glowTypes = { 
			[addonTable.GLOW_TYPE_NONE] = L["options:glow-type:GLOW_TYPE_NONE"],
			[addonTable.GLOW_TYPE_ACTIONBUTTON] = L["options:glow-type:GLOW_TYPE_ACTIONBUTTON"],
			[addonTable.GLOW_TYPE_AUTOUSE] = L["options:glow-type:GLOW_TYPE_AUTOUSE"],
			[addonTable.GLOW_TYPE_PIXEL] = L["options:glow-type:GLOW_TYPE_PIXEL"],
			[addonTable.GLOW_TYPE_ACTIONBUTTON_DIM] = L["options:glow-type:GLOW_TYPE_ACTIONBUTTON_DIM"],
		};

		local dropdownGlowType = CreateFrame("Frame", "NAurasGUI.Interrupts.dropdownGlowType", interruptOptionsArea, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownGlowType, 150);
		dropdownGlowType:SetPoint("TOPLEFT", sizeArea, "BOTTOMLEFT", -10, -20);
		local info = {};
		dropdownGlowType.initialize = function()
			wipe(info);
			for glowType, glowTypeLocalized in pairs(glowTypes) do
				info.text = glowTypeLocalized;
				info.value = glowType;
				info.func = function(self)
					addonTable.db.InterruptsGlowType = self.value;
					_G[dropdownGlowType:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = glowType == addonTable.db.InterruptsGlowType;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownGlowType:GetName() .. "Text"]:SetText(glowTypes[addonTable.db.InterruptsGlowType]);
		dropdownGlowType.text = dropdownGlowType:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownGlowType.text:SetPoint("LEFT", 20, 20);
		dropdownGlowType.text:SetText(L["options:glow-type"]);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownGlowType:GetName() .. "Text"]:SetText(glowTypes[addonTable.db.InterruptsGlowType]); end);

	end

end

local function GUICategory_Additions(index, value)
	local area1, checkBoxExplosiveOrbs;

	-- // area1
	do

		area1 = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		area1:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		area1:SetBackdropColor(0.1, 0.1, 0.2, 1);
		area1:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		area1:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, 0);
		area1:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -10, 0);
		area1:SetHeight(80);
		table_insert(GUIFrame.Categories[index], area1);

	end

	-- // checkBoxExplosiveOrbs
	do
		checkBoxExplosiveOrbs = VGUI.CreateCheckBox();
		checkBoxExplosiveOrbs:SetText(L["options:apps:explosive-orbs:tooltip"]);
		checkBoxExplosiveOrbs.Text:SetPoint("TOPLEFT");
		checkBoxExplosiveOrbs.Text:SetPoint("TOPRIGHT");
		checkBoxExplosiveOrbs.Text:SetJustifyH("CENTER");
		checkBoxExplosiveOrbs:SetOnClickHandler(function(this)
			addonTable.db.Additions_ExplosiveOrbs = this:GetChecked();
			if (not addonTable.db.Additions_ExplosiveOrbs) then
				addonTable.UpdateAllNameplates(true);
			end
		end);
		checkBoxExplosiveOrbs:SetChecked(addonTable.db.Additions_ExplosiveOrbs);
		checkBoxExplosiveOrbs:SetParent(GUIFrame);
		checkBoxExplosiveOrbs:SetPoint("LEFT", area1, "LEFT", 10, 0);
		table_insert(GUIFrame.Categories[index], checkBoxExplosiveOrbs);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxExplosiveOrbs:SetChecked(addonTable.db.Additions_ExplosiveOrbs);
		end);
	end

end

local function GUICategory_SizeAndPosition(index, value)
	local dropdownFrameAnchorToNameplate;
	local frameAnchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "TOP", "CENTER", "BOTTOM", "TOPLEFT", "LEFT", "BOTTOMLEFT" };
	local frameAnchorsLocalization = {
		[frameAnchors[1]] = L["anchor-point:topright"],
		[frameAnchors[2]] = L["anchor-point:right"],
		[frameAnchors[3]] = L["anchor-point:bottomright"],
		[frameAnchors[4]] = L["anchor-point:top"],
		[frameAnchors[5]] = L["anchor-point:center"],
		[frameAnchors[6]] = L["anchor-point:bottom"],
		[frameAnchors[7]] = L["anchor-point:topleft"],
		[frameAnchors[8]] = L["anchor-point:left"],
		[frameAnchors[9]] = L["anchor-point:bottomleft"]
	};


	-- // sliderIconSize
	do

		local sliderIconSize = VGUI.CreateSlider();
		sliderIconSize:SetParent(GUIFrame);
		sliderIconSize:SetWidth(170);
		sliderIconSize:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 5, -13);
		sliderIconSize.label:SetText(L["options:size-and-position:icon-width"]);
		sliderIconSize.slider:SetValueStep(1);
		sliderIconSize.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderIconSize.slider:SetValue(addonTable.db.DefaultIconSizeWidth);
		sliderIconSize.slider:SetScript("OnValueChanged", function(self, value)
			local valueNum = math_ceil(value);
			sliderIconSize.editbox:SetText(tostring(valueNum));
			for _, spellInfo in pairs(addonTable.db.CustomSpells2) do
				if (spellInfo.iconSizeWidth == addonTable.db.DefaultIconSizeWidth) then
					spellInfo.iconSizeWidth = valueNum;
				end
			end
			addonTable.db.DefaultIconSizeWidth = valueNum;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconSize.editbox:SetText(tostring(addonTable.db.DefaultIconSizeWidth));
		sliderIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconSize.editbox:GetText());
				if (v == nil) then
					sliderIconSize.editbox:SetText(tostring(addonTable.db.DefaultIconSizeWidth));
					msg(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
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
		sliderIconSize.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		table_insert(GUIFrame.Categories[index], sliderIconSize);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSize.slider:SetValue(addonTable.db.DefaultIconSizeWidth); sliderIconSize.editbox:SetText(tostring(addonTable.db.DefaultIconSizeWidth)); end);

	end

	-- // sliderIconHeight
	do
		local sliderIconHeight = VGUI.CreateSlider();
		sliderIconHeight:SetParent(GUIFrame);
		sliderIconHeight:SetWidth(170);
		sliderIconHeight:SetPoint("TOP", GUIFrame.ControlsFrame, "TOP", 0, -13);
		sliderIconHeight.label:SetText(L["options:size-and-position:icon-height"]);
		sliderIconHeight.slider:SetValueStep(1);
		sliderIconHeight.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderIconHeight.slider:SetValue(addonTable.db.DefaultIconSizeHeight);
		sliderIconHeight.slider:SetScript("OnValueChanged", function(self, value)
			local valueNum = math_ceil(value);
			sliderIconHeight.editbox:SetText(tostring(valueNum));
			for _, spellInfo in pairs(addonTable.db.CustomSpells2) do
				if (spellInfo.iconSizeHeight == addonTable.db.DefaultIconSizeHeight) then
					spellInfo.iconSizeHeight = valueNum;
				end
			end
			addonTable.db.DefaultIconSizeHeight = valueNum;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconHeight.editbox:SetText(tostring(addonTable.db.DefaultIconSizeHeight));
		sliderIconHeight.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconHeight.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconHeight.editbox:GetText());
				if (v == nil) then
					sliderIconHeight.editbox:SetText(tostring(addonTable.db.DefaultIconSizeHeight));
					msg(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderIconHeight.slider:SetValue(v);
				end
				sliderIconHeight.editbox:ClearFocus();
			end
		end);
		sliderIconHeight.lowtext:SetText("1");
		sliderIconHeight.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		table_insert(GUIFrame.Categories[index], sliderIconHeight);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderIconHeight.slider:SetValue(addonTable.db.DefaultIconSizeHeight);
			sliderIconHeight.editbox:SetText(tostring(addonTable.db.DefaultIconSizeHeight));
		end);
	end

	-- // sliderIconSpacing
	do
		local minValue, maxValue = 0, 50;
		local sliderIconSpacing = VGUI.CreateSlider();
		sliderIconSpacing:SetParent(GUIFrame);
		sliderIconSpacing:SetWidth(170);
		sliderIconSpacing:SetPoint("TOPRIGHT", GUIFrame.ControlsFrame, "TOPRIGHT", -5, -13);
		sliderIconSpacing.label:SetText(L["Space between icons"]);
		sliderIconSpacing.slider:SetValueStep(1);
		sliderIconSpacing.slider:SetMinMaxValues(minValue, maxValue);
		sliderIconSpacing.slider:SetValue(addonTable.db.IconSpacing);
		sliderIconSpacing.slider:SetScript("OnValueChanged", function(self, value)
			sliderIconSpacing.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.IconSpacing = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconSpacing.editbox:SetText(tostring(addonTable.db.IconSpacing));
		sliderIconSpacing.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconSpacing.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconSpacing.editbox:GetText());
				if (v == nil) then
					sliderIconSpacing.editbox:SetText(tostring(addonTable.db.IconSpacing));
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
		table_insert(GUIFrame.Categories[index], sliderIconSpacing);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSpacing.slider:SetValue(addonTable.db.IconSpacing); sliderIconSpacing.editbox:SetText(tostring(addonTable.db.IconSpacing)); end);
	end

	-- // sliderIconXOffset
	do

		local sliderIconXOffset = VGUI.CreateSlider();
		sliderIconXOffset:SetParent(GUIFrame);
		sliderIconXOffset:SetWidth(170);
		sliderIconXOffset:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 5, -73);
		sliderIconXOffset.label:SetText(L["Icon X-coord offset"]);
		sliderIconXOffset.slider:SetValueStep(1);
		sliderIconXOffset.slider:SetMinMaxValues(-200, 200);
		sliderIconXOffset.slider:SetValue(addonTable.db.IconXOffset);
		sliderIconXOffset.slider:SetScript("OnValueChanged", function(self, value)
			sliderIconXOffset.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.IconXOffset = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconXOffset.editbox:SetText(tostring(addonTable.db.IconXOffset));
		sliderIconXOffset.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconXOffset.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconXOffset.editbox:GetText());
				if (v == nil) then
					sliderIconXOffset.editbox:SetText(tostring(addonTable.db.IconXOffset));
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
		table_insert(GUIFrame.Categories[index], sliderIconXOffset);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconXOffset.slider:SetValue(addonTable.db.IconXOffset); sliderIconXOffset.editbox:SetText(tostring(addonTable.db.IconXOffset)); end);

	end

	-- // sliderIconYOffset
	do

		local sliderIconYOffset = VGUI.CreateSlider();
		sliderIconYOffset:SetParent(GUIFrame);
		sliderIconYOffset:SetWidth(170);
		sliderIconYOffset:SetPoint("TOP", GUIFrame.ControlsFrame, "TOP", 0, -73);
		sliderIconYOffset.label:SetText(L["Icon Y-coord offset"]);
		sliderIconYOffset.slider:SetValueStep(1);
		sliderIconYOffset.slider:SetMinMaxValues(-200, 200);
		sliderIconYOffset.slider:SetValue(addonTable.db.IconYOffset);
		sliderIconYOffset.slider:SetScript("OnValueChanged", function(self, value)
			sliderIconYOffset.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.IconYOffset = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconYOffset.editbox:SetText(tostring(addonTable.db.IconYOffset));
		sliderIconYOffset.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconYOffset.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconYOffset.editbox:GetText());
				if (v == nil) then
					sliderIconYOffset.editbox:SetText(tostring(addonTable.db.IconYOffset));
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
		table_insert(GUIFrame.Categories[index], sliderIconYOffset);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconYOffset.slider:SetValue(addonTable.db.IconYOffset); sliderIconYOffset.editbox:SetText(tostring(addonTable.db.IconYOffset)); end);

	end

	-- // sliderIconZoom
	do
		local minV, maxV = 0, 0.3;
		local sliderIconZoom = VGUI.CreateSlider();
		sliderIconZoom:SetParent(GUIFrame);
		sliderIconZoom:SetWidth(170);
		sliderIconZoom:SetPoint("TOPRIGHT", GUIFrame.ControlsFrame, "TOPRIGHT", -5, -73);
		sliderIconZoom.label:SetText(L["options:size-and-position:icon-zoom"]);
		sliderIconZoom.slider:SetValueStep(0.01);
		sliderIconZoom.slider:SetMinMaxValues(minV, maxV);
		sliderIconZoom.slider:SetValue(addonTable.db.IconZoom);
		sliderIconZoom.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.2f", value));
			sliderIconZoom.editbox:SetText(tostring(actualValue));
			addonTable.db.IconZoom = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconZoom.editbox:SetText(tostring(addonTable.db.IconZoom));
		sliderIconZoom.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconZoom.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconZoom.editbox:GetText());
				if (v == nil) then
					sliderIconZoom.editbox:SetText(tostring(addonTable.db.IconZoom));
					Print(L["Value must be a number"]);
				else
					if (v > maxV) then
						v = maxV;
					end
					if (v < minV) then
						v = minV;
					end
					sliderIconZoom.slider:SetValue(v);
				end
				sliderIconZoom.editbox:ClearFocus();
			end
		end);
		sliderIconZoom.lowtext:SetText(tostring(minV));
		sliderIconZoom.hightext:SetText(tostring(maxV));
		table_insert(GUIFrame.Categories[index], sliderIconZoom);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconZoom.slider:SetValue(addonTable.db.IconZoom); sliderIconZoom.editbox:SetText(tostring(addonTable.db.IconZoom)); end);
	end

	-- // dropdownFrameAnchorToNameplate
	do
					
		dropdownFrameAnchorToNameplate = CreateFrame("Frame", "NAuras.GUI.SizeAndPosition.dropdownFrameAnchorToNameplate", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownFrameAnchorToNameplate, 220);
		dropdownFrameAnchorToNameplate:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -140);
		local info = {};
		dropdownFrameAnchorToNameplate.initialize = function()
			wipe(info);
			for _, anchorPoint in pairs(frameAnchors) do
				info.text = frameAnchorsLocalization[anchorPoint];
				info.value = anchorPoint;
				info.func = function(self)
					addonTable.db.FrameAnchorToNameplate = self.value;
					_G[dropdownFrameAnchorToNameplate:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = anchorPoint == addonTable.db.FrameAnchorToNameplate;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownFrameAnchorToNameplate:GetName() .. "Text"]:SetText(frameAnchorsLocalization[addonTable.db.FrameAnchorToNameplate]);
		dropdownFrameAnchorToNameplate.text = dropdownFrameAnchorToNameplate:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownFrameAnchorToNameplate.text:SetPoint("LEFT", 20, 20);
		dropdownFrameAnchorToNameplate.text:SetText(L["options:size-and-position:anchor-point-to-nameplate"]);
		table_insert(GUIFrame.Categories[index], dropdownFrameAnchorToNameplate);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownFrameAnchorToNameplate:GetName() .. "Text"]:SetText(frameAnchorsLocalization[addonTable.db.FrameAnchorToNameplate]); end);
		
	end

	-- // dropdownFrameAnchor
	do
		local dropdownFrameAnchor = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownFrameAnchor", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownFrameAnchor, 220);
		dropdownFrameAnchor:SetPoint("TOPRIGHT", GUIFrame.ControlsFrame, "TOPRIGHT", 0, -140);
		local info = {};
		dropdownFrameAnchor.initialize = function()
			wipe(info);
			for _, anchorPoint in pairs(frameAnchors) do
				info.text = frameAnchorsLocalization[anchorPoint];
				info.value = anchorPoint;
				info.func = function(self)
					addonTable.db.FrameAnchor = self.value;
					_G[dropdownFrameAnchor:GetName().."Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = (addonTable.db.FrameAnchor == anchorPoint);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownFrameAnchor:GetName().."Text"]:SetText(frameAnchorsLocalization[addonTable.db.FrameAnchor]);
		dropdownFrameAnchor.text = dropdownFrameAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownFrameAnchor.text:SetPoint("LEFT", 20, 20);
		dropdownFrameAnchor.text:SetText(L["options:size-and-position:anchor-point-of-frame"]);
		VGUI.SetTooltip(dropdownFrameAnchor, L["options:size-and-position:anchor-point-of-frame:tooltip"]);
		table_insert(GUIFrame.Categories[index], dropdownFrameAnchor);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownFrameAnchor:GetName().."Text"]:SetText(frameAnchorsLocalization[addonTable.db.FrameAnchor]); end);

	end

	-- // dropdownIconAnchor
	do

		local anchors = { addonTable.ICON_ALIGN_BOTTOM_LEFT, addonTable.ICON_ALIGN_TOP_RIGHT, addonTable.ICON_ALIGN_CENTER }; -- // if you change this, don't forget to change 'symmetricAnchors'
		local anchorsLocalization = { 
			[anchors[1]] = L["options:size-and-position:icon-align:bottom-left"],
			[anchors[2]] = L["options:size-and-position:icon-align:top-right"],
			[anchors[3]] = L["options:size-and-position:icon-align:center"] };
		local dropdownIconAnchor = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownIconAnchor", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownIconAnchor, 220);
		dropdownIconAnchor:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -180);
		local info = {};
		dropdownIconAnchor.initialize = function()
			wipe(info);
			for _, anchor in pairs(anchors) do
				info.text = anchorsLocalization[anchor];
				info.value = anchor;
				info.func = function(self)
					addonTable.db.IconAnchor = self.value;
					_G[dropdownIconAnchor:GetName().."Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = (addonTable.db.IconAnchor == info.value);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownIconAnchor:GetName().."Text"]:SetText(anchorsLocalization[addonTable.db.IconAnchor]);
		dropdownIconAnchor.text = dropdownIconAnchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownIconAnchor.text:SetPoint("LEFT", 20, 20);
		dropdownIconAnchor.text:SetText(L["options:size-and-position:icon-align"]);
		table_insert(GUIFrame.Categories[index], dropdownIconAnchor);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownIconAnchor:GetName().."Text"]:SetText(anchorsLocalization[addonTable.db.IconAnchor]); end);

	end

	-- // dropdownIconGrowDirection
	do
		local growDirections = { addonTable.ICON_GROW_DIRECTION_RIGHT, addonTable.ICON_GROW_DIRECTION_LEFT, 
			addonTable.ICON_GROW_DIRECTION_UP, addonTable.ICON_GROW_DIRECTION_DOWN };
		local growDirectionsL = {
			[growDirections[1]] = L["icon-grow-direction:right"],
			[growDirections[2]] = L["icon-grow-direction:left"],
			[growDirections[3]] = L["icon-grow-direction:up"],
			[growDirections[4]] = L["icon-grow-direction:down"],
		};
		local dropdownIconGrowDirection = CreateFrame("Frame", "NAuras.GUI.SizeAndPosition.DropdownIconGrowDirection", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownIconGrowDirection, 220);
		dropdownIconGrowDirection:SetPoint("TOPRIGHT", GUIFrame.ControlsFrame, "TOPRIGHT", 0, -180);
		local info = {};
		dropdownIconGrowDirection.initialize = function()
			wipe(info);
			for _, direction in pairs(growDirections) do
				info.text = growDirectionsL[direction];
				info.value = direction;
				info.func = function(self)
					addonTable.db.IconGrowDirection = self.value;
					_G[dropdownIconGrowDirection:GetName().."Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = (addonTable.db.IconGrowDirection == info.value);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownIconGrowDirection:GetName().."Text"]:SetText(growDirectionsL[addonTable.db.IconGrowDirection]);
		dropdownIconGrowDirection.text = dropdownIconGrowDirection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownIconGrowDirection.text:SetPoint("LEFT", 20, 20);
		dropdownIconGrowDirection.text:SetText(L["options:general:icon-grow-direction"]);
		table.insert(GUIFrame.Categories[index], dropdownIconGrowDirection);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownIconGrowDirection:GetName().."Text"]:SetText(growDirectionsL[addonTable.db.IconGrowDirection]); end);
		
	end

	local dropdownTargetStrata, dropdownNonTargetStrata;
	local frameStratas = {
		"BACKGROUND",
		"LOW",
		"MEDIUM",
		"HIGH",
		"DIALOG",
		"FULLSCREEN",
		"FULLSCREEN_DIALOG",
		"TOOLTIP",
	};

	-- // dropdownTargetStrata
	do
		dropdownTargetStrata = CreateFrame("Frame", "NAuras.GUI.SizeAndPosition.dropdownTargetStrata", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownTargetStrata, 220);
		dropdownTargetStrata:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -220);
		local info = {};
		dropdownTargetStrata.initialize = function()
			wipe(info);
			for _, strata in pairs(frameStratas) do
				info.text = strata;
				info.value = strata;
				info.func = function(self)
					addonTable.db.TargetStrata = self.value;
					_G[dropdownTargetStrata:GetName().."Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = (addonTable.db.TargetStrata == info.value);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownTargetStrata:GetName().."Text"]:SetText(addonTable.db.TargetStrata);
		dropdownTargetStrata.text = dropdownTargetStrata:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownTargetStrata.text:SetPoint("LEFT", 20, 20);
		dropdownTargetStrata.text:SetText(L["options:size-and-position:target-strata"]);
		table.insert(GUIFrame.Categories[index], dropdownTargetStrata);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTargetStrata:GetName().."Text"]:SetText(addonTable.db.TargetStrata); end);
	end

	-- // dropdownNonTargetStrata
	do
		dropdownNonTargetStrata = CreateFrame("Frame", "NAuras.GUI.SizeAndPosition.dropdownNonTargetStrata", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownNonTargetStrata, 220);
		dropdownNonTargetStrata:SetPoint("TOPRIGHT", GUIFrame.ControlsFrame, "TOPRIGHT", 0, -220);
		local info = {};
		dropdownNonTargetStrata.initialize = function()
			wipe(info);
			for _, strata in pairs(frameStratas) do
				info.text = strata;
				info.value = strata;
				info.func = function(self)
					addonTable.db.NonTargetStrata = self.value;
					_G[dropdownNonTargetStrata:GetName().."Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = (addonTable.db.NonTargetStrata == info.value);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownNonTargetStrata:GetName().."Text"]:SetText(addonTable.db.NonTargetStrata);
		dropdownNonTargetStrata.text = dropdownNonTargetStrata:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownNonTargetStrata.text:SetPoint("LEFT", 20, 20);
		dropdownNonTargetStrata.text:SetText(L["options:size-and-position:non-target-strata"]);
		table.insert(GUIFrame.Categories[index], dropdownNonTargetStrata);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownNonTargetStrata:GetName().."Text"]:SetText(addonTable.db.NonTargetStrata); end);
	end

	local dropdownSortMode, buttonCustomSortFunction;
	do
		local SortModesLocalization = {
			[AURA_SORT_MODE_NONE] =					L["icon-sort-mode:none"],
			[AURA_SORT_MODE_EXPIRETIME] =			L["icon-sort-mode:by-expire-time"],
			[AURA_SORT_MODE_ICONSIZE] =				L["icon-sort-mode:by-icon-size"],
			[AURA_SORT_MODE_AURATYPE_EXPIRE] =		L["icon-sort-mode:by-aura-type+by-expire-time"],
			[addonTable.AURA_SORT_MODE_CUSTOM] =	L["icon-sort-mode:custom"],
		};

		local function UpdateButton()
			if (addonTable.db.SortMode == addonTable.AURA_SORT_MODE_CUSTOM) then
				buttonCustomSortFunction:Show();
			else
				buttonCustomSortFunction:Hide();
			end
		end

		dropdownSortMode = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownSortMode", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownSortMode, 300);
		dropdownSortMode:SetPoint("TOP", GUIFrame.ControlsFrame, "TOP", 0, -270);
		local info = {};
		dropdownSortMode.initialize = function()
			wipe(info);
			for sortMode, sortModeL in pairs(SortModesLocalization) do
				info.text = sortModeL;
				info.value = sortMode;
				info.func = function(self)
					addonTable.db.SortMode = self.value;
					_G[dropdownSortMode:GetName().."Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
					UpdateButton();
				end
				info.checked = (addonTable.db.SortMode == info.value);
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownSortMode:GetName().."Text"]:SetText(SortModesLocalization[addonTable.db.SortMode]);
		dropdownSortMode.text = dropdownSortMode:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		dropdownSortMode.text:SetPoint("LEFT", 20, 20);
		dropdownSortMode.text:SetText(L["Sort mode:"]);
		table_insert(GUIFrame.Categories[index], dropdownSortMode);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownSortMode:GetName().."Text"]:SetText(SortModesLocalization[addonTable.db.SortMode]); end);

		local LuaEditor = VGUI.CreateLuaEditor();
		LuaEditor:SetOnAcceptHandler(function(self)
			addonTable.db.CustomSortMethod = self:GetText();
			addonTable.CompileSortFunction();
			addonTable.UpdateAllNameplates(true);
		end);
		LuaEditor:SetOnTextChangedHandler(function(self)
			local script = self:GetText();
			script = "return " .. script;
			local func, errorMsg = loadstring(script);
			if (func ~= nil) then
				self:SetStatusText("");
			else
				self:SetStatusText(errorMsg);
			end
		end);

		local LuaEditorTooltip = VGUI.CreateTooltip();
		LuaEditorTooltip:SetParent(LuaEditor);
		LuaEditorTooltip:SetPoint("TOPLEFT", LuaEditor, "BOTTOMLEFT", 0, 0);
		LuaEditorTooltip:SetPoint("TOPRIGHT", LuaEditor, "BOTTOMRIGHT", 0, 0);
		LuaEditorTooltip:GetTextObject():SetFontObject(GameFontNormal);
		LuaEditorTooltip:GetTextObject():SetJustifyH("LEFT");
		LuaEditorTooltip:SetText(L["options:size-and-position:custom-sorting:tooltip"]);
		LuaEditor:SetInfoButton(true, function()
			if (LuaEditorTooltip:IsShown()) then
				LuaEditorTooltip:Hide();
			else
				LuaEditorTooltip:Show();
			end
		end);

		buttonCustomSortFunction = VGUI.CreateButton();
		buttonCustomSortFunction:SetParent(dropdownSortMode);
		buttonCustomSortFunction:SetText("Lua -->>");
		buttonCustomSortFunction:SetWidth(60);
		buttonCustomSortFunction:SetHeight(22);
		buttonCustomSortFunction:SetPoint("LEFT", dropdownSortMode, "RIGHT", 0, 3);
		buttonCustomSortFunction:SetScript("OnClick", function()
			LuaEditor:SetText(addonTable.db.CustomSortMethod);
			LuaEditor:Show();
		end);
		UpdateButton();
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			UpdateButton();
		end);

	end

	-- do
	-- 	local SortModesLocalization = {
	-- 		[AURA_SORT_MODE_NONE] =				L["icon-sort-mode:none"],
	-- 		[AURA_SORT_MODE_EXPIRETIME] =		L["icon-sort-mode:by-expire-time"],
	-- 		[AURA_SORT_MODE_ICONSIZE] =			L["icon-sort-mode:by-icon-size"],
	-- 		[AURA_SORT_MODE_AURATYPE_EXPIRE] =	L["icon-sort-mode:by-aura-type+by-expire-time"],
	-- 	};

	-- 	dropdownSortMode = VGUI.CreateDropdown();
	-- 	dropdownSortMode:SetParent(GUIFrame);
	-- 	dropdownSortMode:SetSize(300, 24);
	-- 	dropdownSortMode:SetPoint("TOP", GUIFrame.ControlsFrame, "TOP", 0, -270);

	-- 	local t = { };
	-- 	for sortMode, sortModeL in pairs(SortModesLocalization) do
	-- 		local entry = { };
	-- 		entry.text = sortModeL;
	-- 		entry.func = function(self)
	-- 			addonTable.db.SortMode = sortMode;
	-- 			addonTable.UpdateAllNameplates(true);
	-- 		end
	-- 		entry.selected = (addonTable.db.SortMode == sortMode);
	-- 		t[#t+1] = entry;
	-- 	end
	-- 	dropdownSortMode:SetList(t);

	-- 	table_insert(GUIFrame.Categories[index], dropdownSortMode);
	-- end

	local scaleArea, sliderScale, sliderScaleTarget;

	-- // scaleArea
	do

		scaleArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		scaleArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		scaleArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		scaleArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		scaleArea:SetPoint("TOP", dropdownSortMode, "BOTTOM", 0, 0);
		scaleArea:SetWidth(360);
		scaleArea:SetHeight(70);
		table_insert(GUIFrame.Categories[index], scaleArea);

	end

	-- // sliderScaleTarget
	do

		local minValue, maxValue, step = 0.1, 10, 0.1;
		sliderScaleTarget = VGUI.CreateSlider();
		sliderScaleTarget:SetParent(scaleArea);
		sliderScaleTarget:SetWidth(scaleArea:GetWidth() - 20);
		sliderScaleTarget:SetPoint("TOPLEFT", 10, -20);
		sliderScaleTarget.label:SetText(L["options:size-and-position:scale-target"]);
		sliderScaleTarget.slider:SetValueStep(step);
		sliderScaleTarget.slider:SetMinMaxValues(minValue, maxValue);
		sliderScaleTarget.slider:SetValue(addonTable.db.IconScaleTarget);
		sliderScaleTarget.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.1f", value));
			sliderScaleTarget.editbox:SetText(tostring(actualValue));
			addonTable.db.IconScaleTarget = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderScaleTarget.editbox:SetText(tostring(addonTable.db.IconScaleTarget));
		sliderScaleTarget.editbox:SetScript("OnEnterPressed", function(self, value)
			if (self:GetText() ~= "") then
				local v = tonumber(self:GetText());
				if (v == nil) then
					self:SetText(tostring(addonTable.db.IconScaleTarget));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderScaleTarget.slider:SetValue(v);
				end
				self:ClearFocus();
			else
				self:SetText(tostring(addonTable.db.IconScaleTarget));
				msg(L["Value must be a number"]);
			end
		end);
		sliderScaleTarget.lowtext:SetText(tostring(minValue));
		sliderScaleTarget.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderScaleTarget.editbox:SetText(tostring(addonTable.db.IconScaleTarget));
			sliderScaleTarget.slider:SetValue(addonTable.db.IconScaleTarget);
		end);
		sliderScaleTarget:Show();

	end

end

local function GUICategory_Alpha(index, value)
	local alphaArea, sliderAlpha, sliderAlphaTarget;

	-- // alphaArea
	do

		alphaArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		alphaArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		alphaArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		alphaArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		alphaArea:SetPoint("TOPLEFT", 150, -12);
		alphaArea:SetPoint("TOPRIGHT", -12, -12);
		alphaArea:SetHeight(140);
		table_insert(GUIFrame.Categories[index], alphaArea);

	end

	-- // sliderAlpha
	do

		local minValue, maxValue, step = 0, 1, 0.01;
		sliderAlpha = VGUI.CreateSlider();
		sliderAlpha:SetParent(alphaArea);
		sliderAlpha:SetWidth(alphaArea:GetWidth() - 20);
		sliderAlpha:SetPoint("TOPLEFT", 10, -20);
		sliderAlpha.label:SetText(L["options:alpha:alpha"]);
		sliderAlpha.slider:SetValueStep(step);
		sliderAlpha.slider:SetMinMaxValues(minValue, maxValue);
		sliderAlpha.slider:SetValue(addonTable.db.IconAlpha);
		sliderAlpha.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.2f", value));
			sliderAlpha.editbox:SetText(tostring(actualValue));
			addonTable.db.IconAlpha = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderAlpha.editbox:SetText(tostring(addonTable.db.IconAlpha));
		sliderAlpha.editbox:SetScript("OnEnterPressed", function(self, value)
			if (self:GetText() ~= "") then
				local v = tonumber(self:GetText());
				if (v == nil) then
					self:SetText(tostring(addonTable.db.IconAlpha));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderAlpha.slider:SetValue(v);
				end
				self:ClearFocus();
			else
				self:SetText(tostring(addonTable.db.IconAlpha));
				msg(L["Value must be a number"]);
			end
		end);
		sliderAlpha.lowtext:SetText(tostring(minValue));
		sliderAlpha.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderAlpha.editbox:SetText(tostring(addonTable.db.IconAlpha));
			sliderAlpha.slider:SetValue(addonTable.db.IconAlpha);
		end);
		sliderAlpha:Show();

	end

	-- // sliderAlphaTarget
	do

		local minValue, maxValue, step = 0, 1, 0.01;
		sliderAlphaTarget = VGUI.CreateSlider();
		sliderAlphaTarget:SetParent(alphaArea);
		sliderAlphaTarget:SetWidth(alphaArea:GetWidth() - 20);
		sliderAlphaTarget:SetPoint("TOPLEFT", 10, -85);
		sliderAlphaTarget.label:SetText(L["options:alpha:alpha-target"]);
		sliderAlphaTarget.slider:SetValueStep(step);
		sliderAlphaTarget.slider:SetMinMaxValues(minValue, maxValue);
		sliderAlphaTarget.slider:SetValue(addonTable.db.IconAlphaTarget);
		sliderAlphaTarget.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.2f", value));
			sliderAlphaTarget.editbox:SetText(tostring(actualValue));
			addonTable.db.IconAlphaTarget = actualValue;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderAlphaTarget.editbox:SetText(tostring(addonTable.db.IconAlphaTarget));
		sliderAlphaTarget.editbox:SetScript("OnEnterPressed", function(self, value)
			if (self:GetText() ~= "") then
				local v = tonumber(self:GetText());
				if (v == nil) then
					self:SetText(tostring(addonTable.db.IconAlphaTarget));
					msg(L["Value must be a number"]);
				else
					if (v > maxValue) then
						v = maxValue;
					end
					if (v < minValue) then
						v = minValue;
					end
					sliderAlphaTarget.slider:SetValue(v);
				end
				self:ClearFocus();
			else
				self:SetText(tostring(addonTable.db.IconAlphaTarget));
				msg(L["Value must be a number"]);
			end
		end);
		sliderAlphaTarget.lowtext:SetText(tostring(minValue));
		sliderAlphaTarget.hightext:SetText(tostring(maxValue));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderAlphaTarget.editbox:SetText(tostring(addonTable.db.IconAlphaTarget));
			sliderAlphaTarget.slider:SetValue(addonTable.db.IconAlphaTarget);
		end);
		sliderAlphaTarget:Show();

	end

end

local function GUICategory_Dispel(index, value)
	local checkBoxDispellableSpells, dispellableSpellsBlacklist, addButton, editboxAddSpell, dropdownGlowType, controlArea, sizeArea, sliderDispelIconSizeHeight, sliderDispelIconSizeWidth;
	local dispellableSpellsBlacklistMenu = VGUI.CreateDropdownMenu();

	-- // checkBoxDispellableSpells
	do

		checkBoxDispellableSpells = VGUI.CreateCheckBox();
		checkBoxDispellableSpells:SetText(L["options:apps:dispellable-spells"]);
		checkBoxDispellableSpells:SetOnClickHandler(function(this)
			addonTable.db.Additions_DispellableSpells = this:GetChecked();
			if (not addonTable.db.Additions_DispellableSpells) then
				addonTable.UpdateAllNameplates(true);
				controlArea:Hide();
			else
				controlArea:Show();
			end
		end);
		checkBoxDispellableSpells:HookScript("OnShow", function() if (addonTable.db.Additions_DispellableSpells) then controlArea:Show(); end end);
		checkBoxDispellableSpells:HookScript("OnHide", function() controlArea:Hide(); end);
		checkBoxDispellableSpells:SetChecked(addonTable.db.Additions_DispellableSpells);
		checkBoxDispellableSpells:SetParent(GUIFrame);
		checkBoxDispellableSpells:SetPoint("TOPLEFT", 160, -20);
		VGUI.SetTooltip(checkBoxDispellableSpells, L["options:apps:dispellable-spells:tooltip"]);
		table_insert(GUIFrame.Categories[index], checkBoxDispellableSpells);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxDispellableSpells:SetChecked(addonTable.db.Additions_DispellableSpells);
		end);

	end

	-- controlArea
	do
		controlArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
		controlArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		controlArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		controlArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		controlArea:SetPoint("TOPLEFT", GUIFrame.ControlsFrame, "TOPLEFT", 0, -30);
		controlArea:SetPoint("RIGHT", GUIFrame.ControlsFrame, "RIGHT", -5, 0);
		controlArea:SetHeight(160);
		controlArea:Hide();
	end

	-- // sizeArea
	do

		sizeArea = CreateFrame("Frame", nil, controlArea, BackdropTemplateMixin and "BackdropTemplate");
		sizeArea:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = 1,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		});
		sizeArea:SetBackdropColor(0.1, 0.1, 0.2, 1);
		sizeArea:SetBackdropBorderColor(0.8, 0.8, 0.9, 0.4);
		sizeArea:SetPoint("TOPLEFT", controlArea, "TOPLEFT", 10, -10);
		sizeArea:SetPoint("RIGHT", controlArea, "RIGHT", -10, 0);
		sizeArea:SetHeight(80);

	end

	-- // sliderDispelIconSizeWidth
	do

		sliderDispelIconSizeWidth = VGUI.CreateSlider();
		sliderDispelIconSizeWidth:Show();
		sliderDispelIconSizeWidth:SetParent(sizeArea);
		sliderDispelIconSizeWidth:SetWidth((sizeArea:GetWidth() - 20 - 10)/2);
		sliderDispelIconSizeWidth:ClearAllPoints();
		sliderDispelIconSizeWidth:SetPoint("LEFT", sizeArea, "LEFT", 10, 0);
		sliderDispelIconSizeWidth.label:ClearAllPoints();
		sliderDispelIconSizeWidth.label:SetPoint("CENTER", sliderDispelIconSizeWidth, "CENTER", 0, 15);
		sliderDispelIconSizeWidth.label:SetText(L["options:spells:icon-width"]);
		sliderDispelIconSizeWidth.slider:ClearAllPoints();
		sliderDispelIconSizeWidth.slider:SetPoint("LEFT", 3, 0)
		sliderDispelIconSizeWidth.slider:SetPoint("RIGHT", -3, 0)
		sliderDispelIconSizeWidth.slider:SetValueStep(1);
		sliderDispelIconSizeWidth.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderDispelIconSizeWidth.slider:SetScript("OnValueChanged", function(self, value)
			sliderDispelIconSizeWidth.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.DispelIconSizeWidth = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderDispelIconSizeWidth.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderDispelIconSizeWidth.editbox:GetText() ~= "") then
				local v = tonumber(sliderDispelIconSizeWidth.editbox:GetText());
				if (v == nil) then
					sliderDispelIconSizeWidth.editbox:SetText(tostring(addonTable.db.DispelIconSizeWidth));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderDispelIconSizeWidth.slider:SetValue(v);
				end
				sliderDispelIconSizeWidth.editbox:ClearFocus();
			end
		end);
		sliderDispelIconSizeWidth.lowtext:SetText("1");
		sliderDispelIconSizeWidth.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		sliderDispelIconSizeWidth.slider:SetValue(addonTable.db.DispelIconSizeWidth);
		sliderDispelIconSizeWidth.editbox:SetText(tostring(addonTable.db.DispelIconSizeWidth));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderDispelIconSizeWidth.slider:SetValue(addonTable.db.DispelIconSizeWidth);
			sliderDispelIconSizeWidth.editbox:SetText(tostring(addonTable.db.DispelIconSizeWidth));
		end);

	end

	-- // sliderDispelIconSizeHeight
	do

		sliderDispelIconSizeHeight = VGUI.CreateSlider();
		sliderDispelIconSizeHeight:Show();
		sliderDispelIconSizeHeight:SetParent(sizeArea);
		sliderDispelIconSizeHeight:SetWidth((sizeArea:GetWidth() - 20 - 10)/2);
		sliderDispelIconSizeHeight:ClearAllPoints();
		sliderDispelIconSizeHeight:SetPoint("LEFT", sliderDispelIconSizeWidth, "RIGHT", 10, 0);
		sliderDispelIconSizeHeight.label:ClearAllPoints();
		sliderDispelIconSizeHeight.label:SetPoint("CENTER", sliderDispelIconSizeHeight, "CENTER", 0, 15);
		sliderDispelIconSizeHeight.label:SetText(L["options:spells:icon-height"]);
		sliderDispelIconSizeHeight.slider:ClearAllPoints();
		sliderDispelIconSizeHeight.slider:SetPoint("LEFT", 3, 0)
		sliderDispelIconSizeHeight.slider:SetPoint("RIGHT", -3, 0)
		sliderDispelIconSizeHeight.slider:SetValueStep(1);
		sliderDispelIconSizeHeight.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderDispelIconSizeHeight.slider:SetScript("OnValueChanged", function(self, value)
			sliderDispelIconSizeHeight.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.DispelIconSizeHeight = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderDispelIconSizeHeight.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderDispelIconSizeHeight.editbox:GetText() ~= "") then
				local v = tonumber(sliderDispelIconSizeHeight.editbox:GetText());
				if (v == nil) then
					sliderDispelIconSizeHeight.editbox:SetText(tostring(addonTable.db.DispelIconSizeHeight));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderDispelIconSizeHeight.slider:SetValue(v);
				end
				sliderDispelIconSizeHeight.editbox:ClearFocus();
			end
		end);
		sliderDispelIconSizeHeight.lowtext:SetText("1");
		sliderDispelIconSizeHeight.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		sliderDispelIconSizeHeight.slider:SetValue(addonTable.db.DispelIconSizeHeight);
		sliderDispelIconSizeHeight.editbox:SetText(tostring(addonTable.db.DispelIconSizeHeight));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderDispelIconSizeHeight.slider:SetValue(addonTable.db.DispelIconSizeHeight);
			sliderDispelIconSizeHeight.editbox:SetText(tostring(addonTable.db.DispelIconSizeHeight));
		end);

	end

	-- // dropdownGlowType
	do
		local glowTypes = { 
			[addonTable.GLOW_TYPE_NONE] = L["options:glow-type:GLOW_TYPE_NONE"],
			[addonTable.GLOW_TYPE_ACTIONBUTTON] = L["options:glow-type:GLOW_TYPE_ACTIONBUTTON"],
			[addonTable.GLOW_TYPE_AUTOUSE] = L["options:glow-type:GLOW_TYPE_AUTOUSE"],
			[addonTable.GLOW_TYPE_PIXEL] = L["options:glow-type:GLOW_TYPE_PIXEL"],
			[addonTable.GLOW_TYPE_ACTIONBUTTON_DIM] = L["options:glow-type:GLOW_TYPE_ACTIONBUTTON_DIM"],
		};

		dropdownGlowType = CreateFrame("Frame", "NAurasGUI.Dispel.dropdownGlowType", controlArea, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownGlowType, 170);
		dropdownGlowType:SetPoint("TOPLEFT", sizeArea, "BOTTOMLEFT", -10, -20);
		local info = {};
		dropdownGlowType.initialize = function()
			wipe(info);
			for glowType, glowTypeLocalized in pairs(glowTypes) do
				info.text = glowTypeLocalized;
				info.value = glowType;
				info.func = function(self)
					addonTable.db.Additions_DispellableSpells_GlowType = self.value;
					_G[dropdownGlowType:GetName() .. "Text"]:SetText(self:GetText());
					addonTable.UpdateAllNameplates(true);
				end
				info.checked = glowType == addonTable.db.Additions_DispellableSpells_GlowType;
				UIDropDownMenu_AddButton(info);
			end
		end
		_G[dropdownGlowType:GetName() .. "Text"]:SetText(glowTypes[addonTable.db.Additions_DispellableSpells_GlowType]);
		dropdownGlowType.text = dropdownGlowType:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		dropdownGlowType.text:SetPoint("LEFT", 20, 20);
		dropdownGlowType.text:SetText(L["options:glow-type"]);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownGlowType:GetName() .. "Text"]:SetText(glowTypes[addonTable.db.Additions_DispellableSpells_GlowType]); end);

	end

	-- // dispellableSpellsBlacklist
	do
		dispellableSpellsBlacklist = VGUI.CreateButton();
		dispellableSpellsBlacklist:SetParent(controlArea);
		dispellableSpellsBlacklist:SetText(L["options:apps:dispellable-spells:black-list-button"]);
		dispellableSpellsBlacklist:SetWidth(controlArea:GetWidth());
		dispellableSpellsBlacklist:SetHeight(24);
		dispellableSpellsBlacklist:SetPoint("TOP", controlArea, "BOTTOM", 0, -10);
		dispellableSpellsBlacklist:SetScript("OnClick", function(button)
			if (dispellableSpellsBlacklistMenu:IsShown()) then
				dispellableSpellsBlacklistMenu:Hide();
			else
				local t = { };
				for spellName in pairs(addonTable.db.Additions_DispellableSpells_Blacklist) do
					table_insert(t, {
						text = spellName,
						icon = SpellTextureByID[next(AllSpellIDsAndIconsByName[spellName])],
						onCloseButtonClick = function(buttonInfo)
							addonTable.db.Additions_DispellableSpells_Blacklist[spellName] = nil;
							-- close and then open list again
							dispellableSpellsBlacklist:Click(); dispellableSpellsBlacklist:Click();
						end,
					});
				end
				table_sort(t, function(item1, item2) return item1.text < item2.text end);
				dispellableSpellsBlacklistMenu:SetList(t);
				dispellableSpellsBlacklistMenu:SetParent(button);
				dispellableSpellsBlacklistMenu:Show();
				dispellableSpellsBlacklistMenu.searchBox:SetFocus();
				dispellableSpellsBlacklistMenu.searchBox:SetText("");
			end
		end);
		dispellableSpellsBlacklist:SetScript("OnHide", function(self) dispellableSpellsBlacklistMenu:Hide(); end);
		dispellableSpellsBlacklist:Disable();
		hooksecurefunc(addonTable, "OnSpellInfoCachesReady", function() dispellableSpellsBlacklist:Enable(); end);
		GUIFrame:HookScript("OnHide", function() dispellableSpellsBlacklist:Disable(); end);
	end

	-- addButton
	do
		addButton = VGUI.CreateButton();
		addButton:SetParent(dispellableSpellsBlacklistMenu);
		addButton:SetText(L["Add spell"]);
		addButton:SetWidth(dispellableSpellsBlacklistMenu:GetWidth() / 3);
		addButton:SetHeight(24);
		addButton:SetPoint("TOPRIGHT", dispellableSpellsBlacklistMenu, "BOTTOMRIGHT", 0, -8);
		addButton:SetScript("OnClick", function(button)
			local text = editboxAddSpell:GetText();
			if (text ~= nil and text ~= "") then
				local spellExist = false;
				if (AllSpellIDsAndIconsByName[text]) then
					spellExist = true;
				else
					for _spellName, _spellInfo in pairs(AllSpellIDsAndIconsByName) do
						if (string_lower(_spellName) == string_lower(text)) then
							text = _spellName;
							spellExist = true;
							break;
						end
					end
				end
				if (not spellExist) then
					msg(L["Spell seems to be nonexistent"]);
				else
					addonTable.db.Additions_DispellableSpells_Blacklist[text] = true;
					addonTable.UpdateAllNameplates(false);
					-- close and then open list again
					dispellableSpellsBlacklist:Click(); dispellableSpellsBlacklist:Click();
				end
			end
			editboxAddSpell:SetText("");
		end);
	end

	-- editboxAddSpell
	do
		editboxAddSpell = CreateFrame("EditBox", nil, dispellableSpellsBlacklistMenu, "InputBoxTemplate");
		editboxAddSpell:SetAutoFocus(false);
		editboxAddSpell:SetFontObject(GameFontHighlightSmall);
		editboxAddSpell:SetHeight(20);
		editboxAddSpell:SetWidth(dispellableSpellsBlacklistMenu:GetWidth() - addButton:GetWidth() - 10);
		editboxAddSpell:SetPoint("BOTTOMRIGHT", addButton, "BOTTOMLEFT", -5, 2);
		editboxAddSpell:SetJustifyH("LEFT");
		editboxAddSpell:EnableMouse(true);
		editboxAddSpell:SetScript("OnEscapePressed", function() editboxAddSpell:ClearFocus(); end);
		editboxAddSpell:SetScript("OnEnterPressed", function() addButton:Click(); end);
		local text = editboxAddSpell:CreateFontString(nil, "ARTWORK", "GameFontDisableTiny");
		text:SetPoint("LEFT", 0, 0);
		text:SetText(L["options:spells:add-new-spell"]);
		editboxAddSpell:SetScript("OnEditFocusGained", function() text:Hide(); end);
		editboxAddSpell:SetScript("OnEditFocusLost", function() text:Show(); end);
		hooksecurefunc("ChatEdit_InsertLink", function(link)
			if (editboxAddSpell:IsVisible() and editboxAddSpell:HasFocus() and link ~= nil) then
				local spellName = string.match(link, "%[\"?(.-)\"?%]");
				if (spellName ~= nil) then
					editboxAddSpell:SetText(spellName);
					editboxAddSpell:ClearFocus();
					return true;
				end
			end
		end);
	end

	-- dispellableSpellsBlacklistMenu
	do
		dispellableSpellsBlacklistMenu.Background = dispellableSpellsBlacklistMenu:CreateTexture(nil, "BORDER");
		dispellableSpellsBlacklistMenu.Background:SetPoint("TOPLEFT", dispellableSpellsBlacklistMenu, "TOPLEFT", -2, 2);
		dispellableSpellsBlacklistMenu.Background:SetPoint("BOTTOMRIGHT", addButton, "BOTTOMRIGHT",  2, -2);
		dispellableSpellsBlacklistMenu.Background:SetColorTexture(1, 0.3, 0.3, 1);
		dispellableSpellsBlacklistMenu.Border = dispellableSpellsBlacklistMenu:CreateTexture(nil, "BACKGROUND");
		dispellableSpellsBlacklistMenu.Border:SetPoint("TOPLEFT", dispellableSpellsBlacklistMenu, "TOPLEFT", -3, 3);
		dispellableSpellsBlacklistMenu.Border:SetPoint("BOTTOMRIGHT", addButton, "BOTTOMRIGHT",  3, -3);
		dispellableSpellsBlacklistMenu.Border:SetColorTexture(0.1, 0.1, 0.1, 1);
		dispellableSpellsBlacklistMenu:ClearAllPoints();
		dispellableSpellsBlacklistMenu:SetPoint("TOPLEFT", dispellableSpellsBlacklist, "TOPRIGHT", 5, 0);
	end

end

local function DeleteUnexistantSpells()
    local db = addonTable.db;
	for index, spellInfo in pairs(db.CustomSpells2) do
		if (AllSpellIDsAndIconsByName[spellInfo.spellName] == nil) then
			addonTable.Print(("Spell with name '%s' is not found (deleted from game?)"):format(spellInfo.spellName));
			db.CustomSpells2[index] = nil;
		end
	end
end

local function InitializeGUI_CreateSpellInfoCaches()
	GUIFrame:HookScript("OnShow", function()
		local scanAllSpells = coroutine.create(function()
			local misses = 0;
			local id = 0;
			while (misses < 400) do
				id = id + 1;
				local name, _, icon = GetSpellInfo(id);
				if (icon == 136243) then -- 136243 is the a gear icon
					misses = 0;
				elseif (name and name ~= "") then
					misses = 0;
					if (AllSpellIDsAndIconsByName[name] == nil) then AllSpellIDsAndIconsByName[name] = { }; end
					AllSpellIDsAndIconsByName[name][id] = icon;
				else
					misses = misses + 1;
				end
				coroutine.yield();
			end
			DeleteUnexistantSpells();
			addonTable.OnSpellInfoCachesReady();
		end);
		CoroutineProcessor:Queue("scanAllSpells", scanAllSpells);
	end);
	GUIFrame:HookScript("OnHide", function()
		CoroutineProcessor:DeleteFromQueue("scanAllSpells");
		wipe(AllSpellIDsAndIconsByName);
	end);
end

local function InitializeGUI()
	GUIFrame = CreateFrame("Frame", "NAuras.GUIFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate");
	GUIFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	GUIFrame:SetScript("OnEvent", function(self, event, ...)
		if (event == "PLAYER_REGEN_DISABLED") then
			if (self:IsVisible()) then
				self:Hide();
				self:RegisterEvent("PLAYER_REGEN_ENABLED");
			end
		elseif (event == "PLAYER_REGEN_ENABLED") then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED");
			self:Show();
		end
	end);
	GUIFrame:SetHeight(445);
	GUIFrame:SetWidth(530*1.3+20);
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

	local header = GUIFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	header:SetFont(GameFontNormal:GetFont(), 22, "THICKOUTLINE");
	header:SetPoint("BOTTOM", GUIFrame, "TOP", 0, 0);
	header:SetJustifyH("CENTER");
	header:SetText("NameplateAuras");

	GUIFrame.outline = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
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

	GUIFrame.ControlsFrame = CreateFrame("Frame", nil, GUIFrame);
	GUIFrame.ControlsFrame:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 12, 0);
	GUIFrame.ControlsFrame:SetPoint("BOTTOMRIGHT", GUIFrame, "BOTTOMRIGHT", -12, 12);
	GUIFrame.ControlsFrame:Hide();

	local closeButton = VGUI.CreateButton();-- CreateFrame("Button", nil, GUIFrame, "UIPanelButtonTemplate");
	closeButton:SetParent(GUIFrame);
	closeButton:SetText("Close");
	closeButton:SetWidth(60);
	closeButton:SetHeight(20);
	closeButton:SetPoint("BOTTOMRIGHT", GUIFrame, "TOPRIGHT", -4, 0);
	closeButton:SetScript("OnClick", function() GUIFrame:Hide(); end);
	
	GUIFrame.Categories = {};
	GUIFrame.OnDBChangedHandlers = {};
	table_insert(GUIFrame.OnDBChangedHandlers, function() OnGUICategoryClick(GUIFrame.CategoryButtons[1]); end);

	local categories = { L["General"], L["options:category:size-and-position"], L["options:category:alpha"], L["Timer text"], L["Stack text"],
		L["Icon borders"], L["Spells"], L["options:category:interrupts"], L["options:category:dispel"], L["options:category:apps"] };
	for index, value in pairs(categories) do
		local b = CreateGUICategory();
		b.index = index;
		b.text:SetText(value);
		if (index == 1) then
			b:LockHighlight();
			b.text:SetTextColor(1, 1, 1);
			b:SetPoint("TOPLEFT", GUIFrame.outline, "TOPLEFT", 5, -6);
		elseif (index >= #categories - 3) then
			b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 26);
		else
			b:SetPoint("TOPLEFT",GUIFrame.outline,"TOPLEFT", 5, -18 * (index - 1) - 6);
		end

		GUIFrame.Categories[index] = {};

		if (value == L["General"]) then
			GUICategory_1(index, value);
		elseif (value == L["Timer text"]) then
			GUICategory_Fonts(index, value);
		elseif (value == L["Stack text"]) then
			GUICategory_AuraStackFont(index, value);
		elseif (value == L["Icon borders"]) then
			GUICategory_Borders(index, value);
		elseif (value == L["Spells"]) then
			GUICategory_4(index, value);
		elseif (value == L["options:category:interrupts"]) then
			GUICategory_Interrupts(index, value);
		elseif (value == L["options:category:apps"]) then
			GUICategory_Additions(index, value);
		elseif (value == L["options:category:size-and-position"]) then
			GUICategory_SizeAndPosition(index, value);
		elseif (value == L["options:category:dispel"]) then
			GUICategory_Dispel(index, value);
		elseif (value == L["options:category:alpha"]) then
			GUICategory_Alpha(index, value);
		end
	end

	local buttonTestMode;
	do
		buttonTestMode = VGUI.CreateButton();
		buttonTestMode:SetParent(GUIFrame.outline);
		buttonTestMode:SetText(L["options:general:test-mode"]);
		buttonTestMode:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMLEFT", 4, 4);
		buttonTestMode:SetPoint("BOTTOMRIGHT", GUIFrame.outline, "BOTTOMRIGHT", -4, 4);
		buttonTestMode:SetHeight(30);
		buttonTestMode:SetScript("OnClick", function(self, ...)
			addonTable.SwitchTestMode();
		end);
	end

	-- profiles button
	do
		local button = VGUI.CreateButton();
		button:SetParent(GUIFrame.outline);
		button:SetText(L["Profiles"]);
		button:SetHeight(30);
		button:SetPoint("BOTTOMLEFT", buttonTestMode, "TOPLEFT", 0, 0);
		button:SetPoint("BOTTOMRIGHT", buttonTestMode, "TOPRIGHT", 0, 0);
		button:SetScript("OnClick", function(self, ...)
			LibStub("AceConfigDialog-3.0"):Open("NameplateAuras.profiles");
			GUIFrame:Hide();
		end);
	end

	InitializeGUI_CreateSpellInfoCaches();
	addonTable.GUIFrame = GUIFrame;
end

function addonTable.ShowGUI()
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

local LDB = LibStub("LibDataBroker-1.1");
if (LDB ~= nil) then
	local plugin = LDB:NewDataObject(addonName,
		{
			type = "data source",
			text = "",
			icon = [[Interface\AddOns\NameplateAuras\media\broker_logo.tga]],
			tocname = addonName,
		}
	);
	plugin.OnClick = function(display, button)
		if (button == "LeftButton") then
			if (GUIFrame ~= nil and GUIFrame:IsShown()) then
				GUIFrame:Hide();
			else
				addonTable.ShowGUI();
			end
		elseif (button == "RightButton") then
			addonTable.SwitchTestMode();
		end
	end
	plugin.OnTooltipShow = function(tooltip)
		tooltip:AddLine(addonName);
		tooltip:AddLine(" ");
		tooltip:AddLine("|cffeda55fLeftClick:|r open options window");
		tooltip:AddLine("|cffeda55fRightClick:|r switch test mode");
	end
end
