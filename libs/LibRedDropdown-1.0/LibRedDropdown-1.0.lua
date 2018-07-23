local LIB_NAME = "LibRedDropdown-1.0";
local lib = LibStub:NewLibrary(LIB_NAME, 1);
if (not lib) then return; end -- No upgrade needed

local table_insert, string_find, string_format = table.insert, string.find, string.format;

local function table_contains_value(t, v)
	for _, value in pairs(t) do
		if (value == v) then
			return true;
		end
	end
	return false;
end

function lib.CreateDropdownMenu()
	local selectorEx = CreateFrame("Frame", nil, UIParent);
	selectorEx:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	selectorEx:SetSize(350, 300);
	selectorEx.texture = selectorEx:CreateTexture();
	selectorEx.texture:SetAllPoints(selectorEx);
	selectorEx.texture:SetColorTexture(0, 0, 0, 1);
	
	selectorEx.searchLabel = selectorEx:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	selectorEx.searchLabel:SetPoint("TOPLEFT", 5, -10);
	selectorEx.searchLabel:SetJustifyH("LEFT");
	selectorEx.searchLabel:SetText("Search:"); -- todo:localize
	
	selectorEx.searchBox = CreateFrame("EditBox", nil, selectorEx, "InputBoxTemplate");
	selectorEx.searchBox:SetAutoFocus(false);
	selectorEx.searchBox:SetFontObject(GameFontHighlightSmall);
	selectorEx.searchBox:SetPoint("LEFT", selectorEx.searchLabel, "RIGHT", 10, 0);
	selectorEx.searchBox:SetPoint("RIGHT", selectorEx, "RIGHT", -10, 0);
	selectorEx.searchBox:SetHeight(20);
	selectorEx.searchBox:SetWidth(175);
	selectorEx.searchBox:SetJustifyH("LEFT");
	selectorEx.searchBox:EnableMouse(true);
	selectorEx.searchBox:SetScript("OnEscapePressed", function() selectorEx.searchBox:ClearFocus(); end);
	selectorEx.searchBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText();
		if (text == "") then
			selectorEx:SetList(selectorEx.list);
		else
			local t = { };
			for _, value in pairs(selectorEx.list) do
				if (string_find(value.text:lower(), text:lower())) then
					table_insert(t, value);
				end
			end
			selectorEx:SetList(t, true);
			selectorEx.scrollArea:SetVerticalScroll(0);
		end
	end);
	selectorEx:HookScript("OnHide", function() selectorEx.searchBox:SetText(""); end);
	
	selectorEx.scrollArea = CreateFrame("ScrollFrame", nil, selectorEx, "UIPanelScrollFrameTemplate");
	selectorEx.scrollArea:SetPoint("TOPLEFT", selectorEx, "TOPLEFT", 5, -30);
	selectorEx.scrollArea:SetPoint("BOTTOMRIGHT", selectorEx, "BOTTOMRIGHT", -25, 5);
	selectorEx.scrollArea:Show();
	
	selectorEx.scrollAreaChildFrame = CreateFrame("Frame", nil, selectorEx.scrollArea);
	selectorEx.scrollArea:SetScrollChild(selectorEx.scrollAreaChildFrame);
	selectorEx.scrollAreaChildFrame:SetWidth(288);
	selectorEx.scrollAreaChildFrame:SetHeight(288);
	
	selectorEx.buttons = { };
	selectorEx.list = { };
	
	local function GetButton(s, counter)
		if (s.buttons[counter] == nil) then
			local button = lib.CreateButton();
			button:SetParent(s.scrollAreaChildFrame);
			button.font, button.fontSize, button.fontFlags = button.Text:GetFont();
			button:SetWidth(295);
			button:SetHeight(20);
			button:SetPoint("TOPLEFT", 23, -counter * 22 + 20);
			button.Icon = button:CreateTexture();
			button.Icon:SetPoint("RIGHT", button, "LEFT", -3, 0);
			button.Icon:SetWidth(20);
			button.Icon:SetHeight(20);
			button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
			button:Hide();
			s.buttons[counter] = button;
			return button;
		else
			return s.buttons[counter];
		end
	end
	
	-- value.text, value.font, value.icon, value.func, value.onEnter, value.onLeave, value.disabled, value.dontCloseOnClick
	selectorEx.SetList = function(s, t, dontUpdateInternalList)
		for _, button in pairs(s.buttons) do
			button:SetGray(false);
			button:Hide();
			button.Icon:SetTexture();
			button.Text:SetFont(button.font, button.fontSize, button.fontFlags);
			button.Text:SetText(); -- not tested
			button:SetScript("OnClick", nil);
		end
		local counter = 1;
		for _, value in pairs(t) do
			local button = GetButton(s, counter);
			button.Text:SetText(value.text);
			if (value.font ~= nil) then
				button.Text:SetFont(value.font, button.fontSize, button.fontFlags);
			end
			if (value.disabled) then
				button:SetGray(true);
			end
			button.Icon:SetTexture(value.icon);
			button:SetScript("OnClick", function()
				value:func();
				if (not value.dontCloseOnClick) then
					s:Hide();
				end
			end);
			button:SetScript("OnEnter", value.onEnter);
			button:SetScript("OnLeave", value.onLeave);
			button:Show();
			counter = counter + 1;
		end
		if (not dontUpdateInternalList) then
			s.list = t;
		end
	end
	
	selectorEx.GetButtonByText = function(s, text)
		for _, button in pairs(s.buttons) do
			if (button.Text:GetText() == text) then
				return button;
			end
		end
		return nil;
	end
	
	selectorEx:SetList({});
	selectorEx:Hide();
	selectorEx:HookScript("OnShow", function(self) self:SetFrameStrata("TOOLTIP"); self.scrollArea:SetVerticalScroll(0); end);
	
	return selectorEx;
