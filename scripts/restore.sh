#!/bin/bash
# Restaure la dernière sauvegarde, ou un fichier passé en argument

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Détermine le fichier à restaurer
if [[ $# -ge 1 && "$1" != "--dry-run" ]]; then
  BACKUP_FILE="$1"
else
  # Dernière sauvegarde
  BACKUP_FILE=$(ls -t backups/webmon_*.sql 2>/dev/null | head -1 || echo "")
fi

if [[ -z "$BACKUP_FILE" || ! -f "$BACKUP_FILE" ]]; then
  echo -e "${RED}❌ Aucun backup trouvé dans backups/${NC}"
  exit 1
fi

# Vérifie que postgres tourne
if ! docker compose exec -T postgres pg_isready -U webmon >/dev/null 2>&1; then
  echo -e "${RED}❌ Le conteneur postgres ne tourne pas. Lance 'make start' d'abord.${NC}"
  exit 1
fi

# Confirmation
echo -e "${YELLOW}⚠️  Tu vas écraser les données actuelles avec : ${BACKUP_FILE}${NC}"
read -p "Continuer ? (oui/non) : " CONFIRM
if [[ "$CONFIRM" != "oui" ]]; then
  echo "Annulé."
  exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  echo -e "${YELLOW}🧪 Dry-run : pas d'exécution${NC}"
  exit 0
fi

echo -e "${YELLOW}🔄 Restauration en cours...${NC}"

# On purge la table avant restauration pour éviter les conflits de clé
docker compose exec -T postgres psql -U webmon -d webmon -c "DROP TABLE IF EXISTS tasks CASCADE;" > /dev/null

# Restauration
if docker compose exec -T postgres psql -U webmon -d webmon < "$BACKUP_FILE" > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Restauration terminée${NC}"
else
  echo -e "${RED}❌ Erreur pendant la restauration${NC}"
  exit 1
fi