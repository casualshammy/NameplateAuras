-- luacheck: no max line length
-- luacheck: globals LibStub WorldFrame format StaticPopup_Show StaticPopupDialogs CreateFrame debugprofilestop UIParent UNKNOWN GetSpellTexture DEFAULT_CHAT_FRAME
-- luacheck: globals OKAY YES NO ReloadUI GetSpellInfo GetPlayerInfoByGUID

local _, addonTable = ...;
local L = LibStub("AceLocale-3.0"):GetLocale("NameplateAuras");
local SML = LibStub("LibSharedMedia-3.0");
SML:Register("font", "NAuras_TeenBold", 		"Interface\\AddOns\\NameplateAuras\\media\\teen_bold.ttf", 255);
SML:Register("font", "NAuras_TexGyreHerosBold", "Interface\\AddOns\\NameplateAuras\\media\\texgyreheros-bold-webfont.ttf", 255);
local _G, pairs, select, WorldFrame, string_format = _G, pairs, select, WorldFrame, format;
local GetSpellTexture, GetSpellInfo, GetPlayerInfoByGUID = GetSpellTexture, GetSpellInfo, GetPlayerInfoByGUID;

addonTable.SpellTextureByID = setmetatable({
	[197690] = GetSpellTexture(71),		-- // override for defensive stance
	[179057] = GetSpellTexture(183591),	-- // override for Chaos Nova
}, {
	__index = function(t, key)
		local texture = GetSpellTexture(key);
		rawset(t, key, texture);
		return texture;
	end
});

addonTable.SpellNameByID = setmetatable({}, {
	__index = function(t, key)
		local spellName = GetSpellInfo(key);
		rawset(t, key, spellName);
		return spellName;
	end
});

addonTable.UnitClassByGUID = setmetatable({}, {
	__index = function(t, key)
		local _, classFilename = GetPlayerInfoByGUID(key);
		rawset(t, key, classFilename);
		return classFilename;
	end
});

function addonTable.Print(...)
	local text = "";
	for i = 1, select("#", ...) do
		text = text..tostring(select(i, ...)).." "
	end
	DEFAULT_CHAT_FRAME:AddMessage(format("NameplateAuras: %s", text), 0, 128, 128);
end

function addonTable.deepcopy(object)
	local lookup_table = {}
	local function _copy(another_object)
		if type(another_object) ~= "table" then
			return another_object;
		elseif lookup_table[another_object] then
			return lookup_table[another_object];
		end
		local new_table = { };
		lookup_table[another_object] = new_table;
		for index, value in pairs(another_object) do
			new_table[_copy(index)] = _copy(value);
		end
		return setmetatable(new_table, getmetatable(another_object));
	end
	return _copy(object);
end

function addonTable.msg(text)
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

function addonTable.msgWithQuestion(text, funcOnAccept, funcOnCancel)
	local frameName = "NAURAS_MSG_QUESTION";
	if (StaticPopupDialogs[frameName] == nil) then
		StaticPopupDialogs[frameName] = {
			button1 = YES,
			button2 = NO,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		};
	end
	StaticPopupDialogs[frameName].text = text;
	StaticPopupDialogs[frameName].OnAccept = funcOnAccept;
	StaticPopupDialogs[frameName].OnCancel = funcOnCancel;
	StaticPopup_Show(frameName);
end

function addonTable.PopupReloadUI()
	if (StaticPopupDialogs["NAURAS_MSG_RELOAD"] == nil) then
		StaticPopupDialogs["NAURAS_MSG_RELOAD"] = {
			text = L["Please reload UI to apply changes"],
			button1 = L["Reload UI"],
			OnAccept = function() ReloadUI(); end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		};
	end
	StaticPopup_Show("NAURAS_MSG_RELOAD");
end

function addonTable.table_contains_value(t, v)
	for _, value in pairs(t) do
		if (value == v) then
			return true;
		end
	end
	return false;
end

function addonTable.table_count(t)
	local count = 0;
	for _ in pairs(t) do
		count = count + 1;
	end
	return count;
end

function addonTable.ColorizeText(text, r, g, b)
	return string_format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, text);
end

-- // CoroutineProcessor
do
	addonTable.CoroutineProcessor = {};
	addonTable.CoroutineProcessor.frame = CreateFrame("frame");
	addonTable.CoroutineProcessor.update = {};
	addonTable.CoroutineProcessor.size = 0;

	function addonTable.CoroutineProcessor.Queue(_, name, func)
		if (not name) then
			name = string_format("NIL%d", addonTable.CoroutineProcessor.size + 1);
		end
		if (not addonTable.CoroutineProcessor.update[name]) then
			addonTable.CoroutineProcessor.update[name] = func;
			addonTable.CoroutineProcessor.size = addonTable.CoroutineProcessor.size + 1;
			addonTable.CoroutineProcessor.frame:Show();
		end
	end

	function addonTable.CoroutineProcessor.DeleteFromQueue(_, name)
		if (addonTable.CoroutineProcessor.update[name]) then
			addonTable.CoroutineProcessor.update[name] = nil;
			addonTable.CoroutineProcessor.size = addonTable.CoroutineProcessor.size - 1;
			if (addonTable.CoroutineProcessor.size == 0) then
				addonTable.CoroutineProcessor.frame:Hide();
			end
		end
	end

	addonTable.CoroutineProcessor.frame:Hide();
	addonTable.CoroutineProcessor.frame:SetScript("OnUpdate", function()
		local start = debugprofilestop();
		local hasData = true;
		while (debugprofilestop() - start < 16 and hasData) do
			hasData = false;
			for name, func in pairs(addonTable.CoroutineProcessor.update) do
				hasData = true;
				if (coroutine.status(func) ~= "dead") then
					assert(coroutine.resume(func));
				else
					addonTable.CoroutineProcessor:DeleteFromQueue(name);
				end
			end
		end
	end);
end

-- // NPC ID
do

	local DatamineTooltip = CreateFrame("GameTooltip", "NameplateAurasDatamineTooltip", UIParent, "GameTooltipTemplate");
	DatamineTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");

	addonTable.NPCNameByID = setmetatable({}, {
		__index = function(t, key)
			DatamineTooltip:SetHyperlink(("unit:Creature-0-0-0-0-%d"):format(key));
			local npcName = _G["NameplateAurasDatamineTooltipTextLeft1"]:GetText();
			if (npcName == "") then npcName = nil; end
			rawset(t, key, npcName);
			return npcName or UNKNOWN;
		end
	});
end