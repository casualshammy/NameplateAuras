local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "zhCN");
L = L or {}
--[===[@non-debug@
@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="english", table-name="L")@
--@end-non-debug@]===]
--@debug@
L = L or {}
L["< 1min"] = "小于1分钟"
L["< 5sec"] = "小于5秒钟"
L["> 1min"] = "大于1分钟"
L["Add new spell: "] = "添加新法术:"
L["Add spell"] = "添加法术"
L["All auras"] = "所有光环"
L["Always display icons at full opacity (ReloadUI is required)"] = "始终完全不透明显示图标 (需要重新加载用户界面)"
L["Always show auras cast by myself"] = "始终显示自己释放的光环"
L["Anchor point"] = "锚点"
L["Anchor to icon"] = "锚定到图标"
L["Any"] = "任意"
L["Aura type"] = "光环类型"
L["Border thickness"] = "边框粗细"
L["BOTTOM"] = "底部"
L["BOTTOMLEFT"] = "底部左边"
L["BOTTOMRIGHT"] = "底部右边"
L["Buff"] = "增益"
L["By aura type (de/buff) + expire time"] = "以光环类型 (减/增益) + 过期时间"
L["By expire time, ascending"] = "以过期时间,升序"
L["By expire time, descending"] = "以过期时间,降序"
L["By icon size, ascending"] = "以图标大小,升序"
L["By icon size, descending"] = "以图标大小,降序"
L["CENTER"] = "中心"
L["Check spell ID"] = [=[检查法术ID
(comma-separated)]=]
L["Circular"] = "圆形"
L["Circular with OmniCC support"] = "OmniCC 支持的圆形"
L["Circular with timer"] = "圆形计时器"
L["Click to select spell"] = "单击选择法术"
L["Curse"] = "诅咒"
L["Debuff"] = "减益"
L["Default icon size"] = "默认图标大小"
L["Delete all spells"] = "删除所有法术"
L["Delete spell"] = "删除法术"
L["Disabled"] = "关闭"
L["Disease"] = "疾病"
L["Display auras on nameplates of friendly units"] = "在友方姓名板上显示光环"
L["Display auras on player's nameplate"] = "在玩家姓名板上显示光环"
L["Display tenths of seconds"] = "显示十分之一秒为单位"
L["Do you really want to delete ALL spells?"] = "你真的想要删除所有法术吗?"
L["Font"] = "字体"
L["Font scale"] = "字体缩放"
L["Font size"] = "字体大小"
L["Frame anchor:"] = "框体锚点"
L["General"] = "综合"
L["Hide Blizzard's aura frames (Reload UI is required)"] = "隐藏暴雪的光环框体 (需要重新加载用户界面)"
L["Icon anchor:"] = "图标锚点"
L["Icon borders"] = "图标边框"
L["Icon size"] = "图标大小"
L["Icon X-coord offset"] = "图标横向位移"
L["Icon Y-coord offset"] = "图标纵向位移"
L["LEFT"] = "左边"
L["Magic"] = "魔法"
L["Mode"] = "模式"
L["No"] = "否"
L["None"] = "无"
L["Only my auras"] = "仅我的光环"
L["Open profiles dialog"] = "打开配置文件"
L["Options are not available in combat!"] = "选项在战斗中不可用!"
L["options:apps:explosive-orbs:tooltip"] = [=[在邪能爆炸球的姓名版上方显示一个特殊光环（大秘境易爆词缀）

这个光环将会发亮并且是默认大小]=]
L["options:aura-options:allow-multiple-instances"] = "允许该光环的多情况设定"
--[[Translation missing --]]
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[If this option is checked, you will see all instances of this aura, even on the same nameplate.
Otherwise you will see only one instance of this aura (the longest one)]=]
L["options:auras:add-new-spell:error1"] = [=[你应该输入法术名称而不是法术ID.
如果你想用指定ID监视法术,使用"%s"选项]=]
L["options:auras:enabled-state:tooltip"] = [=[开启/关闭光环

%s：不显示光环
%s：如果是你释放的法术则显示光环
%s：显示全部光环]=]
L["options:auras:enabled-state-all"] = "开启，显示全部光环"
L["options:auras:enabled-state-mineonly"] = "打开,仅显示我的光环"
L["options:auras:pvp-state-dontshowinpvp"] = "在PVP时不显示这个光环"
L["options:auras:pvp-state-indefinite"] = "在PvP战斗中显示此光环"
L["options:auras:pvp-state-onlyduringpvpbattles"] = "仅在PVP时显示这个光环"
L["options:category:apps"] = [=[附加 功能]=]
L["options:category:interrupts"] = "打断"
L["options:general:always-show-my-auras:tooltip"] = "这是最高级的过滤器。如果你开启了这个功能，你的光环显示设置将无视其他过滤器的设置。"
L["options:general:error-omnicc-is-not-loaded"] = "你无法选择这项功能因为OmniCC插件还没有启动！"
--[[Translation missing --]]
L["options:general:show-aura-tooltip"] = "Show aura name when mouse is over auras icon"
L["options:general:use-dim-glow"] = "图标较暗发亮"
L["options:general:use-dim-glow:tooltip"] = "如果选择了这个选项，图标将不会一直持续发亮。（这个功能只针对那些你明确设定图标发亮的技能）"
L["options:interrupts:enable-interrupts"] = "开启打断监视"
L["options:interrupts:enable-only-during-pvp-battles"] = "只在PvP战斗中开启"
L["options:interrupts:glow"] = "图标发亮"
L["options:interrupts:icon-size"] = "图标大小"
L["options:interrupts:use-shared-icon-texture"] = "在打断法术上使用同样的材质"
L["options:selector:search"] = "搜索"
L["options:spells:appropriate-spell-ids"] = "适合的法术ID"
--[[Translation missing --]]
L["options:spells:disable-all-spells"] = "Disable all spells"
--[[Translation missing --]]
L["options:spells:enable-all-spells"] = "Enable all spells"
L["options:spells:icon-glow"] = "发亮显示"
L["options:spells:icon-glow-always"] = "总是显示发亮"
L["options:spells:icon-glow-threshold"] = "当光环的剩余时间小于...的时候发亮显示"
--[[Translation missing --]]
L["options:spells:please-push-once-more"] = "Please push once more"
L["options:spells:show-on-friends:warning0"] = [=[请注意：除非你启动了如下功能，否则你将不会在友方姓名版上看到光环：
<一般设置> --> <显示友方单位姓名版光环>]=]
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "最小显示时间为零点一秒"
L["options:timer-text:scale-font-size"] = [=[缩放字体大小
根据
图标大小]=]
L["options:timer-text:text-color-note"] = "文字的颜色将会随着剩余时间而改变"
L["Other"] = "其他"
L["Please reload UI to apply changes"] = "请重新加载用户界面来应用更改"
L["Poison"] = "毒药"
L["Profiles"] = "配置文件"
L["Reload UI"] = "重新加载用户界面"
L["RIGHT"] = "右边"
L["Show border around buff icons"] = "在增益图标周围显示边框"
L["Show border around debuff icons"] = "在减益图标周围显示边框"
L["Show this aura on nameplates of allies"] = "在盟友的血条上显示这个光环"
L["Show this aura on nameplates of enemies"] = "在敌人的血条上显示这个光环"
L["Sort mode:"] = "排序方式:"
L["Space between icons"] = "图标间距"
L["Spell already exists (%s)"] = " (%s) 已存在"
L["Spell seems to be nonexistent"] = "法术似乎不存在"
L["Spells"] = "法术"
L["Stack text"] = "堆叠文字"
L["Text"] = "文字"
L["Text color"] = "文字颜色"
L["Texture with timer"] = "计时器材质"
L["Timer style:"] = "时间风格:"
L["Timer text"] = "计时器文字"
L["TOP"] = "上方"
L["TOPLEFT"] = "左上方"
L["TOPRIGHT"] = "右上方"
L["Unknown spell: %s"] = "未知法术: %s"
L["Value must be a number"] = "值必须是数字"
L["X offset"] = "横向位移"
L["Y offset"] = "纵向位移"
L["Yes"] = "是"
--@end-debug@