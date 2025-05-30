#!/bin/bash

set -e

# Funzione per stampare la barra di avanzamento
print_progress() {
    local current=$1
    local total=$2
    local percent=$(( 100 * current / total ))
    echo -ne "📦 Estrazione: $current di $total completati - $percent% \r"
}

# Chiede il percorso della cartella
echo "📁 Inserisci il percorso della cartella contenente i file .zip (premi INVIO per usare la cartella corrente):"
read -r user_path

# Se vuoto, usa la cartella in cui si trova lo script
if [[ -z "$user_path" ]]; then
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "📂 Nessun percorso inserito. Uso la cartella dello script: $DIR"
else
    # Verifica che la cartella esista
    if [[ ! -d "$user_path" ]]; then
        echo "❌ Errore: la cartella '$user_path' non esiste."
        exit 1
    fi
    DIR="$user_path"
    echo "📂 Cartella specificata: $DIR"
fi

cd "$DIR"

# Trova tutti i file .zip
zip_files=( *.zip )
total_files=${#zip_files[@]}

# Se non ci sono file .zip
if [[ $total_files -eq 0 ]]; then
    echo "⚠️ Nessun file .zip trovato nella cartella."
    exit 0
fi

echo "🔍 Trovati $total_files file .zip. Avvio dell'estrazione..."

# Estrazione con indicatore di avanzamento
current=0
for zipfile in "${zip_files[@]}"; do
    [[ -f "$zipfile" ]] || continue

    foldername="${zipfile%.zip}"
    mkdir -p "$foldername"

    unzip -o "$zipfile" -d "$foldername" >/dev/null

    current=$((current + 1))
    print_progress "$current" "$total_files"
done

echo -e "\n🎉 Tutti i file .zip sono stati estratti correttamente!"
