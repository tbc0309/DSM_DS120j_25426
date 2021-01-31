BEGIN;

CREATE TABLE log(
   id INTEGER PRIMARY KEY, 
   level INTEGER, 
   time INTEGER, 
   user TEXT, 
   event TEXT
);

COMMIT;
