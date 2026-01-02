#!/bin/bash
# =================================================================
# ORDS and APEX Initialization Script
# This script runs after database is ready
# =================================================================

echo "=============================================="
echo "Starting APEX & ORDS Initialization..."
echo "=============================================="

# Wait for database to be ready
echo "Waiting for Oracle Database to be ready..."
until sqlplus -L sys/${ORACLE_PWD}@//${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE} as sysdba <<< "SELECT 1 FROM DUAL;" > /dev/null 2>&1; do
    echo "Database not ready, waiting..."
    sleep 10
done

echo "Database is ready!"

# Setup APEX users
echo "Setting up APEX users..."
sqlplus -L sys/${ORACLE_PWD}@//${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE} as sysdba << EOF
-- Unlock and set passwords for APEX users
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY "${APEX_PUBLIC_USER_PASSWORD}";

-- Create/update APEX_LISTENER
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER APEX_LISTENER IDENTIFIED BY "${APEX_LISTENER_PASSWORD}"';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            EXECUTE IMMEDIATE 'ALTER USER APEX_LISTENER IDENTIFIED BY "${APEX_LISTENER_PASSWORD}"';
        ELSE
            RAISE;
        END IF;
END;
/

ALTER USER APEX_LISTENER ACCOUNT UNLOCK;
GRANT CONNECT TO APEX_LISTENER;

-- Create/update APEX_REST_PUBLIC_USER
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER APEX_REST_PUBLIC_USER IDENTIFIED BY "${APEX_REST_PUBLIC_USER_PASSWORD}"';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            EXECUTE IMMEDIATE 'ALTER USER APEX_REST_PUBLIC_USER IDENTIFIED BY "${APEX_REST_PUBLIC_USER_PASSWORD}"';
        ELSE
            RAISE;
        END IF;
END;
/

ALTER USER APEX_REST_PUBLIC_USER ACCOUNT UNLOCK;
GRANT CONNECT TO APEX_REST_PUBLIC_USER;

COMMIT;
EXIT;
EOF

echo "APEX users configured successfully!"

# Configure ORDS
echo "Configuring ORDS..."
cd /opt/oracle/ords

# Create ORDS config if not exists
if [ ! -f "${ORDS_CONFIG}/default/pool.xml" ]; then
    echo "Creating ORDS configuration..."
    
    ords --config ${ORDS_CONFIG} install \
        --admin-user SYS \
        --db-hostname ${ORACLE_HOST} \
        --db-port ${ORACLE_PORT} \
        --db-servicename ${ORACLE_SERVICE} \
        --feature-db-api true \
        --feature-rest-enabled-sql true \
        --feature-sdw true \
        --gateway-mode proxied \
        --gateway-user APEX_PUBLIC_USER \
        --password-stdin <<< "${ORACLE_PWD}"
    
    echo "ORDS configuration created!"
else
    echo "ORDS configuration already exists, skipping..."
fi

echo "=============================================="
echo "APEX & ORDS Initialization Complete!"
echo "=============================================="

# Start ORDS
echo "Starting ORDS server on port ${ORDS_PORT:-8181}..."
ords --config ${ORDS_CONFIG} serve --port ${ORDS_PORT:-8181}