end

function lib.SetTooltip(frame, text)
	frame:HookScript("OnEnter", function(self, ...)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
		GameTooltip:SetText(text);
		GameTooltip:Show();
	end);
	frame:HookScript("OnLeave", function(self, ...)
		GameTooltip:Hide();
	end);
end

function lib.CreateCheckBox()
	local checkBox = CreateFrame("CheckButton");
	checkBox:SetHeight(20);
	checkBox:SetWidth(20);
	checkBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	checkBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	checkBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
	checkBox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
	checkBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
	checkBox.textFrame = CreateFrame("frame", nil, checkBox);
	checkBox.textFrame:SetPoint("LEFT", checkBox, "RIGHT", 0, 0);
	checkBox.textFrame:EnableMouse(true);
	checkBox.textFrame:HookScript("OnEnter", function(self, ...) checkBox:LockHighlight(); end);
	checkBox.textFrame:HookScript("OnLeave", function(self, ...) checkBox:UnlockHighlight(); end);
	checkBox.textFrame:Show();
	checkBox.textFrame:HookScript("OnMouseDown", function(self) checkBox:SetButtonState("PUSHED"); end);
	checkBox.textFrame:HookScript("OnMouseUp", function(self) checkBox:SetButtonState("NORMAL"); checkBox:Click(); end);
	checkBox.Text = checkBox.textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	checkBox.Text:SetPoint("LEFT", 0, 0);
	checkBox.SetText = function(self, _text)
		self.Text:SetText(_text);
		self.textFrame:SetWidth(self.Text:GetStringWidth() + self:GetWidth());
		self.textFrame:SetHeight(max(self.Text:GetStringHeight(), self:GetHeight()));
	end;
	checkBox.GetText = function(self)
		return self.Text:GetText();
	end
	checkBox.GetTextObject = function(self)
		return self.Text;
	end
	checkBox.SetOnClickHandler = function(self, func)
		self:SetScript("OnClick", func);
	end
	local handlersToBeCopied = { "OnEnter", "OnLeave" };
	hooksecurefunc(checkBox, "HookScript", function(self, script, proc) if (table_contains_value(handlersToBeCopied, script)) then checkBox.textFrame:HookScript(script, proc); end end);
	hooksecurefunc(checkBox, "SetScript",  function(self, script, proc) if (table_contains_value(handlersToBeCopied, script)) then checkBox.textFrame:SetScript(script, proc); end end);
	checkBox:EnableMouse(true);
	checkBox:Hide();
	return checkBox;
end

function lib.CreateCheckBoxTristate()
	local checkButton = lib.CreateCheckBox();
	checkButton.state = 0;
	checkButton.textEntries = { };
	checkButton.SetTriState = function(self, tristate)
		if (type(tristate) ~= "number" or tristate < 0 or tristate > 2) then error(string_format("%s -> TriStateCheckbox -> SetTriState: tristate must be either 0, 1 or 2", LIB_NAME)); end
		self:SetText(self.textEntries[tristate+1] .. " |TInterface\\common\\help-i:26:26:0:0|t");
		self:SetChecked(tristate == 1 or tristate == 2);
		self.state = tristate;
	end;
	checkButton.SetTextEntries = function(self, textEntries)
		self.textEntries = textEntries;
		self:SetText(self.textEntries[self.state+1] .. " |TInterface\\common\\help-i:26:26:0:0|t");
	end;
	checkButton.GetTriState = function(self)
		return self.state;
	end;
	checkButton.SetOnClickHandler = function(self, _func)
		self:SetScript("OnClick", function(_self)
			local newState = _self:GetTriState() + 1;
			if (newState > 2) then newState = 0; end
			_self:SetTriState(newState);
			_func(_self);
		end);
	end;
	return checkButton;
end

