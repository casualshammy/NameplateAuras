local L = LibStub("AceLocale-3.0"):NewLocale("NameplateAuras", "deDE");
L = L or {}
L["< 1min"] = "< 1 Min."
L["< 5sec"] = "< 5 Sek."
L["> 1min"] = "> 1 Min."
L["Add new spell: "] = "Neuen Zauber hinzufügen:"
L["Add spell"] = "Zauber hinzufügen"
L["All auras"] = "Alle Auren"
L["Always display icons at full opacity (ReloadUI is required)"] = "Symbole immer mit voller Deckkraft anzeigen (UI-Neuladen erforderlich)"
L["Always show auras cast by myself"] = "Auren, die ich gewirkt habe, immer anzeigen"
L["Anchor point"] = "Ankerpunkt"
L["Anchor to icon"] = "Am Symbol anheften"
L["Any"] = "Irgendeiner"
L["Aura type"] = "Auratyp"
L["Border thickness"] = "Rahmenbreite"
L["BOTTOM"] = "Unten"
L["BOTTOMLEFT"] = "Unten links"
L["BOTTOMRIGHT"] = "Unten rechts"
L["Buff"] = "Stärkungszauber"
L["By aura type (de/buff) + expire time"] = "Nach Auratyp (Stärkungs-/Schwächungszauber) und Ablaufzeit"
L["By expire time, ascending"] = "Nach Ablaufzeit, zunehmend"
L["By expire time, descending"] = "Nach Ablaufzeit, abnehmend"
L["By icon size, ascending"] = "Nach Symbolgröße, zunehmend"
L["By icon size, descending"] = "Nach Symbolgröße, abnehmend"
L["CENTER"] = "Mittig"
L["Check spell ID"] = [=[Zauber-IDs prüfen
(kommagetrennt)]=]
L["Circular"] = "Kreisförmig"
L["Circular with OmniCC support"] = "Kreisförmig mit OmniCC-Unterstützung"
L["Circular with timer"] = "Kreisförmig mit Timer"
L["Click to select spell"] = "Klicken, um einen Zauber auszuwählen"
L["Curse"] = "Fluch"
L["Debuff"] = "Schwächungszauber"
L["Default icon size"] = "Standard-Symbolgröße"
L["Delete all spells"] = "Alle Zauber entfernen"
L["Delete spell"] = "Zauber löschen"
L["Disabled"] = "Deaktiviert"
L["Disease"] = "Krankheit"
L["Display auras on nameplates of friendly units"] = "Auren auf Namensplaketten verbündeter Einheiten anzeigen"
L["Display auras on player's nameplate"] = "Auren auf der Namensplakette des Spielers anzeigen"
L["Display tenths of seconds"] = "Zehntelsekunden anzeigen"
L["Do you really want to delete ALL spells?"] = "Willst du wirklich ALLE Zauber entfernen?"
L["Font"] = "Schriftart"
L["Font scale"] = "Schriftskalierung"
L["Font size"] = "Schriftgröße"
L["Frame anchor:"] = "Rahmenanker"
L["General"] = "Allgemein"
L["Hide Blizzard's aura frames (Reload UI is required)"] = "Blizzards Auraelemente ausblenden (UI-Neuladen erforderlich)"
L["Icon anchor:"] = "Symbolanker:"
L["Icon borders"] = "Symbolrahmen"
L["Icon size"] = "Symbolgröße"
L["Icon X-coord offset"] = "Symbolverschiebung X-Richtung"
L["Icon Y-coord offset"] = "Symbolverschiebung Y-Richtung"
L["LEFT"] = "Links"
L["Magic"] = "Magie"
L["Mode"] = "Modus"
L["No"] = "Nein"
L["None"] = "Keine"
L["Only my auras"] = "Nur meine Auren"
L["Open profiles dialog"] = "Profildialog öffnen"
L["Options are not available in combat!"] = "Optionen sind im Kampf nicht verfügbar!"
L["options:aura-options:allow-multiple-instances"] = "Mehrere Exemplare dieser Aura erlauben"
L["options:aura-options:allow-multiple-instances:tooltip"] = [=[Falls diese Option angehakt ist, wirst du alle Exemplare dieser Aura sehen, auch wenn diese sich auf derselben Namensplakette befinden.
Anderenfalls wirst du nur ein Exemplar dieser Aura sehen (die mit der größten Restdauer)]=]
L["options:auras:add-new-spell:error1"] = [=[Du solltest den Zaubernamen anstatt die Zauber-ID eingeben.
Verwende die Option "%s", wenn du Zauber mit einer bestimmten ID verfolgen möchtest.]=]
L["options:auras:enabled-state:tooltip"] = [=[Aktiviert/Deaktiviert die Aura

%s: Aura wird nicht gezeigt
%s: Aura wird angezeigt, wenn du sie gewirkt hast
%s: Alle Auren zeigen]=]
L["options:auras:enabled-state-all"] = "Aktiviert, Alle Auren zeigen"
L["options:auras:enabled-state-mineonly"] = "Aktiviert, nur meine Auren zeigen"
L["options:auras:pvp-state-dontshowinpvp"] = "Diese Aura während eines PvP-Kampfes nicht zeigen"
L["options:auras:pvp-state-indefinite"] = "Diese Aura während eines PvP-Kampfes zeigen"
L["options:auras:pvp-state-onlyduringpvpbattles"] = "Diese Aura nur während eines PvP-Kampfes zeigen"
L["options:category:interrupts"] = "Unterbrechungen"
L["options:general:always-show-my-auras:tooltip"] = [=[Dies ist ein Filter höchster Priorität. Falls du diese
 Funktion aktivierst, werden Auren, die du gewirkt hast,
 unabhängig von anderen Filtern gezeigt]=]
