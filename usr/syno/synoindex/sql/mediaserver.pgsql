BEGIN;

CREATE TABLE music
(
  id serial NOT NULL,
  path text NOT NULL,
  title text NOT NULL,
  filesize int8 NOT NULL DEFAULT 0,
  album text,
  artist text,
  album_artist text,
  composer text,
  comment text,
  year int4,
  genre varchar(128),
  frequency int4,
  bitrate int4,
  duration int4,
  channel int4,
  track int4,
  disc int4,
  covercount int4,
  date timestamp,
  mdate timestamp,
  fs_uuid text,
  fs_online boolean DEFAULT TRUE,
  CONSTRAINT music_pkey PRIMARY KEY (id)
)
WITHOUT OIDS;
CREATE INDEX music_album_idx ON music USING btree (album);
CREATE INDEX music_artist_idx ON music USING btree (artist);
CREATE INDEX music_album_artist_idx ON music USING btree (album_artist);
CREATE INDEX music_year_idx ON music USING btree ("year" int4_ops);
CREATE INDEX music_disc_idx ON music USING btree (disc int4_ops);
CREATE INDEX music_track_idx ON music USING btree (track int4_ops);
CREATE INDEX music_genre_idx ON music USING btree (genre);
CREATE INDEX music_composer_idx ON music USING btree (composer);
CREATE INDEX music_title_idx ON music USING btree (title);
CREATE INDEX music_date_idx ON music USING btree (date);
CREATE INDEX music_mdate_idx ON music USING btree (mdate);
CREATE UNIQUE INDEX music_path_idx ON music USING btree (path);

CREATE TABLE playlist
(
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
  CONSTRAINT playlist_pkey PRIMARY KEY (id)
)
WITHOUT OIDS;
CREATE UNIQUE INDEX playlist_path_idx ON playlist USING btree (path);

CREATE TABLE photo
(
  id serial NOT NULL,
  path text NOT NULL,
  title text NOT NULL,
  filesize int8 NOT NULL DEFAULT 0,
  album text,
  resolutionx int4,
  resolutiony int4,
  camera_make varchar(100),
  camera_model varchar(100),
  exposure varchar(20),
  aperture varchar(20),
  iso int4,
  date timestamp,
  timetaken timestamp,
  mdate timestamp,
  fs_uuid text,
  fs_online boolean DEFAULT TRUE,
  CONSTRAINT photo_pkey PRIMARY KEY (id)
)
WITHOUT OIDS;
CREATE INDEX photo_title_idx ON photo USING btree (title);
CREATE INDEX photo_date_idx ON photo USING btree (date);
CREATE INDEX photo_timetaken_idx ON photo USING btree (timetaken);
CREATE INDEX photo_mdate_idx ON photo USING btree (mdate);
CREATE UNIQUE INDEX photo_path_idx ON photo USING btree (path);

CREATE TABLE video
(
  id serial NOT NULL,
  path text NOT NULL,
  title text NOT NULL,
  filesize int8 NOT NULL DEFAULT 0,
  album text,
  container_type text NOT NULL,
  video_codec text,
  frame_bitrate int4,
  frame_rate_num int4,
  frame_rate_den int4,
  video_bitrate int4,
  video_profile int4,
  video_level int4,
  resolutionX int4,
  resolutionY int4,
  audio_codec text,
  audio_bitrate int4,
  frequency int4,
  channel int4,
  duration int4,
  date timestamp,
  mdate timestamp,
  fs_uuid text,
  fs_online boolean DEFAULT TRUE,
  CONSTRAINT video_pkey PRIMARY KEY (id)
)
WITHOUT OIDS;
CREATE INDEX video_title_idx ON video USING btree (title);
CREATE INDEX video_date_idx ON video USING btree (date);
CREATE INDEX video_mdate_idx ON video USING btree (mdate);
CREATE UNIQUE INDEX video_path_idx ON video USING btree (path);

CREATE TABLE directory
(
  id serial NOT NULL,
  path text NOT NULL,
  title text,
  date timestamp,
  mdate timestamp,
  fs_uuid text,
  fs_online boolean DEFAULT TRUE,
  CONSTRAINT directory_pkey PRIMARY KEY (id),
  CONSTRAINT directory_path_key UNIQUE (path)
)
WITHOUT OIDS;
CREATE UNIQUE INDEX directory_path_idx ON directory USING btree (path);

CREATE TABLE video_convert (
 video_path text NOT NULL,
 convert_file_path text NOT NULL,
 resolutionx int4 DEFAULT NULL,
 resolutiony int4 DEFAULT NULL,
 container_type text NOT NULL,
 video_bitrate int4 DEFAULT NULL,
 vcodec text DEFAULT NULL,
 video_profile int4 DEFAULT NULL,
 video_level int4 DEFAULT NULL,
 acodec text DEFAULT NULL,
 audio_bitrate int4 DEFAULT NULL,
 audio_frequency int4 DEFAULT NULL,
 audio_channel int4 DEFAULT NULL,
 convert_type text NOT NULL,
 fs_online boolean DEFAULT TRUE,
 CONSTRAINT video_convert_pkey PRIMARY KEY (convert_file_path),
 CONSTRAINT video_convert_fk1 FOREIGN KEY (video_path) REFERENCES video (path) ON DELETE CASCADE ON UPDATE CASCADE
)
WITHOUT OIDS;
CREATE INDEX video_convert_convert_type_idx ON video_convert USING btree (convert_type);
CREATE INDEX video_convert_video_path_idx ON video_convert USING btree (video_path);

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

CREATE TABLE track
(
  userid int8,
  id serial NOT NULL,
  path text NOT NULL,
  title text NOT NULL,
  title_sort text NOT NULL,
  title_search text NOT NULL,
  agg_genre text,
  agg_genre_sort text,
  agg_genre_search text,
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
CREATE INDEX track_agg_genre_idx ON track USING btree (agg_genre);
CREATE INDEX track_agg_genre_sort_idx ON track USING btree (agg_genre_sort);
CREATE INDEX track_agg_genre_search_idx ON track USING btree (agg_genre_search);
CREATE INDEX track_year_idx ON track USING btree (year int4_ops);
CREATE INDEX track_track_idx ON track USING btree (track int4_ops);
CREATE INDEX track_disc_idx ON track USING btree (disc int4_ops);
CREATE INDEX track_container_idx ON track USING btree (container);
CREATE INDEX track_codec_idx ON track USING btree (codec);
CREATE INDEX track_is_virtual_idx ON track USING btree (is_virtual);
CREATE INDEX track_has_virtual_idx ON track USING btree (has_virtual);
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
CREATE INDEX virtual_info_track_track_idx ON virtual_info_track USING btree (track int4_ops);
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

CREATE TABLE replaygain_track
(
  track int4 NOT NULL,
  rg_track_gain float4,
  rg_track_peak float4,
  rg_album_gain float4,
  rg_album_peak float4,
  
  CONSTRAINT replaygain_track_pkey PRIMARY KEY (track),
  CONSTRAINT replaygain_track_fkey FOREIGN KEY (track)
      REFERENCES track (id) MATCH SIMPLE
	  ON UPDATE CASCADE ON DELETE CASCADE
)
WITHOUT OIDS;
CREATE UNIQUE INDEX replaygain_track_track_idx ON replaygain_track USING btree (track);

COMMIT;
