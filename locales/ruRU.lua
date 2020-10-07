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
L["options:spells:add-new-spell"] = "Нажмите, чтобы добавить новое заклинание"
L["Add spell"] = "Добавить"
L["options:general:full-opacity-always"] = "Иконки всегда полностью непрозрачны"
L["Always show auras cast by myself"] = "Всегда отображать мои ауры"
L["Anchor point"] = "Точка привязки"
L["Anchor to icon"] = "Точка привязки к иконке"
L["Any"] = "Любой"
L["Aura type"] = "Тип ауры"
L["Border thickness"] = "Толщина границы"
L["Buff"] = "Бафф"
L["Check spell ID"] = [=[Проверять ID'ы заклинания
(через запятую)]=]
L["Click to select spell"] = "Нажмите чтобы выбрать заклинание"
L["Curse"] = "Проклятье"
L["Debuff"] = "Дебафф"
L["Delete all spells"] = "Удалить все заклинания"
L["Delete spell"] = "Удалить заклинание"
L["Disabled"] = "Отключено"
L["Disease"] = "Болезнь"
L["Display auras on nameplates of friendly units"] = "Отображать ауры на нэймплэйтах союзников"
L["Display auras on player's nameplate"] = "Отображать ауры на вашем нэймплэйте"
L["Do you really want to delete ALL spells?"] = "Вы действительно хотите удалить ВСЕ заклинания?"
L["Font"] = "Шрифт"
L["Font scale"] = "Масштаб шрифта"
L["Font size"] = "Размер шрифта"
L["General"] = "Общее"
L["options:general:hide-blizz-frames"] = "Прятать фреймы аур Blizzard (кроме игрока)"
L["options:general:hide-player-blizz-frame"] = "Прятать фреймы аур Blizzard на игроке"
L["Icon borders"] = "Границы иконок"
L["Icon X-coord offset"] = "Смещение иконок по X"
L["Icon Y-coord offset"] = "Смещение иконок по Y"
L["Magic"] = "Магия"
L["Options are not available in combat!"] = "Настройки недоступны в бою!"
L["options:apps:explosive-orbs:tooltip"] = [=[Показывать специальную иконку над неймлэйтами Взрывных Сфер (М+ Взрывной)
Эта иконка будет иметь размер по умолчанию и будет подсвечена]=]
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
L["options:general:show-aura-tooltip"] = "Показывать имя ауры при наведении мышью на иконку"
L["options:interrupts:enable-interrupts"] = "Включить отслеживание прерываний"
L["options:interrupts:enable-only-during-pvp-battles"] = "Активно только в PvP"
L["options:interrupts:use-shared-icon-texture"] = "Использовать одну текстуру для всех прерываний"
L["options:spells:appropriate-spell-ids"] = "Соответствующие ID'ы заклинаний:"
L["options:spells:disable-all-spells"] = "Отключить все ауры"
L["options:spells:icon-glow"] = "Подсветка иконки"
L["options:spells:icon-glow-always"] = "Показывать свечение постоянно"
L["options:spells:icon-glow-threshold"] = "Показывать свечение если таймер меньше чем"
L["options:spells:please-push-once-more"] = "Пожалуйста, нажмите еще раз"
L["options:spells:show-on-friends:warning0"] = [=[Пожалуйста, обратите внимание:
Вы не увидите эту ауру на нэймплэйтах союзников, пока не включите эту опцию: <Общее> --> <Отображать ауры на нэймплэйтах союзников>]=]
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Минимальная длительность для отображения десятых долей секунд"
L["options:timer-text:scale-font-size"] = "Масштабировать размер текста в зависимости от размера иконки"
L["options:timer-text:text-color-note"] = [=[Цвет текста будет изменяться
в зависимости от оставшегося времени:]=]
L["Other"] = "Другое"
L["Please reload UI to apply changes"] = "Для принятия изменений необходима перезагрузка интерфейса"
L["Poison"] = "Яд"
L["Profiles"] = "Профили"
L["Reload UI"] = "Перезагрузить UI"
L["Show border around buff icons"] = "Показывать границу у иконок баффов"
L["Show border around debuff icons"] = "Показывать границу у иконок дебаффов"
L["Show this aura on nameplates of allies"] = "Показывать эту ауру на нэймплэйтах союзников"
L["Show this aura on nameplates of enemies"] = "Показывать эту ауру на нэймплэйтах противников"
L["Sort mode:"] = "Режим сортировки:"
L["Space between icons"] = "Расстояние между иконками"
L["Spell seems to be nonexistent"] = "Заклинание не существует"
L["Spells"] = "Заклинания"
L["Stack text"] = "Текст стэков"
L["Text color"] = "Цвет текста"
L["Timer text"] = "Текст таймера"
L["Value must be a number"] = "Значение должно быть числом"
L["X offset"] = "Смещение по X"
L["Y offset"] = "Смещение по Y"
L["options:general:test-mode"] = "Тестовый режим";
L["options:category:size-and-position"] = "Размер и место";
L["options:apps:dispellable-spells"] = "Показывать ауры, которые можно развеять/украсть";
L["options:apps:dispellable-spells:tooltip"] = [=[Показывать ауры, которые можно развеять/украсть, на неймплейтах врагов
Эти ауры будут иметь тусклое свечение и размер по умолчанию]=]
L["options:apps:dispellable-spells:black-list-button"] = "Открыть чёрный список";
L["options:category:dispel"] = "Purge/steal";
L["options:glow-type"] = "Тип свечения";
L["options:glow-type:GLOW_TYPE_NONE"] = "Нет свечения";
L["options:glow-type:GLOW_TYPE_ACTIONBUTTON"] = "Кнопка действия";
L["options:glow-type:GLOW_TYPE_AUTOUSE"] = "Кнопка при автоиспользовании";
L["options:glow-type:GLOW_TYPE_PIXEL"] = "Пиксельное";
L["options:glow-type:GLOW_TYPE_ACTIONBUTTON_DIM"] = "Кнопка действия (тусклый)";
L["options:size-and-position:anchor-point-to-nameplate"] = "Точка крепления к ХП бару";
L["options:size-and-position:anchor-point-of-frame"] = "Точка крепления к группе иконок";
L["options:size-and-position:anchor-point-of-frame:tooltip"] = [['Группа иконок' - это коллекция иконок для каждой полоски ХП]];
L["options:size-and-position:icon-align"] = "Выравнивание иконок";
L["options:general:icon-grow-direction"] = "Направление роста иконок";
L["options:size-and-position:icon-align:bottom-left"] = "Горизонтально: вниз / Вертикально: влево";
L["options:size-and-position:icon-align:top-right"] = "Горизонтально: вверх / Вертикально: вправо";
L["options:size-and-position:icon-align:center"] = "Центр";
L["icon-grow-direction:right"] = "Направо";
L["icon-grow-direction:left"] = "Налево";
L["icon-grow-direction:up"] = "Вверх";
L["icon-grow-direction:down"] = "Вниз";
L["anchor-point:topright"] = "Сверху справа";
L["anchor-point:right"] = "Справа";
L["anchor-point:bottomright"] = "Снизу справа";
L["anchor-point:top"] = "Сверху";
L["anchor-point:center"] = "Центр";
L["anchor-point:bottom"] = "Снизу";
L["anchor-point:topleft"] = "Сверху слева";
L["anchor-point:left"] = "Слева";
L["anchor-point:bottomleft"] = "Снизу слева";
L["icon-sort-mode:none"] = "Без сортировки";
L["icon-sort-mode:by-expire-time"] = "По оставшемуся времени";
L["icon-sort-mode:by-icon-size"] = "По размеру иконки";
L["icon-sort-mode:by-aura-type+by-expire-time"] = "По типу ауры + по оставшемуся времени";
L["options:general:show-cooldown-animation"] = "Показывать анимацию кулдауна";
L["options:alpha:alpha"] = "Прозрачность иконок (исключая те, что на полоске ХП вашей цели)";
L["options:alpha:alpha-target"] = "Прозрачность иконок на полоске ХП вашей цели";
L["options:size-and-position:scale-target"] = "Масштаб иконок на полоске ХП вашей цели";
L["options:category:alpha"] = "Прозрачность";
L["options:spells:enable-all-spells"] = "Включить все ауры"
L["options:general:show-cooldown-text"] = "Показывать оставшееся время ауры";
L["options:general:show-stacks"] = "Показывать стаки ауры"
L["options:spells:icon-animation"] = "Анимация иконки";
L["options:spells:icon-animation-threshold"] = "Показывать анимацию если таймер меньше чем";
L["options:spells:icon-animation-always"] = "Показывать анимацию всё время";
L["options:spells:animation-type"] = "Тип анимации";
L["options:animation-type:ICON_ANIMATION_TYPE_ALPHA"] = "Прозрачность";
L["options:animation-type:ICON_ANIMATION_TYPE_SCALE"] = "Масштаб";

L["options:size-and-position:target-strata"] = "Слой иконок на неймплейте цели"
L["options:size-and-position:non-target-strata"] = "Слой иконок на остальных неймплейтах"
L["options:borders:border-file-path"] = "Путь до файла текстуры границы (начинается с 'Interface\\')";
L["options:borders:border-type"] = "Тип границы";
L["options:borders:BORDER_TYPE_BUILTIN"] = "Встроенный";
L["options:borders:BORDER_TYPE_CUSTOM"] = "Пользовательский";
L["options:size-and-position:icon-width"] = "Ширина иконок (по умолчанию)";
L["options:size-and-position:icon-height"] = "Высота иконок (по умолчанию)";
L["options:spells:icon-width"] = "Ширина иконки";
L["options:spells:icon-height"] = "Высота иконки";

--@end-debug@