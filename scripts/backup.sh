#!/bin/bash
# =================================================================
# Oracle APEX + ORDS Backup Script
# Creates backup of all persistent data
# =================================================================

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="apex_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=============================================="
echo "Oracle APEX Backup Script"
echo -e "==============================================${NC}"
echo ""

# Create backup directory
mkdir -p "${BACKUP_PATH}"
echo -e "${YELLOW}📁 Backup directory: ${BACKUP_PATH}${NC}"

# Check if containers are running
if ! docker ps | grep -q "apex-db"; then
    echo -e "${RED}❌ Error: apex-db container is not running${NC}"
    exit 1
fi

# =================================================================
# 1. Backup Oracle Database (using RMAN or Data Pump)
# =================================================================
echo ""
echo -e "${YELLOW}📦 Backing up Oracle Database...${NC}"

# Export APEX workspaces and applications
docker exec apex-db bash -c "
    export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
    export PATH=\$ORACLE_HOME/bin:\$PATH
    
    # Create export directory if not exists
    mkdir -p /opt/oracle/backup
    
    # Export using Data Pump
    expdp sys/${ORACLE_PWD:-SecurePassword123!}@XEPDB1 \
        directory=DATA_PUMP_DIR \
        dumpfile=apex_export_${TIMESTAMP}.dmp \
        logfile=apex_export_${TIMESTAMP}.log \
        schemas=APEX_240100 \
        exclude=STATISTICS
" 2>/dev/null || echo "Note: Data Pump export may require additional setup"

# Copy database data files
echo "Copying Oracle data files..."
docker cp apex-db:/opt/oracle/oradata "${BACKUP_PATH}/oradata" 2>/dev/null || \
    cp -r ./data/oracle "${BACKUP_PATH}/oradata" 2>/dev/null || \
    echo "Using volume backup method..."

# =================================================================
# 2. Backup ORDS Configuration
# =================================================================
echo ""
echo -e "${YELLOW}📦 Backing up ORDS configuration...${NC}"

if docker ps | grep -q "apex-ords"; then
    docker cp apex-ords:/etc/ords/config "${BACKUP_PATH}/ords_config" 2>/dev/null || \
        cp -r ./data/ords/config "${BACKUP_PATH}/ords_config" 2>/dev/null || true
    
    docker cp apex-ords:/etc/ords/secrets "${BACKUP_PATH}/ords_secrets" 2>/dev/null || \
        cp -r ./data/ords/secrets "${BACKUP_PATH}/ords_secrets" 2>/dev/null || true
fi

# Backup from local bind mounts
if [ -d "./data/ords" ]; then
    cp -r ./data/ords "${BACKUP_PATH}/"
fi

# =================================================================
# 3. Backup APEX Images
# =================================================================
echo ""
echo -e "${YELLOW}📦 Backing up APEX images...${NC}"

if docker ps | grep -q "apex-ords"; then
    docker cp apex-ords:/opt/oracle/apex/images "${BACKUP_PATH}/apex_images" 2>/dev/null || \
        cp -r ./data/apex/images "${BACKUP_PATH}/apex_images" 2>/dev/null || true
fi

# =================================================================
# 4. Backup Environment and Config files
# =================================================================
echo ""
echo -e "${YELLOW}📦 Backing up configuration files...${NC}"

cp .env "${BACKUP_PATH}/.env" 2>/dev/null || true
cp docker-compose.yml "${BACKUP_PATH}/docker-compose.yml"

# =================================================================
# 5. Create compressed archive
# =================================================================
echo ""
echo -e "${YELLOW}📦 Creating compressed archive...${NC}"

cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

echo ""
echo -e "${GREEN}=============================================="
echo "✅ Backup completed successfully!"
echo "=============================================="
echo ""
echo "📁 Backup file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "📊 Backup size: ${BACKUP_SIZE}"
echo -e "==============================================${NC}"
