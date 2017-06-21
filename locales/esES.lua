local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "esES");
L = L or {}
L["< 1min"] = "< 1min"
L["< 5sec"] = "< 5seg"
L["> 1min"] = "> 1min"
L["Add new spell: "] = "Agregar nuevo hechizo:"
L["Add spell"] = "Agregar hechizo"
L["All auras"] = "Todas las auras"
L["Always display icons at full opacity (ReloadUI is required)"] = "Siempre mostrar iconos con opacidad completa (es necesario recargar la UI)"
L["Always show auras cast by myself"] = "Siempre mostrar auras lanzadas por mí"
--Translation missing 
L["Anchor point"] = "Anchor point"
--Translation missing 
L["Anchor to icon"] = "Anchor to icon"
L["Any"] = "Cualquiera"
L["Aura type"] = "Tipo de aura"
L["Border thickness"] = "Grosor del borde"
L["BOTTOM"] = "Parte inferior"
L["BOTTOMLEFT"] = "Parte inferior izquierda"
L["BOTTOMRIGHT"] = "Parte inferior derecha"
--Translation missing 
L["Buff"] = "Buff"
--Translation missing 
L["By aura type (de/buff) + expire time"] = "By aura type (de/buff) + expire time"
L["By expire time, ascending"] = "Por tiempo de expiración, ascendente"
L["By expire time, descending"] = "Por tiempo de expiración, descendente"
L["By icon size, ascending"] = "Por tamaño de icono, ascendente"
L["By icon size, descending"] = "Por tamaño de icono, descendente"
L["CENTER"] = "Parte central"
L["Check spell ID"] = [=[Comprobar ID de hechizo
(comma-separated)]=]
L["Circular"] = "Circular"
L["Circular with OmniCC support"] = "Circular, compatible con OmniCC"
L["Circular with timer"] = "Circular con temporizador"
L["Click to select spell"] = "Haz click para elegir el hechizo"
L["Curse"] = "Maldición"
--Translation missing 
L["Debuff"] = "Debuff"
L["Default icon size"] = "Tamaño de icono por defecto"
L["Delete all spells"] = "Eliminar todos los hechizos"
L["Delete spell"] = "Eliminar hechizo"
L["Disabled"] = "Desactivado"
L["Disease"] = "Enfermedad"
L["Display auras on nameplates of friendly units"] = "Mostrar auras en los nombres de las unidades aliadas"
L["Display auras on player's nameplate"] = "Mostrar auras en el nombre del jugador"
L["Display tenths of seconds"] = "Mostrar décimas de segundo"
L["Do you really want to delete ALL spells?"] = "¿Seguro que quieres eliminar TODOS los hechizos?"
L["Font"] = "Fuente de letra"
--Translation missing 
L["Font scale"] = "Font scale"
L["Font size"] = "Tamaño de fuente"
--Translation missing 
L["Frame anchor:"] = "Frame anchor:"
L["General"] = "General"
L["Hide Blizzard's aura frames (Reload UI is required)"] = "Ocultar los marcos de aura de Blizzard (es necesario recargar la UI)"
--Translation missing 
L["Icon anchor:"] = "Icon anchor:"
L["Icon borders"] = "Bordes del icono"
L["Icon size"] = "Tamaño del icono"
--Translation missing 
L["Icon X-coord offset"] = "Icon X-coord offset"
--Translation missing 
L["Icon Y-coord offset"] = "Icon Y-coord offset"
L["LEFT"] = "Izquierda"
L["Magic"] = "Magia"
--Translation missing 
L["Mode"] = "Mode"
L["No"] = "No"
L["None"] = "Ninguna"
L["Only my auras"] = "Solo mis auras"
--Translation missing 
L["Open profiles dialog"] = "Open profiles dialog"
L["Options are not available in combat!"] = "¡Las opciones no están disponibles en combate!"
L["options:aura-options:allow-multiple-instances"] = "Permitir instancias múltiples de este aura"
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[Si marcas esta opción, podrás ver todas las instancias de este aura, incluso en el mismo nombre.
De lo contrario, verás una sola instancia de este aura (la más extensa).]=]
L["options:auras:add-new-spell:error1"] = [=[Debes ingresar el nombre del hechizo en vez del ID del hechizo.
Utiliza la opción "%s" si deseas rastrear un hechizo con un ID específico.]=]
L["options:auras:enabled-state:tooltip"] = [=[Activar/desactivar aura

%s: el aura no se mostrará
%s: el aura se mostrará si tú la lanzaste
%s: mostrar todas las auras]=]
L["options:auras:enabled-state-all"] = "Activado, mostrar todas las auras"
L["options:auras:enabled-state-mineonly"] = "Activado, mostrar solo mis auras"
L["options:auras:pvp-state-dontshowinpvp"] = "No mostrar este aura durante combate de JcJ"
L["options:auras:pvp-state-indefinite"] = "Mostrar este aura durante combate de JcJ"
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Mostrar este aura solo en combate de JcJ"
--Translation missing 
L["options:category:interrupts"] = "Interrupts"
--Translation missing 
L["options:general:always-show-my-auras:tooltip"] = [=[This is top priority filter. If you enable this feature,
your auras will be shown regardless of other filters]=]
--Translation missing 
L["options:general:error-omnicc-is-not-loaded"] = "You cannot select this option because OmniCC is not loaded!"
--Translation missing 
L["options:interrupts:enable-interrupts"] = "Enable interrupt tracking"
--Translation missing 
L["options:interrupts:enable-only-during-pvp-battles"] = "Enable during PvP battles only"
--Translation missing 
L["options:interrupts:glow"] = "Icon glow"
--Translation missing 
L["options:interrupts:icon-size"] = "Icon size"
--Translation missing 
L["options:interrupts:use-shared-icon-texture"] = "Use the same texture for all interrupt spells"
--Translation missing 
L["options:selector:search"] = "Search:"
--Translation missing 
L["options:spells:appropriate-spell-ids"] = "Appropriate spell IDs:"
--Translation missing 
L["options:spells:icon-glow"] = "Icon glow"
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Duración mínima para mostrar décimas de segundo"
L["options:timer-text:scale-font-size"] = [=[Modificar el tamaño de fuente
de acuerdo con
el tamaño del icono]=]
L["options:timer-text:text-color-note"] = [=[El color de texto cambiará
de acuerdo con el tiempo restante:]=]
L["Other"] = "Otras"
L["Please reload UI to apply changes"] = "Por favor, recargue la UI para aplicar los cambios."
L["Poison"] = "Veneno"
L["Profiles"] = "Perfiles"
L["Reload UI"] = "Recargar UI"
L["RIGHT"] = "Derecha"
--Translation missing 
L["Show border around buff icons"] = "Show border around buff icons"
--Translation missing 
L["Show border around debuff icons"] = "Show border around debuff icons"
L["Show this aura on nameplates of allies"] = "Mostrar este aura en los nombres de los aliados"
L["Show this aura on nameplates of enemies"] = "Mostrar este aura en los nombres de los enemigos"
L["Sort mode:"] = "Ordenar por:"
L["Space between icons"] = "Espacio entre iconos"
L["Spell already exists (%s)"] = "El hechizo ya existe (%s)"
L["Spell seems to be nonexistent"] = "El hechizo no existe"
L["Spells"] = "Hechizos"
--Translation missing 
L["Stack text"] = "Stack text"
L["Text"] = "Texto"
L["Text color"] = "Color de texto"
--Translation missing 
L["Texture with timer"] = "Texture with timer"
--Translation missing 
L["Timer style:"] = "Timer style:"
--Translation missing 
L["Timer text"] = "Timer text"
L["TOP"] = "Parte superior"
L["TOPLEFT"] = "Parte superior izquierda"
L["TOPRIGHT"] = "Parte superior derecha"
L["Unknown spell: %s"] = "Hechizo desconocido: %s"
L["Value must be a number"] = "El valor debe ser numérico"
--Translation missing 
L["X offset"] = "X offset"
--Translation missing 
L["Y offset"] = "Y offset"
L["Yes"] = "Sí"
