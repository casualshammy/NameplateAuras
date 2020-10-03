local _, addonTable = ...;
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

local function GetDefaultDBSpellEntry(enabledState, spellName, iconSize, checkSpellID)
	return {
		["enabledState"] =				enabledState,
		["auraType"] =					AURA_TYPE_ANY,
		["iconSize"] =					(iconSize ~= nil) and iconSize or addonTable.db.DefaultIconSize,
		["spellName"] =					spellName,
		["checkSpellID"] =				checkSpellID,
		["showOnFriends"] =				true,
		["showOnEnemies"] =				true,
		["pvpCombat"] =					CONST_SPELL_PVP_MODES_UNDEFINED,
		["showGlow"] =					nil,
		["glowType"] =					addonTable.GLOW_TYPE_AUTOUSE,
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

	local buttonTestMode, checkBoxHideBlizzardFrames, checkBoxHidePlayerBlizzardFrame, checkBoxShowAurasOnPlayerNameplate,
		checkBoxShowAboveFriendlyUnits, checkBoxShowMyAuras, checkboxAuraTooltip, checkboxShowCooldownAnimation;

	-- buttonTestMode
	do
		buttonTestMode = VGUI.CreateButton();
		buttonTestMode:SetParent(GUIFrame);
		buttonTestMode:SetText(L["options:general:test-mode"]);
		buttonTestMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -28);
		buttonTestMode:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -30, -28);
		buttonTestMode:SetHeight(30);
		buttonTestMode:SetScript("OnClick", function(self, ...)
			addonTable.SwitchTestMode();
		end);
		table_insert(GUIFrame.Categories[index], buttonTestMode);
	end

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
		checkBoxHideBlizzardFrames:SetPoint("TOPLEFT", buttonTestMode, "BOTTOMLEFT", 0, -10);
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

