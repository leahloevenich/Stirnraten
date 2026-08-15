# Stirnraten

**Stirnraten** ist eine iOS-App für ein Begriffe-Ratespiel im Stil von „Wer bin ich?“. Eine Person hält das iPhone im Querformat an die Stirn, während die Mitspielenden den angezeigten Begriff erklären. Durch Kippen des Geräts wird der Begriff als richtig oder übersprungen bewertet.

## Spielablauf

1. **App im Querformat verwenden**  
   Die Startansicht ist für das Querformat optimiert. Im Hochformat fordert die App dazu auf, das Gerät zu drehen.

2. **Kategorie auswählen**  
   Auf dem Startbildschirm werden die verfügbaren Kategorien als farbige Karten angezeigt. Jede Kategorie enthält eine eigene Liste von Begriffen.

3. **Vorbereitung**  
   Nach der Auswahl startet ein kurzer Countdown. In dieser Zeit kann das Smartphone an die Stirn gehalten werden.

4. **Begriffe erraten**  
   Während der Spielrunde zeigt die App nacheinander zufällig ausgewählte Begriffe aus der gewählten Kategorie an. Bereits verwendete Begriffe werden innerhalb der Runde nicht erneut angezeigt.

5. **Begriff bewerten**
   - Gerät in eine Richtung kippen: Begriff wurde **richtig erraten**.
   - Gerät in die andere Richtung kippen: Begriff wird **übersprungen beziehungsweise als falsch** gewertet.

   Die Bewegungserkennung erfolgt über die Gerätesensoren. Haptisches Feedback und ein kurzer grüner beziehungsweise roter Bildschirmblitz bestätigen die Bewertung. Eine kurze Sperrzeit verhindert, dass eine einzelne Bewegung mehrfach erkannt wird.

6. **Ergebnis ansehen**  
   Nach Ablauf der Spielzeit erscheint eine Übersicht mit:
   - der Anzahl richtig erratener Begriffe,
   - allen während der Runde verwendeten Begriffen,
   - der jeweiligen Bewertung als richtig oder falsch.

## Technische Funktionsweise

Die App ist mit **SwiftUI** umgesetzt und besteht im Wesentlichen aus folgenden Bereichen:

- `stirnratenApp.swift` startet die Anwendung.
- `ContentView.swift` enthält die Kategorieauswahl und die layoutspezifische Darstellung für Hoch- und Querformat.
- `CategoryManager.swift` lädt die Kategorien und Begriffe aus der mitgelieferten JSON-Datei und wandelt die dort gespeicherten Farbcodes in SwiftUI-Farben um.
- `TimerView.swift` zeigt den Countdown vor dem Beginn einer Runde.
- `GameView.swift` steuert die laufende Spielrunde, den Rundentimer, die zufällige Begriffsauswahl und die Bewegungserkennung mit **Core Motion**.
- `EndView` in `GameView.swift` stellt anschließend das Rundenergebnis dar.

## Verwendete Frameworks

- **SwiftUI** für die Benutzeroberfläche und Navigation
- **Combine** für die zeitgesteuerten Countdowns
- **Core Motion** für die Erkennung der Gerätebewegung
- **UIKit Feedback Generator** für haptische Rückmeldungen

## Voraussetzungen

Da die Spielsteuerung die Bewegungssensoren und haptisches Feedback des iPhones verwendet, sollte die App für den vollständigen Funktionsumfang auf einem echten iOS-Gerät getestet werden. Im Simulator stehen diese Funktionen nur eingeschränkt zur Verfügung.
