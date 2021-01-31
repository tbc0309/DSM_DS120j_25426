CREATE TABLE user
(
	id varchar(256) NOT NULL,
	name text DEFAULT '',
	device text DEFAULT '',
	ctime bigint NOT NULL DEFAULT (strftime('%s', 'now')),
	mtime bigint NOT NULL DEFAULT (strftime('%s', 'now')),
	PRIMARY KEY (id)
);

CREATE TABLE config
(
	key varchar(256) NOT NULL,
	value text NOT NULL,
	PRIMARY KEY (key)
);

INSERT INTO config (key, value) VALUES('version', '1');
