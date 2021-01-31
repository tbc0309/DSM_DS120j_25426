CREATE TABLE IF NOT EXISTS entry_tmp
(
	id 					INTEGER 	PRIMARY KEY ASC AUTOINCREMENT
	,hash 				TEXT 		NOT NULL
	,project_name 		TEXT		NOT NULL
	,enabled 			INTEGER
	,owner_uid			INTEGER
	,start_at			INTEGER
	,expire_at			INTEGER
	,expire_times		INTEGER
	,use_count			INTEGER
	,auto_gc			INTEGER
	,data				JSON		NOT NULL
);

INSERT INTO entry_tmp SELECT * FROM entry;
DROP TABLE entry;
ALTER TABLE entry_tmp RENAME TO entry;
CREATE UNIQUE INDEX IF NOT EXISTS hash ON entry (hash);
CREATE INDEX IF NOT EXISTS project_name ON entry (project_name);
CREATE INDEX IF NOT EXISTS owner_uid ON entry (owner_uid);
CREATE INDEX IF NOT EXISTS enabled ON entry (enabled);
CREATE INDEX IF NOT EXISTS start_at ON entry (start_at);
CREATE INDEX IF NOT EXISTS expire_at ON entry (expire_at);
CREATE INDEX IF NOT EXISTS expire_times ON entry (expire_times);
CREATE INDEX IF NOT EXISTS auto_gc ON entry (auto_gc);
CREATE INDEX IF NOT EXISTS use_count ON entry (use_count);

PRAGMA user_version = 2;