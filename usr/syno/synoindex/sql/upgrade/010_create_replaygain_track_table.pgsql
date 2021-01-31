-- vim:ft=sql

BEGIN;

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
