----MATVIEWREFRESH.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

SELECT * FROM refresh_network_size();
SELECT * FROM refresh_relay_platforms();
SELECT * FROM refresh_relay_versions();
SELECT * FROM refresh_relay_uptime();
SELECT * FROM refresh_relay_bandwidth();
SELECT * FROM refresh_total_bandwidth();
