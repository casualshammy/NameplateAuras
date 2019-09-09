-- // enums as variables: it's done for better performance
local _, addonTable = ...;
addonTable.CONST_SPELL_MODE_DISABLED, addonTable.CONST_SPELL_MODE_ALL, addonTable.CONST_SPELL_MODE_MYAURAS = 1, 2, 3;
addonTable.AURA_TYPE_BUFF, addonTable.AURA_TYPE_DEBUFF, addonTable.AURA_TYPE_ANY = 1, 2, 3;
addonTable.AURA_SORT_MODE_NONE, addonTable.AURA_SORT_MODE_EXPIREASC, addonTable.AURA_SORT_MODE_EXPIREDES, addonTable.AURA_SORT_MODE_ICONSIZEASC, addonTable.AURA_SORT_MODE_ICONSIZEDES, addonTable.AURA_SORT_MODE_AURATYPE_EXPIRE = 1, 2, 3, 4, 5, 6;
addonTable.TIMER_STYLE_TEXTURETEXT, addonTable.TIMER_STYLE_CIRCULAR, addonTable.TIMER_STYLE_CIRCULAROMNICC, addonTable.TIMER_STYLE_CIRCULARTEXT = 1, 2, 3, 4;
addonTable.CONST_SPELL_PVP_MODES_UNDEFINED, addonTable.CONST_SPELL_PVP_MODES_INPVPCOMBAT, addonTable.CONST_SPELL_PVP_MODES_NOTINPVPCOMBAT = 1, 2, 3;
addonTable.GLOW_TIME_INFINITE = 30*24*60*60; -- // 30 days
addonTable.EXPLOSIVE_ORB_SPELL_ID = 240446;
addonTable.VERY_LONG_COOLDOWN_DURATION = 30*24*60*60; -- // 30 days
addonTable.MAX_AURA_ICON_SIZE = 75;
addonTable.EXPLOSIVE_ORB_NPC_ID_AS_STRING = "120651";
addonTable.ZUL_NPC1_ID_AS_STRING = "139185"; -- // Прислужник Зула https://ru.wowhead.com/npc=139185
addonTable.ZUL_NPC2_ID_AS_STRING = "139195"; -- // Оживленный гной https://ru.wowhead.com/npc=139195
addonTable.ZUL_NPC1_SPELL_ID = 273432;
addonTable.ZUL_NPC2_SPELL_ID = 273556;
addonTable.BORDER_TEXTURES = {
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-1px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-2px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-3px.tga",
	"Interface\\AddOns\\NameplateAuras\\media\\icon-border-4px.tga", "Interface\\AddOns\\NameplateAuras\\media\\icon-border-5px.tga",
};