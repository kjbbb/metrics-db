----MATVIEWREFRESH.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

PERFORM refresh_network_size
PERFORM refresh_relay_platforms
PERFORM refresh_relay_versions
PERFORM refresh_relay_uptime
PERFORM refresh_relay_bandwidth
PERFORM refresh_total_bandwidth