local function GUICategory_2(index, value)
	local button = VGUI.CreateButton();
	button:SetParent(GUIFrame);
	button:SetText(L["Open profiles dialog"]);
	button:SetWidth(170);
	button:SetHeight(40);
	button:SetPoint("CENTER", GUIFrame, "CENTER", 70, 0);
	button:SetScript("OnClick", function(self, ...)
		LibStub("AceConfigDialog-3.0"):Open("NameplateAuras.profiles");
		GUIFrame:Hide();
	end);
	table_insert(GUIFrame.Categories[index], button);
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
	local sliderTimerFontScale, sliderTimerFontSize, timerTextColorArea, tenthsOfSecondsArea, checkboxShowCooldownText;

	-- // checkboxShowCooldownText
	do
		checkboxShowCooldownText = VGUI.CreateCheckBox();
		checkboxShowCooldownText:SetText(L["options:general:show-cooldown-text"]);
		checkboxShowCooldownText:SetOnClickHandler(function(this)
			addonTable.db.ShowCooldownText = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
		end);
		checkboxShowCooldownText:SetChecked(addonTable.db.ShowCooldownText);
		checkboxShowCooldownText:SetParent(GUIFrame);
		checkboxShowCooldownText:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -20);
		table_insert(GUIFrame.Categories[index], checkboxShowCooldownText);
		table_insert(GUIFrame.OnDBChangedHandlers, function() 
			checkboxShowCooldownText:SetChecked(addonTable.db.ShowCooldownText);
			addonTable.UpdateAllNameplates(true);
		end);
	end

	-- // dropdownFont
	do

		local fonts = { };
		local button = VGUI.CreateButton();
		button:SetParent(GUIFrame);
		button:SetText(L["Font"] .. ": " .. addonTable.db.Font);

		for idx, font in next, SML:List("font") do
			table_insert(fonts, {
				["text"] = font,
				["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
				["func"] = function(info)
					button.Text:SetText(L["Font"] .. ": " .. info.text);
					addonTable.db.Font = info.text;
					addonTable.UpdateAllNameplates(true);
				end,
				["font"] = SML:Fetch("font", font),
			});
		end
		table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);

		button:SetWidth(170);
		button:SetHeight(24);
		button:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -48);
		button:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -30, -48);
		button:SetScript("OnClick", function(self, ...)
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
		table_insert(GUIFrame.Categories[index], button);

	end

	-- // sliderTimerFontScale
	do

		local minValue, maxValue = 0.3, 3;
		sliderTimerFontScale = VGUI.CreateSlider();
		sliderTimerFontScale:SetParent(GUIFrame);
		sliderTimerFontScale:SetWidth(200);
		sliderTimerFontScale:SetPoint("TOPLEFT", 300, -88);
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
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerFontScale.editbox:SetText(tostring(addonTable.db.FontScale)); sliderTimerFontScale.slider:SetValue(addonTable.db.FontScale); end);

	end

	-- // sliderTimerFontSize
	do

		local minValue, maxValue = 6, 96;
		sliderTimerFontSize = VGUI.CreateSlider();
		sliderTimerFontSize:SetParent(GUIFrame);
		sliderTimerFontSize:SetWidth(200);
		sliderTimerFontSize:SetPoint("TOPLEFT", 300, -88);
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

	-- // checkBoxUseRelativeFontSize
	do

		local checkBoxUseRelativeFontSize = VGUI.CreateCheckBox();
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
		checkBoxUseRelativeFontSize:SetParent(GUIFrame);
		checkBoxUseRelativeFontSize:SetPoint("TOPLEFT", 160, -100);
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

	-- // dropdownTimerTextAnchor
	do

		local dropdownTimerTextAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchor", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownTimerTextAnchor, 145);
		dropdownTimerTextAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -145);
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
		table_insert(GUIFrame.Categories[index], dropdownTimerTextAnchor);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchor]); end);

	end

	-- // dropdownTimerTextAnchorIcon
	do

		local dropdownTimerTextAnchorIcon = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownTimerTextAnchorIcon", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownTimerTextAnchorIcon, 145);
		dropdownTimerTextAnchorIcon:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 315, -145);
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
		table_insert(GUIFrame.Categories[index], dropdownTimerTextAnchorIcon);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownTimerTextAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.TimerTextAnchorIcon]); end);

	end

	-- // sliderTimerTextXOffset
	do

		local minValue, maxValue = -100, 100;
		local sliderTimerTextXOffset = VGUI.CreateSlider();
		sliderTimerTextXOffset:SetParent(GUIFrame);
		sliderTimerTextXOffset:SetWidth(165);
		sliderTimerTextXOffset:SetPoint("TOPLEFT", 160, -190);
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
		table_insert(GUIFrame.Categories[index], sliderTimerTextXOffset);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerTextXOffset.editbox:SetText(tostring(addonTable.db.TimerTextXOffset)); sliderTimerTextXOffset.slider:SetValue(addonTable.db.TimerTextXOffset); end);

	end

	-- // sliderTimerTextYOffset
	do

		local minValue, maxValue = -100, 100;
		local sliderTimerTextYOffset = VGUI.CreateSlider();
		sliderTimerTextYOffset:SetParent(GUIFrame);
		sliderTimerTextYOffset:SetWidth(165);
		sliderTimerTextYOffset:SetPoint("TOPLEFT", 335, -190);
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
		table_insert(GUIFrame.Categories[index], sliderTimerTextYOffset);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderTimerTextYOffset.editbox:SetText(tostring(addonTable.db.TimerTextYOffset)); sliderTimerTextYOffset.slider:SetValue(addonTable.db.TimerTextYOffset); end);

	end

	-- // timerTextColorArea
	do

		timerTextColorArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
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
		timerTextColorArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -230);
		timerTextColorArea:SetWidth(360);
		timerTextColorArea:SetHeight(71);
		table_insert(GUIFrame.Categories[index], timerTextColorArea);

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
		colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextSoonToExpireColor));
		colorPickerTimerTextFiveSeconds:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.TimerTextSoonToExpireColor = {r, g, b};
				colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextSoonToExpireColor));
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.TimerTextSoonToExpireColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.TimerTextSoonToExpireColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerTimerTextFiveSeconds);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextFiveSeconds.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextSoonToExpireColor)); end);

	end

	-- // colorPickerTimerTextMinute
	do

		local colorPickerTimerTextMinute = VGUI.CreateColorPicker();
		colorPickerTimerTextMinute:SetParent(timerTextColorArea);
		colorPickerTimerTextMinute:SetPoint("TOPLEFT", 135, -40);
		colorPickerTimerTextMinute:SetText(L["< 1min"]);
		colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextUnderMinuteColor));
		colorPickerTimerTextMinute:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.TimerTextUnderMinuteColor = {r, g, b};
				colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextUnderMinuteColor));
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.TimerTextUnderMinuteColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.TimerTextUnderMinuteColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerTimerTextMinute);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMinute.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextUnderMinuteColor)); end);

	end

	-- // colorPickerTimerTextMore
	do

		local colorPickerTimerTextMore = VGUI.CreateColorPicker();
		colorPickerTimerTextMore:SetParent(timerTextColorArea);
		colorPickerTimerTextMore:SetPoint("TOPLEFT", 260, -40);
		colorPickerTimerTextMore:SetText(L["> 1min"]);
		colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextLongerColor));
		colorPickerTimerTextMore:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.TimerTextLongerColor = {r, g, b};
				colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextLongerColor));
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.TimerTextLongerColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.TimerTextLongerColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerTimerTextMore);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerTimerTextMore.colorSwatch:SetVertexColor(unpack(addonTable.db.TimerTextLongerColor)); end);

	end

	-- // tenthsOfSecondsArea
	do

		tenthsOfSecondsArea = CreateFrame("Frame", nil, GUIFrame, BackdropTemplateMixin and "BackdropTemplate");
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
		tenthsOfSecondsArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -305);
		tenthsOfSecondsArea:SetWidth(360);
		tenthsOfSecondsArea:SetHeight(71);
		table_insert(GUIFrame.Categories[index], tenthsOfSecondsArea);

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
		table_insert(GUIFrame.Categories[index], sliderDisplayTenthsOfSeconds);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderDisplayTenthsOfSeconds.editbox:SetText(tostring(addonTable.db.MinTimeToShowTenthsOfSeconds)); sliderDisplayTenthsOfSeconds.slider:SetValue(addonTable.db.MinTimeToShowTenthsOfSeconds); end);

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

	-- // checkboxShowStacks
	do
		local checkboxShowStacks = VGUI.CreateCheckBox();
		checkboxShowStacks:SetText(L["options:general:show-stacks"]);
		checkboxShowStacks:SetOnClickHandler(function(this)
			addonTable.db.ShowStacks = this:GetChecked();
			addonTable.UpdateAllNameplates(true);
		end);
		checkboxShowStacks:SetChecked(addonTable.db.ShowStacks);
		checkboxShowStacks:SetParent(GUIFrame);
		checkboxShowStacks:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -20);
		table_insert(GUIFrame.Categories[index], checkboxShowStacks);
		table_insert(GUIFrame.OnDBChangedHandlers, function() 
			checkboxShowStacks:SetChecked(addonTable.db.ShowStacks);
			addonTable.UpdateAllNameplates(true);
		end);
	end


	-- // dropdownStacksFont
	do

		local fonts = { };
		local button = VGUI.CreateButton();
		button:SetParent(GUIFrame);
		button:SetText(L["Font"] .. ": " .. addonTable.db.StacksFont);

		for idx, font in next, SML:List("font") do
			table_insert(fonts, {
				["text"] = font,
				["icon"] = [[Interface\AddOns\NameplateAuras\media\font.tga]],
				["func"] = function(info)
					button.Text:SetText(L["Font"] .. ": " .. info.text);
					addonTable.db.StacksFont = info.text;
					addonTable.UpdateAllNameplates(true);
				end,
				["font"] = SML:Fetch("font", font),
			});
		end
		table_sort(fonts, function(item1, item2) return item1.text < item2.text; end);

		button:SetWidth(170);
		button:SetHeight(24);
		button:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 160, -48);
		button:SetPoint("TOPRIGHT", GUIFrame, "TOPRIGHT", -30, -48);
		button:SetScript("OnClick", function(self, ...)
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
		table_insert(GUIFrame.Categories[index], button);

	end

	-- // sliderStacksFontScale
	do

		local minValue, maxValue = 0.3, 3;
		local sliderStacksFontScale = VGUI.CreateSlider();
		sliderStacksFontScale:SetParent(GUIFrame);
		sliderStacksFontScale:SetWidth(340);
		sliderStacksFontScale:SetPoint("TOPLEFT", 160, -88);
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
		table_insert(GUIFrame.Categories[index], sliderStacksFontScale);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksFontScale.editbox:SetText(tostring(addonTable.db.StacksFontScale)); sliderStacksFontScale.slider:SetValue(addonTable.db.StacksFontScale); end);

	end

	-- // dropdownStacksAnchor
	do

		local dropdownStacksAnchor = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchor", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownStacksAnchor, 145);
		dropdownStacksAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -145);
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
		table_insert(GUIFrame.Categories[index], dropdownStacksAnchor);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchor:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.StacksTextAnchor]); end);

	end

	-- // dropdownStacksAnchorIcon
	do

		local dropdownStacksAnchorIcon = CreateFrame("Frame", "NAuras.GUI.Fonts.DropdownStacksAnchorIcon", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownStacksAnchorIcon, 145);
		dropdownStacksAnchorIcon:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 315, -145);
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
		table_insert(GUIFrame.Categories[index], dropdownStacksAnchorIcon);
		table_insert(GUIFrame.OnDBChangedHandlers, function() _G[dropdownStacksAnchorIcon:GetName() .. "Text"]:SetText(textAnchorsLocalization[addonTable.db.StacksTextAnchorIcon]); end);

	end

	-- // sliderStacksTextXOffset
	do

		local minValue, maxValue = -100, 100;
		local sliderStacksTextXOffset = VGUI.CreateSlider();
		sliderStacksTextXOffset:SetParent(GUIFrame);
		sliderStacksTextXOffset:SetWidth(165);
		sliderStacksTextXOffset:SetPoint("TOPLEFT", 160, -190);
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
		table_insert(GUIFrame.Categories[index], sliderStacksTextXOffset);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksTextXOffset.editbox:SetText(tostring(addonTable.db.StacksTextXOffset)); sliderStacksTextXOffset.slider:SetValue(addonTable.db.StacksTextXOffset); end);

	end

	-- // sliderStacksTextYOffset
	do

		local minValue, maxValue = -100, 100;
		local sliderStacksTextYOffset = VGUI.CreateSlider();
		sliderStacksTextYOffset:SetParent(GUIFrame);
		sliderStacksTextYOffset:SetWidth(165);
		sliderStacksTextYOffset:SetPoint("TOPLEFT", 335, -190);
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
		table_insert(GUIFrame.Categories[index], sliderStacksTextYOffset);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderStacksTextYOffset.editbox:SetText(tostring(addonTable.db.StacksTextYOffset)); sliderStacksTextYOffset.slider:SetValue(addonTable.db.StacksTextYOffset); end);

	end

	-- // colorPickerStacksTextColor
	do

		local colorPickerStacksTextColor = VGUI.CreateColorPicker();
		colorPickerStacksTextColor:SetParent(GUIFrame);
		colorPickerStacksTextColor:SetPoint("TOPLEFT", 165, -260);
		colorPickerStacksTextColor:SetText(L["Text color"]);
		colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(addonTable.db.StacksTextColor));
		colorPickerStacksTextColor:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.StacksTextColor = {r, g, b};
				colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(addonTable.db.StacksTextColor));
				for nameplate in pairs(addonTable.Nameplates) do
					if (nameplate.NAurasFrame) then
						for _, icon in pairs(nameplate.NAurasIcons) do
							icon.stacks:SetTextColor(unpack(addonTable.db.StacksTextColor));
						end
					end
				end
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.StacksTextColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.StacksTextColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerStacksTextColor);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerStacksTextColor.colorSwatch:SetVertexColor(unpack(addonTable.db.StacksTextColor)); end);

	end

