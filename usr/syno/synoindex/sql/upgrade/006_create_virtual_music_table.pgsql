-- vim:ft=sql

BEGIN;

CREATE TABLE virtual_music (
    id serial NOT NULL,
	path text NOT NULL DEFAULT '',
	title text DEFAULT '',
	album text DEFAULT '',
	artist text DEFAULT '',
	album_artist text DEFAULT '',
	composer text DEFAULT '',
	year int4,
	genre varchar(128),
    comment text NOT NULL,
	duration int NOT NULL,
	track int NOT NULL,
    CONSTRAINT virtual_music_pkey PRIMARY KEY (id),
	CONSTRAINT virtual_music_ukey UNIQUE (comment, track)
)
WITHOUT OIDS;

COMMIT;
