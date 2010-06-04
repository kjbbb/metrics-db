----MATVIEWREFRESH.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

--We need to drop these tables before we create them again--
--TODO maybe there is a better way to do this instead of dropping/recreating tables

DROP TABLE IF EXISTS 
    network_size,
    network_size_30_days,
    network_size_90_days,
    relay_platforms,
    relay_platforms_30_days,
    relay_platforms_90_days,
    relay_versions,
    relay_versions_30_days,
    relay_versions_90_days,
    relay_uptime,
    relay_uptime_30_days,
    relay_uptime_90_days,
    relay_bandwidth,
    relay_bandwidth_30_days,
    relay_bandwidth_90_days,
    total_bandwidth,
    total_bandwidth_30_days,
    total_bandwidth_90_days;

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

--Average relay uptime
CREATE TABLE relay_uptime AS
    SELECT * FROM relay_uptime_v;
CREATE TABLE relay_uptime_30_days AS
    SELECT * FROM relay_uptime
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <=30;
CREATE TABLE relay_uptime_90_days AS
    SELECT * FROM relay_uptime
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <=90;

--Relay bandwidth
CREATE TABLE relay_bandwidth AS
    SELECT * FROM relay_bandwidth_v;
CREATE TABLE relay_bandwidth_30_days AS
    SELECT * FROM relay_bandwidth
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <=30;
CREATE TABLE relay_bandwidth_90_days AS
    SELECT * FROM relay_bandwidth
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <=90;

--Total bandwidth
CREATE TABLE total_bandwidth AS
    SELECT * FROM total_bandwidth_v;
CREATE TABLE total_bandwidth_30_days AS
    SELECT * FROM total_bandwidth
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <=30;
CREATE TABLE total_bandwidth_90_days AS
    SELECT * FROM total_bandwidth
    WHERE EXTRACT('epoch' FROM AGE(date)) / 86400 <=90;

--Select permissions on materialized views
GRANT SELECT ON
    network_size,
    network_size_30_days,
    network_size_90_days,
    relay_platforms,
    relay_platforms_30_days,
    relay_platforms_90_days,
    relay_versions,
    relay_versions_30_days,
    relay_versions_90_days,
    relay_uptime,
    relay_uptime_30_days,
    relay_uptime_90_days,
    relay_bandwidth,
    relay_bandwidth_30_days,
    relay_bandwidth_90_days,
    total_bandwidth,
    total_bandwidth_30_days,
    total_bandwidth_90_days
TO ernie, kjb
