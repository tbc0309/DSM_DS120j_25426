BEGIN;

CREATE TABLE db_info(
 id INTEGER PRIMARY KEY,
 start_time INTEGER,
 end_time INTEGER,
 log_count INTEGER,
 device TEXT
);
INSERT INTO db_info VALUES('1', strftime('%s', 'now'), '0', '0', '');

CREATE TABLE hosts(
 host_id INTEGER PRIMARY KEY AUTOINCREMENT,
 host_name TEXT UNIQUE
);
CREATE INDEX host_idx ON hosts (host_name);

CREATE TABLE tags(
 tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
 tag_name TEXT UNIQUE
);
CREATE INDEX tag_idx ON tags (tag_name);

CREATE TABLE progs(
 prog_id INTEGER PRIMARY KEY AUTOINCREMENT,
 prog_name TEXT UNIQUE
);
CREATE INDEX prog_idx ON progs (prog_name);

CREATE TABLE facs(
 fac_id INTEGER PRIMARY KEY AUTOINCREMENT,
 fac_name TEXT UNIQUE
);
CREATE INDEX fac_idx ON facs (fac_name);

CREATE TABLE logs(
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 host INTEGER default NULL,
 ip INTEGER DEFAULT NULL,
 fac INTEGER default NULL,
 prio INTEGER default NULL,
 llevel INTEGER default NULL,
 tag INTEGER default NULL,
 utcsec INTEGER default NULL,
 r_utcsec INTEGER default NULL,
 tzoffset TEXT default NULL,
 ldate DATE default CURRENT_DATE,
 ltime TIME default CURRENT_TIME,
 prog INTEGER default NULL,
 msg TEXT default NULL,
 FOREIGN KEY(host)   REFERENCES hosts(host_id),
 FOREIGN KEY(tag)    REFERENCES tags(tag_id),
 FOREIGN KEY(prog)   REFERENCES progs(prog_id),
 FOREIGN KEY(fac)    REFERENCES facs(fac_id)
);

CREATE INDEX logs_id_idx ON logs (id);
CREATE INDEX logs_utcsec_idx ON logs (utcsec);
CREATE INDEX logs_r_utcsec_idx ON logs (r_utcsec);
CREATE INDEX logs_llevel_idx ON logs (llevel);
CREATE INDEX logs_ldate_idx ON logs (ldate);
CREATE INDEX logs_ltime_idx ON logs (ltime);

CREATE TABLE dummy(
 id INTEGER,
 noop INTEGER
);

CREATE TRIGGER IF NOT EXISTS fk_check BEFORE INSERT ON logs
BEGIN
    INSERT OR IGNORE INTO hosts VALUES(NULL, NEW.host);
    INSERT OR IGNORE INTO tags VALUES(NULL, NEW.tag);
    INSERT OR IGNORE INTO progs VALUES(NULL, NEW.prog);
    INSERT OR IGNORE INTO facs VALUES(NULL, NEW.fac);
    
    INSERT INTO logs VALUES(NULL, 
			    (SELECT host_id FROM hosts WHERE host_name=NEW.host),
			    NEW.ip,
			    (SELECT fac_id FROM facs WHERE fac_name=NEW.fac),
			    NEW.prio,
			    NEW.llevel,
			    (SELECT tag_id FROM tags WHERE tag_name=NEW.tag),
			    NEW.utcsec,
             NEW.r_utcsec,
			    NEW.tzoffset,
			    NEW.ldate,
			    NEW.ltime,
			    (SELECT prog_id FROM progs WHERE prog_name=NEW.prog),
			    NEW.msg);

    UPDATE db_info SET log_count=log_count+1 WHERE 1=id;

    UPDATE dummy SET noop = '0' WHERE rowid = 1 AND RAISE(IGNORE);
    select raise(ignore);
END;

COMMIT;
