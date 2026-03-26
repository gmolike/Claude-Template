#!/bin/bash
set -euo pipefail

echo "=== {{PROJECT_NAME}} Backend .NET Setup ==="

read -p "Projektname (z.B. MyProject): " PROJECT_NAME

echo "Ersetze Platzhalter..."

# Rename directories
for dir in $(find src tests -type d -name '*{{PROJECT_NAME}}*' 2>/dev/null | sort -r); do
  newdir=$(echo "$dir" | sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g")
  mv "$dir" "$newdir"
done

# Rename files
for file in $(find . -type f -name '*{{PROJECT_NAME}}*' -not -path "./.git/*" 2>/dev/null); do
  newfile=$(echo "$file" | sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g")
  mv "$file" "$newfile"
done

# Replace in file contents
find . -type f \( -name "*.cs" -o -name "*.csproj" -o -name "*.sln" -o -name "*.json" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sh" -o -name "*.xml" -o -name "*.props" \) \
  -not -path "./.git/*" \
  -exec sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" {} +

echo "Setup abgeschlossen!"
echo "Naechste Schritte:"
echo "  1. docker-compose up -d (PostgreSQL starten)"
echo "  2. dotnet ef database update (Migrationen anwenden)"
echo "  3. dotnet run --project src/$PROJECT_NAME.API"
