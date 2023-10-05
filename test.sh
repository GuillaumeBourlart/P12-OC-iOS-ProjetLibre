#!/bin/sh

set -e

# Obtenir le schéma par défaut
scheme_list=$(xcodebuild -list -json | tr -d "\n")
default=$(echo $scheme_list | jq -r '.project.targets[0]')
echo "Using default scheme: $default"

scheme=$default

# Obtenir le device pour le simulateur
device=$(xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//")

# Détecter le type de projet : workspace ou project
if [ "`ls -A | grep -i \\.xcworkspace\$`" ]; then
    filetype_parameter="workspace"
    file_to_build=$(ls -A | grep -i \\.xcworkspace\$ | awk '{$1=$1;print}')
else
    filetype_parameter="project"
    file_to_build=$(ls -A | grep -i \\.xcodeproj\$ | awk '{$1=$1;print}')
fi

# Lancer les tests
xcodebuild test -scheme "$scheme" -destination "platform=iOS Simulator,name=$device" -$filetype_parameter "$file_to_build"
