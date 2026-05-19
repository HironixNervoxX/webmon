#!/bin/bash
# Sauvegarde la base PostgreSQL dans backups/webmon_<timestamp>.sql

set -euo pipefail

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Détection mode dry-run
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  echo -e "${YELLOW}🧪 Mode dry-run : aucune écriture${NC}"
fi

# Vérifie que postgres tourne
if ! docker compose ps postgres | grep -q "running"; then
  echo -e "${RED}❌ Le conteneur postgres ne tourne pas. Lance 'make start' d'abord.${NC}"
  exit 1
fi

# Prépare le dossier de sauvegarde
mkdir -p backups

# Nom du fichier
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backups/webmon_${TIMESTAMP}.sql"

echo -e "${YELLOW}📦 Sauvegarde en cours : ${BACKUP_FILE}${NC}"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "  (dry-run, pas d'exécution réelle)"
  exit 0
fi

# Exécute pg_dump dans le conteneur
if docker compose exec -T postgres pg_dump -U webmon -d webmon > "$BACKUP_FILE"; then
  SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo -e "${GREEN}✅ Sauvegarde réussie : ${BACKUP_FILE} (${SIZE})${NC}"
else
  echo -e "${RED}❌ Échec de la sauvegarde${NC}"
  rm -f "$BACKUP_FILE"
  exit 1
fi

# Nettoie les vieux backups (garde les 10 plus récents)
cd backups
ls -t webmon_*.sql 2>/dev/null | tail -n +11 | xargs -r rm -f
cd ..
echo -e "${GREEN}🧹 Anciens backups nettoyés (on garde les 10 plus récents)${NC}"