BEGIN;

CREATE TABLE personal_playlist
(
  userid int8 NOT NULL,
  id serial NOT NULL,
  path text NOT NULL,
  title text NOT NULL,
  filesize int8 NOT NULL DEFAULT 0,
  album text,
  song_count int4 NOT NULL DEFAULT 0,
  date timestamp,
  mdate timestamp,
  fs_uuid text,
  fs_online boolean DEFAULT TRUE,
  updated character DEFAULT '1',
  CONSTRAINT personal_playlist_pkey PRIMARY KEY (id)
)
WITHOUT OIDS;
CREATE UNIQUE INDEX personal_playlist_path_idx ON personal_playlist USING btree (path);

CREATE TABLE personal_directory
(
  userid int8 NOT NULL,
  id serial NOT NULL,
  path text NOT NULL,
  title text,
  date timestamp,
  mdate timestamp,
  fs_uuid text,
  fs_online boolean DEFAULT TRUE,
  updated character DEFAULT '1',
  CONSTRAINT personal_directory_pkey PRIMARY KEY (id),
  CONSTRAINT personal_directory_path_key UNIQUE (path)
)
WITHOUT OIDS;
CREATE UNIQUE INDEX personal_directory_path_idx ON personal_directory USING btree (path);

COMMIT;