L["options:general:error-omnicc-is-not-loaded"] = "Du kannst diese Option nicht auswählen, weil OmniCC nicht geladen ist!"
L["options:general:use-dim-glow"] = "Schwaches Leuchten von Symbolen "
L["options:general:use-dim-glow:tooltip"] = [=[Wenn diese Option aktiviert ist wird kein konstantes inneres und äußeres Leuchten des Symbols sichtbar sein.
(Diese Option ist nur verfügbar für Zauber welche explizit für das Leuchten von Symbolen aktiviert wurden)]=]
L["options:interrupts:enable-interrupts"] = "Unterbrechungsverfolgung aktivieren"
L["options:interrupts:enable-only-during-pvp-battles"] = "Nur während PvP-Kämpfen aktivieren"
L["options:interrupts:glow"] = "Symbolleuchten"
L["options:interrupts:icon-size"] = "Symbolgröße"
L["options:interrupts:use-shared-icon-texture"] = "Die gleiche Textur für alle Unterbrechungszauber verwenden"
L["options:selector:search"] = "Suchen:"
L["options:spells:appropriate-spell-ids"] = "Passende Zauber-IDs:"
L["options:spells:icon-glow"] = "Zeige Leuchten"
L["options:spells:icon-glow-always"] = "Zeige Leuchten immer aktiv"
L["options:spells:icon-glow-threshold"] = "Zeige Leuchte wenn verbleibende Zeit der Aura kleiner ist als"
L["options:spells:show-on-friends:warning0"] = [=[Achtung:
Die Aura wird nicht bei Nameplates freundlicher Einhaten angezeigt bis folgende option aktiviert wird:
<Allgemein> --> <Zeige Aura bei Nameplates von freundlichen Einheiten>]=]
L["options:timer-text:min-duration-to-display-tenths-of-seconds"] = "Minimale Dauer zur Anzeige von Zehntelsekunden"
L["options:timer-text:scale-font-size"] = [=[Schriftgröße an
Symbolgröße
anpassen]=]
L["options:timer-text:text-color-note"] = [=[Die Textfarbe wird je nach
 verbleibender Zeit geändert:]=]
L["Other"] = "Andere"
L["Please reload UI to apply changes"] = "Bitte UI neuladen, um Änderungen zu übernehmen"
L["Poison"] = "Gift"
L["Profiles"] = "Profile"
L["Reload UI"] = "UI neuladen"
L["RIGHT"] = "Rechts"
L["Show border around buff icons"] = "Rahmen um Stärkungszaubersymbole zeigen"
L["Show border around debuff icons"] = "Rahmen um Schwächungszaubersymbole zeigen"
L["Show this aura on nameplates of allies"] = "Diese Aura auf Namensplaketten Verbündeter anzeigen"
L["Show this aura on nameplates of enemies"] = "Diese Aura auf Namensplaketten von Feinden anzeigen"
L["Sort mode:"] = "Anordnung:"
L["Space between icons"] = "Platz zwischen Symbolen"
L["Spell already exists (%s)"] = "Zauber existiert bereits (%s)"
L["Spell seems to be nonexistent"] = "Zauber scheint nicht zu existieren"
L["Spells"] = "Zauber"
L["Stack text"] = "Stapeltext"
L["Text"] = "Text"
L["Text color"] = "Textfarbe"
L["Texture with timer"] = "Textur mit Timer"
L["Timer style:"] = "Timerstil:"
L["Timer text"] = "Timertext"
L["TOP"] = "Oben"
L["TOPLEFT"] = "Oben links"
L["TOPRIGHT"] = "Oben rechts"
L["Unknown spell: %s"] = "Unbekannter Zauber: %s"
L["Value must be a number"] = "Wert muss eine Zahl sein"
L["X offset"] = "X-Verschiebung"
L["Y offset"] = "Y-Verschiebung"
L["Yes"] = "Ja"
