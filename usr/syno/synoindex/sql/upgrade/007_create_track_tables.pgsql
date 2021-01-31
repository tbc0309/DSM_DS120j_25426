-- vim:ft=sql

BEGIN;

CREATE TABLE track
(
  userid int8,
  id serial NOT NULL,
  path text NOT NULL,
  title text NOT NULL,
  title_sort text NOT NULL,
  title_search text NOT NULL,
  filesize int8 DEFAULT 0,
  year int4,
  frequency int4,
  channel int4,
  bitrate int4,
  duration float4,
  comment text,
  track int4,
  disc int4,
  container text,
  codec text,
  is_virtual boolean DEFAULT FALSE,
  has_virtual boolean DEFAULT FALSE,
  covercount int4,
  date timestamp,
  mdate timestamp,
  
  CONSTRAINT track_pkey PRIMARY KEY (id)
)
WITHOUT OIDS;
CREATE INDEX track_title_idx ON track USING btree (title);
CREATE INDEX track_title_sort_idx ON track USING btree (title_sort);
CREATE INDEX track_title_search_idx ON track USING btree (title_search);
CREATE INDEX track_year_idx ON track USING btree (year int4_ops);
CREATE INDEX track_track_idx ON track USING btree (track int4_ops);
CREATE INDEX track_disc_idx ON track USING btree (disc int4_ops);
CREATE INDEX track_container_idx ON track USING btree (container);
CREATE INDEX track_codec_idx ON track USING btree (codec);
CREATE INDEX track_date_idx ON track USING btree (date);
CREATE INDEX track_mdate_idx ON track USING btree (mdate);
CREATE UNIQUE INDEX track_path_is_virtual_track_idx ON track USING btree (path, is_virtual, track);

CREATE TABLE genre_track
(
  track int4 NOT NULL,
  genre text NOT NULL,
  genre_sort text NOT NULL,
  genre_search text NOT NULL,
  
  CONSTRAINT genre_track_pkey PRIMARY KEY (track, genre),
  CONSTRAINT genre_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX genre_track_track_idx ON genre_track USING btree (track int4_ops);
CREATE INDEX genre_track_genre_idx ON genre_track USING btree (genre);
CREATE INDEX genre_track_genre_sort_idx ON genre_track USING btree (genre_sort);
CREATE INDEX genre_track_genre_search_idx ON genre_track USING btree (genre_search);
CREATE UNIQUE INDEX genre_track_track_genre_idx ON genre_track USING btree (track, genre);

CREATE TABLE composer_track
(
  track int4 NOT NULL,
  composer text NOT NULL,
  composer_sort text NOT NULL,
  composer_search text NOT NULL,
  
  CONSTRAINT composer_track_pkey PRIMARY KEY (track, composer),
  CONSTRAINT composer_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX composer_track_track_idx ON composer_track USING btree (track int4_ops);
CREATE INDEX composer_track_composer_idx ON composer_track USING btree (composer);
CREATE INDEX composer_track_composer_sort_idx ON composer_track USING btree (composer_sort);
CREATE INDEX composer_track_composer_search_idx ON composer_track USING btree (composer_search);
CREATE UNIQUE INDEX composer_track_track_composer_idx ON composer_track USING btree (track, composer);

CREATE TABLE artist_track
(
  track int4 NOT NULL,
  artist text NOT NULL,
  artist_sort text NOT NULL,
  artist_search text NOT NULL,
  has_album_artist boolean DEFAULT FALSE,
  
  CONSTRAINT artist_track_pkey PRIMARY KEY (track, artist),
  CONSTRAINT artist_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX artist_track_track_idx ON artist_track USING btree (track int4_ops);
CREATE INDEX artist_track_artist_idx ON artist_track USING btree (artist);
CREATE INDEX artist_track_artist_sort_idx ON artist_track USING btree (artist_sort);
CREATE INDEX artist_track_artist_search_idx ON artist_track USING btree (artist_search);
CREATE UNIQUE INDEX artist_track_track_artist_idx ON artist_track USING btree (track, artist);

CREATE TABLE album_track
(
  track int4 NOT NULL,
  album text NOT NULL,
  album_sort text NOT NULL,
  album_search text NOT NULL,
  album_artist text,
  album_artist_sort text,
  album_artist_search text,
  from_album_artist boolean DEFAULT FALSE,
  
  CONSTRAINT album_track_pkey PRIMARY KEY (track, album, album_artist),
  CONSTRAINT album_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX album_track_track_idx ON album_track USING btree (track int4_ops);
CREATE INDEX album_track_album_idx ON album_track USING btree (album);
CREATE INDEX album_track_album_sort_idx ON album_track USING btree (album_sort);
CREATE INDEX album_track_album_search_idx ON album_track USING btree (album_search);
CREATE INDEX album_track_album_artist_idx ON album_track USING btree (album_artist);
CREATE INDEX album_track_album_artist_sort_idx ON album_track USING btree (album_artist_sort);
CREATE INDEX album_track_album_artist_search_idx ON album_track USING btree (album_artist_search);
CREATE UNIQUE INDEX album_track_track_album_album_artist_idx ON album_track USING btree (track, album, album_artist);

CREATE TABLE virtual_info_track
(
	track int4 NOT NULL,
	audio_offset text NOT NULL DEFAULT '',
	cue_sheet_path text NOT NULL DEFAULT '',
    CONSTRAINT virtual_info_track_pkey PRIMARY KEY (track),
	CONSTRAINT virtual_info_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX virtual_info_track_cue_sheet_path_idx ON virtual_info_track USING btree (cue_sheet_path);
CREATE UNIQUE INDEX virtual_info_track_audio_offset_cue_sheet_path_idx ON virtual_info_track USING btree (track);

CREATE TABLE rating_track
(
  userid int8,
  track int4 NOT NULL,
  star int4 NOT NULL DEFAULT 0,
  
  CONSTRAINT rating_track_pkey PRIMARY KEY (userid, track),
  CONSTRAINT rating_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX rating_track_track_idx ON rating_track USING btree (track int4_ops);
CREATE INDEX rating_track_star_idx ON rating_track USING btree (star int4_ops);
CREATE UNIQUE INDEX rating_track_userid_track_idx ON rating_track USING btree (userid, track);

CREATE TABLE playcount_track
(
  userid int8,
  track int4 NOT NULL,
  count int8 DEFAULT 0,
  mdate timestamp,
  
  CONSTRAINT playcount_track_pkey PRIMARY KEY (userid, track),
  CONSTRAINT playcount_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE INDEX playcount_track_track_idx ON playcount_track USING btree (track int4_ops);
CREATE INDEX playcount_track_count_idx ON playcount_track USING btree (count int8_ops);
CREATE INDEX playcount_track_mdate_idx ON playcount_track USING btree (mdate);
CREATE UNIQUE INDEX playcount_track_userid_track_idx ON playcount_track USING btree (userid, track);

COMMIT;
