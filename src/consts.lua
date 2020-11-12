-- // enums as variables: it's done for better performance
local _, addonTable = ...;

addonTable.CONST_SPELL_MODE_DISABLED = 1;
addonTable.CONST_SPELL_MODE_ALL = 2;
addonTable.CONST_SPELL_MODE_MYAURAS = 3;

addonTable.AURA_TYPE_BUFF = 1;
addonTable.AURA_TYPE_DEBUFF = 2;
addonTable.AURA_TYPE_ANY = 3;

addonTable.AURA_SORT_MODE_NONE = 1;
addonTable.AURA_SORT_MODE_EXPIRETIME = 2;
addonTable.AURA_SORT_MODE_ICONSIZE = 4;
addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE = 6;
addonTable.AURA_SORT_MODE_CUSTOM = 7;

addonTable.CONST_SPELL_PVP_MODES_UNDEFINED = 1;
addonTable.CONST_SPELL_PVP_MODES_INPVPCOMBAT = 2;
addonTable.CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT = 3;

addonTable.GLOW_TIME_INFINITE = 30*24*60*60; -- // 30 days

addonTable.EXPLOSIVE_ORB_SPELL_ID = 240446;

addonTable.VERY_LONG_COOLDOWN_DURATION = 30*24*60*60; -- // 30 days

addonTable.MAX_AURA_ICON_SIZE = 75;

addonTable.EXPLOSIVE_ORB_NPC_ID_AS_STRING = "120651";

addonTable.BORDER_TEXTURES = {
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-1px.tga",
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-2px.tga",
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-3px.tga",
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-4px.tga",
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-5px.tga",
};

addonTable.GLOW_TYPE_NONE = 1;
addonTable.GLOW_TYPE_ACTIONBUTTON = 2;
addonTable.GLOW_TYPE_AUTOUSE = 3;
addonTable.GLOW_TYPE_PIXEL = 4;
addonTable.GLOW_TYPE_ACTIONBUTTON_DIM = 5;

addonTable.ICON_ALIGN_BOTTOM_LEFT = 1;
addonTable.ICON_ALIGN_TOP_RIGHT = 2;
addonTable.ICON_ALIGN_CENTER = 3;

addonTable.ICON_GROW_DIRECTION_RIGHT = 1;
addonTable.ICON_GROW_DIRECTION_LEFT = 2;
addonTable.ICON_GROW_DIRECTION_UP = 3;
addonTable.ICON_GROW_DIRECTION_DOWN = 4;

addonTable.ICON_ANIMATION_TYPE_ALPHA = 2;

addonTable.ICON_ANIMATION_DISPLAY_MODE_NONE = 1;
addonTable.ICON_ANIMATION_DISPLAY_MODE_ALWAYS = 2;
addonTable.ICON_ANIMATION_DISPLAY_MODE_THRESHOLD = 3;

addonTable.BORDER_TYPE_BUILTIN = 1;
addonTable.BORDER_TYPE_CUSTOM = 2;

addonTable.DR_TEXTURES = {
	["disorient"] = [[Interface\AddOns\NameplateAuras\media\square-violet.tga]],
	["incapacitate"] = [[Interface\AddOns\NameplateAuras\media\square-silver.tga]],
	["silence"] = [[Interface\AddOns\NameplateAuras\media\square-blue.tga]],
	["stun"] = [[Interface\AddOns\NameplateAuras\media\square-orange.tga]],
	["root"] = [[Interface\AddOns\NameplateAuras\media\square-green.tga]],
	["disarm"] = [[Interface\AddOns\NameplateAuras\media\square-yellow.tga]],
	["taunt"] = [[Interface\AddOns\NameplateAuras\media\square-red.tga]],
};
