local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "ruRU");
L = L or {}
--[===[@non-debug@
@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="english", table-name="L")@
--@end-non-debug@]===]
--@debug@
L = L or {}
L["< 1min"] = "< 1мин"
L["< 5sec"] = "< 5сек"
L["> 1min"] = "> 1мин"
L["Add new spell: "] = "Добавить новое заклинание: "
L["Add spell"] = "Добавить"
L["All auras"] = "Все ауры"
L["Always display icons at full opacity (ReloadUI is required)"] = "Иконки всегда непрозрачны (требуется рестарт UI)"
L["Always show auras cast by myself"] = "Всегда отображать мои ауры"
L["Anchor point"] = "Точка привязки"
L["Anchor to icon"] = "Точка привязки к иконке"
L["Any"] = "Любой"
L["Aura type"] = "Тип ауры"
L["Border thickness"] = "Толщина границы"
L["BOTTOM"] = "Снизу"
L["BOTTOMLEFT"] = "Снизу слева"
L["BOTTOMRIGHT"] = "Снизу справа"
L["Buff"] = "Бафф"
L["By aura type (de/buff) + expire time"] = "По типу ауры (де/бафф) + по оставшемуся времени"
L["By expire time, ascending"] = "По оставшемуся времени, по возрастанию"
L["By expire time, descending"] = "По оставшемуся времени, по убыванию"
L["By icon size, ascending"] = "По размеру иконки, по возрастанию"
L["By icon size, descending"] = "По размеру иконки, по убыванию"
L["CENTER"] = "В центре"
L["Check spell ID"] = [=[Проверять ID'ы заклинания
(через запятую)]=]
L["Circular"] = "Круговой"
L["Circular with OmniCC support"] = "Круговой с поддержкой OmniCC"
L["Circular with timer"] = "Круговой с таймером"
L["Click to select spell"] = "Нажмите чтобы выбрать заклинание"
L["Curse"] = "Проклятье"
L["Debuff"] = "Дебафф"
L["Default icon size"] = "Размер иконок по умолчанию"
L["Delete all spells"] = "Удалить все заклинания"
L["Delete spell"] = "Удалить заклинание"
L["Disabled"] = "Отключено"
L["Disease"] = "Болезнь"
L["Display auras on nameplates of friendly units"] = "Отображать ауры на нэймплэйтах союзников"
L["Display auras on player's nameplate"] = "Отображать ауры на вашем нэймплэйте"
L["Display tenths of seconds"] = "Отображать десятые доли секунд на таймерах"
L["Do you really want to delete ALL spells?"] = "Вы действительно хотите удалить ВСЕ заклинания?"
L["Font"] = "Шрифт"
L["Font scale"] = "Масштаб шрифта"
L["Font size"] = "Размер шрифта"
L["Frame anchor:"] = "Якорь для фрейма:"
L["General"] = "Общее"
L["options:general:hide-blizz-frames"] = "Прятать фреймы аур Blizzard (кроме игрока)"
L["options:general:hide-player-blizz-frame"] = "Прятать фреймы аур Blizzard на игроке"
L["Icon anchor:"] = "Якорь для иконок:"
L["Icon borders"] = "Границы иконок"
L["Icon size"] = "Размер иконки"
L["Icon X-coord offset"] = "Смещение иконок по X"
L["Icon Y-coord offset"] = "Смещение иконок по Y"
L["LEFT"] = "Слева"
L["Magic"] = "Магия"
L["Mode"] = "Режим"
L["No"] = "Нет"
L["None"] = "Без сортировки"
L["Only my auras"] = "Только мои ауры"
L["Open profiles dialog"] = "Открыть окно профилей"
L["Options are not available in combat!"] = "Настройки недоступны в бою!"
L["options:apps:explosive-orbs:tooltip"] = [=[Показывать специальную иконку над неймлэйтами Взрывных Сфер (М+ Взрывной)
Эта иконка будет иметь размер по умолчанию и будет подсвечена]=]
L["options:aura-options:allow-multiple-instances"] = "Отображать все экземпляры этой ауры"
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[Если эта опция включена, вы будете видеть все экземпляры этой ауры,
даже на одной полоске здоровья. В другом случае вы будете видеть
только один экземпляр ауры (самый длительный)]=]
L["options:auras:add-new-spell:error1"] = [=[Следует вводить имя заклинания, а не его ID.
Используйте опцию "%s", если вы хотите отслеживать заклинание с определенным ID]=]
L["options:auras:enabled-state:tooltip"] = [=[Включить/отключить ауру

%s: аура не будет показываться
%s: аура будет показываться только если вы применили ее
%s: показывать все ауры]=]
L["options:auras:enabled-state-all"] = "Включено, показывать все ауры"
L["options:auras:enabled-state-mineonly"] = "Включено, показывать только мои ауры"
L["options:auras:pvp-state-dontshowinpvp"] = "Не отображать эту ауру в PvP битвах"
L["options:auras:pvp-state-indefinite"] = "Отображать эту ауру в PvP битвах"
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Отображать эту ауру только в PvP битвах"
L["options:category:apps"] = "Дополнения"
L["options:category:interrupts"] = "Прерывания"
L["options:general:always-show-my-auras:tooltip"] = [=[Это высший по приоритету фильтр. Если он включен, ваши ауры
будут отображаться вне зависимости от других фильтров]=]
L["options:general:error-omnicc-is-not-loaded"] = "Вы не можете выбрать эту опцию, потому что OmniCC не загружен!"
L["options:general:show-aura-tooltip"] = "Показывать имя ауры при наведении мышью на иконку"
L["options:general:use-dim-glow"] = "Слабое свечение иконок"
L["options:general:use-dim-glow:tooltip"] = [=[Если эта опция включена, вы не увидите постоянного внутреннего и внешнего свечения значков
(эта опция работает только для тех заклинаний, для которых вы явно включили подсветку иконки)]=]
L["options:interrupts:enable-interrupts"] = "Включить отслеживание прерываний"
L["options:interrupts:enable-only-during-pvp-battles"] = "Активно только в PvP"
L["options:interrupts:glow"] = "Подсветка иконки"
L["options:interrupts:icon-size"] = "Размер иконки"
L["options:interrupts:use-shared-icon-texture"] = "Использовать одну текстуру для всех прерываний"
L["options:selector:search"] = "Поиск:"
L["options:spells:appropriate-spell-ids"] = "Соответствующие ID'ы заклинаний:"
L["options:spells:disable-all-spells"] = "Отключить все ауры"
L["options:spells:icon-glow"] = "Подсветка иконки"
L["options:spells:icon-glow-always"] = "Показывать свечение постоянно"
L["options:spells:icon-glow-threshold"] = "Показывать свечение если таймер меньше чем"
L["options:spells:please-push-once-more"] = "Пожалуйста, нажмите еще раз"
L["options:spells:show-on-friends:warning0"] = [=[Пожалуйста, обратите внимание:
Вы не увидите эту ауру на нэймплэйтах союзников, пока не включите эту опцию: <Общее> --> <Отображать ауры на нэймплэйтах союзников>]=]
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Минимальная длительность для отображения десятых долей секунд"
L["options:timer-text:scale-font-size"] = [=[Масштабировать
размер текста в
зависимости от
размера иконки]=]
L["options:timer-text:text-color-note"] = [=[Цвет текста будет изменяться
в зависимости от оставшегося времени:]=]
L["Other"] = "Другое"
L["Please reload UI to apply changes"] = "Для принятия изменений необходима перезагрузка интерфейса"
L["Poison"] = "Яд"
L["Profiles"] = "Профили"
L["Reload UI"] = "Перезагрузить UI"
L["RIGHT"] = "Справа"
L["Show border around buff icons"] = "Показывать границу у иконок баффов"
L["Show border around debuff icons"] = "Показывать границу у иконок дебаффов"
L["Show this aura on nameplates of allies"] = "Показывать эту ауру на нэймплэйтах союзников"
L["Show this aura on nameplates of enemies"] = "Показывать эту ауру на нэймплэйтах противников"
L["Sort mode:"] = "Режим сортировки:"
L["Space between icons"] = "Расстояние между иконками"
L["Spell already exists (%s)"] = "Заклинание уже добавлено (%s)"
L["Spell seems to be nonexistent"] = "Заклинание не существует"
L["Spells"] = "Заклинания"
L["Stack text"] = "Текст стэков"
L["Text"] = "Текст"
L["Text color"] = "Цвет текста"
L["Texture with timer"] = "Текстура с таймером"
L["Timer style:"] = "Вид таймера:"
L["Timer text"] = "Текст таймера"
L["TOP"] = "Сверху"
L["TOPLEFT"] = "Сверху слева"
L["TOPRIGHT"] = "Сверху справа"
L["Unknown spell: %s"] = "Неизвестное заклинание: %s"
L["Value must be a number"] = "Значение должно быть числом"
L["X offset"] = "Смещение по X"
L["Y offset"] = "Смещение по Y"
L["Yes"] = "Да"
L["options:general:test-mode"] = "Тестовый режим вкл/выкл";
L["options:category:size-and-position"] = "Размер и место";
L["options:apps:dispellable-spells"] = "Показывать ауры, которые можно развеять/украсть";
L["options:apps:dispellable-spells:tooltip"] = [=[Показывать ауры, которые можно развеять/украсть, на неймплейтах врагов
Эти ауры будут иметь тусклое свечение и размер по умолчанию]=]
L["options:apps:dispellable-spells:black-list-button"] = "Открыть чёрный список";
L["options:category:dispel"] = "Purge/steal";

--@end-debug@