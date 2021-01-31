-- entry
CREATE TABLE IF NOT EXISTS entry
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
	,data				TEXT		NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS hash ON entry (hash);
CREATE INDEX IF NOT EXISTS project_name ON entry (project_name);
CREATE INDEX IF NOT EXISTS owner_uid ON entry (owner_uid);
CREATE INDEX IF NOT EXISTS enabled ON entry (enabled);
CREATE INDEX IF NOT EXISTS start_at ON entry (start_at);
CREATE INDEX IF NOT EXISTS expire_at ON entry (expire_at);
CREATE INDEX IF NOT EXISTS expire_times ON entry (expire_times);
CREATE INDEX IF NOT EXISTS auto_gc ON entry (auto_gc);
CREATE INDEX IF NOT EXISTS use_count ON entry (use_count);


-- session
CREATE TABLE IF NOT EXISTS session
(
	id 					INTEGER 	PRIMARY KEY ASC AUTOINCREMENT
	,session_id			TEXT		NOT NULL
	,uid				INTEGER
	,ip 				TEXT		NOT NULL
	,timeout 			INTEGER
);
CREATE UNIQUE INDEX IF NOT EXISTS session_id ON session (session_id);
CREATE INDEX IF NOT EXISTS ip ON session (ip);
CREATE INDEX IF NOT EXISTS timeout ON session (timeout);


-- token
CREATE TABLE IF NOT EXISTS token
(
	id 					INTEGER 	PRIMARY KEY ASC AUTOINCREMENT
	,entry_id			INTEGER		REFERENCES entry(id)		ON DELETE CASCADE
	,session_id			INTEGER		REFERENCES session(id)		ON DELETE CASCADE
	,timeout 			INTEGER
);
CREATE INDEX IF NOT EXISTS entry_id ON token (entry_id);
CREATE INDEX IF NOT EXISTS session_id ON token (session_id);
CREATE INDEX IF NOT EXISTS timeout ON token (timeout);

PRAGMA user_version = 1;