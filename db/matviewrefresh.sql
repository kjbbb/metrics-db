----MATVIEWREFRESH.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

CREATE LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_network_size() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_network_size_date network_size.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_network_size_date
        FROM network_size
        LIMIT 1;

        IF max_statusentry_date - max_network_size_date > 0 THEN
            SELECT
                DATE(validafter),
                COUNT(*) / relay_statuses_per_day.count AS avg_running,
                SUM(CASE WHEN isexit IS TRUE THEN 1 ELSE 0 END)
                    / relay_statuses_per_day.count AS avg_exit,
                SUM(CASE WHEN isguard IS TRUE THEN 1 ELSE 0 END)
                    / relay_statuses_per_day.count AS avg_guard
            INTO network_size
            FROM statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuse
                GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) = relay_statuses_per_day.date
                AND DATE(validafter) > max_network_size_date
            GROUP BY DATE(validafter), relay_statuses_per_day.count
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_relay_platforms() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_relay_platforms_date relay_platforms.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_relay_platforms_date
        FROM relay_platforms
        LIMIT 1;

        IF max_statusentry_date - max_relay_platforms_date > 0 THEN
            SELECT
                DATE(validafter),
                SUM(CASE WHEN platform LIKE '%Linux%' THEN 1 ELSE 0 END) /
                    relay_statuses_per_day.count AS avg_linux,
                SUM(CASE WHEN platform LIKE '%Darwin%' THEN 1 ELSE 0 END) /
                    relay_statuses_per_day.count AS avg_darwin,
                SUM(CASE WHEN platform LIKE '%BSD%' THEN 1 ELSE 0 END) /
                    relay_statuses_per_day.count AS avg_bsd,
                SUM(CASE WHEN platform LIKE '%Windows%' THEN 1 ELSE 0 END) /
                    relay_statuses_per_day.count AS avg_windows,
                SUM(CASE WHEN platform NOT LIKE '%Windows%'
                    AND platform NOT LIKE '%Darwin%'
                    AND platform NOT LIKE '%BSD%'
                    AND platform NOT LIKE '%Linux%' THEN 1 ELSE 0 END) /
                    relay_statuses_per_day.count AS avg_other
            INTO relay_platforms
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                    FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuse
                    GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) > max_relay_platforms_date
            GROUP BY DATE(validafter), relay_statuses_per_day.count
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_relay_versions() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_relay_versions_date relay_versions.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_relay_versions_date
        FROM relay_versions
        LIMIT 1;

        IF max_statusentry_date - max_relay_versions_date > 0 THEN
            SELECT
              DATE(validafter),
              SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.1.2' THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS "0.1.2",
              SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.0' THEN 1 ELSE 0 END)
                  /relay_statuses_per_day.count AS "0.2.0",
              SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.1' THEN 1 ELSE 0 END)
                  /relay_statuses_per_day.count AS "0.2.1",
              SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.2' THEN 1 ELSE 0 END)
                  /relay_statuses_per_day.count AS "0.2.2"
            INTO relay_versions
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                    FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                    GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) > max_relay_versions_date
            GROUP BY DATE(validafter), relay_statuses_per_day.count
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_relay_uptime() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_relay_uptime_date relay_uptime.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_relay_uptime_date
        FROM relay_uptime
        LIMIT 1;

        IF max_statusentry_date - max_relay_uptime_date > 0 THEN
            SELECT (AVG(uptime) / relay_statuses_per_day.count)::INT AS uptime,
                (STDDEV(uptime) / relay_statuses_per_day.count)::INT AS stddev,
                DATE(validafter)
            INTO relay_uptime
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE validafter IS NOT NULL
            GROUP BY DATE(validafter), relay_statuses_per_day.count
            WHERE DATE(validafter) > max_relay_uptime_date
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_relay_bandwidth() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_relay_bandwidth_date relay_bandwidth.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_relay_bandwidth_date
        FROM relay_bandwidth
        LIMIT 1;

        IF max_statusentry_date - max_relay_bandwidth_date > 0 THEN
            SELECT (AVG(bandwidthavg)
                    / relay_statuses_per_day.count)::INT AS bwavg,
                (AVG(bandwidthburst)
                    / relay_statuses_per_day.count)::INT AS bwburst,
                (AVG(bandwidthobserved)
                    / relay_statuses_per_day.count)::INT AS bwobserved,
                DATE(validafter)
            INTO relay_bandwidth
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                        FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                        GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE validafter IS NOT NULL
                AND DATE(validafter) > max_relay_bandwidth_date
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_total_bandwidth() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_total_bandwidth_date total_bandwidth.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_total_bandwidth_date
        FROM total_bandwidth
        LIMIT 1;

        IF max_statusentry_date - max_total_bandwidth_date > 0 THEN
            SELECT (SUM(bandwidthavg)
                    / relay_statuses_per_day.count)::BIGINT AS bwavg,
                (SUM(bandwidthburst)
                    / relay_statuses_per_day.count)::BIGINT AS bwburst,
                (SUM(bandwidthobserved)
                    / relay_statuses_per_day.count)::BIGINT AS bwobserved,
                DATE(validafter)
            INTO total_bandwidth
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                        FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                        GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE validafter IS NOT NULL
                AND DATE(validafter) > max_total_bandwidth_date
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql
