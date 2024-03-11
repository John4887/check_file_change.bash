#!/bin/bash

script="check_file_change.bash"
version="1.0.0"
author="John Gonzalez"

# Affichage de l'aide
usage() {
  echo "Usage to check a file: $0 --file <path_file>"
  echo "Usage to validate the file change: $0 --update --file <path_file>"
  echo "Options:"
  echo "  --update             Update file state after change was detected"
  echo "  --file <path_file>   Specify the path of the file to check"
  echo "  -h                   Show this help message"
  echo "  -v                   Show version"
}

# Variables initiales
file_to_monitor=""
update=""

# Gestion des options longues
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        -v|--version) echo "$script - $author - $version" ; exit 0 ;;
        --update) update=1; shift ;;
        --file) file_to_monitor="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$file_to_monitor" ]]; then
    echo "Error: You have to specify the file to monitor with --file option"
    usage
    exit 1
fi

# Définition des fichiers d'état basés sur le fichier à surveiller
filename=$(basename "$file_to_monitor")
CONTROL_DIR="/usr/local/ncpa/plugins/file_monitor_control"
STATE_FILE="${CONTROL_DIR}/${filename}_state.txt"
TEMP_STATE_FILE="${CONTROL_DIR}/${filename}_temp_state.txt"

mkdir -p "$CONTROL_DIR"

generate_current_state() {
    md5sum "$file_to_monitor" | awk '{print $1}'
}

# Mise à jour du fichier d'état
if [[ ! -z "$update" ]]; then
    if [[ -f "$TEMP_STATE_FILE" ]]; then
        mv "$TEMP_STATE_FILE" "$STATE_FILE"
        echo "State file updated with success."
        exit 0
    else
        echo "Error: Temp state file is missed, unable to update."
        exit 1
    fi
fi

generate_current_state > "$TEMP_STATE_FILE"

if [[ -f "$STATE_FILE" ]]; then
    DIFF=$(diff "$STATE_FILE" "$TEMP_STATE_FILE")
    if [[ ! -z "$DIFF" ]]; then
        echo "WARNING: Change detected in $file_to_monitor. Please check. Manually execute the script with --update after checking if the change is valid."
        exit 1
    else
        echo "OK: No change detected in $file_to_monitor."
        exit 0
    fi
else
    echo "Initial state file created for $file_to_monitor. Monitoring will be activated on the next execution."
    mv "$TEMP_STATE_FILE" "$STATE_FILE"
    exit 0
fi
