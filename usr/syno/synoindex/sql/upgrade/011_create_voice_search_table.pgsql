-- vim:ft=sql

BEGIN;

CREATE TABLE voice_search(
	track integer NOT NULL,
	title text NOT NULL DEFAULT '',
	album text NOT NULL DEFAULT '',
	artist text NOT NULL DEFAULT '',
	album_artist text NOT NULL DEFAULT '',

	CONSTRAINT voice_search_pkey PRIMARY KEY (track),
	CONSTRAINT voice_search_track_fkey FOREIGN KEY (track)
		REFERENCES track (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

COMMIT;
