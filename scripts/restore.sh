#!/bin/bash
# =================================================================
# Oracle APEX + ORDS Restore Script
# Restores backup to persistent storage
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}❌ Usage: ./restore.sh <backup_file.tar.gz>${NC}"
    echo ""
    echo "Available backups:"
    ls -la ./backups/*.tar.gz 2>/dev/null || echo "No backups found in ./backups/"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="./restore_temp"

echo -e "${GREEN}=============================================="
echo "Oracle APEX Restore Script"
echo -e "==============================================${NC}"
echo ""

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Error: Backup file not found: ${BACKUP_FILE}${NC}"
    exit 1
fi

# Confirm restore
echo -e "${YELLOW}⚠️  WARNING: This will overwrite existing data!${NC}"
echo ""
read -p "Are you sure you want to restore from ${BACKUP_FILE}? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# =================================================================
# 1. Stop containers
# =================================================================
echo ""
echo -e "${YELLOW}🛑 Stopping containers...${NC}"
docker-compose down 2>/dev/null || true

# =================================================================
# 2. Extract backup
# =================================================================
echo ""
echo -e "${YELLOW}📦 Extracting backup...${NC}"

rm -rf "${RESTORE_DIR}"
mkdir -p "${RESTORE_DIR}"
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"

# Find the backup folder name
BACKUP_FOLDER=$(ls "${RESTORE_DIR}" | head -1)
BACKUP_PATH="${RESTORE_DIR}/${BACKUP_FOLDER}"

echo "Backup folder: ${BACKUP_PATH}"

# =================================================================
# 3. Restore Oracle Data
# =================================================================
echo ""
echo -e "${YELLOW}📦 Restoring Oracle data...${NC}"

if [ -d "${BACKUP_PATH}/oradata" ]; then
    mkdir -p ./data/oracle
    rm -rf ./data/oracle/*
    cp -r "${BACKUP_PATH}/oradata/"* ./data/oracle/
    echo "✅ Oracle data restored"
else
    echo "⚠️  Oracle data not found in backup"
fi

# =================================================================
# 4. Restore ORDS Configuration
# =================================================================
echo ""
echo -e "${YELLOW}📦 Restoring ORDS configuration...${NC}"

if [ -d "${BACKUP_PATH}/ords_config" ] || [ -d "${BACKUP_PATH}/ords" ]; then
    mkdir -p ./data/ords/config
    mkdir -p ./data/ords/secrets
    
    if [ -d "${BACKUP_PATH}/ords_config" ]; then
        cp -r "${BACKUP_PATH}/ords_config/"* ./data/ords/config/ 2>/dev/null || true
    fi
    
    if [ -d "${BACKUP_PATH}/ords_secrets" ]; then
        cp -r "${BACKUP_PATH}/ords_secrets/"* ./data/ords/secrets/ 2>/dev/null || true
    fi
    
    if [ -d "${BACKUP_PATH}/ords" ]; then
        cp -r "${BACKUP_PATH}/ords/"* ./data/ords/ 2>/dev/null || true
    fi
    
    echo "✅ ORDS configuration restored"
else
    echo "⚠️  ORDS configuration not found in backup"
fi

# =================================================================
# 5. Restore APEX Images
# =================================================================
echo ""
echo -e "${YELLOW}📦 Restoring APEX images...${NC}"

if [ -d "${BACKUP_PATH}/apex_images" ]; then
    mkdir -p ./data/apex/images
    rm -rf ./data/apex/images/*
    cp -r "${BACKUP_PATH}/apex_images/"* ./data/apex/images/
    echo "✅ APEX images restored"
else
    echo "⚠️  APEX images not found in backup"
fi

# =================================================================
# 6. Restore .env file (optional)
# =================================================================
if [ -f "${BACKUP_PATH}/.env" ]; then
    echo ""
    read -p "Restore .env file? (yes/no): " RESTORE_ENV
    if [ "$RESTORE_ENV" == "yes" ]; then
        cp "${BACKUP_PATH}/.env" ./.env
        echo "✅ .env file restored"
    fi
fi

# =================================================================
# 7. Cleanup
# =================================================================
echo ""
echo -e "${YELLOW}🧹 Cleaning up...${NC}"
rm -rf "${RESTORE_DIR}"

# =================================================================
# 8. Set permissions
# =================================================================
echo ""
echo -e "${YELLOW}🔐 Setting permissions...${NC}"
chmod -R 755 ./data 2>/dev/null || true

# =================================================================
# 9. Start containers
# =================================================================
echo ""
read -p "Start containers now? (yes/no): " START_CONTAINERS

if [ "$START_CONTAINERS" == "yes" ]; then
    echo -e "${YELLOW}🚀 Starting containers...${NC}"
    docker-compose up -d
    echo ""
    echo "Waiting for containers to be healthy..."
    sleep 10
    docker-compose ps
fi

echo ""
echo -e "${GREEN}=============================================="
echo "✅ Restore completed successfully!"
echo -e "==============================================${NC}"
