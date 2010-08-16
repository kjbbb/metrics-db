-- REFRESH.SQL
-- This script should be run every time ernie is run to keep data sinks
-- up to date by calling the refresh functions.

-- Keep the relay_statuses_per_day helper materialized-view up-to-date.
SELECT *
INTO relay_statuses_per_day
FROM relay_statuses_per_day_v;

SELECT * FROM refresh_network_size();
SELECT * FROM refresh_relay_platforms();
SELECT * FROM refresh_relay_versions();
SELECT * FROM refresh_relay_uptime();
SELECT * FROM refresh_relay_bandwidth();
SELECT * FROM refresh_total_bandwidth();
SELECT * FROM refresh_platforms_uptime_month();
SELECT * FROM refresh_churn();

-- Clear the updates table, since we have just updated everything.
DELETE FROM updates;
