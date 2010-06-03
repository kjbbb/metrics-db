----MATVIEWS.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

--We need to drop these tables before we create them again--

DROP TABLE IF EXISTS network_size,
    network_size_30_days,
    network_size_90_days,
    relay_platforms,
    relay_platforms_30_days,
    relay_platforms_90_days,
    relay_versions,
    relay_versions_30_days,
    relay_versions_90_days;

--Materialized views that will be updated on every run of ernie--

--Total network size--
CREATE TABLE network_size AS
    SELECT * FROM network_size_v;
--Network size past 30 days--
CREATE TABLE network_size_30_days AS
    SELECT * FROM network_size
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <= 30;
--Network size past 90 days--
CREATE TABLE network_size_90_days AS
    SELECT * FROM network_size
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <= 90;

--Total relay platforms--
CREATE TABLE relay_platforms AS
    SELECT * FROM relay_platforms_v;
--Relay platforms past 30 days--
CREATE TABLE relay_platforms_30_days AS
    SELECT * FROM relay_platforms
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <= 30;
--Relay platforms past 90 days--
CREATE TABLE relay_platforms_90_days AS
    SELECT * FROM relay_platforms
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <= 90;

--Total relay versions--
CREATE TABLE relay_versions AS
    SELECT * FROM relay_versions_v;
--Relay verions past 30 days--
CREATE TABLE relay_versions_30_days AS
    SELECT * FROM relay_versions
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <= 30;
--Relay verions past 90 days--
CREATE TABLE relay_versions_90_days AS
    SELECT * FROM relay_versions
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <= 90;

--Select permissions
GRANT SELECT ON relay_platforms,
    relay_platforms_30_days,
    relay_platforms_90_days,
    relay_versions,
    relay_versions_30_days,
    relay_versions_90_days,
    network_size,
    network_size_30_days,
    network_size_90_days
TO ernie, kjb
