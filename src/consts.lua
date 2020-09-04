-- // enums as variables: it's done for better performance
local _, addonTable = ...;
addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_ALL, addonTable.CONST_SPELL_MODE_MYAURAS = 1, 2, 3;
addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY = 1, 2, 3;
addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIRETIME, addonTable.AURA_SORT_MODE_ICONSIZE, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE = 1, 2, 4, 6;
addonTable.CONST_SPELL_PVP_MODES_UNDEFINED, addonTable.CONST_SPELL_PVP_MODES_INPVPCOMBAT, addonTable.CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT = 1, 2, 3;
addonTable.GLOW_TIME_INFINITE = 30*24*60*60; -- // 30 days
addonTable.EXPLOSIVE_ORB_SPELL_ID = 240446;
addonTable.VERY_LONG_COOLDOWN_DURATION = 30*24*60*60; -- // 30 days
addonTable.MAX_AURA_ICON_SIZE = 75;
addonTable.EXPLOSIVE_ORB_NPC_ID_AS_STRING = "120651";
addonTable.BORDER_TEXTURES = {
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-1px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-2px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-3px.tga",
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-4px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-5px.tga",
};
addonTable.GLOW_TYPE_NONE, addonTable.GLOW_TYPE_ACTIONBUTTON, addonTable.GLOW_TYPE_AUTOUSE, addonTable.GLOW_TYPE_PIXEL, addonTable.GLOW_TYPE_ACTIONBUTTON_DIM = 1, 2, 3, 4, 5;
addonTable.ICON_ALIGN_BOTTOM_LEFT, addonTable.ICON_ALIGN_TOP_RIGHT, addonTable.ICON_ALIGN_CENTER = 1, 2, 3;
addonTable.ICON_GROW_DIRECTION_RIGHT, addonTable.ICON_GROW_DIRECTION_LEFT, addonTable.ICON_GROW_DIRECTION_UP, addonTable.ICON_GROW_DIRECTION_DOWN = 1, 2, 3, 4;