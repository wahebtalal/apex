#!/bin/bash
set -e

echo "=========================================="
echo "ORDS Configuration Script"
echo "=========================================="

# Configuration directory
ORDS_CONFIG="/etc/ords/config"
CONN_STRING="${DB_HOSTNAME}:${DB_PORT}/${DB_SERVICE}"

echo "Database: ${CONN_STRING}"

# Wait for database to be ready
echo "Waiting for database..."
until echo "exit" | sqlplus -L sys/${SYS_PASSWORD}@//${CONN_STRING} as sysdba 2>/dev/null; do
    echo "Waiting for Oracle Database to be ready..."
    sleep 10
done

echo "Database is ready!"

# Check if ORDS is already configured
if [ -f "${ORDS_CONFIG}/databases/default/pool.xml" ]; then
    echo "ORDS already configured, starting server..."
else
    echo "Configuring ORDS for the first time..."
    
    # Create config directory
    mkdir -p ${ORDS_CONFIG}
    
    # Install ORDS (non-interactive)
    ords --config ${ORDS_CONFIG} install \
        --admin-user SYS \
        --proxy-user \
        --db-hostname ${DB_HOSTNAME} \
        --db-port ${DB_PORT} \
        --db-servicename ${DB_SERVICE} \
        --feature-db-api true \
        --feature-rest-enabled-sql true \
        --feature-sdw true \
        --log-folder /tmp \
        --password-stdin <<< "${SYS_PASSWORD}"
    
    echo "ORDS configuration completed!"
fi

# Start ORDS
echo "Starting ORDS on port 8181..."
exec ords --config ${ORDS_CONFIG} serve --port 8181
