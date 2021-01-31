BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS node_cred (cred_id TEXT PRIMARY KEY, node_id TEXT, addr TEXT, port INTEGER, protocol TEXT, session TEXT);
CREATE TABLE IF NOT EXISTS temp_cred (cred_id TEXT PRIMARY KEY, node_id TEXT, addr TEXT, port INTEGER, protocol TEXT, session TEXT);
CREATE TABLE IF NOT EXISTS node_attr (node_id TEXT PRIMARY KEY, app TEXT, attr TEXT, value TEXT);
CREATE TABLE IF NOT EXISTS db_ver (value INTEGER);
DELETE FROM db_ver;
INSERT INTO db_ver (value) VALUES (2);
COMMIT TRANSACTION;