end

local function GUICategory_Borders(index, value)

	local debuffArea;

	-- // sliderBorderThickness
	do

		local minValue, maxValue = 1, 5;
		local sliderBorderThickness = VGUI.CreateSlider();
		sliderBorderThickness:SetParent(GUIFrame);
		sliderBorderThickness:SetWidth(325);
		sliderBorderThickness:SetPoint("TOPLEFT", 160, -30);
		sliderBorderThickness.label:SetText(L["Border thickness"]);
		sliderBorderThickness.slider:SetValueStep(1);
		sliderBorderThickness.slider:SetMinMaxValues(minValue, maxValue);
		sliderBorderThickness.slider:SetValue(addonTable.db.BorderThickness);
		sliderBorderThickness.slider:SetScript("OnValueChanged", function(self, value)
			local actualValue = tonumber(string_format("%.0f", value));
			sliderBorderThickness.editbox:SetText(tostring(actualValue));
			addonTable.db.BorderThickness = actualValue;
			for nameplate in pairs(addonTable.Nameplates) do
				if (nameplate.NAurasFrame) then
					for _, icon in pairs(nameplate.NAurasIcons) do
						icon.border:SetTexture(BORDER_TEXTURES[addonTable.db.BorderThickness]);
					end
				end
			end
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
		table_insert(GUIFrame.Categories[index], sliderBorderThickness);
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderBorderThickness.editbox:SetText(tostring(addonTable.db.BorderThickness)); sliderBorderThickness.slider:SetValue(addonTable.db.BorderThickness); end);

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
		checkBoxBuffBorder:SetPoint("TOPLEFT", 160, -90);
		checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(addonTable.db.BuffBordersColor));
		checkBoxBuffBorder.ColorButton:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.BuffBordersColor = {r, g, b};
				checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(addonTable.db.BuffBordersColor));
				addonTable.UpdateAllNameplates(true);
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.BuffBordersColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.BuffBordersColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], checkBoxBuffBorder);
		table_insert(GUIFrame.OnDBChangedHandlers, function() checkBoxBuffBorder:SetChecked(addonTable.db.ShowBuffBorders); checkBoxBuffBorder.ColorButton.colorSwatch:SetVertexColor(unpack(addonTable.db.BuffBordersColor)); end);

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
		debuffArea:SetPoint("TOPLEFT", 150, -120);
		debuffArea:SetWidth(360);
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
		colorPickerDebuffMagic:SetColor(unpack(addonTable.db.DebuffBordersMagicColor));
		colorPickerDebuffMagic:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.DebuffBordersMagicColor = {r, g, b};
				colorPickerDebuffMagic:SetColor(unpack(addonTable.db.DebuffBordersMagicColor));
				addonTable.UpdateAllNameplates();
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.DebuffBordersMagicColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.DebuffBordersMagicColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerDebuffMagic);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffMagic:SetColor(unpack(addonTable.db.DebuffBordersMagicColor)); end);

	end

	-- // colorPickerDebuffCurse
	do

		local colorPickerDebuffCurse = VGUI.CreateColorPicker();
		colorPickerDebuffCurse:SetParent(debuffArea);
		colorPickerDebuffCurse:SetPoint("TOPLEFT", 135, -45);
		colorPickerDebuffCurse:SetText(L["Curse"]);
		colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersCurseColor));
		colorPickerDebuffCurse:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.DebuffBordersCurseColor = {r, g, b};
				colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersCurseColor));
				addonTable.UpdateAllNameplates();
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.DebuffBordersCurseColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.DebuffBordersCurseColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerDebuffCurse);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffCurse.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersCurseColor)); end);

	end

	-- // colorPickerDebuffDisease
	do

		local colorPickerDebuffDisease = VGUI.CreateColorPicker();
		colorPickerDebuffDisease:SetParent(debuffArea);
		colorPickerDebuffDisease:SetPoint("TOPLEFT", 255, -45);
		colorPickerDebuffDisease:SetText(L["Disease"]);
		colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersDiseaseColor));
		colorPickerDebuffDisease:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.DebuffBordersDiseaseColor = {r, g, b};
				colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersDiseaseColor));
				addonTable.UpdateAllNameplates();
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.DebuffBordersDiseaseColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.DebuffBordersDiseaseColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerDebuffDisease);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffDisease.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersDiseaseColor)); end);

	end

	-- // colorPickerDebuffPoison
	do

		local colorPickerDebuffPoison = VGUI.CreateColorPicker();
		colorPickerDebuffPoison:SetParent(debuffArea);
		colorPickerDebuffPoison:SetPoint("TOPLEFT", 15, -70);
		colorPickerDebuffPoison:SetText(L["Poison"]);
		colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersPoisonColor));
		colorPickerDebuffPoison:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.DebuffBordersPoisonColor = {r, g, b};
				colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersPoisonColor));
				addonTable.UpdateAllNameplates();
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.DebuffBordersPoisonColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.DebuffBordersPoisonColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerDebuffPoison);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffPoison.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersPoisonColor)); end);

	end

	-- // colorPickerDebuffOther
	do

		local colorPickerDebuffOther = VGUI.CreateColorPicker();
		colorPickerDebuffOther:SetParent(debuffArea);
		colorPickerDebuffOther:SetPoint("TOPLEFT", 135, -70);
		colorPickerDebuffOther:SetText(L["Other"]);
		colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersOtherColor));
		colorPickerDebuffOther:SetScript("OnClick", function()
			ColorPickerFrame:Hide();
			local function callback(restore)
				local r, g, b;
				if (restore) then
					r, g, b = unpack(restore);
				else
					r, g, b = ColorPickerFrame:GetColorRGB();
				end
				addonTable.db.DebuffBordersOtherColor = {r, g, b};
				colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersOtherColor));
				addonTable.UpdateAllNameplates();
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
			ColorPickerFrame:SetColorRGB(unpack(addonTable.db.DebuffBordersOtherColor));
			ColorPickerFrame.hasOpacity = false;
			ColorPickerFrame.previousValues = { unpack(addonTable.db.DebuffBordersOtherColor) };
			ColorPickerFrame:Show();
		end);
		table_insert(GUIFrame.Categories[index], colorPickerDebuffOther);
		table_insert(GUIFrame.OnDBChangedHandlers, function() colorPickerDebuffOther.colorSwatch:SetVertexColor(unpack(addonTable.db.DebuffBordersOtherColor)); end);

	end

