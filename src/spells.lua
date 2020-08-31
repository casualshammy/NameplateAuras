local _, addonTable = ...;
local L = addonTable.L;

-- // utilities
local Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID;
do

	Print, msg, msgWithQuestion, table_count, SpellTextureByID, SpellNameByID, UnitClassByGUID = 
		addonTable.Print, addonTable.msg, addonTable.msgWithQuestion, addonTable.table_count, addonTable.SpellTextureByID, addonTable.SpellNameByID, addonTable.UnitClassByGUID;
	
end

addonTable.Interrupts = {
	[1766] = 5,	-- Kick (Rogue)
	[2139] = 6, 	-- Counterspell (Mage)
	[6552] = 4, 	-- Pummel (Warrior)
	[19647] = 6, 	-- Spell Lock (Warlock)
	[47528] = 3, 	-- Mind Freeze (Death Knight)
	[57994] = 3, 	-- Wind Shear (Shaman)
	[91802] = 2, 	-- Shambling Rush (Death Knight)
	[93985] = 4,	-- Skull Bash (feral+bear, tested)
	[96231] = 4, 	-- Rebuke (Paladin)
	[106839] = 4, 	-- Skull Bash (Feral)
	[115781] = 6, 	-- Optical Blast (Warlock)
	[116705] = 4, 	-- Spear Hand Strike (Monk)
	[132409] = 6, 	-- Spell Lock (Warlock)
	[147362] = 3, 	-- Countershot (Hunter)
	[171138] = 6, 	-- Shadow Lock (Warlock)
	[183752] = 3, 	-- Consume Magic (Demon Hunter)
	[187707] = 3,	-- Muzzle (Hunter)
	[212619] = 6,	-- Call Felhunter (Warlock)
	[231665] = 3,	-- Avengers Shield (Paladin)
	[91802] = 2,	-- Shambling Rush
};

addonTable.TalentsReducingInterruptTime = {
	[GetSpellInfo(221404)] = true, -- // Burning Determination
	[GetSpellInfo(221677)] = true, -- // Calming Waters
	[GetSpellInfo(221660)] = true, -- // Holy Concentration
};

addonTable.MarkerSpellsForRestorationShamansAndShadowPriests = {
	[232698] = true,	-- // Облик Тьмы
	[34914] = true,		-- // Прикосновение вампира
	[15407] = true,		-- // Пытка разума
	[47585] = true,		-- // Слияние с тьмой
	[8092] = true,		-- // Взрыв разума
	[228260] = true,	-- // Извержение бездны
	[79206] = true,		-- // Благосклонность предков
	[61295] = true,		-- // Быстрина
	[77130] = true,		-- // Возрождение духа
	[77472] = true,		-- // Волна исцеления
	[5394] = true,		-- // Тотем исцеляющего потока
	[1064] = true,		-- // Цепное исцеление
};

