-- vim:ft=sql

BEGIN;

ALTER TABLE track ADD COLUMN agg_genre text;
ALTER TABLE track ADD COLUMN agg_genre_sort text;
ALTER TABLE track ADD COLUMN agg_genre_search text;

CREATE INDEX track_agg_genre_idx ON track USING btree (agg_genre);
CREATE INDEX track_agg_genre_sort_idx ON track USING btree (agg_genre_sort);
CREATE INDEX track_agg_genre_search_idx ON track USING btree (agg_genre_search);
CREATE INDEX track_is_virtual_idx ON track USING btree (is_virtual);
CREATE INDEX track_has_virtual_idx ON track USING btree (has_virtual);

CREATE INDEX virtual_info_track_track_idx ON virtual_info_track USING btree (track int4_ops);

COMMIT;
