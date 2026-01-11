---
description: Automatisches Build-Testing und Error-Fixing für SmallTalk macOS App
---

# Workflow: Mandatory Xcode Build Verification & Auto-Fix

## Zweck
**Dieser Workflow ist obligatorisch für jede Code-Änderung.** Er stellt sicher, dass kein Code an den Nutzer übergeben wird, der nicht erfolgreich kompiliert.

## Workflow-Schritte (Automatischer Loop)
1. **Build ausführen**: Nach jeder Implementation von Features oder Designs.
2. **Analyse**: Automatische Extraktion von Fehlern aus dem Terminal.
3. **Fixing**: Iterative Fehlerbehebung bis zum Erfolg.
4. **Validierung**: Erst nach Exit Code 0 ist die Aufgabe abgeschlossen.
```bash
cd /Users/printingminh/Desktop/Desktop/SmallTalk/SmallTalk
xcodebuild -scheme SmallTalk -destination 'platform=macOS' -quiet
```

### 2. Error-Analyse
Wenn der Build fehlschlägt (Exit Code ≠ 0):
- Parse die Fehlermeldungen für:
  - File-Pfad (z.B. `/path/to/File.swift`)
  - Zeilennummer (z.B. `:42:`)
  - Fehler-Typ (z.B. `error:`, `Cannot find type 'X'`)
  - Fehler-Beschreibung

### 3. Automatisches Fixing
Für jeden Fehler:
1. Öffne die betroffene Datei mit `view_file`
2. Analysiere den Kontext (Imports, Typen, etc.)
3. Behebe den Fehler mit `replace_file_content`
4. Commit die Änderung

### 4. Re-Build & Iteration
- Führe `xcodebuild` erneut aus
- Wiederhole Steps 2-3 bis Exit Code = 0

## Wichtige Hinweise
- **Kein manuelles Xcode nötig**: Terminal-basierter Workflow
- **Kein Copy-Paste**: Fehler werden direkt aus Terminal-Output extrahiert
- **Sofortige Analyse**: Fehler werden automatisch geparsed und gefixt
- **Iterativ**: Prozess wiederholt sich bis Build erfolgreich

## Beispiel-Fehlertypen & Fixes

### Typ 1: Missing Import
```
Error: Cannot find type 'AVAudioEngine' in scope
Fix: Add `import AVFoundation`
```

### Typ 2: Deprecated API
```
Warning: 'oldFunction' was deprecated in macOS 14.0
Fix: Replace with new API based on deprecation message
```

### Typ 3: Type Mismatch
```
Error: Cannot convert value of type 'X' to expected type 'Y'
Fix: Add type conversion or update declaration
```

## Turbo-Mode
Dieser Workflow ist für schnelles Iterieren optimiert:
- Jeder Build + Fix Cycle: ~30-60 Sekunden
- Keine UI-Interaktion nötig
- Vollautomatisch bis zum erfolgreichen Build
