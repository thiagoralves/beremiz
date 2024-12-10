#!/bin/bash

# Prüfe ob eine Datei übergeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: $0 datei.json" >&2
    exit 1
fi

# Prüfe ob die Datei existiert
if [ ! -f "$1" ]; then
    echo "Fehler: Datei '$1' nicht gefunden" >&2
    exit 1
fi

# JSON formatieren und sortieren, nur Objekte, Arrays unverändert lassen
jq --sort-keys 'walk(if type == "object" then . else . end)' "$1" 2>/dev/null

# Prüfe ob jq erfolgreich war
if [ $? -ne 0 ]; then
    # Bei Fehler Original-Datei ausgeben
    cat "$1"
fi
