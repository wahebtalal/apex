-- =================================================================
-- Oracle APEX Setup Script
-- Run this after the database container is ready
-- =================================================================

-- Connect as SYSDBA
-- sqlplus sys/YourPassword@//localhost:1521/XEPDB1 as sysdba

-- Step 1: Unlock APEX_PUBLIC_USER account
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY "ApexPublic123!";

-- Step 2: Create APEX_LISTENER user (if not exists)
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER APEX_LISTENER IDENTIFIED BY "ApexListener123!"';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN -- User already exists
            EXECUTE IMMEDIATE 'ALTER USER APEX_LISTENER IDENTIFIED BY "ApexListener123!"';
        ELSE
            RAISE;
        END IF;
END;
/

ALTER USER APEX_LISTENER ACCOUNT UNLOCK;

-- Step 3: Create APEX_REST_PUBLIC_USER (if not exists)
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER APEX_REST_PUBLIC_USER IDENTIFIED BY "ApexRest123!"';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            EXECUTE IMMEDIATE 'ALTER USER APEX_REST_PUBLIC_USER IDENTIFIED BY "ApexRest123!"';
        ELSE
            RAISE;
        END IF;
END;
/

ALTER USER APEX_REST_PUBLIC_USER ACCOUNT UNLOCK;

-- Step 4: Grant necessary privileges
GRANT CONNECT TO APEX_LISTENER;
GRANT CONNECT TO APEX_REST_PUBLIC_USER;

-- Step 5: Configure APEX RESTful Services
BEGIN
    APEX_INSTANCE_ADMIN.SET_PARAMETER(
        p_parameter => 'RESTFUL_SERVICES_ENABLED',
        p_value     => 'Y'
    );
END;
/

-- Step 6: Create ORDS metadata
BEGIN
    ORDS_ADMIN.PROVISION_RUNTIME_ROLE(
        p_user => 'APEX_LISTENER',
        p_proxy_enabled_schemas => TRUE
    );
END;
/

BEGIN
    ORDS_ADMIN.PROVISION_RUNTIME_ROLE(
        p_user => 'APEX_REST_PUBLIC_USER',
        p_proxy_enabled_schemas => TRUE
    );
END;
/

-- Step 7: Configure ACL for network access (optional, for web services)
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => '*',
        ace  => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'APEX_240100', -- Change to your APEX schema
            principal_type => xs_acl.ptype_db
        )
    );
END;
/

COMMIT;

-- Verify APEX installation
SELECT VERSION, STATUS FROM DBA_REGISTRY WHERE COMP_ID = 'APEX';

-- Show APEX workspaces
SELECT WORKSPACE_ID, WORKSPACE, PRIMARY_SCHEMA FROM APEX_WORKSPACES;

PROMPT APEX Setup completed successfully!
