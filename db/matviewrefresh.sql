----MATVIEWREFRESH.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

--Make this script a transaction, so we don't lose any data
--in case of a mistake.
BEGIN;

--We need to drop these tables before we create them again--
--TODO maybe there is a better way to do this instead of dropping/recreating tables

DROP TABLE IF EXISTS
    network_size,
    relay_platforms,
    relay_versions,
    relay_uptime,
    relay_bandwidth,
    total_bandwidth;

--Materialized views that will be updated on every run of ernie--

--Total network size--
CREATE TABLE network_size AS
    SELECT * FROM network_size_v;

--Total relay platforms--
CREATE TABLE relay_platforms AS
    SELECT * FROM relay_platforms_v;

--Total relay versions--
CREATE TABLE relay_versions AS
    SELECT * FROM relay_versions_v;

--Average relay uptime
CREATE TABLE relay_uptime AS
    SELECT * FROM relay_uptime_v;

--Relay bandwidth
CREATE TABLE relay_bandwidth AS
    SELECT * FROM relay_bandwidth_v;

--Total bandwidth
CREATE TABLE total_bandwidth AS
    SELECT * FROM total_bandwidth_v;

--Select permissions on materialized views
GRANT SELECT ON
    network_size,
    relay_platforms,
    relay_versions,
    relay_uptime,
    relay_bandwidth,
    total_bandwidth,
TO ernie;

COMMIT;