addonTable.DefaultSpells2 = {
	[1] = {
		[51514] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[51514] }, -- // Hex
		[6358] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[6358] },
		[33786] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[33786] },
		[5782] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[5782] }, 
		[5484] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[5484] }, 
		[45438] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[45438] }, 
		[642] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[642] }, 
		[8122] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[8122] }, 
		[23335] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[23335] }, 
		[23333] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[23333] }, 
		[34976] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[34976] }, 
		[2094] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[2094] }, 
		[33206] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[33206] }, 
		[47585] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[47585] }, 
		[87204] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[87204] },
		[108416] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[108416] }, 
		[104773] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[104773] }, 
		[871] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[871] }, 
		[19263] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[19263] }, 
		[61336] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[61336] }, 
		[31230] =	{ ["enabledState"] = "all", ["auraType"] = "buff",		  ["iconSize"] = 45, ["spellName"] = SpellNameByID[31230] }, 
		[6940] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[6940] }, 
		[31821] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31821] }, 
		[48707] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[48707] }, 
		[108271] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[108271] }, 
		[53480] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[53480] },
		[15286] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[15286] }, 
		[122783] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[122783] }, 
		[122278] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[122278] },
		[115078] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[115078] },
		[125174] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[125174] },
		[88611] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[88611] },
		[221527] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[221527] },
		[31935] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31935] },
		[140023] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[140023] },
		[51271] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[51271] },
		[200108] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[200108] },
		[29166] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[29166] },
		[118] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[118] },
		[122] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[122] },
		[110909] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[110909] },
		[1044] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[1044] },
		[205369] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[205369] },
		[130736] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[130736] },
		[20066] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[20066] },
		[212638] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[212638] },
		[216113] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[216113] },
		[408] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[408] },
		[108839] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[108839] },
		[152173] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[152173] },
		[212640] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[212640] },
		[137639] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[137639] },
		[196098] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[196098] },
		[31661] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31661] },
		[117526] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[117526] },
		[5211] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[5211] },
		[207319] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[207319] },
		[74001] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[74001] },
		[114052] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[114052] },
		[99] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[99] },
		[22812] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[22812] },
		[12472] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[12472] },
		[120954] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[120954] },
		[6770] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[6770] },
		[198589] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[198589] },
		[211881] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[211881] },
		[30283] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[30283] },
		[5246] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[5246] },
		[23920] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[23920] },
		[194223] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[194223] },
		[47481] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[47481] },
		[198144] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[198144] },
		[6789] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[6789] },
		[1833] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[1833] },
		[19386] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[19386] },
		[9484] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[9484] },
		[207167] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[207167] },
		[199804] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[199804] },
		[86659] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[86659] },
		[46924] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[46924] },
		[5277] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[5277] },
		[221703] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[221703] },
		[102342] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[102342] },
		[47482] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[47482] },
		[78675] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[78675] },
		[1776] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[1776] },
		[1330] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[1330] },
		[196555] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[196555] },
		[197862] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[197862] },
		[22570] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[22570] },
		[124974] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[124974] },
		[16166] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[16166] },
		[54216] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[54216] },
		[51690] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[51690] },
		[10060] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[10060] },
		[228049] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[228049] },
		[69369] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[69369] },
		[3045] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[3045] },
		[37506] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[37506] },
		[1719] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[1719] },
		[207810] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[207810] },
		[31850] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31850] },
		[196718] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[196718] },
		[105771] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[105771] },
		[136634] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[136634] },
		[113724] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[113724] },
		[199683] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[199683] },
		[31117] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31117] },
		[108194] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[108194] },
		[105421] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[105421] },
		[132168] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[132168] },
		[194249] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[194249] },
		[186265] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[186265] },
		[102359] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[102359] },
		[209789] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[209789] },
		[33395] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[33395] },
		[31224] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31224] },
		[210918] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[210918] },
		[853] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[853] },
		[118038] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[118038] },
		[116849] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[116849] },
		[118905] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[118905] },
		[121471] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[121471] },
		[135373] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[135373] },
		[224668] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[224668] },
		[710] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[710] },
		[198111] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[198111] },
		[115176] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[115176] },
		[163505] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[163505], ["checkSpellID"] = { [163505] = true } },
		[15487] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[15487] },
		[107574] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[107574] },
		[8178] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[8178] },
		[47476] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[47476] },
		[152151] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[152151] },
		[12042] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[12042] },
		[18499] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[18499] },
		[89766] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[89766] },
		[204150] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[204150] },
		[13750] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[13750] },
		[132169] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[132169] },
		[197871] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[197871] },
		[212295] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[212295] },
		[119381] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[119381] },
		[605] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[605] },
		[339] =		{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[339] },
		[200166] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[200166] },
		[1022] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[1022] },
		[120086] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[120086] },
		[205191] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[205191] },
		[7922] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[7922] },
		[188501] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[188501] },
		[115268] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[115268] },
		[31842] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[31842] },
		[198817] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[198817] },
		[3355] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[3355] },
		[2825] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[2825] },
		[200200] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[200200] },
		[48792] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[48792] },
		[64695] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[64695] },
		[47788] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[47788] },
		[171152] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[171152] },
		[179057] =	{ ["enabledState"] = "all", ["auraType"] = "buff/debuff", ["iconSize"] = 45, ["spellName"] = SpellNameByID[179057] },
	},
	[2] = {
		[236748] = { ["enabledState"] = 2, ["auraType"] = 2, ["iconSize"] = 45, ["spellName"] = SpellNameByID[236748] },
		[235450] = { ["enabledState"] = 2, ["auraType"] = 1, ["iconSize"] = 45, ["spellName"] = SpellNameByID[235450] },
		[235313] = { ["enabledState"] = 2, ["auraType"] = 1, ["iconSize"] = 45, ["spellName"] = SpellNameByID[235313] },
		[236077] = { ["enabledState"] = 2, ["auraType"] = 2, ["iconSize"] = 45, ["spellName"] = SpellNameByID[236077] },
		[236273] = { ["enabledState"] = 2, ["auraType"] = 2, ["iconSize"] = 45, ["spellName"] = SpellNameByID[236273] },
		[236320] = { ["enabledState"] = 2, ["auraType"] = 2, ["iconSize"] = 45, ["spellName"] = SpellNameByID[236320] },
	},
};
