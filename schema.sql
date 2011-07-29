CREATE TABLE IF NOT EXISTS networks (
	network_id INTEGER PRIMARY KEY,
	network_name TEXT UNIQUE ON CONFLICT IGNORE
);

CREATE TABLE IF NOT EXISTS series (
	series_id INTEGER PRIMARY KEY,
	series_code TEXT,
	series_name TEXT,
	CONSTRAINT unique_series UNIQUE (series_code, series_name) ON CONFLICT IGNORE
);

CREATE TABLE IF NOT EXISTS episodes (
	episode_id INTEGER PRIMARY KEY,
	series_id INTEGER,
	network_id INTEGER,
	show_title TEXT,
	episode INTEGER,
	season INTEGER,
	synopsis TEXT,
	pub_date TEXT,
	CONSTRAINT unique_episodes UNIQUE (series_id, network_id, show_title, episode, season) ON CONFLICT IGNORE
);