end

local function GUICategory_4(index, value)
	local controls = { };
	local selectedSpell = 0;
	local dropdownMenuSpells = VGUI.CreateDropdownMenu();
	local spellArea, editboxAddSpell, buttonAddSpell, dropdownSelectSpell, sliderSpellIconSize, dropdownSpellShowType, editboxSpellID, buttonDeleteSpell, checkboxShowOnFriends,
		checkboxShowOnEnemies, selectSpell, checkboxPvPMode, checkboxEnabled, checkboxGlow, areaGlow, sliderGlowThreshold, areaIconSize, areaAuraType, areaIDs,
		areaMaxAuraDurationFilter, sliderMaxAuraDurationFilter, dropdownGlowType, areaAnimation, checkboxAnimation, dropdownAnimationType, sliderAnimationThreshold;
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
		[addonTable.ICON_ANIMATION_TYPE_SCALE] = L["options:animation-type:ICON_ANIMATION_TYPE_SCALE"],
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
		spellArea:SetPoint("TOPLEFT", GUIFrame.outline, "TOPRIGHT", 10, -85);
		spellArea:SetPoint("BOTTOMLEFT", GUIFrame.outline, "BOTTOMRIGHT", 10, 0);
		spellArea:SetWidth(360);

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
		editboxAddSpell:SetPoint("TOPLEFT", GUIFrame, 172, -30);
		editboxAddSpell:SetHeight(20);
		editboxAddSpell:SetWidth(200);
		editboxAddSpell:SetJustifyH("LEFT");
		editboxAddSpell:EnableMouse(true);
		editboxAddSpell:SetScript("OnEscapePressed", function() editboxAddSpell:ClearFocus(); end);
		editboxAddSpell:SetScript("OnEnterPressed", function() buttonAddSpell:Click(); end);
		local text = editboxAddSpell:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		text:SetPoint("LEFT", 0, 15);
		text:SetText(L["Add new spell: "]);
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
		buttonAddSpell:SetWidth(115);
		buttonAddSpell:SetHeight(20);
		buttonAddSpell:SetPoint("LEFT", editboxAddSpell, "RIGHT", 10, 0);
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
				local newSpellInfo = GetDefaultDBSpellEntry(CONST_SPELL_MODE_ALL, spellName, addonTable.db.DefaultIconSize,
					(customSpellID ~= nil) and { [customSpellID] = true } or nil);
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
			sliderSpellIconSize.slider:SetValue(spellInfo.iconSize);
			sliderSpellIconSize.editbox:SetText(tostring(spellInfo.iconSize));
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
				dropdownGlowType:Hide();
				areaGlow:SetHeight(40);
			elseif (spellInfo.showGlow == GLOW_TIME_INFINITE) then
				checkboxGlow:SetTriState(2);
				sliderGlowThreshold:Hide();
				areaGlow:SetHeight(80);
			else
				checkboxGlow:SetTriState(1);
				sliderGlowThreshold.slider:SetValue(spellInfo.showGlow);
				areaGlow:SetHeight(80);
			end
			_G[dropdownGlowType:GetName().."Text"]:SetText(glowTypes[spellInfo.glowType]);
			if (spellInfo.animationDisplayMode == addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE) then
				checkboxAnimation:SetTriState(0);
				sliderAnimationThreshold:Hide();
				dropdownAnimationType:Hide();
				areaAnimation:SetHeight(40);
			elseif (spellInfo.animationDisplayMode == addonTable.ICON_ANIMATION_DISPLAY_MODE_ALWAYS) then
				checkboxAnimation:SetTriState(2);
				sliderAnimationThreshold:Hide();
				areaAnimation:SetHeight(80);
			elseif (spellInfo.animationDisplayMode == addonTable.ICON_ANIMATION_DISPLAY_MODE_THRESHOLD) then
				checkboxAnimation:SetTriState(1);
				sliderAnimationThreshold.slider:SetValue(spellInfo.animationTimer);
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
			addonTable.ColorizeText(L["options:auras:enabled-state-all"], 0, 1, 0)));
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
		areaGlow:SetWidth(340);
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
				dropdownGlowType:Hide();
				areaGlow:SetHeight(40);
			elseif (self:GetTriState() == 1) then
				addonTable.db.CustomSpells2[selectedSpell].showGlow = 5;
				sliderGlowThreshold:Show();
				dropdownGlowType:Show();
				sliderGlowThreshold.slider:SetValue(5);
				areaGlow:SetHeight(80);
			else
				addonTable.db.CustomSpells2[selectedSpell].showGlow = GLOW_TIME_INFINITE;
				sliderGlowThreshold:Hide();
				dropdownGlowType:Show();
				areaGlow:SetHeight(80);
			end
			addonTable.UpdateAllNameplates(false);
		end);
		checkboxGlow:SetParent(areaGlow);
		checkboxGlow:SetPoint("TOPLEFT", 10, -10);
		-- VGUI.SetTooltip(checkboxGlow, format(L["options:auras:enabled-state:tooltip"],
			-- addonTable.ColorizeText(L["Disabled"], 1, 1, 1),
			-- addonTable.ColorizeText(L["options:auras:enabled-state-mineonly"], 0, 1, 1),
			-- addonTable.ColorizeText(L["options:auras:enabled-state-all"], 0, 1, 0)));
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

		local minV, maxV = 1, 30;
		sliderGlowThreshold = VGUI.CreateSlider();
		sliderGlowThreshold:SetParent(areaGlow);
		sliderGlowThreshold:SetWidth(140);
		sliderGlowThreshold.label:ClearAllPoints();
		sliderGlowThreshold.label:SetPoint("CENTER", sliderGlowThreshold, "CENTER", 0, 15);
		sliderGlowThreshold.label:SetText();
		sliderGlowThreshold:ClearAllPoints();
		sliderGlowThreshold:SetPoint("TOPRIGHT", areaGlow, "TOPRIGHT", -10, 5);
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
		sliderGlowThreshold.lowtext:SetText("1");
		sliderGlowThreshold.hightext:SetText("30");
		table_insert(controls, sliderGlowThreshold);

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
		areaAnimation:SetWidth(340);
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
				dropdownAnimationType:Hide();
				areaAnimation:SetHeight(40);
			elseif (self:GetTriState() == 1) then
				addonTable.db.CustomSpells2[selectedSpell].animationDisplayMode = addonTable.ICON_ANIMATION_DISPLAY_MODE_THRESHOLD;
				sliderAnimationThreshold:Show();
				dropdownAnimationType:Show();
				sliderAnimationThreshold.slider:SetValue(5);
				areaAnimation:SetHeight(80);
			else
				addonTable.db.CustomSpells2[selectedSpell].animationDisplayMode = addonTable.ICON_ANIMATION_DISPLAY_MODE_ALWAYS;
				sliderAnimationThreshold:Hide();
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

		local minV, maxV = 1, 30;
		sliderAnimationThreshold = VGUI.CreateSlider();
		sliderAnimationThreshold:SetParent(areaAnimation);
		sliderAnimationThreshold:SetWidth(140);
		sliderAnimationThreshold.label:ClearAllPoints();
		sliderAnimationThreshold.label:SetPoint("CENTER", sliderAnimationThreshold, "CENTER", 0, 15);
		sliderAnimationThreshold.label:SetText();
		sliderAnimationThreshold:ClearAllPoints();
		sliderAnimationThreshold:SetPoint("TOPRIGHT", areaAnimation, "TOPRIGHT", -10, 5);
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
		areaIconSize:SetPoint("TOPLEFT", areaAnimation, "BOTTOMLEFT", 170, 0);
		areaIconSize:SetWidth(170);
		areaIconSize:SetHeight(70);
		table_insert(controls, areaIconSize);

	end

	-- // sliderSpellIconSize
	do

		sliderSpellIconSize = VGUI.CreateSlider();
		sliderSpellIconSize:SetParent(areaIconSize);
		sliderSpellIconSize:SetWidth(160);
		sliderSpellIconSize:SetPoint("TOPLEFT", 18, -23);
		sliderSpellIconSize.label:ClearAllPoints();
		sliderSpellIconSize.label:SetPoint("CENTER", sliderSpellIconSize, "CENTER", 0, 15);
		sliderSpellIconSize.label:SetText(L["Icon size"]);
		sliderSpellIconSize:ClearAllPoints();
		sliderSpellIconSize:SetPoint("CENTER", areaIconSize, "CENTER", 0, 0);
		sliderSpellIconSize.slider:ClearAllPoints();
		sliderSpellIconSize.slider:SetPoint("LEFT", 3, 0)
		sliderSpellIconSize.slider:SetPoint("RIGHT", -3, 0)
		sliderSpellIconSize.slider:SetValueStep(1);
		sliderSpellIconSize.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderSpellIconSize.slider:SetScript("OnValueChanged", function(self, value)
			sliderSpellIconSize.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.CustomSpells2[selectedSpell].iconSize = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderSpellIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderSpellIconSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderSpellIconSize.editbox:GetText());
				if (v == nil) then
					sliderSpellIconSize.editbox:SetText(tostring(addonTable.db.CustomSpells2[selectedSpell].iconSize));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
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
		sliderSpellIconSize.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		table_insert(controls, sliderSpellIconSize);

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
		areaAuraType:SetWidth(170);
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
		areaIDs:SetWidth(340);
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

	local interruptOptionsArea, checkBoxInterrupts;

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
		interruptOptionsArea:SetPoint("TOPLEFT", 150, -40);
		interruptOptionsArea:SetWidth(360);
		interruptOptionsArea:SetHeight(140);
		interruptOptionsArea:Hide();

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
		dropdownGlowType:SetPoint("TOPLEFT", interruptOptionsArea, "TOPLEFT", 5, -20);
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

	-- // checkBoxUseSharedIconTexture
	do

		local checkBoxUseSharedIconTexture = VGUI.CreateCheckBox();
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
		checkBoxUseSharedIconTexture:SetPoint("TOPLEFT", 20, -50);
		checkBoxUseSharedIconTexture:Show();
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxUseSharedIconTexture:SetChecked(addonTable.db.InterruptsUseSharedIconTexture);
		end);

	end

	-- // checkBoxEnableOnlyInPvPMode
	do

		local checkBoxEnableOnlyInPvPMode = VGUI.CreateCheckBox();
		checkBoxEnableOnlyInPvPMode:Show();
		checkBoxEnableOnlyInPvPMode:SetText(L["options:interrupts:enable-only-during-pvp-battles"]);
		checkBoxEnableOnlyInPvPMode:SetOnClickHandler(function(this)
			addonTable.db.InterruptsShowOnlyOnPlayers = this:GetChecked();
			addonTable.UpdateAllNameplates(false);
		end);
		checkBoxEnableOnlyInPvPMode:SetChecked(addonTable.db.InterruptsShowOnlyOnPlayers);
		checkBoxEnableOnlyInPvPMode:SetParent(interruptOptionsArea);
		checkBoxEnableOnlyInPvPMode:SetPoint("TOPLEFT", 20, -70);
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			checkBoxEnableOnlyInPvPMode:SetChecked(addonTable.db.InterruptsShowOnlyOnPlayers);
		end);

	end

	-- // sliderInterruptIconSize
	do

		local sliderInterruptIconSize = VGUI.CreateSlider();
		sliderInterruptIconSize:Show();
		sliderInterruptIconSize:SetParent(interruptOptionsArea);
		sliderInterruptIconSize:SetWidth(175);
		sliderInterruptIconSize.label:ClearAllPoints();
		sliderInterruptIconSize.label:SetPoint("TOPLEFT", interruptOptionsArea, "TOPLEFT", 25, -100);
		sliderInterruptIconSize.label:SetText(L["options:interrupts:icon-size"]);
		sliderInterruptIconSize:ClearAllPoints();
		sliderInterruptIconSize:SetPoint("LEFT", sliderInterruptIconSize.label, "RIGHT", 10, 5);
		sliderInterruptIconSize.slider:ClearAllPoints();
		sliderInterruptIconSize.slider:SetPoint("LEFT", 3, 0)
		sliderInterruptIconSize.slider:SetPoint("RIGHT", -3, 0)
		sliderInterruptIconSize.slider:SetValueStep(1);
		sliderInterruptIconSize.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderInterruptIconSize.slider:SetScript("OnValueChanged", function(self, value)
			sliderInterruptIconSize.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.InterruptsIconSize = math_ceil(value);
			addonTable.UpdateAllNameplates(false);
		end);
		sliderInterruptIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderInterruptIconSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderInterruptIconSize.editbox:GetText());
				if (v == nil) then
					sliderInterruptIconSize.editbox:SetText(tostring(addonTable.db.InterruptsIconSize));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
					end
					if (v < 1) then
						v = 1;
					end
					sliderInterruptIconSize.slider:SetValue(v);
				end
				sliderInterruptIconSize.editbox:ClearFocus();
			end
		end);
		sliderInterruptIconSize.lowtext:SetText("1");
		sliderInterruptIconSize.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		sliderInterruptIconSize.slider:SetValue(addonTable.db.InterruptsIconSize);
		sliderInterruptIconSize.editbox:SetText(tostring(addonTable.db.InterruptsIconSize));
		table_insert(GUIFrame.OnDBChangedHandlers, function()
			sliderInterruptIconSize.slider:SetValue(addonTable.db.InterruptsIconSize);
			sliderInterruptIconSize.editbox:SetText(tostring(addonTable.db.InterruptsIconSize));
		end);

	end