function lib.CreateColorPicker()
	local colorButton = CreateFrame("Button");
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
	colorButton.GetTextObject = function(self)
		return self.text;
	end
	colorButton.SetText = function(self, text)
		self.text:SetText(text);
	end
	colorButton.GetText = function(self)
		return self.text:GetText();
	end
	colorButton.SetColor = function(self, r, g, b)
		self.colorSwatch:SetVertexColor(r, g, b);
		lib.SetTooltip(self, string_format("R: %d, G: %d, B: %d", r, g, b));
	end
	colorButton.GetColor = function(self)
		local r, g, b = self.colorSwatch:GetVertexColor();
		return r, g, b;
	end
	return colorButton;
end

function lib.CreateCheckBoxWithColorPicker()
	local checkBox = lib.CreateCheckBox();
	checkBox.textFrame:ClearAllPoints();
	checkBox.textFrame:SetPoint("LEFT", checkBox, "RIGHT", 20, 0);
	checkBox.ColorButton = lib.CreateColorPicker();
	checkBox.ColorButton:SetParent(checkBox);
	checkBox.ColorButton:SetPoint("LEFT", 19, 0);
	checkBox.ColorButton:Show();
	checkBox.SetColor = checkBox.ColorButton.SetColor;
	checkBox.GetColor = checkBox.ColorButton.GetColor;
	return checkBox;
end

function lib.CreateSlider()
	local frame = CreateFrame("Frame");
	frame:SetHeight(100);
	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	frame.label:SetPoint("TOPLEFT");
	frame.label:SetPoint("TOPRIGHT");
	frame.label:SetJustifyH("CENTER");
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
	
	frame.GetTextObject = function(self) return self.label; end
	frame.GetBaseSliderObject = function(self) return self.slider; end
	frame.GetEditboxObject = function(self) return self.editbox; end
	frame.GetLowTextObject = function(self) return self.lowtext; end
	frame.GetHighTextObject = function(self) return self.hightext; end
	
	return frame;
end

function lib.CreateButton()
	local button = CreateFrame("Button");
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
	button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	button.Text:SetPoint("CENTER", 0, 0);
	button.Text:SetJustifyH("CENTER");
	button.Text:SetTextColor(1, 0.82, 0, 1);
	button:SetScript("OnMouseDown", function(self) self.Text:SetPoint("CENTER", 1, -1) end);
	button:SetScript("OnMouseUp", function(self) self.Text:SetPoint("CENTER", 0, 0) end);
	
	button.SetGray = function(self, gray)
		self.Normal:SetColorTexture(unpack(gray and {0, 0, 0, 1} or {0.38, 0, 0, 1}));
		self.grayed = gray;
	end
	
	button.IsGrayed = function(self)
		return self.grayed == true;
	end
	
	button.SetText = function(self, text)
		self.Text:SetText(text);
	end
	
	button.GetText = function(self)
		return self.Text:GetText();
	end
	
	button.GetTextObject = function(self)
		return self.Text;
	end
	
	return button;
end

function lib.CreateDebugWindow()
	local popup = CreateFrame("EditBox", nil, UIParent);
	popup:SetFrameStrata("DIALOG");
	popup:SetMultiLine(true);
	popup:SetAutoFocus(true);
	popup:SetFontObject(ChatFontNormal);
	popup:SetSize(450, 300);
	popup:Hide();
	popup.orig_Hide = popup.Hide;
	popup.orig_Show = popup.Show;
	
	popup.Hide = function(self)
		self:SetText("");
		self.ScrollFrame:Hide();
		self.Background:Hide();
		self:orig_Hide();
	end
	
	popup.Show = function(self)
		self.ScrollFrame:Show();
		self.Background:Show();
		self:orig_Show();
	end
	
	popup.AddText = function(self, v)
		if not v then return end
		local m = self:GetText();
		if (m ~= "") then
			m = m.."\n";
		end
		self:SetText(m..v);
	end

	popup:SetScript("OnEscapePressed", function(self)
		self:ClearFocus();
		self:Hide();
		self.ScrollFrame:Hide();
		self.Background:Hide();
	end);

	local s = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate");
	s:SetFrameStrata("DIALOG");
	s:SetSize(450, 300);
	s:SetPoint("CENTER");
	s:SetScrollChild(popup);
	s:Hide();

	s:SetScript("OnMouseDown",function(self)
		self:GetScrollChild():SetFocus();
	end);

	local bg = CreateFrame("Frame",nil,UIParent)
	bg:SetFrameStrata("DIALOG")
	bg:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	bg:SetBackdropColor(.05,.05,.05,.8)
	bg:SetBackdropBorderColor(.5,.5,.5)
	bg:SetPoint("TOPLEFT",s,-10,10)
	bg:SetPoint("BOTTOMRIGHT",s,30,-10)
	bg:Hide()

	popup.ScrollFrame = s;
	popup.Background = bg;
		
	return popup;
end
