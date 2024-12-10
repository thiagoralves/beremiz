#!/bin/bash

# Prüfe ob die korrekten Parameter übergeben wurden
if [ $# -ne 2 ]; then
    echo "Verwendung: $0 datei1.json datei2.json"
    exit 1
fi

# Prüfe ob die Dateien existieren
if [ ! -f "$1" ]; then
    echo "Fehler: Datei '$1' nicht gefunden"
    exit 1
fi

if [ ! -f "$2" ]; then
    echo "Fehler: Datei '$2' nicht gefunden"
    exit 1
fi

# Temporäre Dateien erstellen
TEMP1=$(mktemp)
TEMP2=$(mktemp)

# Aufräumen bei Beendigung
trap 'rm -f "$TEMP1" "$TEMP2"' EXIT

# JSON-Dateien sortieren
jq --sort-keys 'walk(if type == "object" then . else . end)' "$1" > "$TEMP1"
jq --sort-keys 'walk(if type == "object" then . else . end)' "$2" > "$TEMP2"

# Prüfe ob jq erfolgreich war
if [ $? -ne 0 ]; then
    echo "Fehler: Probleme beim Parsen der JSON-Dateien"
    exit 1
fi

# Prüfe ob colordiff verfügbar ist
if command -v colordiff >/dev/null 2>&1; then
    DIFF_CMD="colordiff"
else
    DIFF_CMD="diff"
fi

# Vergleich durchführen
$DIFF_CMD "$TEMP1" "$TEMP2"

# Exit-Code des diff-Befehls weitergeben
exit $?
