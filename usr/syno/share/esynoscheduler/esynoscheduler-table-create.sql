PRAGMA auto_vacuum = FULL;
PRAGMA foreign_keys = ON;
CREATE TABLE if not exists task (
			task_name			TEXT PRIMARY KEY NOT NULL,
			description			TEXT,
			event				TEXT NOT NULL,
			depend_on_task		TEXT,
			enable				INTEGER DEFAULT 1,
			owner				INTEGER NOT NULL,
			run_the_same_time	INTEGER DEFAULT 1,
			notify_enable		INTEGER DEFAULT 0,
			notify_mail			TEXT,
			notify_if_error		INTEGER DEFAULT 0,
			operation			TEXT NOT NULL,
			operation_type		TEXT NOT NULL,
			status				TEXT NOT NULL DEFAULT "{}",
			last_start_time		INTEGER,
			last_stop_time		INTEGER,
			last_exit_info		TEXT,
			extra				TEXT DEFAULT "{}"
);

CREATE TABLE if not exists task_result (
			result_id		INTEGER PRIMARY KEY NOT NULL,
			task_name		TEXT NOT NULL,
			pid				INTEGER NOT NULL,
			event_fire_time	INTEGER NOT NULL,
			start_time		INTEGER NOT NULL,
			stop_time		INTEGER,
			exit_info		TEXT,
			trigger_event	TEXT NOT NULL,
			run_time_env	TEXT DEFAULT "{}",
			extra				TEXT DEFAULT "{}",
			CONSTRAINT 		task_result_fkey_task_name FOREIGN KEY (task_name) REFERENCES task (task_name) 
				ON UPDATE CASCADE ON DELETE CASCADE
);