end

local function GUICategory_Additions(index, value)
	local checkBoxExplosiveOrbs;

	-- // checkBoxExplosiveOrbs
	do
		checkBoxExplosiveOrbs = VGUI.CreateCheckBox();
		checkBoxExplosiveOrbs:SetText(L["options:apps:explosive-orbs"]);
		checkBoxExplosiveOrbs:SetOnClickHandler(function(this)
			addonTable.db.Additions_ExplosiveOrbs = this:GetChecked();
			if (not addonTable.db.Additions_ExplosiveOrbs) then
				addonTable.UpdateAllNameplates(true);
			end
		end);
		checkBoxExplosiveOrbs:SetChecked(addonTable.db.Additions_ExplosiveOrbs);
		checkBoxExplosiveOrbs:SetParent(GUIFrame);
		checkBoxExplosiveOrbs:SetPoint("TOPLEFT", 160, -20);
		VGUI.SetTooltip(checkBoxExplosiveOrbs, L["options:apps:explosive-orbs:tooltip"]);
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
		sliderIconSize:SetWidth(155);
		sliderIconSize:SetPoint("TOPLEFT", 160, -25);
		sliderIconSize.label:SetText(L["Default icon size"]);
		sliderIconSize.slider:SetValueStep(1);
		sliderIconSize.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderIconSize.slider:SetValue(addonTable.db.DefaultIconSize);
		sliderIconSize.slider:SetScript("OnValueChanged", function(self, value)
			local valueNum = math_ceil(value);
			sliderIconSize.editbox:SetText(tostring(valueNum));
			for _, spellInfo in pairs(addonTable.db.CustomSpells2) do
				if (spellInfo.iconSize == addonTable.db.DefaultIconSize) then
					spellInfo.iconSize = valueNum;
				end
			end
			addonTable.db.DefaultIconSize = valueNum;
			addonTable.UpdateAllNameplates(true);
		end);
		sliderIconSize.editbox:SetText(tostring(addonTable.db.DefaultIconSize));
		sliderIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderIconSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderIconSize.editbox:GetText());
				if (v == nil) then
					sliderIconSize.editbox:SetText(tostring(addonTable.db.DefaultIconSize));
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
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderIconSize.slider:SetValue(addonTable.db.DefaultIconSize); sliderIconSize.editbox:SetText(tostring(addonTable.db.DefaultIconSize)); end);

	end

	-- // sliderIconSpacing
	do
		local minValue, maxValue = 0, 50;
		local sliderIconSpacing = VGUI.CreateSlider();
		sliderIconSpacing:SetParent(GUIFrame);
		sliderIconSpacing:SetWidth(155);
		sliderIconSpacing:SetPoint("TOPLEFT", 345, -25);
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
		sliderIconXOffset:SetWidth(155);
		sliderIconXOffset:SetPoint("TOPLEFT", 160, -85);
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
		sliderIconYOffset:SetWidth(155);
		sliderIconYOffset:SetPoint("TOPLEFT", 345, -85);
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

	-- // dropdownFrameAnchorToNameplate
	do
					
		dropdownFrameAnchorToNameplate = CreateFrame("Frame", "NAuras.GUI.SizeAndPosition.dropdownFrameAnchorToNameplate", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownFrameAnchorToNameplate, 130);
		dropdownFrameAnchorToNameplate:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -150);
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
		UIDropDownMenu_SetWidth(dropdownFrameAnchor, 130);
		dropdownFrameAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 316, -150);
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
		UIDropDownMenu_SetWidth(dropdownIconAnchor, 130);
		dropdownIconAnchor:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -190);
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
		UIDropDownMenu_SetWidth(dropdownIconGrowDirection, 130);
		dropdownIconGrowDirection:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 316, -190);
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
		UIDropDownMenu_SetWidth(dropdownTargetStrata, 300);
		dropdownTargetStrata:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -230);
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
		UIDropDownMenu_SetWidth(dropdownNonTargetStrata, 300);
		dropdownNonTargetStrata:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -270);
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

	-- // dropdownSortMode
	do
		local SortModesLocalization = {
			[AURA_SORT_MODE_NONE] =				L["icon-sort-mode:none"],
			[AURA_SORT_MODE_EXPIRETIME] =		L["icon-sort-mode:by-expire-time"],
			[AURA_SORT_MODE_ICONSIZE] =			L["icon-sort-mode:by-icon-size"],
			[AURA_SORT_MODE_AURATYPE_EXPIRE] =	L["icon-sort-mode:by-aura-type+by-expire-time"],
		};


		local dropdownSortMode = CreateFrame("Frame", "NAuras.GUI.Cat1.DropdownSortMode", GUIFrame, "UIDropDownMenuTemplate");
		UIDropDownMenu_SetWidth(dropdownSortMode, 300);
		dropdownSortMode:SetPoint("TOPLEFT", GUIFrame, "TOPLEFT", 146, -320);
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

	end

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
		scaleArea:SetPoint("TOPLEFT", 150, -360);
		scaleArea:SetWidth(360);
		scaleArea:SetHeight(70);
		table_insert(GUIFrame.Categories[index], scaleArea);

	end

	-- // sliderScaleTarget
	do

		local minValue, maxValue, step = -10, 10, 0.1;
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
		alphaArea:SetWidth(360);
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
	local checkBoxDispellableSpells, dispellableSpellsBlacklist, addButton, editboxAddSpell, dropdownGlowType, controlArea;
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
		controlArea:SetPoint("TOPLEFT", 150, -40);
		controlArea:SetWidth(360);
		controlArea:SetHeight(140);
		controlArea:Hide();
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
		dropdownGlowType:SetPoint("TOP", controlArea, "TOP", 0, -20);
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

	-- // sliderSpellIconSize
	do

		local sliderSpellIconSize = VGUI.CreateSlider();
		sliderSpellIconSize:Show();
		sliderSpellIconSize:SetParent(controlArea);
		sliderSpellIconSize:SetWidth(controlArea:GetWidth() - 10);
		sliderSpellIconSize.label:ClearAllPoints();
		sliderSpellIconSize.label:SetPoint("CENTER", sliderSpellIconSize, "CENTER", 0, 15);
		sliderSpellIconSize.label:SetText(L["Icon size"]);
		sliderSpellIconSize:ClearAllPoints();
		sliderSpellIconSize:SetPoint("TOP", controlArea, "TOP", 0, -50);
		sliderSpellIconSize.slider:ClearAllPoints();
		sliderSpellIconSize.slider:SetPoint("LEFT", 3, 0)
		sliderSpellIconSize.slider:SetPoint("RIGHT", -3, 0)
		sliderSpellIconSize.slider:SetValueStep(1);
		sliderSpellIconSize.slider:SetMinMaxValues(1, addonTable.MAX_AURA_ICON_SIZE);
		sliderSpellIconSize.slider:SetValue(addonTable.db.Additions_DispellableSpells_IconSize);
		sliderSpellIconSize.editbox:SetText(tostring(addonTable.db.Additions_DispellableSpells_IconSize));
		sliderSpellIconSize.slider:SetScript("OnValueChanged", function(self, value)
			sliderSpellIconSize.editbox:SetText(tostring(math_ceil(value)));
			addonTable.db.Additions_DispellableSpells_IconSize = math_ceil(value);
			addonTable.UpdateAllNameplates(true);
		end);
		sliderSpellIconSize.editbox:SetScript("OnEnterPressed", function(self, value)
			if (sliderSpellIconSize.editbox:GetText() ~= "") then
				local v = tonumber(sliderSpellIconSize.editbox:GetText());
				if (v == nil) then
					sliderSpellIconSize.editbox:SetText(tostring(addonTable.db.Additions_DispellableSpells_IconSize));
					Print(L["Value must be a number"]);
				else
					if (v > addonTable.MAX_AURA_ICON_SIZE) then
						v = addonTable.MAX_AURA_ICON_SIZE;
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
		sliderSpellIconSize.hightext:SetText(tostring(addonTable.MAX_AURA_ICON_SIZE));
		table_insert(GUIFrame.OnDBChangedHandlers, function() sliderSpellIconSize.slider:SetValue(addonTable.db.Additions_DispellableSpells_IconSize); end);

	end

	-- // dispellableSpellsBlacklist
	do
		dispellableSpellsBlacklist = VGUI.CreateButton();
		dispellableSpellsBlacklist:SetParent(controlArea);
		dispellableSpellsBlacklist:SetText(L["options:apps:dispellable-spells:black-list-button"]);
		dispellableSpellsBlacklist:SetWidth(controlArea:GetWidth());
		dispellableSpellsBlacklist:SetHeight(24);
		dispellableSpellsBlacklist:SetPoint("TOPLEFT", controlArea, "BOTTOMLEFT", 0, -10);
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
		local text = editboxAddSpell:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		text:SetPoint("LEFT", 0, 0);
		text:SetText(L["Add new spell: "]);
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

	local header = GUIFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	header:SetFont(GameFontNormal:GetFont(), 22, "THICKOUTLINE");
	header:SetPoint("CENTER", GUIFrame, "CENTER", 0, 230);
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

	local closeButton = CreateFrame("Button", "NAuras.GUI.CloseButton", GUIFrame, "UIPanelButtonTemplate");
	closeButton:SetWidth(24);
	closeButton:SetHeight(24);
	closeButton:SetPoint("TOPRIGHT", 0, 22);
	closeButton:SetScript("OnClick", function() GUIFrame:Hide(); end);
	closeButton.text = closeButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	closeButton.text:SetPoint("CENTER", closeButton, "CENTER", 1, -1);
	closeButton.text:SetText("X");

	GUIFrame.Categories = {};
	GUIFrame.OnDBChangedHandlers = {};
	table_insert(GUIFrame.OnDBChangedHandlers, function() OnGUICategoryClick(GUIFrame.CategoryButtons[1]); end);

	local categories = { L["General"], L["Profiles"], L["options:category:size-and-position"], L["options:category:alpha"], L["Timer text"], L["Stack text"],
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
		elseif (value == L["Profiles"]) then
			GUICategory_2(index, value);
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
