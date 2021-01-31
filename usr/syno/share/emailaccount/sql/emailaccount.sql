BEGIN;

CREATE TABLE emailaccountinfo 
(
  uid integer NOT NULL,
  email_type text NOT NULL,
  alias text NOT NULL,
  host text DEFAULT '',
  port text DEFAULT '',
  account text NOT NULL,
  passwd text DEFAULT '',
  auth text DEFAULT 'true',
  sender_account text DEFAULT '',
  sender_name text DEFAULT '',
  access_token text DEFAULT '',
  refresh_token text DEFAULT '',
  expires_in text DEFAULT '',
  is_default boolean DEFAULT false,
  tls text DEFAULT 'true',
  PRIMARY KEY (uid,alias)
);

COMMIT;
