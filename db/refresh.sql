-- REFRESH.SQL
-- This script should be run every time ernie is run to keep data sinks
-- up to date by calling the refresh functions.

-- Make this script a transaction, in case we need to roll-back changes.
BEGIN;

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

-- Clear the updates table, since we have just updated everything.
DELETE FROM updates;

-- Keep the relay_statuses_per_day helper materialized-view up-to-date.
SELECT *
INTO relay_statuses_per_day
FROM relay_statuses_per_day_v;

-- Clear the updates table, since we have just updated everything.
DELETE FROM updates;

-- Commit the transaction.
COMMIT;
